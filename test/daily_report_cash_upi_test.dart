// Daily Report net Cash / UPI-Bank columns (CashUpiExchangeImplementationPlan.md
// Phase 12): merging ledger days into the invoice days, and the CSV columns.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/database/report_service.dart';
import 'package:invoiso/models/report_models.dart';

void main() {
  test('merge: union of invoice and ledger days, sorted, 0 where missing', () {
    final rows = ReportService.mergeDailyCashUpi(
      [
        const DailyPoint(date: '2026-09-24', invoiceCount: 2, billed: 500, cogs: 300),
        const DailyPoint(date: '2026-09-26', invoiceCount: 1, billed: 100),
      ],
      {
        '2026-09-25': (cash: -990.0, upiBank: 1000.0), // exchanges only
        '2026-09-26': (cash: 150.0, upiBank: 0.0),
      },
    );
    expect(rows.map((d) => d.date), ['2026-09-24', '2026-09-25', '2026-09-26']);
    expect([rows[0].invoiceCount, rows[0].billed, rows[0].profit, rows[0].cash],
        [2, 500, 200, 0]);
    expect([rows[1].invoiceCount, rows[1].billed, rows[1].cash, rows[1].upiBank],
        [0, 0, -990, 1000]);
    expect([rows[2].billed, rows[2].cash], [100, 150]);
  });

  test('CSV: Cash and UPI/Bank columns only when asked', () {
    const rows = [
      DailyPoint(date: '2026-09-25', invoiceCount: 0, billed: 0, cash: -990, upiBank: 1000),
    ];
    final off = ReportService.exportDailyReportCsv(rows).split('\n');
    expect(off.first, isNot(contains('Cash')));
    final on = ReportService.exportDailyReportCsv(rows, cashUpi: true).split('\n');
    expect(on.first, endsWith('"Cash","UPI/Bank"'));
    expect(on[1], endsWith('"-990.00","1000.00"'));
  });
}
