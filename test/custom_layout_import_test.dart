import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/models/custom_invoice_layout.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/repositories/company_info_repository.dart';
import 'package:invoiso/repositories/installation_repository.dart';
import 'package:invoiso/repositories/invoice_repository.dart';
import 'package:invoiso/repositories/payment_repository.dart';
import 'package:invoiso/repositories/settings_repository.dart';
import 'package:invoiso/screens/settings/pdf_settings_screen_v2.dart';
import 'package:invoiso/services/backend_services.dart';

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this.bytes);

  final Uint8List bytes;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return FilePickerResult([
      PlatformFile(
        name: 'imported-layout.json',
        size: bytes.length,
        bytes: bytes,
      ),
    ]);
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  final List<CustomInvoiceLayout> layouts = [];
  final Map<SettingKey, String> settings = {};
  InvoiceTemplate? savedTemplate;
  PageSize? savedPageSize;
  String? savedThemeColor;
  bool clearedThemeColor = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('getCustomInvoiceLayouts')) {
      return Future.value(List<CustomInvoiceLayout>.of(layouts));
    }
    if (name.contains('saveCustomInvoiceLayouts')) {
      final list =
          invocation.positionalArguments.first as List<CustomInvoiceLayout>;
      layouts
        ..clear()
        ..addAll(list);
      return Future<void>.value();
    }
    if (name.contains('setSetting')) {
      settings[invocation.positionalArguments.first as SettingKey] =
          invocation.positionalArguments[1] as String;
      return Future<void>.value();
    }
    if (name.contains('deleteSetting')) {
      settings.remove(invocation.positionalArguments.first as SettingKey);
      return Future<void>.value();
    }
    if (name.contains('setInvoiceTemplate')) {
      savedTemplate = invocation.positionalArguments.first as InvoiceTemplate;
      return Future<void>.value();
    }
    if (name.contains('setPageSize')) {
      savedPageSize = invocation.positionalArguments.first as PageSize;
      return Future<void>.value();
    }
    if (name.contains('setPdfThemeColor')) {
      savedThemeColor = invocation.positionalArguments.first as String;
      return Future<void>.value();
    }
    if (name.contains('clearPdfThemeColor')) {
      clearedThemeColor = true;
      savedThemeColor = null;
      return Future<void>.value();
    }
    if (name.contains('getInvoiceTemplate')) {
      return Future.value(InvoiceTemplate.classic);
    }
    if (name.contains('getPageSize')) return Future.value(PageSize.a4);
    if (name.contains('getBusinessType')) return Future.value(BusinessType.both);
    if (name.contains('getLogoPosition')) return Future.value(LogoPosition.left);
    if (name.contains('getLogoSize')) return Future.value('80');
    if (name.contains('getSignaturePosition')) return Future.value('left');
    if (name.contains('getSignatureSize')) return Future.value('50');
    if (name.contains('getPdfTimeFormat')) return Future.value('12h');
    if (name.contains('getUpiIds')) return Future.value(const <UpiEntry>[]);
    if (name.contains('getBankAccounts')) {
      return Future.value(const <BankAccount>[]);
    }
    if (name.contains('getInvoicePdfMetadataColumns')) {
      return Future.value(<String, bool>{});
    }
    if (name.contains('getWatermarkOpacity')) return Future.value(0.2);
    if (name.contains('getCustomerCustomFieldDefs')) {
      return Future.value(const <CustomFieldDef>[]);
    }
    if (name.contains('getCompanyLogo') ||
        name.contains('getSignatureImage') ||
        name.contains('getWatermarkImage')) {
      return Future<String?>.value(null);
    }
    if (name.contains('getPdfLandscape')) return Future.value(false);
    if (name.contains('getPdfThemeColor')) return Future.value(null);
    if (name.contains('getShowTotalQuantity')) return Future.value(false);
    if (name.contains('getShowInvoiceFooterBranding')) {
      return Future.value(true);
    }
    if (name.contains('getShow') || name.contains('getWatermarkFullPage')) {
      return Future.value(false);
    }
    if (name.contains('getLetterheadEnabled')) return Future.value(false);
    if (name.contains('getLetterheadHideCompanyHeader')) {
      return Future.value(true);
    }
    if (name.contains('getPrintMarginTopMm')) return Future.value(40.0);
    if (name.contains('getPrintMarginBottomMm')) return Future.value(25.0);
    if (name.contains('getPrintMarginLeftMm')) return Future.value(10.0);
    if (name.contains('getPrintMarginRightMm')) return Future.value(10.0);
    if (name.contains('getPrintContentScale')) return Future.value(100.0);
    if (name.contains('getSetting')) {
      return Future<String?>.value(
        settings[invocation.positionalArguments.first as SettingKey],
      );
    }
    return Future<void>.value();
  }
}

