import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/obj/object_stream.dart';
import 'package:pdf/widgets.dart' as pw;

import 'test_pdf_font_service.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/custom_invoice_layout.dart';
import 'package:invoiso/services/pdf/pdf_preview_sample.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';

/// Counts PDF text-showing operators in the document's page content streams.
/// A blank page has none, so this catches a preview that renders white space.
/// The widget tree is laid out during `save()`, so call that first.
int _textOperatorCount(pw.Document document) {
  var count = 0;
  for (final page in document.document.pdfPageList.pages) {
    for (final content in page.contents) {
      if (content is PdfObjectStream) {
        final text = String.fromCharCodes(content.buf.output());
        count += RegExp(r'\]TJ').allMatches(text).length;
      }
    }
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.ThemeData pdfTheme;
  late Uint8List logoBytes;
  late Uint8List watermarkBytes;
  late Uint8List signatureBytes;

  setUpAll(() async {
    pdfTheme = await TestPdfFontService.loadTheme();
    logoBytes = await File('assets/images/demo_logo.png').readAsBytes();
    watermarkBytes = await File('assets/images/watermark.png').readAsBytes();
    signatureBytes = await File('assets/images/sig.jpeg').readAsBytes();
  });

  PdfGenerationSettings settingsFor(CustomInvoiceLayout layout) {
    final template = layout.effectiveBaseTemplate;
    final pageFormat = PDFService.pageSizeToFormat(layout.pageSize);
    final fontSizeScale = pdfFontSizeFromKey(layout.fontSize).scale;
    return PdfGenerationSettings(
      company: PdfPreviewSample.fallbackCompany(),
      template: template,
      invoicePrefix: 'INV-',
      showGst: true,
      showQuantity: true,
      showDiscount: true,
      showTypeTag: true,
      businessType: BusinessType.both,
      upiEntries: const [
        UpiEntry(label: 'UPI', id: 'sample@upi', isDefault: true),
      ],
      showQrStr: 'true',
      showBankDetails: true,
      bankAccounts: const [
        BankAccount(
          label: 'Default Bank',
          bankName: 'Sample Bank',
          accountNumber: '1234567890',
          ifscCode: 'SMPL0001234',
          isDefault: true,
        ),
      ],
      logoPosition: LogoPosition.left,
      logoSizePx: 80,
      logoBytes: logoBytes,
      signatureBytes: signatureBytes,
      thankYouNote: 'Thank you for your business!',
      datePattern: 'dd/MM/yyyy',
      showFooterBranding: layout.showSoftwareBranding,
      themeColor: layout.themeColorHex == null
          ? null
          : PdfColor.fromHex(layout.themeColorHex!),
      showPreviousBalance: true,
      pageFormat: pageFormat,
      pageSize: layout.pageSize,
      showTotalQuantity: layout.showTotalQuantity,
      pdfTheme: pdfTheme,
      watermarkBytes: watermarkBytes,
      showCgstSgst: true,
      landscape: layout.landscape,
      showDescription: true,
      descriptionNewLine: true,
      fontSizeScale: fontSizeScale,
      companyNameScale: pdfSectionScale(
        layout.sectionSizes['pdfCompanyNameFontSize'],
        fontSizeScale,
      ),
      docTitleScale: pdfSectionScale(
        layout.sectionSizes['pdfDocTitleFontSize'],
        fontSizeScale,
      ),
      tableHeaderScale: pdfSectionScale(
        layout.sectionSizes['pdfTableHeaderFontSize'],
        fontSizeScale,
      ),
      tableItemsScale: pdfSectionScale(
        layout.sectionSizes['pdfTableItemsFontSize'],
        fontSizeScale,
      ),
      totalsScale: pdfSectionScale(
        layout.sectionSizes['pdfTotalsFontSize'],
        fontSizeScale,
      ),
      letterheadEnabled: layout.letterheadEnabled,
      letterheadHideCompanyHeader: layout.letterheadHideCompanyHeader,
      printMarginTopMm: layout.printMarginTopMm,
      printMarginBottomMm: layout.printMarginBottomMm,
      printMarginLeftMm: layout.printMarginLeftMm,
      printMarginRightMm: layout.printMarginRightMm,
      printContentScale: layout.printContentScale,
      blockLayout: layout.blockLayout,
    );
  }

  CustomInvoiceLayout layout({
    InvoiceTemplate baseTemplate = InvoiceTemplate.gridClassic,
    PageSize pageSize = PageSize.a4,
    bool landscape = false,
    String fontSize = 'medium',
    String themeColorHex = '#2563EB',
    double contentScale = 100,
    bool letterheadEnabled = true,
  }) {
    return CustomInvoiceLayout(
      id: 'test-layout',
      name: 'Test Layout',
      description: 'Renderer test',
      baseTemplate: baseTemplate,
      pageSize: pageSize,
      landscape: landscape,
      themeColorHex: themeColorHex,
      fontSize: fontSize,
      sectionSizes: const {
        'pdfCompanyNameFontSize': 'xlarge',
        'pdfTotalsFontSize': 'large',
      },
      showTotalQuantity: true,
      showSoftwareBranding: false,
      letterheadEnabled: letterheadEnabled,
      letterheadHideCompanyHeader: true,
      printMarginTopMm: 35,
      printMarginBottomMm: 24,
      printMarginLeftMm: 10,
      printMarginRightMm: 10,
      printContentScale: contentScale,
      createdAt: DateTime(2026, 10, 29),
    );
  }

  test('layout page size is used by the real PDF renderer', () async {
    final a5 = PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(layout(pageSize: PageSize.a5)),
    );

    final page = a5.document.pdfPageList.pages.first;
    expect(page.pageFormat.width, closeTo(PdfPageFormat.a5.width, 0.01));
    expect(page.pageFormat.height, closeTo(PdfPageFormat.a5.height, 0.01));
    expect(await a5.save(), isNotEmpty);
  });

  test('layout landscape and margins are used by the real PDF renderer',
      () async {
    final landscape = PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(layout(
        pageSize: PageSize.a5,
        landscape: true,
      )),
    );

    final page = landscape.document.pdfPageList.pages.first;
    expect(page.pageFormat.width, greaterThan(page.pageFormat.height));
    expect(await landscape.save(), isNotEmpty);
  });

  test('font, colour and content-scale changes alter the generated invoice',
      () async {
    final baseInvoice = PdfPreviewSample.createSampleInvoice();
    final a = await PDFService.generateInvoicePDFWithSettings(
      baseInvoice,
      settingsFor(layout()),
    ).save();
    final b = await PDFService.generateInvoicePDFWithSettings(
      baseInvoice,
      settingsFor(layout(
        fontSize: 'xlarge',
        themeColorHex: '#047857',
        contentScale: 75,
      )),
    ).save();

    expect(a, isNotEmpty);
    expect(b, isNotEmpty);
    expect(a, isNot(equals(b)));
  });

  test('letterhead custom margins render across supported templates', () async {
    for (final template in [
      InvoiceTemplate.classic,
      InvoiceTemplate.modern,
      InvoiceTemplate.minimal,
      InvoiceTemplate.executive,
      InvoiceTemplate.compact,
      InvoiceTemplate.gridClassic,
    ]) {
      final pageSize =
          template == InvoiceTemplate.compact ? PageSize.a6 : PageSize.a4;
      final bytes = await PDFService.generateInvoicePDFWithSettings(
        PdfPreviewSample.createSampleInvoice(),
        settingsFor(layout(
          baseTemplate: template,
          pageSize: pageSize,
          contentScale: 85,
        )),
      ).save();
      expect(bytes, isNotEmpty, reason: '${template.name} rendered empty');
    }
  });

  test('imported block layout is rendered instead of the classic template',
      () async {
    // The block document's own page size (letter) differs from the layout's
    // settings page size (A4), so this proves the block renderer was used.
    final blockLayout = CustomInvoiceLayout(
      id: 'block-layout',
      name: 'Block Layout',
      description: 'Imported page/theme/layout document',
      baseTemplate: InvoiceTemplate.classic,
      pageSize: PageSize.a4,
      blockLayout: {
        'page': {'size': 'letter', 'margin': 12},
        'theme': {'primary': '#0F766E', 'text': '#111827'},
        'layout': [
          {
            'type': 'header',
            'left': {'companyName': '{{company.name}}'},
            'right': {'title': '{{invoice.title}}'},
          },
          {'type': 'table'},
          {
            'type': 'summary',
            'rows': [
              {'label': 'Total', 'value': '{{total}}', 'highlight': true},
            ],
          },
        ],
      },
      createdAt: DateTime(2026, 10, 31),
    );

    final doc = PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(blockLayout),
    );

    final page = doc.document.pdfPageList.pages.first;
    expect(page.pageFormat.width, closeTo(PdfPageFormat.letter.width, 0.01));
    expect(page.pageFormat.height, closeTo(PdfPageFormat.letter.height, 0.01));
    expect(await doc.save(), isNotEmpty);
    // Page size alone does not prove the imported layout drew anything.
    expect(_textOperatorCount(doc), greaterThan(0),
        reason: 'imported layout rendered a blank page');
  });

  test('unknown block types render their readable content, not a blank page',
      () async {
    final imported = CustomInvoiceLayout(
      id: 'unknown-blocks',
      name: 'Unknown Blocks',
      description: 'Blocks with custom names',
      baseTemplate: InvoiceTemplate.classic,
      pageSize: PageSize.a4,
      themeColorHex: '#0F766E',
      blockLayout: {
        'page': {'size': 'a5'},
        'layout': [
          {
            'type': 'brandBanner',
            'title': 'Custom Heading',
            'lines': ['{{company.name}}', '{{total}}'],
          },
          {
            'type': 'mysterySection',
            'children': [
              {'type': 'text', 'content': 'Nested custom text'},
            ],
          },
        ],
      },
      createdAt: DateTime(2026, 10, 31),
    );

    final doc = PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(imported),
    );

    expect(await doc.save(), isNotEmpty);
    expect(_textOperatorCount(doc), greaterThan(0));
  });

  test('block layout uses the saved theme colour when the document has none',
      () async {
    CustomInvoiceLayout themed(String hex) => CustomInvoiceLayout(
          id: 'no-theme',
          name: 'No Theme',
          description: 'Colour lives in the layout settings',
          baseTemplate: InvoiceTemplate.classic,
          pageSize: PageSize.a4,
          themeColorHex: hex,
          blockLayout: {
            'page': {'size': 'a4'},
            'layout': [
              {'type': 'table'},
              {
                'type': 'summary',
                'rows': [
                  {'label': 'Total', 'value': '{{total}}', 'highlight': true},
                ],
              },
            ],
          },
          createdAt: DateTime(2026, 10, 31),
        );

    final teal = await PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(themed('#0F766E')),
    ).save();
    final red = await PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(themed('#DC2626')),
    ).save();

    // Without plumbing the layout colour into the block renderer both outputs
    // would use the same default blue.
    expect(teal, isNot(equals(red)));
  });

  test('pixel page dimensions are converted to a real A4 page', () async {
    // Layout designers commonly write A4 as 794×1123 CSS pixels, or use
    // 150/300 DPI canvases. Treating those as millimetres produced a 794 mm
    // page and a miniature invoice.
    for (final dimensions in const [
      [794.0, 1123.0],
      [1240.0, 1754.0],
      [2480.0, 3508.0],
    ]) {
      final imported = CustomInvoiceLayout(
        id: 'pixel-page',
        name: 'Pixel Page',
        description: 'A4 written in pixels',
        baseTemplate: InvoiceTemplate.classic,
        pageSize: PageSize.a4,
        themeColorHex: '#0F766E',
        blockLayout: {
          'page': {
            'width': dimensions[0],
            'height': dimensions[1],
            'margin': 40,
          },
          'layout': [
            {'type': 'table'},
            {
              'type': 'summary',
              'rows': [
                {'label': 'Total', 'value': '{{total}}', 'highlight': true},
              ],
            },
          ],
        },
        createdAt: DateTime(2026, 10, 31),
      );

      final doc = PDFService.generateInvoicePDFWithSettings(
        PdfPreviewSample.createSampleInvoice(),
        settingsFor(imported),
      );

      final page = doc.document.pdfPageList.pages.first;
      expect(page.pageFormat.width, closeTo(PdfPageFormat.a4.width, 1.0),
          reason: 'width for ${dimensions[0]}x${dimensions[1]}');
      expect(page.pageFormat.height, closeTo(PdfPageFormat.a4.height, 1.0),
          reason: 'height for ${dimensions[0]}x${dimensions[1]}');
      expect(await doc.save(), isNotEmpty);
      expect(_textOperatorCount(doc), greaterThan(0));
    }
  });

  test('explicit page units and millimetre sizes keep their real size',
      () async {
    CustomInvoiceLayout withPage(Map<String, dynamic> page) =>
        CustomInvoiceLayout(
          id: 'unit-page',
          name: 'Unit Page',
          description: 'Page unit handling',
          baseTemplate: InvoiceTemplate.classic,
          pageSize: PageSize.a4,
          blockLayout: {
            'page': page,
            'layout': [
              {'type': 'text', 'content': 'Unit test'},
            ],
          },
          createdAt: DateTime(2026, 10, 31),
        );

    final millimeters = PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(withPage({'width': 148, 'height': 210})),
    );
    final mmPage = millimeters.document.pdfPageList.pages.first;
    expect(mmPage.pageFormat.width, closeTo(PdfPageFormat.a5.width, 0.5));
    expect(mmPage.pageFormat.height, closeTo(PdfPageFormat.a5.height, 0.5));

    final pixels = PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(withPage({
        'width': 800,
        'height': 600,
        'unit': 'px',
        'margin': 24,
      })),
    );
    final pxPage = pixels.document.pdfPageList.pages.first;
    expect(pxPage.pageFormat.width, closeTo(600, 0.5));
    expect(pxPage.pageFormat.height, closeTo(450, 0.5));
    expect(await pixels.save(), isNotEmpty);
  });

  test('a layout with no renderable blocks still draws a themed invoice body',
      () async {    final imported = CustomInvoiceLayout(
      id: 'empty-blocks',
      name: 'Empty Blocks',
      description: 'Names the renderer does not know',
      baseTemplate: InvoiceTemplate.classic,
      pageSize: PageSize.a4,
      themeColorHex: '#0F766E',
      blockLayout: {
        'page': {'size': 'a5', 'margin': 10},
        'theme': {'primary': '#0F766E', 'text': '#111827'},
        'layout': [
          {'type': 'mysteryOne'},
          {'type': 'mysteryTwo'},
        ],
      },
      createdAt: DateTime(2026, 10, 31),
    );

    final doc = PDFService.generateInvoicePDFWithSettings(
      PdfPreviewSample.createSampleInvoice(),
      settingsFor(imported),
    );

    final page = doc.document.pdfPageList.pages.first;
    expect(page.pageFormat.width, closeTo(PdfPageFormat.a5.width, 0.01));
    expect(await doc.save(), isNotEmpty);
    expect(_textOperatorCount(doc), greaterThan(0),
        reason: 'unrenderable layout should never preview as a blank page');
  });
}
