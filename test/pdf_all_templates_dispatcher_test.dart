// Debugging note: the app's preview/print buttons wrap PDF generation in a
// try/catch and only surface `e.toString()` in a SnackBar — no stack trace,
// no file/line. This test calls the exact same dispatcher the app calls
// (PDFService.generateInvoicePDFWithSettings) for every template, uncaught,
// so a broken template fails loudly here with a full stack trace instead of
// silently in production. To debug a fresh "Error previewing PDF: ..."
// report: reproduce it by adding/adjusting a case below and reading the
// first `package:invoiso/...` frame in the failure — that's the real bug
// site, everything below it (package:pdf/, package:flutter/) is library
// plumbing.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
  name: 'MADATHIL HARDWARE',
  address: 'PALOLIKKUND ROAD VALAPURAM',
  phone: '9778146009',
  email: '',
  website: '',
  gstin: '32CHMPN7497M1ZF',
  fssaiCode: 'ABDDDGGGHHHJJJ',
  panNumber: 'ASDWERTYUG',
  country: 'India',
);

// 25 items so the invoice spans multiple physical pages — exercises
// MultiPage overflow/pagination, not just the single-page case.
List<InvoiceItem> _sampleItems() => List.generate(25, (i) {
      final product = Product(
        id: 'p${i + 1}',
        name: 'CEMENT ACC ${i + 1}',
        description: i % 3 == 0
            ? ''
            : 'Premium grade cement, weather-resistant packaging, sourced from certified plant batch ${i + 1}.',
        price: 370 + i * 5,
        stock: 10,
        hsncode: '2523',
        tax_rate: 18,
      );
      return InvoiceItem(product: product, quantity: 1 + (i % 5));
    });

Invoice _sampleInvoice() {
  return Invoice(
    id: 'inv1',
    invoiceNumber: '212',
    customer: Customer(
      id: 'c1',
      name: 'HAMEED PT ZAMZAM',
      email: '',
      phone: '',
      address: 'PULAKKATTUTHODI PERINTHALMANNA',
      gstin: '',
    ),
    items: _sampleItems(),
    date: DateTime(2026, 7, 17, 9, 25, 13),
    type: 'Invoice',
    taxRate: 0.18,
    taxMode: TaxMode.perItem,
    notes: 'Here is a short sample of structured \nstudy notes based on a basic topic,\nplant photosynthesis. You can use this clean layout for school or work',
  );
}

extension InvoiceTemplateExtension on InvoiceTemplate {
  String get displayName {
    switch (this) {
      case InvoiceTemplate.classic:
        return 'Classic';
      case InvoiceTemplate.modern:
        return 'Modern';
      case InvoiceTemplate.minimal:
        return 'Minimal';
      case InvoiceTemplate.executive:
        return 'Executive';
      case InvoiceTemplate.compact:
        return 'Compact (A6)';
      case InvoiceTemplate.thermal:
        return 'Thermal Receipt';
      case InvoiceTemplate.gridClassic:
        return 'Grid Classic';
    }
  }
}

// PageSize each template is actually allowed to render at
// (see InvoiceTemplatePageSizeExtension.supportsPageSize in common.dart).
PageSize _pageSizeFor(InvoiceTemplate template) => switch (template) {
      InvoiceTemplate.compact => PageSize.a6,
      InvoiceTemplate.thermal => PageSize.thermal80,
      _ => PageSize.a4,
    };

const _logoVariants = {
  'square': 'assets/images/demo_logo.png',
  'wide': 'assets/images/wide_logo.png',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final template in InvoiceTemplate.values) {
    for (final logoVariant in _logoVariants.entries) {
      test(
          '${template.name} template renders with ${logoVariant.key} logo via the real PDFService dispatcher',
          () async {
        final pageSize = _pageSizeFor(template);
        final pdfTheme = await TestPdfFontService.loadTheme();
        final watermarkBytes =
            await File('assets/images/watermark.png').readAsBytes();
        final logoBytes = await File(logoVariant.value).readAsBytes();
        final signatureBytes =
            await File('assets/images/sig.jpeg').readAsBytes();
        final settings = PdfGenerationSettings(
          company: _company,
          template: template,
          invoicePrefix: 'INV-',
          showGst: true,
          showQuantity: true,
          showDiscount: true,
          showTypeTag: true,
          businessType: BusinessType.both,
          upiEntries: const [
            UpiEntry(
                label: 'HDFC Bank', id: 'business@okhdfcbank', isDefault: true),
          ],
          showQrStr: 'true',
          showBankDetails: true,
          bankAccounts: const [
            BankAccount(
              label: 'Business Account',
              bankName: 'HDFC Bank',
              accountNumber: '123456789012',
              ifscCode: 'HDFC0001234',
              isDefault: true,
            ),
          ],
          logoPosition: LogoPosition.left,
          logoSizePx: 80,
          logoBytes: logoBytes,
          signatureBytes: signatureBytes,
          thankYouNote: 'Thank you for your business!',
          datePattern: 'dd/MM/yyyy',
          showFooterBranding: true,
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
        );

        final pdf = PDFService.generateInvoicePDFWithSettings(
          _sampleInvoice(),
          settings,
          previousBalanceDue: 50.0,
        );
        final bytes = await pdf.save();
        expect(bytes, isNotEmpty);
        final outputPath =
            'output/all_pdfs_test/invoiso_${template.displayName}_${logoVariant.key}.pdf';
        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(await pdf.save());
      });
    }
  }
}
