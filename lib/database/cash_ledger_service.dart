import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:invoiso/models/cash_ledger_entry.dart';
import 'package:invoiso/utils/app_date.dart';
import 'package:invoiso/utils/app_logger.dart';
import 'database_helper.dart';

const _tag = 'CashLedgerService';

/// Cash / UPI-Bank exchange ledger (CashUpiExchangeImplementationPlan.md).
class CashLedgerService {
  static final _dbHelper = DatabaseHelper();
  static const _uuid = Uuid();

  /// Invoice payment methods that land in the UPI/Bank account. 'Check' and
  /// 'Other' aren't money in hand until cleared, so they don't count.
  static const upiBankPaymentMethods = ['UPI', 'Bank Transfer', 'Online'];

  // ── Builders: the only place the delta rules live ──────────────────────

  /// UPI→Cash: UPI/Bank +amount, Cash −amount (Cash→UPI mirrors it). The fee
  /// is separate income and lands in whichever account it was paid through.
  static CashLedgerEntry buildExchange({
    required bool upiToCash,
    required double amount,
    required double fee,
    required String feeMethod,
    required DateTime dateTime,
    String? receiptNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? createdBy,
  }) {
    var cash = upiToCash ? -amount : amount;
    var upi = upiToCash ? amount : -amount;
    if (feeMethod == CashLedgerEntry.accountCash) {
      cash += fee;
    } else {
      upi += fee;
    }
    return CashLedgerEntry(
      id: _uuid.v4(),
      entryType:
          upiToCash ? CashLedgerEntry.upiToCash : CashLedgerEntry.cashToUpi,
      receiptNumber: receiptNumber,
      exchangeAmount: amount,
      serviceFee: fee,
      feeMethod: feeMethod,
      cashDelta: cash,
      upiDelta: upi,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      dateTime: dateTime,
      notes: notes,
      createdBy: createdBy,
    );
  }

  /// Expense / withdrawal: [amount] leaves [account]. Bank deposit: cash moves
  /// into UPI/Bank, so the total is unchanged.
  static CashLedgerEntry buildMovement({
    required String type,
    required double amount,
    String account = CashLedgerEntry.accountCash,
    required DateTime dateTime,
    String? notes,
    String? createdBy,
  }) {
    final isDeposit = type == CashLedgerEntry.bankDeposit;
    final fromCash = isDeposit || account == CashLedgerEntry.accountCash;
    return CashLedgerEntry(
      id: _uuid.v4(),
      entryType: type,
      cashDelta: fromCash ? -amount : 0,
      upiDelta: isDeposit ? amount : (fromCash ? 0 : -amount),
      dateTime: dateTime,
      notes: notes,
      createdBy: createdBy,
    );
  }

  // ── Writes ────────────────────────────────────────────────────────────────

