// Daily Report with the Cash/UPI exchange feature
// (CashUpiExchangeImplementationPlan.md Phase 12): merging ledger days into the
// invoice days, invoice / cash-exchange lines per day, and the CSV columns.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/models/report_models.dart';

void main() {
  final rows = ReportService.mergeDailyCashUpi(
    [
      const DailyPoint(date: '2026-09-24', invoiceCount: 2, billed: 500, cogs: 300),
      const DailyPoint(date: '2026-09-26', invoiceCount: 1, billed: 100),
    ],
    {
      // exchange only: 1000 UPI→Cash, 10 fee in cash
      '2026-09-25': (cash: -990.0, upiBank: 1000.0, payCash: 0.0, payUpi: 0.0,
          fee: 10.0, exchanges: 1),
      // invoice payment only
      '2026-09-26': (cash: 0.0, upiBank: 0.0, payCash: 150.0, payUpi: 0.0,
          fee: 0.0, exchanges: 0),
    },
  );

  test('merge: union of invoice and ledger days, sorted, 0 where missing', () {
    expect(rows.map((d) => d.date), ['2026-09-24', '2026-09-25', '2026-09-26']);
    expect([rows[0].invoiceCount, rows[0].billed, rows[0].profit, rows[0].cash],
        [2, 500, 200, 0]);
    expect([rows[1].invoiceCount, rows[1].billed, rows[1].cash, rows[1].upiBank],
        [0, 0, -990, 1000]);
    // Service fee counts in total profit; the exchanged amount never does.
    expect([
      rows[1].exchangeCount,
      rows[1].serviceIncome,
      rows[1].profit,
      rows[1].totalProfit
    ], [1, 10, 0, 10]);
    expect(rows[0].totalProfit, 200);
    expect([rows[2].billed, rows[2].paidCash, rows[2].cash], [100, 150, 0]);
  });

  test('lines: one per activity type, filtered', () {
    String key(DailyLine l) => '${l.d.date}${l.exchange ? ' ex' : ''}';
    expect(ReportService.dailyLines(rows, exchanges: true).map(key),
        ['2026-09-24', '2026-09-25 ex', '2026-09-26']);
    expect(ReportService.dailyLines(rows).map(key),
        ['2026-09-24', '2026-09-26']);
    expect(ReportService.dailyLines(rows, invoices: false, exchanges: true)
        .map(key), ['2026-09-25 ex']);
  });

  test('CSV: Type and Cash / UPI-Bank columns only when asked', () {
    final lines = ReportService.dailyLines(rows, exchanges: true);
    final off = ReportService.exportDailyReportCsv(
            ReportService.dailyLines(rows))
        .split('\n');
    expect(off.first, isNot(contains('Cash')));
    final on =
        ReportService.exportDailyReportCsv(lines, cashUpi: true).split('\n');
    expect(on.first, startsWith('"Date","Type","Count"'));
    expect(on.first, endsWith('"Cash","UPI/Bank"'));
    // Exchange line: profit = fee, no sales / COGS / margin.
    expect(on[2],
        '"2026-09-25","Cash exchange","1","","","10.00","","-990.00","1000.00"');
    // Invoice line: Cash / UPI-Bank = payments received.
    expect(on[3], endsWith('"150.00","0.00"'));
  });
}
