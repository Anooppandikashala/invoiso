import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/report_models.dart';

/// Accounts payable aging (PurchaseGstReportsPlan.md P3): unpaid purchase
/// bills by days past due, as of [asOf] — same buckets as aged receivables.
/// Reuses the receivable row models: customerName = supplier,
/// invoiceId = bill number. Drafts and fully paid bills skipped. Pure.
class PayablesAging {
  const PayablesAging._();

  static ({List<AgedReceivable> detail, List<AgedReceivableSummaryRow> summary})
      build(List<PurchaseBill> bills, {DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final detail = <AgedReceivable>[];
    // Per supplier: [current, 1-30, 31-60, 61-90, 90+, noDueDate]
    final buckets = <String, List<double>>{};
    final names = <String, String>{};

    for (final b in bills) {
      if (b.isDraft) continue;
      final owed = b.outstandingBalance;
      if (owed <= InvoiceCalculator.moneyEpsilon) continue;
      final d = InvoiceCalculator.daysOverdue(dueDate: b.dueDate, asOf: now);
      detail.add(AgedReceivable(
        invoiceId: (b.billNumber ?? '').isEmpty ? '—' : b.billNumber!,
        customerName: b.supplierName,
        outstanding: owed,
        daysOverdue: d,
        hasNoDueDate: b.dueDate == null,
      ));
      final key = b.supplierId ?? b.supplierName;
      names[key] = b.supplierName;
      final s = buckets.putIfAbsent(key, () => <double>[0, 0, 0, 0, 0, 0]);
      final idx = b.dueDate == null
          ? 5
          : d == 0
              ? 0
              : d <= 30
                  ? 1
                  : d <= 60
                      ? 2
                      : d <= 90
                          ? 3
                          : 4;
      s[idx] += owed;
    }

    detail.sort((a, b) {
      if (a.hasNoDueDate != b.hasNoDueDate) return a.hasNoDueDate ? 1 : -1;
      return b.daysOverdue.compareTo(a.daysOverdue);
    });
    final summary = [
      for (final e in buckets.entries)
        AgedReceivableSummaryRow(
          customerName: names[e.key] ?? e.key,
          current: e.value[0],
          d0to30: e.value[1],
          d31to60: e.value[2],
          d61to90: e.value[3],
          d90plus: e.value[4],
          noDueDate: e.value[5],
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
    return (detail: detail, summary: summary);
  }
}
