// Cash / UPI-Bank ledger rules (CashUpiExchangeImplementationPlan.md), checked
// against the real schema on an in-memory sqflite_common_ffi database.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/database/cash_ledger_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/models/cash_ledger_entry.dart';
import 'package:invoiso/services/exchange_receipt_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  final day = DateTime(2026, 9, 25, 10);

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: DatabaseHelper().dbVersion,
      onCreate: (db, v) => DatabaseHelper().createDbForTest(db, v),
    );
  });
  tearDown(() => db.close());

  Future<void> add(CashLedgerEntry e) => db.insert('cash_ledger', e.toMap());
  Future<void> opening(double cash, double upi, DateTime date) =>
      add(CashLedgerEntry(
          id: 'open',
          entryType: CashLedgerEntry.opening,
          cashDelta: cash,
          upiDelta: upi,
          dateTime: date));
  CashLedgerEntry exchange(bool upiToCash, String feeMethod) =>
      CashLedgerService.buildExchange(
          upiToCash: upiToCash,
          amount: 1000,
          fee: 10,
          feeMethod: feeMethod,
          dateTime: day);
  Future<void> invoicePayment(String id, String invoiceId, double amount,
          String method, String date) =>
      db.insert('invoice_payments', {
        'id': id,
        'invoice_id': invoiceId,
        'invoice_number': invoiceId,
        'receipt_number': '$invoiceId-R1',
        'amount_paid': amount,
        'balance_after': 0,
        'date_paid': date,
        'payment_method': method,
      });
  Future<void> invoice(String id, {String? deletedAt}) =>
      db.insert('invoices', {'id': id, 'deleted_at': deletedAt});

  test('client example: ₹5,000 cash + ₹10,000 UPI/Bank = ₹15,000', () async {
    await opening(5000, 10000, day);
    final b = await CashLedgerService.balancesOn(db);
    expect(b.cash, 5000);
    expect(b.upiBank, 10000);
    expect(b.cash + b.upiBank, 15000);
  });

  test('UPI→Cash ₹1,000 with ₹10 fee: fee lands in the chosen account',
      () async {
    final byCash = exchange(true, CashLedgerEntry.accountCash);
    expect(byCash.cashDelta, -990); // −1,000 given, +10 fee
    expect(byCash.upiDelta, 1000);

    final byUpi = exchange(true, CashLedgerEntry.accountUpiBank);
    expect(byUpi.cashDelta, -1000);
    expect(byUpi.upiDelta, 1010);
  });

  test('Cash→UPI ₹1,000 with ₹10 fee mirrors it', () async {
    final byCash = exchange(false, CashLedgerEntry.accountCash);
    expect(byCash.cashDelta, 1010);
    expect(byCash.upiDelta, -1000);

    final byUpi = exchange(false, CashLedgerEntry.accountUpiBank);
    expect(byUpi.cashDelta, 1000);
    expect(byUpi.upiDelta, -990);
  });

  test('only the fee is income; exchange amount never is', () async {
    await add(exchange(true, CashLedgerEntry.accountCash));
    await add(exchange(false, CashLedgerEntry.accountUpiBank));
    final t = await CashLedgerService.periodTotalsOn(
        db, DateTime(2026, 9, 25), DateTime(2026, 9, 25, 23, 59));
    expect(t.serviceIncome, 20);

    // Total moves only by the fees.
    final b = await CashLedgerService.balancesOn(db);
    expect(b.cash + b.upiBank, 20);
  });

  test('expense, withdrawal and bank deposit', () async {
    await opening(5000, 10000, day);
    await add(CashLedgerService.buildMovement(
        type: CashLedgerEntry.expense, amount: 200, dateTime: day));
    await add(CashLedgerService.buildMovement(
        type: CashLedgerEntry.withdrawal,
        amount: 300,
        account: CashLedgerEntry.accountUpiBank,
        dateTime: day));
    await add(CashLedgerService.buildMovement(
        type: CashLedgerEntry.bankDeposit, amount: 1000, dateTime: day));

    final b = await CashLedgerService.balancesOn(db);
    expect(b.cash, 5000 - 200 - 1000);
    expect(b.upiBank, 10000 - 300 + 1000);

    final t = await CashLedgerService.periodTotalsOn(
        db, DateTime(2026, 9, 25), DateTime(2026, 9, 25, 23, 59));
    expect(t.expenses, 200);
    expect(t.serviceIncome, 0);
  });

  test('invoice payments: counted from the opening date, by method', () async {
    await invoice('i1');
    await invoice('i2', deletedAt: '2026-09-25T12:00:00.000');
    await invoicePayment('p1', 'i1', 100, 'Cash', '2026-09-24'); // before
    await invoicePayment('p2', 'i1', 200, 'Cash', '2026-09-25');
    await invoicePayment('p3', 'i1', 300, 'UPI', '2026-09-25');
    await invoicePayment('p4', 'i1', 400, 'Bank Transfer', '2026-09-26');
    await invoicePayment('p5', 'i1', 500, 'Online', '2026-09-26');
    await invoicePayment('p6', 'i1', 600, 'Check', '2026-09-26'); // not counted
    await invoicePayment('p7', 'i2', 700, 'Cash', '2026-09-26'); // deleted inv

    // No opening balance yet → invoice payments aren't counted.
    var b = await CashLedgerService.balancesOn(db);
    expect(b.trackingStart, isNull);
    expect(b.cash, 0);

    await opening(0, 0, day);
    b = await CashLedgerService.balancesOn(db);
    expect(b.cash, 200);
    expect(b.upiBank, 300 + 400 + 500);
  });

  test('history merges counted invoice payments, newest first', () async {
    await invoice('i1');
    await invoice('i2', deletedAt: '2026-09-25T12:00:00.000');
    await invoicePayment('p1', 'i1', 100, 'Cash', '2026-09-24'); // before
    await invoicePayment('p2', 'i1', 300, 'UPI', '2026-09-26');
    await invoicePayment('p3', 'i1', 600, 'Check', '2026-09-26'); // not counted
    await invoicePayment('p4', 'i2', 700, 'Cash', '2026-09-26'); // deleted inv

    // No opening balance → no invoice payments in the list either.
    await add(exchange(true, CashLedgerEntry.accountCash));
    expect((await CashLedgerService.entriesOn(db)).length, 1);

    await opening(0, 0, day);
    final start = (await CashLedgerService.balancesOn(db)).trackingStart;
    final all = await CashLedgerService.entriesOn(db, paymentsFrom: start);
    // Payment (26 Sep) first; exchange and opening share 25 Sep 10:00.
    expect(all.first.entryType, CashLedgerEntry.invoicePayment);
    expect(all.skip(1).map((e) => e.entryType).toSet(),
        {CashLedgerEntry.upiToCash, CashLedgerEntry.opening});
    final pay = all.first;
    expect(pay.id, 'p2');
    expect(pay.upiDelta, 300);
    expect(pay.cashDelta, 0);
    expect(pay.exchangeAmount, 300);
    expect(pay.feeMethod, 'UPI');

    final onlyPayments = await CashLedgerService.entriesOn(db,
        type: CashLedgerEntry.invoicePayment, paymentsFrom: start);
    expect(onlyPayments.map((e) => e.id), ['p2']);

    // Counts follow the same filters as the rows.
    expect(await CashLedgerService.countEntriesOn(db, paymentsFrom: start), 3);
    expect(
        await CashLedgerService.countEntriesOn(db,
            type: CashLedgerEntry.invoicePayment, paymentsFrom: start),
        1);
    expect(
        await CashLedgerService.countEntriesOn(db,
            type: CashLedgerEntry.upiToCash, paymentsFrom: start),
        1);
    // Date range applies to payments too (26 Sep payment is outside 25 Sep).
    final on25 = await CashLedgerService.entriesOn(db,
        from: DateTime(2026, 9, 25),
        to: DateTime(2026, 9, 25, 23, 59, 59),
        paymentsFrom: start);
    expect(on25.any((e) => e.entryType == CashLedgerEntry.invoicePayment),
        isFalse);

    // Pages don't overlap and cover everything.
    final p1 = await CashLedgerService.entriesOn(db,
        paymentsFrom: start, limit: 2, offset: 0);
    final p2 = await CashLedgerService.entriesOn(db,
        paymentsFrom: start, limit: 2, offset: 2);
    expect(p1.length, 2);
    expect(p2.length, 1);
    expect({...p1.map((e) => e.id), ...p2.map((e) => e.id)}.length, 3);

    // Sum of the listed deltas matches the balance.
    final b = await CashLedgerService.balancesOn(db);
    expect(all.fold<double>(0, (t, e) => t + e.upiDelta), b.upiBank);
    expect(all.fold<double>(0, (t, e) => t + e.cashDelta), b.cash);
  });

  test('receipt file name: customer_receipt_date_time, customer optional', () {
    CashLedgerEntry at(String? name) => CashLedgerEntry(
        id: 'x',
        entryType: CashLedgerEntry.upiToCash,
        customerName: name,
        dateTime: DateTime(2026, 9, 26, 14, 5));
    expect(ExchangeReceiptService.fileName(at('Ravi Kumar')),
        'Ravi_Kumar_receipt_20260926_1405.pdf');
    expect(ExchangeReceiptService.fileName(at(' A/B: shop ')),
        'A_B_shop_receipt_20260926_1405.pdf');
    expect(ExchangeReceiptService.fileName(at('शिवा')),
        'शिवा_receipt_20260926_1405.pdf');
    expect(ExchangeReceiptService.fileName(at(null)),
        'receipt_20260926_1405.pdf');
    expect(ExchangeReceiptService.fileName(at('  ')),
        'receipt_20260926_1405.pdf');
  });

  test('period opening / closing: balances as at a day boundary', () async {
    await invoice('i1');
    await opening(5000, 10000, DateTime(2026, 9, 1));
    await add(CashLedgerService.buildExchange(
        upiToCash: true,
        amount: 1000,
        fee: 10,
        feeMethod: CashLedgerEntry.accountCash,
        dateTime: DateTime(2026, 9, 10, 15))); // cash −990, upi +1000
    await invoicePayment('p1', 'i1', 300, 'UPI', '2026-09-10');
    await add(CashLedgerService.buildMovement(
        type: CashLedgerEntry.expense,
        amount: 200,
        dateTime: DateTime(2026, 9, 20, 9))); // cash −200

    // Period 10–15 Sep: opening = as at 10 Sep 00:00, closing = as at 16 Sep.
    final open10 =
        await CashLedgerService.balancesOn(db, before: DateTime(2026, 9, 10));
    expect((open10.cash, open10.upiBank), (5000, 10000));
    final close15 =
        await CashLedgerService.balancesOn(db, before: DateTime(2026, 9, 16));
    expect((close15.cash, close15.upiBank), (4010, 11300));
    // The 20 Sep expense only shows in the current balance.
    final now = await CashLedgerService.balancesOn(db);
    expect((now.cash, now.upiBank), (3810, 11300));
  });

  test('opening balance is a single row that can be edited', () async {
    await opening(5000, 10000, day);
    // saveOpening re-writes the same id with ConflictAlgorithm.replace.
    await db.insert(
        'cash_ledger',
        CashLedgerEntry(
                id: 'open',
                entryType: CashLedgerEntry.opening,
                cashDelta: 6000,
                upiDelta: 10000,
                dateTime: day)
            .toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    final rows = await db.query('cash_ledger',
        where: 'entry_type = ?', whereArgs: [CashLedgerEntry.opening]);
    expect(rows.length, 1);
    expect((await CashLedgerService.balancesOn(db)).cash, 6000);
  });
}
