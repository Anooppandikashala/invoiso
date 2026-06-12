import 'dart:io';
import 'dart:typed_data';

import 'package:invoiso/common.dart';
import 'package:invoiso/services/pdf_font_assets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../test_support/ttf_glyph_coverage.dart';

Future<void> main(List<String> args) async {
  final outputPath =
      args.isEmpty ? 'output/invoiso_currency_render_check.pdf' : args.first;

  final fontBytes = _loadFontBytes();
  final missingRunes = _findMissingCurrencyRunes(fontBytes);
  if (missingRunes.isNotEmpty) {
    stderr.writeln('FAIL: Missing PDF font glyphs:');
    for (final missing in missingRunes) {
      stderr.writeln(
        '- ${missing.currency.code} ${missing.currency.symbol}: '
        'U+${missing.rune.toRadixString(16).toUpperCase()}',
      );
    }
    exitCode = 1;
    return;
  }

  final pdf = pw.Document(
    title: 'Invoiso Currency Font Check',
    creator: 'Invoiso PDF currency render check',
  );
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(ByteData.sublistView(fontBytes[PdfFontAssets.regular]!)),
    bold: pw.Font.ttf(ByteData.sublistView(fontBytes[PdfFontAssets.bold]!)),
    italic: pw.Font.ttf(ByteData.sublistView(fontBytes[PdfFontAssets.italic]!)),
    boldItalic: pw.Font.ttf(
      ByteData.sublistView(fontBytes[PdfFontAssets.boldItalic]!),
    ),
    fontFallback: [
      pw.Font.ttf(ByteData.sublistView(
        fontBytes[PdfFontAssets.sinhalaFallback]!,
      )),
    ],
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text(
          'Invoiso Currency Symbol Render Check',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: const ['Code', 'Name', 'Symbol', 'Sample'],
          data: SupportedCurrencies.all.map((currency) {
            return [
              currency.code,
              currency.name,
              currency.symbol,
              '${currency.symbol} 123.45',
            ];
          }).toList(),
          border: pw.TableBorder.all(color: PdfColors.grey400),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ),
  );

  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(await pdf.save());

  stdout.writeln(
    'PASS: ${SupportedCurrencies.all.length} currency entries are covered.',
  );
  stdout.writeln('PDF written to ${outputFile.path}');
}

Map<String, Uint8List> _loadFontBytes() {
  const fontAssets = [
    PdfFontAssets.regular,
    PdfFontAssets.bold,
    PdfFontAssets.italic,
    PdfFontAssets.boldItalic,
    PdfFontAssets.sinhalaFallback,
  ];

  return {
    for (final asset in fontAssets) asset: File(asset).readAsBytesSync(),
  };
}

List<_MissingRune> _findMissingCurrencyRunes(Map<String, Uint8List> fontBytes) {
  final fontCoverages =
      fontBytes.values.map(TtfGlyphCoverage.fromBytes).toList();
  final missing = <_MissingRune>[];

  for (final currency in SupportedCurrencies.all) {
    for (final rune in currency.symbol.runes) {
      if (_isIgnorableRune(rune)) {
        continue;
      }

      final supported =
          fontCoverages.any((coverage) => coverage.supportsRune(rune));
      if (!supported) {
        missing.add(_MissingRune(currency, rune));
      }
    }
  }

  return missing;
}

bool _isIgnorableRune(int rune) {
  return rune == 0x20 || rune == 0x09 || rune == 0x0a || rune == 0x0d;
}

class _MissingRune {
  const _MissingRune(this.currency, this.rune);

  final CurrencyOption currency;
  final int rune;
}
