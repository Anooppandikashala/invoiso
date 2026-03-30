import 'package:flutter/material.dart';
import 'package:invoiso/database/payment_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_payment.dart';
import 'package:invoiso/services/payment_receipt_service.dart';

class ApplyPaymentDialog extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback onPaymentRecorded;

  const ApplyPaymentDialog({
    super.key,
    required this.invoice,
    required this.onPaymentRecorded,
  });

  @override
  State<ApplyPaymentDialog> createState() => _ApplyPaymentDialogState();
}

class _ApplyPaymentDialogState extends State<ApplyPaymentDialog> {
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
    final payments =
        await PaymentService.getPaymentsForInvoice(widget.invoice.id);
    if (mounted) {
      setState(() {
        _payments = payments;
        _isLoadingPayments = false;
        _amountController.text = _outstanding.toStringAsFixed(2);
      });
    }
  }

  double get _totalPaid => _payments.fold(0.0, (s, p) => s + p.amountPaid);
  double get _outstanding =>
      (widget.invoice.total - _totalPaid).clamp(0.0, double.infinity);
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
    setState(() => _isSaving = true);
    try {
      await PaymentService.addPayment(
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
            content: Text(_outstanding <= 0
                ? 'Invoice fully paid!'
                : 'Payment recorded. Outstanding: ${widget.invoice.currencySymbol} ${_outstanding.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to record payment: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePayment(InvoicePayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Payment'),
        content: Text(
            'Delete receipt ${payment.receiptNumber}?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await PaymentService.deletePayment(payment.id);
    widget.onPaymentRecorded();
    await _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: theme.primaryColor,
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
                        const Text('Record Payment',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                          '#${widget.invoice.id} — ${widget.invoice.customer.name}',
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
                          label: 'Invoice Total',
                          value: '$sym ${widget.invoice.total.toStringAsFixed(2)}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        PaymentSummaryCard(
                          label: 'Amount Paid',
                          value: '$sym ${_totalPaid.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        PaymentSummaryCard(
                          label: 'Outstanding',
                          value: '$sym ${_outstanding.toStringAsFixed(2)}',
                          color: _outstanding <= 0 ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text('Payment History',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800])),
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
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: const Center(
                          child: Text('No payments recorded yet',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      _buildPaymentHistoryTable(sym),

                    // Paid-in-full banner
                    if (!_isLoadingPayments && _outstanding <= 0) ...[
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Invoice fully paid',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],

                    // New payment form (only if outstanding > 0)
                    if (!_isLoadingPayments && _outstanding > 0) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text('New Payment',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800])),
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
                                      labelText: 'Amount ($sym)',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      helperText:
                                          'Max: $sym ${_outstanding.toStringAsFixed(2)}',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) {
                                      final n =
                                          double.tryParse(v?.trim() ?? '');
                                      if (n == null || n <= 0) {
                                        return 'Enter a valid amount';
                                      }
                                      if (n > _outstanding + 0.005) {
                                        return 'Exceeds outstanding balance';
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
                                        labelText: 'Date',
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
                                      labelText: 'Payment Method',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    hint: const Text('Select method'),
                                    items: _methods
                                        .map((m) => DropdownMenuItem(
                                            value: m, child: Text(m)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedMethod = v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Tax Covered',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      fillColor: Colors.grey[50],
                                      filled: true,
                                      helperText: 'Auto-calculated',
                                    ),
                                    child: Text(
                                      '$sym ${_taxOnEnteredAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: 'Reference / Notes (optional)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                hintText: 'e.g. cheque no., transaction ID...',
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
                    child: const Text('Close'),
                  ),
                  if (!_isLoadingPayments && _outstanding > 0) ...[
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
                      label: Text(_isSaving ? 'Saving...' : 'Record Payment'),
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

  Widget _buildPaymentHistoryTable(String sym) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                    width: 130,
                    child: Text('Receipt #',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 90,
                    child: Text('Date',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(
                    child: Text('Amount',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(
                    child: Text('Tax Covered',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 100,
                    child: Text('Method',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(width: 72),
              ],
            ),
          ),
          ..._payments.map((p) => _buildPaymentRow(p, sym)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(InvoicePayment payment, String sym) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
              payment.datePaid.toString().split(' ')[0],
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
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              payment.paymentMethod ?? '—',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Download receipt',
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
                  message: 'Delete payment',
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
      {super.key, required this.label, required this.value, required this.color});

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
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
