// GSTR-1 Excel writer (Gstr1ExportPlan.md Part D1): template sheet names and
// order, header row 4, data from row 5 in template value formats, optional
// Invoices register sheet. Reads the xlsx back with the archive package.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/report_models.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/services/gst/gstr1_excel_writer.dart';

Product _p(double price, double rate, {String hsn = '8471', String unit = 'pcs'}) =>
    Product(
        id: 'p$hsn$rate', name: 'Item $hsn', description: '', price: price,
        stock: 0, hsncode: hsn, tax_rate: rate, unit: unit);

Invoice _inv(String id, {String gstin = '', String pos = '33', bool inter = false,
        String type = 'Invoice', required List<InvoiceItem> items}) =>
    Invoice(
      id: id,
      invoiceNumber: id,
      customer: Customer(
          id: 'c$id', name: 'Cust & Co $id', email: '', phone: '', address: '',
          gstin: gstin),
      items: items,
      date: DateTime(2026, 11, 5),
      type: type,
      taxMode: TaxMode.perItem,
      isInterState: inter,
      placeOfSupply: pos,
    );

/// Sheet name → list of rows (cells joined by '|'), from the written xlsx.
Map<String, List<String>> _read(List<int> bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  String file(String name) => utf8.decode(zip.findFile(name)!.content);
  final names = RegExp(r'<sheet name="([^"]+)"')
      .allMatches(file('xl/workbook.xml'))
      .map((m) => m.group(1)!.replaceAll('&amp;', '&'))
      .toList();
  return {
    for (var i = 0; i < names.length; i++)
      names[i]: [
        for (final row in RegExp(r'<row r="\d+">(.*?)</row>')
            .allMatches(file('xl/worksheets/sheet${i + 1}.xml')))
          RegExp(r'<t xml:space="preserve">(.*?)</t>|<v>(.*?)</v>')
              .allMatches(row.group(1)!)
              .map((m) => (m.group(1) ?? m.group(2))!.replaceAll('&amp;', '&'))
              .join('|'),
      ],
  };
}

void main() {
  final report = Gstr1Builder.build(Gstr1Input(
    companyGstin: '33ABCDE1234F1Z5',
    numberOf: (i) => 'INV-${i.id}',
    documents: [
      _inv('1', gstin: '29PQRST6789L1ZQ', pos: '29', inter: true, items: [
        InvoiceItem(product: _p(100, 18), quantity: 2),
        InvoiceItem(product: _p(50, 5, hsn: '1006', unit: 'kg'), quantity: 1),
      ]),
      _inv('2', items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
      _inv('cn1', type: 'Credit Note', gstin: '29PQRST6789L1ZQ', pos: '29',
          inter: true, items: [InvoiceItem(product: _p(100, 18), quantity: 1)]),
    ],
    documentsIssued: const [
      DocumentIssuedRow(
          type: 'Invoice', from: 'INV-1', to: 'INV-2', total: 2, cancelled: 0),
    ],
  ));

  test('template sheets in order, headers on row 4, values from row 5', () {
    final bytes = Gstr1ExcelWriter.build(report);
    Directory('output').createSync();
    File('output/gstr1_writer_test.xlsx').writeAsBytesSync(bytes); // for manual checks
    final s = _read(bytes);
    expect(s.keys, [
      'b2b,sez,de', 'b2cl', 'b2cs', 'cdnr', 'cdnur', 'exp', 'at', 'atadj',
      'exemp', 'hsn(b2b)', 'hsn(b2c)', 'docs', 'eco',
    ]);

    final b2b = s['b2b,sez,de']!;
    expect(b2b[0], 'Summary For B2B, SEZ, DE (4A, 4B, 6B, 6C)');
    expect(b2b[3], startsWith('GSTIN/UIN of Recipient|Receiver Name|Invoice Number'));
    // 2 rate lines of invoice 1, value repeated; '&' escaped and read back.
    expect(b2b[4],
        '29PQRST6789L1ZQ|Cust & Co 1|INV-1|05-Nov-2026|288.5|29-Karnataka|N|Regular B2B|18|200|0');
    expect(b2b[5], contains('|5|50|0'));
    // Summary: 1 recipient, 1 invoice, value counted once, taxable 250.
    expect(b2b[2], '1|1|288.5|250|0');

    expect(s['b2cs']![4], 'OE|33-Tamil Nadu|18|100|0');
    expect(s['cdnr']![4], contains('|C|29-Karnataka|N|Regular B2B|118|18|100|0'));
    expect(s['exemp']!.sublist(4), [
      'Inter-State supplies to registered persons|0|0|0',
      'Intra-State supplies to registered persons|0|0|0',
      'Inter-State supplies to unregistered persons|0|0|0',
      'Intra-State supplies to unregistered persons|0|0|0',
    ]);
    expect(s['hsn(b2b)']![4], '1006|Item 1006|KGS-KILOGRAMS|1|52.5|5|50|2.5|0|0|0');
    expect(s['docs']![4], 'Invoices for outward supply|INV-1|INV-2|2|0');
    expect(s['exp']!, hasLength(4)); // headers only
  });

  test('Invoices register sheet only when asked', () {
    expect(_read(Gstr1ExcelWriter.build(report)).containsKey('Invoices'), isFalse);
    final s = _read(Gstr1ExcelWriter.build(report, includeRegister: true));
    expect(s.keys.last, 'Invoices');
    expect(s['Invoices']![4],
        'Invoice|INV-1|05-Nov-2026|Cust & Co 1|29PQRST6789L1ZQ|29-Karnataka|250|38.5|288.5');
    expect(s['Invoices']!, hasLength(4 + 3)); // 2 invoices + 1 note
  });
}
