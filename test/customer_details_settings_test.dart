// Settings → Customer Details (moved from Invoice Settings): loads the saved
// customer-field switches, Print on PDF shows under an enabled field, and
// Save writes the same setting keys as before.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/screens/settings/customer_details_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  final repo = SqliteSettingsRepository();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_customer_details_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    await DatabaseHelper().switchToFile('customer_details_test.db');
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
  }

  testWidgets('loads, toggles and saves customer field settings', (tester) async {
    await tester.runAsync(() async {
      await repo.setSetting(SettingKey.customerDobEnabled, 'true');
      await repo.setSetting(SettingKey.showCustomerDobInPdf, 'false');
    });
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: sqliteRepositoryOverrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CustomerDetailsSettingsScreen(),
      ),
    ));
    await settle(tester);

    expect(find.text('Customize Customer Details'), findsOneWidget);
    // DOB on → its Print on PDF switch shows (off, as saved).
    final printOnPdf = find.widgetWithText(SwitchListTile, 'Print on PDF');
    expect(printOnPdf, findsOneWidget);
    expect(tester.widget<SwitchListTile>(printOnPdf).value, isFalse);

    final shipping = find.ancestor(
        of: find.text('Separate Shipping Address'), matching: find.byType(SwitchListTile));
    await tester.tap(shipping);
    await tester.pump();
    expect(find.widgetWithText(SwitchListTile, 'Print on PDF'), findsNWidgets(2));

    await tester.tap(find.text('Save'));
    await settle(tester);
    final saved = await tester.runAsync(() => Future.wait([
          repo.getSetting(SettingKey.shippingAddressEnabled),
          repo.getSetting(SettingKey.customerDobEnabled),
          repo.getSetting(SettingKey.showCustomerDobInPdf),
        ]));
    expect(saved, ['true', 'true', 'false']);
    expect(find.text('Customer details saved.'), findsOneWidget);
  });
}
