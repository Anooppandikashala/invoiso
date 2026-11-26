import 'dart:convert';
import 'dart:typed_data';

import 'package:invoiso_template_engine/invoiso_template_engine.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/test.dart';

Future<String> _raw(Map<String, dynamic> document, Map<String, dynamic> data,
    TemplateOptions options, {TemplateAssets assets = const TemplateAssets()}) async {
  final pdf = pw.Document(compress: false)
    ..addPage(buildBlockLayoutPage(
        document: document, data: data, options: options, assets: assets));
  return latin1.decode(await pdf.save());
}

String _words(String raw) =>
    RegExp(r'\[\((.*?)\)\]TJ').allMatches(raw).map((m) => m.group(1)).join(' ');

void main() {
  final data = {
    'company': {'name': 'Sample Co'},
    'invoice': {'date': '2026-11-21T14:05:00.000', 'status': 'declined'},
    'items': [
      {'name': 'Bolt', 'qty': 1},
    ],
    'totals': {'total': 10},
  };

  test('text-size settings: roles use section sizes, others the overall size',
      () async {
    final raw = await _raw({
      'engine': 2,
      'layout': [
        {'type': 'text', 'role': 'companyName', 'size': 10, 'value': 'A'},
        {'type': 'text', 'size': 10, 'value': 'B'},
        {
          'type': 'table',
          'size': 9,
          'columns': [
            {'id': 'n', 'label': 'Item', 'value': '{{row.name}}'},
          ],
          'footerRows': [
            {'cells': {'n': 'Total'}},
          ],
        },
      ],
    }, data, const TemplateOptions(
        fontScale: 1.5,
        companyNameScale: 2,
        tableHeaderScale: 3,
        tableItemsScale: 1.2,
        totalsScale: 0.5));
    expect(raw, contains(' 20 Tf')); // company name 10 × 2
    expect(raw, contains(' 15 Tf')); // plain text 10 × 1.5
    expect(raw, contains(' 27 Tf')); // table header 9 × 3
    expect(raw, contains(' 10.8 Tf')); // table rows 9 × 1.2
    expect(raw, contains(' 4.5 Tf')); // totals rows 9 × 0.5
  });

  test('v1 header block uses company-name and title sizes', () async {
    final raw = await _raw({
      'layout': [
        {
          'type': 'header',
          'left': {'companyName': '{{company.name}}'},
          'right': {'title': 'INVOICE'},
        },
      ],
    }, data, const TemplateOptions(companyNameScale: 2, docTitleScale: 3));
    expect(raw, contains(' 34 Tf')); // 17 × 2
    expect(raw, contains(' 48 Tf')); // 16 × 3
  });

  test('"show time" off prints the date only', () async {
    final doc = {
      'engine': 2,
      'layout': [
        {'type': 'text', 'value': 'D {{invoice.datetime}}'},
      ],
    };
    expect(_words(await _raw(doc, data, const TemplateOptions())),
        contains('D 21/11/2026 14:05'));
    final off = _words(await _raw(doc, data, const TemplateOptions(showTime: false)));
    expect(off, contains('D 21/11/2026'));
    expect(off, isNot(contains('14:05')));
  });

  test('declined quotations get the DECLINED stamp; watermark draws', () async {
    final raw = await _raw({
      'layout': [
        {'type': 'text', 'content': 'Body'},
      ],
    }, data, const TemplateOptions(watermarkFullPage: true),
        assets: TemplateAssets(watermark: _png1x1));
    expect(_words(raw), contains('DECLINED'));
    expect(raw, matches(RegExp(r'/Subtype\s*/Image')));
  });

  test('overlay text (licence watermark) is drawn on every page', () async {
    final document = {
      'engine': 2,
      'layout': [
        {
          'type': 'table',
          'columns': [
            {'id': 'n', 'label': 'Item', 'value': '{{row.name}}'},
          ],
        },
      ],
    };
    final long = {
      ...data,
      'invoice': {'date': '2026-11-21T14:05:00.000'},
      'items': [for (var i = 0; i < 120; i++) {'name': 'Item $i', 'qty': 1}],
    };
    final none = await _raw(document, long, const TemplateOptions());
    expect(_words(none), isNot(contains('PREVIEW')));

    final pdf = pw.Document(compress: false)
      ..addPage(buildBlockLayoutPage(
          document: document,
          data: long,
          options: const TemplateOptions(overlayText: 'PREVIEW')));
    final raw = latin1.decode(await pdf.save());
    final pages = RegExp(r'/Type\s*/Page\b').allMatches(raw).length;
    expect(pages, greaterThan(1));
    expect(RegExp(r'\(PREVIEW\)').allMatches(raw).length, pages);
  });

  test('a logo image block never shows the signature when there is no logo',
      () async {
    final raw = await _raw({
      'engine': 2,
      'layout': [
        {'type': 'image', 'source': 'logo'},
        {'type': 'text', 'value': 'Body'},
      ],
    }, data, const TemplateOptions(),
        assets: TemplateAssets(signature: _png1x1));
    expect(raw, isNot(matches(RegExp(r'/Subtype\s*/Image'))));
  });
}

// 1×1 transparent PNG.
final _png1x1 = Uint8List.fromList(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='));
