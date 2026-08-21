import 'dart:io';
import 'dart:typed_data';

import 'package:invoiso/common/common.dart';
import 'package:invoiso/services/pdf/pdf_font_assets.dart';
import 'package:invoiso/common/supported_currencies.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../test_support/ttf_glyph_coverage.dart';

Future<void> main() async {
  const outputPath = 'output/invoiso_currency_render_check.pdf';

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
  // Fonts read directly from disk (not via PdfFontService.loadTheme(),
  // which uses rootBundle) since rootBundle needs a Flutter asset-bundle
  // binding this standalone script doesn't have.
  pw.Font font(String assetPath) =>
      pw.Font.ttf(ByteData.sublistView(fontBytes[assetPath]!));

  final theme = pw.ThemeData.withFont(
    base: font(PdfFontAssets.regular),
    bold: font(PdfFontAssets.bold),
    italic: font(PdfFontAssets.italic),
    boldItalic: font(PdfFontAssets.boldItalic),
    fontFallback: [
      font(PdfFontAssets.symbolsFallback),
      font(PdfFontAssets.interRegular),
      font(PdfFontAssets.arabicFallback),
      font(PdfFontAssets.arabicFallbackBold),
      font(PdfFontAssets.sinhalaFallback),
      font(PdfFontAssets.bengaliFallback),
      font(PdfFontAssets.bengaliFallbackBold),
      font(PdfFontAssets.malayalamFallback),
      font(PdfFontAssets.malayalamFallbackBold),
      font(PdfFontAssets.devanagariFallback),
      font(PdfFontAssets.devanagariFallbackBold),
      font(PdfFontAssets.tamilFallback),
      font(PdfFontAssets.tamilFallbackBold),
      font(PdfFontAssets.kannadaFallback),
      font(PdfFontAssets.kannadaFallbackBold),
      font(PdfFontAssets.teluguFallback),
      font(PdfFontAssets.teluguFallbackBold),
      font(PdfFontAssets.thaiFallback),
      font(PdfFontAssets.thaiFallbackBold),
      font(PdfFontAssets.khmerFallback),
      font(PdfFontAssets.khmerFallbackBold),
      font(PdfFontAssets.georgianFallback),
      font(PdfFontAssets.georgianFallbackBold),
      font(PdfFontAssets.armenianFallback),
      font(PdfFontAssets.armenianFallbackBold),
      font(PdfFontAssets.myanmarFallback),
      font(PdfFontAssets.myanmarFallbackBold),
    ],
  );

  pdf.addPage(
    pw.MultiPage(
      theme: theme,
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
    // Primary fonts
    PdfFontAssets.regular,
    PdfFontAssets.bold,
    PdfFontAssets.italic,
    PdfFontAssets.boldItalic,
    // Sinhala
    PdfFontAssets.sinhalaFallback,
    // Arabic
    PdfFontAssets.arabicFallback,
    PdfFontAssets.arabicFallbackBold,
    // Bengali
    PdfFontAssets.bengaliFallback,
    PdfFontAssets.bengaliFallbackBold,
    // Devanagari
    PdfFontAssets.devanagariFallback,
    PdfFontAssets.devanagariFallbackBold,
    // Malayalam
    PdfFontAssets.malayalamFallback,
    PdfFontAssets.malayalamFallbackBold,
    // Tamil
    PdfFontAssets.tamilFallback,
    PdfFontAssets.tamilFallbackBold,
    // Kannada
    PdfFontAssets.kannadaFallback,
    PdfFontAssets.kannadaFallbackBold,
    // Telugu
    PdfFontAssets.teluguFallback,
    PdfFontAssets.teluguFallbackBold,
    // Thai
    PdfFontAssets.thaiFallback,
    PdfFontAssets.thaiFallbackBold,
    // Khmer
    PdfFontAssets.khmerFallback,
    PdfFontAssets.khmerFallbackBold,
    // Georgian
    PdfFontAssets.georgianFallback,
    PdfFontAssets.georgianFallbackBold,
    // Armenian
    PdfFontAssets.armenianFallback,
    PdfFontAssets.armenianFallbackBold,
    // Myanmar
    PdfFontAssets.myanmarFallback,
    PdfFontAssets.myanmarFallbackBold,
    // Unicode symbols
    PdfFontAssets.symbolsFallback,
    // Inter
    PdfFontAssets.interRegular,
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
