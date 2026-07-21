import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/services/pdf/pdf_template_gridclassic.dart';
import 'package:invoiso/utils/amount_in_words.dart';

final _company = CompanyInfo(
  name: 'MADATHIL HARDWARE',
  address: 'PALOLIKKUND ROAD VALAPURAM',
  phone: '9778146009',
  email: '',
  website: '',
  gstin: '32CHMPN7497M1ZF',
);

Invoice _sampleInvoice({
  double discount = 0,
  bool discountPerUnit = false,
  double taxRate = 0,
  TaxMode taxMode = TaxMode.none,
  List<AdditionalCost> additionalCosts = const [],
}) {
  final product = Product(
    id: 'p1',
    name: 'CEMENT ACC',
    description: '',
    price: 370,
    stock: 10,
    hsncode: '2523',
    tax_rate: taxRate.toInt(),
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
    items:List.generate(
        22,
        (index) => InvoiceItem(
      product: product,
      quantity: index + 1, // Example: 1, 2, 3, ..., 10
      discount: discount,
      discountPerUnit: discountPerUnit,
    ),
  ),
    date: DateTime(2026, 7, 17, 9, 25, 13),
    type: 'Invoice',
    taxRate: taxRate,
    taxMode: taxMode,
    additionalCosts: additionalCosts,
  );
}

void main() {
  test('amount in words matches expected Indian numbering', () {
    expect(AmountInWords.amount(1110), 'One Thousand One Hundred and Ten Only');
    expect(AmountInWords.amount(0), 'Zero Only');
    expect(AmountInWords.amount(100000), 'One Lakh Only');
  });

  for (final pageFormat in [PdfPageFormat.a4, PdfPageFormat.a5, PdfPageFormat.a6])
  {
    for (final showQuantity in [true, false]) {
      test(
          'gridClassic template renders on ${pageFormat == PdfPageFormat.a4 ? 'A4' : pageFormat == PdfPageFormat.a5 ? 'A5' : 'A6'} '
          '(showQuantity=$showQuantity)', () async {
        final doc = pw.Document();
        doc.addPage(buildGridClassicTemplate(
          _sampleInvoice(),
          _company,
          'Rs.',
          '',
          showQuantity: showQuantity,
          pageFormat: pageFormat,
          showFooterBranding: true,
          showTypeTag: false,
          showTotalQuantity: true,
        ));
        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        final name = pageFormat == PdfPageFormat.a4 ? 'a4' : pageFormat == PdfPageFormat.a5 ? "a5" : "a6";
        final outputPath = 'output/invoiso_grid_pdf_' + name + showQuantity.toString() + '.pdf';
        final outputFile = File(outputPath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(await doc.save());
      });
    }
  }

  test('gridClassic renders with discount, tax, additional costs and previous balance',
      () async {
    final doc = pw.Document();
    doc.addPage(buildGridClassicTemplate(
      _sampleInvoice(
        discount: 10,
        discountPerUnit: true,
        taxRate: 0.18,
        taxMode: TaxMode.global,
        additionalCosts: const [AdditionalCost(label: 'Shipping', amount: 50)],
      ),
      _company,
      'Rs.',
      '',
      showDiscount: true,
      previousBalanceDue: 200,
      showFooterBranding: true,
      showTotalQuantity: true
    ));
    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    final outputPath = 'output/invoiso_grid_pdf.pdf';
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(await doc.save());
  });
}
