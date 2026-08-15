import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/domain/purchase_bill_calculator.dart';
import 'package:invoiso/domain/purchase_bill_totals_calculator.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/models/supplier.dart';
import 'package:invoiso/models/supplier_payment.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/product_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/supplier_provider.dart';
import 'package:invoiso/utils/app_date.dart';
import 'package:invoiso/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────
// Top-level screen — owns the list<->form toggle. No new dashboard index
// needed for the form; it's an internal widget swap (see plan doc).
class PurchaseBillManagementScreen extends ConsumerStatefulWidget {
  final User user;
  const PurchaseBillManagementScreen({super.key, required this.user});

  @override
  ConsumerState<PurchaseBillManagementScreen> createState() =>
      _PurchaseBillManagementScreenState();
}

class _PurchaseBillManagementScreenState
    extends ConsumerState<PurchaseBillManagementScreen> {
  bool _showingForm = false;
  PurchaseBill? _billToEdit;

  void _openNewBillForm() {
    setState(() {
      _billToEdit = null;
      _showingForm = true;
    });
  }

  void _openEditBillForm(PurchaseBill bill) {
    setState(() {
      _billToEdit = bill;
      _showingForm = true;
    });
  }

  void _closeForm() {
    setState(() {
      _showingForm = false;
      _billToEdit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showingForm) {
      return _PurchaseBillFormScreen(
        key: ValueKey('purchase_bill_form_${_billToEdit?.id ?? 'new'}'),
        billToEdit: _billToEdit,
        onDone: _closeForm,
      );
    }
    return _PurchaseBillListView(
      user: widget.user,
      onNew: _openNewBillForm,
      onEdit: _openEditBillForm,
    );
  }
}

// ─────────────────────────────────────────────
// List view: paginated table, search, soft-delete + trash.
class _PurchaseBillListView extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback onNew;
  final ValueChanged<PurchaseBill> onEdit;

  const _PurchaseBillListView({
    required this.user,
    required this.onNew,
    required this.onEdit,
  });

  @override
  ConsumerState<_PurchaseBillListView> createState() => _PurchaseBillListViewState();
}

