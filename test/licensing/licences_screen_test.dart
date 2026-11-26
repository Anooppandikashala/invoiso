import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/l10n/app_localizations_en.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/repositories/company_info_repository.dart';
import 'package:invoiso/screens/settings/licences_screen.dart';
import 'package:invoiso/services/licensing/licence_api.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/licensing/licence_store.dart';

import 'licence_fakes.dart';

class _Company implements CompanyInfoRepository {
  @override
  Future<CompanyInfo?> getCompanyInfo() async =>
      CompanyInfo(name: 'Shop', address: '', phone: '', email: '', website: '', gstin: '');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  final l10n = AppLocalizationsEn();
  final now = DateTime.utc(2026, 11, 25);
  late TestSigner signer;
  late FakeLicenceApi api;

  LicenceService service() => LicenceService(
        api: api,
        store: LicenceStore(),
        now: () => now,
        activationCode: () async => testActivationCode,
        publicKey: signer.publicKey,
      );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [companyInfoRepositoryProvider.overrideWithValue(_Company())],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LicencesScreen(service: service()),
      ),
    ));
    // Ed25519 checks + shared_prefs are real async work.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    signer = TestSigner();
    await signer.init();
    api = FakeLicenceApi();
  });

  testWidgets('shows the activation code and the empty state', (tester) async {
    await pump(tester);
    expect(find.text(testActivationCode), findsOneWidget);
    expect(find.text(l10n.licencesEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a licence 40 days without a check shows overdue + banner', (tester) async {
    await tester.runAsync(() async => LicenceStore().save([
          StoredLicence(
            licence: await signer.licence(),
            lease: await signer.lease(now.subtract(const Duration(days: 40))),
          ),
        ]));
    await pump(tester);
    expect(find.text(l10n.licencesStatusOverdue), findsOneWidget);
    expect(find.text(l10n.licencesOverdueBanner), findsOneWidget);
    expect(find.text(l10n.licencesRenewOffline), findsOneWidget);
  });

  testWidgets('Enter licence key shows the server error in plain words', (tester) async {
    api.activateResult = const LicenceApiResult.error('active_elsewhere');
    await pump(tester);
    await tester.tap(find.text(l10n.licencesEnterKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, l10n.licencesKeyLabel), 'INVS-0000-0000-0000-0000');
    // Activate does nothing until the email is filled in too.
    await tester.tap(find.text(l10n.licencesActivate));
    await tester.pumpAndSettle();
    expect(find.text(l10n.licencesEmailLabel), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, l10n.licencesEmailLabel), 'buyer@example.com');
    await tester.tap(find.text(l10n.licencesActivate));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text(l10n.licenceErrActiveElsewhere), findsOneWidget);
  });
}
