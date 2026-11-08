import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'test_pdf_font_service.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';

final _company = CompanyInfo(
  name: 'ACME INDUSTRIAL SUPPLIES LTD',
  address: '123 INDUSTRIAL AVENUE, TECH PARK',
  phone: '+91 9876543210',
  email: 'billing@acmeindustrial.com',
  website: 'https://acmeindustrial.com',
  gstin: '32AAACA1234A1Z5',
  fssaiCode: '10012011000123',
  panNumber: 'AAACA1234A',
  country: 'India',
);

List<InvoiceItem> _sampleItems({int count = 20}) => List.generate(count, (i) {
      final product = Product(
        id: 'p${i + 1}',
        name: 'PRECISION VALVE ASSEMBLY ${i + 1}',
        description: 'Industrial grade stainless steel 316, batch #${i + 100}.',
        price: 450.0 + i * 15,
        stock: 50,
        hsncode: '8481',
        tax_rate: 18,
      );
      return InvoiceItem(product: product, quantity: 1 + (i % 4));
    });

Invoice _sampleInvoice({int itemCount = 20}) {
  return Invoice(
    id: 'inv-letterhead-test-1',
    invoiceNumber: 'INV-2026-089',
    customer: Customer(
      id: 'cust-101',
      name: 'BHARAT ENGINEERING WORKS',
      businessName: 'Bharat Engineering Works Pvt Ltd',
      email: 'procurement@bharateng.com',
      phone: '+91 9123456789',
      address: 'Plot 45, MIDC Industrial Area, Pune, Maharashtra - 411018',
      gstin: '27AABCB9876B1Z2',
    ),
    items: _sampleItems(count: itemCount),
    date: DateTime(2026, 10, 28, 14, 30, 0),
    type: 'Invoice',
    taxRate: 0.18,
    taxMode: TaxMode.perItem,
    notes: 'Goods once sold will not be taken back without prior written inspection approval.\nSubject to local jurisdiction.',
  );
}

PageSize _pageSizeFor(InvoiceTemplate template) => switch (template) {
      InvoiceTemplate.compact => PageSize.a6,
      InvoiceTemplate.thermal => PageSize.thermal80,
      _ => PageSize.a4,
    };

