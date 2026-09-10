import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:invoiso/common/common.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/services/refund_receipt_service.dart';
import 'package:invoiso/widgets/return_l10n.dart';

// Canonical (stored) reason values; displayed via [returnReasonLabel].
const _returnReasons = <String>[
  'Damaged / defective',
  'Wrong item delivered',
  'Not required',
  'Quality issue',
  'Other',
];

const _refundMethods = <String>['Cash', 'Bank Transfer', 'Check', 'Online', 'Other'];

/// Creates a Credit Note (sales return) against [invoice]. Pick returned lines
/// + quantities, choose how the value is settled, and (optionally) pay a
/// refund straight away.
class CreateReturnDialog extends ConsumerStatefulWidget {
  final Invoice invoice;
  final VoidCallback onCreated;

  const CreateReturnDialog({
    super.key,
    required this.invoice,
    required this.onCreated,
  });

  @override
  ConsumerState<CreateReturnDialog> createState() => _CreateReturnDialogState();
}

class _CreateReturnDialogState extends ConsumerState<CreateReturnDialog> {
  final _qtyCtrls = <String, TextEditingController>{};
  final _restock = <String, bool>{};
  final _reasonNoteCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  Map<String, double> _alreadyReturned = const {};
  String _reason = _returnReasons.first;
  CreditSettlement _settlement = CreditSettlement.customerCredit;
  String _refundMethod = _refundMethods.first;
  final DateTime _date = DateTime.now();

  Invoice get _inv => widget.invoice;
  String get _sym => _inv.currencySymbol;

  @override
  void initState() {
    super.initState();
    for (final item in _inv.items) {
      _qtyCtrls[item.id] = TextEditingController();
      _restock[item.id] = true;
    }
    _settlement = _inv.outstandingBalance > InvoiceCalculator.moneyEpsilon
        ? CreditSettlement.reduceInvoice
        : CreditSettlement.refund;
    _load();
  }

