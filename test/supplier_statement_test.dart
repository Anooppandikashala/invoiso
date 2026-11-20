// Supplier statement (PurchaseGstReportsPlan.md P4): opening balance from
// earlier bills / payments, bills as credit, payments as debit, running
// payable balance, overdue as of today, other suppliers and drafts skipped.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/domain/supplier_statement.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/models/supplier_payment.dart';

PurchaseBill _bill(String id, double cost, DateTime date,
        {String supplier = 's1', DateTime? due, bool draft = false,
        List<(double, DateTime)> payments = const []}) =>
    PurchaseBill(
      id: id,
      billNumber: 'B-$id',
      supplierId: supplier,
      supplierName: 'Supplier $supplier',
      billDate: date,
      dueDate: due,
      isDraft: draft,
      items: [
        PurchaseBillItem(
            productName: 'X', quantity: 1, costPerUnit: cost, taxRate: 0)
      ],
      payments: [
        for (final (i, (amt, d)) in payments.indexed)
          SupplierPayment(id: '$id-$i', billId: id, amountPaid: amt,
              previouslyPaid: 0, balanceAfter: 0, datePaid: d,
              paymentMethod: 'UPI'),
      ],
    );

void main() {
  test('opening, bills credit, payments debit, running balance, overdue', () {
    final bills = [
      _bill('1', 1000, DateTime(2026, 10, 5),
          payments: [(400, DateTime(2026, 10, 20)), (100, DateTime(2026, 11, 3))]),
      _bill('2', 500, DateTime(2026, 11, 10), due: DateTime(2026, 11, 15)),
      _bill('3', 300, DateTime(2026, 11, 12), supplier: 's2'), // other supplier
      _bill('4', 999, DateTime(2026, 11, 12), draft: true), // draft
    ];
    final st = SupplierStatement.build(bills,
        supplierKey: 's1',
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 30),
        currencyCode: 'INR',
        currencySymbol: 'Rs.',
        asOf: DateTime(2026, 11, 20));

    expect(st.customerName, 'Supplier s1');
    expect(st.openingBalance, 600); // 1000 − 400 paid in October
    expect([st.invoiced, st.paid], [500, 100]);
    expect(st.lines.map((l) => (l.type, l.debit, l.credit, l.balance)), [
      ('Payment', 100, 0, 500),
      ('Bill', 0, 500, 1000),
    ]);
    expect(st.lines.first.description, 'Payment for B-1 (UPI)');
    expect(st.closingBalance, 1000);
    expect(st.overdueBalance, 500); // bill 2 due 15 Nov, unpaid
  });

  test('walk-in supplier (no id) grouped by name', () {
    final b = PurchaseBill(
        id: 'w', supplierName: 'Local Shop', billDate: DateTime(2026, 11, 2),
        items: [PurchaseBillItem(
            productName: 'X', quantity: 1, costPerUnit: 50, taxRate: 0)]);
    final key = SupplierStatement.keyOf(b);
    final st = SupplierStatement.build([b],
        supplierKey: key, from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 30),
        currencyCode: 'INR', currencySymbol: 'Rs.');
    expect([st.customerName, st.closingBalance], ['Local Shop', 50]);
  });
}
