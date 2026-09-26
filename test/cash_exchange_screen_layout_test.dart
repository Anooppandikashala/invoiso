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
  Future<int> countEntries({DateTime? from, DateTime? to, String? type, DateTime? paymentsFrom}) async => 3;
  @override
  Future<List<CashLedgerEntry>> getEntries({DateTime? from, DateTime? to, String? type, DateTime? paymentsFrom, int limit = 25, int offset = 0}) async => [
        CashLedgerEntry(id: '1', entryType: CashLedgerEntry.cashToUpi, receiptNumber: 'EXC-0002', exchangeAmount: 200000, serviceFee: 5000, feeMethod: 'cash', cashDelta: 205000, upiDelta: -200000, customerName: 'A very long customer name for testing', customerPhone: '9876543210', dateTime: d, notes: 'Some long notes about this exchange transaction'),
        CashLedgerEntry(id: '2', entryType: CashLedgerEntry.invoicePayment, receiptNumber: 'INV-1-R1', exchangeAmount: 838.95, feeMethod: 'UPI', upiDelta: 838.95, customerName: 'Customer1', dateTime: d, notes: '00000100'),
        CashLedgerEntry(id: '3', entryType: CashLedgerEntry.opening, cashDelta: 5000, upiDelta: 10000000, dateTime: d),
      ];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  for (final width in [320.0, 400.0, 480.0, 600.0, 700.0, 900.0, 1400.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow at ${width}px, text x$scale', (tester) async {
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
                user: User(id: 'u', username: 'admin', password: '', userType: 'admin')),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Cash'), findsWidgets);
      });
    }
  }
}
