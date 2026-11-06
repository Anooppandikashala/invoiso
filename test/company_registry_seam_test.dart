// Company switching through BackendServices.companyRegistry (cloud
// CloudParityPlan.md Phase 3): local edition behaviour unchanged (switch →
// Login, create dialog asks for an admin account); cloud edition keeps the
// login (switch → same user re-read → onboarding/dashboard), no admin account
// fields, New Company only for the owner.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_profile.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/sqlite_repository_overrides.dart';
import 'package:invoiso/repositories/auth_repository.dart';
import 'package:invoiso/repositories/company_registry_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_company_info_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_installation_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_attachment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_invoice_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_payment_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_return_repository.dart';
import 'package:invoiso/repositories/sqlite/sqlite_settings_repository.dart';
import 'package:invoiso/screens/auth/login_screen.dart';
import 'package:invoiso/screens/onboarding/onboarding_screen.dart';
import 'package:invoiso/screens/settings/company_management_screen.dart';
import 'package:invoiso/services/backend_services.dart';

class _FakeRegistry implements CompanyRegistryRepository {
  final companies = [
    CompanyProfile(id: 'a', name: 'Alpha', dbFileName: '', createdAt: DateTime(2026)),
    CompanyProfile(id: 'b', name: 'Beta', dbFileName: '', createdAt: DateTime(2026)),
  ];
  String active = 'a';

  @override
  Future<List<CompanyProfile>> listCompanies() async => companies;
  @override
  Future<String?> getActiveCompanyId() async => active;
  @override
  Future<void> switchToCompany(String id) async => active = id;
  @override
  Future<CompanyProfile> createCompany(String name) async => throw UnimplementedError();
  @override
  Future<void> renameCompany(String id, String name) async {}
  @override
  Future<void> deleteCompany(String id) async {}
}

/// Cloud auth: getUserById re-reads the same login (role of the new company).
class _FakeCloudAuth implements AuthRepository {
  final List<String> lookedUp = [];
  @override
  Future<User?> getUserById(String id) async {
    lookedUp.add(id);
    return User(id: id, username: 'owner@x.com', password: '', userType: 'admin');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late _FakeRegistry registry;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tmp = Directory.systemTemp.createTempSync('invoiso_registry_seam_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path);
    // Two companies → refreshWindowTitle sets the desktop window title.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('window_manager'), (call) async => null);
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
    tmp.deleteSync(recursive: true);
  });

  var dbCounter = 0;
  setUp(() async {
    await DatabaseHelper().switchToFile('registry_seam_${dbCounter++}.db');
    registry = _FakeRegistry();
    BackendServices.configure(
      settings: SqliteSettingsRepository(),
      companyInfo: SqliteCompanyInfoRepository(),
      invoices: SqliteInvoiceRepository(),
      payments: SqlitePaymentRepository(),
      installation: SqliteInstallationRepository(),
      attachments: SqliteInvoiceAttachmentRepository(),
      returns: SqliteReturnRepository(),
      companyRegistry: registry,
    );
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  Future<void> pumpScreen(WidgetTester tester,
      {required bool cloud, required String userType, AuthRepository? auth}) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final base = ProviderContainer().read(appEditionConfigProvider);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...sqliteRepositoryOverrides,
        if (auth != null) authRepositoryProvider.overrideWithValue(auth),
        appEditionConfigProvider.overrideWithValue(AppEditionConfig(
          name: base.name,
          version: base.version,
          developer: base.developer,
          supportEmail: base.supportEmail,
          website: base.website,
          license: base.license,
          description: base.description,
          additionalNote: base.additionalNote,
          thankYouNote: base.thankYouNote,
          enableUpdateCheck: false,
          isCloud: cloud,
        )),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompanyManagementScreen(
          currentUser:
              User(id: 'u1', username: 'owner', password: '', userType: userType),
        ),
      ),
    ));
    await settle(tester);
  }

  Future<void> switchToBeta(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, 'Switch'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Switch').last); // confirm
    await tester.pump();
    await settle(tester);
  }

  testWidgets('local: New Company asks for an admin account', (tester) async {
    await pumpScreen(tester, cloud: false, userType: 'user');
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    await tester.tap(find.text('+ New Company'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Account'), findsOneWidget);
  });

  testWidgets('local: switching lands on Login', (tester) async {
    await pumpScreen(tester, cloud: false, userType: 'admin');
    await switchToBeta(tester);
    expect(registry.active, 'b');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('cloud: no admin account fields; New Company owner-only',
      (tester) async {
    await pumpScreen(tester, cloud: true, userType: 'user');
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('+ New Company'), findsNothing);

    await pumpScreen(tester, cloud: true, userType: 'admin');
    await tester.tap(find.text('+ New Company'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Account'), findsNothing);
  });

  testWidgets('cloud: switching keeps the login (no Login screen)',
      (tester) async {
    final auth = _FakeCloudAuth();
    await pumpScreen(tester, cloud: true, userType: 'admin', auth: auth);
    await switchToBeta(tester);
    expect(registry.active, 'b');
    expect(auth.lookedUp, ['u1']);
    expect(find.byType(LoginScreen), findsNothing);
    // Fresh test DB has onboarding not completed → onboarding, as for a new company.
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
