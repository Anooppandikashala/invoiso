import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/l10n/app_localizations_en.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/repositories/company_registry_repository.dart';
import 'package:invoiso/repositories/invoice_attachment_repository.dart';
import 'package:invoiso/repositories/return_repository.dart';
import 'package:invoiso/screens/settings/pdf_settings_screen_v2.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/services/templates/template_pack.dart';
import 'package:invoiso/services/templates/template_pack_store.dart';
import 'package:invoiso/widgets/template_list_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pdf_settings_custom_layout_test.dart'
    show
        FakeSettingsRepository,
        FakeCompanyInfoRepository,
        FakeInvoiceRepository,
        FakePaymentRepository,
        FakeInstallationRepository;

const _secret = 'SECRET-PACK-LAYOUT-TEXT';

/// Records what the screen saves.
class _Repo extends FakeSettingsRepository {
  final saved = <SettingKey, String>{};
  final deleted = <SettingKey>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    final args = invocation.positionalArguments;
    if (name.contains('"setSetting"')) {
      saved[args[0] as SettingKey] = args[1] as String;
      deleted.remove(args[0]);
      return Future<void>.value();
    }
    if (name.contains('"deleteSetting"')) {
      deleted.add(args[0] as SettingKey);
      saved.remove(args[0]);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _Attachments implements InvoiceAttachmentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Returns implements ReturnRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Registry implements CompanyRegistryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Free, so it can be selected without a licence (paid + no licence = locked).
Uint8List _devPack({String id = 'gst-tax-invoice', String name = 'GST Tax Invoice', bool free = true}) =>
    Uint8List.fromList(utf8.encode('INVDEV1\n${jsonEncode({
      'manifest': {'templateId': id, 'name': name, 'version': 1, 'minEngine': 2, 'free': free},
      'layout': {
        'engine': 2,
        'layout': [
          {'type': 'text', 'value': _secret},
        ],
      },
    })}'));

void main() {
  final l10n = AppLocalizationsEn();
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('pdf_settings_pack');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (call) async => tmp.path);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> settle(WidgetTester tester) async {
    // Real I/O (files, prefs, licence checks) advances ~one await per pass.
    for (var i = 0; i < 25; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('installed template: listed with status, no Edit JSON, saved by id only, never in the JSON editor',
      (tester) async {
    final loader = FontLoader('DejaVuSans')..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    await loader.load();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final result = await tester.runAsync(() => TemplatePackStore(
          decoder: const DevPackDecoder(NoPackDecoder(), enabled: true),
          baseDir: () async => tmp,
        ).install(_devPack()));
    expect(result!.status, PackInstallStatus.installed);
    // A paid template with no licence on this PC: listed but locked.
    await tester.runAsync(() => TemplatePackStore(
          decoder: const DevPackDecoder(NoPackDecoder(), enabled: true),
          baseDir: () async => tmp,
        ).install(_devPack(id: 'paid-design', name: 'Paid Design', free: false)));

    final repo = _Repo();
    BackendServices.configure(
      settings: repo,
      companyInfo: FakeCompanyInfoRepository(),
      invoices: FakeInvoiceRepository(),
      payments: FakePaymentRepository(),
      installation: FakeInstallationRepository(),
      attachments: _Attachments(),
      returns: _Returns(),
      companyRegistry: _Registry(),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'DejaVuSans'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PdfSettingsScreenV2(),
      ),
    ));
    await settle(tester);

    final tile = find.widgetWithText(TemplateListTile, 'GST Tax Invoice');
    expect(find.text(l10n.storeTitle.toUpperCase()), findsOneWidget);
    expect(tile, findsOneWidget);
    // Free template: usable; no Edit JSON on the tile.
    expect(find.descendant(of: tile, matching: find.text(l10n.pdfPackStatusFree)), findsOneWidget);
    // Paid template without a licence: greyed out, can't be selected.
    final paid = find.widgetWithText(TemplateListTile, 'Paid Design');
    expect(tester.widget<TemplateListTile>(paid).isDisabled, isTrue);
    await tester.tap(paid);
    await settle(tester);
    expect(find.text('Paid Design'), findsOneWidget); // tile only, not in the headers
    expect(find.descendant(of: tile, matching: find.byTooltip(l10n.pdfLayoutEditTooltip)), findsNothing);
    expect(find.descendant(of: tile, matching: find.byTooltip(l10n.pdfPackRemoveTooltip)), findsOneWidget);

    // Use it: both headers (settings column + preview) show its name.
    expect(find.text('Classic'), findsNWidgets(3)); // tile + 2 headers
    await tester.tap(tile);
    await settle(tester);
    expect(find.text('GST Tax Invoice'), findsNWidgets(3)); // tile + 2 headers
    expect(find.text('Classic'), findsOneWidget); // built-in tile only

    // Save: only the id is stored, the custom layout is cleared.
    await tester.tap(find.text(l10n.pdfSettingsSaveSettingsButton));
    await settle(tester);
    expect(repo.saved[SettingKey.activeTemplatePack], 'gst-tax-invoice');
    expect(repo.deleted, contains(SettingKey.activeCustomLayout));
    for (final v in repo.saved.values) {
      expect(v, isNot(contains(_secret)));
    }

    // While it is selected, JSON create / save-as are off (no look-alike copy).
    await tester.tap(find.text(l10n.pdfLayoutAddButton));
    await settle(tester);
    expect(find.text(l10n.pdfPackNoJsonCopy), findsNWidgets(2));
    await tester.tap(find.text(l10n.pdfLayoutCreateEditJsonTitle));
    await settle(tester);
    expect(find.text(l10n.pdfLayoutCreateFromJsonTitle), findsNothing);
    await tester.tapAt(const Offset(700, 50)); // close the sheet
    await settle(tester);

    // Back on a built-in template, the JSON editor holds nothing of the template.
    await tester.tap(find.text('Classic').first);
    await settle(tester);
    await tester.tap(find.text(l10n.pdfLayoutAddButton));
    await settle(tester);
    await tester.tap(find.text(l10n.pdfLayoutCreateEditJsonTitle));
    await settle(tester);
    final editor = tester.widgetList<TextField>(find.byType(TextField)).map((f) => f.controller?.text ?? '');
    expect(editor.any((t) => t.contains('"name"')), isTrue, reason: 'JSON editor should be open');
    expect(editor.any((t) => t.contains(_secret)), isFalse);

    // §9.5b #5: the custom-layouts list never holds the template's layout.
    for (final layout in repo.layouts) {
      expect(layout.toPrettyJson(), isNot(contains(_secret)));
    }
  });
}
