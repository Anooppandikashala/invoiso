import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/domain/purchase_bill_calculator.dart';
import 'package:invoiso/common/invoiso_colors.dart';
import 'package:invoiso/domain/purchase_bill_totals_calculator.dart';
import 'package:invoiso/l10n/app_localizations.dart';
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
// List view: paginated table, search, sort, filter, soft-delete + trash.
// Structure mirrors InvoiceManagementScreenV2 — gradient table header,
// isWide-responsive columns/actions (row buttons collapse into one
// overflow menu below the breakpoint instead of overflowing), and
// dialog-based Sort/Filter buttons instead of an always-visible strip.
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

  // Sort — 'bill_date' | 'supplier_name' | 'total_amount'
  String _sortField = 'bill_date';
  bool _sortAscending = false;

  // Filter — payment status is the only meaningful dimension here (no
  // due-date concept on purchase bills, unlike invoices).
  String _statusFilter = 'all'; // 'all' | 'paid' | 'partial' | 'unpaid'

  static const List<Map<String, dynamic>> _statusFilterOptionsV2 = [
    {'value': 'all', 'color': Colors.grey},
    {'value': 'paid', 'color': Colors.green},
    {'value': 'partial', 'color': Colors.orange},
    {'value': 'unpaid', 'color': Colors.red},
  ];

  static const List<(String, bool, IconData)> _sortOptionsV2 = [
    ('bill_date', false, Icons.calendar_today_outlined),
    ('bill_date', true, Icons.calendar_today_outlined),
    ('supplier_name', true, Icons.sort_by_alpha_outlined),
    ('supplier_name', false, Icons.sort_by_alpha_outlined),
    ('total_amount', false, Icons.trending_down_outlined),
    ('total_amount', true, Icons.trending_up_outlined),
  ];

  static String _sortOptionLabel(AppLocalizations l10n, String field, bool asc) {
    return switch ((field, asc)) {
      ('bill_date', false) => l10n.purchaseBillMgmtSortDateNewest,
      ('bill_date', true) => l10n.purchaseBillMgmtSortDateOldest,
      ('supplier_name', true) => l10n.purchaseBillMgmtSortSupplierAZ,
      ('supplier_name', false) => l10n.purchaseBillMgmtSortSupplierZA,
      ('total_amount', false) => l10n.purchaseBillMgmtSortAmountHighest,
      _ => l10n.purchaseBillMgmtSortAmountLowest,
    };
  }

  static String _statusFilterLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'paid' => l10n.paymentStatusPaid,
      'partial' => l10n.paymentStatusPartial,
      'unpaid' => l10n.paymentStatusUnpaid,
      _ => l10n.invoiceMgmtStatusAllLabel,
    };
  }

  int get _activeFilterCountV2 => _statusFilter != 'all' ? 1 : 0;

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
          orderBy: _sortField,
          orderAscending: _sortAscending,
        ),
        billRepo.getPurchaseBillCount(searchQuery: _searchQuery),
      ]);
      var bills = results[0] as List<PurchaseBill>;
      final count = results[1] as int;
      final paidTotals = bills.isEmpty
          ? <String, double>{}
          : await ref
              .read(supplierPaymentRepositoryProvider)
              .getTotalPaidBatch(bills.map((b) => b.id).toList());
      // Payment status isn't a DB column (derived from total vs paid), so —
      // same tradeoff as InvoiceManagementScreenV2's own filters — it's
      // applied to the already-paginated page rather than the query; a
      // filtered page can show fewer than _pageSize rows.
      if (_statusFilter != 'all') {
        bills = bills.where((b) {
          final paid = paidTotals[b.id] ?? 0.0;
          final status = PurchaseBillCalculator.paymentStatus(total: b.total, paid: paid);
          switch (_statusFilter) {
            case 'paid':
              return status == PaymentStatus.paid;
            case 'partial':
              return status == PaymentStatus.partial;
            case 'unpaid':
              return status == PaymentStatus.unpaid;
            default:
              return true;
          }
        }).toList();
      }
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
        AppError.show(context,
            AppLocalizations.of(context)!.purchaseBillMgmtLoadErrorMessage(e.toString()),
            onRetry: _loadPage);
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

  Future<void> _showApplyPaymentDialog(PurchaseBill row) async {
    final full = await ref.read(purchaseBillRepositoryProvider).getPurchaseBillById(row.id) ?? row;
    if (!mounted) return;
    final paid = await ref.read(supplierPaymentRepositoryProvider).getTotalPaidForBill(full.id);
    if (!mounted) return;
    final outstanding = PurchaseBillCalculator.outstanding(total: full.total, paid: paid);
    if (outstanding <= 0) {
      AppError.show(context,
          AppLocalizations.of(context)!.purchaseBillMgmtAlreadyFullyPaidMessage,
          isError: false);
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RecordPaymentDialog(
        bill: full,
        currencySymbol: _currencySymbol,
        outstanding: outstanding,
        onPaymentRecorded: _loadPage,
      ),
    );
  }

  Future<void> _softDelete(PurchaseBill bill) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppError.confirm(
      context,
      title: l10n.invoiceMgmtMoveToTrashTitle,
      message: l10n.purchaseBillMgmtMoveToTrashBody(bill.billNumber ?? bill.id),
      confirmLabel: l10n.invoiceMgmtMoveToTrashTitle,
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    await ref.read(purchaseBillRepositoryProvider).softDeletePurchaseBill(bill.id);
    await _loadPage();
    if (mounted) AppError.showSuccess(context, l10n.purchaseBillMgmtMovedToTrashMessage);
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

  void _handleRowActionV2(String action, PurchaseBill bill) {
    switch (action) {
      case 'view':
        _viewBill(bill);
      case 'edit':
        _editBill(bill);
      case 'pay':
        _showApplyPaymentDialog(bill);
      case 'delete':
        if (widget.user.isAdmin()) _softDelete(bill);
    }
  }

  List<PopupMenuEntry<String>> _rowActionMenuItemsV2(PurchaseBill bill) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PopupMenuItem(value: 'view', child: _MenuRow(Icons.visibility_outlined, l10n.actionView, Colors.green)),
      PopupMenuItem(value: 'edit', child: _MenuRow(Icons.edit_outlined, l10n.actionEdit, Colors.blue)),
      PopupMenuItem(value: 'pay', child: _MenuRow(Icons.payments_outlined, l10n.actionApplyPayment, Colors.purple)),
      if (widget.user.isAdmin())
        PopupMenuItem(value: 'delete', child: _MenuRow(Icons.delete_outline, l10n.invoiceMgmtMoveToTrashTitle, Colors.red)),
    ];
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback? onPressed) {
    final effectiveColor = onPressed != null ? color : Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: effectiveColor, size: 18),
        ),
      ),
    );
  }

  Widget _rowActionsV2(PurchaseBill bill, PaymentStatus status, bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final menu = PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: l10n.invoiceMgmtMoreActionsTooltip,
      padding: EdgeInsets.zero,
      onSelected: (action) => _handleRowActionV2(action, bill),
      itemBuilder: (ctx) => _rowActionMenuItemsV2(bill),
    );
    if (!isWide) return menu;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildActionButton(Icons.visibility_outlined, Colors.green, l10n.actionView, () => _viewBill(bill)),
        _buildActionButton(Icons.edit_outlined, Colors.blue, l10n.actionEdit, () => _editBill(bill)),
        _buildActionButton(Icons.payments_outlined,
            status == PaymentStatus.paid ? Colors.green : Colors.purple,
            l10n.actionApplyPayment, () => _showApplyPaymentDialog(bill)),
        if (widget.user.isAdmin())
          _buildActionButton(Icons.delete_outline, Colors.red, l10n.actionDelete, () => _softDelete(bill)),
      ],
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final Color color;
    final String label;
    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        label = l10n.paymentStatusPaid;
      case PaymentStatus.partial:
        color = Colors.orange;
        label = l10n.paymentStatusPartial;
      case PaymentStatus.unpaid:
        color = Colors.red;
        label = l10n.paymentStatusUnpaid;
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

  Future<void> _showSortDialogV2() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.purchaseBillMgmtSortByTitle),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _sortOptionsV2.map((opt) {
                final (field, asc, icon) = opt;
                final selected = _sortField == field && _sortAscending == asc;
                final primaryColor = Theme.of(context).primaryColor;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, size: 20, color: selected ? primaryColor : null),
                  title: Text(_sortOptionLabel(l10n, field, asc),
                      style: TextStyle(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? primaryColor : null)),
                  trailing: selected ? Icon(Icons.check_circle, color: primaryColor, size: 20) : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    if (_sortField == field && _sortAscending == asc) return;
                    setState(() {
                      _sortField = field;
                      _sortAscending = asc;
                      _currentPage = 0;
                    });
                    _loadPage();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.actionClose)),
          ],
        );
      },
    );
  }

  Future<void> _showFilterDialogV2() async {
    final l10n = AppLocalizations.of(context)!;
    String tempStatus = _statusFilter;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(l10n.purchaseBillMgmtFilterTitle),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.purchaseBillMgmtPaymentStatusLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusFilterOptionsV2.map((opt) {
                      final selected = tempStatus == opt['value'];
                      final color = opt['color'] as Color;
                      return ChoiceChip(
                        label: Text(_statusFilterLabel(AppLocalizations.of(context)!, opt['value'] as String)),
                        selected: selected,
                        onSelected: (_) => setDialogState(() => tempStatus = opt['value'] as String),
                        selectedColor: color.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: selected ? color.withValues(alpha: 0.9) : null,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => setDialogState(() => tempStatus = 'all'),
                child: Text(l10n.actionReset),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(l10n.actionCancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      setState(() {
                        _statusFilter = tempStatus;
                        _currentPage = 0;
                      });
                      _loadPage();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                    child: Text(l10n.actionApply),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }

  List<Widget> _headerBarV2() {
    final l10n = AppLocalizations.of(context)!;
    return [
      IconButton(
        icon: const Icon(Icons.delete_sweep_outlined),
        onPressed: _showTrashDialog,
        tooltip: l10n.invoiceMgmtTrashLabel,
      ),
      IconButton(
        onPressed: _isLoading ? null : _loadPage,
        icon: _isLoading
            ? const SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.refresh),
        tooltip: l10n.actionRefresh,
      ),
    ];
  }

  Widget _searchFilterRowV2(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.purchaseBillMgmtSearchHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _currentPage = 0;
        });
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 400), _loadPage);
      },
    );

    final filterButton = Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: _showFilterDialogV2,
          icon: const Icon(Icons.filter_list, size: 18),
          label: Text(l10n.invoiceMgmtFilterLabel),
        ),
        if (_activeFilterCountV2 > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
              child: Text('$_activeFilterCountV2',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );

    final sortButton = OutlinedButton.icon(
      onPressed: _showSortDialogV2,
      icon: const Icon(Icons.sort, size: 18),
      label: Text(l10n.invoiceMgmtSortLabel),
    );

    final newBillButton = FilledButton.icon(
      onPressed: widget.onNew,
      icon: const Icon(Icons.add, size: 18),
      label: Text(l10n.purchaseBillMgmtNewBillButton),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: searchField)),
          const SizedBox(width: 12),
          filterButton,
          const SizedBox(width: 12),
          sortButton,
          const Spacer(),
          newBillButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        const SizedBox(height: 12),
        Row(children: [Expanded(child: filterButton), const SizedBox(width: 12), Expanded(child: sortButton)]),
        const SizedBox(height: 12),
        newBillButton,
      ],
    );
  }

  Widget _tableHeaderRowV2(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    const style = TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.4);
    return Container(
      decoration: BoxDecoration(
        gradient: PurchaseBillManagementScreenColors.topBarBackgroundGradientColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('#', style: style)),
          Expanded(flex: 3, child: Text(l10n.purchaseBillMgmtColBill, style: style)),
          if (isWide) ...[
            Expanded(flex: 2, child: Text(l10n.supplierMgmtColSupplier, style: style)),
            SizedBox(width: 100, child: Text(l10n.invoiceMgmtColDate, style: style)),
          ],
          Expanded(child: Text(l10n.fieldTotalLabel, style: style)),
          SizedBox(width: 76, child: Text(l10n.invoiceMgmtColStatus, style: style)),
          if (isWide) Expanded(child: Text(l10n.purchaseBillMgmtColBalance, style: style)),
          SizedBox(width: isWide ? 180 : 48, child: const SizedBox()),
        ],
      ),
    );
  }

  Widget _billRowV2(PurchaseBill bill, int index, bool isEven, bool isWide) {
    final paid = _paidTotals[bill.id] ?? 0.0;
    final status = PurchaseBillCalculator.paymentStatus(total: bill.total, paid: paid);
    final outstanding = PurchaseBillCalculator.outstanding(total: bill.total, paid: paid);
    return Container(
      decoration: BoxDecoration(
        color: isEven
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$index',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(bill.billNumber ?? '#${bill.id}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  if (!isWide) ...[
                    const SizedBox(height: 2),
                    Text(
                        '${bill.supplierName.isEmpty ? '—' : bill.supplierName}  ·  ${AppDate.format(bill.billDate)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
          if (isWide) ...[
            Expanded(
              flex: 2,
              child: Text(bill.supplierName.isEmpty ? '—' : bill.supplierName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            SizedBox(width: 100, child: Text(AppDate.format(bill.billDate), style: const TextStyle(fontSize: 13))),
          ],
          Expanded(
            child: Text('$_currencySymbol ${bill.total.toStringAsFixed(2)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          SizedBox(width: 76, child: Align(alignment: Alignment.centerLeft, child: _buildStatusChip(status))),
          if (isWide)
            Expanded(
              child: status == PaymentStatus.paid
                  ? Text('—', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                  : Text(
                      '$_currencySymbol ${outstanding.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: status == PaymentStatus.partial ? Colors.orange[700] : Colors.red[700]),
                    ),
            ),
          SizedBox(width: isWide ? 180 : 48, child: _rowActionsV2(bill, status, isWide)),
        ],
      ),
    );
  }

  Widget _paginationV2(bool isWide) {
    final l10n = AppLocalizations.of(context)!;
    final totalPages = _totalPages == 0 ? 1 : _totalPages;
    final left = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.invoiceMgmtRowsPerPageLabel, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
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
        Text(l10n.purchaseBillMgmtTotalCountLabel(_totalCount), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ],
    );

    // Icon-only (no "Previous"/"Next" text label) — with a text label this
    // Row's own intrinsic width could exceed what's left inside the
    // pagination bar even wrapped in a Wrap (Wrap doesn't shrink a single
    // child below its natural size, only wraps whole children to a new
    // line), so it kept overflowing by a few pixels at some widths.
    final right = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.actionPrevious,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          ),
          child: Text(l10n.invoiceMgmtPageOfLabel(_currentPage + 1, totalPages),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _currentPage < totalPages - 1 ? () => _changePage(_currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: l10n.actionNext,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );

    // A Row(spaceBetween) here can still overflow right at the isWide
    // threshold (900px) — "Previous"/"Next" labels plus the page indicator
    // don't reliably fit in what's left after `left`. Wrap behaves the same
    // as Row when both sides fit on one line, and drops to a second line
    // instead of overflowing when they don't, regardless of isWide.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [left, right],
    );
  }

  // A plain Center can't shrink its child, so on a short window (the
  // search/filter row alone can be taller than the Expanded area gives
  // it once it wraps to a Column in narrow mode) this content would
  // overflow. Scrolling instead of overflowing, but still centered
  // when there's enough room via the minHeight constraint.
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 72, color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(l10n.purchaseBillMgmtNoBillsFoundTitle,
                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty && _statusFilter == 'all'
                      ? l10n.purchaseBillMgmtCreateFirstMessage
                      : l10n.purchaseBillMgmtTryAdjustingMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, outerConstraints) {
      final isWide = outerConstraints.maxWidth >= 900;
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey[50],
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.purchaseBillMgmtTitle),
          backgroundColor:
              Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          actions: [..._headerBarV2(), const SizedBox(width: 8)],
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              padding: const EdgeInsets.all(20),
              child: _searchFilterRowV2(isWide),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: _bills.isEmpty
                        ? _buildEmptyState()
                        // No max-width cap here (unlike InvoiceManagementScreenV2's
                        // dense many-column table) — with only ~7 columns, capping
                        // this at maxWidthNarrow left huge empty margins on a wide
                        // desktop window, making the whole screen look shrunk.
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SingleChildScrollView(
                              child: Card(
                                elevation: 2,
                                shadowColor: Colors.black.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    _tableHeaderRowV2(isWide),
                                    ..._bills.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final globalIndex = (_currentPage * _pageSize) + index + 1;
                                      return _billRowV2(entry.value, globalIndex, index.isEven, isWide);
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
            if (_bills.isNotEmpty)
              Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: _paginationV2(isWide),
              ),
          ],
        ),
      );
    });
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label),
      ],
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
    final l10n = AppLocalizations.of(context)!;
    await ref.read(purchaseBillRepositoryProvider).restorePurchaseBill(bill.id);
    setState(() => _bills.removeWhere((b) => b.id == bill.id));
    widget.onRestored();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.purchaseBillMgmtRestoredMessage), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                Text(l10n.invoiceMgmtTrashLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            if (_bills.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(l10n.invoiceMgmtTrashIsEmptyLabel,
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
                      title: Text('#${b.billNumber ?? b.id} — ${b.supplierName.isEmpty ? l10n.purchaseBillMgmtUnknownSupplierLabel : b.supplierName}'),
                      subtitle: Text(AppDate.format(b.billDate)),
                      trailing: TextButton.icon(
                        onPressed: () => _restore(b),
                        icon: const Icon(Icons.restore, size: 16),
                        label: Text(l10n.actionRestore),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionClose)),
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
    final l10n = AppLocalizations.of(context)!;
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
                          '${bill.supplierName.isEmpty ? l10n.purchaseBillMgmtUnknownSupplierLabel : bill.supplierName} · ${AppDate.format(bill.billDate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: l10n.actionEdit,
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
                      Text(l10n.purchaseBillMgmtNotesSectionLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(bill.notes!.trim()),
                      const SizedBox(height: 16),
                    ],
                    Text(l10n.purchaseBillMgmtItemsSectionLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    _buildItemsTable(bill, sym),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${l10n.fieldSubtotalLabel}: $sym ${bill.subtotal.toStringAsFixed(2)}'),
                          Text('${l10n.fieldTaxLabel}: $sym ${bill.tax.toStringAsFixed(2)}'),
                          Text('${l10n.fieldTotalLabel}: $sym ${bill.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        PaymentSummaryTile(label: l10n.fieldTotalLabel, value: '$sym ${bill.total.toStringAsFixed(2)}', color: Colors.blue),
                        const SizedBox(width: 12),
                        PaymentSummaryTile(label: l10n.paymentDialogAmountPaidLabel, value: '$sym ${_totalPaid.toStringAsFixed(2)}', color: Colors.green),
                        const SizedBox(width: 12),
                        PaymentSummaryTile(
                          label: l10n.invoiceMgmtColOutstanding,
                          value: '$sym ${_outstanding.toStringAsFixed(2)}',
                          color: _outstanding <= 0 ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.paymentDialogHistoryTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                          child: Text(l10n.paymentDialogNoPaymentsMessage,
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
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionClose)),
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
                      label: Text(l10n.actionRecordPayment),
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
    final l10n = AppLocalizations.of(context)!;
    const headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
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
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(l10n.purchaseBillMgmtColItem, style: headerStyle)),
                Expanded(child: Text(l10n.purchaseBillMgmtQtyDetailLabel, style: headerStyle)),
                Expanded(child: Text(l10n.purchaseBillMgmtColCost, style: headerStyle)),
                Expanded(child: Text(l10n.purchaseBillMgmtColTaxPercent, style: headerStyle)),
                Expanded(child: Text(l10n.fieldTotalLabel, style: headerStyle)),
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

// Canonical values persisted to SupplierPayment.paymentMethod stay in
// English (matches ApplyPaymentDialog's own _paymentMethodLabel pattern) —
// only the dropdown's displayed label is localized.
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
        final l10n = AppLocalizations.of(context)!;
        Navigator.pop(context);
        AppError.showSuccess(context, l10n.purchaseBillMgmtPaymentRecordedMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppError.show(context,
            AppLocalizations.of(context)!.paymentDialogRecordFailedMessage(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sym = widget.currencySymbol;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.payments_outlined, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(l10n.actionRecordPayment),
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
                  labelText: l10n.paymentDialogAmountFieldLabel(sym),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  helperText: l10n.paymentDialogMaxHelperText(sym, widget.outstanding.toStringAsFixed(2)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return l10n.paymentDialogInvalidAmountError;
                  if (n > widget.outstanding + InvoiceCalculator.moneyEpsilon) {
                    return l10n.paymentDialogExceedsOutstandingError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.invoiceMgmtColDate,
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
                  labelText: l10n.paymentDialogMethodFieldLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: Text(l10n.paymentDialogSelectMethodHint),
                items: _methods
                    .map((m) => DropdownMenuItem(value: m, child: Text(_paymentMethodLabel(l10n, m))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMethod = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.createInvoiceNotesOptionalLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_isSaving ? l10n.createInvoiceSavingEllipsisLabel : l10n.actionRecordPayment),
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
              costIncludesTax: i.costIncludesTax,
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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: item.productName);
    final descController = TextEditingController(text: item.productDescription);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final costController = TextEditingController(text: item.costPerUnit.toString());
    final taxController = TextEditingController(text: item.taxRate.toString());
    final formKey = GlobalKey<FormState>();
    final isCustom = item.productId == null;
    bool costIncludesTax = item.costIncludesTax;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.purchaseBillMgmtEditItemTitle),
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
                      decoration: InputDecoration(labelText: l10n.fieldItemNameLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.purchaseBillMgmtEnterItemNameMessage : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: InputDecoration(labelText: l10n.purchaseBillMgmtDescriptionOptionalLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          decoration: InputDecoration(labelText: l10n.purchaseBillMgmtQuantityLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? l10n.purchaseBillMgmtInvalidValueMessage : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: costController,
                          decoration: InputDecoration(labelText: l10n.purchaseBillMgmtCostPerUnitLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => double.tryParse(v ?? '') == null ? l10n.purchaseBillMgmtInvalidValueMessage : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: taxController,
                    decoration: InputDecoration(labelText: l10n.fieldTaxRateLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.purchaseBillMgmtCostIncludesTaxLabel),
                    value: costIncludesTax,
                    onChanged: (v) => setDialogState(() => costIncludesTax = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
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
                  item.costIncludesTax = costIncludesTax;
                });
                Navigator.pop(ctx);
              },
              child: Text(l10n.actionSave),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_useExistingSupplier && _supplierId == null) {
      AppError.show(context, l10n.purchaseBillMgmtSelectSupplierMessage);
      return;
    }
    if (!_useExistingSupplier && _supplierNameController.text.trim().isEmpty) {
      AppError.show(context, l10n.purchaseBillMgmtEnterSupplierNameMessage);
      return;
    }
    if (_items.isEmpty) {
      AppError.show(context, l10n.purchaseBillMgmtAddAtLeastOneItemMessage);
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
        AppError.showSuccess(context,
            _isEditing ? l10n.purchaseBillMgmtUpdatedMessage : l10n.purchaseBillMgmtCreatedMessage);
        widget.onDone();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppError.show(context, l10n.purchaseBillMgmtSaveErrorMessage(e.toString()));
      }
    }
  }

  Future<void> _showAddSupplierDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final businessNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newSupplier = await showDialog<Supplier>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.supplierMgmtAddSupplierButton),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.fieldNameLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.purchaseBillMgmtEnterNameMessage : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: businessNameCtrl,
                  decoration: InputDecoration(labelText: l10n.fieldBusinessNameLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: l10n.fieldPhoneLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
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
            child: Text(l10n.actionAdd),
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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final costController = TextEditingController();
    final taxController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    bool costIncludesTax = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_box, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Text(l10n.purchaseBillMgmtAddCustomItemTitle),
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
                    decoration: InputDecoration(labelText: l10n.fieldItemNameLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.purchaseBillMgmtEnterItemNameMessage : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(labelText: l10n.purchaseBillMgmtDescriptionOptionalLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          decoration: InputDecoration(labelText: l10n.purchaseBillMgmtQuantityLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? l10n.purchaseBillMgmtInvalidValueMessage : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: costController,
                          decoration: InputDecoration(labelText: l10n.purchaseBillMgmtCostPerUnitLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => double.tryParse(v ?? '') == null ? l10n.purchaseBillMgmtInvalidValueMessage : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: taxController,
                    decoration: InputDecoration(labelText: l10n.fieldTaxRateLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.purchaseBillMgmtCostIncludesTaxLabel),
                    value: costIncludesTax,
                    onChanged: (v) => setDialogState(() => costIncludesTax = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
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
                  costIncludesTax: costIncludesTax,
                ));
                Navigator.pop(ctx);
              },
              child: Text(l10n.actionAdd, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _addProductItemDialog(Product product) {
    final l10n = AppLocalizations.of(context)!;
    final quantityController = TextEditingController(text: '1');
    final costController = TextEditingController(
        text: (product.purchasePrice > 0 ? product.purchasePrice : product.price).toStringAsFixed(2));
    final taxController = TextEditingController(text: product.tax_rate.toString());
    final formKey = GlobalKey<FormState>();
    bool costIncludesTax = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
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
                          decoration: InputDecoration(labelText: l10n.purchaseBillMgmtQuantityLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? l10n.purchaseBillMgmtInvalidValueMessage : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: costController,
                          decoration: InputDecoration(labelText: l10n.purchaseBillMgmtCostPerUnitLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          validator: (v) => double.tryParse(v ?? '') == null ? l10n.purchaseBillMgmtInvalidValueMessage : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: taxController,
                    decoration: InputDecoration(labelText: l10n.fieldTaxRateLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.purchaseBillMgmtCostIncludesTaxLabel),
                    value: costIncludesTax,
                    onChanged: (v) => setDialogState(() => costIncludesTax = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
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
                  costIncludesTax: costIncludesTax,
                ));
                Navigator.pop(ctx);
              },
              child: Text(l10n.actionAdd),
            ),
          ],
        );
      }),
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(_isEditing ? l10n.purchaseBillMgmtEditPurchaseBillTitle : l10n.purchaseBillMgmtNewBillButton,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(
            _isEditing ? l10n.purchaseBillMgmtUpdateSubtitle : l10n.purchaseBillMgmtCreateSubtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: Text(l10n.purchaseBillMgmtSaveDraftButton),
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
                label: Text(_isSaving ? l10n.createInvoiceSavingEllipsisLabel : l10n.purchaseBillMgmtSavePurchaseBillButton, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Same flat-card look as CreateInvoiceScreenV2's `_flatCardDecorationV2`
  // (12px radius + a subtle shadow instead of a plain border-only card).
  BoxDecoration _flatCardDecorationV2() => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      );

  Widget _buildDetailsCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: _flatCardDecorationV2(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(l10n.purchaseBillMgmtBillDetailsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  tooltip: l10n.supplierMgmtAddSupplierButton,
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
                labelText: l10n.purchaseBillMgmtSupplierRequiredLabel,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _billNumberController,
            decoration: InputDecoration(
              labelText: l10n.purchaseBillMgmtBillNumberOptionalLabel,
              hintText: l10n.purchaseBillMgmtAutoGenerateHint,
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickBillDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.purchaseBillMgmtBillDateRequiredLabel,
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: l10n.purchaseBillMgmtPickDateTooltip,
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
              labelText: l10n.createInvoiceNotesOptionalLabel,
              hintText: l10n.purchaseBillMgmtAddAnyNotesHint,
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
                    labelText: l10n.purchaseBillMgmtAttachmentOptionalLabel,
                    hintText: l10n.purchaseBillMgmtAttachFileHint,
                    prefixIcon: const Icon(Icons.attach_file),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: l10n.purchaseBillMgmtBrowseTooltip,
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
    final l10n = AppLocalizations.of(context)!;
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
              label: l10n.purchaseBillMgmtExistingSupplierLabel,
              onTap: () => setState(() => _useExistingSupplier = true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSupplierTypeSegment(
              selected: !_useExistingSupplier,
              icon: Icons.person,
              label: l10n.purchaseBillMgmtWalkInSupplierLabel,
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
          final l10n = AppLocalizations.of(context)!;
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: l10n.purchaseBillMgmtSupplierRequiredLabel,
              hintText: l10n.purchaseBillMgmtSearchSupplierHint,
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
              if (_supplierId == null) return l10n.purchaseBillMgmtSelectSupplierFromListMessage;
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
      error: (e, _) => Text(AppLocalizations.of(context)!.supplierMgmtLoadErrorMessage(e.toString())),
    );
  }

  Widget _buildTotalsFooter() {
    final l10n = AppLocalizations.of(context)!;
    final totals = _totals;
    return Column(
      children: [
        _buildTotalRow(l10n.fieldSubtotalLabel, totals.subtotal),
        _buildTotalRow(l10n.fieldTaxLabel, totals.tax),
        const SizedBox(height: 4),
        _buildTotalRow(l10n.purchaseBillMgmtGrandTotalLabel, totals.total, isGrand: true),
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
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);
    final filteredProducts = products.maybeWhen(
      data: (list) => list
          .where((p) => p.type == 'product')
          .where((p) => _productQuery.isEmpty ||
              p.name.toLowerCase().contains(_productQuery.toLowerCase()))
          .toList(),
      orElse: () => <Product>[],
    );

    return Container(
      decoration: _flatCardDecorationV2(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.purchaseBillMgmtItemsSectionLabel.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_items.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addAdHocItemDialog,
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n.purchaseBillMgmtAddCustomItemTitle),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty && isWide)
            Expanded(
              child: Center(
                child: Text(l10n.purchaseBillMgmtNoItemsAddedMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(l10n.purchaseBillMgmtNoItemsAddedMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            )
          else if (isWide)
            Flexible(
              child: ListView.builder(
                shrinkWrap: false,
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildItemRow(index, _items[index]),
              ),
            )
          else
            ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value)),
          const SizedBox(height: 12),
          if (_productQuery.isNotEmpty) ...[
            // Same floating-panel treatment as CreateInvoiceScreenV2's
            // product dropdown (Material + border) — without it, this list
            // had no visual separation from the card behind it.
            Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: filteredProducts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.createInvoiceNoProductsFoundMessage,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: filteredProducts.length > 8 ? 8 : filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(product.name),
                            subtitle: Text(l10n.purchaseBillMgmtLastCostLabel(
                                '$_currencySymbol${product.purchasePrice.toStringAsFixed(2)}')),
                            trailing: const Icon(Icons.add_circle, color: Colors.green),
                            onTap: () => _addProductItemDialog(product),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _productSearchController,
            focusNode: _productSearchFocus,
            decoration: InputDecoration(
              hintText: l10n.purchaseBillMgmtSearchProductsHint,
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

  // Card-row style (numbered badge + name + wrapped detail chips + total),
  // matching CreateInvoiceScreenV2's item rows exactly — no more
  // fixed-width table columns to keep aligned with a header row.
  Widget _buildItemRow(int index, PurchaseBillItem item) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
            ),
            child: Text('${index + 1}',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item.productName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (item.productId == null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(l10n.purchaseBillMgmtCustomBadgeLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _buildItemDetail(l10n.purchaseBillMgmtQtyDetailLabel,
                          item.quantity == item.quantity.roundToDouble()
                              ? item.quantity.toInt().toString()
                              : item.quantity.toString()),
                      _buildItemDetail(l10n.purchaseBillMgmtUnitCostDetailLabel,
                          '$_currencySymbol${item.costPerUnit.toStringAsFixed(2)}'),
                      if (item.taxRate > 0) ...[
                        item.costIncludesTax
                            ? _buildItemDetail(
                                l10n.fieldTaxLabel,
                                l10n.purchaseBillMgmtTaxInclusiveLabel(item.taxRate
                                    .toStringAsFixed(item.taxRate == item.taxRate.roundToDouble() ? 0 : 1)),
                                color: Colors.teal[700])
                            : _buildItemDetail(l10n.fieldTaxLabel,
                                '${item.taxRate.toStringAsFixed(item.taxRate == item.taxRate.roundToDouble() ? 0 : 1)}%'),
                        if (item.costIncludesTax)
                          _buildItemDetail(l10n.purchaseBillMgmtNetCostDetailLabel,
                              '$_currencySymbol${item.netCostPerUnit.toStringAsFixed(2)}',
                              color: Colors.teal[700]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$_currencySymbol${item.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l10n.purchaseBillMgmtEditItemTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: () => _editItemDialog(index, item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: l10n.purchaseBillMgmtRemoveItemTooltip,
            visualDensity: VisualDensity.compact,
            color: Theme.of(context).colorScheme.error,
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