  @override
  void dispose() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    _reasonNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final returned = await ref
        .read(returnRepositoryProvider)
        .getReturnedQtyByLine(_inv.id);
    if (!mounted) return;
    setState(() {
      _alreadyReturned = returned;
      _loading = false;
    });
  }

  double _soldQty(InvoiceItem item) => item.quantity;

  double _returnableQty(InvoiceItem item) {
    final prior = _alreadyReturned[item.product.id] ?? 0.0;
    final left = _soldQty(item) - prior;
    return left < 0 ? 0.0 : left;
  }

  double _enteredQty(InvoiceItem item) =>
      double.tryParse(_qtyCtrls[item.id]!.text.trim()) ?? 0.0;

  /// Returned lines as InvoiceItems, flat discount + extra cost prorated to the
  /// returned fraction (a per-unit discount already scales with quantity).
  List<InvoiceItem> _returnLines() {
    final lines = <InvoiceItem>[];
    for (final item in _inv.items) {
      final qty = _enteredQty(item);
      if (qty <= 0) continue;
      final ratio = item.quantity > 0 ? qty / item.quantity : 0.0;
      lines.add(InvoiceItem(
        id: const Uuid().v4(),
        product: Product(
          id: item.product.id,
          name: item.product.name,
          description: item.product.description,
          price: item.product.price,
          stock: item.product.stock,
          hsncode: item.product.hsncode,
          tax_rate: item.product.tax_rate,
          type: item.product.type,
          purchasePrice: item.product.purchasePrice,
          aliasName: item.product.aliasName,
          unit: item.product.unit,
          unlimitedStock: item.product.unlimitedStock,
          priceIncludesTax: item.product.priceIncludesTax,
        ),
        quantity: qty,
        discount: item.discountPerUnit ? item.discount : item.discount * ratio,
        discountPerUnit: item.discountPerUnit,
        unitPrice: item.unitPrice,
        extraCost: (item.extraCost ?? 0.0) * ratio,
        unit: item.unit,
        description: item.description,
        metadata: item.metadata,
        restocked: _restock[item.id] ?? true,
      ));
    }
    return lines;
  }

  /// Live totals — a throwaway Invoice reusing the same tax settings, minus any
  /// invoice-level discount (not re-applied on a partial return).
  Invoice _draft(List<InvoiceItem> lines) => Invoice(
        id: 'draft',
        customer: _inv.customer,
        items: lines,
        date: _date,
        type: 'Credit Note',
        taxRate: _inv.taxRate,
        taxMode: _inv.taxMode,
        isInterState: _inv.isInterState,
        currencyCode: _inv.currencyCode,
        currencySymbol: _inv.currencySymbol,
      );

  String? _validate(AppLocalizations l10n, List<InvoiceItem> lines) {
    if (lines.isEmpty) return l10n.returnValidationNoQty;
    for (final item in _inv.items) {
      final qty = _enteredQty(item);
      if (qty > _returnableQty(item) + InvoiceCalculator.moneyEpsilon) {
        return l10n.returnValidationMaxQty(
            item.product.name, _fmtQty(_returnableQty(item)));
      }
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final lines = _returnLines();
    final err = _validate(l10n, lines);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(returnRepositoryProvider);
      final number = await ref
          .read(invoiceRepositoryProvider)
          .generateNextInvoiceNumber('Credit Note');
      final total = _draft(lines).total;
      final reasonText = _reasonNoteCtrl.text.trim();

      final cn = Invoice(
        id: const Uuid().v4(),
        invoiceNumber: number,
        customer: _inv.customer,
        items: lines,
        date: _date,
        type: 'Credit Note',
        taxRate: _inv.taxRate,
        taxMode: _inv.taxMode,
        isInterState: _inv.isInterState,
        currencyCode: _inv.currencyCode,
        currencySymbol: _inv.currencySymbol,
        originalInvoiceId: _inv.id,
        originalInvoiceNumber: _inv.invoiceNumber,
        originalInvoiceDate: _inv.date,
        returnReason: reasonText.isEmpty ? _reason : '$_reason — $reasonText',
        creditSettlement: _settlement,
      );

      await repo.createCreditNote(
        creditNote: cn,
        originalInvoice: _inv,
        immediateRefund: _settlement == CreditSettlement.refund
            ? (
                amount: total,
                method: _refundMethod,
                date: _date,
                notes: null,
              )
            : null,
      );

      widget.onCreated();

      SnackBarAction? voucherAction;
      if (_settlement == CreditSettlement.refund) {
        final refunds = await repo.getRefundsForCreditNote(cn.id);
        if (refunds.isNotEmpty) {
          final remaining = await repo.getRemainingCustomerCredit(
            customerId: cn.customer.id,
            customerName: cn.customer.name,
            currencyCode: cn.currencyCode,
          );
          final refund = refunds.last;
          voucherAction = SnackBarAction(
            label: l10n.returnPrintVoucher,
            onPressed: () => RefundReceiptService.printOrDownload(
                context, cn, refund,
                remainingCredit: remaining),
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.returnCreatedMessage(
              '$_sym${total.toStringAsFixed(2)}')),
          action: voucherAction,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.returnCreateError('$e'))));
    }
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = _loading ? <InvoiceItem>[] : _returnLines();
    final draft = _draft(lines);
    final fullyPaid = _inv.outstandingBalance <= InvoiceCalculator.moneyEpsilon;

    return AlertDialog(
      title: Text(l10n.returnDialogTitle(_inv.invoiceNumber ?? _inv.id)),
      content: SizedBox(
        width: 520,
        child: _loading
            ? const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.returnCustomerLabel(_inv.customer.name),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._inv.items.map((i) => _lineRow(l10n, i)),
                    const Divider(height: 24),
                    _totalsBlock(l10n, draft),
                    const SizedBox(height: 12),
                    _reasonBlock(l10n),
                    const SizedBox(height: 12),
                    _settlementBlock(l10n, fullyPaid, draft.total),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.returnCreateButton),
        ),
      ],
    );
  }

  Widget _lineRow(AppLocalizations l10n, InvoiceItem item) {
    final returnable = _returnableQty(item);
    final prior = _alreadyReturned[item.product.id] ?? 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.product.name,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.returnLineSold(_fmtQty(_soldQty(item)))}'
                  '${prior > 0 ? '  ·  ${l10n.returnLineReturned(_fmtQty(prior))}' : ''}'
                  '  ·  ${l10n.returnLineLeft(_fmtQty(returnable))}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                ),
              ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _qtyCtrls[item.id],
                  enabled: returnable > 0,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l10n.returnFieldReturn,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.returnToStockTooltip,
                child: Checkbox(
                  value: _restock[item.id] ?? true,
                  onChanged: returnable > 0
                      ? (v) => setState(() => _restock[item.id] = v ?? true)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalsBlock(AppLocalizations l10n, Invoice draft) {
    Widget row(String label, double value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
              Text('$_sym${value.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
            ],
          ),
        );
    return Column(
      children: [
        row(l10n.returnSubtotalLabel, draft.subtotal),
        if (draft.tax > 0) row(l10n.fieldTaxLabel, draft.tax),
        row(l10n.returnTotalLabel, draft.total, bold: true),
      ],
    );
  }

  Widget _reasonBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _reason,
          decoration:
              InputDecoration(isDense: true, labelText: l10n.returnReasonLabel),
          items: [
            for (final r in _returnReasons)
              DropdownMenuItem(value: r, child: Text(returnReasonLabel(l10n, r))),
          ],
          onChanged: (v) => setState(() => _reason = v ?? _returnReasons.first),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonNoteCtrl,
          decoration: InputDecoration(
              isDense: true, labelText: l10n.returnReasonNoteLabel),
        ),
      ],
    );
  }

  Widget _settlementBlock(AppLocalizations l10n, bool fullyPaid, double total) {
    final options = <(CreditSettlement, String)>[
      if (!fullyPaid)
        (
          CreditSettlement.reduceInvoice,
          l10n.returnSettlementReduceInvoice(
              '$_sym${_inv.outstandingBalance.toStringAsFixed(2)}')
        ),
      (CreditSettlement.refund, l10n.returnSettlementRefundNow),
      (CreditSettlement.customerCredit, l10n.returnSettlementKeepCredit),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.returnSettlementLabel,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        for (final o in options)
          RadioListTile<CreditSettlement>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: o.$1,
            groupValue: _settlement,
            onChanged: (v) => setState(() => _settlement = v!),
            title: Text(o.$2, style: const TextStyle(fontSize: 13.5)),
          ),
        if (_settlement == CreditSettlement.refund) ...[
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _refundMethod,
            decoration: InputDecoration(
                isDense: true, labelText: l10n.returnRefundMethodLabel),
            items: [
              for (final m in _refundMethods)
                DropdownMenuItem(
                    value: m, child: Text(refundMethodLabel(l10n, m))),
            ],
            onChanged: (v) =>
                setState(() => _refundMethod = v ?? _refundMethods.first),
          ),
        ],
      ],
    );
  }
}
