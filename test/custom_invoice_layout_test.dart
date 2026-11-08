import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/custom_invoice_layout.dart';

void main() {
  CustomInvoiceLayout sample() => CustomInvoiceLayout(
        id: 'layout-1',
        name: 'Grid Branded',
        description: 'A saved grid layout',
        baseTemplate: InvoiceTemplate.gridClassic,
        pageSize: PageSize.a5,
        landscape: true,
        themeColorHex: '#2563EB',
        fontSize: 'large',
        sectionSizes: const {
          'pdfCompanyNameFontSize': 'xlarge',
          'pdfTotalsFontSize': 'small',
        },
        showTotalQuantity: true,
        showSoftwareBranding: false,
        letterheadEnabled: true,
        letterheadHideCompanyHeader: false,
        printMarginTopMm: 32,
        printMarginBottomMm: 22,
        printMarginLeftMm: 9,
        printMarginRightMm: 11,
        printContentScale: 85,
        thermalWidthMargin: '2',
        thermalItemLayout: 'detailed',
        thermalCompanyNameSize: 'large',
        createdAt: DateTime(2026, 10, 29, 10, 30),
      );

  group('CustomInvoiceLayout JSON', () {
    test('accepts partial layouts that omit template and page size', () {
      // A layout that only overrides theme/margins must be importable instead
      // of being rejected (which left the screen on the default theme).
      final decoded = CustomInvoiceLayout.fromJson(jsonEncode({
        'name': 'Theme only',
        'themeColorHex': '#047857',
        'printContentScale': 85,
      }));

      expect(decoded.baseTemplate, InvoiceTemplate.classic);
      expect(decoded.pageSize, PageSize.a4);
      expect(decoded.themeColorHex, '#047857');
      expect(decoded.printContentScale, 85);
    });

    test('accepts the human-readable settings/letterhead layout format', () {
      final decoded = CustomInvoiceLayout.fromJson(jsonEncode({
        'name': 'Corporate Navy',
        'description': 'Settings-only import',
        'baseTemplate': 'classic',
        'pageSize': 'a4',
        'orientation': 'landscape',
        'themeColor': '#002E78',
        'fontSize': 'small',
        'sectionSizes': {
          'companyName': 'large',
          'tableItems': 'small',
          'totals': 'medium',
        },
        'displayOptions': {
          'showTotalQuantity': true,
          'showSoftwareBranding': false,
        },
        'letterhead': {
          'enabled': true,
          'hideCompanyHeader': false,
          'marginTopMm': 32,
          'marginBottomMm': 22,
          'marginLeftMm': 9,
          'marginRightMm': 11,
          'contentScale': 85,
        },
      }));

      expect(decoded.themeColorHex, '#002E78');
      expect(decoded.fontSize, 'small');
      expect(decoded.landscape, isTrue);
      expect(decoded.showTotalQuantity, isTrue);
      expect(decoded.showSoftwareBranding, isFalse);
      expect(decoded.letterheadEnabled, isTrue);
      expect(decoded.letterheadHideCompanyHeader, isFalse);
      expect(decoded.printMarginTopMm, 32);
      expect(decoded.printMarginBottomMm, 22);
      expect(decoded.printMarginLeftMm, 9);
      expect(decoded.printMarginRightMm, 11);
      expect(decoded.printContentScale, 85);
      expect(decoded.sectionSizes, {
        'pdfCompanyNameFontSize': 'large',
        'pdfTableItemsFontSize': 'small',
        'pdfTotalsFontSize': 'medium',
      });
    });

    test('uses the block document theme when no themeColorHex is stored', () {
      final decoded = CustomInvoiceLayout.fromJson(jsonEncode({
        'name': 'Block themed',
        'theme': {'primary': '#7C2D12'},
        'layout': [
          {'type': 'header'},
        ],
      }));

      expect(decoded.themeColorHex, '#7C2D12');
      expect(decoded.effectiveThemeColorHex, '#7C2D12');
    });

    test('normalises human-readable template and paper names', () {
      final grid = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'Grid Classic',
        'pageSize': 'A5',
      }));
      expect(grid.baseTemplate, InvoiceTemplate.gridClassic);
      expect(grid.pageSize, PageSize.a5);

      final thermal = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'thermal-receipt',
        'pageSize': '80mm',
      }));
      expect(thermal.baseTemplate, InvoiceTemplate.thermal);
      expect(thermal.pageSize, PageSize.thermal80);
    });

    test('round-trips every configurable field through JSON', () {
      final original = sample();
      final decoded = CustomInvoiceLayout.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.description, original.description);
      expect(decoded.baseTemplate, original.baseTemplate);
      expect(decoded.pageSize, original.pageSize);
      expect(decoded.landscape, original.landscape);
      expect(decoded.themeColorHex, original.themeColorHex);
      expect(decoded.fontSize, original.fontSize);
      expect(decoded.sectionSizes, original.sectionSizes);
      expect(decoded.showTotalQuantity, original.showTotalQuantity);
      expect(decoded.showSoftwareBranding, original.showSoftwareBranding);
      expect(decoded.letterheadEnabled, original.letterheadEnabled);
      expect(
        decoded.letterheadHideCompanyHeader,
        original.letterheadHideCompanyHeader,
      );
      expect(decoded.printMarginTopMm, original.printMarginTopMm);
      expect(decoded.printMarginBottomMm, original.printMarginBottomMm);
      expect(decoded.printMarginLeftMm, original.printMarginLeftMm);
      expect(decoded.printMarginRightMm, original.printMarginRightMm);
      expect(decoded.printContentScale, original.printContentScale);
      expect(decoded.thermalWidthMargin, original.thermalWidthMargin);
      expect(decoded.thermalItemLayout, original.thermalItemLayout);
      expect(decoded.thermalCompanyNameSize, original.thermalCompanyNameSize);
      expect(decoded.createdAt, original.createdAt);
    });

    test('accepts numeric strings and normalises the colour', () {
      final decoded = CustomInvoiceLayout.fromJson(jsonEncode({
        'name': 'Lenient',
        'baseTemplate': 'classic',
        'pageSize': 'a4',
        'themeColorHex': '2563eb',
        'printMarginTopMm': '20',
        'printContentScale': '90',
        'createdAt': '2026-10-29T10:30:00.000',
      }));

      expect(decoded.pageSize, PageSize.a4);
      expect(decoded.themeColorHex, '#2563EB');
      expect(decoded.printMarginTopMm, 20);
      expect(decoded.printContentScale, 90);
    });

    test('normalises an incompatible template/page-size pair on apply', () {
      final decoded = CustomInvoiceLayout.fromJson(jsonEncode({
        'name': 'Thermal on A4',
        'baseTemplate': 'thermal',
        'pageSize': 'a4',
      }));

      // Thermal only supports 80mm/58mm; the renderer must fall back to the
      // normal A4 template rather than emitting an invalid receipt page.
      expect(decoded.baseTemplate, InvoiceTemplate.thermal);
      expect(decoded.effectiveBaseTemplate, InvoiceTemplate.classic);
    });

    test('reports malformed JSON with a simple message', () {
      expect(
        () => CustomInvoiceLayout.fromJson('{ not json'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Error on JSON file',
          ),
        ),
      );
    });

    test('accepts a bare block array and rejects only primitive roots', () {
      final array = CustomInvoiceLayout.fromJson(jsonEncode([
        {'type': 'header'},
        {'type': 'table'},
      ]));
      expect(array.hasBlockLayout, isTrue);
      expect((array.blockLayout?['layout'] as List), hasLength(2));

      // An empty array is still a design document, so it gets a usable
      // default structure instead of falling back to Classic.
      final empty = CustomInvoiceLayout.fromJson('[]');
      expect(empty.hasBlockLayout, isTrue);

      expect(
        () => CustomInvoiceLayout.fromJson('42'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Error on JSON file',
          ),
        ),
      );
    });

    test('accepts block layouts under renamed keys and named sections', () {
      final sections = CustomInvoiceLayout.fromJson(jsonEncode({
        'page': {'size': 'a5'},
        'sections': [
          {'type': 'header'},
          {'type': 'table'},
        ],
      }));
      expect(sections.hasBlockLayout, isTrue);
      expect(sections.pageSize, PageSize.a5);

      final named = CustomInvoiceLayout.fromJson(jsonEncode({
        'header': {'title': 'My Invoice'},
        'table': {},
      }));
      expect(named.hasBlockLayout, isTrue);
      expect((named.blockLayout?['layout'] as List), hasLength(2));

      final nestedNamed = CustomInvoiceLayout.fromJson(jsonEncode({
        'layout': {
          'header': {'title': 'Nested Invoice'},
          'table': {},
        },
      }));
      expect(nestedNamed.hasBlockLayout, isTrue);
      expect((nestedNamed.blockLayout?['layout'] as List), hasLength(2));

      final singleBlock = CustomInvoiceLayout.fromJson(jsonEncode({
        'type': 'header',
        'left': {'companyName': '{{company.name}}'},
      }));
      expect(singleBlock.hasBlockLayout, isTrue);
      expect((singleBlock.blockLayout?['layout'] as List), hasLength(1));

      // A design that only sets page/theme still renders as a custom block
      // layout instead of silently using the built-in Classic template.
      final pageOnly = CustomInvoiceLayout.fromJson(jsonEncode({
        'page': {'size': 'a4'},
        'theme': {'primary': '#123456'},
      }));
      expect(pageOnly.hasBlockLayout, isTrue);
      expect(pageOnly.themeColorHex, '#123456');
    });

    test('named section aliases keep their own blocks, not the defaults', () {
      final layout = CustomInvoiceLayout.fromJson(jsonEncode({
        'page': {'size': 'a4'},
        'theme': {'primary': '#0F766E'},
        'layout': {
          'Bill To': {
            'fields': ['{{customer.name}}', '{{customer.address}}'],
          },
          'bank_details': {
            'fields': ['{{bank.name}}', '{{bank.account}}'],
          },
          'items': <String, dynamic>{},
          'notes': {'content': 'Thank you for your business'},
        },
      }));

      expect(layout.hasBlockLayout, isTrue);
      final blocks = (layout.blockLayout!['layout'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        blocks.map((block) => block['type']),
        containsAll(['billto', 'bankdetails', 'items', 'notes']),
      );
      expect(blocks, hasLength(4));
      final billTo = blocks.firstWhere((block) => block['type'] == 'billto');
      expect(billTo['fields'], contains('{{customer.name}}'));
      // A page/theme document used to replace unknown sections with the
      // default invoice body; the actual imported sections must win.
      expect(blocks.any((block) => block['type'] == 'header'), isFalse);
    });

    test('falls back to safe defaults for unknown enum values', () {
      final unknownTemplate = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'not-a-template',
        'pageSize': 'a4',
      }));
      expect(unknownTemplate.baseTemplate, InvoiceTemplate.classic);

      final unknownPageSize = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'classic',
        'pageSize': 'not-a-size',
      }));
      expect(unknownPageSize.pageSize, PageSize.a4);
    });

    test('falls back to safe defaults for invalid colour, font and sizes', () {
      final badColor = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'classic',
        'themeColorHex': 'blue',
      }));
      expect(badColor.themeColorHex, isNull);

      final badFont = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'classic',
        'fontSize': 'huge',
      }));
      expect(badFont.fontSize, 'medium');

      final badSections = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'classic',
        'sectionSizes': {'notARealSetting': 'large'},
      }));
      expect(badSections.sectionSizes, isEmpty);
    });

    test('keeps oversized margins instead of rejecting the layout', () {
      final decoded = CustomInvoiceLayout.fromJson(jsonEncode({
        'baseTemplate': 'classic',
        'pageSize': 'a4',
        'printMarginTopMm': 200,
        'printMarginBottomMm': 100,
      }));

      expect(decoded.printMarginTopMm, 200);
      expect(decoded.printMarginBottomMm, 100);
    });

    test('ignores unknown keys, so unrelated data cannot execute or leak in',
        () {
      final decoded = CustomInvoiceLayout.fromJson(jsonEncode({
        'name': 'Safe',
        'baseTemplate': 'classic',
        'pageSize': 'a4',
        'command': r'rm -rf /',
        'script': 'alert(1)',
      }));

      expect(decoded.name, 'Safe');
      expect(decoded.toMap().containsKey('command'), isFalse);
      expect(decoded.toMap().containsKey('script'), isFalse);
    });

    test('lenient fromMap keeps loading old layouts with bad optional values',
        () {
      final decoded = CustomInvoiceLayout.fromMap({
        'name': 'Legacy',
        'baseTemplate': 'classic',
        'pageSize': 'a4',
        'fontSize': 'gigantic',
        'themeColorHex': 'not-a-colour',
        'printMarginTopMm': 'not-a-number',
      });

      expect(decoded.fontSize, 'medium');
      expect(decoded.themeColorHex, isNull);
      expect(decoded.printMarginTopMm, 40);
    });
  });

  group('CustomInvoiceLayout persistence', () {
    late Database db;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DatabaseHelper().dbVersion,
          onCreate: (d, v) => DatabaseHelper().createDbForTest(d, v),
        ),
      );
      DatabaseHelper.setTestDatabase(db);
    });

    tearDown(() async {
      DatabaseHelper.setTestDatabase(null);
      await db.close();
    });

    test('saves a layout and reloads every field', () async {
      await SettingsService.saveCustomInvoiceLayouts([sample()]);
      final loaded = await SettingsService.getCustomInvoiceLayouts();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'layout-1');
      expect(loaded.single.name, 'Grid Branded');
      expect(loaded.single.baseTemplate, InvoiceTemplate.gridClassic);
      expect(loaded.single.pageSize, PageSize.a5);
      expect(loaded.single.landscape, isTrue);
      expect(loaded.single.themeColorHex, '#2563EB');
      expect(loaded.single.printContentScale, 85);
      expect(loaded.single.createdAt, DateTime(2026, 10, 29, 10, 30));
    });

    test('updates a layout in place without duplicating it', () async {
      final original = sample();
      await SettingsService.saveCustomInvoiceLayouts([original]);

      final edited =
          original.copyWith(name: 'Grid Branded v2', fontSize: 'small');
      await SettingsService.saveCustomInvoiceLayouts([edited]);
      final loaded = await SettingsService.getCustomInvoiceLayouts();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, original.id);
      expect(loaded.single.name, 'Grid Branded v2');
      expect(loaded.single.fontSize, 'small');
      expect(loaded.single.createdAt, original.createdAt);
    });

    test('skips unusable stored entries without hiding valid layouts',
        () async {
      await SettingsService.setSetting(
        SettingKey.customInvoiceLayouts,
        jsonEncode([
          sample().toMap(),
          'not-an-object',
          null,
          42,
          {'baseTemplate': 'classic', 'name': 'Still Fine'},
        ]),
      );

      final loaded = await SettingsService.getCustomInvoiceLayouts();

      expect(loaded.map((l) => l.name), ['Grid Branded', 'Still Fine']);
    });

    test('keeps loading a stored layout whose template name is unknown',
        () async {
      // A layout saved by an older/newer build must not hide the rest of the
      // list; unknown enum values fall back to the classic renderer.
      await SettingsService.setSetting(
        SettingKey.customInvoiceLayouts,
        jsonEncode([
          {'name': 'Legacy', 'baseTemplate': 'retired-template'},
          {'name': 'Modern', 'baseTemplate': 'gridClassic'},
        ]),
      );

      final loaded = await SettingsService.getCustomInvoiceLayouts();

      expect(loaded.map((l) => l.name), ['Legacy', 'Modern']);
      expect(loaded.first.baseTemplate, InvoiceTemplate.classic);
    });

    test('returns an empty list instead of throwing on unusable storage',
        () async {
      await SettingsService.setSetting(
        SettingKey.customInvoiceLayouts,
        '{ this is not json',
      );

      expect(await SettingsService.getCustomInvoiceLayouts(), isEmpty);

      await SettingsService.setSetting(
        SettingKey.customInvoiceLayouts,
        jsonEncode({'name': 'object not list'}),
      );

      expect(await SettingsService.getCustomInvoiceLayouts(), isEmpty);
    });
  });
}
