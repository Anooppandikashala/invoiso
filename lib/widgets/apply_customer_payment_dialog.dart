import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/utils/app_date.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart' show PaymentSummaryCard;

/// Applies one payment across several of a customer's open invoices —
/// smallest outstanding balance first by default, editable per invoice
/// before applying.
class ApplyCustomerPaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;
  final VoidCallback onPaymentApplied;

  const ApplyCustomerPaymentDialog({
    super.key,
    required this.customer,
    required this.onPaymentApplied,
  });

  @override
  ConsumerState<ApplyCustomerPaymentDialog> createState() =>
      _ApplyCustomerPaymentDialogState();
}

class _ApplyCustomerPaymentDialogState extends ConsumerState<ApplyCustomerPaymentDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Invoice> _openInvoices = [];
  String? _selectedCurrency;
  final Map<String, TextEditingController> _rowControllers = {};
  final _autoFillController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedMethod;

  static const _methods = ['Cash', 'Bank Transfer', 'Check', 'Online', 'Other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    _autoFillController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final invoices =
        await ref.read(invoiceRepositoryProvider).getOpenInvoicesForCustomer(widget.customer.id);
    if (!mounted) return;
    setState(() {
      _openInvoices = invoices;
      _selectedCurrency = invoices.isEmpty ? null : invoices.first.currencyCode;
      _isLoading = false;
      for (final inv in invoices) {
        _rowControllers[inv.id] = TextEditingController(text: '0.00');
      }
    });
  }

  List<String> get _currencies =>
      _openInvoices.map((i) => i.currencyCode).toSet().toList()..sort();

  List<Invoice> get _invoicesForCurrency =>
      _openInvoices.where((i) => i.currencyCode == _selectedCurrency).toList();

  double get _totalOutstanding =>
      _invoicesForCurrency.fold(0.0, (s, i) => s + i.outstandingBalance);

  double get _totalAllocated => _invoicesForCurrency.fold(
      0.0, (s, i) => s + (double.tryParse(_rowControllers[i.id]?.text.trim() ?? '') ?? 0.0));

  // Smallest outstanding balance first, so a limited payment clears as many
  // whole invoices as possible instead of leaving several partially paid.
  void _autoFillSmallestFirst() {
    var remaining = double.tryParse(_autoFillController.text.trim()) ?? 0.0;
    if (remaining <= 0) return;
    final bySmallest = [..._invoicesForCurrency]
      ..sort((a, b) => a.outstandingBalance.compareTo(b.outstandingBalance));
    setState(() {
      for (final inv in bySmallest) {
        final alloc = remaining <= 0 ? 0.0 : remaining.clamp(0.0, inv.outstandingBalance);
        _rowControllers[inv.id]?.text = alloc.toStringAsFixed(2);
        remaining -= alloc;
      }
    });
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

  Future<void> _apply() async {
    final allocations = <({Invoice invoice, double amount})>[];
    for (final inv in _invoicesForCurrency) {
      final amount = double.tryParse(_rowControllers[inv.id]?.text.trim() ?? '') ?? 0.0;
      if (amount > InvoiceCalculator.moneyEpsilon) {
        if (amount > inv.outstandingBalance + InvoiceCalculator.moneyEpsilon) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Amount for ${inv.invoiceNumber ?? inv.id} exceeds its outstanding balance.'),
            backgroundColor: Colors.red,
          ));
          return;
        }
        allocations.add((invoice: inv, amount: amount));
      }
    }
    if (allocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter an amount for at least one invoice.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await ref.read(paymentRepositoryProvider).applyPaymentAcrossInvoices(
            allocations: allocations,
            datePaid: _selectedDate,
            paymentMethod: _selectedMethod,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      widget.onPaymentApplied();
      if (!mounted) return;
      final sym = _invoicesForCurrency.first.currencySymbol;
      final total = saved.fold(0.0, (s, p) => s + p.amountPaid);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Applied $sym ${total.toStringAsFixed(2)} across ${saved.length} invoice${saved.length == 1 ? '' : 's'}.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to apply payment: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  const Icon(Icons.payments_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Receive Payment',
                            style: TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(widget.customer.name,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _openInvoices.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('No open invoices for this customer.',
                              style:
                                  TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_currencies.length > 1) ...[
                                DropdownButtonFormField<String>(
                                  value: _selectedCurrency,
                                  decoration: InputDecoration(
                                    labelText: 'Currency',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  items: _currencies
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _selectedCurrency = v);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              Row(
                                children: [
                                  PaymentSummaryCard(
                                    label: 'Total Outstanding',
                                    value:
                                        '${_invoicesForCurrency.first.currencySymbol} ${_totalOutstanding.toStringAsFixed(2)}',
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  PaymentSummaryCard(
                                    label: 'Total Allocated',
                                    value:
                                        '${_invoicesForCurrency.first.currencySymbol} ${_totalAllocated.toStringAsFixed(2)}',
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _autoFillController,
                                      decoration: InputDecoration(
                                        labelText:
                                            'Amount Received (${_invoicesForCurrency.first.currencySymbol})',
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                        helperText: 'Auto-allocates smallest invoice first',
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: FilledButton.tonal(
                                      onPressed: _autoFillSmallestFirst,
                                      child: const Text('Auto-allocate'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                  'Open Invoices (oldest first) — ${_invoicesForCurrency.length}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              // Bounded + virtualized so a customer with many
                              // open invoices doesn't push the date/method/
                              // notes fields and Apply button out of easy
                              // reach — this scrolls independently instead of
                              // growing the whole dialog.
                              SizedBox(
                                height: _invoicesForCurrency.length.clamp(1, 5) * 68.0,
                                child: ListView.builder(
                                  itemCount: _invoicesForCurrency.length,
                                  itemBuilder: (context, i) =>
                                      _buildInvoiceRow(_invoicesForCurrency[i]),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickDate,
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Date',
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                          suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                        ),
                                        child: Text(AppDate.format(_selectedDate)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedMethod,
                                      decoration: InputDecoration(
                                        labelText: 'Payment Method',
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                      ),
                                      hint: const Text('Select method'),
                                      items: _methods
                                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                          .toList(),
                                      onChanged: (v) => setState(() => _selectedMethod = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                decoration: InputDecoration(
                                  labelText: 'Reference / Notes (optional)',
                                  border:
                                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  hintText: 'e.g. cheque no., transaction ID...',
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  if (!_isLoading && _openInvoices.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isSaving ? 'Applying...' : 'Apply Payment'),
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

  Widget _buildInvoiceRow(Invoice inv) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.invoiceNumber ?? inv.id,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(AppDate.format(inv.date),
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${inv.currencySymbol} ${inv.outstandingBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Colors.orange)),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _rowControllers[inv.id],
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}
