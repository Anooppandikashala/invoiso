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

  test('grid: one cell per item, bold label parts, odd cell blank or spanning',
      () async {
    final data = {
      'invoice': {
        'headerFields': [
          {'label': 'Invoice No.', 'value': 'INV-1'},
          {'label': 'Dated', 'value': '21/11/2026'},
          {'label': 'Due Date', 'value': '06/12/2026'},
        ],
      },
    };
    Map<String, dynamic> grid(bool span) => {
          'type': 'grid',
          'source': 'invoice.headerFields',
          'columns': 2,
          'border': 0.8,
          'spanLast': span,
          'cell': {'type': 'text', 'value': '**{{row.label}}:** {{row.value}}'},
        };
    for (final span in [false, true]) {
      final r = await _render([grid(span)], data);
      expect(r.text, contains('Invoice No.: INV-1'));
      expect(r.text, contains('Dated: 21/11/2026'));
      expect(r.text, contains('Due Date: 06/12/2026'));
      expect(r.raw, isNot(contains('**')));
    }
  });

  test('table header repeat follows the user setting; template can override',
      () async {
    final data = {
      'items': [
        for (var i = 0; i < 120; i++) {'name': 'Item $i', 'qty': 1},
      ],
    };
    Future<({int headers, int pages})> render(
        {bool? repeat, bool setting = false, bool v1 = false,
        bool detail = false}) async {
      final table = v1
          ? {
              'type': 'table',
              'columns': [
                {'key': 'item', 'label': 'COLHEAD'},
              ],
            }
          : {
              'type': 'table',
              if (repeat != null) 'repeatHeader': repeat,
              'columns': [
                {'id': 'n', 'label': 'COLHEAD', 'value': '{{row.name}}'},
              ],
              if (detail) 'detailRow': {'value': 'note {{row.name}}'},
            };
      final pdf = pw.Document(compress: false)
        ..addPage(buildBlockLayoutPage(
            document: {
              if (!v1) 'engine': 2,
              'layout': [table],
            },
            data: data,
            options: TemplateOptions(repeatTableHeader: setting)));
      final raw = latin1.decode(await pdf.save());
      return (
        headers: RegExp(r'\(COLHEAD\)').allMatches(raw).length,
        pages: pdf.document.pdfPageList.pages.length,
      );
    }

    final off = await render();
    expect(off.pages, greaterThan(1));
    expect(off.headers, 1); // setting off (default) → first page only
    final on = await render(setting: true);
    expect(on.headers, on.pages); // setting on → every page
    expect((await render(setting: true, repeat: false)).headers, 1);
    final forced = await render(repeat: true);
    expect(forced.headers, forced.pages);
    // Description-on-new-line mode (row-by-row) still repeats / doesn't.
    final detailOn = await render(setting: true, detail: true);
    expect(detailOn.pages, greaterThan(1));
    expect(detailOn.headers, detailOn.pages);
    expect((await render(detail: true)).headers, 1);
    final v1On = await render(setting: true, v1: true);
    expect(v1On.headers, v1On.pages); // old-style tables follow it too
  });

  test('detailRow: full-width line under each row only when its if holds',
      () async {
    Map<String, dynamic> table(String border) => {
          'type': 'table',
          'border': border,
          'columns': [
            {'id': 'd', 'label': 'Item', 'cell': [
              {'value': '{{row.name}}'},
              {'value': 'IN {{row.description}}', 'if': '!settings.newLine'},
            ]},
            {'id': 'q', 'label': 'Qty', 'value': '{{row.qty|qty}}'},
          ],
          'detailRow': {'value': 'DL {{row.description}}', 'if': 'settings.newLine'},
          'footerRows': [
            {'cells': {'d': 'Total'}},
          ],
        };
    Map<String, dynamic> data(bool newLine) => {
          'settings': {'newLine': newLine},
          'items': [
            {'name': 'Bolt', 'description': 'zinc', 'qty': 2},
            {'name': 'Nut', 'description': '', 'qty': 3},
          ],
        };
    for (final border in ['grid', 'horizontal', 'outer', 'none']) {
      final on = await _render([table(border)], data(true),
          options: const TemplateOptions(showDescription: true));
      expect(on.text, contains('DL zinc'));
      expect(on.text, isNot(contains('IN zinc')));
      expect(on.text, contains('Total'));
      final off = await _render([table(border)], data(false),
          options: const TemplateOptions(showDescription: true));
      expect(off.text, contains('IN zinc'));
      expect(off.text, isNot(contains('DL zinc')));
    }
  });
}
