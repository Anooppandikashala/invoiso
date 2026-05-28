import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/database/settings_service.dart';

// ─── Date preset enum ─────────────────────────────────────────────────────────

enum _DatePreset {
  last30('Last 30 days'),
  last3m('Last 3 months'),
  last6m('Last 6 months'),
  thisYear('This year'),
  allTime('All time');

  final String label;
  const _DatePreset(this.label);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  _DatePreset _preset = _DatePreset.last3m;
  bool _loading = false;
  String _sym = 'Rs.';

  RevenueKpi _kpi = RevenueKpi.empty;
  List<MonthlyPoint> _trend = [];
  StatusBreakdown _status = StatusBreakdown.empty;
  List<AgedReceivable> _aged = [];
  List<TaxBucket> _taxBuckets = [];
  List<TopCustomer> _topCustomers = [];
  List<TopProduct> _topProducts = [];

  // Table pagination state
  int _agedPage = 0;
  int _agedPageSize = 10;
  int _customersPage = 0;
  int _customersPageSize = 10;
  int _productsPage = 0;
  int _productsPageSize = 10;
  QuotationStats _quotStats = QuotationStats.empty;

  // Formatting
  final _fmt = NumberFormat('#,##0.00');
  final _fmtInt = NumberFormat('#,##0');

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    return switch (_preset) {
      _DatePreset.last30 => (now.subtract(const Duration(days: 30)), now),
      _DatePreset.last3m => (
          DateTime(now.year, now.month - 3, now.day),
          now
        ),
      _DatePreset.last6m => (
          DateTime(now.year, now.month - 6, now.day),
          now
        ),
      _DatePreset.thisYear => (DateTime(now.year, 1, 1), now),
      _DatePreset.allTime => (DateTime(2000), now),
    };
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _loadCurrency();
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    final code =
        (await SettingsService.getSetting(SettingKey.currency)) ?? 'INR';
    final sym = SupportedCurrencies.all
        .firstWhere((c) => c.code == code,
            orElse: () => SupportedCurrencies.all.first)
        .symbol;
    if (mounted) setState(() => _sym = sym);
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final (from, to) = _range;
    try {
      final results = await Future.wait<dynamic>([
        ReportService.getRevenueSummary(from, to),
        ReportService.getMonthlyRevenueTrend(from, to),
        ReportService.getPaymentStatusBreakdown(from, to),
        ReportService.getAgedReceivables(),
        ReportService.getTaxByRate(from, to),
        ReportService.getTopCustomers(from, to),
        ReportService.getTopProducts(from, to),
        ReportService.getQuotationStats(from, to),
      ]);
      if (!mounted) return;
      setState(() {
        _kpi = results[0] as RevenueKpi;
        _trend = (results[1] as List).cast<MonthlyPoint>();
        _status = results[2] as StatusBreakdown;
        _aged = (results[3] as List).cast<AgedReceivable>();
        _taxBuckets = (results[4] as List).cast<TaxBucket>();
        _topCustomers = (results[5] as List).cast<TopCustomer>();
        _topProducts = (results[6] as List).cast<TopProduct>();
        _quotStats = results[7] as QuotationStats;
        _agedPage = 0;
        _customersPage = 0;
        _productsPage = 0;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _reload,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.red,
          indicatorWeight: 6,
          dividerColor: primary,
          tabs: const [
            Tab(text: 'Revenue'),
            Tab(text: 'Receivables'),
            Tab(text: 'Tax'),
            Tab(text: 'Top Customers'),
            Tab(text: 'Top Products'),
            Tab(text: 'Quotations'),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // ── Date filter strip (extends AppBar colour, no overflow risk) ──
            Container(
              //color: primary,
              decoration: BoxDecoration(
                  borderRadius:BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                color: primary
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(8, 6, 5, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _DatePreset.values.map((p) {
                    final sel = _preset == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.label),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel
                              ? const Color(0xFF002E78)
                              : Colors.grey[700],
                        ),
                        selected: sel,
                        selectedColor: Colors.white,
                        backgroundColor:
                            Colors.white,
                        side: BorderSide(
                          width: 2,
                          color: sel
                              ? primary
                              : Colors.grey.withValues(alpha: 0.45),
                        ),
                        onSelected: (_) {
                          setState(() => _preset = p);
                          _reload();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // ── Tab content ───────────────────────────────────────────────
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildRevenue(),
                    _buildReceivables(),
                    _buildTax(),
                    _buildTopCustomers(),
                    _buildTopProducts(),
                    _buildQuotations(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
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
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
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
              Text('Rows per page:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: pageSize,
                underline: const SizedBox(),
                items: [10, 25, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (n) { if (n != null) onSizeChange(n); },
              ),
              const SizedBox(width: 16),
              Text('$start – $end of $total', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0 ? () => onPageChange(currentPage - 1) : null,
                tooltip: 'Previous',
              ),
              Text('Page ${currentPage + 1} of $totalPages',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages - 1 ? () => onPageChange(currentPage + 1) : null,
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
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
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
                Expanded(child: _kpiCard(
                    'Total Billed',
                    '$_sym ${_fmt.format(_kpi.billed)}',
                    const Color(0xFF002E78),
                    Icons.receipt_long)),
                const SizedBox(width: 12),
                Expanded(child: _kpiCard(
                    'Total Collected',
                    '$_sym ${_fmt.format(_kpi.collected)}',
                    const Color(0xFF16A34A),
                    Icons.check_circle_outline)),
                const SizedBox(width: 12),
                Expanded(child: _kpiCard(
                    'Outstanding',
                    '$_sym ${_fmt.format(_kpi.outstanding)}',
                    const Color(0xFFDC2626),
                    Icons.schedule)),
                const SizedBox(width: 12),
                Expanded(child: _kpiCard(
                    'Avg Invoice Value',
                    '$_sym ${_fmt.format(_kpi.avgInvoiceValue)}',
                    const Color(0xFF7C3AED),
                    Icons.trending_up)),
              ],
            ),
          ),
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
                '${_kpiCard.runtimeType == _kpiCard.runtimeType ? '' : ''}${_fmtInt.format(_kpi.invoiceCount)} invoice${_kpi.invoiceCount == 1 ? '' : 's'} in period',
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

  Widget _buildBarChart() {
    final maxY = _trend
            .map((p) => p.billed > p.collected ? p.billed : p.collected)
            .fold(0.0, (a, b) => a > b ? a : b) *
        1.2;

    final groups = _trend.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: e.value.billed,
            color: const Color(0xFF3B82F6),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: e.value.collected,
            color: const Color(0xFF22C55E),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 100 : maxY,
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
                _fmtInt.format(value),
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF94A3B8)),
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
                  return Text(m,
                      style: const TextStyle(fontSize: 9));
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
                '$label\n$_sym ${_fmt.format(rod.toY)}',
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
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
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
                        _statusLegendRow(
                            const Color(0xFF22C55E),
                            'Paid',
                            _status.paid,
                            _status.total),
                        const SizedBox(height: 12),
                        _statusLegendRow(
                            const Color(0xFFF59E0B),
                            'Partial',
                            _status.partial,
                            _status.total),
                        const SizedBox(height: 12),
                        _statusLegendRow(
                            const Color(0xFFEF4444),
                            'Unpaid',
                            _status.unpaid,
                            _status.total),
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
                  onPageChange: (p) => setState(() => _agedPage = p),
                  onSizeChange: (s) => setState(() { _agedPageSize = s; _agedPage = 0; }),
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
    final pct =
        total == 0 ? '0' : (count / total * 100).toStringAsFixed(1);
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text('$label  ',
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF1E293B))),
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
    final (bucketLabel, bucketColor) = switch (d) {
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
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1E293B)),
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
              child: Text('$_sym ${_fmt.format(r.outstanding)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626)))),
          Expanded(
              flex: 2,
              child: Text('$d days',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569)))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    final totalTax =
        _taxBuckets.fold(0.0, (s, b) => s + b.taxCollected);
    final ts = DateTime.now().millisecondsSinceEpoch;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // Total tax KPI
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _kpiCard(
                    'Total Tax Collected',
                    '$_sym ${_fmt.format(totalTax)}',
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
              Expanded(child: const SizedBox.shrink()),
              const SizedBox(width: 12),
              Expanded(child: const SizedBox.shrink()),
            ],
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
                  'Tax Collected by Rate (GST)',
                  trailing: _exportBtn('Export CSV', () async {
                    final csv = ReportService.exportTaxCsv(_taxBuckets);
                    await _saveCsv(csv, 'tax_report_$ts.csv');
                  }),
                ),
              ),
              if (_taxBuckets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _emptyState(
                      'No taxable items in this period'),
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
              child: Text('$_sym ${_fmt.format(b.taxCollected)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF1E293B)))),
          Expanded(
              flex: 2,
              child: Text('$share%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B)))),
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
              child: Text('$_sym ${_fmt.format(total)}',
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
      child: Center(
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
                  'Top ${_topCustomers.length} Customers by Revenue',
                  trailing: _exportBtn('Export CSV', () async {
                    final csv = ReportService.exportTopCustomersCsv(
                        _topCustomers);
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
                // Horizontal bars
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: pct.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius:
                                            BorderRadius.circular(4),
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
                                '$_sym ${_fmt.format(c.collected)}',
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
                // Full table
                _customerTableHeader(),
                ..._topCustomers
                    .skip(_customersPage * _customersPageSize)
                    .take(_customersPageSize)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => _customerRow(_customersPage * _customersPageSize + e.key + 1, e.value)),
                _buildReportPagination(
                  currentPage: _customersPage,
                  pageSize: _customersPageSize,
                  total: _topCustomers.length,
                  onPageChange: (p) => setState(() => _customersPage = p),
                  onSizeChange: (s) => setState(() { _customersPageSize = s; _customersPage = 0; }),
                ),
              ],
            ],
          ),
        ),
      ],
          )))
    );
  }

  Widget _customerTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          SizedBox(width: 32, child: _TableHead('#')),
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
              width: 32,
              child: Text('$rank',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B8)))),
          Expanded(
              flex: 4,
              child: Text(c.name,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 1,
              child: Text('${c.invoiceCount}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(
              flex: 2,
              child: Text('$_sym ${_fmt.format(c.billed)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569)))),
          Expanded(
              flex: 2,
              child: Text('$_sym ${_fmt.format(c.collected)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A)))),
          Expanded(
              flex: 2,
              child: Text(
                  c.outstanding > 0
                      ? '$_sym ${_fmt.format(c.outstanding)}'
                      : '—',
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
      child: Center(
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
                  'Top ${_topProducts.length} Products / Services by Revenue',
                  trailing: _exportBtn('Export CSV', () async {
                    final csv =
                        ReportService.exportTopProductsCsv(_topProducts);
                    await _saveCsv(csv, 'top_products_$ts.csv');
                  }),
                ),
              ),
              if (_topProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _emptyState('No product data in this period'),
                )
              else ...[
                // Horizontal bars
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    children: _topProducts.take(5).map((p) {
                      final pct = p.revenue / maxRevenue;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: pct.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED),
                                        borderRadius:
                                            BorderRadius.circular(4),
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
                                '$_sym ${_fmt.format(p.revenue)}',
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
                    .map((e) => _productRow(_productsPage * _productsPageSize + e.key + 1, e.value)),
                _buildReportPagination(
                  currentPage: _productsPage,
                  pageSize: _productsPageSize,
                  total: _topProducts.length,
                  onPageChange: (p) => setState(() => _productsPage = p),
                  onSizeChange: (s) => setState(() { _productsPageSize = s; _productsPage = 0; }),
                ),
              ],
            ],
          ),
        ),
      ],
          )))
    );
  }

  Widget _productTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: const Row(
        children: [
          SizedBox(width: 32, child: _TableHead('#')),
          Expanded(flex: 4, child: _TableHead('Product / Service')),
          Expanded(flex: 2, child: _TableHead('Units Sold', right: true)),
          Expanded(flex: 2, child: _TableHead('Revenue', right: true)),
          Expanded(flex: 2, child: _TableHead('Discount Given', right: true)),
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
              width: 32,
              child: Text('$rank',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B8)))),
          Expanded(
              flex: 4,
              child: Text(p.name,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis)),
          Expanded(
              flex: 2,
              child: Text(_fmtInt.format(p.unitsSold),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(
              flex: 2,
              child: Text('$_sym ${_fmt.format(p.revenue)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C3AED)))),
          Expanded(
              flex: 2,
              child: Text(
                  p.discountGiven > 0
                      ? '$_sym ${_fmt.format(p.discountGiven)}'
                      : '—',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B)))),
        ],
      ),
    );
  }

  // ─── Section 6: Quotation Conversion ───────────────────────────────────────

  Widget _buildQuotations() {
    final q = _quotStats;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _kpiCard(
                  'Quotations Issued',
                  _fmtInt.format(q.quotationsIssued),
                  const Color(0xFF0284C7),
                  Icons.request_quote_outlined),
              _kpiCard(
                  'Invoices in Period',
                  _fmtInt.format(q.invoicesInPeriod),
                  const Color(0xFF16A34A),
                  Icons.receipt_outlined),
              _kpiCard(
                  'Conversion Rate',
                  '${q.conversionRate.toStringAsFixed(1)}%',
                  const Color(0xFF7C3AED),
                  Icons.trending_up),
            ],
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
          )))
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
