import 'package:uuid/uuid.dart';

import 'package:invoiso/domain/purchase_bill_calculator.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/supplier_payment.dart';
import 'package:invoiso/utils/app_logger.dart';
import 'database_helper.dart';

const _tag = 'SupplierPaymentService';

class SupplierPaymentService {
  static final _dbHelper = DatabaseHelper();
  static const _uuid = Uuid();

  // ─────────────────────────────────────────────
  // Add a payment — snapshot fields computed inside a transaction.
  // Returns the fully populated SupplierPayment that was persisted.
  static Future<SupplierPayment> addPayment({
    required PurchaseBill bill,
    required double amountPaid,
    required DateTime datePaid,
    String? paymentMethod,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    late SupplierPayment saved;

    await db.transaction((txn) async {
      final sumResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount_paid), 0.0) AS total FROM supplier_payments WHERE bill_id = ?',
        [bill.id],
      );
      final previouslyPaid = (sumResult.first['total'] as num).toDouble();

      final balanceAfter = PurchaseBillCalculator.outstanding(
        total: bill.total,
        paid: previouslyPaid + amountPaid,
      );

      saved = SupplierPayment(
        id: _uuid.v4(),
        billId: bill.id,
        supplierId: bill.supplierId,
        amountPaid: amountPaid,
        previouslyPaid: previouslyPaid,
        balanceAfter: balanceAfter,
        datePaid: datePaid,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      await txn.insert('supplier_payments', saved.toMap());
      AppLogger.d(_tag, 'Payment added for bill ${bill.id} — ₹$amountPaid');
    });

    return saved;
  }

  // ─────────────────────────────────────────────
  // Fetch all payments for a bill, oldest first
  static Future<List<SupplierPayment>> getPaymentsForBill(String billId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'supplier_payments',
      where: 'bill_id = ?',
      whereArgs: [billId],
      orderBy: 'date_paid ASC, rowid ASC',
    );
    return rows.map(SupplierPayment.fromMap).toList();
  }

  // ─────────────────────────────────────────────
  // Aggregate: total amount paid for a bill
  static Future<double> getTotalPaidForBill(String billId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_paid), 0.0) AS total FROM supplier_payments WHERE bill_id = ?',
      [billId],
    );
    return (result.first['total'] as num).toDouble();
  }

  // ─────────────────────────────────────────────
  // Batch fetch: map of billId → totalPaid for a list of bill IDs.
  // Used by the list view to avoid N+1 queries.
  static Future<Map<String, double>> getTotalPaidBatch(
      List<String> billIds) async {
    if (billIds.isEmpty) return {};
    final db = await _dbHelper.database;
    final placeholders = List.filled(billIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT bill_id, COALESCE(SUM(amount_paid), 0.0) AS total '
      'FROM supplier_payments '
      'WHERE bill_id IN ($placeholders) '
      'GROUP BY bill_id',
      billIds,
    );
    return {
      for (final row in rows)
        row['bill_id'] as String: (row['total'] as num).toDouble()
    };
  }

  // ─────────────────────────────────────────────
  // Delete a single payment (admin action — hard delete)
  static Future<void> deletePayment(String paymentId) async {
    final db = await _dbHelper.database;
    await db
        .delete('supplier_payments', where: 'id = ?', whereArgs: [paymentId]);
    AppLogger.d(_tag, 'Payment deleted: $paymentId');
  }
}
