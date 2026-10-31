import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_info.dart';
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
import 'package:invoiso/widgets/template_list_tile.dart';

class FakeSettingsRepository implements SettingsRepository {
  final List<CustomInvoiceLayout> layouts = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('getCustomInvoiceLayouts')) {
      return Future.value(List<CustomInvoiceLayout>.of(layouts));
    }
    if (name.contains('saveCustomInvoiceLayouts')) {
      final list = invocation.positionalArguments.first as List<CustomInvoiceLayout>;
      layouts
        ..clear()
        ..addAll(list);
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
    if (name.contains('getShowInvoiceFooterBranding')) return Future.value(true);
    if (name.contains('getShow') || name.contains('getWatermarkFullPage')) {
      return Future.value(false);
    }
    if (name.contains('getLetterheadEnabled')) return Future.value(false);
    if (name.contains('getLetterheadHideCompanyHeader')) return Future.value(true);
    if (name.contains('getPrintMarginTopMm')) return Future.value(40.0);
    if (name.contains('getPrintMarginBottomMm')) return Future.value(25.0);
    if (name.contains('getPrintMarginLeftMm')) return Future.value(10.0);
    if (name.contains('getPrintMarginRightMm')) return Future.value(10.0);
    if (name.contains('getPrintContentScale')) return Future.value(100.0);
    if (name.contains('getSetting')) return Future<String?>.value(null);
    return Future<void>.value();
  }
}

class FakeCompanyInfoRepository implements CompanyInfoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<CompanyInfo?>.value(null);
}

class FakeInvoiceRepository implements InvoiceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakePaymentRepository implements PaymentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeInstallationRepository implements InstallationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('add layout from current settings appears in list', (tester) async {
    final loader = FontLoader('DejaVuSans')
      ..addFont(rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    await loader.load();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeSettingsRepository();
    BackendServices.configure(
      settings: repo,
      companyInfo: FakeCompanyInfoRepository(),
      invoices: FakeInvoiceRepository(),
      payments: FakePaymentRepository(),
      installation: FakeInstallationRepository(),
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

    debugPrint('templates label size: ${tester.getSize(find.text('TEMPLATES'))}');
    debugPrint('add layout size: ${tester.getSize(find.text('Add Layout'))}');

    expect(find.text('Add Layout'), findsOneWidget);
    await tester.tap(find.text('Add Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Save Current Settings as Layout'), findsOneWidget);
    await tester.tap(find.text('Save Current Settings as Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Save as Custom Layout'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Layout Name'), 'Test Layout');
    await tester.tap(find.text('Save Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repo.layouts, hasLength(1));
    // The name appears on the inserted-layout tile and in the Preview header.
    expect(find.text('Test Layout'), findsWidgets);
    expect(find.text('YOUR INSERTED LAYOUTS'), findsOneWidget);

    // Edit the inserted layout through the JSON editor.
    await tester.tap(find.byTooltip('Edit layout JSON'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Edit Layout JSON'), findsOneWidget);
    await tester.tap(find.text('Save & Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.layouts, hasLength(1));

    // Add a second layout through the JSON editor.
    await tester.tap(find.text('Add Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Create / Edit JSON'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create Layout from JSON'), findsOneWidget);
    await tester.tap(find.text('Save & Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.layouts, hasLength(2));

    // Remove it again.
    await tester.tap(find.descendant(
      of: find.widgetWithText(TemplateListTile, 'Test Layout'),
      matching: find.byTooltip('Remove inserted layout'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Only the first layout is removed; the second JSON-created layout stays.
    expect(repo.layouts, hasLength(1));
    expect(repo.layouts.single.name, 'My Custom Layout');
    expect(find.text('Test Layout'), findsNothing);
  });
}
