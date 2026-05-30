import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/domain/invoice_calculator.dart';

void main() {
  group('InvoiceCalculator', () {
    test('classifies unpaid partial and paid with money tolerance', () {
      expect(
        InvoiceCalculator.paymentStatus(total: 100, paid: 0),
        PaymentStatus.unpaid,
      );
      expect(
        InvoiceCalculator.paymentStatus(total: 100, paid: 40),
        PaymentStatus.partial,
      );
      expect(
        InvoiceCalculator.paymentStatus(total: 100, paid: 99.996),
        PaymentStatus.paid,
      );
    });

    test('clamps tiny outstanding balances to zero', () {
      expect(InvoiceCalculator.outstanding(total: 100, paid: 99.996), 0);
      expect(InvoiceCalculator.outstanding(total: 100, paid: 80), 20);
    });

    test('detects overdue only when there is balance past due date', () {
      final asOf = DateTime(2026, 5, 30, 15);

      expect(
        InvoiceCalculator.isOverdue(
          dueDate: DateTime(2026, 5, 29, 23),
          outstanding: 10,
          asOf: asOf,
        ),
        isTrue,
      );
      expect(
        InvoiceCalculator.isOverdue(
          dueDate: DateTime(2026, 5, 30),
          outstanding: 10,
          asOf: asOf,
        ),
        isFalse,
      );
      expect(
        InvoiceCalculator.isOverdue(
          dueDate: DateTime(2026, 5, 29),
          outstanding: 0,
          asOf: asOf,
        ),
        isFalse,
      );
    });

    test('returns positive days overdue only', () {
      final asOf = DateTime(2026, 5, 30, 15);

      expect(
        InvoiceCalculator.daysOverdue(
          dueDate: DateTime(2026, 5, 25),
          asOf: asOf,
        ),
        5,
      );
      expect(
        InvoiceCalculator.daysOverdue(
          dueDate: DateTime(2026, 5, 31),
          asOf: asOf,
        ),
        0,
      );
    });
  });
}
