import 'dart:convert';

import 'package:invoiso_template_engine/invoiso_template_engine.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/test.dart';

/// Renders one text block and returns the page text (words joined by space).
Future<String> _render(String content, Map<String, dynamic> data,
    [TemplateOptions options = const TemplateOptions(currencySymbol: 'Rs')]) async {
  final pdf = pw.Document(compress: false)
    ..addPage(buildBlockLayoutPage(
      document: {
        'layout': [
          {'type': 'text', 'content': content},
        ],
      },
      data: data,
      options: options,
    ));
  final raw = latin1.decode(await pdf.save());
  final words = RegExp(r'\[\((.*?)\)\]TJ').allMatches(raw).map((m) => m.group(1));
  return words.join(' ');
}

void main() {
  group('formatAmount', () {
    test('none / international / indian', () {
      expect(formatAmount(1234567.891, 'none'), '1234567.89');
      expect(formatAmount(1234567.891, 'international'), '1,234,567.89');
      expect(formatAmount(1234567.891, 'indian'), '12,34,567.89');
      expect(formatAmount(5, 'unknown'), '5.00');
    });
  });

  test('formatQuantity', () {
    expect(formatQuantity(2), '2');
    expect(formatQuantity(2.5), '2.5');
    expect(formatQuantity(2.256), '2.26');
  });

  test('formatDate with 24h / 12h time', () {
    final d = DateTime(2026, 11, 21, 14, 5);
    expect(formatDate(d, 'dd/MM/yyyy'), '21/11/2026');
    expect(formatDate(d, 'dd/MM/yyyy', withTime: true), '21/11/2026 14:05');
    expect(formatDate(d, 'dd/MM/yyyy', withTime: true, timeFormat: '12'),
        '21/11/2026 2:05 PM');
  });

  group('placeholders', () {
    final data = {
      'invoice': {
        'date': '2026-11-21T14:05:00.000',
        'custom': {'Vehicle No': 'KL-10-AB-1234'},
      },
      'company': {'fssai': '00000000000000'},
      'totals': {'taxable': 1234567.5, 'totalQty': 75, 'taxInWords': 'Ten Only'},
      'taxSummary': [
        {'hsn': '2523'},
      ],
    };

    test('totals numbers print as money with the separator setting', () async {
      expect(
          await _render('T {{totals.taxable}}', data,
              const TemplateOptions(currencySymbol: 'Rs', amountSeparator: 'indian')),
          contains('T Rs 12,34,567.50'));
    });

    test('quantities stay plain numbers', () async {
      expect(await _render('Q {{totals.totalQty}}', data), contains('Q 75'));
    });

    test('nested and case-insensitive lookup', () async {
      expect(await _render('V {{invoice.custom.vehicle no}}', data),
          contains('V KL-10-AB-1234'));
      expect(await _render('F {{company.FSSAI}}', data), contains('F 00000000000000'));
      expect(await _render('W {{totals.taxInWords}}', data), contains('W Ten Only'));
    });

    test('invoice.datetime follows time format', () async {
      expect(
          await _render('D {{invoice.datetime}}', data,
              const TemplateOptions(timeFormat: '12')),
          contains('D 21/11/2026 2:05 PM'));
    });

    test('unknown keys and lists resolve to empty', () async {
      // A line whose placeholders are ALL empty is hidden, so pair each with
      // a known value.
      expect(await _render('X{{nope.nothing}}{{totals.totalQty}}Y', data),
          contains('X75Y'));
      expect(await _render('X{{taxSummary}}{{totals.totalQty}}Y', data),
          contains('X75Y'));
    });
  });
}
