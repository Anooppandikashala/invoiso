import 'package:uuid/uuid.dart';

import '../domain/invoice_calculator.dart';
import '../domain/payment_receipt_numbers.dart';
import '../models/invoice.dart';
import '../models/invoice_payment.dart';
import '../utils/app_date.dart';
import '../utils/app_logger.dart';
import 'database_helper.dart';

const _tag = 'PaymentService';

class PaymentService {
  static final _dbHelper = DatabaseHelper();
  static const _uuid = Uuid();

  // ─────────────────────────────────────────────
  // Add a payment — all snapshot fields computed inside a transaction.
  // Returns the fully populated InvoicePayment that was persisted.
  static Future<InvoicePayment> addPayment({
    required Invoice invoice,
    required double amountPaid,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    late InvoicePayment saved;

    await db.transaction((txn) async {
      // 1. Snapshot: total already paid before this installment
      final sumResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount_paid), 0.0) AS total FROM invoice_payments WHERE invoice_id = ?',
        [invoice.id],
      );
      final previouslyPaid = (sumResult.first['total'] as num).toDouble();

      // 2. Determine next receipt suffix using MAX to avoid reuse after deletions
      final suffixResult = await txn.rawQuery(
        'SELECT receipt_number FROM invoice_payments WHERE invoice_id = ?',
        [invoice.id],
      );
      final receiptNumber = PaymentReceiptNumbers.nextReceiptNumber(
        invoiceId: invoice.id,
        existingReceiptNumbers:
            suffixResult.map((row) => row['receipt_number'] as String?),
      );

      // 3. Compute tax portion proportionally
      final taxAmountPaid = invoice.total > 0
          ? (amountPaid * (invoice.tax / invoice.total))
          : 0.0;

      // 4. Snapshot: balance remaining after this installment
      final balanceAfter = InvoiceCalculator.outstanding(
        total: invoice.total,
        paid: previouslyPaid + amountPaid,
      );

      saved = InvoicePayment(
        id: _uuid.v4(),
        invoiceId: invoice.id,
        invoiceNumber: invoice.invoiceNumber ?? invoice.id,
        receiptNumber: receiptNumber,
        amountPaid: amountPaid,
        taxAmountPaid: taxAmountPaid,
        previouslyPaid: previouslyPaid,
        balanceAfter: balanceAfter,
        datePaid: datePaid,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      await txn.insert('invoice_payments', saved.toMap());
      AppLogger.d(_tag, 'Payment added: ${saved.receiptNumber} — ₹$amountPaid');
    });

    return saved;
  }

  // ─────────────────────────────────────────────
  // Batch mark-as-paid: single DB transaction for N invoices.
  // Skips invoices that are already paid within the standard money tolerance.
  static Future<int> addPaymentBatch({
    required List<Invoice> invoices,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final invoice in invoices) {
        final amountPaid = invoice.outstandingBalance;
        if (amountPaid <= InvoiceCalculator.moneyEpsilon) continue;

        final suffixResult = await txn.rawQuery(
          'SELECT receipt_number FROM invoice_payments WHERE invoice_id = ?',
          [invoice.id],
        );
        final receiptNumber = PaymentReceiptNumbers.nextReceiptNumber(
          invoiceId: invoice.id,
          existingReceiptNumbers:
              suffixResult.map((row) => row['receipt_number'] as String?),
        );

        final taxAmountPaid = invoice.total > 0
            ? (amountPaid * (invoice.tax / invoice.total))
            : 0.0;

        final payment = InvoicePayment(
          id: _uuid.v4(),
          invoiceId: invoice.id,
          invoiceNumber: invoice.invoiceNumber ?? invoice.id,
          receiptNumber: receiptNumber,
          amountPaid: amountPaid,
          taxAmountPaid: taxAmountPaid,
          previouslyPaid: invoice.amountPaid,
          balanceAfter: 0.0,
          datePaid: datePaid,
          paymentMethod: paymentMethod,
          notes: notes,
        );

        await txn.insert('invoice_payments', payment.toMap());
        count++;
      }
    });
    AppLogger.d(_tag, 'Batch payment: $count invoice(s) marked as paid.');
    return count;
  }

  // ─────────────────────────────────────────────
  // Fetch all payments for an invoice, oldest first
  static Future<List<InvoicePayment>> getPaymentsForInvoice(
      String invoiceId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'invoice_payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'date_paid ASC, rowid ASC',
    );
    return rows.map(InvoicePayment.fromMap).toList();
  }

  // ─────────────────────────────────────────────
  // Aggregate: total amount paid for an invoice
  static Future<double> getTotalPaidForInvoice(String invoiceId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_paid), 0.0) AS total FROM invoice_payments WHERE invoice_id = ?',
      [invoiceId],
    );
    return (result.first['total'] as num).toDouble();
  }

  // ─────────────────────────────────────────────
  // Batch fetch: map of invoiceId → totalPaid for a list of invoice IDs.
  // Used by the list view to avoid N+1 queries.
  static Future<Map<String, double>> getTotalPaidBatch(
      List<String> invoiceIds) async {
    if (invoiceIds.isEmpty) return {};
    final db = await _dbHelper.database;
    final placeholders = List.filled(invoiceIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT invoice_id, COALESCE(SUM(amount_paid), 0.0) AS total '
      'FROM invoice_payments '
      'WHERE invoice_id IN ($placeholders) '
      'GROUP BY invoice_id',
      invoiceIds,
    );
    return {
      for (final row in rows)
        row['invoice_id'] as String: (row['total'] as num).toDouble()
    };
  }

  // ─────────────────────────────────────────────
  // Delete a single payment (admin action — hard delete)
  static Future<void> deletePayment(String paymentId) async {
    final db = await _dbHelper.database;
    await db
        .delete('invoice_payments', where: 'id = ?', whereArgs: [paymentId]);
    AppLogger.d(_tag, 'Payment deleted: $paymentId');
  }

  // ─────────────────────────────────────────────
  // Reporting: all payments in a date range
  static Future<List<InvoicePayment>> getAllPaymentsBetween(
      DateTime from, DateTime to) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'invoice_payments',
      where: 'date_paid >= ? AND date_paid <= ?',
      whereArgs: [
        AppDate.dateKey(from),
        AppDate.dateKey(to),
      ],
      orderBy: 'date_paid ASC',
    );
    return rows.map(InvoicePayment.fromMap).toList();
  }

  // Reporting: total tax collected in a date range
  static Future<double> getTaxPaidBetween(DateTime from, DateTime to) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(tax_amount_paid), 0.0) AS total '
      'FROM invoice_payments '
      'WHERE date_paid >= ? AND date_paid <= ?',
      [
        AppDate.dateKey(from),
        AppDate.dateKey(to),
      ],
    );
    return (result.first['total'] as num).toDouble();
  }
}
