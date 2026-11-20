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
import 'package:invoiso/models/cash_ledger_entry.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/services/customer_statement_pdf_service.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/services/gst/gstr1_excel_writer.dart';
import 'package:invoiso/services/gst/gstr1_pdf_writer.dart';
import 'package:invoiso/services/gst/gstr1_service.dart';
import 'package:invoiso/models/gstr3b_summary.dart';
import 'package:invoiso/services/gst/gstr3b_pdf_writer.dart';
import 'package:invoiso/models/purchase_gst_report.dart';
import 'package:invoiso/providers/purchase_bills_settings_provider.dart';
import 'package:invoiso/services/gst/purchase_gst_builder.dart';
import 'package:invoiso/services/gst/purchase_register_export.dart';
import 'package:invoiso/domain/payables_aging.dart';
import 'package:invoiso/domain/supplier_statement.dart';
import 'package:invoiso/models/purchase_bill.dart';

import '../common/supported_currencies.dart';
import 'package:invoiso/utils/formatters.dart';

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

// Daily Report lines shown (Cash/UPI exchange feature on).
enum _DailyView { all, invoices, exchanges }

enum _CurrencyScope { selected, all }

enum _CustomerReportMode { overview, statements }

enum _DailyMode { today, last30, monthYear, custom }

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  final String? initialStatementCustomerKey;
  final bool isAdmin;
  const ReportsScreen(
      {super.key, this.initialStatementCustomerKey, this.isAdmin = true});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedIndex = 0;
  // Purchase price restricted to admins: hide cost, profit and stock value.
  bool _hideCost = false;
  // Daily Report net Cash / UPI-Bank columns: exchange feature on, admins only.
  bool _cashUpi = false;
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
  _DailyView _dailyView = _DailyView.all;
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
  List<AgedReceivableSummaryRow> _agedSummary = [];
  // Receivables sub-tabs: 0 Payment status · 1 Aging summary · 2 Aged invoices.
  // Both aging lists load the first time an aging sub-tab shows.
  int _arSection = 0;
  bool _agedLoaded = false;
  List<TaxBucket> _taxBuckets = [];
  // Tax sub-tabs (TaxTabRedesignPlan.md): 0 By rate · 1 HSN · 2 Documents.
  // HSN / Documents load the first time their sub-tab shows (null = not yet).
  int _taxSection = 0;
  List<HsnSummaryRow>? _hsnRows;
  List<DocumentIssuedRow>? _docRows;
  String _hsnFilter = 'all'; // 'all' | 'b2b' | 'b2c'
  String _hsnQuery = '';
  int _hsnPage = 0;
  int _hsnPageSize = 25;
  // GSTR-1 sub-tab (3): own period — returns are filed per month / quarter.
  bool _gstr1Quarterly = false;
  late (int, int) _gstr1Period = () {
    final last = DateTime(DateTime.now().year, DateTime.now().month - 1);
    return (last.year, last.month); // (year, month or quarter)
  }();
  Gstr1Report? _gstr1Report;
  Gstr3bSummary? _gstr3b; // Tax sub-tab 4 (same return period as GSTR-1)
  bool _gstr3bLoading = false;
  // Purchases tab (9) — purchase register (PurchaseGstReportsPlan.md P2).
  PurchaseGstReport? _purchaseReport;
  String _purchaseFilter = 'all'; // 'all' | 'registered' | 'unregistered'
  String _purchaseQuery = '';
  int _purchasePage = 0;
  int _purchasePageSize = 25;
  bool _purchasesAdminOnly = false;
  int _purchaseSection = 0; // 0 register, 1 payables, 2 supplier statement
  ({List<AgedReceivable> detail, List<AgedReceivableSummaryRow> summary})?
      _payables; // as of today, all bills (not period-bound)
  List<PurchaseBill>? _allPurchaseBills; // payables + supplier statement
  String? _statementSupplierKey;
  int _payablesPage = 0;
  int _payablesPageSize = 25;
  bool get _showPurchases =>
      ref.watch(enablePurchaseBillsAndSuppliersProvider) &&
      (!_purchasesAdminOnly || widget.isAdmin);
  /// GSTR-1 / GSTR-3B: own return period → side-panel period / currency hidden.
  bool get _isGstr1Section =>
      _selectedIndex == 2 && _showGstFields && _taxSection >= 3;
  bool _gstr1Loading = false;
  bool _gstr1IncludeRegister = false;
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
  int _agedSummaryPage = 0;
  int _agedSummaryPageSize = 10;
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

  InventoryValuationSummary _inventorySummary = InventoryValuationSummary.empty;
  List<InventoryValuationRow> _inventoryRows = [];
  int _inventoryPage = 0;
  int _inventoryPageSize = 25;

  bool _showFooterBranding = true;
  bool _showGstFields = false;

  // Formatting
  final _fmtInt = NumberFormat('#,##0');

  String? get _reportCurrencyCode =>
      _currencyScope == _CurrencyScope.selected ? _currencyCode : null;

  String get _currencyScopeLabel => switch (_currencyScope) {
        _CurrencyScope.selected => _currencyCode,
        _CurrencyScope.all =>
          AppLocalizations.of(context)!.reportsAllCurrenciesLabel,
      };

  String _money(num value) {
    final amount = AmountFormat.moneyGrouped(value.toDouble());
    return _currencyScope == _CurrencyScope.selected ? '$_sym $amount' : amount;
  }

  String _statementMoney(CustomerStatement statement, num value) =>
      '${statement.currencySymbol} ${AmountFormat.moneyGrouped(value.toDouble())}';

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
    final showGst = await settingsRepo.getShowGstFields();
    final results = await Future.wait([
      settingsRepo.getSetting(SettingKey.currency),
      settingsRepo.getDateFormat(),
      settingsRepo.getProductColumnsConfig(),
      settingsRepo.getSetting(SettingKey.cashUpiExchangeEnabled),
      settingsRepo.getSetting(SettingKey.purchaseBillsAndSuppliersAdminOnly),
    ]);
    final code = (results[0] as String?) ?? 'INR';
    final currency = SupportedCurrencies.all.firstWhere((c) => c.code == code,
        orElse: () => SupportedCurrencies.all.first);
    final dateFormat = results[1] as DateFormatOption;
    final hideCost = (results[2] as ProductColumnsConfig).purchasePriceAdminOnly &&
        !widget.isAdmin;
    if (mounted) {
      setState(() {
        _hideCost = hideCost;
        _purchasesAdminOnly = results[4] == 'true';
        _cashUpi = results[3] == 'true' && widget.isAdmin;
        _sym = currency.symbol;
        _currencyCode = currency.code;
        _currencyName = currency.name;
        _datePattern = dateFormat.key;
        _showFooterBranding = showFooterBranding;
        _showGstFields = showGst;
      });
    }
  }

  Future<void> _invalidateAndReload() async {
    if (!mounted) return;
    // Editions that cache report data (cloud) drop it, so this really refetches.
    await ref.read(appEditionConfigProvider).refreshCaches?.call();
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

  /// Aging summary + aged invoices, the first time an aging sub-tab shows.
  Future<void> _loadArSection() async {
    if (_arSection == 0 || _agedLoaded) return;
    final repo = ref.read(reportRepositoryProvider);
    final r = await Future.wait([
      repo.getAgedReceivables(currencyCode: _reportCurrencyCode),
      repo.getAgedReceivableSummary(currencyCode: _reportCurrencyCode),
    ]);
    if (!mounted) return;
    setState(() {
      _aged = (r[0] as List).cast<AgedReceivable>();
      _agedSummary = (r[1] as List).cast<AgedReceivableSummaryRow>();
      _agedLoaded = true;
    });
  }

  /// HSN summary / Documents issued, the first time their sub-tab shows.
  Future<void> _loadTaxSection() async {
    final (from, to) = _range;
    final repo = ref.read(reportRepositoryProvider);
    if (_taxSection == 1 && _hsnRows == null) {
      final rows =
          await repo.getHsnSummary(from, to, currencyCode: _reportCurrencyCode);
      if (mounted) setState(() => _hsnRows = rows);
    } else if (_taxSection == 2 && _docRows == null) {
      final rows = await repo.getDocumentsIssued(from, to);
      if (mounted) setState(() => _docRows = rows);
    } else if (_taxSection == 3 && _gstr1Report == null) {
      await _loadGstr1();
    } else if (_taxSection == 4 && _gstr3b == null) {
      await _loadGstr3b();
    }
  }

  Future<void> _loadGstr3b() async {
    if (_gstr3bLoading) return;
    setState(() => _gstr3bLoading = true);
    final (year, n) = _gstr1Period;
    try {
      final summary = await Gstr3bService.load(
        _gstr1Quarterly
            ? Gstr1Period.quarter(year, n)
            : Gstr1Period.month(year, n),
        invoices: ref.read(invoiceRepositoryProvider),
        reports: ref.read(reportRepositoryProvider),
        companyInfo: ref.read(companyInfoRepositoryProvider),
        purchaseBills: ref.read(enablePurchaseBillsAndSuppliersProvider) &&
                (!_purchasesAdminOnly || widget.isAdmin)
            ? ref.read(purchaseBillRepositoryProvider)
            : null,
      );
      if (mounted) setState(() => _gstr3b = summary);
    } finally {
      if (mounted) setState(() => _gstr3bLoading = false);
    }
  }

  /// Purchases → Payables: unpaid bills aged by due date, as of today.
  Future<void> _loadPayables() async {
    final bills =
        await ref.read(purchaseBillRepositoryProvider).getAllPurchaseBills();
    if (!mounted) return;
    setState(() {
      _allPurchaseBills = bills;
      _payables = PayablesAging.build(bills);
      _payablesPage = 0;
    });
  }

  Future<void> _loadGstr1() async {
    if (_gstr1Loading) return;
    setState(() => _gstr1Loading = true);
    final (year, n) = _gstr1Period;
    try {
      final report = await Gstr1Service.load(
        _gstr1Quarterly
            ? Gstr1Period.quarter(year, n)
            : Gstr1Period.month(year, n),
        invoices: ref.read(invoiceRepositoryProvider),
        reports: ref.read(reportRepositoryProvider),
        companyInfo: ref.read(companyInfoRepositoryProvider),
      );
      if (mounted) setState(() => _gstr1Report = report);
    } finally {
      if (mounted) setState(() => _gstr1Loading = false);
    }
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
          final status = await ref
              .read(reportRepositoryProvider)
              .getPaymentStatusBreakdown(from, to,
                  currencyCode: _reportCurrencyCode);
          if (!mounted) return;
          setState(() {
            _status = status;
            _agedLoaded = false; // reload on next view (period / currency changed)
            _agedPage = 0;
            _agedSummaryPage = 0;
          });
          _loadArSection();
        case 2:
          final buckets = await ref
              .read(reportRepositoryProvider)
              .getTaxByRate(from, to, currencyCode: _reportCurrencyCode);
          if (!mounted) return;
          setState(() {
            _taxBuckets = buckets;
            _hsnRows = null; // reload on next view (period / currency changed)
            _docRows = null;
            _gstr1Report = null;
            _gstr3b = null;
            _hsnPage = 0;
          });
          _loadTaxSection();
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
            if (_cashUpi)
              ref.read(cashLedgerRepositoryProvider).getDailyNet(dFrom, dTo),
          ]);
          if (!mounted) return;
          setState(() {
            _dailyReport = _cashUpi
                ? ReportService.mergeDailyCashUpi(r[0] as List<DailyPoint>,
                    r[2] as Map<String, CashDailyNet>)
                : r[0] as List<DailyPoint>;
            _missingCostItemCount = r[1] as int;
            _dailyPage = 0;
          });
        case 9:
          final bills = await ref
              .read(purchaseBillRepositoryProvider)
              .getPurchaseBillsInRange(from, to);
          final company =
              await ref.read(companyInfoRepositoryProvider).getCompanyInfo();
          if (!mounted) return;
          setState(() {
            _purchaseReport = PurchaseGstBuilder.build(
                companyGstin: company?.gstin ?? '', bills: bills);
            _purchasePage = 0;
            _payables = null;
          });
          if (_purchaseSection >= 1) await _loadPayables();
        case 8:
          final r = await Future.wait([
            ref.read(reportRepositoryProvider).getInventoryValuationSummary(),
            ref.read(reportRepositoryProvider).getInventoryValuationRows(),
          ]);
          if (!mounted) return;
          setState(() {
            _inventorySummary = r[0] as InventoryValuationSummary;
            _inventoryRows = (r[1] as List).cast<InventoryValuationRow>();
            _inventoryPage = 0;
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

  Future<void> _savePdf(Uint8List bytes, String filename) => _saveBytes(
      bytes, filename, 'pdf', AppLocalizations.of(context)!.reportsSavePdfReportTitle);

  Future<void> _saveBytes(
      Uint8List bytes, String filename, String extension, String title) async {
    final l10n = AppLocalizations.of(context)!;
    String? savePath;
    try {
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: title,
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: [extension],
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
    (Icons.warehouse_outlined, Icons.warehouse),
    (Icons.shopping_cart_outlined, Icons.shopping_cart),
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
      7 => l10n.reportsNavDailyReportLabel,
      9 => l10n.reportsNavPurchasesLabel,
      _ => l10n.reportsNavInventoryLabel,
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
          for (int i = 0; i < _navIcons.length; i++)
            if (!(_hideCost && i == 8) && (i != 9 || _showPurchases))
              _navItem(i, primary),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(
                height: 1, color: Theme.of(context).colorScheme.outlineVariant),
          ),
          // GSTR-1 has its own return period and is always INR → the panel's
          // currency / period don't apply (hidden like other tabs do).
          if (_isGstr1Section)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(AppLocalizations.of(context)!.reportsGstr1PanelNote,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          // ── Currency scope ── (inventory is a single-currency snapshot)
          if (_selectedIndex != 8 && _selectedIndex != 9 && !_isGstr1Section) ...[
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
          ],
          if (_selectedIndex != 6 &&
              _selectedIndex != 7 &&
              _selectedIndex != 8 &&
              !(_selectedIndex == 9 && _purchaseSection == 1) &&
              !_isGstr1Section) ...[
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
      8 => _buildInventoryValuation(),
      9 => _buildPurchases(),
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
    return SizedBox(
      width: double.infinity,
      child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        if (trailing != null) trailing,
      ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon,
      {bool outlined = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: outlined ? 0 : 1,
      color: outlined ? scheme.surfaceContainerHighest : null,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: outlined
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
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
            mainAxisSize: MainAxisSize.min,
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

  Widget _missingCostBanner([String? message]) {
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
              message ?? AppLocalizations.of(context)!
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
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsTotalBilledLabel,
                                  _money(_kpi.billed),
                                  Theme.of(context).primaryColor,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsAvgInvoiceValueLabel,
                                  _money(_kpi.avgInvoiceValue),
                                  const Color(0xFF7C3AED),
                                  Icons.trending_up)),
                          if (!_hideCost) ...[
                          const SizedBox(width: 12),
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsTotalProfitLabel,
                                  _money(_kpi.profit),
                                  _kpi.profit < 0
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  Icons.savings_outlined)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsRealizedProfitLabel,
                                  _money(_kpi.realizedProfit),
                                  _kpi.realizedProfit < 0
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  Icons.payments_outlined)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_hideCost && _missingCostItemCount > 0)
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
                      trailing: _hideCost ? null : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _exportBtn(l10n.reportsExportCsvLabel, () async {
                            final csv = ReportService.exportTrendCsv(_trend);
                            await _saveCsv(csv, 'revenue_report_$ts.csv');
                          }),
                          const SizedBox(width: 4),
                          _exportBtn(l10n.customerMgmtExportPdfMenuLabel,
                              () async {
                            final (from, to) = _range;
                            final bytes =
                                await ReportService.exportRevenueReportPdf(
                              _trend,
                              _kpi,
                              currencySymbol: _sym,
                              showFooterBranding: _showFooterBranding,
                              dateRangeLabel:
                                  '${_formatDate(from)} – ${_formatDate(to)}  •  $_currencyScopeLabel',
                            );
                            await _savePdf(bytes, 'revenue_report_$ts.pdf');
                          }),
                        ],
                      ),
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
                          if (!_hideCost) ...[
                          const SizedBox(width: 24),
                          _legend(
                              const Color(0xFF7C3AED), l10n.reportsProfitLabel),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Monthly breakdown table
              if (_trend.isNotEmpty)
                _sectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: _cardTitle(l10n.reportsMonthlyBreakdownTitle),
                      ),
                      _revenueTableHeader(),
                      ..._trend.map(_revenueRow),
                      _revenueTotalsRow(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _revenueTableHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(flex: 2, child: _TableHead(l10n.reportsMonthColumnLabel)),
          Expanded(
              flex: 1, child: _TableHead(l10n.navInvoices, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsBilledLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.dashboardCollectedLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.dashboardOutstandingLabel, right: true)),
          if (!_hideCost) ...[
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsCogsColumnLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsProfitLabel, right: true)),
          Expanded(
              flex: 1,
              child: _TableHead(l10n.reportsMarginColumnLabel, right: true)),
          ],
        ],
      ),
    );
  }

  Widget _revenueCell(String text,
          {int flex = 2, Color? color, FontWeight? weight}) =>
      Expanded(
        flex: flex,
        child: Text(text,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 13,
                fontWeight: weight,
                color: color ??
                    Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _revenueRow(MonthlyPoint p) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(_formatMonthKey(p.month),
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface))),
          _revenueCell(_fmtInt.format(p.invoiceCount), flex: 1),
          _revenueCell(_money(p.billed),
              color: const Color(0xFF1D4ED8), weight: FontWeight.w600),
          _revenueCell(_money(p.collected)),
          _revenueCell(_money(p.outstanding)),
          if (!_hideCost) ...[
          _revenueCell(_money(p.cogs)),
          _revenueCell(_money(p.profit),
              color: p.profit < 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A),
              weight: FontWeight.w600),
          _revenueCell('${p.marginPercent.toStringAsFixed(0)}%', flex: 1),
          ],
        ],
      ),
    );
  }

  Widget _revenueTotalsRow() {
    final l10n = AppLocalizations.of(context)!;
    final invoices = _trend.fold<int>(0, (a, p) => a + p.invoiceCount);
    final billed = _trend.fold<double>(0, (a, p) => a + p.billed);
    final collected = _trend.fold<double>(0, (a, p) => a + p.collected);
    final outstanding = _trend.fold<double>(0, (a, p) => a + p.outstanding);
    final cogs = _trend.fold<double>(0, (a, p) => a + p.cogs);
    final profit = _trend.fold<double>(0, (a, p) => a + p.profit);
    final net = _trend.fold<double>(0, (a, p) => a + p.netSales);
    final margin = net == 0 ? 0.0 : (profit / net) * 100;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(l10n.reportsTotalRowLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700))),
          _revenueCell(_fmtInt.format(invoices),
              flex: 1, weight: FontWeight.w700),
          _revenueCell(_money(billed), weight: FontWeight.w700),
          _revenueCell(_money(collected), weight: FontWeight.w700),
          _revenueCell(_money(outstanding), weight: FontWeight.w700),
          if (!_hideCost) ...[
          _revenueCell(_money(cogs), weight: FontWeight.w700),
          _revenueCell(_money(profit),
              weight: FontWeight.w700,
              color: profit < 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A)),
          _revenueCell('${margin.toStringAsFixed(0)}%',
              flex: 1, weight: FontWeight.w700),
          ],
        ],
      ),
    );
  }

  String _formatMonthKey(String key) {
    final d = DateTime.tryParse('$key-01');
    return d == null ? key : DateFormat('MMM yyyy').format(d);
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
            .map((p) => [p.billed, p.collected, if (!_hideCost) p.profit]
                .reduce((a, b) => a > b ? a : b))
            .fold(0.0, (a, b) => a > b ? a : b) *
        1.2;
    final minY = _hideCost
        ? 0.0
        : _trend.map((p) => p.profit).fold(0.0, (a, b) => a < b ? a : b) *
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
          if (!_hideCost)
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.donut_large, size: 16),
                        label: Text(l10n.reportsPaymentStatusTab)),
                    ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.people_outline, size: 16),
                        label: Text(l10n.reportsAgingSummaryTab)),
                    ButtonSegment(
                        value: 2,
                        icon: const Icon(Icons.receipt_long_outlined, size: 16),
                        label: Text(l10n.reportsAgedInvoicesTab)),
                  ],
                  selected: {_arSection},
                  onSelectionChanged: (s) {
                    if (!mounted) return;
                    setState(() => _arSection = s.first);
                    _loadArSection();
                  },
                ),
              ),
              if (_arSection != 0 && !_agedLoaded)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              // Donut chart + legend row
              if (_arSection == 0)
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

              // A/R aging summary by customer
              if (_arSection == 1 && _agedLoaded)
                _sectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: _cardTitle(
                          l10n.reportsArAgingSummaryTitle,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _exportBtn(l10n.reportsExportCsvLabel, () async {
                                final csv = ReportService
                                    .exportAgedReceivableSummaryCsv(
                                        _agedSummary);
                                await _saveCsv(
                                    csv, 'ar_aging_summary_$ts.csv');
                              }),
                              const SizedBox(width: 4),
                              _exportBtn(l10n.customerMgmtExportPdfMenuLabel,
                                  () => _exportArAgingPdf(ts)),
                            ],
                          ),
                        ),
                      ),
                      if (_agedSummary.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _emptyState(
                              l10n.reportsNoOutstandingInvoicesMessage),
                        )
                      else ...[
                      _agedSummaryHeader(),
                      ..._agedSummary
                          .skip(_agedSummaryPage * _agedSummaryPageSize)
                          .take(_agedSummaryPageSize)
                          .map(_agedSummaryRow),
                      _agedSummaryTotalsRow(),
                      _buildReportPagination(
                        currentPage: _agedSummaryPage,
                        pageSize: _agedSummaryPageSize,
                        total: _agedSummary.length,
                        onPageChange: (p) {
                          if (!mounted) return;
                          setState(() => _agedSummaryPage = p);
                        },
                        onSizeChange: (s) {
                          if (!mounted) return;
                          setState(() {
                            _agedSummaryPageSize = s;
                            _agedSummaryPage = 0;
                          });
                        },
                      ),
                      ],
                    ],
                  ),
                ),

              // Aged receivables table
              if (_arSection == 2 && _agedLoaded)
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _cardTitle(
                        l10n.reportsAgedReceivablesTitle(_aged.length),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _exportBtn(l10n.reportsExportCsvLabel, () async {
                              final csv =
                                  ReportService.exportAgedReceivablesCsv(_aged);
                              await _saveCsv(
                                  csv, 'aged_receivables_$ts.csv');
                            }),
                            const SizedBox(width: 4),
                            _exportBtn(l10n.customerMgmtExportPdfMenuLabel,
                                () => _exportArAgingPdf(ts)),
                          ],
                        ),
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
                      _agedDetailTotalsRow(),
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

  Future<void> _exportArAgingPdf(int ts) async {
    final bytes = await ReportService.exportAgedReceivablesPdf(
      _agedSummary,
      _aged,
      currencySymbol: _sym,
      showFooterBranding: _showFooterBranding,
      asOfLabel: '${_formatDate(DateTime.now())}  •  $_currencyScopeLabel',
    );
    await _savePdf(bytes, 'ar_aging_$ts.pdf');
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

  Widget _agedHeader({bool payables = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: _TableHead(payables
                  ? l10n.purchaseRegisterSupplierLabel
                  : l10n.labelCustomer)),
          Expanded(
              flex: 3,
              child: _TableHead(payables
                  ? l10n.purchaseRegisterBillNoLabel
                  : l10n.reportsInvoiceIdLabel)),
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

  Widget _agedSummaryHeader({bool payables = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: _TableHead(payables
                  ? l10n.purchaseRegisterSupplierLabel
                  : l10n.labelCustomer)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsCurrentBucketLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsBucket0to30Label, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsBucket31to60Label, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsBucket61to90Label, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsBucket90PlusLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsNoDueDateLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsTotalRowLabel, right: true)),
        ],
      ),
    );
  }

  Widget _agedMoneyCell(double v, {Color? color, FontWeight? weight}) => Expanded(
        flex: 2,
        child: Text(v == 0 ? '—' : _money(v),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 13,
                fontWeight: weight,
                color: color ??
                    Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _agedSummaryRow(AgedReceivableSummaryRow r) {
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
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface))),
          _agedMoneyCell(r.current),
          _agedMoneyCell(r.d0to30),
          _agedMoneyCell(r.d31to60),
          _agedMoneyCell(r.d61to90),
          _agedMoneyCell(r.d90plus,
              color: r.d90plus > 0 ? const Color(0xFF991B1B) : null),
          _agedMoneyCell(r.noDueDate),
          _agedMoneyCell(r.total,
              color: const Color(0xFFDC2626), weight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _agedSummaryTotalsRow([List<AgedReceivableSummaryRow>? rows]) {
    final l10n = AppLocalizations.of(context)!;
    double c = 0, a30 = 0, a60 = 0, a90 = 0, a90p = 0, nd = 0, t = 0;
    for (final r in rows ?? _agedSummary) {
      c += r.current;
      a30 += r.d0to30;
      a60 += r.d31to60;
      a90 += r.d61to90;
      a90p += r.d90plus;
      nd += r.noDueDate;
      t += r.total;
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(l10n.reportsTotalRowLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700))),
          _agedMoneyCell(c, weight: FontWeight.w700),
          _agedMoneyCell(a30, weight: FontWeight.w700),
          _agedMoneyCell(a60, weight: FontWeight.w700),
          _agedMoneyCell(a90, weight: FontWeight.w700),
          _agedMoneyCell(a90p, weight: FontWeight.w700),
          _agedMoneyCell(nd, weight: FontWeight.w700),
          _agedMoneyCell(t,
              weight: FontWeight.w700, color: const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _agedDetailTotalsRow([List<AgedReceivable>? rows]) {
    final l10n = AppLocalizations.of(context)!;
    final total = (rows ?? _aged).fold<double>(0, (a, r) => a + r.outstanding);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(l10n.reportsTotalRowLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700))),
          const Expanded(flex: 3, child: SizedBox()),
          Expanded(
              flex: 2,
              child: Text(_money(total),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626)))),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
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
                      if (_showGstFields) ...[
                        Expanded(
                          child: _kpiCard(
                              l10n.reportsCgstSgstLabel,
                              _money(_taxBuckets.fold(0.0, (s, b) => s + b.cgst + b.sgst)),
                              const Color(0xFF059669),
                              Icons.call_split),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _kpiCard(
                              l10n.reportsIgstLabel,
                              _money(_taxBuckets.fold(0.0, (s, b) => s + b.igst)),
                              const Color(0xFFD97706),
                              Icons.local_shipping_outlined),
                        ),
                      ] else
                        const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),

              if (_showGstFields)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: 0,
                          icon: const Icon(Icons.percent, size: 16),
                          label: Text(l10n.reportsTaxCollectedByRateTitle)),
                      ButtonSegment(
                          value: 1,
                          icon: const Icon(Icons.qr_code, size: 16),
                          label: Text(l10n.reportsHsnSummaryTab)),
                      ButtonSegment(
                          value: 2,
                          icon: const Icon(Icons.numbers, size: 16),
                          label: Text(l10n.reportsDocumentsIssuedTab)),
                      ButtonSegment(
                          value: 3,
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(l10n.reportsGstr1Tab)),
                      ButtonSegment(
                          value: 4,
                          icon: const Icon(Icons.summarize_outlined, size: 16),
                          label: Text(l10n.reportsGstr3bTab)),
                    ],
                    selected: {_taxSection},
                    onSelectionChanged: (s) {
                      if (!mounted) return;
                      setState(() => _taxSection = s.first);
                      _loadTaxSection();
                    },
                  ),
                ),
              if (_showGstFields && _taxSection == 1) _hsnSummaryCard(ts),
              if (_showGstFields && _taxSection == 2) _docsIssuedCard(ts),
              if (_showGstFields && _taxSection == 3) _gstr1Card(),
              if (_showGstFields && _taxSection == 4) _gstr3bCard(),
              // Tax breakdown table
              if (!_showGstFields || _taxSection == 0)
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: _cardTitle(
                        l10n.reportsTaxCollectedByRateTitle,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _exportBtn(l10n.reportsExportCsvLabel, () async {
                              final csv =
                                  ReportService.exportTaxCsv(_taxBuckets,
                                      showGst: _showGstFields);
                              await _saveCsv(csv, 'tax_report_$ts.csv');
                            }),
                            const SizedBox(width: 4),
                            _exportBtn(l10n.customerMgmtExportPdfMenuLabel,
                                () async {
                              final (from, to) = _range;
                              final bytes =
                                  await ReportService.exportTaxReportPdf(
                                _taxBuckets,
                                currencySymbol: _sym,
                                showFooterBranding: _showFooterBranding,
                                showGst: _showGstFields,
                                dateRangeLabel:
                                    '${_formatDate(from)} – ${_formatDate(to)}  •  $_currencyScopeLabel',
                              );
                              await _savePdf(bytes, 'tax_report_$ts.pdf');
                            }),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        l10n.reportsTaxAccrualNote,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
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
              child:
                  _TableHead(l10n.reportsTaxableAmountLabel, right: true)),
          Expanded(
              flex: 3,
              child: _TableHead(l10n.reportsTaxCollectedLabel, right: true)),
          Expanded(
              flex: 3,
              child: _TableHead(l10n.reportsGrossAmountLabel, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsShareLabel, right: true)),
        ],
      ),
    );
  }

  Widget _taxRow(TaxBucket b, double total) {
    final share =
        total == 0 ? '0' : (b.taxCollected / total * 100).toStringAsFixed(1);
    final rateStr = b.rate % 1 == 0
        ? b.rate.toStringAsFixed(0)
        : b.rate.toStringAsFixed(1);
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
              child: Text('$rateStr%',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface))),
          Expanded(
              flex: 3,
              child: Text(_money(b.taxableAmount),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 3,
              child: Text(_money(b.taxCollected),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface))),
          Expanded(
              flex: 3,
              child: Text(_money(b.gross),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant))),
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
    final taxable = _taxBuckets.fold<double>(0, (a, b) => a + b.taxableAmount);
    final gross = _taxBuckets.fold<double>(0, (a, b) => a + b.gross);
    TextStyle bold() => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface);
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
                  style: bold())),
          Expanded(
              flex: 3,
              child: Text(_money(taxable),
                  textAlign: TextAlign.right, style: bold())),
          Expanded(
              flex: 3,
              child: Text(_money(total),
                  textAlign: TextAlign.right, style: bold())),
          Expanded(
              flex: 3,
              child: Text(_money(gross),
                  textAlign: TextAlign.right, style: bold())),
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

  // GST HSN summary (GSTR-1 Table 12) and documents issued (Table 13) —
  // shown on the Tax tab only when GST fields are on.
  Widget _gstTableRow(List<(String, int, bool)> cells,
      {bool header = false, bool bold = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: header
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: cs.outlineVariant))),
      color: header ? cs.surfaceContainerHighest : null,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: header ? 8 : 10),
      child: Row(
        children: [
          for (final (text, flex, right) in cells)
            Expanded(
              flex: flex,
              child: header
                  ? _TableHead(text, right: right)
                  : Text(text,
                      textAlign: right ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                          color: cs.onSurface)),
            ),
        ],
      ),
    );
  }

  Widget _hsnSummaryCard(int ts) {
    final l10n = AppLocalizations.of(context)!;
    String rate(double r) => '${r.toStringAsFixed(r % 1 == 0 ? 0 : 2)}%';
    String qty(double q) => q.toStringAsFixed(q % 1 == 0 ? 0 : 2);
    final all = _hsnRows;
    // Filter + search over all rows; only one page is built.
    final rows = all == null
        ? const <HsnSummaryRow>[]
        : [
            for (final r in all)
              if ((_hsnFilter == 'all' || (_hsnFilter == 'b2b') == r.b2b) &&
                  r.hsn.contains(_hsnQuery.trim()))
                r,
          ];
    void setFilter(VoidCallback change) {
      if (!mounted) return;
      setState(() {
        change();
        _hsnPage = 0;
      });
    }

    return _sectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: _cardTitle(
              l10n.reportsHsnSummaryTitle,
              trailing: all == null
                  ? null
                  : _exportBtn(l10n.reportsExportCsvLabel, () async {
                      await _saveCsv(ReportService.exportHsnSummaryCsv(all),
                          'hsn_summary_$ts.csv');
                    }),
            ),
          ),
          if (all == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState(l10n.reportsNoTaxableItemsMessage),
            )
          else ...[
            if (all.any((r) => r.b2b && r.hsn.isEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _missingCostBanner(l10n.gstMissingB2bHsnWarning),
              ),
            if (all.any((r) => r.invalidGstinCustomers.isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _missingCostBanner(l10n.gstInvalidB2bGstinWarning(
                    {for (final r in all) ...r.invalidGstinCustomers}
                        .join(', '))),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (key, label) in [
                    ('all', l10n.invoiceMgmtStatusAllLabel),
                    ('b2b', 'B2B'),
                    ('b2c', 'B2C'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _hsnFilter == key,
                      onSelected: (_) => setFilter(() => _hsnFilter = key),
                    ),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: l10n.reportsHsnSearchHint,
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xsmall)),
                      ),
                      onChanged: (v) => setFilter(() => _hsnQuery = v),
                    ),
                  ),
                ],
              ),
            ),
            _gstTableRow([
              (l10n.reportsGstSupplyTypeLabel, 2, false),
              (l10n.productMgmtHsnSacLabel, 3, false),
              (l10n.reportsGstUnitLabel, 2, false),
              (l10n.fieldTaxRateLabel, 2, true),
              (l10n.reportsGstQtyLabel, 2, true),
              (l10n.reportsTaxableAmountLabel, 3, true),
              (l10n.reportsTaxCollectedLabel, 3, true),
            ], header: true),
            for (final r
                in rows.skip(_hsnPage * _hsnPageSize).take(_hsnPageSize))
              _gstTableRow([
                (r.b2b ? 'B2B' : 'B2C', 2, false),
                (r.hsn.isEmpty ? '—' : r.hsn, 3, false),
                (r.unit.isEmpty ? '—' : r.unit, 2, false),
                (rate(r.rate), 2, true),
                (qty(r.quantity), 2, true),
                (_money(r.taxable), 3, true),
                (_money(r.igst + r.cgst + r.sgst), 3, true),
              ]),
            _buildReportPagination(
              currentPage: _hsnPage,
              pageSize: _hsnPageSize,
              total: rows.length,
              onPageChange: (p) {
                if (!mounted) return;
                setState(() => _hsnPage = p);
              },
              onSizeChange: (n) => setFilter(() => _hsnPageSize = n),
            ),
          ],
        ],
      ),
    );
  }

  /// Reports → Tax → GSTR-1: period picker, preview (blocking / sections /
  /// excluded / warnings) and Excel export (Gstr1ExportPlan.md Part D2).
  /// Purchases → Payables: aging summary by supplier + detail by bill.
  Widget _payablesSection(int ts) {
    final l10n = AppLocalizations.of(context)!;
    final p = _payables;
    if (p == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    Future<void> pdf() async {
      final bytes = await ReportService.exportAgedReceivablesPdf(
        p.summary,
        p.detail,
        currencySymbol: _sym,
        showFooterBranding: _showFooterBranding,
        asOfLabel: _formatDate(DateTime.now()),
        payables: true,
      );
      await _savePdf(bytes, 'ap_aging_$ts.pdf');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: _cardTitle(
                  l10n.purchaseApAgingSummaryTitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _exportBtn(l10n.reportsExportCsvLabel, () async {
                        await _saveCsv(
                            ReportService.exportAgedReceivableSummaryCsv(
                                p.summary,
                                payables: true),
                            'ap_aging_summary_$ts.csv');
                      }),
                      const SizedBox(width: 4),
                      _exportBtn(l10n.customerMgmtExportPdfMenuLabel, pdf),
                    ],
                  ),
                ),
              ),
              if (p.summary.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _emptyState(l10n.purchaseNoPayablesMessage),
                )
              else ...[
                _agedSummaryHeader(payables: true),
                ...p.summary.map(_agedSummaryRow),
                _agedSummaryTotalsRow(p.summary),
              ],
            ],
          ),
        ),
        if (p.detail.isNotEmpty)
          _sectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: _cardTitle(
                    l10n.purchaseAgedBillsTitle(p.detail.length),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _exportBtn(l10n.reportsExportCsvLabel, () async {
                          await _saveCsv(
                              ReportService.exportAgedReceivablesCsv(p.detail,
                                  payables: true),
                              'aged_payables_$ts.csv');
                        }),
                        const SizedBox(width: 4),
                        _exportBtn(l10n.customerMgmtExportPdfMenuLabel, pdf),
                      ],
                    ),
                  ),
                ),
                _agedHeader(payables: true),
                ...p.detail
                    .skip(_payablesPage * _payablesPageSize)
                    .take(_payablesPageSize)
                    .map(_agedRow),
                _agedDetailTotalsRow(p.detail),
                _buildReportPagination(
                  currentPage: _payablesPage,
                  pageSize: _payablesPageSize,
                  total: p.detail.length,
                  onPageChange: (n) {
                    if (!mounted) return;
                    setState(() => _payablesPage = n);
                  },
                  onSizeChange: (n) {
                    if (!mounted) return;
                    setState(() {
                      _payablesPageSize = n;
                      _payablesPage = 0;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Purchases → Supplier statement: pick a supplier; side-panel period.
  Widget _supplierStatementCard(int ts) {
    final l10n = AppLocalizations.of(context)!;
    final bills = _allPurchaseBills;
    if (bills == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // Suppliers with saved bills: key → (name, bill count), by name.
    final suppliers = <String, (String, int)>{};
    for (final b in bills) {
      if (b.isDraft) continue;
      final k = SupplierStatement.keyOf(b);
      suppliers[k] = (b.supplierName, (suppliers[k]?.$2 ?? 0) + 1);
    }
    final keys = suppliers.keys.toList()
      ..sort((a, b) => suppliers[a]!.$1
          .toLowerCase()
          .compareTo(suppliers[b]!.$1.toLowerCase()));
    final key = suppliers.containsKey(_statementSupplierKey)
        ? _statementSupplierKey
        : null;
    final (from, to) = _range;
    final st = key == null
        ? null
        : SupplierStatement.build(bills,
            supplierKey: key,
            from: from,
            to: to,
            currencyCode: _currencyCode,
            currencySymbol: _sym);

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
                  child: LayoutBuilder(
                    builder: (context, c) => DropdownMenu<String>(
                      width: c.maxWidth,
                      initialSelection: key,
                      enabled: keys.isNotEmpty,
                      enableFilter: true,
                      requestFocusOnTap: true,
                      label: Text(l10n.purchaseRegisterSupplierLabel),
                      hintText: l10n.purchaseSelectSupplierHint,
                      leadingIcon: const Icon(Icons.search, size: 18),
                      dropdownMenuEntries: [
                        for (final k in keys)
                          DropdownMenuEntry(
                              value: k,
                              label: '${suppliers[k]!.$1} (${suppliers[k]!.$2})'),
                      ],
                      onSelected: (k) {
                        if (!mounted) return;
                        setState(() => _statementSupplierKey = k);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _exportBtn(l10n.reportsExportCsvLabel, () async {
                  if (st == null) return;
                  await _saveCsv(
                      ReportService.exportCustomerStatementsCsv([st],
                          supplier: true),
                      'supplier_statement_$ts.csv');
                }),
                const SizedBox(width: 4),
                _exportBtn(l10n.customerMgmtExportPdfMenuLabel, () async {
                  if (st == null) return;
                  final bytes = await CustomerStatementPdfService.export([st],
                      showFooterBranding: _showFooterBranding, supplier: true);
                  await _savePdf(bytes, 'supplier_statement_$ts.pdf');
                }),
              ],
            ),
          ),
          if (keys.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState(l10n.purchaseRegisterEmpty),
            )
          else if (st == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState(l10n.purchaseSelectSupplierHint),
            )
          else
            _customerStatementSection(st, supplier: true),
        ],
      ),
    );
  }

  /// Return period shared by the GSTR-1 and GSTR-3B sub-tabs.
  String _returnPeriodLabel() {
    final ml = MaterialLocalizations.of(context);
    final (y, n) = _gstr1Period;
    return _gstr1Quarterly
        ? '${ml.formatMonthYear(DateTime(y, n * 3 - 2))} – '
            '${ml.formatMonthYear(DateTime(y, n * 3))}'
        : ml.formatMonthYear(DateTime(y, n));
  }

  /// Monthly / quarterly switch + recent periods (24 months / 8 quarters).
  /// Changing it reloads the open return sub-tab.
  Widget _returnPeriodPicker() {
    final l10n = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final periods = <(int, int)>[
      if (_gstr1Quarterly)
        for (var i = 0; i < 8; i++)
          () {
            final q = (now.month - 1) ~/ 3 + 1 - i;
            final y = now.year + ((q - 1) / 4).floor();
            return (y, (q - 1) % 4 + 1);
          }()
      else
        for (var i = 0; i < 24; i++)
          (DateTime(now.year, now.month - i).year,
              DateTime(now.year, now.month - i).month),
    ];
    String label((int, int) p) => _gstr1Quarterly
        ? '${ml.formatMonthYear(DateTime(p.$1, p.$2 * 3 - 2))} – '
            '${ml.formatMonthYear(DateTime(p.$1, p.$2 * 3))}'
        : ml.formatMonthYear(DateTime(p.$1, p.$2));
    void setPeriod(void Function() change) {
      setState(() {
        change();
        _gstr1Report = null;
        _gstr3b = null;
      });
      _loadTaxSection();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l10n.gstr1Monthly)),
              ButtonSegment(value: true, label: Text(l10n.gstr1Quarterly)),
            ],
            selected: {_gstr1Quarterly},
            onSelectionChanged: (v) => setPeriod(() {
              _gstr1Quarterly = v.first;
              final last = DateTime(now.year, now.month - (v.first ? 3 : 1));
              _gstr1Period = v.first
                  ? (last.year, (last.month - 1) ~/ 3 + 1)
                  : (last.year, last.month);
            }),
          ),
          DropdownButton<(int, int)>(
            value: periods.contains(_gstr1Period) ? _gstr1Period : null,
            items: [
              for (final p in periods)
                DropdownMenuItem(value: p, child: Text(label(p))),
            ],
            onChanged: (p) {
              if (p != null) setPeriod(() => _gstr1Period = p);
            },
          ),
        ],
      ),
    );
  }

  Widget _gstr1Card() {
    final l10n = AppLocalizations.of(context)!;
    final r = _gstr1Report;

    String issue(Gstr1Issue i) {
      final msg = switch (i.kind) {
        Gstr1IssueKind.nonInr => l10n.gstr1IssueNonInr,
        Gstr1IssueKind.missingPlaceOfSupply => l10n.gstr1IssueMissingPos,
        Gstr1IssueKind.invalidCustomerGstin => l10n.gstr1IssueInvalidGstin,
        Gstr1IssueKind.missingHsn => l10n.gstr1IssueMissingHsn,
        Gstr1IssueKind.unusualRate => l10n.gstr1IssueUnusualRate(i.detail),
        Gstr1IssueKind.invoiceDiscount => l10n.gstr1IssueInvoiceDiscount,
        Gstr1IssueKind.negativeB2cs => l10n.gstr1IssueNegativeB2cs(
            GstUtils.stateLabel(i.detail.split('|').first),
            i.detail.split('|').last),
      };
      return i.number.isEmpty ? msg : '${i.number} — $msg';
    }

    Widget issueList(String title, List<Gstr1Issue> list, Color color) =>
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(Icons.warning_amber_rounded, color: color),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          children: [
            for (final i in list.take(50))
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 20, 6),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(issue(i), style: const TextStyle(fontSize: 13))),
              ),
            if (list.length > 50)
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 20, 10),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.gstr1MoreIssues(list.length - 50))),
              ),
          ],
        );

    double taxable(Iterable<double> v) => v.fold(0.0, (a, b) => a + b);
    int docs(List<Gstr1DocRow> rows) => rows.map((x) => x.invoiceId).toSet().length;

    return _sectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: _cardTitle(l10n.reportsGstr1Title),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(l10n.reportsGstr1Subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          _returnPeriodPicker(),
          if (r == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (!r.companyGstinValid)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _missingCostBanner(l10n.gstr1CompanyGstinMissing),
              ),
            _gstTableRow([
              (l10n.gstr1SectionLabel, 5, false),
              (l10n.gstr1RowsLabel, 2, true),
              (l10n.reportsTaxableAmountLabel, 3, true),
            ], header: true),
            for (final (name, count, value) in [
              ('B2B (4A)', docs(r.b2b), taxable(r.b2b.map((x) => x.taxable))),
              ('B2C Large (5)', docs(r.b2cl), taxable(r.b2cl.map((x) => x.taxable))),
              ('B2C Small (7)', r.b2cs.length, taxable(r.b2cs.map((x) => x.taxable))),
              ('${l10n.gstr1NotesRegistered} (9B)', docs(r.cdnr),
                  taxable(r.cdnr.map((x) => x.taxable))),
              ('${l10n.gstr1NotesUnregistered} (9B)', docs(r.cdnur),
                  taxable(r.cdnur.map((x) => x.taxable))),
              ('${l10n.gstr1NilExempt} (8)', 4,
                  taxable(r.exemp.map((x) => x.nil + x.exempt + x.nonGst))),
              ('HSN B2B (12)', r.hsnB2b.length, taxable(r.hsnB2b.map((x) => x.taxable))),
              ('HSN B2C (12)', r.hsnB2c.length, taxable(r.hsnB2c.map((x) => x.taxable))),
            ])
              _gstTableRow([
                (name, 5, false),
                ('$count', 2, true),
                (_money(value), 3, true),
              ]),
            _gstTableRow([
              ('${l10n.reportsDocumentsIssuedTab} (13)', 5, false),
              ('${r.docs.fold(0, (a, d) => a + d.total)}', 2, true),
              ('', 3, true),
            ]),
            if (r.excluded.isNotEmpty)
              issueList(l10n.gstr1ExcludedTitle(r.excluded.length), r.excluded,
                  Theme.of(context).colorScheme.error),
            if (r.warnings.isNotEmpty)
              issueList(l10n.gstr1WarningsTitle(r.warnings.length), r.warnings,
                  Colors.orange),
            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              controlAffinity: ListTileControlAffinity.leading,
              value: _gstr1IncludeRegister,
              onChanged: (v) =>
                  setState(() => _gstr1IncludeRegister = v ?? false),
              title: Text(l10n.gstr1IncludeRegister),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l10n.customerMgmtExportPdfMenuLabel),
                onPressed: _gstr1Loading
                    ? null
                    : () async {
                        final (y, n) = _gstr1Period;
                        final bytes = await Gstr1PdfWriter.build(r,
                            periodLabel: _returnPeriodLabel(),
                            company: await ref
                                .read(companyInfoRepositoryProvider)
                                .getCompanyInfo(),
                            datePattern: _datePattern,
                            showFooterBranding: _showFooterBranding);
                        if (!mounted) return;
                        await _savePdf(
                            bytes,
                            _gstr1Quarterly
                                ? 'gstr1_$y-Q$n.pdf'
                                : 'gstr1_$y-${n.toString().padLeft(2, '0')}.pdf');
                      },
              ),
              FilledButton.icon(
                icon: const Icon(Icons.table_view_outlined),
                label: Text(l10n.gstr1ExportExcel),
                onPressed: !r.companyGstinValid || _gstr1Loading
                    ? null
                    : () async {
                        final (y, n) = _gstr1Period;
                        final name = _gstr1Quarterly
                            ? 'gstr1_$y-Q$n.xlsx'
                            : 'gstr1_$y-${n.toString().padLeft(2, '0')}.xlsx';
                        await _saveBytes(
                            Gstr1ExcelWriter.build(r,
                                includeRegister: _gstr1IncludeRegister),
                            name,
                            'xlsx',
                            l10n.gstr1ExportExcel);
                      },
              ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Purchases (PurchaseGstReportsPlan.md) ─────────────────────────────────

  Widget _buildPurchases() {
    final l10n = AppLocalizations.of(context)!;
    final r = _purchaseReport;
    if (r == null) return const Center(child: CircularProgressIndicator());
    final gst = _showGstFields;
    final rows = [
      for (final x in r.rows)
        if ((_purchaseFilter == 'all' ||
                (_purchaseFilter == 'registered') ==
                    (x.supplierState != null)) &&
            ('${x.supplierName} ${x.billNumber}'
                .toLowerCase()
                .contains(_purchaseQuery.trim().toLowerCase())))
          x,
    ];
    void setFilter(VoidCallback change) {
      if (!mounted) return;
      setState(() {
        change();
        _purchasePage = 0;
      });
    }

    String rate(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}%';
    String issue(PurchaseGstIssue i) {
      final msg = switch (i.kind) {
        PurchaseGstIssueKind.invalidSupplierGstin => l10n.purchaseIssueInvalidGstin,
        PurchaseGstIssueKind.taxWithoutGstin => l10n.purchaseIssueTaxWithoutGstin,
        PurchaseGstIssueKind.unusualRate => l10n.gstr1IssueUnusualRate(i.detail),
      };
      return i.billNumber.isEmpty ? msg : '${i.billNumber} — $msg';
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final (from, to) = _range;
    final periodLabel = '${_formatDate(from)} – ${_formatDate(to)}';
    double sum(double Function(PurchaseGstRow) f) =>
        r.rows.fold(0.0, (a, x) => a + f(x));

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
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.receipt_long_outlined, size: 16),
                        label: Text(l10n.purchaseRegisterTitle)),
                    ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(l10n.purchasePayablesTab)),
                    ButtonSegment(
                        value: 2,
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: Text(l10n.purchaseSupplierStatementTab)),
                  ],
                  selected: {_purchaseSection},
                  onSelectionChanged: (v) {
                    if (!mounted) return;
                    setState(() => _purchaseSection = v.first);
                    if (v.first >= 1 && _payables == null) _loadPayables();
                  },
                ),
              ),
              if (_purchaseSection == 1) _payablesSection(ts),
              if (_purchaseSection == 2) _supplierStatementCard(ts),
              if (_purchaseSection == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          child: _kpiCard(l10n.purchaseKpiTotal,
                              _money(sum((x) => x.total)),
                              const Color(0xFF7C3AED), Icons.shopping_cart_outlined)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _kpiCard(l10n.purchaseKpiTaxable,
                              _money(sum((x) => x.taxable)),
                              const Color(0xFF0284C7), Icons.receipt_long_outlined)),
                      if (gst) ...[
                        const SizedBox(width: 12),
                        Expanded(
                            child: _kpiCard(l10n.purchaseKpiItc,
                                _money(r.itcRegular.total + r.rcmTax.total),
                                const Color(0xFF059669), Icons.verified_outlined)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _kpiCard(l10n.purchaseKpiNotClaimable,
                                _money(r.ineligibleTax.total),
                                const Color(0xFFD97706), Icons.block_outlined)),
                      ],
                    ],
                  ),
                ),
              ),
              if (_purchaseSection == 0)
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _cardTitle(
                        l10n.purchaseRegisterTitle,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _exportBtn(l10n.reportsExportCsvLabel, () async {
                              await _saveCsv(
                                  PurchaseRegisterExport.csv(r.rows,
                                      datePattern: _datePattern),
                                  'purchase_register_$ts.csv');
                            }),
                            const SizedBox(width: 4),
                            _exportBtn(l10n.customerMgmtExportPdfMenuLabel,
                                () async {
                              final bytes = await PurchaseRegisterExport.pdf(r,
                                  periodLabel: periodLabel,
                                  company: await ref
                                      .read(companyInfoRepositoryProvider)
                                      .getCompanyInfo(),
                                  datePattern: _datePattern,
                                  showFooterBranding: _showFooterBranding);
                              if (!mounted) return;
                              await _savePdf(bytes, 'purchase_register_$ts.pdf');
                            }),
                          ],
                        ),
                      ),
                    ),
                    if (r.rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _emptyState(l10n.purchaseRegisterEmpty),
                      )
                    else ...[
                      if (gst && r.warnings.isNotEmpty)
                        ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                          leading: const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          title: Text(l10n.gstr1WarningsTitle(r.warnings.length),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          children: [
                            for (final i in r.warnings.take(50))
                              Padding(
                                padding: const EdgeInsets.fromLTRB(56, 0, 20, 6),
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(issue(i),
                                        style: const TextStyle(fontSize: 13))),
                              ),
                          ],
                        ),
                      if (gst) ...[
                        _gstTableRow([
                          (l10n.fieldTaxRateLabel, 2, false),
                          (l10n.reportsTaxableAmountLabel, 3, true),
                          ('IGST', 2, true),
                          ('CGST', 2, true),
                          ('SGST', 2, true),
                        ], header: true),
                        for (final b in r.byRate)
                          _gstTableRow([
                            (rate(b.rate), 2, false),
                            (_money(b.taxable), 3, true),
                            (_money(b.igst), 2, true),
                            (_money(b.cgst), 2, true),
                            (_money(b.sgst), 2, true),
                          ]),
                        const SizedBox(height: 16),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (gst)
                              for (final (key, label) in [
                                ('all', l10n.invoiceMgmtStatusAllLabel),
                                ('registered', l10n.purchaseFilterRegistered),
                                ('unregistered', l10n.purchaseFilterUnregistered),
                              ])
                                ChoiceChip(
                                  label: Text(label),
                                  selected: _purchaseFilter == key,
                                  onSelected: (_) =>
                                      setFilter(() => _purchaseFilter = key),
                                ),
                            SizedBox(
                              width: 240,
                              child: TextField(
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.search, size: 18),
                                  hintText: l10n.purchaseRegisterSearchHint,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppBorderRadius.xsmall)),
                                ),
                                onChanged: (v) =>
                                    setFilter(() => _purchaseQuery = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _gstTableRow([
                        (l10n.invoiceMgmtColDate, 2, false),
                        (l10n.purchaseRegisterBillNoLabel, 2, false),
                        (l10n.purchaseRegisterSupplierLabel, 3, false),
                        if (gst) ('GSTIN', 3, false),
                        (l10n.reportsTaxableAmountLabel, 2, true),
                        (l10n.fieldTaxLabel, 2, true),
                        (l10n.fieldTotalLabel, 2, true),
                        if (gst) ('ITC', 1, true),
                      ], header: true),
                      for (final x in rows
                          .skip(_purchasePage * _purchasePageSize)
                          .take(_purchasePageSize))
                        _gstTableRow([
                          (_formatDate(x.date), 2, false),
                          (x.billNumber.isEmpty ? '—' : x.billNumber, 2, false),
                          (x.supplierName, 3, false),
                          if (gst)
                            (x.supplierGstin.isEmpty ? '—' : x.supplierGstin, 3, false),
                          (_money(x.taxable), 2, true),
                          (_money(x.tax), 2, true),
                          (_money(x.total), 2, true),
                          if (gst)
                            (x.reverseCharge
                                ? 'RCM'
                                : x.itcEligible ? 'Y' : 'N', 1, true),
                        ]),
                      _buildReportPagination(
                        currentPage: _purchasePage,
                        pageSize: _purchasePageSize,
                        total: rows.length,
                        onPageChange: (p) {
                          if (!mounted) return;
                          setState(() => _purchasePage = p);
                        },
                        onSizeChange: (n) => setFilter(() => _purchasePageSize = n),
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

  /// Reports → Tax → GSTR-3B: summary to type into the portal (no upload
  /// file). Sales = GSTR-1 numbers; ITC from purchase bills.
  Widget _gstr3bCard() {
    final l10n = AppLocalizations.of(context)!;
    final r = _gstr3b;
    Widget table(List<(String, int, bool)> header,
            List<List<(String, int, bool)>> rows) =>
        Column(children: [
          _gstTableRow(header, header: true),
          for (final row in rows) _gstTableRow(row),
        ]);
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
    List<(String, int, bool)> heads(String label, double taxable, double igst,
            double cgst, {bool showTaxable = true}) =>
        [
          (label, 6, false),
          (showTaxable ? _money(taxable) : '', 2, true),
          (_money(igst), 2, true),
          (_money(cgst), 2, true),
          (_money(cgst), 2, true),
        ];
    final taxHeader = [
      (l10n.gstr3bNature, 6, false),
      (l10n.reportsTaxableAmountLabel, 2, true),
      ('IGST', 2, true),
      ('CGST', 2, true),
      ('SGST', 2, true),
    ];

    return _sectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: _cardTitle(
              l10n.gstr3bTitle,
              trailing: r == null
                  ? null
                  : _exportBtn(l10n.customerMgmtExportPdfMenuLabel, () async {
                      final (y, n) = _gstr1Period;
                      final bytes = await Gstr3bPdfWriter.build(r,
                          periodLabel: _returnPeriodLabel(),
                          company: await ref
                              .read(companyInfoRepositoryProvider)
                              .getCompanyInfo(),
                          datePattern: _datePattern,
                          showFooterBranding: _showFooterBranding);
                      if (!mounted) return;
                      await _savePdf(
                          bytes,
                          _gstr1Quarterly
                              ? 'gstr3b_$y-Q$n.pdf'
                              : 'gstr3b_$y-${n.toString().padLeft(2, '0')}.pdf');
                    }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(l10n.gstr3bSubtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          _returnPeriodPicker(),
          if (r == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (!r.companyGstinValid)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _missingCostBanner(l10n.gstr1CompanyGstinMissing),
              ),
            if (r.salesExcluded.isNotEmpty || r.salesWarnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _missingCostBanner(l10n.gstr3bSalesIssues(
                    r.salesExcluded.length, r.salesWarnings.length)),
              ),
            if (r.purchaseWarnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _missingCostBanner(
                    l10n.gstr3bPurchaseIssues(r.purchaseWarnings.length)),
              ),
            if (!_showPurchases)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _missingCostBanner(l10n.gstr3bPurchasesOffNote),
              ),
            heading(l10n.gstr3b31Title),
            table(taxHeader, [
              heads(l10n.gstr3bOutwardTaxable, r.outwardTaxable.taxable,
                  r.outwardTaxable.tax.igst, r.outwardTaxable.tax.cgst),
              heads(l10n.gstr3bZeroRated, r.outwardZeroRated, 0, 0),
              heads(l10n.gstr3bNilExempt, r.outwardNilExempt, 0, 0),
              heads(l10n.gstr3bInwardRcm, r.inwardReverseCharge.taxable,
                  r.inwardReverseCharge.tax.igst, r.inwardReverseCharge.tax.cgst),
              heads(l10n.gstr3bNonGst, r.outwardNonGst, 0, 0),
            ]),
            if (r.interStateUnregistered.isNotEmpty) ...[
              heading(l10n.gstr3b32Title),
              table([
                (l10n.gstr3bPlaceOfSupply, 6, false),
                (l10n.reportsTaxableAmountLabel, 3, true),
                ('IGST', 3, true),
              ], [
                for (final x in r.interStateUnregistered)
                  [
                    (GstUtils.stateLabel(x.pos), 6, false),
                    (_money(x.taxable), 3, true),
                    (_money(x.igst), 3, true),
                  ],
              ]),
            ],
            heading(l10n.gstr3b4Title),
            table(taxHeader, [
              heads(l10n.gstr3bItcRcm, 0, r.itcReverseCharge.igst,
                  r.itcReverseCharge.cgst, showTaxable: false),
              heads(l10n.gstr3bItcOther, 0, r.itcOther.igst, r.itcOther.cgst,
                  showTaxable: false),
              heads(l10n.gstr3bItcNet, 0, r.itcNet.igst, r.itcNet.cgst,
                  showTaxable: false),
              heads(l10n.gstr3bNotClaimable, 0, r.notClaimable.igst,
                  r.notClaimable.cgst, showTaxable: false),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(l10n.gstr3bBlockedNote,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            heading(l10n.gstr3b5Title),
            table([
              (l10n.gstr3bNature, 6, false),
              (l10n.gstr3bInterState, 3, true),
              (l10n.gstr3bIntraState, 3, true),
            ], [
              [
                (l10n.gstr3bExemptInward, 6, false),
                (_money(r.inwardExemptInter), 3, true),
                (_money(r.inwardExemptIntra), 3, true),
              ],
            ]),
            heading(l10n.gstr3b61Title),
            table([
              (l10n.fieldTaxLabel, 2, false),
              (l10n.gstr3bPayable, 2, true),
              (l10n.gstr3bPaidItc, 2, true),
              (l10n.gstr3bPaidCash, 2, true),
              (l10n.gstr3bItcLeft, 2, true),
            ], [
              for (final (name, p) in [
                ('IGST', r.igst),
                ('CGST', r.cgst),
                ('SGST', r.sgst),
              ])
                [
                  (name, 2, false),
                  (_money(p.payable), 2, true),
                  (_money(p.paidByItc), 2, true),
                  (_money(p.paidInCash), 2, true),
                  (_money(p.itcLeft), 2, true),
                ],
            ]),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _docsIssuedCard(int ts) {
    final l10n = AppLocalizations.of(context)!;
    String nature(String type) => switch (type) {
          'Credit Note' => l10n.gstDocNatureCreditNote,
          'Debit Note' => l10n.gstDocNatureDebitNote,
          _ => l10n.gstDocNatureOutward,
        };
    return _sectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: _cardTitle(
              l10n.reportsDocumentsIssuedTitle,
              trailing: _docRows == null
                  ? null
                  : _exportBtn(l10n.reportsExportCsvLabel, () async {
                      await _saveCsv(
                          ReportService.exportDocumentsIssuedCsv(_docRows!),
                          'documents_issued_$ts.csv');
                    }),
            ),
          ),
          if (_docRows == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_docRows!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _emptyState(l10n.reportsNoDocumentsIssuedMessage),
            )
          else ...[
            _gstTableRow([
              (l10n.reportsGstDocNatureLabel, 4, false),
              (l10n.reportsGstFromLabel, 3, false),
              (l10n.reportsGstToLabel, 3, false),
              (l10n.reportsGstTotalNumberLabel, 2, true),
              (l10n.reportsGstCancelledLabel, 2, true),
            ], header: true),
            for (final r in _docRows!)
              _gstTableRow([
                (nature(r.type), 4, false),
                (r.from, 3, false),
                (r.to, 3, false),
                ('${r.total}', 2, true),
                ('${r.cancelled}', 2, true),
              ]),
          ],
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
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      side: BorderSide(
          color: selected
              ? Theme.of(context).primaryColor
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _exportBtn(
                      AppLocalizations.of(context)!.reportsExportCsvLabel,
                      () async {
                    final csv =
                        ReportService.exportTopCustomersCsv(_topCustomers);
                    await _saveCsv(csv, 'top_customers_$ts.csv');
                  }),
                  const SizedBox(width: 4),
                  _exportBtn(
                      AppLocalizations.of(context)!
                          .customerMgmtExportPdfMenuLabel, () async {
                    final (from, to) = _range;
                    final bytes = await ReportService.exportTopCustomersPdf(
                      _topCustomers,
                      currencySymbol: _sym,
                      showFooterBranding: _showFooterBranding,
                      dateRangeLabel:
                          '${_formatDate(from)} – ${_formatDate(to)}  •  $_currencyScopeLabel',
                    );
                    await _savePdf(bytes, 'top_customers_$ts.pdf');
                  }),
                ],
              ),
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
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor),
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

  Widget _customerStatementSection(CustomerStatement statement,
      {bool supplier = false}) {
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statement.currencyCode,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _statementSummaryCards(statement, supplier: supplier),
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

  Widget _statementSummaryCards(CustomerStatement statement,
      {bool supplier = false}) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _kpiCard(
          l10n.reportsOpeningLabel,
          _statementMoney(statement, statement.openingBalance),
          Theme.of(context).colorScheme.onSurfaceVariant,
          Icons.account_balance_wallet),
      _kpiCard(
          supplier ? l10n.purchaseBilledLabel : l10n.reportsInvoicedLabel,
          _statementMoney(statement, statement.invoiced),
          Theme.of(context).primaryColor,
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
                          : Theme.of(context).primaryColor))),
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
                              trailing: _hideCost ? null : Row(
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
                                  const SizedBox(width: 4),
                                  _exportBtn(
                                      AppLocalizations.of(context)!
                                          .customerMgmtExportPdfMenuLabel,
                                      () async {
                                    final (from, to) = _range;
                                    final bytes = await ReportService
                                        .exportTopProductsPdf(
                                      _topProducts,
                                      currencySymbol: _sym,
                                      rankByProfit: _rankProductsByProfit,
                                      showFooterBranding: _showFooterBranding,
                                      dateRangeLabel:
                                          '${_formatDate(from)} – ${_formatDate(to)}  •  $_currencyScopeLabel',
                                    );
                                    await _savePdf(
                                        bytes, 'top_products_$ts.pdf');
                                  }),
                                ],
                              ),
                            ),
                          ),
                          if (!_hideCost && _missingCostItemCount > 0)
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
          if (!_hideCost) ...[
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsProfitLabel, right: true)),
          Expanded(
              flex: 1,
              child: _TableHead(l10n.reportsMarginColumnLabel, right: true)),
          ],
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
          if (!_hideCost) ...[
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
        ],
      ),
    );
  }

  // ─── Section: Inventory Valuation ──────────────────────────────────────────

  Widget _inventoryExcludedBanner() {
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
              AppLocalizations.of(context)!.reportsInventoryExcludedBannerMessage(
                  _inventorySummary.excludedCount),
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryValuation() {
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsInventoryBlockedValueLabel,
                                  _money(_inventorySummary.stockValue),
                                  Theme.of(context).primaryColor,
                                  Icons.warehouse_outlined)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsInventoryPotentialSaleValueLabel,
                                  _money(_inventorySummary.retailValue),
                                  const Color(0xFF7C3AED),
                                  Icons.sell_outlined)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsInventoryLockedProfitLabel,
                                  _money(_inventorySummary.lockedProfit),
                                  _inventorySummary.lockedProfit < 0
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A),
                                  Icons.savings_outlined)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsInventoryTotalUnitsLabel,
                                  _fmtInt.format(_inventorySummary.totalUnits),
                                  const Color(0xFF0F766E),
                                  Icons.inventory_2_outlined)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _kpiCard(
                                  l10n.reportsInventoryProductCountLabel,
                                  _fmtInt.format(_inventorySummary.productCount),
                                  const Color(0xFF334155),
                                  Icons.category_outlined)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_inventorySummary.excludedCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _inventoryExcludedBanner(),
                ),
              _sectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: _cardTitle(
                        l10n.reportsInventoryBreakdownTitle,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _exportBtn(l10n.reportsExportCsvLabel, () async {
                              final rows = await ref
                                  .read(reportRepositoryProvider)
                                  .getInventoryValuationRows(limit: null);
                              final csv = ReportService
                                  .exportInventoryValuationCsv(
                                      rows, _inventorySummary);
                              await _saveCsv(csv, 'inventory_valuation_$ts.csv');
                            }),
                            const SizedBox(width: 4),
                            _exportBtn(l10n.customerMgmtExportPdfMenuLabel,
                                () async {
                              final rows = await ref
                                  .read(reportRepositoryProvider)
                                  .getInventoryValuationRows(limit: null);
                              final bytes = await ReportService
                                  .exportInventoryValuationPdf(
                                rows,
                                _inventorySummary,
                                currencySymbol: _sym,
                                showFooterBranding: _showFooterBranding,
                              );
                              await _savePdf(bytes, 'inventory_valuation_$ts.pdf');
                            }),
                          ],
                        ),
                      ),
                    ),
                    if (_inventoryRows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _emptyState(l10n.reportsNoInventoryDataMessage),
                      )
                    else ...[
                      _inventoryTableHeader(),
                      ..._inventoryRows
                          .skip(_inventoryPage * _inventoryPageSize)
                          .take(_inventoryPageSize)
                          .map(_inventoryRow),
                      _buildReportPagination(
                        currentPage: _inventoryPage,
                        pageSize: _inventoryPageSize,
                        total: _inventoryRows.length,
                        onPageChange: (p) {
                          if (!mounted) return;
                          setState(() => _inventoryPage = p);
                        },
                        onSizeChange: (s) {
                          if (!mounted) return;
                          setState(() {
                            _inventoryPageSize = s;
                            _inventoryPage = 0;
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

  Widget _inventoryTableHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
              flex: 4, child: _TableHead(l10n.reportsInventoryProductColumnLabel)),
          Expanded(
              flex: 2,
              child:
                  _TableHead(l10n.reportsInventoryStockColumnLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsInventoryPurchasePriceColumnLabel,
                  right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsInventoryStockValueColumnLabel,
                  right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsInventorySaleValueColumnLabel,
                  right: true)),
        ],
      ),
    );
  }

  Widget _inventoryRow(InventoryValuationRow p) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(p.name,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(_fmtInt.format(p.stock),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 2,
              child: Text(_money(p.purchasePrice),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              flex: 2,
              child: Text(_money(p.stockValue),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor))),
          Expanded(
              flex: 2,
              child: Text(_money(p.retailValue),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  // ─── Section: Daily Sales & Profit Report ──────────────────────────────────

  List<DailyLine> get _dailyLines => ReportService.dailyLines(_dailyReport,
      invoices: !_cashUpi || _dailyView != _DailyView.exchanges,
      exchanges: _cashUpi && _dailyView != _DailyView.invoices);

  Widget _buildDailyReport() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final l10n = AppLocalizations.of(context)!;
    final lines = _dailyLines;
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
                              trailing: _hideCost ? null : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _exportBtn(l10n.reportsExportCsvLabel,
                                      () async {
                                    final csv =
                                        ReportService.exportDailyReportCsv(
                                            _dailyLines,
                                            cashUpi: _cashUpi);
                                    await _saveCsv(csv, 'daily_report_$ts.csv');
                                  }),
                                  const SizedBox(width: 4),
                                  _exportBtn(
                                      l10n.customerMgmtExportPdfMenuLabel,
                                      () async {
                                    final (from, to) = _dailyRange;
                                    final bytes = await ReportService
                                        .exportDailyReportPdf(
                                      _dailyLines,
                                      currencySymbol: _sym,
                                      showFooterBranding: _showFooterBranding,
                                      dateRangeLabel:
                                          '${_formatDate(from)} – ${_formatDate(to)}  •  $_currencyScopeLabel',
                                      cashUpi: _cashUpi,
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
                          if (!_hideCost && _missingCostItemCount > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: _missingCostBanner(),
                            ),
                          if (_cashUpi)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final (v, label) in [
                                    (_DailyView.all,
                                        l10n.invoiceMgmtStatusAllLabel),
                                    (_DailyView.invoices, l10n.navInvoices),
                                    (_DailyView.exchanges,
                                        l10n.reportsTransactionsLabel),
                                  ])
                                    _rangeModeChip(label, _dailyView == v, () {
                                      if (!mounted) return;
                                      setState(() {
                                        _dailyView = v;
                                        _dailyPage = 0;
                                      });
                                    }),
                                ],
                              ),
                            ),
                          _dailyKpis(),
                          if (lines.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _emptyState(
                                  l10n.reportsNoSalesInPeriodMessage),
                            )
                          else ...[
                            _dailyTableHeader(),
                            for (var i = _dailyPage * _dailyPageSize;
                                i < lines.length &&
                                    i < (_dailyPage + 1) * _dailyPageSize;
                                i++)
                              _dailyRow(lines[i],
                                  showDate: i == _dailyPage * _dailyPageSize ||
                                      lines[i - 1].d.date != lines[i].d.date),
                            _buildReportPagination(
                              currentPage: _dailyPage,
                              pageSize: _dailyPageSize,
                              total: lines.length,
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
          if (_cashUpi)
            Expanded(flex: 2, child: _TableHead(l10n.reportsTypeColumnLabel)),
          Expanded(
              flex: 1,
              child: _TableHead(
                  _cashUpi ? l10n.reportsCountColumnLabel : l10n.navInvoices,
                  right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsSalesColumnLabel, right: true)),
          if (!_hideCost) ...[
          Expanded(
              flex: 2,
              child: _TableHead(l10n.reportsCogsColumnLabel, right: true)),
          Expanded(
              flex: 2, child: _TableHead(l10n.reportsProfitLabel, right: true)),
          Expanded(
              flex: 1,
              child: _TableHead(l10n.reportsMarginColumnLabel, right: true)),
          ],
          if (_cashUpi) ...[
          Expanded(
              flex: 2,
              child: _TableHead(l10n.cashExchangeCashLabel, right: true)),
          Expanded(
              flex: 2,
              child: _TableHead(l10n.cashExchangeUpiBankLabel, right: true)),
          ],
        ],
      ),
    );
  }

  Widget _dailyKpis() {
    final l10n = AppLocalizations.of(context)!;
    final showInv = !_cashUpi || _dailyView != _DailyView.exchanges;
    final showExc = _cashUpi && _dailyView != _DailyView.invoices;
    double sum(double Function(DailyPoint) f) =>
        _dailyReport.fold<double>(0, (a, d) => a + f(d));
    final profit = sum((d) => d.profit);
    final totalProfit = sum((d) => d.totalProfit);
    final cash = sum((d) => d.cash);
    final upi = sum((d) => d.upiBank);
    Color profitColor(double v) =>
        v < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    // As many cards per line as fit at >= 150px each; the rest wrap.
    Widget row(List<Widget> cards) => LayoutBuilder(builder: (context, c) {
          const minW = 150.0, gap = 12.0;
          final perRow = ((c.maxWidth + gap) / (minW + gap))
              .floor()
              .clamp(1, cards.length);
          final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final k in cards)
                SizedBox(width: w, child: IntrinsicHeight(child: k)),
            ],
          );
        });
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showInv) ...[
            if (showExc) ...[
              _TableHead(l10n.navInvoices),
              const SizedBox(height: 8),
            ],
            row([
              _kpiCard(l10n.reportsSalesColumnLabel, _money(sum((d) => d.billed)),
                  Theme.of(context).primaryColor, Icons.receipt_long,
                  outlined: true),
              if (!_hideCost) ...[
                _kpiCard(l10n.reportsCogsColumnLabel, _money(sum((d) => d.cogs)),
                    const Color(0xFFEA580C), Icons.inventory_2_outlined,
                    outlined: true),
                _kpiCard(
                    _cashUpi
                        ? l10n.reportsInvoiceProfitLabel
                        : l10n.reportsTotalProfitLabel,
                    _money(profit),
                    profitColor(profit),
                    Icons.savings_outlined,
                    outlined: true),
              ],
            ]),
          ],
          if (showExc) ...[
            if (showInv) ...[
              const SizedBox(height: 16),
              _TableHead(l10n.reportsCashExchangeTypeLabel),
              const SizedBox(height: 8),
            ],
            row([
              _kpiCard(
                  l10n.reportsTxnsLabel,
                  _fmtInt.format(
                      _dailyReport.fold<int>(0, (a, d) => a + d.exchangeCount)),
                  const Color(0xFF7C3AED),
                  Icons.swap_horiz,
                  outlined: true),
              _kpiCard(
                  l10n.reportsServiceIncomeLabel,
                  _money(sum((d) => d.serviceIncome)),
                  const Color(0xFF0F766E),
                  Icons.trending_up,
                  outlined: true),
              _kpiCard(
                  l10n.cashExchangeCashLabel,
                  _money(cash),
                  cash < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  Icons.payments_outlined,
                  outlined: true),
              _kpiCard(
                  l10n.cashExchangeUpiBankLabel,
                  _money(upi),
                  upi < 0 ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                  Icons.account_balance_outlined,
                  outlined: true),
              if (showInv && !_hideCost)
                _kpiCard(l10n.reportsTotalProfitLabel, _money(totalProfit),
                    profitColor(totalProfit), Icons.savings_outlined,
                    outlined: true),
            ]),
          ],
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

  // One line of the daily table; [showDate] is false for the second line of
  // the same day. Exchange lines: profit = service fee, Cash / UPI-Bank =
  // ledger movements; invoice lines: Cash / UPI-Bank = payments received.
  Widget _dailyRow(DailyLine l, {required bool showDate}) {
    final l10n = AppLocalizations.of(context)!;
    final d = l.d;
    final ex = l.exchange;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final profit = ex ? d.serviceIncome : d.profit;
    Widget cell(int flex, String text, {Color? color, bool bold = false}) =>
        Expanded(
            flex: flex,
            child: Text(text,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w600 : null,
                    color: color ?? muted)));
    Color signed(double v) => v < 0
        ? const Color(0xFFDC2626)
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: ex || d.invoiceCount == 0
          ? null
          : () => _openDayInInvoiceStatus(d.date),
      child: Container(
        decoration: BoxDecoration(
            color: ex ? const Color(0xFF0F766E).withValues(alpha: 0.06) : null,
            border: showDate
                ? Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant))
                : null),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Text(showDate ? _formatStoredDate(d.date) : '',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface))),
            if (_cashUpi)
              Expanded(
                  flex: 2,
                  child: Text(
                      ex ? l10n.reportsCashExchangeTypeLabel : l10n.navInvoices,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ex
                              ? const Color(0xFF0F766E)
                              : Theme.of(context).colorScheme.onSurface))),
            cell(1, _fmtInt.format(ex ? d.exchangeCount : d.invoiceCount)),
            ex
                ? cell(2, '—')
                : cell(2, _money(d.billed),
                    color: const Color(0xFF1D4ED8), bold: true),
            if (!_hideCost) ...[
              cell(2, ex ? '—' : _money(d.cogs)),
              cell(2, _money(profit),
                  bold: true,
                  color: profit < 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A)),
              cell(1, ex ? '—' : '${d.marginPercent.toStringAsFixed(0)}%'),
            ],
            if (_cashUpi)
              for (final v in ex ? [d.cash, d.upiBank] : [d.paidCash, d.paidUpi])
                cell(2, _money(v), color: signed(v), bold: true),
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
                              Theme.of(context).primaryColor,
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _exportBtn(l10n.reportsExportCsvLabel, () async {
                                final csv = ReportService
                                    .exportInvoiceStatusCsv(filtered);
                                await _saveCsv(
                                    csv, 'invoice_status_$ts.csv');
                              }),
                              const SizedBox(width: 4),
                              _exportBtn(l10n.customerMgmtExportPdfMenuLabel,
                                  () async {
                                final filterName = switch (_invoiceFilter) {
                                  _InvoiceFilter.all =>
                                    l10n.invoiceMgmtStatusAllLabel,
                                  _InvoiceFilter.paid => l10n.paymentStatusPaid,
                                  _InvoiceFilter.partial =>
                                    l10n.paymentStatusPartial,
                                  _InvoiceFilter.unpaid =>
                                    l10n.paymentStatusUnpaid,
                                  _InvoiceFilter.overdue =>
                                    l10n.dashboardOverdueSectionTitle,
                                };
                                final bytes = await ReportService
                                    .exportInvoiceStatusPdf(
                                  filtered,
                                  currencySymbol: _sym,
                                  showFooterBranding: _showFooterBranding,
                                  dateRangeLabel:
                                      '$_invoiceStatusRangeLabel  •  $filterName  •  $_currencyScopeLabel',
                                );
                                await _savePdf(
                                    bytes, 'invoice_status_$ts.pdf');
                              }),
                            ],
                          ),
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
      _ => Theme.of(context).primaryColor,
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
