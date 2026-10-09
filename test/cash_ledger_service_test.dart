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

  test('daily net per account: movements + counted payments, not the opening',
      () async {
    final next = DateTime(2026, 9, 26, 15);
    await opening(5000, 10000, day);
    await add(exchange(true, CashLedgerEntry.accountCash)); // 25th
    await add(CashLedgerService.buildMovement(
        type: CashLedgerEntry.expense, amount: 200, dateTime: next));
    await add(CashLedgerService.buildMovement(
        type: CashLedgerEntry.bankDeposit, amount: 300, dateTime: next));
    await invoice('i1');
    await invoice('i2', deletedAt: '2026-09-26T12:00:00.000');
    await invoicePayment('p1', 'i1', 50, 'Cash', '2026-09-24'); // pre-opening
    await invoicePayment('p2', 'i1', 150, 'Cash', '2026-09-26');
    await invoicePayment('p3', 'i1', 400, 'UPI', '2026-09-26');
    await invoicePayment('p4', 'i1', 600, 'Check', '2026-09-26'); // not money
    await invoicePayment('p5', 'i2', 700, 'Cash', '2026-09-26'); // deleted inv

    final net = await CashLedgerService.dailyNetOn(
        db, DateTime(2026, 9, 24), DateTime(2026, 9, 26));
    expect(net.keys.toSet(), {'2026-09-25', '2026-09-26'});
    // 25th: one exchange with a 10 service fee; 26th: ledger movements and
    // invoice payments kept apart, no exchanges, no fees.
    expect(net['2026-09-25'], (
      cash: -990.0,
      upiBank: 1000.0,
      payCash: 0.0,
      payUpi: 0.0,
      fee: 10.0,
      exchanges: 1
    ));
    expect(net['2026-09-26'], (
      cash: -200.0 - 300,
      upiBank: 300.0,
      payCash: 150.0,
      payUpi: 400.0,
      fee: 0.0,
      exchanges: 0
    ));

    // Reconciles with the balances: closing(26th) − closing(25th) = net(26th).
    final c25 = await CashLedgerService.balancesOn(db, before: DateTime(2026, 9, 26));
    final c26 = await CashLedgerService.balancesOn(db, before: DateTime(2026, 9, 27));
    final n26 = net['2026-09-26']!;
    expect(c26.cash - c25.cash, n26.cash + n26.payCash);
    expect(c26.upiBank - c25.upiBank, n26.upiBank + n26.payUpi);

    // Range limits both sources.
    expect((await CashLedgerService.dailyNetOn(
            db, DateTime(2026, 9, 26), DateTime(2026, 9, 26)))
        .keys, ['2026-09-26']);
  });

  group('edit / delete with edit log', () {
    final created = DateTime(2026, 9, 25, 10, 5);
    final soon = created.add(const Duration(hours: 2));
    Future<CashLedgerEntry> saved(CashLedgerEntry e) async {
      await add(e);
      return e;
    }

    CashLedgerEntry staffExchange() => CashLedgerService.buildExchange(
        upiToCash: true,
        amount: 1000,
        fee: 10,
        feeMethod: CashLedgerEntry.accountCash,
        dateTime: day,
        receiptNumber: 'EXC-0001',
        customerId: 'c1',
        customerName: 'Ravi',
        createdBy: 'staff',
        createdAt: created);

    Future<void> change(String id,
            {CashLedgerEntry? updated,
            String userId = 'staff',
            bool isAdmin = false,
            DateTime? now}) =>
        db.transaction((txn) => CashLedgerService.changeOn(txn, id,
            updated: updated,
            userId: userId,
            userName: userId,
            isAdmin: isAdmin,
            now: now ?? soon));

    test('edit rebuilds deltas, keeps identity, logs the old version',
        () async {
      await opening(5000, 10000, day);
      final e = await saved(staffExchange());
      // Wrong button: it was Cash→UPI ₹2,000, fee ₹20 by UPI.
      await change(e.id,
          updated: CashLedgerService.buildExchange(
              upiToCash: false,
              amount: 2000,
              fee: 20,
              feeMethod: CashLedgerEntry.accountUpiBank,
              dateTime: day,
              customerName: 'Ravi'));

      final b = await CashLedgerService.balancesOn(db);
      expect(b.cash, 5000 + 2000);
      expect(b.upiBank, 10000 - 2000 + 20);

      final row = CashLedgerEntry.fromMap(
          (await db.query('cash_ledger', where: 'id = ?', whereArgs: [e.id]))
              .first);
      expect(row.entryType, CashLedgerEntry.cashToUpi);
      expect(row.receiptNumber, 'EXC-0001');
      expect(row.createdBy, 'staff');
      expect(row.createdAt, created);

      final h = await CashLedgerService.historyOn(db, entryId: e.id);
      expect(h.length, 1);
      expect(h.first.action, 'edit');
      expect(h.first.changedByName, 'staff');
      expect(h.first.entry.exchangeAmount, 1000);
      expect(h.first.entry.cashDelta, -990);

      final listed = await CashLedgerService.entriesOn(db);
      expect(listed.firstWhere((x) => x.id == e.id).edited, isTrue);
      expect(listed.firstWhere((x) => x.id == 'open').edited, isFalse);
    });

    test('moving the date moves the amount between days', () async {
      final e = await saved(staffExchange());
      await change(e.id,
          updated: CashLedgerService.buildExchange(
              upiToCash: true,
              amount: 1000,
              fee: 10,
              feeMethod: CashLedgerEntry.accountCash,
              dateTime: DateTime(2026, 9, 24, 18),
              customerName: 'Ravi'));
      final net = await CashLedgerService.dailyNetOn(
          db, DateTime(2026, 9, 24), DateTime(2026, 9, 25));
      expect(net.keys, ['2026-09-24']);
      expect(net['2026-09-24']!.cash, -990);
    });

    test('expense account switch', () async {
      final e = await saved(CashLedgerService.buildMovement(
          type: CashLedgerEntry.expense,
          amount: 200,
          dateTime: day,
          createdBy: 'staff',
          createdAt: created));
      await change(e.id,
          updated: CashLedgerService.buildMovement(
              type: CashLedgerEntry.expense,
              amount: 250,
              account: CashLedgerEntry.accountUpiBank,
              dateTime: day));
      final b = await CashLedgerService.balancesOn(db);
      expect((b.cash, b.upiBank), (0.0, -250.0));
    });

    test('delete removes the row and keeps it in the log', () async {
      final e = await saved(staffExchange());
      await change(e.id);
      expect(await db.query('cash_ledger'), isEmpty);
      final d = await CashLedgerService.historyOn(db, action: 'delete');
      expect(d.single.entry.receiptNumber, 'EXC-0001');
      expect(d.single.entry.customerName, 'Ravi');
    });

    test('change log: pages, newest first, filter by action', () async {
      for (var i = 0; i < 25; i++) {
        final e = await saved(CashLedgerService.buildMovement(
            type: CashLedgerEntry.expense,
            amount: i + 1.0,
            dateTime: day,
            createdBy: 'staff',
            createdAt: created));
        await change(e.id, now: soon.add(Duration(minutes: i)));
      }
      expect(await CashLedgerService.countChangesOn(db, action: 'delete'), 25);
      final pages = [
        for (final offset in [0, 10, 20])
          await CashLedgerService.historyOn(db,
              action: 'delete', limit: 10, offset: offset)
      ];
      expect(pages.map((p) => p.length), [10, 10, 5]);
      final amounts =
          pages.expand((p) => p).map((c) => -c.entry.cashDelta).toList();
      expect(amounts, [for (var i = 25; i >= 1; i--) i.toDouble()]);

      // One edit, logged after the deletes: newest in "all", alone in "edit".
      final e = await saved(staffExchange());
      await change(e.id,
          updated: CashLedgerService.buildExchange(
              upiToCash: true,
              amount: 1500,
              fee: 10,
              feeMethod: CashLedgerEntry.accountCash,
              dateTime: day,
              customerName: 'Ravi'),
          now: soon.add(const Duration(hours: 1)));
      expect(await CashLedgerService.countChangesOn(db), 26);
      expect(await CashLedgerService.countChangesOn(db, action: 'edit'), 1);
      final all = await CashLedgerService.historyOn(db, limit: 10);
      expect(all.first.action, 'edit');
      expect(all.first.entry.id, e.id);
      expect(all.skip(1).every((c) => c.action == 'delete'), isTrue);
    });

    test('unchanged save writes nothing', () async {
      final e = await saved(staffExchange());
      await change(e.id, updated: staffExchange());
      expect(await db.query('cash_ledger_history'), isEmpty);
    });

    test('who can change what', () async {
      final e = await saved(staffExchange());
      bool can(CashLedgerEntry x,
              {String user = 'staff', bool admin = false, DateTime? now}) =>
          CashLedgerService.canModify(x,
              userId: user, isAdmin: admin, now: now ?? soon);
      final late = created.add(const Duration(hours: 24));

      expect(can(e), isTrue); // own, within 24 h
      expect(can(e, now: late), isFalse); // window over
      expect(can(e, user: 'other'), isFalse); // someone else's
      expect(can(e, user: 'admin', admin: true, now: late), isTrue);
      // Adjustments and pre-v51 rows (no entry time): admins only.
      final adj = CashLedgerEntry(
          id: 'a',
          entryType: CashLedgerEntry.adjustment,
          cashDelta: 5,
          dateTime: day,
          createdBy: 'staff',
          createdAt: created);
      expect(can(adj), isFalse);
      expect(can(adj, user: 'admin', admin: true), isTrue);
      final old = CashLedgerEntry(
          id: 'o', entryType: CashLedgerEntry.expense, dateTime: day,
          createdBy: 'staff');
      expect(can(old), isFalse);
      // Never: opening and invoice payments.
      for (final type in [
        CashLedgerEntry.opening,
        CashLedgerEntry.invoicePayment
      ]) {
        expect(
            can(CashLedgerEntry(id: 'x', entryType: type, dateTime: day),
                user: 'admin', admin: true),
            isFalse);
      }

      // Enforced on write too, nothing logged.
      await expectLater(change(e.id, userId: 'other'), throwsStateError);
      await expectLater(change(e.id, now: late), throwsStateError);
      await expectLater(change('missing', isAdmin: true), throwsStateError);
      expect(await db.query('cash_ledger_history'), isEmpty);
      expect((await db.query('cash_ledger')).length, 1);
    });
  });
}