class _FakeCompanyInfoRepository implements CompanyInfoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(null);
}

class _FakeInvoiceRepository implements InvoiceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeInstallationRepository implements InstallationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('imported JSON is applied to the active PDF settings',
      (tester) async {
    final loader = FontLoader('DejaVuSans')
      ..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    await loader.load();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const layoutJson = '''
{
  "name": "Imported Brand",
  "description": "Imported from a file",
  "baseTemplate": "gridClassic",
  "pageSize": "a5",
  "themeColorHex": "#047857",
  "fontSize": "large",
  "printContentScale": 85
}
''';
    FilePicker.platform =
        _FakeFilePicker(Uint8List.fromList(utf8.encode(layoutJson)));

    final repo = _FakeSettingsRepository();
    BackendServices.configure(
      settings: repo,
      companyInfo: _FakeCompanyInfoRepository(),
      invoices: _FakeInvoiceRepository(),
      payments: _FakePaymentRepository(),
      installation: _FakeInstallationRepository(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'DejaVuSans'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PdfSettingsScreenV2(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Add Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Import from JSON File'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repo.layouts, hasLength(1));
    expect(repo.layouts.single.name, 'Imported Brand');
    // The renderer reads persisted settings, so importing must activate them.
    expect(repo.savedTemplate, InvoiceTemplate.gridClassic);
    expect(repo.savedPageSize, PageSize.a5);
    expect(repo.savedThemeColor, '#047857');
    expect(repo.clearedThemeColor, isFalse);
    // The name appears on the inserted-layout tile and in the Preview header.
    expect(find.text('Imported Brand'), findsWidgets);
  });

  testWidgets('imported block layout JSON becomes the active render layout',
      (tester) async {
    final loader = FontLoader('DejaVuSans')
      ..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    await loader.load();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const layoutJson = '''
{
  "name": "Imported Blocks",
  "description": "Block layout imported from a file",
  "page": { "size": "a5", "margin": 12 },
  "theme": { "primary": "#0F766E" },
  "layout": [
    {
      "type": "header",
      "left": { "companyName": "{{company.name}}" },
      "right": { "title": "{{invoice.title}}" }
    },
    { "type": "table" },
    {
      "type": "summary",
      "rows": [
        { "label": "Total", "value": "{{total}}", "highlight": true }
      ]
    }
  ]
}
''';
    FilePicker.platform =
        _FakeFilePicker(Uint8List.fromList(utf8.encode(layoutJson)));

    final repo = _FakeSettingsRepository();
    BackendServices.configure(
      settings: repo,
      companyInfo: _FakeCompanyInfoRepository(),
      invoices: _FakeInvoiceRepository(),
      payments: _FakePaymentRepository(),
      installation: _FakeInstallationRepository(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'DejaVuSans'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PdfSettingsScreenV2(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Add Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Import from JSON File'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repo.layouts, hasLength(1));
    final imported = repo.layouts.single;
    expect(imported.name, 'Imported Blocks');
    expect(imported.hasBlockLayout, isTrue);
    expect(imported.pageSize, PageSize.a5);
    expect(repo.savedPageSize, PageSize.a5);
    expect(repo.savedThemeColor, '#0F766E');

    // The renderer reads this key, not the in-memory screen state.
    final activeRaw = repo.settings[SettingKey.activeCustomLayout];
    expect(activeRaw, isNotNull);
    final active = CustomInvoiceLayout.fromJson(activeRaw!);
    expect(active.id, imported.id);
    expect(active.hasBlockLayout, isTrue);
    expect(active.blockLayout!['layout'], hasLength(3));

    // The name appears on the inserted-layout tile and in the Preview header.
    expect(find.text('Imported Blocks'), findsWidgets);
  });

  testWidgets('invalid JSON shows a simple error message and saves nothing',
      (tester) async {
    final loader = FontLoader('DejaVuSans')
      ..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    await loader.load();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    FilePicker.platform = _FakeFilePicker(
      Uint8List.fromList(utf8.encode('{ this is not json')),
    );

    final repo = _FakeSettingsRepository();
    BackendServices.configure(
      settings: repo,
      companyInfo: _FakeCompanyInfoRepository(),
      invoices: _FakeInvoiceRepository(),
      payments: _FakePaymentRepository(),
      installation: _FakeInstallationRepository(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'DejaVuSans'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PdfSettingsScreenV2(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Add Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Import from JSON File'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Error on JSON file'), findsOneWidget);
    expect(repo.layouts, isEmpty);
  });
}
