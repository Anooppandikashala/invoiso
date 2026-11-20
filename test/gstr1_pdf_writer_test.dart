// GSTR-1 PDF (summary + detail tables): renders with the bundled fonts for a
// month with B2B, B2C, a credit note, warnings and documents issued.
// Writes output/gstr1_pdf_test.pdf for a visual check (pdftoppm).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/report_models.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/services/gst/gstr1_pdf_writer.dart';

import 'test_pdf_font_service.dart';

Product _p(double price, double rate, String hsn) => Product(
    id: 'p$hsn', name: 'Item $hsn', description: '', price: price, stock: 0,
    hsncode: hsn, tax_rate: rate, unit: 'pcs');

Invoice _inv(String id, {String gstin = '', String pos = '33', bool inter = false,
        String type = 'Invoice', required List<InvoiceItem> items}) =>
    Invoice(
      id: id,
      invoiceNumber: id,
      customer: Customer(
          id: 'c$id', name: 'Customer $id', email: '', phone: '', address: '',
          gstin: gstin),
      items: items,
      date: DateTime(2026, 10, 5),
      type: type,
      taxMode: TaxMode.perItem,
      isInterState: inter,
      placeOfSupply: pos,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GSTR-1 PDF renders summary and sections', () async {
    final report = Gstr1Builder.build(Gstr1Input(
      companyGstin: '33ABCDE1234F1Z5',
      numberOf: (i) => 'INV-${i.id}',
      documents: [
        _inv('1', gstin: '29PQRST6789L1ZQ', pos: '29', inter: true, items: [
          InvoiceItem(product: _p(100, 18, '8471'), quantity: 2),
          InvoiceItem(product: _p(100, 15, ''), quantity: 1), // warnings
        ]),
        _inv('2', items: [InvoiceItem(product: _p(500, 5, '1006'), quantity: 3)]),
        _inv('cn1', type: 'Credit Note', gstin: '29PQRST6789L1ZQ', pos: '29',
            inter: true,
            items: [InvoiceItem(product: _p(100, 18, '8471'), quantity: 1)]),
      ],
      documentsIssued: const [
        DocumentIssuedRow(
            type: 'Invoice', from: 'INV-1', to: 'INV-2', total: 2, cancelled: 0),
      ],
    ));
    final bytes = await Gstr1PdfWriter.build(
      report,
      periodLabel: 'October 2026',
      company: CompanyInfo(
          name: 'Demo Traders', address: 'Chennai', phone: '', email: '',
          website: '', gstin: '33ABCDE1234F1Z5'),
      datePattern: 'dd/MM/yyyy',
      theme: await TestPdfFontService.loadTheme(),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    Directory('output').createSync();
    File('output/gstr1_pdf_test.pdf').writeAsBytesSync(bytes);
  });
}