  static Future<CashLedgerEntry> addExchange({
    required bool upiToCash,
    required double amount,
    required double fee,
    required String feeMethod,
    required DateTime dateTime,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? createdBy,
  }) async {
    final db = await _dbHelper.database;
    late CashLedgerEntry saved;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
          'SELECT receipt_number FROM cash_ledger WHERE receipt_number IS NOT NULL');
      var max = 0;
      for (final r in rows) {
        final n = int.tryParse(
                (r['receipt_number'] as String).replaceAll(RegExp(r'\D'), '')) ??
            0;
        if (n > max) max = n;
      }
      saved = buildExchange(
        upiToCash: upiToCash,
        amount: amount,
        fee: fee,
        feeMethod: feeMethod,
        dateTime: dateTime,
        receiptNumber: 'EXC-${(max + 1).toString().padLeft(4, '0')}',
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        createdBy: createdBy,
      );
      await txn.insert('cash_ledger', saved.toMap());
    });
    AppLogger.d(_tag, 'Exchange added: ${saved.receiptNumber}');
    return saved;
  }

  static Future<CashLedgerEntry> addMovement({
    required String type,
    required double amount,
    String account = CashLedgerEntry.accountCash,
    required DateTime dateTime,
    String? notes,
    String? createdBy,
  }) async {
    final entry = buildMovement(
      type: type,
      amount: amount,
      account: account,
      dateTime: dateTime,
      notes: notes,
      createdBy: createdBy,
    );
    await (await _dbHelper.database).insert('cash_ledger', entry.toMap());
    return entry;
  }

  /// Signed correction entered directly by an admin.
  static Future<CashLedgerEntry> addAdjustment({
    double cashDelta = 0,
    double upiDelta = 0,
    required DateTime dateTime,
    String? notes,
    String? createdBy,
  }) async {
    final entry = CashLedgerEntry(
      id: _uuid.v4(),
      entryType: CashLedgerEntry.adjustment,
      cashDelta: cashDelta,
      upiDelta: upiDelta,
      dateTime: dateTime,
      notes: notes,
      createdBy: createdBy,
    );
    await (await _dbHelper.database).insert('cash_ledger', entry.toMap());
    return entry;
  }

  /// At most one opening row: first save inserts it, later saves update it.
  static Future<void> saveOpening({
    required double cash,
    required double upiBank,
    required DateTime date,
    String? createdBy,
  }) async {
    final db = await _dbHelper.database;
    final existing = await getOpening();
    final entry = CashLedgerEntry(
      id: existing?.id ?? _uuid.v4(),
      entryType: CashLedgerEntry.opening,
      cashDelta: cash,
      upiDelta: upiBank,
      dateTime: date,
      createdBy: createdBy,
    );
    await db.insert('cash_ledger', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteEntry(String id) async {
    await (await _dbHelper.database)
        .delete('cash_ledger', where: 'id = ?', whereArgs: [id]);
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  static Future<CashLedgerEntry?> getOpening() async {
    final rows = await (await _dbHelper.database).query('cash_ledger',
        where: 'entry_type = ?', whereArgs: [CashLedgerEntry.opening], limit: 1);
    return rows.isEmpty ? null : CashLedgerEntry.fromMap(rows.first);
  }

  /// One page of history, newest first. [from]/[to] are inclusive; [type]
  /// filters entry_type. [paymentsFrom] is the opening-balance date
  /// (`CashBalances.trackingStart`): invoice payments are listed from then
  /// on, and not at all when it's null.
  static Future<List<CashLedgerEntry>> getEntries({
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
    int limit = 25,
    int offset = 0,
  }) async =>
      entriesOn(await _dbHelper.database,
          from: from,
          to: to,
          type: type,
          paymentsFrom: paymentsFrom,
          limit: limit,
          offset: offset);

  /// Total rows [getEntries] would page through with the same filters.
  static Future<int> countEntries({
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
  }) async =>
      countEntriesOn(await _dbHelper.database,
          from: from, to: to, type: type, paymentsFrom: paymentsFrom);

  /// The two history sources with every filter applied inside each branch,
  /// so each can use its date index (cash_ledger.date_time,
  /// invoice_payments.date_paid); a branch the type filter excludes is
  /// dropped. Invoice payments follow the same rules as [balancesOn].
  static ({String? ledger, String? payments, List<Object?> ledgerArgs,
      List<Object?> paymentArgs}) _historyParts(
      DateTime? from, DateTime? to, String? type, DateTime? paymentsFrom) {
    String? ledger;
    final ledgerArgs = <Object?>[];
    if (type != CashLedgerEntry.invoicePayment) {
      final where = <String>[];
      if (from != null) {
        where.add('date_time >= ?');
        ledgerArgs.add(from.toIso8601String());
      }
      if (to != null) {
        where.add('date_time <= ?');
        ledgerArgs.add(to.toIso8601String());
      }
      if (type != null) {
        where.add('entry_type = ?');
        ledgerArgs.add(type);
      }
      ledger = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    }

    String? payments;
    final paymentArgs = <Object?>[];
    if (paymentsFrom != null &&
        (type == null || type == CashLedgerEntry.invoicePayment)) {
      final start = from == null || from.isBefore(paymentsFrom)
          ? paymentsFrom
          : from;
      final marks = upiBankPaymentMethods.map((_) => '?').join(', ');
      payments = 'FROM invoice_payments p JOIN invoices i ON i.id = p.invoice_id '
          'WHERE i.deleted_at IS NULL AND p.date_paid >= ? '
          "${to == null ? '' : 'AND p.date_paid <= ? '}"
          "AND p.payment_method IN ('Cash', $marks)";
      paymentArgs
        ..add(AppDate.dateKey(start))
        ..addAll([if (to != null) AppDate.dateKey(to)])
        ..addAll(upiBankPaymentMethods);
    }
    return (
      ledger: ledger,
      payments: payments,
      ledgerArgs: ledgerArgs,
      paymentArgs: paymentArgs
    );
  }

  /// Ledger rows plus counted invoice payments as read-only
  /// [CashLedgerEntry.invoicePayment] rows. Payments have no time of day, so
  /// they sort at 00:00 of their date.
  @visibleForTesting
  static Future<List<CashLedgerEntry>> entriesOn(
    DatabaseExecutor db, {
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
    int limit = 25,
    int offset = 0,
  }) async {
    final h = _historyParts(from, to, type, paymentsFrom);
    final branches = <String>[
      if (h.ledger != null)
        'SELECT id, entry_type, receipt_number, exchange_amount, '
            'service_fee, fee_method, cash_delta, upi_delta, customer_id, '
            'customer_name, customer_phone, date_time, notes, created_by '
            'FROM cash_ledger${h.ledger}',
      // Aliased so the columns are named when this branch runs alone.
      if (h.payments != null)
        "SELECT p.id AS id, '${CashLedgerEntry.invoicePayment}' AS entry_type, "
            'p.receipt_number AS receipt_number, '
            'p.amount_paid AS exchange_amount, 0 AS service_fee, '
            'p.payment_method AS fee_method, '
            "CASE WHEN p.payment_method = 'Cash' THEN p.amount_paid ELSE 0 END "
            'AS cash_delta, '
            "CASE WHEN p.payment_method = 'Cash' THEN 0 ELSE p.amount_paid END "
            'AS upi_delta, '
            'i.customer_id AS customer_id, i.customer_name AS customer_name, '
            'NULL AS customer_phone, '
            "p.date_paid || 'T00:00:00.000' AS date_time, "
            'p.invoice_number AS notes, NULL AS created_by '
            '${h.payments}',
    ];
    if (branches.isEmpty) return [];
    final rows = await db.rawQuery(
      '${branches.join(' UNION ALL ')} '
      'ORDER BY date_time DESC LIMIT ? OFFSET ?',
      [...h.ledgerArgs, ...h.paymentArgs, limit, offset],
    );
    return rows.map(CashLedgerEntry.fromMap).toList();
  }

  @visibleForTesting
  static Future<int> countEntriesOn(
    DatabaseExecutor db, {
    DateTime? from,
    DateTime? to,
    String? type,
    DateTime? paymentsFrom,
  }) async {
    final h = _historyParts(from, to, type, paymentsFrom);
    final parts = <String>[
      if (h.ledger != null) '(SELECT COUNT(*) FROM cash_ledger${h.ledger})',
      if (h.payments != null) '(SELECT COUNT(*) ${h.payments})',
    ];
    if (parts.isEmpty) return 0;
    final r = await db.rawQuery('SELECT ${parts.join(' + ')} AS n',
        [...h.ledgerArgs, ...h.paymentArgs]);
    return (r.first['n'] as num).toInt();
  }

  /// Current balances, or as at [before] (a day boundary, exclusive) for a
  /// period's opening / closing balance.
  static Future<CashBalances> getBalances({DateTime? before}) async =>
      balancesOn(await _dbHelper.database, before: before);

  static Future<CashPeriodTotals> getPeriodTotals(
          DateTime from, DateTime to) async =>
      periodTotalsOn(await _dbHelper.database, from, to);

  /// Ledger sums plus invoice payments (non-deleted invoices) dated on or
  /// after the opening-balance date. Before an opening balance is set,
  /// invoice payments aren't counted. [before] (a day boundary) limits both
  /// to rows dated earlier; payments, stored by date, count from 00:00.
  @visibleForTesting
  static Future<CashBalances> balancesOn(DatabaseExecutor db,
      {DateTime? before}) async {
    final sums = (await db.rawQuery(
      'SELECT COALESCE(SUM(cash_delta), 0) AS cash, '
      'COALESCE(SUM(upi_delta), 0) AS upi FROM cash_ledger'
      '${before == null ? '' : ' WHERE date_time < ?'}',
      [if (before != null) before.toIso8601String()],
    ))
        .first;
    var cash = (sums['cash'] as num).toDouble();
    var upi = (sums['upi'] as num).toDouble();

    final openingRows = await db.query('cash_ledger',
        columns: ['date_time'],
        where: 'entry_type = ?',
        whereArgs: [CashLedgerEntry.opening],
        limit: 1);
    DateTime? start;
    if (openingRows.isNotEmpty) {
      start = DateTime.parse(openingRows.first['date_time'] as String);
      final marks = upiBankPaymentMethods.map((_) => '?').join(', ');
      final pay = (await db.rawQuery(
        "SELECT COALESCE(SUM(CASE WHEN payment_method = 'Cash' THEN amount_paid END), 0) AS cash, "
        'COALESCE(SUM(CASE WHEN payment_method IN ($marks) THEN amount_paid END), 0) AS upi '
        'FROM invoice_payments WHERE date_paid >= ? '
        "${before == null ? '' : 'AND date_paid < ? '}"
        'AND invoice_id IN (SELECT id FROM invoices WHERE deleted_at IS NULL)',
        [
          ...upiBankPaymentMethods,
          AppDate.dateKey(start),
          if (before != null) AppDate.dateKey(before),
        ],
      ))
          .first;
      cash += (pay['cash'] as num).toDouble();
      upi += (pay['upi'] as num).toDouble();
    }
    return (cash: cash, upiBank: upi, trackingStart: start);
  }

  @visibleForTesting
  static Future<CashPeriodTotals> periodTotalsOn(
      DatabaseExecutor db, DateTime from, DateTime to) async {
    final r = (await db.rawQuery(
      'SELECT COALESCE(SUM(service_fee), 0) AS income, '
      "COALESCE(SUM(CASE WHEN entry_type = 'expense' THEN -(cash_delta + upi_delta) END), 0) AS expenses "
      'FROM cash_ledger WHERE date_time >= ? AND date_time <= ?',
      [from.toIso8601String(), to.toIso8601String()],
    ))
        .first;
    return (
      serviceIncome: (r['income'] as num).toDouble(),
      expenses: (r['expenses'] as num).toDouble(),
    );
  }
}
