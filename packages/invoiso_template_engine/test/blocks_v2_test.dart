import 'dart:convert';

import 'package:invoiso_template_engine/invoiso_template_engine.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/test.dart';

Future<({String text, int pages})> _render(Map<String, dynamic> document,
    {int items = 1}) async {
  final pdf = pw.Document(compress: false)
    ..addPage(buildBlockLayoutPage(
      document: document,
      data: {
        'company': {'name': 'Sample Co', 'gstin': '00AAAAA0000A0Z0'},
        'items': [
          for (var i = 0; i < items; i++) {'name': 'Item', 'qty': 1, 'amount': 10},
        ],
      },
      options: const TemplateOptions(currencySymbol: 'Rs'),
    ));
  final raw = latin1.decode(await pdf.save());
  final words = RegExp(r'\[\((.*?)\)\]TJ').allMatches(raw).map((m) => m.group(1));
  return (text: words.join(' '), pages: pdf.document.pdfPageList.pages.length);
}

void main() {
  test('box, row, column and styled text render', () async {
    final r = await _render({
      'engine': 2,
      'gap': 0,
      'styles': {
        'h': {'size': 14, 'bold': true},
      },
      'layout': [
        {
          'type': 'row',
          'border': 0.8,
          'children': [
            {
              'type': 'box',
              'width': '60%',
              'padding': 4,
              'child': {
                'type': 'column',
                'children': [
                  {'type': 'text', 'style': 'h', 'value': '{{company.name}}'},
                  {'type': 'text', 'uppercase': true, 'value': 'gstin {{company.gstin}}'},
                ],
              },
            },
            {
              'type': 'box',
              'border': {'width': 1, 'top': true, 'bottom': true},
              'background': '#F3F4F6',
              'radius': 4,
              'child': {'type': 'text', 'italic': true, 'value': 'Right cell'},
            },
          ],
        },
        {'type': 'divider', 'thickness': 2, 'color': '#FF0000'},
      ],
    });
    expect(r.text, contains('Sample Co'));
    expect(r.text, contains('GSTIN 00AAAAA0000A0Z0'));
    expect(r.text, contains('Right cell'));
  });

  test('pageHeader / pageFooter repeat with page numbers; frame draws', () async {
    final r = await _render({
      'engine': 2,
      'page': {
        'size': 'a4',
        'frame': {'width': 1, 'color': '#000000'},
      },
      'pageHeader': [
        {'type': 'text', 'value': 'HDR {{company.name}}'},
      ],
      'pageFooter': [
        {'type': 'pageNumber', 'value': 'Sheet {{page}}/{{pages}}'},
      ],
      'layout': [
        {'type': 'table'},
      ],
    }, items: 120);
    expect(r.pages, greaterThan(1));
    expect(RegExp('HDR Sample Co').allMatches(r.text).length, r.pages);
    expect(r.text, contains('Sheet 1/${r.pages}'));
    expect(r.text, contains('Sheet ${r.pages}/${r.pages}'));
  });

  test('without "engine": 2 the old meanings stay (row stacks, box = note)',
      () async {
    final r = await _render({
      'layout': [
        {
          'type': 'row',
          'children': [
            {'type': 'text', 'content': 'First'},
            {'type': 'text', 'content': 'Second'},
          ],
        },
        {'type': 'box', 'title': 'Terms', 'content': 'Old note box'},
      ],
    });
    expect(r.text, contains('First'));
    expect(r.text, contains('Second'));
    expect(r.text, contains('TERMS'));
    expect(r.text, contains('Old note box'));
  });
}
