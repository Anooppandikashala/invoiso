import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_payment.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/services/payment_receipt_service.dart';
import 'package:invoiso/utils/app_date.dart';

String _paymentMethodLabel(AppLocalizations l10n, String method) {
  switch (method) {
    case 'Cash':
      return l10n.paymentMethodCash;
    case 'Bank Transfer':
      return l10n.paymentMethodBankTransfer;
    case 'Check':
      return l10n.paymentMethodCheck;
    case 'Online':
      return l10n.paymentMethodOnline;
    default:
      return l10n.paymentMethodOther;
  }
}

class ApplyPaymentDialog extends ConsumerStatefulWidget {
  final Invoice invoice;
  final VoidCallback onPaymentRecorded;

  const ApplyPaymentDialog({
    super.key,
    required this.invoice,
    required this.onPaymentRecorded,
  });

  @override
  ConsumerState<ApplyPaymentDialog> createState() => _ApplyPaymentDialogState();
}

class _ApplyPaymentDialogState extends ConsumerState<ApplyPaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  String? _selectedMethod;
  bool _isSaving = false;
  bool _isLoadingPayments = true;
  List<InvoicePayment> _payments = [];

  static const _methods = ['Cash', 'Bank Transfer', 'Check', 'Online', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    final payments = await ref
        .read(paymentRepositoryProvider)
        .getPaymentsForInvoice(widget.invoice.id);
    if (mounted) {
      setState(() {
        _payments = payments;
        _isLoadingPayments = false;
        _amountController.text = _outstanding.toStringAsFixed(2);
      });
    }
  }

  double get _totalPaid => _payments.fold(0.0, (s, p) => s + p.amountPaid);
  double get _outstanding => InvoiceCalculator.outstanding(
      total: widget.invoice.total, paid: _totalPaid);
  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;
  double get _taxOnEnteredAmount {
    if (widget.invoice.total <= 0) return 0.0;
    return _enteredAmount * (widget.invoice.tax / widget.invoice.total);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      await ref.read(paymentRepositoryProvider).addPayment(
            invoice: widget.invoice,
            amountPaid: _enteredAmount,
            datePaid: _selectedDate,
            paymentMethod: _selectedMethod,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      widget.onPaymentRecorded();
      await _loadPayments();
      _notesController.clear();

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_outstanding <= InvoiceCalculator.moneyEpsilon
                ? l10n.paymentDialogFullyPaidExclaimMessage
                : l10n.paymentDialogRecordedMessage(
                    widget.invoice.currencySymbol,
                    _outstanding.toStringAsFixed(2))),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(l10n.paymentDialogRecordFailedMessage(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePayment(InvoicePayment payment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l10n.paymentDialogDeleteTitle),
        content:
            Text(l10n.paymentDialogDeleteConfirmBody(payment.receiptNumber)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(paymentRepositoryProvider).deletePayment(payment.id);
    widget.onPaymentRecorded();
    await _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sym = widget.invoice.currencySymbol;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              decoration: BoxDecoration(
                color: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.actionRecordPayment,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                          l10n.paymentDialogInvoiceRefLabel(
                              widget.invoice.invoiceNumber ?? widget.invoice.id,
                              widget.invoice.customer.name),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        PaymentSummaryCard(
                          label: l10n.paymentDialogInvoiceTotalLabel,
                          value:
                              '$sym ${widget.invoice.total.toStringAsFixed(2)}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        PaymentSummaryCard(
                          label: l10n.paymentDialogAmountPaidLabel,
                          value: '$sym ${_totalPaid.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        PaymentSummaryCard(
                          label: l10n.dashboardOutstandingLabel,
                          value: '$sym ${_outstanding.toStringAsFixed(2)}',
                          color: _outstanding <= InvoiceCalculator.moneyEpsilon
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(l10n.paymentDialogHistoryTitle,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 8),

                    if (_isLoadingPayments)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
                    else if (_payments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Center(
                          child: Text(l10n.paymentDialogNoPaymentsMessage,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ),
                      )
                    else
                      _buildPaymentHistoryTable(sym, l10n),

                    // Paid-in-full banner
                    if (!_isLoadingPayments &&
                        _outstanding <= InvoiceCalculator.moneyEpsilon) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.paymentDialogFullyPaidBannerLabel,
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],

                    // New payment form (only if outstanding > 0)
                    if (!_isLoadingPayments &&
                        _outstanding > InvoiceCalculator.moneyEpsilon) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(l10n.paymentDialogNewPaymentTitle,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    decoration: InputDecoration(
                                      labelText: l10n
                                          .paymentDialogAmountFieldLabel(sym),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      helperText:
                                          l10n.paymentDialogMaxHelperText(sym,
                                              _outstanding.toStringAsFixed(2)),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) {
                                      final n =
                                          double.tryParse(v?.trim() ?? '');
                                      if (n == null || n <= 0) {
                                        return l10n
                                            .paymentDialogInvalidAmountError;
                                      }
                                      if (n >
                                          _outstanding +
                                              InvoiceCalculator.moneyEpsilon) {
                                        return l10n
                                            .paymentDialogExceedsOutstandingError;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickDate,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: l10n.invoiceMgmtColDate,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        suffixIcon: const Icon(
                                            Icons.calendar_today,
                                            size: 18),
                                      ),
                                      child: Text(
                                        '${_selectedDate.year}-'
                                        '${_selectedDate.month.toString().padLeft(2, '0')}-'
                                        '${_selectedDate.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedMethod,
                                    decoration: InputDecoration(
                                      labelText:
                                          l10n.paymentDialogMethodFieldLabel,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    hint: Text(
                                        l10n.paymentDialogSelectMethodHint),
                                    items: _methods
                                        .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(
                                                _paymentMethodLabel(l10n, m))))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedMethod = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText:
                                          l10n.paymentDialogTaxCoveredLabel,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      fillColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      filled: true,
                                      helperText: l10n
                                          .paymentDialogAutoCalculatedHelper,
                                    ),
                                    child: Text(
                                      '$sym ${_taxOnEnteredAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: l10n.paymentDialogNotesFieldLabel,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                hintText: l10n.paymentDialogNotesHint,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.actionClose),
                  ),
                  if (!_isLoadingPayments &&
                      _outstanding > InvoiceCalculator.moneyEpsilon) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _savePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isSaving
                          ? l10n.createInvoiceSavingEllipsisLabel
                          : l10n.actionRecordPayment),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryTable(String sym, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 130,
                    child: Text(l10n.paymentDialogReceiptColLabel,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 90,
                    child: Text(l10n.invoiceMgmtColDate,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(
                    child: Text(l10n.labelAmount,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(
                    child: Text(l10n.paymentDialogTaxCoveredLabel,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 100,
                    child: Text(l10n.paymentDialogMethodColLabel,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                const SizedBox(width: 72),
              ],
            ),
          ),
          ..._payments.map((p) => _buildPaymentRow(p, sym, l10n)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
      InvoicePayment payment, String sym, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              payment.receiptNumber,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              AppDate.format(payment.datePaid),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              '$sym ${payment.amountPaid.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.green),
            ),
          ),
          Expanded(
            child: Text(
              '$sym ${payment.taxAmountPaid.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              payment.paymentMethod == null
                  ? '—'
                  : _paymentMethodLabel(l10n, payment.paymentMethod!),
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: l10n.paymentDialogDownloadReceiptTooltip,
                  child: InkWell(
                    onTap: () => PaymentReceiptService.printOrDownload(
                        context, widget.invoice, payment),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.download_outlined,
                          size: 17, color: Colors.indigo[400]),
                    ),
                  ),
                ),
                Tooltip(
                  message: l10n.paymentDialogDeletePaymentTooltip,
                  child: InkWell(
                    onTap: () => _deletePayment(payment),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 17, color: Colors.red[400]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const PaymentSummaryCard(
      {super.key,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