PdfGenerationSettings _createSettings({
  required InvoiceTemplate template,
  required pw.ThemeData pdfTheme,
  required Uint8List logoBytes,
  required Uint8List watermarkBytes,
  required Uint8List signatureBytes,
  bool letterheadEnabled = false,
  bool letterheadHideCompanyHeader = true,
  double printMarginTopMm = 40.0,
  double printMarginBottomMm = 25.0,
  double printMarginLeftMm = 10.0,
  double printMarginRightMm = 10.0,
  double printContentScale = 100.0,
  bool showFooterBranding = true,
}) {
  final pageSize = _pageSizeFor(template);
  return PdfGenerationSettings(
    company: _company,
    template: template,
    invoicePrefix: 'INV-',
    showGst: true,
    showQuantity: true,
    showDiscount: true,
    showTypeTag: true,
    businessType: BusinessType.both,
    upiEntries: const [
      UpiEntry(label: 'HDFC', id: 'acme@okhdfcbank', isDefault: true),
    ],
    showQrStr: 'true',
    showBankDetails: true,
    bankAccounts: const [
      BankAccount(
        label: 'Corporate Current',
        bankName: 'HDFC Bank',
        accountNumber: '50200012345678',
        ifscCode: 'HDFC0000123',
        isDefault: true,
      ),
    ],
    logoPosition: LogoPosition.left,
    logoSizePx: 80,
    logoBytes: logoBytes,
    signatureBytes: signatureBytes,
    thankYouNote: 'Thank you for your business!',
    datePattern: 'dd/MM/yyyy',
    showFooterBranding: showFooterBranding,
    themeColor: null,
    showPreviousBalance: true,
    pageFormat: PDFService.pageSizeToFormat(pageSize),
    pageSize: pageSize,
    showTotalQuantity: true,
    pdfTheme: pdfTheme,
    watermarkBytes: watermarkBytes,
    watermarkOpacity: 0.05,
    signaturePosition: 'right',
    descriptionNewLine: true,
    showCgstSgst: true,
    showDescription: true,
    letterheadEnabled: letterheadEnabled,
    letterheadHideCompanyHeader: letterheadHideCompanyHeader,
    printMarginTopMm: printMarginTopMm,
    printMarginBottomMm: printMarginBottomMm,
    printMarginLeftMm: printMarginLeftMm,
    printMarginRightMm: printMarginRightMm,
    printContentScale: printContentScale,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const supportedTemplates = [
    InvoiceTemplate.classic,
    InvoiceTemplate.modern,
    InvoiceTemplate.minimal,
    InvoiceTemplate.executive,
    InvoiceTemplate.compact,
    InvoiceTemplate.gridClassic,
  ];

  group('Pre-printed Letterhead Mode and Print Customization', () {
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

    for (final template in supportedTemplates) {
      test(
          '${template.name} renders in letterhead mode with custom margins and scale',
          () async {
        final settings = _createSettings(
          template: template,
          pdfTheme: pdfTheme,
          logoBytes: logoBytes,
          watermarkBytes: watermarkBytes,
          signatureBytes: signatureBytes,
          letterheadEnabled: true,
          letterheadHideCompanyHeader: true,
          printMarginTopMm: 45.0,
          printMarginBottomMm: 30.0,
          printMarginLeftMm: 12.0,
          printMarginRightMm: 12.0,
          printContentScale: 85.0,
          showFooterBranding: false, // Software branding removed
        );

        final pdf = PDFService.generateInvoicePDFWithSettings(
          _sampleInvoice(itemCount: 15),
          settings,
          previousBalanceDue: 120.0,
        );

        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(1000));

        final outDir = Directory('output/pdf_letterhead_test');
        if (!outDir.existsSync()) {
          outDir.createSync(recursive: true);
        }
        await File('${outDir.path}/letterhead_${template.name}_scale85.pdf')
            .writeAsBytes(bytes);
      });

      test(
          '${template.name} preserves standard layout when letterhead mode is disabled (backward compatibility)',
          () async {
        final settings = _createSettings(
          template: template,
          pdfTheme: pdfTheme,
          logoBytes: logoBytes,
          watermarkBytes: watermarkBytes,
          signatureBytes: signatureBytes,
          letterheadEnabled: false,
          showFooterBranding: true,
        );

        final pdf = PDFService.generateInvoicePDFWithSettings(
          _sampleInvoice(itemCount: 4),
          settings,
        );

        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
      });

      test(
          '${template.name} respects canonical showFooterBranding = false (no software branding)',
          () async {
        final settings = _createSettings(
          template: template,
          pdfTheme: pdfTheme,
          logoBytes: logoBytes,
          watermarkBytes: watermarkBytes,
          signatureBytes: signatureBytes,
          letterheadEnabled: true,
          showFooterBranding: false,
        );

        final pdf = PDFService.generateInvoicePDFWithSettings(
          _sampleInvoice(itemCount: 3),
          settings,
        );

        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
      });
    }

    test('Content scale presets (70%, 80%, 90%, 100%) render correctly on Classic', () async {
      for (final scale in [70.0, 80.0, 90.0, 100.0]) {
        final settings = _createSettings(
          template: InvoiceTemplate.classic,
          pdfTheme: pdfTheme,
          logoBytes: logoBytes,
          watermarkBytes: watermarkBytes,
          signatureBytes: signatureBytes,
          letterheadEnabled: true,
          printContentScale: scale,
        );

        final pdf = PDFService.generateInvoicePDFWithSettings(
          _sampleInvoice(itemCount: 10),
          settings,
        );

        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
      }
    });

    test('Multi-page pagination correctly respects letterhead margins', () async {
      final settings = _createSettings(
        template: InvoiceTemplate.classic,
        pdfTheme: pdfTheme,
        logoBytes: logoBytes,
        watermarkBytes: watermarkBytes,
        signatureBytes: signatureBytes,
        letterheadEnabled: true,
        printMarginTopMm: 50.0,
        printMarginBottomMm: 35.0,
        printContentScale: 90.0,
        showFooterBranding: false,
      );

      // 35 items forces multi-page rendering across continuation pages
      final pdf = PDFService.generateInvoicePDFWithSettings(
        _sampleInvoice(itemCount: 35),
        settings,
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(pdf.document.pdfPageList.pages.length, greaterThan(1));
    });
  });
}
