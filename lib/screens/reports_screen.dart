import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/providers/repositories.dart';

// ─── Date preset enum ─────────────────────────────────────────────────────────

enum _DatePreset {
  last30('Last 30 days'),
  last3m('Last 3 months'),
  last6m('Last 6 months'),
  thisYear('This year'),
  thisFY('This FY'),
  lastFY('Last FY'),
  allTime('All time'),
  custom('Custom');

  final String label;
  const _DatePreset(this.label);
}

enum _InvoiceFilter { all, paid, partial, unpaid, overdue }

enum _CurrencyScope { selected, all }

enum _CustomerReportMode { overview, statements }

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedIndex = 0;
  final Set<int> _loadedTabs = {};
  final Map<int, bool> _tabLoading = {};

  _DatePreset _preset = _DatePreset.last3m;
  _CurrencyScope _currencyScope = _CurrencyScope.selected;
  String _sym = 'Rs.';
  String _currencyCode = 'INR';
  String _currencyName = 'Indian Rupee';
  String _datePattern = DateFormatOption.ddmmyyyy.key;
  DateTime? _customFrom;
  DateTime? _customTo;

  RevenueKpi _kpi = RevenueKpi.empty;
  List<MonthlyPoint> _trend = [];
  int _missingCostItemCount = 0;
  StatusBreakdown _status = StatusBreakdown.empty;
  List<AgedReceivable> _aged = [];
  List<TaxBucket> _taxBuckets = [];
  List<TopCustomer> _topCustomers = [];
  List<TopProduct> _topProducts = [];
  List<CustomerStatementCustomer> _statementCustomers = [];
  List<CustomerStatement> _customerStatements = [];
  String? _statementCustomerKey;
  String? _statementCurrencyCode;
  _CustomerReportMode _customerMode = _CustomerReportMode.overview;

  // Table pagination state
  int _agedPage = 0;
  int _agedPageSize = 10;
  int _customersPage = 0;
  int _customersPageSize = 10;
  int _productsPage = 0;
  int _productsPageSize = 10;
  bool _rankProductsByProfit = false;
  QuotationStats _quotStats = QuotationStats.empty;
  List<InvoiceStatusRow> _invoiceList = [];
  _InvoiceFilter _invoiceFilter = _InvoiceFilter.all;
  int _invoicePage = 0;
  int _invoicePageSize = 25;

  // Formatting
  final _fmt = NumberFormat('#,##0.00');
  final _fmtInt = NumberFormat('#,##0');

  String? get _reportCurrencyCode =>
      _currencyScope == _CurrencyScope.selected ? _currencyCode : null;

  String get _currencyScopeLabel => switch (_currencyScope) {
        _CurrencyScope.selected => _currencyCode,
        _CurrencyScope.all => 'All currencies',
      };

  String _money(num value) {
    final amount = _fmt.format(value);
    return _currencyScope == _CurrencyScope.selected ? '$_sym $amount' : amount;
  }

  String _statementMoney(CustomerStatement statement, num value) =>
      '${statement.currencySymbol} ${_fmt.format(value)}';

  CustomerStatementCustomer? get _selectedStatementCustomer {
    final key = _statementCustomerKey;
    if (key == null) return null;
    for (final customer in _statementCustomers) {
      if (customer.key == key) return customer;
    }
    return null;
  }

  List<CustomerStatement> get _visibleCustomerStatements {
    if (_currencyScope != _CurrencyScope.all) return _customerStatements;
    if (_customerStatements.isEmpty) return const [];
    final code = _statementCurrencyCode;
    if (code == null) return [_customerStatements.first];
    final match = _customerStatements.where((s) => s.currencyCode == code);
    return match.isEmpty ? [_customerStatements.first] : match.toList();
  }

  String? _resolvedStatementCurrency(List<CustomerStatement> statements) {
    if (statements.isEmpty) return null;
    final current = _statementCurrencyCode;
    if (current != null && statements.any((s) => s.currencyCode == current)) {
      return current;
    }
    return statements.first.currencyCode;
  }

  String _formatDate(DateTime date) => DateFormat(_datePattern).format(date);

  String _formatStoredDate(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : _formatDate(parsed);
  }

  (DateTime, DateTime) get _range {
    final now = DateTime.now();

    // Indian financial year: Apr 1 -> Mar 31
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;

    return switch (_preset) {
      _DatePreset.last30 => (now.subtract(const Duration(days: 30)), now),
      _DatePreset.last3m => (DateTime(now.year, now.month - 3, now.day), now),
      _DatePreset.last6m => (DateTime(now.year, now.month - 6, now.day), now),
      _DatePreset.thisYear => (DateTime(now.year, 1, 1), now),
      _DatePreset.thisFY => (DateTime(fyStartYear, 4, 1), now),
      _DatePreset.lastFY => (
          DateTime(fyStartYear - 1, 4, 1),
          DateTime(fyStartYear, 4, 1).subtract(const Duration(milliseconds: 1)),
        ),
      _DatePreset.allTime => (DateTime(2000, 1, 1), now),
      _DatePreset.custom => (
          _customFrom ?? now.subtract(const Duration(days: 30)),
          _customTo ?? now,
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadReportSettings();
    _loadTab(0);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadReportSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final results = await Future.wait([
      settingsRepo.getSetting(SettingKey.currency),
      settingsRepo.getDateFormat(),
    ]);
    final code = (results[0] as String?) ?? 'INR';
    final currency = SupportedCurrencies.all.firstWhere((c) => c.code == code,
        orElse: () => SupportedCurrencies.all.first);
    final dateFormat = results[1] as DateFormatOption;
    if (mounted) {
      setState(() {
        _sym = currency.symbol;
        _currencyCode = currency.code;
        _currencyName = currency.name;
        _datePattern = dateFormat.key;
      });
    }
  }

  Future<void> _invalidateAndReload() async {
    if(!mounted) return;
    setState(() {
      _loadedTabs.clear();
      _tabLoading.clear();
    });
    await _loadReportSettings();
    _loadTab(_selectedIndex);
  }

  void _onCurrencyScopeChange(_CurrencyScope scope) {
    if (_currencyScope == scope || !mounted) return;
    setState(() {
      _currencyScope = scope;
      _statementCurrencyCode = null;
      _loadedTabs.clear();
      _tabLoading.clear();
    });
    _loadTab(_selectedIndex);
  }

  void _onPeriodChange(_DatePreset p) {
    if (_preset == p || !mounted) return;
    setState(() {
      _preset = p;
      _loadedTabs.clear();
      _tabLoading.clear();
    });
    _loadTab(_selectedIndex);
  }

  Future<void> _loadTab(int index) async {
    if (_tabLoading[index] == true || !mounted) return;
    setState(() => _tabLoading[index] = true);
    final (from, to) = _range;
    try {
      switch (index) {
        case 0:
          final r = await Future.wait([
            ref.read(reportRepositoryProvider).getRevenueSummary(from, to,
                currencyCode: _reportCurrencyCode),
            ref.read(reportRepositoryProvider).getMonthlyRevenueTrend(from, to,
                currencyCode: _reportCurrencyCode),
            ref.read(reportRepositoryProvider).getMissingCostItemCount(from, to,
                currencyCode: _reportCurrencyCode),
          ]);
          if (!mounted) return;
          setState(() {
            _kpi = r[0] as RevenueKpi;
            _trend = (r[1] as List).cast<MonthlyPoint>();
            _missingCostItemCount = r[2] as int;
          });
        case 1:
          final r = await Future.wait([
            ref.read(reportRepositoryProvider).getPaymentStatusBreakdown(from, to,
                currencyCode: _reportCurrencyCode),
            ref.read(reportRepositoryProvider).getAgedReceivables(currencyCode: _reportCurrencyCode),
          ]);
          if (!mounted) return;
          setState(() {
            _status = r[0] as StatusBreakdown;
            _aged = (r[1] as List).cast<AgedReceivable>();
            _agedPage = 0;
          });
        case 2:
          final buckets = await ref.read(reportRepositoryProvider).getTaxByRate(from, to,
              currencyCode: _reportCurrencyCode);
          if (!mounted) return;
          setState(() => _taxBuckets = buckets);
        case 3:
          final r = await Future.wait([
            ref.read(reportRepositoryProvider).getTopCustomers(from, to,
                currencyCode: _reportCurrencyCode),
            ref.read(reportRepositoryProvider).getStatementCustomers(
                currencyCode: _reportCurrencyCode),
          ]);
          final customers = (r[0] as List).cast<TopCustomer>();
          final statementCustomers =
              (r[1] as List).cast<CustomerStatementCustomer>();
          var selectedCustomer = _statementCustomerKey;
          if (statementCustomers.isEmpty) {
            selectedCustomer = null;
          } else if (selectedCustomer == null ||
              !statementCustomers.any((c) => c.key == selectedCustomer)) {
            selectedCustomer = statementCustomers.first.key;
          }
          final statements = selectedCustomer == null
              ? <CustomerStatement>[]
              : await ref.read(reportRepositoryProvider).getCustomerStatements(
                  selectedCustomer,
                  from,
                  to,
                  currencyCode: _reportCurrencyCode,
                );
          if (!mounted) return;
          setState(() {
            _topCustomers = customers;
            _statementCustomers = statementCustomers;
            _statementCustomerKey = selectedCustomer;
            _customerStatements = statements;
            _statementCurrencyCode = _resolvedStatementCurrency(statements);
            _customersPage = 0;
          });
        case 4:
          final r = await Future.wait([
            ref.read(reportRepositoryProvider).getTopProducts(from, to,
                currencyCode: _reportCurrencyCode,
                rankByProfit: _rankProductsByProfit),
            ref.read(reportRepositoryProvider).getMissingCostItemCount(from, to,
                currencyCode: _reportCurrencyCode),
          ]);
          if (!mounted) return;
          setState(() {
            _topProducts = r[0] as List<TopProduct>;
            _missingCostItemCount = r[1] as int;
            _productsPage = 0;
          });
        case 5:
          final stats = await ref.read(reportRepositoryProvider).getQuotationStats(
            from,
            to,
            currencyCode: _reportCurrencyCode,
          );
          if (!mounted) return;
          setState(() => _quotStats = stats);
        case 6:
          final list = await ref.read(reportRepositoryProvider).getInvoiceStatusList(
            from,
            to,
            currencyCode: _reportCurrencyCode,
          );
          if (!mounted) return;
          setState(() {
            _invoiceList = list;
            _invoicePage = 0;
          });
      }
      if (mounted) {
        setState(() {
          _loadedTabs.add(index);
          _tabLoading[index] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _tabLoading[index] = false);
    }
  }

  Future<void> _loadCustomerStatement(String customerKey) async
  {
    if(!mounted) return;
    setState(() {
      _statementCustomerKey = customerKey;
      _tabLoading[3] = true;
    });
    final (from, to) = _range;
    try {
      final statements = await ref.read(reportRepositoryProvider).getCustomerStatements(
        customerKey,
        from,
        to,
        currencyCode: _reportCurrencyCode,
      );
      if (!mounted) return;
      setState(() {
        _customerStatements = statements;
        _statementCurrencyCode = _resolvedStatementCurrency(statements);
        _tabLoading[3] = false;
      });
    } catch (_) {
      if (mounted) setState(() => _tabLoading[3] = false);
    }
  }

  Future<void> _pickStatementCustomer() async {
    if (_statementCustomers.isEmpty) return;
    final selectedKey = await showDialog<String>(
      context: context,
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalized = query.trim().toLowerCase();
            final customers = normalized.isEmpty
                ? _statementCustomers
                : _statementCustomers.where((customer) {
                    return customer.name.toLowerCase().contains(normalized) ||
                        customer.key.toLowerCase().contains(normalized);
                  }).toList();
            return AlertDialog(
              title: const Text('Select customer'),
              content: SizedBox(
                width: 520,
                height: 460,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search customer',
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: customers.isEmpty
                          ? Center(
                              child: Text('No customers match this search',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600)),
                            )
                          : ListView.separated(
                              itemCount: customers.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                final selected =
                                    customer.key == _statementCustomerKey;
                                return ListTile(
                                  dense: true,
                                  title: Text(customer.name,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      '${customer.invoiceCount} invoice${customer.invoiceCount == 1 ? '' : 's'}'),
                                  trailing: selected
                                      ? const Icon(Icons.check,
                                          color: Color(0xFF16A34A))
                                      : null,
                                  onTap: () =>
                                      Navigator.pop(context, customer.key),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selectedKey != null && selectedKey != _statementCustomerKey) {
      await _loadCustomerStatement(selectedKey);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _customFrom ?? now.subtract(const Duration(days: 30)),
      end: _customTo ?? now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initialRange,
      helpText: 'Select date range (max 1 year)',
      saveText: 'Apply',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              ColorScheme.light(primary: Theme.of(context).primaryColor),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
            child: child!,
          ),
        ),
      ),
    );
    if (picked == null) return;

    final days = picked.end.difference(picked.start).inDays;
    if (days > 366) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum range is 1 year. End date clamped.'),
          duration: Duration(seconds: 3),
        ),
      );
      _customFrom = picked.start;
      _customTo = picked.start.add(const Duration(days: 365));
    } else {
      _customFrom = picked.start;
      _customTo = picked.end;
    }
    if(!mounted) return;
    setState(() {
      _preset = _DatePreset.custom;
      _loadedTabs.clear();
      _tabLoading.clear();
    });
    _loadTab(_selectedIndex);
  }

  Future<void> _saveCsv(String csv, String filename) async {
    String? savePath;
    try {
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Report',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
    } catch (_) {
      // FilePicker not supported on this platform, fall back to Documents dir
      final dir = await getApplicationDocumentsDirectory();
      savePath = '${dir.path}/$filename';
    }
    if (savePath == null) return; // user cancelled
    await File(savePath).writeAsString('﻿$csv'); // BOM for Excel
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: $savePath'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  static const _navItems = [
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Revenue'),
    (
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      'Receivables'
    ),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Tax'),
    (Icons.people_outline, Icons.people, 'Customers'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
    (Icons.request_quote_outlined, Icons.request_quote, 'Quotations'),
    (Icons.list_alt_outlined, Icons.list_alt, 'Invoice Status'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isCurrentTabLoading = _tabLoading[_selectedIndex] == true;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isCurrentTabLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _invalidateAndReload,
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(primary),
          const VerticalDivider(
              width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: Container(
              color: Colors.white,
              child: isCurrentTabLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Color primary) {
    return Container(
      width: 192,
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // ── Nav items ──
          for (int i = 0; i < _navItems.length; i++) _navItem(i, primary),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          // ── Currency scope ──
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('CURRENCY',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
          ),
          _currencyScopeItem(_CurrencyScope.selected, primary),
          _currencyScopeItem(_CurrencyScope.all, primary),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          // ── Period filter ──
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('PERIOD',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final p in _DatePreset.values) _periodItem(p, primary),
                  if (_preset == _DatePreset.custom &&
                      _customFrom != null &&
                      _customTo != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 2, 16, 8),
                      child: Text(
                        '${_formatDate(_customFrom!)} –\n${_formatDate(_customTo!)}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyScopeItem(_CurrencyScope scope, Color primary) {
    final sel = _currencyScope == scope;
    final label = switch (scope) {
      _CurrencyScope.selected => 'Current selected currency ($_currencyName)',
      _CurrencyScope.all => 'All currencies',
    };
    return InkWell(
      onTap: () => _onCurrencyScopeChange(scope),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(
              sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 15,
              color: sel ? primary : const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: sel
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, Color primary) {
    final (iconOut, iconFilled, label) = _navItems[index];
    final sel = _selectedIndex == index;
    return InkWell(
      onTap: () {
        if (_selectedIndex == index || !mounted) return;
        setState(() => _selectedIndex = index);
        if (!_loadedTabs.contains(index) && _tabLoading[index] != true) {
          _loadTab(index);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(sel ? iconFilled : iconOut,
                size: 18, color: sel ? primary : const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    color: sel ? primary : const Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _periodItem(_DatePreset p, Color primary) {
    final sel = _preset == p;
    final isCustom = p == _DatePreset.custom;
    return InkWell(
      onTap: () => isCustom ? _pickCustomRange() : _onPeriodChange(p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(
              sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 15,
              color: sel ? primary : const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 8),
            Text(isCustom ? 'Custom…' : p.label,
                style: TextStyle(
                    fontSize: 13,
                    color:
                        sel ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_selectedIndex) {
      0 => _buildRevenue(),
      1 => _buildReceivables(),
      2 => _buildTax(),
      3 => _buildTopCustomers(),
      4 => _buildTopProducts(),
      5 => _buildQuotations(),
      6 => _buildInvoiceStatus(),
      _ => const SizedBox.shrink(),
    };
  }

  // ─── Shared widgets ─────────────────────────────────────────────────────────

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _cardTitle(String text, {Widget? trailing}) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPagination({
    required int currentPage,
    required int pageSize,
    required int total,
    required void Function(int) onPageChange,
    required void Function(int) onSizeChange,
  }) {
    final totalPages = (total / pageSize).ceil().clamp(1, 999999);
    final start = currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize).clamp(0, total);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Rows per page:',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: pageSize,
                underline: const SizedBox(),
                items: [10, 25, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (n) {
                  if (n != null) onSizeChange(n);
                },
              ),
              const SizedBox(width: 16),
              Text('$start – $end of $total',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0
                    ? () => onPageChange(currentPage - 1)
                    : null,
                tooltip: 'Previous',
              ),
              Text('Page ${currentPage + 1} of $totalPages',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade700)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChange(currentPage + 1)
                    : null,
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exportBtn(String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.download_outlined, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  Widget _missingCostBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_missingCostItemCount item${_missingCostItemCount == 1 ? '' : 's'} '
              'sold in this period have no purchase price set — profit/margin '
              'is understated for those items until a purchase price is added '
              'to the product.',
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(msg,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── Section 1: Revenue ─────────────────────────────────────────────────────

  Widget _buildRevenue() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          child: _kpiCard('Total Billed', _money(_kpi.billed),
                              const Color(0xFF002E78), Icons.receipt_long)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Total Collected',
                              _money(_kpi.collected),
                              const Color(0xFF16A34A),
                              Icons.check_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Outstanding',
                              _money(_kpi.outstanding),
                              const Color(0xFFDC2626),
                              Icons.schedule)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Avg Invoice Value',
                              _money(_kpi.avgInvoiceValue),
                              const Color(0xFF7C3AED),
                              Icons.trending_up)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Total Profit',
                              _money(_kpi.profit),
                              _kpi.profit < 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                              Icons.savings_outlined)),
                    ],
                  ),
                ),
              ),
              if (_missingCostItemCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _missingCostBanner(),
                ),

              // Monthly bar chart
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(
                      'Monthly Revenue Trend',
                      trailing: _exportBtn('Export CSV', () async {
                        final csv = ReportService.exportTrendCsv(_trend);
                        await _saveCsv(csv, 'revenue_trend_$ts.csv');
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmtInt.format(_kpi.invoiceCount)} invoice${_kpi.invoiceCount == 1 ? '' : 's'} in period · $_currencyScopeLabel',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    if (_trend.isEmpty)
                      _emptyState('No invoice data in this period')
                    else
                      SizedBox(
                        height: 240,
                        child: _buildBarChart(),
                      ),
                    if (_trend.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legend(const Color(0xFF3B82F6), 'Billed'),
                          const SizedBox(width: 24),
                          _legend(const Color(0xFF22C55E), 'Collected'),
                          const SizedBox(width: 24),
                          _legend(const Color(0xFF7C3AED), 'Profit'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  String _abbreviateNum(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return _fmtInt.format(v);
  }

  Widget _buildBarChart() {
    final maxY = _trend
            .map((p) =>
                [p.billed, p.collected, p.profit].reduce((a, b) => a > b ? a : b))
            .fold(0.0, (a, b) => a > b ? a : b) *
        1.2;
    final minY = _trend
        .map((p) => p.profit)
        .fold(0.0, (a, b) => a < b ? a : b) *
        (_trend.any((p) => p.profit < 0) ? 1.2 : 1.0);

    final groups = _trend.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: e.value.billed,
            color: const Color(0xFF3B82F6),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: e.value.collected,
            color: const Color(0xFF22C55E),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: e.value.profit,
            color: const Color(0xFF7C3AED),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 100 : maxY,
        minY: minY,
        alignment: BarChartAlignment.spaceAround,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY == 0 ? 25 : maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, _) => Text(
                _abbreviateNum(value),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _trend.length) {
                  return const SizedBox.shrink();
                }
                final m = _trend[idx].month;
                // Format 'YYYY-MM' → 'MMM YY'
                try {
                  final dt = DateFormat('yyyy-MM').parse(m);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MMM yy').format(dt),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  );
                } catch (_) {
                  return Text(m, style: const TextStyle(fontSize: 9));
                }
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? 'Billed' : 'Collected';
              return BarTooltipItem(
                '$label\n${_money(rod.toY)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Section 2: Payment & Receivables ──────────────────────────────────────

  Widget _buildReceivables() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donut chart + legend row
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('Payment Status Breakdown'),
                    const SizedBox(height: 20),
                    if (_status.total == 0)
                      _emptyState('No invoices in this period')
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: _buildDonut(),
                          ),
                          const SizedBox(width: 32),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statusLegendRow(const Color(0xFF22C55E), 'Paid',
                                  _status.paid, _status.total),
                              const SizedBox(height: 12),
                              _statusLegendRow(const Color(0xFFF59E0B),
                                  'Partial', _status.partial, _status.total),
                              const SizedBox(height: 12),
                              _statusLegendRow(const Color(0xFFEF4444),
                                  'Unpaid', _status.unpaid, _status.total),
                              const SizedBox(height: 16),
                              Text(
                                '${_fmtInt.format(_status.total)} total invoices',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Aged receivables table
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _cardTitle(
                        'Aged Receivables (${_aged.length})',
                        trailing: _exportBtn('Export CSV', () async {
                          final csv =
                              ReportService.exportAgedReceivablesCsv(_aged);
                          await _saveCsv(csv, 'aged_receivables_$ts.csv');
                        }),
                      ),
                    ),
                    if (_aged.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _emptyState('No outstanding invoices'),
                      )
                    else ...[
                      _agedHeader(),
                      ..._aged
                          .skip(_agedPage * _agedPageSize)
                          .take(_agedPageSize)
                          .map(_agedRow),
                      _buildReportPagination(
                        currentPage: _agedPage,
                        pageSize: _agedPageSize,
                        total: _aged.length,
                        onPageChange: (p) {
                          if(!mounted) return;
                          setState(() => _agedPage = p);
                        },
                        onSizeChange: (s) {
                          if(!mounted) return;
                          setState(() {
                            _agedPageSize = s;
                            _agedPage = 0;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonut() {
    final total = _status.total;
    return PieChart(
      PieChartData(
        centerSpaceRadius: 60,
        sectionsSpace: 2,
        sections: [
          if (_status.paid > 0)
            PieChartSectionData(
              value: _status.paid.toDouble(),
              color: const Color(0xFF22C55E),
              title: '${(_status.paid / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              radius: 50,
            ),
          if (_status.partial > 0)
            PieChartSectionData(
              value: _status.partial.toDouble(),
              color: const Color(0xFFF59E0B),
              title: '${(_status.partial / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              radius: 50,
            ),
          if (_status.unpaid > 0)
            PieChartSectionData(
              value: _status.unpaid.toDouble(),
              color: const Color(0xFFEF4444),
              title: '${(_status.unpaid / total * 100).toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              radius: 50,
            ),
        ],
      ),
    );
  }

  Widget _statusLegendRow(Color color, String label, int count, int total) {
    final pct = total == 0 ? '0' : (count / total * 100).toStringAsFixed(1);
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text('$label  ',
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        Text('$count  ($pct%)',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _agedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: const [
          Expanded(flex: 3, child: _TableHead('Customer')),
          Expanded(flex: 3, child: _TableHead('Invoice ID')),
          Expanded(flex: 2, child: _TableHead('Outstanding', right: true)),
          Expanded(flex: 2, child: _TableHead('Days Overdue', right: true)),
          Expanded(flex: 2, child: _TableHead('Bucket', right: true)),
        ],
      ),
    );
  }

  Widget _agedRow(AgedReceivable r) {
    final d = r.daysOverdue;
    final (bucketLabel, bucketColor) = r.hasNoDueDate
        ? ('No Due Date', const Color(0xFF94A3B8))
        : switch (d) {
            0 => ('Current', const Color(0xFF64748B)),
            <= 30 => ('0–30 days', const Color(0xFF22C55E)),
            <= 60 => ('31–60 days', const Color(0xFFF59E0B)),
            <= 90 => ('61–90 days', const Color(0xFFEF4444)),
            _ => ('90+ days', const Color(0xFF991B1B)),
          };

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(r.customerName,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 3,
              child: Text(r.invoiceId,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(_money(r.outstanding),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626)))),
          Expanded(
              flex: 2,
              child: Text(r.hasNoDueDate ? '—' : '$d days',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bucketColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(bucketLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: bucketColor)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 3: Tax ─────────────────────────────────────────────────────────

  Widget _buildTax() {
    final totalTax = _taxBuckets.fold(0.0, (s, b) => s + b.taxCollected);
    final ts = DateTime.now().millisecondsSinceEpoch;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total tax KPI
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _kpiCard(
                            'Total Tax Collected',
                            _money(totalTax),
                            const Color(0xFF7C3AED),
                            Icons.account_balance_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpiCard(
                            'Tax Rate Buckets',
                            _taxBuckets.length.toString(),
                            const Color(0xFF0284C7),
                            Icons.pie_chart_outline),
                      ),
                      const SizedBox(width: 12),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),

              // Tax breakdown table
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _cardTitle(
                        'Tax Collected by Rate',
                        trailing: _exportBtn('Export CSV', () async {
                          final csv = ReportService.exportTaxCsv(_taxBuckets);
                          await _saveCsv(csv, 'tax_report_$ts.csv');
                        }),
                      ),
                    ),
                    if (_taxBuckets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _emptyState('No taxable items in this period'),
                      )
                    else ...[
                      _taxTableHeader(),
                      ..._taxBuckets.map((b) => _taxRow(b, totalTax)),
                      _taxTotalRow(totalTax),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taxTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _TableHead('Tax Rate (%)')),
          Expanded(flex: 3, child: _TableHead('Tax Collected', right: true)),
          Expanded(flex: 2, child: _TableHead('Share', right: true)),
        ],
      ),
    );
  }

  Widget _taxRow(TaxBucket b, double total) {
    final share =
        total == 0 ? '0' : (b.taxCollected / total * 100).toStringAsFixed(1);
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('${b.rate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B)))),
          Expanded(
              flex: 3,
              child: Text(_money(b.taxCollected),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF1E293B)))),
          Expanded(
              flex: 2,
              child: Text('$share%',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
        ],
      ),
    );
  }

  Widget _taxTotalRow(double total) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
        color: Color(0xFFF8FAFC),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Expanded(
              flex: 2,
              child: Text('Total',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)))),
          Expanded(
              flex: 3,
              child: Text(_money(total),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)))),
          const Expanded(
              flex: 2,
              child: Text('100%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B)))),
        ],
      ),
    );
  }

  // ─── Section 4: Top Customers ───────────────────────────────────────────────

  Widget _buildTopCustomers() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final maxCollected = _topCustomers.isEmpty
        ? 1.0
        : _topCustomers.first.collected.clamp(1.0, double.infinity);

    return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _customerModeChip(
                              _CustomerReportMode.overview, 'Overview'),
                          _customerModeChip(
                              _CustomerReportMode.statements, 'Statements'),
                        ],
                      ),
                    ),
                    if (_customerMode == _CustomerReportMode.overview)
                      _buildCustomerOverviewCard(ts, maxCollected)
                    else
                      _buildCustomerStatementsCard(ts),
                  ],
                ))));
  }

  Widget _customerModeChip(_CustomerReportMode mode, String label) {
    final selected = _customerMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF002E78).withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? const Color(0xFF002E78) : const Color(0xFF64748B),
      ),
      side: BorderSide(
          color: selected ? const Color(0xFF002E78) : const Color(0xFFE2E8F0)),
      onSelected: (_) {
        if(!mounted) return;
        setState(() => _customerMode = mode);
      },
    );
  }

  Widget _buildCustomerOverviewCard(int ts, double maxCollected) {
    return _sectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: _cardTitle(
              'Top ${_topCustomers.length} Customers by Revenue',
              trailing: _exportBtn('Export CSV', () async {
                final csv = ReportService.exportTopCustomersCsv(_topCustomers);
                await _saveCsv(csv, 'top_customers_$ts.csv');
              }),
            ),
          ),
          if (_topCustomers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState('No customer data in this period'),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: _topCustomers.take(5).map((c) {
                  final pct = c.collected / maxCollected;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(c.name,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: pct.clamp(0.0, 1.0),
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: Text(
                            _money(c.collected),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF002E78)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            _customerTableHeader(),
            ..._topCustomers
                .skip(_customersPage * _customersPageSize)
                .take(_customersPageSize)
                .toList()
                .asMap()
                .entries
                .map((e) => _customerRow(
                    _customersPage * _customersPageSize + e.key + 1, e.value)),
            _buildReportPagination(
              currentPage: _customersPage,
              pageSize: _customersPageSize,
              total: _topCustomers.length,
              onPageChange: (p) {
                if(!mounted) return;
                setState(() => _customersPage = p);
              },
              onSizeChange: (s) {
                if(!mounted) return;
                setState(() {
                  _customersPageSize = s;
                  _customersPage = 0;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerStatementsCard(int ts) {
    final selectedCustomer = _selectedStatementCustomer;
    final visibleStatements = _visibleCustomerStatements;
    return _sectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _statementCustomers.isEmpty
                        ? null
                        : _pickStatementCustomer,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 18),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedCustomer == null
                            ? 'Select customer'
                            : '${selectedCustomer.name} (${selectedCustomer.invoiceCount})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedCustomer == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currencyScope == _CurrencyScope.all &&
                    _customerStatements.isNotEmpty) ...[
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: _statementCurrencyCode ??
                          _customerStatements.first.currencyCode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _customerStatements
                          .map((statement) => DropdownMenuItem(
                                value: statement.currencyCode,
                                child: Text(
                                  statement.currencyCode,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null && mounted) {
                          setState(() => _statementCurrencyCode = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Align(
                  alignment: Alignment.topCenter,
                  child: _exportBtn('Export CSV', () async {
                    final csv = ReportService.exportCustomerStatementsCsv(
                        visibleStatements);
                    await _saveCsv(csv, 'customer_statement_$ts.csv');
                  }),
                ),
              ],
            ),
          ),
          if (_statementCustomers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState('No customers with invoices'),
            )
          else if (visibleStatements.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState('No statement activity for this customer'),
            )
          else
            ...visibleStatements.map(_customerStatementSection),
        ],
      ),
    );
  }

  Widget _customerStatementSection(CustomerStatement statement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text(statement.customerName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF002E78).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statement.currencyCode,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF002E78))),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _statementSummaryCards(statement),
        ),
        _statementTableHeader(),
        if (statement.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _emptyState('No transactions in this period'),
          )
        else
          ...statement.lines.asMap().entries.map(
              (entry) => _statementRow(statement, entry.key + 1, entry.value)),
      ],
    );
  }

  Widget _statementSummaryCards(CustomerStatement statement) {
    final cards = [
      _kpiCard('Opening', _statementMoney(statement, statement.openingBalance),
          const Color(0xFF64748B), Icons.account_balance_wallet),
      _kpiCard('Invoiced', _statementMoney(statement, statement.invoiced),
          const Color(0xFF002E78), Icons.receipt_long_outlined),
      _kpiCard('Paid', _statementMoney(statement, statement.paid),
          const Color(0xFF16A34A), Icons.payments_outlined),
      _kpiCard('Closing', _statementMoney(statement, statement.closingBalance),
          const Color(0xFF7C3AED), Icons.summarize_outlined),
      _kpiCard('Overdue', _statementMoney(statement, statement.overdueBalance),
          const Color(0xFFDC2626), Icons.warning_amber_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 5
            : width >= 760
                ? 3
                : width >= 500
                    ? 2
                    : 1;
        const spacing = 12.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, height: 112, child: card),
          ],
        );
      },
    );
  }

  Widget _statementTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          SizedBox(width: 48, child: _TableHead('SL')),
          Expanded(flex: 2, child: _TableHead('Date')),
          Expanded(flex: 2, child: _TableHead('Type')),
          Expanded(flex: 3, child: _TableHead('Reference')),
          Expanded(flex: 4, child: _TableHead('Description')),
          Expanded(flex: 2, child: _TableHead('Debit', right: true)),
          Expanded(flex: 2, child: _TableHead('Credit', right: true)),
          Expanded(flex: 2, child: _TableHead('Balance', right: true)),
        ],
      ),
    );
  }

  Widget _statementRow(
      CustomerStatement statement, int rank, CustomerStatementLine line) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text('$rank',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
          Expanded(
              flex: 2,
              child: Text(_formatStoredDate(line.date),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
          Expanded(
              flex: 2,
              child: Text(line.type,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: line.type == 'Payment'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF002E78)))),
          Expanded(
              flex: 3,
              child: Text(line.reference,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 4,
              child: Text(line.description,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(
                  line.debit > 0 ? _statementMoney(statement, line.debit) : '-',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
          Expanded(
              flex: 2,
              child: Text(
                  line.credit > 0
                      ? _statementMoney(statement, line.credit)
                      : '-',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF16A34A)))),
          Expanded(
              flex: 2,
              child: Text(_statementMoney(statement, line.balance),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }

  Widget _customerTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          SizedBox(width: 48, child: _TableHead('SL')),
          Expanded(flex: 4, child: _TableHead('Customer')),
          Expanded(flex: 1, child: _TableHead('Invoices', right: true)),
          Expanded(flex: 2, child: _TableHead('Billed', right: true)),
          Expanded(flex: 2, child: _TableHead('Collected', right: true)),
          Expanded(flex: 2, child: _TableHead('Outstanding', right: true)),
        ],
      ),
    );
  }

  Widget _customerRow(int rank, TopCustomer c) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text('$rank',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
          Expanded(
              flex: 4,
              child: Text(c.name,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 1,
              child: Text('${c.invoiceCount}',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(
              flex: 2,
              child: Text(_money(c.billed),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
          Expanded(
              flex: 2,
              child: Text(_money(c.collected),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A)))),
          Expanded(
              flex: 2,
              child: Text(c.outstanding > 0 ? _money(c.outstanding) : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: c.outstanding > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF94A3B8)))),
        ],
      ),
    );
  }

  // ─── Section 5: Top Products ─────────────────────────────────────────────────

  Widget _buildTopProducts() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final maxRevenue = _topProducts.isEmpty
        ? 1.0
        : _topProducts.first.revenue.clamp(1.0, double.infinity);

    return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: _cardTitle(
                              'Top ${_topProducts.length} Products / Services by ${_rankProductsByProfit ? 'Profit' : 'Revenue'}',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      if(!mounted) return;
                                      setState(() => _rankProductsByProfit =
                                          !_rankProductsByProfit);
                                      _loadTab(4);
                                    },
                                    icon: Icon(
                                        _rankProductsByProfit
                                            ? Icons.trending_up
                                            : Icons.payments_outlined,
                                        size: 16),
                                    label: Text(
                                        _rankProductsByProfit
                                            ? 'Rank: Profit'
                                            : 'Rank: Revenue',
                                        style: const TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF64748B),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  _exportBtn('Export CSV', () async {
                                    final csv =
                                        ReportService.exportTopProductsCsv(
                                            _topProducts);
                                    await _saveCsv(
                                        csv, 'top_products_$ts.csv');
                                  }),
                                ],
                              ),
                            ),
                          ),
                          if (_missingCostItemCount > 0)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: _missingCostBanner(),
                            ),
                          if (_topProducts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child:
                                  _emptyState('No product data in this period'),
                            )
                          else ...[
                            // Horizontal bars
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Column(
                                children: _topProducts.take(10).map((p) {
                                  final pct = p.revenue / maxRevenue;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 160,
                                          child: Text(p.name,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF1E293B)),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                              FractionallySizedBox(
                                                widthFactor:
                                                    pct.clamp(0.0, 1.0),
                                                child: Container(
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF7C3AED),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 110,
                                          child: Text(
                                            _money(p.revenue),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF7C3AED)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Full table
                            _productTableHeader(),
                            ..._topProducts
                                .skip(_productsPage * _productsPageSize)
                                .take(_productsPageSize)
                                .toList()
                                .asMap()
                                .entries
                                .map((e) => _productRow(
                                    _productsPage * _productsPageSize +
                                        e.key +
                                        1,
                                    e.value)),
                            _buildReportPagination(
                              currentPage: _productsPage,
                              pageSize: _productsPageSize,
                              total: _topProducts.length,
                              onPageChange: (p) {
                                if(!mounted) return;
                                setState(() => _productsPage = p);
                              },
                              onSizeChange: (s) {
                                if(!mounted) return;
                                setState(() {
                                  _productsPageSize = s;
                                  _productsPage = 0;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ))));
  }

  Widget _productTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          SizedBox(width: 48, child: _TableHead('SL')),
          Expanded(flex: 4, child: _TableHead('Product / Service')),
          Expanded(flex: 2, child: _TableHead('Units Sold', right: true)),
          Expanded(flex: 2, child: _TableHead('Revenue', right: true)),
          Expanded(flex: 2, child: _TableHead('Discount Given', right: true)),
          Expanded(flex: 2, child: _TableHead('Profit', right: true)),
          Expanded(flex: 1, child: _TableHead('Margin', right: true)),
        ],
      ),
    );
  }

  Widget _productRow(int rank, TopProduct p) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text('$rank',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
          Expanded(
              flex: 4,
              child: Text(p.name,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(_fmtInt.format(p.unitsSold),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(
              flex: 2,
              child: Text(_money(p.revenue),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C3AED)))),
          Expanded(
              flex: 2,
              child: Text(p.discountGiven > 0 ? _money(p.discountGiven) : '—',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(
              flex: 2,
              child: Text(_money(p.profit),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.profit < 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A)))),
          Expanded(
              flex: 1,
              child: Text('${p.marginPercent.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
        ],
      ),
    );
  }

  // ─── Section 6: Quotation Conversion ───────────────────────────────────────

  Widget _buildQuotations() {
    final q = _quotStats;
    return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _kpiCard(
                                  'Quotations Issued',
                                  _fmtInt.format(q.quotationsIssued),
                                  const Color(0xFF0284C7),
                                  Icons.request_quote_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kpiCard(
                                  'Invoices in Period',
                                  _fmtInt.format(q.invoicesInPeriod),
                                  const Color(0xFF16A34A),
                                  Icons.receipt_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kpiCard(
                                  'Conversion Rate',
                                  '${q.conversionRate.toStringAsFixed(1)}%',
                                  const Color(0xFF7C3AED),
                                  Icons.trending_up),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle('About Conversion Rate'),
                          const SizedBox(height: 12),
                          Text(
                            'Conversion rate = Invoices created ÷ Quotations issued × 100.\n'
                            'A rate above 100% means more invoices were raised than quotations in the selected period '
                            '(common when invoices are created directly without a prior quotation).\n\n'
                            'Note: this is a period-level ratio, not individual quote-to-invoice tracking.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ))));
  }

  // ─── Section 7: Invoice Status ─────────────────────────────────────────────

  List<InvoiceStatusRow> get _filteredInvoices => switch (_invoiceFilter) {
        _InvoiceFilter.all => _invoiceList,
        _InvoiceFilter.paid =>
          _invoiceList.where((r) => r.status == 'Paid').toList(),
        _InvoiceFilter.partial =>
          _invoiceList.where((r) => r.status == 'Partial').toList(),
        _InvoiceFilter.unpaid =>
          _invoiceList.where((r) => r.status == 'Unpaid').toList(),
        _InvoiceFilter.overdue =>
          _invoiceList.where((r) => r.isOverdue).toList(),
      };

  int _invoiceCount(String status) =>
      _invoiceList.where((r) => r.status == status).length;

  int get _overdueCount => _invoiceList.where((r) => r.isOverdue).length;

  String get _invoiceStatusRangeLabel {
    final (from, to) = _range;
    return '${_formatDate(from)} - ${_formatDate(to)}';
  }

  static const Map<String, Color> _statusColors = {
    'Paid': Color(0xFF16A34A),
    'Partial': Color(0xFFF59E0B),
    'Unpaid': Color(0xFF64748B),
    'Overdue': Color(0xFFDC2626),
  };

  Widget _buildInvoiceStatus() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final filtered = _filteredInvoices;
    final pageStart = _invoicePage * _invoicePageSize;
    final pageRows = filtered.skip(pageStart).take(_invoicePageSize).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text('Showing invoices dated $_invoiceStatusRangeLabel',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              // KPI summary row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          child: _kpiCard(
                              'Total Invoices',
                              _fmtInt.format(_invoiceList.length),
                              const Color(0xFF002E78),
                              Icons.receipt_long_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Paid',
                              _fmtInt.format(_invoiceCount('Paid')),
                              const Color(0xFF16A34A),
                              Icons.check_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Partial',
                              _fmtInt.format(_invoiceCount('Partial')),
                              const Color(0xFFF59E0B),
                              Icons.timelapse_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Unpaid',
                              _fmtInt.format(_invoiceCount('Unpaid')),
                              const Color(0xFF64748B),
                              Icons.remove_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              'Overdue',
                              _fmtInt.format(_overdueCount),
                              const Color(0xFFDC2626),
                              Icons.warning_amber_outlined)),
                    ],
                  ),
                ),
              ),
              // Table card
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: filter chips + export
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final f in _InvoiceFilter.values)
                                  _filterChip(f),
                              ],
                            ),
                          ),
                          _exportBtn('Export CSV', () async {
                            final csv =
                                ReportService.exportInvoiceStatusCsv(filtered);
                            await _saveCsv(csv, 'invoice_status_$ts.csv');
                          }),
                        ],
                      ),
                    ),
                    // Table header
                    _invoiceStatusHeader(),
                    // Rows
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _emptyState('No invoices match this filter'),
                      )
                    else ...[
                      ...pageRows.asMap().entries.map((e) =>
                          _invoiceStatusRow(pageStart + e.key + 1, e.value)),
                      _buildReportPagination(
                        currentPage: _invoicePage,
                        pageSize: _invoicePageSize,
                        total: filtered.length,
                        onPageChange: (p) {
                          if(!mounted) return;
                          setState(() => _invoicePage = p);
                        },
                        onSizeChange: (s) {
                          setState(() {
                            if(!mounted) return;
                            _invoicePageSize = s;
                            _invoicePage = 0;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(_InvoiceFilter f) {
    final sel = _invoiceFilter == f;
    final label = switch (f) {
      _InvoiceFilter.all => 'All (${_invoiceList.length})',
      _InvoiceFilter.paid => 'Paid (${_invoiceCount('Paid')})',
      _InvoiceFilter.partial => 'Partial (${_invoiceCount('Partial')})',
      _InvoiceFilter.unpaid => 'Unpaid (${_invoiceCount('Unpaid')})',
      _InvoiceFilter.overdue => 'Overdue ($_overdueCount)',
    };
    final color = switch (f) {
      _InvoiceFilter.paid => const Color(0xFF16A34A),
      _InvoiceFilter.partial => const Color(0xFFF59E0B),
      _InvoiceFilter.unpaid => const Color(0xFF64748B),
      _InvoiceFilter.overdue => const Color(0xFFDC2626),
      _ => const Color(0xFF002E78),
    };
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      selectedColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
        color: sel ? color : const Color(0xFF64748B),
      ),
      side: BorderSide(color: sel ? color : const Color(0xFFE2E8F0)),
      onSelected: (_) {
        if(!mounted) return;
        setState(() {
          _invoiceFilter = f;
          _invoicePage = 0;
        });
      },
    );
  }

  Widget _invoiceStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          SizedBox(width: 32, child: _TableHead('#')),
          Expanded(flex: 2, child: _TableHead('Date')),
          Expanded(flex: 3, child: _TableHead('Invoice ID')),
          Expanded(flex: 4, child: _TableHead('Customer')),
          Expanded(flex: 2, child: _TableHead('Total', right: true)),
          Expanded(flex: 2, child: _TableHead('Paid', right: true)),
          Expanded(flex: 2, child: _TableHead('Outstanding', right: true)),
          Expanded(flex: 2, child: _TableHead('Status', right: true)),
        ],
      ),
    );
  }

  Widget _invoiceStatusRow(int rank, InvoiceStatusRow r) {
    final statusColor = _statusColors[r.status] ?? const Color(0xFF64748B);
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          SizedBox(
              width: 32,
              child: Text('$rank',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
          Expanded(
              flex: 2,
              child: Text(_formatStoredDate(r.date),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
          Expanded(
              flex: 3,
              child: Text(r.id,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 4,
              child: Text(r.customerName,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(_money(r.total),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
          Expanded(
              flex: 2,
              child: Text(_money(r.paid),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF16A34A)))),
          Expanded(
              flex: 2,
              child: Text(r.outstanding > 0 ? _money(r.outstanding) : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: r.outstanding > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF94A3B8)))),
          Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.status,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                    if (r.isOverdue) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFDC2626).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Overdue',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626))),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Table header cell ────────────────────────────────────────────────────────

class _TableHead extends StatelessWidget {
  final String text;
  final bool right;

  const _TableHead(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }
}
