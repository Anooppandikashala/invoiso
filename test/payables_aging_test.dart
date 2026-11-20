// Payables aging (PurchaseGstReportsPlan.md P3): buckets by due date, partial
// payments, no due date, drafts / paid bills skipped, reverse charge owes no
// tax to the supplier. Pure.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/domain/payables_aging.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/models/supplier_payment.dart';

final _today = DateTime(2026, 11, 20);

PurchaseBill _bill(String id, double cost,
        {String supplier = 'Kumar', DateTime? due, double paid = 0,
        bool draft = false, bool rcm = false}) =>
    PurchaseBill(
      id: id,
      billNumber: 'B-$id',
      supplierId: supplier,
      supplierName: supplier,
      billDate: DateTime(2026, 9, 1),
      dueDate: due,
      isDraft: draft,
      reverseCharge: rcm,
      items: [
        PurchaseBillItem(
            productName: 'X', quantity: 1, costPerUnit: cost, taxRate: 0)
      ],
      payments: [
        if (paid > 0)
          SupplierPayment(id: 'p$id', billId: id, amountPaid: paid,
              previouslyPaid: 0, balanceAfter: cost - paid,
              datePaid: DateTime(2026, 9, 2)),
      ],
    );

void main() {
  test('buckets by days past due; partial payment, no due date, skips', () {
    final r = PayablesAging.build([
      _bill('1', 100, due: DateTime(2026, 11, 25)), // not due → current
      _bill('2', 200, due: DateTime(2026, 11, 10), paid: 50), // 10 days → 150
      _bill('3', 300, due: DateTime(2026, 8, 1)), // 111 days → 90+
      _bill('4', 400), // no due date
      _bill('5', 500, due: DateTime(2026, 10, 1), supplier: 'Ravi'), // 50 → 31-60
      _bill('6', 600, due: DateTime(2026, 10, 1), paid: 600), // paid → skip
      _bill('7', 700, due: DateTime(2026, 10, 1), draft: true), // draft → skip
    ], asOf: _today);

    expect(r.detail.map((x) => x.invoiceId), ['B-3', 'B-5', 'B-2', 'B-1', 'B-4']);
    expect(r.detail[2].outstanding, 150);
    expect(r.detail[2].daysOverdue, 10);
    expect(r.detail.last.hasNoDueDate, isTrue);

    final kumar = r.summary.firstWhere((x) => x.customerName == 'Kumar');
    expect([kumar.current, kumar.d0to30, kumar.d31to60, kumar.d90plus, kumar.noDueDate],
        [100, 150, 0, 300, 400]);
    expect(kumar.total, 950);
    expect(r.summary.first.customerName, 'Kumar'); // largest total first
    expect(r.summary.last.d31to60, 500);
  });

  test('reverse-charge bill: only the bill value is owed to the supplier', () {
    final bill = PurchaseBill(
      id: 'r', supplierName: 'GTA', billDate: DateTime(2026, 11, 1),
      dueDate: DateTime(2026, 11, 15), reverseCharge: true,
      items: [PurchaseBillItem(
          productName: 'Freight', quantity: 1, costPerUnit: 1000, taxRate: 5)],
    );
    final r = PayablesAging.build([bill], asOf: _today);
    expect(r.detail.single.outstanding, 1000);
    expect(r.detail.single.invoiceId, '—'); // no bill number
  });
}
