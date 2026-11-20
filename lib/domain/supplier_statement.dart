import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/report_models.dart';

/// Supplier statement (PurchaseGstReportsPlan.md P4): one supplier's bills
/// and payments in [from]–[to] with a running payable balance. Reuses the
/// customer statement model: invoiced = billed. Supplier-ledger convention —
/// bill = credit (we owe more), payment = debit; balance = amount payable.
/// Drafts skipped. Pure.
class SupplierStatement {
  const SupplierStatement._();

  /// Key used to group bills by supplier (walk-in suppliers by name).
  static String keyOf(PurchaseBill b) => b.supplierId ?? 'name:${b.supplierName}';

  static CustomerStatement build(
    List<PurchaseBill> bills, {
    required String supplierKey,
    required DateTime from,
    required DateTime to,
    required String currencyCode,
    required String currencySymbol,
    DateTime? asOf,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day + 1);
    bool before(DateTime d) => d.isBefore(start);
    bool within(DateTime d) => !d.isBefore(start) && d.isBefore(end);

    final mine = [
      for (final b in bills)
        if (!b.isDraft && keyOf(b) == supplierKey) b,
    ];
    final drafts = <(DateTime, int, CustomerStatementLine)>[];
    double opening = 0, billed = 0, paid = 0, overdue = 0;
    CustomerStatementLine line(DateTime d, String type, String ref,
            String desc, {double debit = 0, double credit = 0}) =>
        CustomerStatementLine(
            date: d.toIso8601String(), type: type, reference: ref,
            description: desc, debit: debit, credit: credit, balance: 0);

    for (final b in mine) {
      final ref = (b.billNumber ?? '').isEmpty ? '—' : b.billNumber!;
      if (before(b.billDate)) {
        opening += b.total;
      } else if (within(b.billDate)) {
        billed += b.total;
        drafts.add((b.billDate, 0,
            line(b.billDate, 'Bill', ref, 'Purchase bill', credit: b.total)));
      }
      for (final p in b.payments) {
        if (before(p.datePaid)) {
          opening -= p.amountPaid;
        } else if (within(p.datePaid)) {
          paid += p.amountPaid;
          final method = p.paymentMethod ?? '';
          drafts.add((p.datePaid, 1, line(p.datePaid, 'Payment', ref,
              method.isEmpty ? 'Payment for $ref' : 'Payment for $ref ($method)',
              debit: p.amountPaid)));
        }
      }
      if (InvoiceCalculator.isOverdue(
          dueDate: b.dueDate, outstanding: b.outstandingBalance, asOf: asOf)) {
        overdue += b.outstandingBalance;
      }
    }

    drafts.sort((a, b) {
      final byDay = DateTime(a.$1.year, a.$1.month, a.$1.day)
          .compareTo(DateTime(b.$1.year, b.$1.month, b.$1.day));
      return byDay != 0 ? byDay : a.$2.compareTo(b.$2);
    });
    var running = opening;
    final lines = [
      for (final (_, _, l) in drafts)
        CustomerStatementLine(
          date: l.date, type: l.type, reference: l.reference,
          description: l.description, debit: l.debit, credit: l.credit,
          balance: running += l.credit - l.debit,
        ),
    ];
    return CustomerStatement(
      customerKey: supplierKey,
      customerName: mine.isEmpty ? '' : mine.first.supplierName,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      openingBalance: opening,
      invoiced: billed,
      paid: paid,
      closingBalance: running,
      overdueBalance: overdue,
      lines: lines,
    );
  }
}
