import 'dart:convert';

import 'package:invoiso_template_engine/invoiso_template_engine.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/test.dart';

Map<String, dynamic> _data({bool interState = false, String upi = ''}) => {
      'invoice': {'isInterState': interState},
      'items': [
        {'slNo': 1, 'name': 'Bolt', 'description': 'M8 zinc', 'typeTag': 'product', 'qty': 2, 'amount': 1200},
        {'slNo': 2, 'name': 'Nut', 'description': '', 'typeTag': 'product', 'qty': 3, 'amount': 300},
      ],
      'taxSummary': [
        {'hsn': '7318', 'taxable': 1500, 'cgstRate': 9, 'cgst': 135, 'sgstRate': 9, 'sgst': 135, 'igstRate': 18, 'igst': 270, 'totalTax': 270},
      ],
      'charges': [
        {'label': 'Freight', 'amount': 50},
        {'label': 'Packing', 'amount': 20},
      ],
      'totals': {'taxable': 1500, 'tax': 270, 'totalQty': 5, 'previousBalanceDue': 0},
      'payment': {'upiPayload': upi},
    };

Future<({String text, String raw})> _render(List<Map<String, dynamic>> layout,
    Map<String, dynamic> data,
    {TemplateOptions options =
        const TemplateOptions(currencySymbol: 'Rs', amountSeparator: 'international', showDescription: true)}) async {
  final pdf = pw.Document(compress: false)
    ..addPage(buildBlockLayoutPage(
        document: {'engine': 2, 'layout': layout}, data: data, options: options));
  final raw = latin1.decode(await pdf.save());
  final words = RegExp(r'\[\((.*?)\)\]TJ').allMatches(raw).map((m) => m.group(1));
  return (text: words.join(' '), raw: raw);
}

Map<String, dynamic> _taxTable() => {
      'type': 'table',
      'source': 'taxSummary',
      'border': 'grid',
      'header': {'background': '#E5E7EB', 'color': '#111111'},
      'columns': [
        {'id': 'hsn', 'label': 'HSN', 'value': '{{row.hsn}}'},
        {'id': 'tv', 'label': 'Taxable', 'value': '{{row.taxable|number}}'},
        {'if': '!invoice.isInterState', 'id': 'cg', 'label': 'CGST', 'value': '{{row.cgstRate|percent}} {{row.cgst|money}}'},
        {'if': 'invoice.isInterState', 'id': 'ig', 'label': 'IGST', 'value': '{{row.igstRate|percent}} {{row.igst|money}}'},
      ],
      'footerRows': [
        {'bold': true, 'cells': {'hsn': 'Total', 'tv': '{{totals.taxable|number}}'}},
        {'if': 'totals.previousBalanceDue', 'cells': {'hsn': 'Previous balance'}},
      ],
    };

void main() {
  test('table over taxSummary with filters, footer rows and conditional columns',
      () async {
    final intra = await _render([_taxTable()], _data());
    expect(intra.text, contains('7318 1,500.00 9% Rs 135.00'));
    expect(intra.text, contains('Total 1,500.00'));
    expect(intra.text, isNot(contains('IGST')));
    expect(intra.text, isNot(contains('Previous balance')));

    final inter = await _render([_taxTable()], _data(interState: true));
    expect(inter.text, contains('18% Rs 270.00'));
    expect(inter.text, isNot(contains('CGST')));
  });

  test('items table: multi-line cells, display name, description setting',
      () async {
    final table = {
      'type': 'table',
      'columns': [
        {'id': 'd', 'label': 'Item', 'cell': [
          {'value': '{{row.displayName}}'},
          {'value': '{{row.description}}', 'italic': true},
          {'value': '{{row.typeTag|capitalize}}'},
        ]},
        {'id': 'q', 'label': 'Qty', 'value': '{{row.qty|qty}}'},
      ],
      'footerRows': [
        {'cells': {'d': 'Total', 'q': '{{totals.totalQty|qty}}'}},
      ],
    };
    final shown = await _render([table], _data());
    expect(shown.text, contains('Bolt M8 zinc Product'));
    expect(shown.text, contains('Total 5'));

    final hidden = await _render([table], _data(),
        options: const TemplateOptions(showDescription: false));
    expect(hidden.text, isNot(contains('M8 zinc')));
  });

  test('if block, if on any block, and repeat', () async {
    final r = await _render([
      {'type': 'if', 'when': 'invoice.isInterState',
       'then': {'type': 'text', 'value': 'INTER'},
       'else': {'type': 'text', 'value': 'INTRA'}},
      {'type': 'text', 'if': 'totals.previousBalanceDue', 'value': 'HIDDEN'},
      {'type': 'repeat', 'source': 'charges',
       'child': {'type': 'text', 'value': 'C {{row.label}} {{row.amount|money}}'}},
    ], _data());
    expect(r.text, contains('INTRA'));
    expect(r.text, isNot(contains('INTER ')));
    expect(r.text, isNot(contains('HIDDEN')));
    expect(r.text, contains('C Freight Rs 50.00'));
    expect(r.text, contains('C Packing Rs 20.00'));
  });

  test('qr draws only when there is a UPI payload or payment QR image', () async {
    final layout = [
      {'type': 'qr', 'title': 'Pay via UPI'},
      {'type': 'text', 'value': 'END'},
    ];
    final none = await _render(layout, _data());
    expect(none.text, isNot(contains('Pay via UPI')));

    final upi = await _render(layout, _data(upi: 'upi://pay?pa=sample@upi&am=10.00'));
    expect(upi.text, contains('Pay via UPI'));
    expect(upi.raw.length, greaterThan(none.raw.length));
  });
}
