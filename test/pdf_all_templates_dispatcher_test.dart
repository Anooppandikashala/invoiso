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
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common.dart';
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
);

Invoice _sampleInvoice() {
  final product = Product(
    id: 'p1',
    name: 'CEMENT ACC',
    description: '',
    price: 370,
    stock: 10,
    hsncode: '2523',
    tax_rate: 18,
  );
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
    items: [InvoiceItem(product: product, quantity: 3)],
    date: DateTime(2026, 7, 17, 9, 25, 13),
    type: 'Invoice',
    taxRate: 18,
    taxMode: TaxMode.global,
    notes: 'Handle with care',
  );
}

// PageSize each template is actually allowed to render at
// (see InvoiceTemplatePageSizeExtension.supportsPageSize in common.dart).
PageSize _pageSizeFor(InvoiceTemplate template) => switch (template) {
      InvoiceTemplate.compact => PageSize.a6,
      InvoiceTemplate.thermal => PageSize.thermal80,
      _ => PageSize.a4,
    };

void main() {
  for (final template in InvoiceTemplate.values) {
    test('${template.name} template renders via the real PDFService dispatcher',
        () async {
      final pageSize = _pageSizeFor(template);
      final settings = PdfGenerationSettings(
        company: _company,
        template: template,
        invoicePrefix: 'INV-',
        showGst: true,
        showQuantity: true,
        showDiscount: true,
        showTypeTag: true,
        businessType: BusinessType.both,
        upiEntries: const [],
        showQrStr: 'false',
        showBankDetails: false,
        bankAccounts: const [],
        logoPosition: LogoPosition.left,
        logoSizePx: 60,
        logoBytes: null,
        thankYouNote: 'Thank you for your business!',
        datePattern: 'dd/MM/yyyy',
        showFooterBranding: true,
        themeColor: null,
        showPreviousBalance: true,
        pageFormat: PDFService.pageSizeToFormat(pageSize),
        pageSize: pageSize,
        showTotalQuantity: true,
        pdfTheme: pw.ThemeData.base(),
      );

      final pdf = PDFService.generateInvoicePDFWithSettings(
        _sampleInvoice(),
        settings,
        previousBalanceDue: 50.0,
      );
      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
    });
  }
}
