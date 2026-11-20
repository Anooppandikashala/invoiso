// GSTR-3B summary PDF renders with the bundled fonts.
// Writes output/gstr3b_pdf_test.pdf for a visual check (pdftoppm).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/gstr1_report.dart';
import 'package:invoiso/models/purchase_bill.dart';
import 'package:invoiso/models/purchase_bill_item.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/services/gst/gstr3b_builder.dart';
import 'package:invoiso/services/gst/gstr3b_pdf_writer.dart';
import 'package:invoiso/services/gst/purchase_gst_builder.dart';

import 'test_pdf_font_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GSTR-3B PDF renders all tables', () async {
    const gstin = '33ABCDE1234F1Z5';
    final Gstr1Report sales = Gstr1Builder.build(
        Gstr1Input(companyGstin: gstin, documents: const [], numberOf: (i) => i.id));
    final summary = Gstr3bBuilder.build(
      companyGstin: gstin,
      sales: sales,
      purchases: PurchaseGstBuilder.build(companyGstin: gstin, bills: [
        PurchaseBill(id: 'a', billDate: DateTime(2026, 10, 2),
            supplierGstin: '29ABCDE1234F1Z5',
            items: [PurchaseBillItem(
                productName: 'X', quantity: 1, costPerUnit: 1000, taxRate: 18)]),
        PurchaseBill(id: 'b', billDate: DateTime(2026, 10, 3), reverseCharge: true,
            items: [PurchaseBillItem(
                productName: 'Freight', quantity: 1, costPerUnit: 500, taxRate: 5)]),
      ]),
    );
    final bytes = await Gstr3bPdfWriter.build(summary,
        periodLabel: 'October 2026',
        company: CompanyInfo(name: 'Demo Traders', address: 'Chennai', phone: '',
            email: '', website: '', gstin: gstin),
        datePattern: 'dd/MM/yyyy',
        theme: await TestPdfFontService.loadTheme());
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    Directory('output').createSync();
    File('output/gstr3b_pdf_test.pdf').writeAsBytesSync(bytes);
  });
}
