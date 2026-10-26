import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/refund.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/services/refund_receipt_service.dart';
import 'package:invoiso/widgets/return_l10n.dart';

const _methods = <String>['Cash', 'Bank Transfer', 'Check', 'Online', 'Other'];

/// Records a cash/bank refund against a credit note that still has unused
/// customer credit, then offers to print the refund voucher.
class RecordRefundDialog extends ConsumerStatefulWidget {
  final Invoice creditNote;
  final VoidCallback onRefunded;

  const RecordRefundDialog({
    super.key,
    required this.creditNote,
    required this.onRefunded,
  });

  @override
  ConsumerState<RecordRefundDialog> createState() => _RecordRefundDialogState();
}

class _RecordRefundDialogState extends ConsumerState<RecordRefundDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = _methods.first;
  final DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  double _remaining = 0;

  String get _sym => widget.creditNote.currencySymbol;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cn = widget.creditNote;
    final remaining = await ref
        .read(returnRepositoryProvider)
        .getRemainingCustomerCredit(
          customerId: cn.customer.id,
          customerName: cn.customer.name,
          currencyCode: cn.currencyCode,
        );
    if (!mounted) return;
    setState(() {
      _remaining = remaining;
      _amountCtrl.text = remaining.toStringAsFixed(2);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= InvoiceCalculator.moneyEpsilon ||
        amount > _remaining + InvoiceCalculator.moneyEpsilon) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.refundValidationRange(
              '$_sym${_remaining.toStringAsFixed(2)}'))));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(returnRepositoryProvider);
      final Refund refund = await repo.recordRefund(
        creditNote: widget.creditNote,
        amount: amount,
        date: _date,
        method: _method,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      widget.onRefunded();
      final remainingAfter = await repo.getRemainingCustomerCredit(
        customerId: widget.creditNote.customer.id,
        customerName: widget.creditNote.customer.name,
        currencyCode: widget.creditNote.currencyCode,
      );
      if (!mounted) return;
      // The snackbar outlives this dialog; print with the navigator's context.
      final hostContext = Navigator.of(context).context;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n
            .refundRecordedMessage('$_sym${amount.toStringAsFixed(2)}')),
        action: SnackBarAction(
          label: l10n.returnPrintVoucher,
          onPressed: () => RefundReceiptService.preview(
              hostContext, widget.creditNote, refund,
              remainingCredit: remainingAfter),
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.refundRecordError('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.refundDialogTitle(
          widget.creditNote.invoiceNumber ?? widget.creditNote.id)),
      content: SizedBox(
        width: 360,
        child: _loading
            ? const SizedBox(
                height: 90, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      l10n.refundAvailableCredit(
                          '$_sym${_remaining.toStringAsFixed(2)}'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                        isDense: true, labelText: l10n.refundAmountLabel),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _method,
                    decoration: InputDecoration(
                        isDense: true, labelText: l10n.refundMethodLabel),
                    items: [
                      for (final m in _methods)
                        DropdownMenuItem(
                            value: m, child: Text(refundMethodLabel(l10n, m))),
                    ],
                    onChanged: (v) =>
                        setState(() => _method = v ?? _methods.first),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(
                        isDense: true, labelText: l10n.refundNotesLabel),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving || _loading ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.refundRecordButton),
        ),
      ],
    );
  }
}