class _PurchaseBillListViewState extends ConsumerState<_PurchaseBillListView> {
  List<PurchaseBill> _bills = [];
  Map<String, double> _paidTotals = {};
  int _totalCount = 0;
  int _currentPage = 0;
  int _pageSize = 10;
  String _searchQuery = '';
  bool _isLoading = false;
  String _currencySymbol = '₹';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _loadPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    final currency = await ref.read(settingsRepositoryProvider).getCurrency();
    if (mounted) setState(() => _currencySymbol = currency.symbol);
  }

  int get _totalPages => (_totalCount / _pageSize).ceil();

  Future<void> _loadPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final billRepo = ref.read(purchaseBillRepositoryProvider);
      final results = await Future.wait([
        billRepo.getPurchaseBillsPaginated(
          page: _currentPage,
          pageSize: _pageSize,
          searchQuery: _searchQuery,
        ),
        billRepo.getPurchaseBillCount(searchQuery: _searchQuery),
      ]);
      final bills = results[0] as List<PurchaseBill>;
      final count = results[1] as int;
      final paidTotals = bills.isEmpty
          ? <String, double>{}
          : await ref
              .read(supplierPaymentRepositoryProvider)
              .getTotalPaidBatch(bills.map((b) => b.id).toList());
      if (!mounted) return;
      setState(() {
        _bills = bills;
        _totalCount = count;
        _paidTotals = paidTotals;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppError.show(context, 'Failed to load purchase bills: $e', onRetry: _loadPage);
      }
    }
  }

  void _changePage(int page) {
    if (!mounted) return;
    setState(() => _currentPage = page);
    _loadPage();
  }

  Future<void> _editBill(PurchaseBill row) async {
    final full = await ref.read(purchaseBillRepositoryProvider).getPurchaseBillById(row.id);
    widget.onEdit(full ?? row);
  }

  Future<void> _viewBill(PurchaseBill row) async {
    final full = await ref.read(purchaseBillRepositoryProvider).getPurchaseBillById(row.id) ?? row;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _BillDetailDialog(
        bill: full,
        currencySymbol: _currencySymbol,
        onChanged: _loadPage,
        onEdit: () {
          Navigator.pop(ctx);
          widget.onEdit(full);
        },
      ), 
    );
  }

  Future<void> _softDelete(PurchaseBill bill) async {
    final confirmed = await AppError.confirm(
      context,
      title: 'Move to Trash',
      message: 'Move bill "${bill.billNumber ?? bill.id}" to trash? Stock will be reversed.',
      confirmLabel: 'Move to Trash',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    await ref.read(purchaseBillRepositoryProvider).softDeletePurchaseBill(bill.id);
    await _loadPage();
    if (mounted) AppError.showSuccess(context, 'Purchase bill moved to trash.');
  }

  void _showTrashDialog() async {
    final deleted = await ref.read(purchaseBillRepositoryProvider).getDeletedPurchaseBills();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _PurchaseBillTrashDialog(
        deletedBills: deleted,
        onRestored: _loadPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Bills'),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _showTrashDialog,
            tooltip: 'Trash',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPage,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onNew,
        icon: const Icon(Icons.add),
        label: const Text('New Purchase Bill'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildTableHeader(),
              _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _bills.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 900),
                                child: _buildDataTable(),
                              ),
                            ),
                          ),
              ),
              _buildPaginationControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            'Purchase Bills ($_totalCount)',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search by bill number or supplier...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 0;
                    });
                    _loadPage();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 0;
          });
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 400), _loadPage);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No purchase bills found',
              style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? 'Create your first purchase bill to get started' : 'Try adjusting your search',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columns: const [
        DataColumn(label: Text('Sl. No', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Bill #', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: List.generate(_bills.length, (index) {
        final bill = _bills[index];
        final serial = (_currentPage * _pageSize) + index + 1;
        final paid = _paidTotals[bill.id] ?? 0.0;
        final status = PurchaseBillCalculator.paymentStatus(total: bill.total, paid: paid);
        final outstanding = PurchaseBillCalculator.outstanding(total: bill.total, paid: paid);
        return DataRow(
          color: WidgetStateProperty.all(
            index.isEven ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          cells: [
            DataCell(Text(serial.toString())),
            DataCell(Text(bill.billNumber ?? '—', style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(bill.supplierName.isEmpty ? '—' : bill.supplierName)),
            DataCell(Text(AppDate.format(bill.billDate))),
            DataCell(Text('$_currencySymbol ${bill.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
            DataCell(_buildStatusChip(status)),
            DataCell(
              status == PaymentStatus.paid
                  ? Text('—', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                  : Text(
                      '$_currencySymbol ${outstanding.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: status == PaymentStatus.partial ? Colors.orange[700] : Colors.red[700],
                      ),
                    ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    color: Colors.blue,
                    onPressed: () => _viewBill(bill),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.orange,
                    onPressed: () => _editBill(bill),
                    tooltip: 'Edit',
                  ),
                  if (widget.user.isAdmin())
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => _softDelete(bill),
                      tooltip: 'Delete',
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    final Color color;
    final String label;
    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        label = 'Paid';
      case PaymentStatus.partial:
        color = Colors.orange;
        label = 'Partial';
      case PaymentStatus.unpaid:
        color = Colors.red;
        label = 'Unpaid';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = _totalPages == 0 ? 1 : _totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Rows per page:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox(),
                items: [10, 25, 50, 100].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                onChanged: (n) {
                  if (n == null) return;
                  setState(() {
                    _pageSize = n;
                    _currentPage = 0;
                  });
                  _loadPage();
                },
              ),
              const SizedBox(width: 16),
              Text('Total: $_totalCount', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Page ${_currentPage + 1} of $totalPages',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
              IconButton(
                onPressed: _currentPage < totalPages - 1 ? () => _changePage(_currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Trash Dialog (no permanent-delete — repository doesn't expose one)
class _PurchaseBillTrashDialog extends ConsumerStatefulWidget {
  final List<PurchaseBill> deletedBills;
  final VoidCallback onRestored;

  const _PurchaseBillTrashDialog({required this.deletedBills, required this.onRestored});

  @override
  ConsumerState<_PurchaseBillTrashDialog> createState() => _PurchaseBillTrashDialogState();
}

class _PurchaseBillTrashDialogState extends ConsumerState<_PurchaseBillTrashDialog> {
  late List<PurchaseBill> _bills;

  @override
  void initState() {
    super.initState();
    _bills = List.from(widget.deletedBills);
  }

  Future<void> _restore(PurchaseBill bill) async {
    await ref.read(purchaseBillRepositoryProvider).restorePurchaseBill(bill.id);
    setState(() => _bills.removeWhere((b) => b.id == bill.id));
    widget.onRestored();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase bill restored.'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text('Trash', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            if (_bills.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('Trash is empty',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _bills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final b = _bills[index];
                    return ListTile(
                      leading: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      title: Text('#${b.billNumber ?? b.id} — ${b.supplierName.isEmpty ? 'Unknown supplier' : b.supplierName}'),
                      subtitle: Text(AppDate.format(b.billDate)),
                      trailing: TextButton.icon(
                        onPressed: () => _restore(b),
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Restore'),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bill detail dialog: items + payment history + Record Payment action.
class _BillDetailDialog extends ConsumerStatefulWidget {
  final PurchaseBill bill;
  final String currencySymbol;
  final VoidCallback onChanged;
  final VoidCallback onEdit;

  const _BillDetailDialog({
    required this.bill,
    required this.currencySymbol,
    required this.onChanged,
    required this.onEdit,
  });

  @override
  ConsumerState<_BillDetailDialog> createState() => _BillDetailDialogState();
}

class _BillDetailDialogState extends ConsumerState<_BillDetailDialog> {
  bool _isLoadingPayments = true;
  List<SupplierPayment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments =
        await ref.read(supplierPaymentRepositoryProvider).getPaymentsForBill(widget.bill.id);
    if (mounted) {
      setState(() {
        _payments = payments;
        _isLoadingPayments = false;
      });
    }
  }

  double get _totalPaid => _payments.fold(0.0, (s, p) => s + p.amountPaid);
  double get _outstanding =>
      PurchaseBillCalculator.outstanding(total: widget.bill.total, paid: _totalPaid);

  Future<void> _showRecordPaymentDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RecordPaymentDialog(
        bill: widget.bill,
        currencySymbol: widget.currencySymbol,
        outstanding: _outstanding,
        onPaymentRecorded: () {
          widget.onChanged();
          _loadPayments();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final sym = widget.currencySymbol;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${bill.billNumber ?? bill.id}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '${bill.supplierName.isEmpty ? 'Unknown supplier' : bill.supplierName} · ${AppDate.format(bill.billDate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Edit',
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bill.notes != null && bill.notes!.trim().isNotEmpty) ...[
                      Text('Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(bill.notes!.trim()),
                      const SizedBox(height: 16),
                    ],
                    Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    _buildItemsTable(bill, sym),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Subtotal: $sym ${bill.subtotal.toStringAsFixed(2)}'),
                          Text('Tax: $sym ${bill.tax.toStringAsFixed(2)}'),
                          Text('Total: $sym ${bill.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        PaymentSummaryTile(label: 'Total', value: '$sym ${bill.total.toStringAsFixed(2)}', color: Colors.blue),
                        const SizedBox(width: 12),
                        PaymentSummaryTile(label: 'Paid', value: '$sym ${_totalPaid.toStringAsFixed(2)}', color: Colors.green),
                        const SizedBox(width: 12),
                        PaymentSummaryTile(
                          label: 'Outstanding',
                          value: '$sym ${_outstanding.toStringAsFixed(2)}',
                          color: _outstanding <= 0 ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Payment History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    if (_isLoadingPayments)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                    else if (_payments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('No payments recorded yet',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                      )
                    else
                      ..._payments.map((p) => _buildPaymentRow(p, sym)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  if (!_isLoadingPayments && _outstanding > 0) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showRecordPaymentDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Record Payment'),
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

  Widget _buildItemsTable(PurchaseBill bill, String sym) {
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
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Cost', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Tax %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          ...bill.items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(item.productName, style: const TextStyle(fontSize: 13))),
                    Expanded(child: Text(item.quantity.toString(), style: const TextStyle(fontSize: 13))),
                    Expanded(child: Text(item.costPerUnit.toStringAsFixed(2), style: const TextStyle(fontSize: 13))),
                    Expanded(child: Text(item.taxRate.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                    Expanded(child: Text('$sym ${item.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(SupplierPayment p, String sym) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(AppDate.format(p.datePaid), style: const TextStyle(fontSize: 13))),
          Expanded(
            child: Text('$sym ${p.amountPaid.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.green)),
          ),
          Expanded(
            child: Text(p.paymentMethod ?? '—',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 2,
            child: Text(p.notes ?? '—',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class PaymentSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const PaymentSummaryTile({super.key, required this.label, required this.value, required this.color});

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
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Record Payment dialog.
class _RecordPaymentDialog extends ConsumerStatefulWidget {
  final PurchaseBill bill;
  final String currencySymbol;
  final double outstanding;
  final VoidCallback onPaymentRecorded;

  const _RecordPaymentDialog({
    required this.bill,
    required this.currencySymbol,
    required this.outstanding,
    required this.onPaymentRecorded,
  });

  @override
  ConsumerState<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<_RecordPaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedMethod;
  bool _isSaving = false;

  static const _methods = ['Cash', 'Bank Transfer', 'Check', 'Online', 'Other'];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.outstanding.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(supplierPaymentRepositoryProvider).addPayment(
            bill: widget.bill,
            amountPaid: double.parse(_amountController.text.trim()),
            datePaid: _selectedDate,
            paymentMethod: _selectedMethod,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      widget.onPaymentRecorded();
      if (mounted) {
        Navigator.pop(context);
        AppError.showSuccess(context, 'Payment recorded.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppError.show(context, 'Failed to record payment: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.currencySymbol;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.payments_outlined, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Text('Record Payment'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount ($sym)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  helperText: 'Max: $sym ${widget.outstanding.toStringAsFixed(2)}',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  if (n > widget.outstanding + InvoiceCalculator.moneyEpsilon) {
                    return 'Exceeds outstanding balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(AppDate.dateKey(_selectedDate), style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text('Select method'),
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedMethod = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_isSaving ? 'Saving...' : 'Record Payment'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Create/Edit form.
class _PurchaseBillFormScreen extends ConsumerStatefulWidget {
  final PurchaseBill? billToEdit;
  final VoidCallback onDone;

  const _PurchaseBillFormScreen({super.key, required this.billToEdit, required this.onDone});

  @override
  ConsumerState<_PurchaseBillFormScreen> createState() => _PurchaseBillFormScreenState();
}

class _PurchaseBillFormScreenState extends ConsumerState<_PurchaseBillFormScreen> {
  final _billNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _attachmentPathController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _productSearchFocus = FocusNode();

  bool _useExistingSupplier = true;
  String? _supplierId;
  int _supplierFieldGen = 0;
  final _supplierNameController = TextEditingController();
  DateTime _billDate = DateTime.now();
  List<PurchaseBillItem> _items = [];
  String _currencySymbol = '₹';
  bool _isSaving = false;
  String _productQuery = '';

  bool get _isEditing => widget.billToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    final bill = widget.billToEdit;
    if (bill != null) {
      _billNumberController.text = bill.billNumber ?? '';
      _notesController.text = bill.notes ?? '';
      _attachmentPathController.text = bill.attachmentPath ?? '';
      _supplierId = bill.supplierId;
      _supplierNameController.text = bill.supplierName;
      _useExistingSupplier = bill.supplierId != null;
      _billDate = bill.billDate;
      _items = List.from(bill.items);
    }
  }

  Future<void> _loadCurrency() async {
    final currency = await ref.read(settingsRepositoryProvider).getCurrency();
    if (mounted) setState(() => _currencySymbol = currency.symbol);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _notesController.dispose();
    _attachmentPathController.dispose();
    _productSearchController.dispose();
    _productSearchFocus.dispose();
    _supplierNameController.dispose();
    super.dispose();
  }

  PurchaseBillTotals get _totals => PurchaseBillTotalsCalculator.totals(
        lines: _items.map((i) => PurchaseBillTotalsCalculator.line(
              costPerUnit: i.costPerUnit,
              quantity: i.quantity,
              taxRatePercent: i.taxRate,
            )),
      );

  Future<void> _pickBillDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _billDate = picked);
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _attachmentPathController.text = result.files.single.path!);
    }
  }

  void _addItem(PurchaseBillItem item) {
    setState(() => _items.add(item));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _editItemDialog(int index, PurchaseBillItem item) {
    final nameController = TextEditingController(text: item.productName);
    final descController = TextEditingController(text: item.productDescription);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final costController = TextEditingController(text: item.costPerUnit.toString());
    final taxController = TextEditingController(text: item.taxRate.toString());
    final formKey = GlobalKey<FormState>();
    final isCustom = item.productId == null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Item'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCustom) ...[
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Item Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter an item name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: costController,
                        decoration: InputDecoration(labelText: 'Cost/unit', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: taxController,
                  decoration: InputDecoration(labelText: 'Tax Rate (%)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                if (isCustom) {
                  item.productName = nameController.text.trim();
                  item.productDescription = descController.text.trim();
                }
                item.quantity = double.tryParse(quantityController.text) ?? item.quantity;
                item.costPerUnit = double.tryParse(costController.text) ?? item.costPerUnit;
                item.taxRate = double.tryParse(taxController.text) ?? item.taxRate;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_useExistingSupplier && _supplierId == null) {
      AppError.show(context, 'Please select a supplier or switch to walk-in.');
      return;
    }
    if (!_useExistingSupplier && _supplierNameController.text.trim().isEmpty) {
      AppError.show(context, 'Please enter a supplier name.');
      return;
    }
    if (_items.isEmpty) {
      AppError.show(context, 'Add at least one item.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bill = PurchaseBill(
        id: widget.billToEdit?.id ?? const Uuid().v4(),
        supplierId: _useExistingSupplier ? _supplierId : null,
        supplierName: _supplierNameController.text.trim(),
        billNumber: _billNumberController.text.trim().isEmpty ? null : _billNumberController.text.trim(),
        billDate: _billDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        attachmentPath: _attachmentPathController.text.trim().isEmpty ? null : _attachmentPathController.text.trim(),
        items: _items,
        payments: widget.billToEdit?.payments ?? const [],
        createdAt: widget.billToEdit?.createdAt,
      );

      final repo = ref.read(purchaseBillRepositoryProvider);
      if (_isEditing) {
        await repo.updatePurchaseBill(bill);
      } else {
        await repo.insertPurchaseBill(bill);
      }

      if (mounted) {
        AppError.showSuccess(context, _isEditing ? 'Purchase bill updated!' : 'Purchase bill created!');
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppError.show(context, 'Error saving purchase bill: $e');
      }
    }
  }

  Future<void> _showAddSupplierDialog() async {
    final nameCtrl = TextEditingController();
    final businessNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newSupplier = await showDialog<Supplier>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Supplier'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: businessNameCtrl,
                  decoration: InputDecoration(labelText: 'Business Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final supplier = Supplier(
                id: const Uuid().v4(),
                name: nameCtrl.text.trim(),
                businessName: businessNameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              await ref.read(supplierRepositoryProvider).insertSupplier(supplier);
              ref.read(suppliersProvider.notifier).refresh();
              if (ctx.mounted) Navigator.pop(ctx, supplier);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newSupplier != null && mounted) {
      setState(() {
        _supplierId = newSupplier.id;
        _supplierNameController.text = newSupplier.name;
        _supplierFieldGen++;
      });
    }
  }

  void _addAdHocItemDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final costController = TextEditingController();
    final taxController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_box, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text('Add Custom Item'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Item Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter an item name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: costController,
                        decoration: InputDecoration(labelText: 'Cost/unit', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: taxController,
                  decoration: InputDecoration(labelText: 'Tax Rate (%)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              _addItem(PurchaseBillItem(
                productId: null,
                productName: nameController.text.trim(),
                productDescription: descController.text.trim(),
                quantity: double.tryParse(quantityController.text) ?? 1.0,
                costPerUnit: double.tryParse(costController.text) ?? 0.0,
                taxRate: double.tryParse(taxController.text) ?? 0.0,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addProductItemDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    final costController = TextEditingController(
        text: (product.purchasePrice > 0 ? product.purchasePrice : product.price).toStringAsFixed(2));
    final taxController = TextEditingController(text: product.tax_rate.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(product.name, style: const TextStyle(fontSize: 18)),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: costController,
                        decoration: InputDecoration(labelText: 'Cost/unit', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: taxController,
                  decoration: InputDecoration(labelText: 'Tax Rate (%)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              _addItem(PurchaseBillItem(
                productId: product.id,
                productName: product.name,
                productDescription: product.description,
                quantity: double.tryParse(quantityController.text) ?? 1.0,
                costPerUnit: double.tryParse(costController.text) ?? 0.0,
                taxRate: double.tryParse(taxController.text) ?? 0.0,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildFormAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (!isWide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildItemsCard(false),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildItemsCard(true)),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: SingleChildScrollView(child: _buildDetailsCard())),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildFormAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 12,
      toolbarHeight: 76,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: widget.onDone,
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            shape: const CircleBorder(),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEditing ? 'Edit Purchase Bill' : 'New Purchase Bill',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(
            _isEditing ? 'Update this purchase bill' : 'Create a new purchase bill for your supplier',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save Draft'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16, color: Colors.white),
                label: Text(_isSaving ? 'Saving...' : 'Save Purchase Bill', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Bill Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSupplierTypeToggle(),
          const SizedBox(height: 16),
          if (_useExistingSupplier)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSupplierDropdown()),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  tooltip: 'Add Supplier',
                  onPressed: _showAddSupplierDialog,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            )
          else
            TextFormField(
              controller: _supplierNameController,
              decoration: InputDecoration(
                labelText: 'Supplier *',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _billNumberController,
            decoration: InputDecoration(
              labelText: 'Bill Number (optional)',
              hintText: 'Auto generate',
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickBillDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Bill Date *',
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Pick date',
                  onPressed: _pickBillDate,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
              ),
              child: Text(AppDate.dateKey(_billDate)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any notes',
              prefixIcon: const Icon(Icons.notes),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _attachmentPathController,
                  decoration: InputDecoration(
                    labelText: 'Attachment (optional)',
                    hintText: 'Attach file',
                    prefixIcon: const Icon(Icons.attach_file),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: 'Browse',
                onPressed: _pickAttachment,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          _buildTotalsFooter(),
        ],
      ),
    );
  }

  Widget _buildSupplierTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSupplierTypeSegment(
              selected: _useExistingSupplier,
              icon: Icons.check_circle,
              label: 'Existing Supplier',
              onTap: () => setState(() => _useExistingSupplier = true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSupplierTypeSegment(
              selected: !_useExistingSupplier,
              icon: Icons.person,
              label: 'Walk-in Supplier',
              onTap: () => setState(() {
                _useExistingSupplier = false;
                _supplierId = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierTypeSegment({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    final unselected = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall - 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall - 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : unselected),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : unselected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    final suppliersAsync = ref.watch(suppliersProvider);
    return suppliersAsync.when(
      data: (suppliers) => Autocomplete<Supplier>(
        key: ValueKey(_supplierFieldGen),
        displayStringForOption: (s) => s.name,
        initialValue: TextEditingValue(text: _supplierNameController.text),
        optionsBuilder: (query) {
          if (query.text.isEmpty) return suppliers;
          return suppliers.where((s) => s.name.toLowerCase().contains(query.text.toLowerCase()));
        },
        onSelected: (selected) {
          setState(() {
            _supplierId = selected.id;
            _supplierNameController.text = selected.name;
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Supplier *',
              hintText: 'Search supplier',
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            ),
            onChanged: (text) {
              final selected = suppliers.where((s) => s.id == _supplierId).firstOrNull;
              if (selected != null && selected.name != text) {
                setState(() => _supplierId = null);
              }
            },
            validator: (v) {
              if (_supplierId == null) return 'Select a supplier from the list';
              return null;
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(option.name, overflow: TextOverflow.ellipsis),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Failed to load suppliers: $e'),
    );
  }

  Widget _buildTotalsFooter() {
    final totals = _totals;
    return Column(
      children: [
        _buildTotalRow('Subtotal', totals.subtotal),
        _buildTotalRow('Tax', totals.tax),
        const SizedBox(height: 4),
        _buildTotalRow('Grand Total', totals.total, isGrand: true),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isGrand = false}) {
    final accent = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontWeight: isGrand ? FontWeight.bold : FontWeight.normal, fontSize: isGrand ? 16 : 14)),
          Flexible(
            child: Text('$_currencySymbol ${amount.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isGrand ? 20 : 14,
                  color: isGrand ? accent : null,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(bool isWide) {
    final products = ref.watch(productsProvider);
    final filteredProducts = products.maybeWhen(
      data: (list) => _productQuery.isEmpty
          ? list
          : list.where((p) => p.name.toLowerCase().contains(_productQuery.toLowerCase())).toList(),
      orElse: () => <Product>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text('Items (${_items.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addAdHocItemDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Custom Item'),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty && isWide)
            Expanded(
              child: Center(
                child: Text('No items added yet',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No items added yet',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            )
          else if (isWide)
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemsTableHeader(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: false,
                      itemCount: _items.length,
                      itemBuilder: (context, index) => _buildItemRow(index, _items[index]),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildItemsTableHeader(),
            ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value)),
          ],
          const SizedBox(height: 12),
          if (_productQuery.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: filteredProducts.isEmpty
                  ? const Padding(padding: EdgeInsets.all(12), child: Text('No products found'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredProducts.length > 8 ? 8 : filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(product.name),
                          subtitle: Text('Last cost: $_currencySymbol${product.purchasePrice.toStringAsFixed(2)}'),
                          trailing: const Icon(Icons.add_circle, color: Colors.green),
                          onTap: () => _addProductItemDialog(product),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _productSearchController,
            focusNode: _productSearchFocus,
            decoration: InputDecoration(
              hintText: 'Search products to add...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (v) => setState(() => _productQuery = v),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTableHeader() {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('#', style: style)),
          Expanded(flex: 2, child: Text('Item / Description', style: style)),
          SizedBox(width: 110, child: Text('Qty', style: style)),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: Text('Unit Cost', style: style)),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: Text('Amount', style: style)),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, PurchaseBillItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 22, child: Text('${index + 1}')),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.productId == null)
                  const Text('Custom item', style: TextStyle(fontSize: 11, color: Colors.deepPurple)),
              ],
            ),
          ),
          SizedBox(width: 110, child: _buildQtyStepper(item)),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('$_currencySymbol${item.costPerUnit.toStringAsFixed(2)}', maxLines: 1),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('$_currencySymbol${item.total.toStringAsFixed(2)}',
                  maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _editItemDialog(index, item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyStepper(PurchaseBillItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (item.quantity > 1) item.quantity -= 1;
            }),
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove, size: 14)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 26, maxWidth: 50),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.quantity == item.quantity.roundToDouble()
                    ? item.quantity.toInt().toString()
                    : item.quantity.toString(),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => item.quantity += 1),
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 14)),
          ),
        ],
      ),
    );
  }
}
