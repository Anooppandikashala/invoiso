import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/providers/returns_settings_provider.dart';
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

/// Stamped on a credit note that puts at least one line back into stock.
const salesReturnTitle = 'Credit Note (Sales Return)';

/// Full-screen page that creates a Credit Note (sales return) against
/// [invoice]. Pick returned lines + quantities, choose how the value is
/// settled, and (optionally) pay a refund straight away. Built for invoices
/// with many lines: searchable lazy list, totals/settlement always visible.
class CreateReturnScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  final VoidCallback onCreated;

  const CreateReturnScreen({
    super.key,
    required this.invoice,
    required this.onCreated,
  });

  @override
  ConsumerState<CreateReturnScreen> createState() => _CreateReturnScreenState();
}

class _CreateReturnScreenState extends ConsumerState<CreateReturnScreen> {
  final _qtyCtrls = <String, TextEditingController>{};
  final _restock = <String, bool>{};
  final _reasonNoteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _onlySelected = false;

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
    _searchCtrl.dispose();
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
    // The voucher snackbar outlives this page; use the navigator's context
    // (still mounted after pop) for its print action.
    final hostContext = Navigator.of(context).context;
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
        invoiceTitle: lines.any((l) => l.restocked) ? salesReturnTitle : null,
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
            onPressed: () => RefundReceiptService.preview(
                hostContext, cn, refund,
                remainingCredit: remaining),
          );
        }
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
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

  /// Lines shown in the list: search on product name / HSN, optionally only
  /// lines with a return quantity entered.
  List<InvoiceItem> _visibleItems() {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _inv.items.where((i) {
      if (_onlySelected && _enteredQty(i) <= 0) return false;
      if (q.isEmpty) return true;
      return i.product.name.toLowerCase().contains(q) ||
          i.product.hsncode.toLowerCase().contains(q);
    }).toList();
  }

  bool get _hasEntries =>
      _qtyCtrls.values.any((c) => c.text.trim().isNotEmpty);

  /// "Return all" / "Clear" act on the lines currently shown.
  void _fillVisible(List<InvoiceItem> items, {required bool all}) {
    setState(() {
      for (final i in items) {
        final left = _returnableQty(i);
        _qtyCtrls[i.id]!.text = all && left > 0 ? _fmtQty(left) : '';
      }
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasEntries) return true;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.returnDiscardTitle),
        content: Text(l10n.returnDiscardBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionDiscard)),
        ],
      ),
    );
    return ok ?? false;
  }

  // Same look as the create-invoice V2 screen: flat outlined cards on the
  // scaffold background, uppercase section labels, outlined filled fields.
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      );

  InputDecoration _fieldDecoration({String? label, String? hint, Widget? prefixIcon}) {
    final radius = BorderRadius.circular(AppBorderRadius.xsmall);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      isDense: true,
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _countChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = _loading ? <InvoiceItem>[] : _returnLines();
    final draft = _draft(lines);
    final fullyPaid = _inv.outstandingBalance <= InvoiceCalculator.moneyEpsilon;
    final number = _inv.invoiceNumber ?? _inv.id;
    final title = ref.watch(returnsEnabledProvider)
        ? l10n.returnScreenTitleSalesReturn(number)
        : l10n.returnScreenTitleReturnItems(number);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _saving) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(l10n.returnCustomerLabel(_inv.customer.name),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.normal)),
            ],
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(AppPadding.small),
                child: LayoutBuilder(builder: (context, constraints) {
                  // Same breakpoint as the create-invoice V2 screen.
                  final wide = constraints.maxWidth >= 980;
                  final itemsCard =
                      _itemsCard(l10n, lines.length, draft.total,
                          constraints.maxWidth >= 600);
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(l10n.returnReasonLabel),
                      _reasonBlock(l10n),
                      const SizedBox(height: 18),
                      _settlementBlock(l10n, fullyPaid, draft.total),
                    ],
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: itemsCard),
                        AppSpacing.wSmall,
                        SizedBox(
                          width: Platform.isAndroid ? 300 : 420,
                          child: Container(
                            decoration: _cardDecoration(),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding:
                                        const EdgeInsets.all(AppPadding.medium),
                                    child: details,
                                  ),
                                ),
                                _totalsFooter(l10n, draft),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: itemsCard),
                      AppSpacing.hSmall,
                      Container(
                        decoration: _cardDecoration(),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ExpansionTile(
                              title: _sectionLabel(l10n.returnDetailsSection),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                  AppPadding.medium, 0, AppPadding.medium,
                                  AppPadding.medium),
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxHeight: constraints.maxHeight * 0.45),
                                  child: SingleChildScrollView(child: details),
                                ),
                              ],
                            ),
                            _totalsFooter(l10n, draft),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
      ),
    );
  }

  Widget _itemsCard(
      AppLocalizations l10n, int selected, double total, bool table) {
    final items = _visibleItems();
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ITEMS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
              const SizedBox(width: 10),
              _countChip(AppLocalizations.of(context)!
                  .dashboardItemCountLabel(_inv.items.length)),
              const Spacer(),
              if (selected > 0)
                Text(
                  l10n.returnSelectedCount(
                      selected, '$_sym${total.toStringAsFixed(2)}'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _toolbar(l10n, items),
          const SizedBox(height: 12),
          if (table) _headerRow(l10n),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => _lineRow(l10n, items[i], table),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(AppLocalizations l10n, List<InvoiceItem> items) {
    final buttonShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchCtrl,
            decoration: _fieldDecoration(
                hint: l10n.returnSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20)),
            onChanged: (_) => setState(() {}),
          ),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              shape: buttonShape,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
          onPressed: () => _fillVisible(items, all: true),
          icon: const Icon(Icons.done_all, size: 18),
          label: Text(l10n.returnAllButton),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              shape: buttonShape,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
          onPressed: () => _fillVisible(items, all: false),
          icon: const Icon(Icons.clear_all, size: 18),
          label: Text(l10n.actionClear),
        ),
        FilterChip(
          label: Text(l10n.returnOnlySelectedChip),
          selected: _onlySelected,
          shape: buttonShape,
          onSelected: (v) => setState(() => _onlySelected = v),
        ),
      ],
    );
  }

  Widget _headerRow(AppLocalizations l10n) {
    final style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget num(String t) => SizedBox(
        width: 72,
        child: Text(t.toUpperCase(), style: style, textAlign: TextAlign.end));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text(l10n.invoiceMgmtColSlNo.toUpperCase(), style: style)),
          Expanded(child: Text(l10n.returnColProduct.toUpperCase(), style: style)),
          num(l10n.returnColSold),
          num(l10n.returnColReturned),
          num(l10n.returnColLeft),
          const SizedBox(width: 20),
          SizedBox(
              width: 128,
              child: Text(l10n.returnFieldReturn.toUpperCase(),
                  style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 72,
              child: Text(l10n.returnColToStock.toUpperCase(),
                  style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _lineRow(AppLocalizations l10n, InvoiceItem item, bool table) {
    final returnable = _returnableQty(item);
    final prior = _alreadyReturned[item.product.id] ?? 0.0;
    final selected = _enteredQty(item) > 0;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final entered = _enteredQty(item);
    // Step the return qty by 1, kept within 0..returnable.
    void step(double delta) {
      final next = (entered + delta).clamp(0.0, returnable);
      setState(() => _qtyCtrls[item.id]!.text = next > 0 ? _fmtQty(next) : '');
    }
    Widget stepButton(IconData icon, VoidCallback? onPressed) => IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          color: Theme.of(context).primaryColor,
        );
    final qtyInput = SizedBox(
      width: 64,
      child: TextField(
        controller: _qtyCtrls[item.id],
        enabled: returnable > 0,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          // Never more than what's left to return on this line.
          TextInputFormatter.withFunction((oldValue, newValue) {
            final v = double.tryParse(newValue.text);
            return v != null && v > returnable + InvoiceCalculator.moneyEpsilon
                ? oldValue
                : newValue;
          }),
        ],
        style: const TextStyle(fontSize: 14),
        decoration: _fieldDecoration(
                label: table ? null : l10n.returnFieldReturn, hint: '0')
            .copyWith(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
        onChanged: (_) => setState(() {}),
      ),
    );
    final qtyField = SizedBox(
      width: 128,
      child: Row(
        children: [
          stepButton(Icons.remove_circle_outline,
              returnable > 0 && entered > 0 ? () => step(-1) : null),
          qtyInput,
          stepButton(Icons.add_circle_outline,
              entered < returnable ? () => step(1) : null),
        ],
      ),
    );
    final stockBox = SizedBox(
      width: 72,
      child: Tooltip(
        message: l10n.returnToStockTooltip,
        child: Checkbox(
          value: _restock[item.id] ?? true,
          onChanged: returnable > 0
              ? (v) => setState(() => _restock[item.id] = v ?? true)
              : null,
        ),
      ),
    );
    final name = Text(item.product.name,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: AppFontSize.medium,
            fontWeight: FontWeight.bold,
            color: returnable > 0 ? null : muted));
    // HSN · unit price / unit · tax % · discount, as on the original invoice.
    String pct(double v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';
    final taxRate = switch (_inv.taxMode) {
      TaxMode.perItem => item.product.tax_rate.toDouble(),
      TaxMode.global => _inv.taxRate * 100,
      TaxMode.none => 0.0,
    };
    final info = [
      if (item.product.hsncode.trim().isNotEmpty)
        '${l10n.productMgmtHsnSacLabel} ${item.product.hsncode.trim()}',
      '$_sym${item.effectivePrice.toStringAsFixed(2)}'
          '${item.effectiveUnit.isNotEmpty ? ' / ${item.effectiveUnit}' : ''}',
      if (taxRate > 0) '${l10n.fieldTaxLabel} ${pct(taxRate)}%',
      if (item.totalDiscount > 0)
        '${l10n.fieldDiscountLabel} −$_sym${item.totalDiscount.toStringAsFixed(2)}',
    ].join('  ·  ');
    final infoText = Text(info,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: muted));
    // Line's position on the original invoice — stays the same when filtered.
    final slNo = SizedBox(
        width: 48,
        child: Text('${_inv.items.indexOf(item) + 1}',
            style: TextStyle(color: muted)));
    final decoration = BoxDecoration(
      color: selected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.06)
          : null,
      border: Border(
          bottom:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
    );
    if (table) {
      Widget num(double v) => SizedBox(
          width: 72,
          child: Text(_fmtQty(v),
              textAlign: TextAlign.end,
              style: TextStyle(color: returnable > 0 ? null : muted)));
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: decoration,
        child: Row(
          children: [
            slNo,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [name, infoText],
              ),
            ),
            num(_soldQty(item)),
            num(prior),
            num(returnable),
            const SizedBox(width: 20),
            qtyField,
            stockBox,
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: decoration,
      child: Row(
        children: [
          slNo,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                name,
                infoText,
                Text(
                  '${l10n.returnLineSold(_fmtQty(_soldQty(item)))}'
                  '${prior > 0 ? '  ·  ${l10n.returnLineReturned(_fmtQty(prior))}' : ''}'
                  '  ·  ${l10n.returnLineLeft(_fmtQty(returnable))}',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          qtyField,
          stockBox,
        ],
      ),
    );
  }

  // Totals + Create button pinned at the bottom of the side panel, styled
  // like the create-invoice totals footer (green bold total).
  Widget _totalsFooter(AppLocalizations l10n, Invoice draft) {
    Widget row(String label, double value, {bool total = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label:',
                  style: TextStyle(
                      fontSize: total ? 18 : 14,
                      fontWeight: total ? FontWeight.bold : FontWeight.normal,
                      color: total ? Colors.green : null)),
              Text('$_sym${value.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: total ? 20 : 14,
                      fontWeight: FontWeight.bold,
                      color: total ? Colors.green : null)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(l10n.returnSubtotalLabel, draft.subtotal),
          if (draft.tax > 0) row(l10n.fieldTaxLabel, draft.tax),
          const SizedBox(height: 8),
          row(l10n.returnTotalLabel, draft.total, total: true),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.assignment_return_outlined),
            label: Text(l10n.returnCreateButton,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _reasonBlock(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _reason,
          decoration: _fieldDecoration(label: l10n.returnReasonLabel),
          items: [
            for (final r in _returnReasons)
              DropdownMenuItem(value: r, child: Text(returnReasonLabel(l10n, r))),
          ],
          onChanged: (v) => setState(() => _reason = v ?? _returnReasons.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonNoteCtrl,
          decoration: _fieldDecoration(label: l10n.returnReasonNoteLabel),
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
        _sectionLabel(l10n.returnSettlementLabel),
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
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _refundMethod,
            decoration: _fieldDecoration(label: l10n.returnRefundMethodLabel),
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
