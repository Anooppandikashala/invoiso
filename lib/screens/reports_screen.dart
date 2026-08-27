import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/services/customer_statement_pdf_service.dart';
import 'package:invoiso/providers/repositories.dart';

import '../common/supported_currencies.dart';

// ─── Date preset enum ─────────────────────────────────────────────────────────

enum _DatePreset {
  last30,
  last3m,
  last6m,
  thisYear,
  thisFY,
  lastFY,
  //allTime,
  custom,
}

enum _InvoiceFilter { all, paid, partial, unpaid, overdue }

enum _CurrencyScope { selected, all }

enum _CustomerReportMode { overview, statements }

enum _DailyMode { today, last30, monthYear, custom }

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  final String? initialStatementCustomerKey;
  const ReportsScreen({super.key, this.initialStatementCustomerKey});

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
  List<DailyPoint> _dailyReport = [];
  int _dailyPage = 0;
  int _dailyPageSize = 25;
  _DailyMode _dailyMode = _DailyMode.today;
  int _dailyYear = DateTime.now().year;
  int _dailyMonth = DateTime.now().month;
  DateTime? _dailyCustomFrom;
  DateTime? _dailyCustomTo;
  _DailyMode _invoiceDateMode = _DailyMode.last30;
  int _invoiceYear = DateTime.now().year;
  int _invoiceMonth = DateTime.now().month;
  DateTime? _invoiceExactDay;
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

  bool _showFooterBranding = true;

  // Formatting
  final _fmt = NumberFormat('#,##0.00');
  final _fmtInt = NumberFormat('#,##0');

  String? get _reportCurrencyCode =>
      _currencyScope == _CurrencyScope.selected ? _currencyCode : null;

  String get _currencyScopeLabel => switch (_currencyScope) {
        _CurrencyScope.selected => _currencyCode,
        _CurrencyScope.all =>
          AppLocalizations.of(context)!.reportsAllCurrenciesLabel,
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
      //_DatePreset.allTime => (DateTime(2000, 1, 1), now),
      _DatePreset.custom => (
          _customFrom ?? now.subtract(const Duration(days: 30)),
          _customTo ?? now,
        ),
    };
  }

  (DateTime, DateTime) get _dailyRange {
    final now = DateTime.now();
    if (_dailyMode == _DailyMode.today) {
      return (DateTime(now.year, now.month, now.day), now);
    }
    if (_dailyMode == _DailyMode.last30) {
      return (now.subtract(const Duration(days: 30)), now);
    }
    if (_dailyMode == _DailyMode.custom) {
      return (_dailyCustomFrom ?? now, _dailyCustomTo ?? now);
    }
    final start = DateTime(_dailyYear, _dailyMonth, 1);
    final end = DateTime(_dailyYear, _dailyMonth + 1, 1)
        .subtract(const Duration(days: 1));
    return (start, end.isAfter(now) ? now : end);
  }

  (DateTime, DateTime) get _invoiceStatusRange {
    final exact = _invoiceExactDay;
    if (exact != null) return (exact, exact);
    final now = DateTime.now();
    if (_invoiceDateMode == _DailyMode.last30) {
      return (now.subtract(const Duration(days: 30)), now);
    }
    final start = DateTime(_invoiceYear, _invoiceMonth, 1);
    final end = DateTime(_invoiceYear, _invoiceMonth + 1, 1)
        .subtract(const Duration(days: 1));
    return (start, end.isAfter(now) ? now : end);
  }

  @override
  void initState() {
    super.initState();
    final initialKey = widget.initialStatementCustomerKey;
    if (initialKey != null) {
      _selectedIndex = 3;
      _customerMode = _CustomerReportMode.statements;
      _statementCustomerKey = initialKey;
    }
    _init();
  }

  Future<void> _init() async {
    await _loadReportSettings();
    _loadTab(_selectedIndex);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadReportSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final showFooterBranding =
        await settingsRepo.getShowInvoiceFooterBranding();
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
        _showFooterBranding = showFooterBranding;
      });
    }
  }

  Future<void> _invalidateAndReload() async {
    if (!mounted) return;
    setState(() {
      _loadedTabs.clear();
      _tabLoading.clear();
      _invoiceExactDay = null;
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
            ref
                .read(reportRepositoryProvider)
                .getRevenueSummary(from, to, currencyCode: _reportCurrencyCode),
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
            ref.read(reportRepositoryProvider).getPaymentStatusBreakdown(
                from, to,
                currencyCode: _reportCurrencyCode),
            ref
                .read(reportRepositoryProvider)
                .getAgedReceivables(currencyCode: _reportCurrencyCode),
          ]);
          if (!mounted) return;
          setState(() {
            _status = r[0] as StatusBreakdown;
            _aged = (r[1] as List).cast<AgedReceivable>();
            _agedPage = 0;
          });
        case 2:
          final buckets = await ref
              .read(reportRepositoryProvider)
              .getTaxByRate(from, to, currencyCode: _reportCurrencyCode);
          if (!mounted) return;
          setState(() => _taxBuckets = buckets);
        case 3:
          final r = await Future.wait([
            ref
                .read(reportRepositoryProvider)
                .getTopCustomers(from, to, currencyCode: _reportCurrencyCode),
            ref
                .read(reportRepositoryProvider)
                .getStatementCustomers(currencyCode: _reportCurrencyCode),
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
          final stats =
              await ref.read(reportRepositoryProvider).getQuotationStats(
                    from,
                    to,
                    currencyCode: _reportCurrencyCode,
                  );
          if (!mounted) return;
          setState(() => _quotStats = stats);
        case 6:
          final (ifrom, ito) = _invoiceStatusRange;
          final list =
              await ref.read(reportRepositoryProvider).getInvoiceStatusList(
                    ifrom,
                    ito,
                    currencyCode: _reportCurrencyCode,
                  );
          if (!mounted) return;
          setState(() {
            _invoiceList = list;
            _invoicePage = 0;
          });
        case 7:
          final (dFrom, dTo) = _dailyRange;
          final r = await Future.wait([
            ref.read(reportRepositoryProvider).getDailyRevenueTrend(dFrom, dTo,
                currencyCode: _reportCurrencyCode),
            ref.read(reportRepositoryProvider).getMissingCostItemCount(
                dFrom, dTo,
                currencyCode: _reportCurrencyCode),
          ]);
          if (!mounted) return;
          setState(() {
            _dailyReport = r[0] as List<DailyPoint>;
            _missingCostItemCount = r[1] as int;
            _dailyPage = 0;
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

  Future<void> _loadCustomerStatement(String customerKey) async {
    if (!mounted) return;
    setState(() {
      _statementCustomerKey = customerKey;
      _tabLoading[3] = true;
    });
    final (from, to) = _range;
    try {
      final statements =
          await ref.read(reportRepositoryProvider).getCustomerStatements(
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
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.reportsSelectCustomerTitle),
              content: SizedBox(
                width: 520,
                height: 460,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.createInvoiceSearchCustomerLabel,
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: customers.isEmpty
                          ? Center(
                              child: Text(
                                  l10n.reportsNoCustomersMatchSearchMessage,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            )
                          : ListView.separated(
                              itemCount: customers.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                final selected =
                                    customer.key == _statementCustomerKey;
                                return ListTile(
                                  dense: true,
                                  title: Text(customer.name,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      l10n.dashboardInvoiceCountLabel(
                                          customer.invoiceCount)),
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
                  child: Text(l10n.actionCancel),
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
    final rawNow = DateTime.now();
    final now = DateTime(rawNow.year, rawNow.month, rawNow.day);
    final initialRange = DateTimeRange(
      start: _customFrom ?? now.subtract(const Duration(days: 30)),
      end: _customTo ?? now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initialRange,
      helpText:
          AppLocalizations.of(context)!.reportsSelectDateRangeMaxYearHelpText,
      saveText: AppLocalizations.of(context)!.actionApply,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: Theme.of(context).primaryColor),
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
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.reportsMaxRangeOneYearMessage),
          duration: const Duration(seconds: 3),
        ),
      );
      _customFrom = picked.start;
      _customTo = picked.start.add(const Duration(days: 365));
    } else {
      _customFrom = picked.start;
      _customTo = picked.end;
    }
    if (!mounted) return;
    setState(() {
      _preset = _DatePreset.custom;
      _loadedTabs.clear();
      _tabLoading.clear();
    });
    _loadTab(_selectedIndex);
  }

  Future<void> _pickDailyCustomRange() async {
    final rawNow = DateTime.now();
    final now = DateTime(rawNow.year, rawNow.month, rawNow.day);
    final initialRange = DateTimeRange(
      start: _dailyCustomFrom ?? now.subtract(const Duration(days: 30)),
      end: _dailyCustomTo ?? now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initialRange,
      helpText:
          AppLocalizations.of(context)!.reportsSelectDailyRangeMaxDaysHelpText,
      saveText: AppLocalizations.of(context)!.actionApply,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: Theme.of(context).primaryColor),
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
    if (days > 31) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .reportsMaxRangeThirtyOneDaysMessage),
          duration: const Duration(seconds: 3),
        ),
      );
      _dailyCustomFrom = picked.start;
      _dailyCustomTo = picked.start.add(const Duration(days: 31));
    } else {
      _dailyCustomFrom = picked.start;
      _dailyCustomTo = picked.end;
    }
    if (!mounted) return;
    setState(() => _dailyMode = _DailyMode.custom);
    _loadTab(7);
  }

  Future<void> _saveCsv(String csv, String filename) async {
    final l10n = AppLocalizations.of(context)!;
    final csvBytes = utf8.encode('﻿$csv'); // BOM for Excel
    String? savePath;
    try {
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.reportsSaveCsvReportTitle,
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Platform.isAndroid ? csvBytes : null,
      );
    } catch (_) {
      // FilePicker not supported on this platform, fall back to Documents dir
      final dir = await getApplicationDocumentsDirectory();
      savePath = '${dir.path}/$filename';
    }
    if (savePath == null) return; // user cancelled
    if (!Platform.isAndroid) {
      await File(savePath).writeAsBytes(csvBytes);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.reportsSavedAtMessage(savePath)),
        action: SnackBarAction(label: l10n.actionOk, onPressed: () {}),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _savePdf(Uint8List bytes, String filename) async {
    final l10n = AppLocalizations.of(context)!;
    String? savePath;
    try {
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.reportsSavePdfReportTitle,
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: Platform.isAndroid ? bytes : null,
      );
    } catch (_) {
      final dir = await getApplicationDocumentsDirectory();
      savePath = '${dir.path}/$filename';
    }
    if (savePath == null) return; // user cancelled
    if (!Platform.isAndroid) {
      await File(savePath).writeAsBytes(bytes);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.reportsSavedAtMessage(savePath)),
        action: SnackBarAction(label: l10n.actionOk, onPressed: () {}),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  // Icons only — labels are locale-dependent, see _navLabel(), since a
  // static const list can't hold a BuildContext-dependent AppLocalizations
  // string.
  static const _navIcons = [
    (Icons.bar_chart_outlined, Icons.bar_chart),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
    (Icons.receipt_long_outlined, Icons.receipt_long),
    (Icons.people_outline, Icons.people),
    (Icons.inventory_2_outlined, Icons.inventory_2),
    (Icons.request_quote_outlined, Icons.request_quote),
    (Icons.list_alt_outlined, Icons.list_alt),
    (Icons.calendar_today_outlined, Icons.calendar_today),
  ];

  String _presetLabel(_DatePreset preset) {
    final l10n = AppLocalizations.of(context)!;
    return switch (preset) {
      _DatePreset.last30 => l10n.reportsPresetLast30DaysLabel,
      _DatePreset.last3m => l10n.reportsPresetLast3MonthsLabel,
      _DatePreset.last6m => l10n.reportsPresetLast6MonthsLabel,
      _DatePreset.thisYear => l10n.reportsPresetThisYearLabel,
      _DatePreset.thisFY => l10n.reportsPresetThisFYLabel,
      _DatePreset.lastFY => l10n.reportsPresetLastFYLabel,
      _DatePreset.custom => l10n.commonCustomEllipsisLabel,
    };
  }

  String _navLabel(int index) {
    final l10n = AppLocalizations.of(context)!;
    return switch (index) {
      0 => l10n.reportsNavRevenueLabel,
      1 => l10n.reportsNavReceivablesLabel,
      2 => l10n.reportsNavTaxLabel,
      3 => l10n.navCustomers,
      4 => l10n.navProducts,
      5 => l10n.navQuotations,
      6 => l10n.reportsNavInvoiceStatusLabel,
      _ => l10n.reportsNavDailyReportLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isCurrentTabLoading = _tabLoading[_selectedIndex] == true;
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.navReports,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
              tooltip: AppLocalizations.of(context)!.actionRefresh,
              onPressed: _invalidateAndReload,
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(primary),
          VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Theme.of(context).colorScheme.surfaceContainer,
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // ── Nav items ──
          for (int i = 0; i < _navIcons.length; i++) _navItem(i, primary),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(
                height: 1, color: Theme.of(context).colorScheme.outlineVariant),
          ),
          // ── Currency scope ──
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
                AppLocalizations.of(context)!.reportsCurrencySectionLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8)),
          ),
          _currencyScopeItem(_CurrencyScope.selected, primary),
          _currencyScopeItem(_CurrencyScope.all, primary),
          if (_selectedIndex != 6 && _selectedIndex != 7) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            // ── Period filter ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                  AppLocalizations.of(context)!.reportsPeriodSectionLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _currencyScopeItem(_CurrencyScope scope, Color primary) {
    final sel = _currencyScope == scope;
    final l10n = AppLocalizations.of(context)!;
    final label = switch (scope) {
      _CurrencyScope.selected =>
        l10n.reportsCurrentSelectedCurrencyLabel(_currencyName),
      _CurrencyScope.all => l10n.reportsAllCurrenciesLabel,
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
              color:
                  sel ? primary : Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: sel
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, Color primary) {
    final (iconOut, iconFilled) = _navIcons[index];
    final label = _navLabel(index);
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
                size: 18,
                color: sel
                    ? primary
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    color: sel
                        ? primary
                        : Theme.of(context).colorScheme.onSurfaceVariant)),
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
              color:
                  sel ? primary : Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(width: 8),
            Text(
                isCustom
                    ? AppLocalizations.of(context)!.commonCustomEllipsisLabel
                    : _presetLabel(p),
                style: TextStyle(
                    fontSize: 13,
                    color: sel
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
      7 => _buildDailyReport(),
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
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
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
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(l10n.invoiceMgmtRowsPerPageLabel,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13)),
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
              Text(l10n.reportsShowingRangeLabel(start, end, total),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0
                    ? () => onPageChange(currentPage - 1)
                    : null,
                tooltip: l10n.actionPrevious,
              ),
              Text(l10n.invoiceMgmtPageOfLabel(currentPage + 1, totalPages),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChange(currentPage + 1)
                    : null,
                tooltip: l10n.actionNext,
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
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
              AppLocalizations.of(context)!
                  .reportsMissingCostBannerMessage(_missingCostItemCount),
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
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
                size: 48, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(msg,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── Section 1: Revenue ─────────────────────────────────────────────────────

  Widget _buildRevenue() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final l10n = AppLocalizations.of(context)!;
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
                          child: _kpiCard(
                              l10n.reportsTotalBilledLabel,
                              _money(_kpi.billed),
                              const Color(0xFF002E78),
                              Icons.receipt_long)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.reportsTotalCollectedLabel,
                              _money(_kpi.collected),
                              const Color(0xFF16A34A),
                              Icons.check_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.dashboardOutstandingLabel,
                              _money(_kpi.outstanding),
                              const Color(0xFFDC2626),
                              Icons.schedule)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.reportsAvgInvoiceValueLabel,
                              _money(_kpi.avgInvoiceValue),
                              const Color(0xFF7C3AED),
                              Icons.trending_up)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.reportsTotalProfitLabel,
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
                      l10n.reportsMonthlyRevenueTrendTitle,
                      trailing:
                          _exportBtn(l10n.reportsExportCsvLabel, () async {
                        final csv = ReportService.exportTrendCsv(_trend);
                        await _saveCsv(csv, 'revenue_trend_$ts.csv');
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.reportsInvoiceCountInPeriodLabel(
                          _kpi.invoiceCount, _currencyScopeLabel),
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    if (_trend.isEmpty)
                      _emptyState(l10n.reportsNoInvoiceDataMessage)
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
                          _legend(
                              const Color(0xFF3B82F6), l10n.reportsBilledLabel),
                          const SizedBox(width: 24),
                          _legend(const Color(0xFF22C55E),
                              l10n.dashboardCollectedLabel),
                          const SizedBox(width: 24),
                          _legend(
                              const Color(0xFF7C3AED), l10n.reportsProfitLabel),
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
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
            .map((p) => [p.billed, p.collected, p.profit]
                .reduce((a, b) => a > b ? a : b))
            .fold(0.0, (a, b) => a > b ? a : b) *
        1.2;
    final minY =
        _trend.map((p) => p.profit).fold(0.0, (a, b) => a < b ? a : b) *
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
            color: Theme.of(context).colorScheme.outlineVariant,
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
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
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
              final l10n = AppLocalizations.of(context)!;
              final label = rodIndex == 0
                  ? l10n.reportsBilledLabel
                  : l10n.dashboardCollectedLabel;
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
    final l10n = AppLocalizations.of(context)!;
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
                    _cardTitle(l10n.reportsPaymentStatusBreakdownTitle),
                    const SizedBox(height: 20),
                    if (_status.total == 0)
                      _emptyState(l10n.reportsNoInvoicesInPeriodMessage)
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
                              _statusLegendRow(
                                  const Color(0xFF22C55E),
                                  l10n.paymentStatusPaid,
                                  _status.paid,
                                  _status.total),
                              const SizedBox(height: 12),
                              _statusLegendRow(
                                  const Color(0xFFF59E0B),
                                  l10n.paymentStatusPartial,
                                  _status.partial,
                                  _status.total),
                              const SizedBox(height: 12),
                              _statusLegendRow(
                                  const Color(0xFFEF4444),
                                  l10n.paymentStatusUnpaid,
                                  _status.unpaid,
                                  _status.total),
                              const SizedBox(height: 16),
                              Text(
                                l10n.reportsTotalInvoicesCountLabel(
                                    _status.total),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
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
                        l10n.reportsAgedReceivablesTitle(_aged.length),
                        trailing:
                            _exportBtn(l10n.reportsExportCsvLabel, () async {
                          final csv =
                              ReportService.exportAgedReceivablesCsv(_aged);
                          await _saveCsv(csv, 'aged_receivables_$ts.csv');
                        }),
                      ),
                    ),
                    if (_aged.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _emptyState(
                            l10n.reportsNoOutstandingInvoicesMessage),
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
                          if (!mounted) return;
                          setState(() => _agedPage = p);
                        },
                        onSizeChange: (s) {
                          if (!mounted) return;
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
            style: TextStyle(
                fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
        Text('$count  ($pct%)',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _agedHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(flex: 3, child: _TableHead(l10n.labelCustomer)),
          Expanded(flex: 3, child: _TableHead(l10n.reportsInvoiceIdLabel)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.dashboardOutstandingLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsDaysOverdueLabel, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsBucketLabel, right: true)),
        ],
      ),
    );
  }

  Widget _agedRow(AgedReceivable r) {
    final l10n = AppLocalizations.of(context)!;
    final d = r.daysOverdue;
    final (bucketLabel, bucketColor) = r.hasNoDueDate
        ? (
            l10n.reportsNoDueDateLabel,
            Theme.of(context).colorScheme.onSurfaceVariant
          )
        : switch (d) {
            0 => (
                l10n.reportsCurrentBucketLabel,
                Theme.of(context).colorScheme.onSurfaceVariant
              ),
            <= 30 => (l10n.reportsBucket0to30Label, const Color(0xFF22C55E)),
            <= 60 => (l10n.reportsBucket31to60Label, const Color(0xFFF59E0B)),
            <= 90 => (l10n.reportsBucket61to90Label, const Color(0xFFEF4444)),
            _ => (l10n.reportsBucket90PlusLabel, const Color(0xFF991B1B)),
          };

    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(r.customerName,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 3,
              child: Text(r.invoiceId,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              child: Text(r.hasNoDueDate ? '—' : l10n.reportsDaysCountLabel(d),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
    final l10n = AppLocalizations.of(context)!;

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
                            l10n.reportsTotalTaxCollectedLabel,
                            _money(totalTax),
                            const Color(0xFF7C3AED),
                            Icons.account_balance_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpiCard(
                            l10n.reportsTaxRateBucketsLabel,
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
                        l10n.reportsTaxCollectedByRateTitle,
                        trailing:
                            _exportBtn(l10n.reportsExportCsvLabel, () async {
                          final csv = ReportService.exportTaxCsv(_taxBuckets);
                          await _saveCsv(csv, 'tax_report_$ts.csv');
                        }),
                      ),
                    ),
                    if (_taxBuckets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _emptyState(l10n.reportsNoTaxableItemsMessage),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(flex: 2, child: _TableHead(l10n.fieldTaxRateLabel)),
          Expanded(
              flex: 3,
              child: _TableHead(l10n.reportsTaxCollectedLabel, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsShareLabel, right: true)),
        ],
      ),
    );
  }

  Widget _taxRow(TaxBucket b, double total) {
    final share =
        total == 0 ? '0' : (b.taxCollected / total * 100).toStringAsFixed(1);
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('${b.rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface))),
          Expanded(
              flex: 3,
              child: Text(_money(b.taxCollected),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface))),
          Expanded(
              flex: 2,
              child: Text('$share%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  Widget _taxTotalRow(double total) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1.5)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(AppLocalizations.of(context)!.fieldTotalLabel,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface))),
          Expanded(
              flex: 3,
              child: Text(_money(total),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface))),
          Expanded(
              flex: 2,
              child: Text('100%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
                              _CustomerReportMode.overview,
                              AppLocalizations.of(context)!
                                  .reportsOverviewLabel),
                          _customerModeChip(
                              _CustomerReportMode.statements,
                              AppLocalizations.of(context)!
                                  .reportsStatementsLabel),
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
        color: selected
            ? const Color(0xFF002E78)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
          color: selected
              ? const Color(0xFF002E78)
              : Theme.of(context).colorScheme.outlineVariant),
      onSelected: (_) {
        if (!mounted) return;
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
              AppLocalizations.of(context)!
                  .reportsTopCustomersByRevenueTitle(_topCustomers.length),
              trailing: _exportBtn(
                  AppLocalizations.of(context)!.reportsExportCsvLabel,
                  () async {
                final csv = ReportService.exportTopCustomersCsv(_topCustomers);
                await _saveCsv(csv, 'top_customers_$ts.csv');
              }),
            ),
          ),
          if (_topCustomers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState(
                  AppLocalizations.of(context)!.reportsNoCustomerDataMessage),
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
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
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
                if (!mounted) return;
                setState(() => _customersPage = p);
              },
              onSizeChange: (s) {
                if (!mounted) return;
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
    final l10n = AppLocalizations.of(context)!;
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
                      decoration: InputDecoration(
                        labelText: l10n.labelCustomer,
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedCustomer == null
                            ? l10n.reportsSelectCustomerTitle
                            : '${selectedCustomer.name} (${selectedCustomer.invoiceCount})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedCustomer == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
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
                      decoration: InputDecoration(
                        labelText: l10n.onboardingCurrencyLabel,
                        isDense: true,
                        border: const OutlineInputBorder(),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _exportBtn(l10n.reportsExportCsvLabel, () async {
                        final csv = ReportService.exportCustomerStatementsCsv(
                            visibleStatements);
                        await _saveCsv(csv, 'customer_statement_$ts.csv');
                      }),
                      const SizedBox(width: 4),
                      _exportBtn(l10n.customerMgmtExportPdfMenuLabel, () async {
                        if (visibleStatements.isEmpty) return;
                        final bytes = await CustomerStatementPdfService.export(
                          visibleStatements,
                          showFooterBranding: _showFooterBranding,
                        );
                        await _savePdf(bytes, 'customer_statement_$ts.pdf');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_statementCustomers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState(l10n.reportsNoCustomersWithInvoicesMessage),
            )
          else if (visibleStatements.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState(l10n.reportsNoStatementActivityMessage),
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
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
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
            child: _emptyState(
                AppLocalizations.of(context)!.reportsNoTransactionsMessage),
          )
        else
          ...statement.lines.asMap().entries.map(
              (entry) => _statementRow(statement, entry.key + 1, entry.value)),
      ],
    );
  }

  Widget _statementSummaryCards(CustomerStatement statement) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _kpiCard(
          l10n.reportsOpeningLabel,
          _statementMoney(statement, statement.openingBalance),
          Theme.of(context).colorScheme.onSurfaceVariant,
          Icons.account_balance_wallet),
      _kpiCard(
          l10n.reportsInvoicedLabel,
          _statementMoney(statement, statement.invoiced),
          const Color(0xFF002E78),
          Icons.receipt_long_outlined),
      _kpiCard(
          l10n.paymentStatusPaid,
          _statementMoney(statement, statement.paid),
          const Color(0xFF16A34A),
          Icons.payments_outlined),
      _kpiCard(
          l10n.reportsClosingLabel,
          _statementMoney(statement, statement.closingBalance),
          const Color(0xFF7C3AED),
          Icons.summarize_outlined),
      _kpiCard(
          l10n.dashboardOverdueSectionTitle,
          _statementMoney(statement, statement.overdueBalance),
          const Color(0xFFDC2626),
          Icons.warning_amber_outlined),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(width: 48, child: _TableHead(l10n.reportsSlColumnLabel)),
          Expanded(flex: 2, child: _TableHead(l10n.invoiceMgmtColDate)),
          Expanded(flex: 2, child: _TableHead(l10n.reportsTypeColumnLabel)),
          Expanded(
              flex: 3, child: _TableHead(l10n.reportsReferenceColumnLabel)),
          Expanded(
              flex: 4,
              child: _TableHead(l10n.customerMgmtCsvColDescriptionHeader)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsDebitColumnLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsCreditColumnLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsBalanceColumnLabel, right: true)),
        ],
      ),
    );
  }

  Widget _statementRow(
      CustomerStatement statement, int rank, CustomerStatementLine line) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 2,
              child: Text(_formatStoredDate(line.date),
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 4,
              child: Text(line.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(
                  line.debit > 0 ? _statementMoney(statement, line.debit) : '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface))),
        ],
      ),
    );
  }

  Widget _customerTableHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(width: 48, child: _TableHead(l10n.reportsSlColumnLabel)),
          Expanded(flex: 4, child: _TableHead(l10n.labelCustomer)),
          Expanded(
              flex: 1,
              child: _TableHead(l10n.reportsInvoicesColumnLabel, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsBilledLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.dashboardCollectedLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.dashboardOutstandingLabel, right: true)),
        ],
      ),
    );
  }

  Widget _customerRow(int rank, TopCustomer c) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 4,
              child: Text(c.name,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 1,
              child: Text('${c.invoiceCount}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 2,
              child: Text(_money(c.billed),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
                          : Theme.of(context).colorScheme.onSurfaceVariant))),
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
                              AppLocalizations.of(context)!
                                  .reportsTopProductsByMetricTitle(
                                      _topProducts.length,
                                      _rankProductsByProfit
                                          ? AppLocalizations.of(context)!
                                              .reportsProfitLabel
                                          : AppLocalizations.of(context)!
                                              .reportsNavRevenueLabel),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      if (!mounted) return;
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
                                            ? AppLocalizations.of(context)!
                                                .reportsRankByProfitLabel
                                            : AppLocalizations.of(context)!
                                                .reportsRankByRevenueLabel,
                                        style: const TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  _exportBtn(
                                      AppLocalizations.of(context)!
                                          .reportsExportCsvLabel, () async {
                                    final csv =
                                        ReportService.exportTopProductsCsv(
                                            _topProducts);
                                    await _saveCsv(csv, 'top_products_$ts.csv');
                                  }),
                                ],
                              ),
                            ),
                          ),
                          if (_missingCostItemCount > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: _missingCostBanner(),
                            ),
                          if (_topProducts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _emptyState(AppLocalizations.of(context)!
                                  .reportsNoProductDataMessage),
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
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
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
                                if (!mounted) return;
                                setState(() => _productsPage = p);
                              },
                              onSizeChange: (s) {
                                if (!mounted) return;
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          SizedBox(width: 48, child: _TableHead(l10n.reportsSlColumnLabel)),
          Expanded(
              flex: 4,
              child: _TableHead(l10n.reportsProductServiceColumnLabel)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsUnitsSoldColumnLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsNavRevenueLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsDiscountGivenColumnLabel,
                  right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsProfitLabel, right: true)),
          Expanded(
              flex: 1,
              child: _TableHead(l10n.reportsMarginColumnLabel, right: true)),
        ],
      ),
    );
  }

  Widget _productRow(int rank, TopProduct p) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 4,
              child: Text(p.name,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(_fmtInt.format(p.unitsSold),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  // ─── Section: Daily Sales & Profit Report ──────────────────────────────────

  Widget _buildDailyReport() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final l10n = AppLocalizations.of(context)!;
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
                              l10n.reportsDailySalesProfitTitle,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _exportBtn(l10n.reportsExportCsvLabel,
                                      () async {
                                    final csv =
                                        ReportService.exportDailyReportCsv(
                                            _dailyReport);
                                    await _saveCsv(csv, 'daily_report_$ts.csv');
                                  }),
                                  const SizedBox(width: 4),
                                  _exportBtn(
                                      l10n.customerMgmtExportPdfMenuLabel,
                                      () async {
                                    final (from, to) = _dailyRange;
                                    final bytes = await ReportService
                                        .exportDailyReportPdf(
                                      _dailyReport,
                                      currencySymbol: _sym,
                                      showFooterBranding: _showFooterBranding,
                                      dateRangeLabel:
                                          '${_formatDate(from)} – ${_formatDate(to)}  •  $_currencyScopeLabel',
                                    );
                                    await _savePdf(
                                        bytes, 'daily_report_$ts.pdf');
                                  }),
                                ],
                              ),
                            ),
                          ),
                          _rangeModeSelector(
                            mode: _dailyMode,
                            year: _dailyYear,
                            month: _dailyMonth,
                            showToday: true,
                            onCustomTap: _pickDailyCustomRange,
                            customRangeLabel: _dailyCustomFrom != null &&
                                    _dailyCustomTo != null
                                ? _dailyCustomFrom!.isAtSameMomentAs(
                                            _dailyCustomTo!) ||
                                        _formatDate(_dailyCustomFrom!) ==
                                            _formatDate(_dailyCustomTo!)
                                    ? _formatDate(_dailyCustomFrom!)
                                    : '${_formatDate(_dailyCustomFrom!)} – ${_formatDate(_dailyCustomTo!)}'
                                : null,
                            onModeChanged: (m) {
                              if (!mounted) return;
                              setState(() => _dailyMode = m);
                              _loadTab(7);
                            },
                            onMonthChanged: (m) {
                              if (!mounted) return;
                              setState(() => _dailyMonth = m);
                              _loadTab(7);
                            },
                            onYearChanged: (y) {
                              if (!mounted) return;
                              setState(() => _dailyYear = y);
                              _loadTab(7);
                            },
                          ),
                          if (_missingCostItemCount > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: _missingCostBanner(),
                            ),
                          if (_dailyReport.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _emptyState(
                                  l10n.reportsNoSalesInPeriodMessage),
                            )
                          else ...[
                            _dailyTableHeader(),
                            ..._dailyReport
                                .skip(_dailyPage * _dailyPageSize)
                                .take(_dailyPageSize)
                                .map(_dailyRow),
                            _buildReportPagination(
                              currentPage: _dailyPage,
                              pageSize: _dailyPageSize,
                              total: _dailyReport.length,
                              onPageChange: (p) {
                                if (!mounted) return;
                                setState(() => _dailyPage = p);
                              },
                              onSizeChange: (s) {
                                if (!mounted) return;
                                setState(() {
                                  _dailyPageSize = s;
                                  _dailyPage = 0;
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

  // Locale-correct month name (follows the active app language via
  // Intl.defaultLocale) rather than a hardcoded English list.
  static String _monthName(int month) =>
      DateFormat.MMMM().format(DateTime(2000, month));

  Widget _rangeModeSelector({
    required _DailyMode mode,
    required int year,
    required int month,
    required ValueChanged<_DailyMode> onModeChanged,
    required ValueChanged<int> onMonthChanged,
    required ValueChanged<int> onYearChanged,
    bool showToday = false,
    VoidCallback? onCustomTap,
    String? customRangeLabel,
  }) {
    final now = DateTime.now();
    final years = [for (int y = now.year; y >= now.year - 5; y--) y];
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showToday)
            _rangeModeChip(l10n.reportsTodayLabel, mode == _DailyMode.today,
                () => onModeChanged(_DailyMode.today)),
          _rangeModeChip(
              l10n.reportsPresetLast30DaysLabel,
              mode == _DailyMode.last30,
              () => onModeChanged(_DailyMode.last30)),
          _rangeModeChip(
              l10n.reportsMonthYearLabel,
              mode == _DailyMode.monthYear,
              () => onModeChanged(_DailyMode.monthYear)),
          if (onCustomTap != null)
            _rangeModeChip(l10n.reportsCustomRangeLabel,
                mode == _DailyMode.custom, onCustomTap),
          if (mode == _DailyMode.custom && customRangeLabel != null)
            Text(customRangeLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (mode == _DailyMode.monthYear) ...[
            DropdownButton<int>(
              value: month,
              underline: const SizedBox(),
              items: [
                for (int m = 1; m <= 12; m++)
                  DropdownMenuItem(value: m, child: Text(_monthName(m))),
              ],
              onChanged: (m) {
                if (m != null) onMonthChanged(m);
              },
            ),
            DropdownButton<int>(
              value: year,
              underline: const SizedBox(),
              items: [
                for (final y in years)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (y) {
                if (y != null) onYearChanged(y);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _rangeModeChip(String label, bool sel, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF1D4ED8).withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
              color: sel
                  ? const Color(0xFF1D4ED8)
                  : Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                color: sel
                    ? const Color(0xFF1D4ED8)
                    : Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }

  Widget _dailyTableHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(flex: 2, child: _TableHead(l10n.invoiceMgmtColDate)),
          Expanded(flex: 1, child: _TableHead(l10n.navInvoices, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsSalesColumnLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsCogsColumnLabel, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsProfitLabel, right: true)),
          Expanded(
              flex: 1,
              child: _TableHead(l10n.reportsMarginColumnLabel, right: true)),
        ],
      ),
    );
  }

  void _openDayInInvoiceStatus(String dateKey) {
    final day = DateTime.tryParse(dateKey);
    if (day == null || !mounted) return;
    setState(() {
      _selectedIndex = 6;
      _invoiceExactDay = DateTime(day.year, day.month, day.day);
      _invoiceFilter = _InvoiceFilter.all;
      _invoicePage = 0;
    });
    _loadTab(6);
  }

  Widget _dailyRow(DailyPoint d) {
    return InkWell(
      onTap: () => _openDayInInvoiceStatus(d.date),
      child: Container(
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Text(_formatStoredDate(d.date),
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface))),
            Expanded(
                flex: 1,
                child: Text(_fmtInt.format(d.invoiceCount),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
            Expanded(
                flex: 2,
                child: Text(_money(d.billed),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D4ED8)))),
            Expanded(
                flex: 2,
                child: Text(_money(d.cogs),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
            Expanded(
                flex: 2,
                child: Text(_money(d.profit),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: d.profit < 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A)))),
            Expanded(
                flex: 1,
                child: Text('${d.marginPercent.toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
          ],
        ),
      ),
    );
  }

  // ─── Section 6: Quotation Conversion ───────────────────────────────────────

  Widget _buildQuotations() {
    final q = _quotStats;
    final l10n = AppLocalizations.of(context)!;
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
                                  l10n.reportsQuotationsIssuedLabel,
                                  _fmtInt.format(q.quotationsIssued),
                                  const Color(0xFF0284C7),
                                  Icons.request_quote_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kpiCard(
                                  l10n.reportsInvoicesInPeriodLabel,
                                  _fmtInt.format(q.invoicesInPeriod),
                                  const Color(0xFF16A34A),
                                  Icons.receipt_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kpiCard(
                                  l10n.reportsConversionRateLabel,
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
                          _cardTitle(l10n.reportsAboutConversionRateTitle),
                          const SizedBox(height: 12),
                          Text(
                            l10n.reportsConversionRateExplanationBody,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
    final (from, to) = _invoiceStatusRange;
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
    final l10n = AppLocalizations.of(context)!;

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
                    Icon(Icons.info_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                        l10n.reportsShowingInvoicesDatedLabel(
                            _invoiceStatusRangeLabel),
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              if (_invoiceExactDay != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.event,
                          size: 16, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 6),
                      Text(
                          l10n.reportsFilteredToDateLabel(
                              _formatDate(_invoiceExactDay!)),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8))),
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          setState(() => _invoiceExactDay = null);
                          _loadTab(6);
                        },
                        child: Text(l10n.actionClear,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                _rangeModeSelector(
                  mode: _invoiceDateMode,
                  year: _invoiceYear,
                  month: _invoiceMonth,
                  onModeChanged: (m) {
                    if (!mounted) return;
                    setState(() => _invoiceDateMode = m);
                    _loadTab(6);
                  },
                  onMonthChanged: (m) {
                    if (!mounted) return;
                    setState(() => _invoiceMonth = m);
                    _loadTab(6);
                  },
                  onYearChanged: (y) {
                    if (!mounted) return;
                    setState(() => _invoiceYear = y);
                    _loadTab(6);
                  },
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
                              l10n.reportsTotalInvoicesLabel,
                              _fmtInt.format(_invoiceList.length),
                              const Color(0xFF002E78),
                              Icons.receipt_long_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.paymentStatusPaid,
                              _fmtInt.format(_invoiceCount('Paid')),
                              const Color(0xFF16A34A),
                              Icons.check_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.paymentStatusPartial,
                              _fmtInt.format(_invoiceCount('Partial')),
                              const Color(0xFFF59E0B),
                              Icons.timelapse_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.paymentStatusUnpaid,
                              _fmtInt.format(_invoiceCount('Unpaid')),
                              Theme.of(context).colorScheme.onSurfaceVariant,
                              Icons.remove_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(
                              l10n.dashboardOverdueSectionTitle,
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
                          _exportBtn(l10n.reportsExportCsvLabel, () async {
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
                        child: _emptyState(
                            l10n.reportsNoInvoicesMatchFilterMessage),
                      )
                    else ...[
                      ...pageRows.asMap().entries.map((e) =>
                          _invoiceStatusRow(pageStart + e.key + 1, e.value)),
                      _buildReportPagination(
                        currentPage: _invoicePage,
                        pageSize: _invoicePageSize,
                        total: filtered.length,
                        onPageChange: (p) {
                          if (!mounted) return;
                          setState(() => _invoicePage = p);
                        },
                        onSizeChange: (s) {
                          setState(() {
                            if (!mounted) return;
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
    final l10n = AppLocalizations.of(context)!;
    final label = switch (f) {
      _InvoiceFilter.all => l10n.reportsLabelWithCountLabel(
          l10n.invoiceMgmtStatusAllLabel, _invoiceList.length),
      _InvoiceFilter.paid => l10n.reportsLabelWithCountLabel(
          l10n.paymentStatusPaid, _invoiceCount('Paid')),
      _InvoiceFilter.partial => l10n.reportsLabelWithCountLabel(
          l10n.paymentStatusPartial, _invoiceCount('Partial')),
      _InvoiceFilter.unpaid => l10n.reportsLabelWithCountLabel(
          l10n.paymentStatusUnpaid, _invoiceCount('Unpaid')),
      _InvoiceFilter.overdue => l10n.reportsLabelWithCountLabel(
          l10n.dashboardOverdueSectionTitle, _overdueCount),
    };
    final color = switch (f) {
      _InvoiceFilter.paid => const Color(0xFF16A34A),
      _InvoiceFilter.partial => const Color(0xFFF59E0B),
      _InvoiceFilter.unpaid => Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: sel ? color : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
          color: sel ? color : Theme.of(context).colorScheme.outlineVariant),
      onSelected: (_) {
        if (!mounted) return;
        setState(() {
          _invoiceFilter = f;
          _invoicePage = 0;
        });
      },
    );
  }

  Widget _invoiceStatusHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(width: 32, child: _TableHead('#')),
          Expanded(flex: 2, child: _TableHead(l10n.invoiceMgmtColDate)),
          Expanded(flex: 3, child: _TableHead(l10n.reportsInvoiceIdLabel)),
          Expanded(flex: 4, child: _TableHead(l10n.labelCustomer)),
          Expanded(
              flex: 2, child: _TableHead(l10n.fieldTotalLabel, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.paymentStatusPaid, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.dashboardOutstandingLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.invoiceMgmtColStatus, right: true)),
        ],
      ),
    );
  }

  // r.status is an internal data code ('Paid'/'Partial'/'Unpaid') used for
  // color/filter lookups elsewhere — only the displayed text is translated,
  // the underlying value must stay untouched so those lookups keep working.
  String _statusDisplayLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      'Paid' => l10n.paymentStatusPaid,
      'Partial' => l10n.paymentStatusPartial,
      'Unpaid' => l10n.paymentStatusUnpaid,
      _ => status,
    };
  }

  Widget _invoiceStatusRow(int rank, InvoiceStatusRow r) {
    final statusColor = _statusColors[r.status] ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          SizedBox(
              width: 32,
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 2,
              child: Text(_formatStoredDate(r.date),
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 3,
              child: Text(r.id,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 4,
              child: Text(r.customerName,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(_money(r.total),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
                          : Theme.of(context).colorScheme.onSurfaceVariant))),
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
                      child: Text(_statusDisplayLabel(r.status),
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
                        child: Text(
                            AppLocalizations.of(context)!
                                .dashboardOverdueSectionTitle,
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
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
