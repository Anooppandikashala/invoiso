import 'package:invoiso/common.dart';

class InvoiceCalculator {
  static const double moneyEpsilon = 0.005;

  const InvoiceCalculator._();

  static double outstanding({
    required double total,
    required double paid,
  }) {
    final balance = total - paid;
    return balance <= moneyEpsilon ? 0.0 : balance;
  }

  static bool isPaid({
    required double total,
    required double paid,
  }) =>
      outstanding(total: total, paid: paid) <= moneyEpsilon;

  static PaymentStatus paymentStatus({
    required double total,
    required double paid,
  }) {
    if (paid <= moneyEpsilon) return PaymentStatus.unpaid;
    return isPaid(total: total, paid: paid)
        ? PaymentStatus.paid
        : PaymentStatus.partial;
  }

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int daysOverdue({
    required DateTime? dueDate,
    DateTime? asOf,
  }) {
    if (dueDate == null) return 0;
    final today = dateOnly(asOf ?? DateTime.now());
    final due = dateOnly(dueDate);
    final days = today.difference(due).inDays;
    return days > 0 ? days : 0;
  }

  static bool isOverdue({
    required DateTime? dueDate,
    required double outstanding,
    DateTime? asOf,
  }) =>
      outstanding > moneyEpsilon &&
      daysOverdue(dueDate: dueDate, asOf: asOf) > 0;
}
