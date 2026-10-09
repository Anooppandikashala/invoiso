// Renders CashExchangeScreen (fake repos, large amounts, long names) at
// phone-to-desktop widths and 130% text; any RenderFlex overflow fails.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/cash_ledger_entry.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/repositories/cash_ledger_repository.dart';
import 'package:invoiso/repositories/settings_repository.dart';
import 'package:invoiso/screens/cash_exchange_screen.dart';

class _Settings implements SettingsRepository {
  @override
  Future<CurrencyOption> getCurrency() async =>
      const CurrencyOption(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Ledger implements CashLedgerRepository {
  final d = DateTime(2026, 9, 26, 12);
  @override
  Future<CashBalances> getBalances({DateTime? before}) async =>
      (cash: 1234567.89, upiBank: -98765.43, trackingStart: DateTime(2026, 9, 1));
  @override
  Future<CashLedgerEntry?> getOpening() async => null;
  @override
  Future<CashPeriodTotals> getPeriodTotals(DateTime f, DateTime t) async =>
      (serviceIncome: 12345.67, expenses: 9999.99);
  @override
  Future<int> countEntries({DateTime? from, DateTime? to, String? type, DateTime? paymentsFrom}) async => 4;
  @override
  Future<List<CashLedgerEntry>> getEntries({DateTime? from, DateTime? to, String? type, DateTime? paymentsFrom, int limit = 25, int offset = 0}) async => [
        CashLedgerEntry(id: '1', entryType: CashLedgerEntry.cashToUpi, receiptNumber: 'EXC-0002', exchangeAmount: 200000, serviceFee: 5000, feeMethod: 'cash', cashDelta: 205000, upiDelta: -200000, customerName: 'A very long customer name for testing', customerPhone: '9876543210', dateTime: d, notes: 'Some long notes about this exchange transaction', createdBy: 'u', createdAt: DateTime.now(), edited: true),
        CashLedgerEntry(id: '2', entryType: CashLedgerEntry.invoicePayment, receiptNumber: 'INV-1-R1', exchangeAmount: 838.95, feeMethod: 'UPI', upiDelta: 838.95, customerName: 'Customer1', dateTime: d, notes: '00000100'),
        CashLedgerEntry(id: '3', entryType: CashLedgerEntry.opening, cashDelta: 5000, upiDelta: 10000000, dateTime: d),
        CashLedgerEntry(id: '4', entryType: CashLedgerEntry.expense, cashDelta: -250, dateTime: d, createdBy: 'other', createdAt: DateTime.now()),
      ];
  // Change log: 25 deletes + 3 edits of entry '1' (edits first, newest).
  List<CashLedgerChange> _log(String? action) => [
        for (var i = 0; i < 3; i++)
          (action: 'edit', entry: CashLedgerEntry(id: '1', entryType: CashLedgerEntry.upiToCash, exchangeAmount: 100.0 + i, dateTime: d, notes: 'edited #$i'), changedByName: 'admin', changedAt: d),
        for (var i = 0; i < 25; i++)
          (action: 'delete', entry: CashLedgerEntry(id: 'd$i', entryType: CashLedgerEntry.expense, cashDelta: -1, dateTime: d, notes: 'deleted #$i'), changedByName: 'admin', changedAt: d),
      ].where((c) => action == null || c.action == action).toList();
  @override
  Future<int> countChanges({String? action}) async => _log(action).length;
  @override
  Future<List<CashLedgerChange>> getChanges({String? action, int limit = 10, int offset = 0}) async =>
      _log(action).skip(offset).take(limit).toList();
  @override
  Future<List<CashLedgerChange>> getHistory(String entryId) async =>
      _log('edit').where((c) => c.entry.id == entryId).toList();
  @override
  Future<CashLedgerEntry?> getEntry(String id) async =>
      (await getEntries()).firstWhere((e) => e.id == id);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> _pump(WidgetTester tester, double width, double scale,
    String userType) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWith((ref) => _Settings()),
      cashLedgerRepositoryProvider.overrideWith((ref) => _Ledger()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: CashExchangeScreen(
          user: User(id: 'u', username: userType, password: '', userType: userType)),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 400.0, 480.0, 600.0, 700.0, 900.0, 1400.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow at ${width}px, text x$scale', (tester) async {
        await _pump(tester, width, scale, 'admin');
        expect(find.text('Cash'), findsWidgets);
        expect(find.text('Total balance'), findsWidgets);
      });
    }
  }

  // Regular users: no balances, income or expense totals, but every action.
  for (final width in [320.0, 1400.0]) {
    testWidgets('regular user at ${width}px sees actions, not balances',
        (tester) async {
      await _pump(tester, width, 1.0, 'user');
      for (final hidden in [
        'Total balance',
        'Service income (today)',
        'Service income (this month)',
        'Expenses (this month)',
      ]) {
        expect(find.text(hidden), findsNothing, reason: hidden);
      }
      expect(find.textContaining('Closing balance'), findsNothing);
      expect(find.text('UPI → Cash'), findsOneWidget);
      expect(find.text('Withdrawal'), findsOneWidget);
    });
  }

  // ⋮ menus: regular user 'u' only on their own exchange (Print, Edit,
  // Delete), not on someone else's expense; admin also gets History on the
  // edited row and a menu on the expense. Opening / invoice payment: none.
  testWidgets('regular user: menu only on own recent entry', (tester) async {
    await _pump(tester, 1400, 1.0, 'user');
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text('Change log'), findsNothing);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Change history'), findsNothing);
  });

  testWidgets('admin: menus on every changeable row, history, change log',
      (tester) async {
    await _pump(tester, 1400, 1.0, 'admin');
    expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
    expect(find.text('Change log'), findsOneWidget);
    expect(find.text('Edited'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Change history'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('change log: 10 per page, filter, edit opens history',
      (tester) async {
    await _pump(tester, 1400, 1.0, 'admin');
    await tester.tap(find.text('Change log'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 3'), findsOneWidget); // 28 changes
    expect(find.textContaining('edited #'), findsNWidgets(3));
    expect(find.textContaining('deleted #'), findsNWidgets(7));

    // Deleted only: 25 → 3 pages; page 2 starts at #10.
    await tester.tap(find.text('Deleted'));
    await tester.pumpAndSettle();
    expect(find.textContaining('edited #'), findsNothing);
    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();
    expect(find.text('Page 2 of 3'), findsOneWidget);
    expect(find.textContaining('deleted #10'), findsOneWidget);
    expect(find.textContaining('deleted #9'), findsNothing);

    // Edited only: one page; tapping a row opens the entry's history with
    // its current version on top.
    await tester.tap(find.text('Edited').last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Page 1 of 1')), findsOneWidget);
    await tester.tap(find.textContaining('edited #0'));
    await tester.pumpAndSettle();
    expect(find.text('Change history'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
  });

  // Balances collapse to one line with the closing total; no overflow.
  for (final width in [320.0, 1400.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('balances collapse at ${width}px, text x$scale',
          (tester) async {
        await _pump(tester, width, scale, 'admin');
        expect(find.textContaining('Opening balance ·'), findsOneWidget);
        await tester.ensureVisible(find.text('Hide balances'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hide balances'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Opening balance ·'), findsNothing);
        expect(find.textContaining('Closing balance: '), findsOneWidget);
        await tester.ensureVisible(find.text('Show balances'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Show balances'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Opening balance ·'), findsOneWidget);
      });
    }
  }

  testWidgets('regular user: no balances toggle', (tester) async {
    await _pump(tester, 1400, 1.0, 'user');
    expect(find.text('Hide balances'), findsNothing);
  });
}
