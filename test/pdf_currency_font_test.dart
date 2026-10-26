import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/supported_currencies.dart';
import 'package:invoiso/services/pdf/pdf_font_assets.dart';

import '../test_support/ttf_glyph_coverage.dart';

void main() {
  test('bundled PDF fonts cover every supported currency symbol', () {
    // Same fonts PdfFontService loads into the PDF theme (base + fallbacks).
    final fontCoverages = [
      PdfFontAssets.regular,
      PdfFontAssets.bold,
      PdfFontAssets.italic,
      PdfFontAssets.boldItalic,
      PdfFontAssets.sinhalaFallback,
      PdfFontAssets.arabicFallback,
      PdfFontAssets.arabicFallbackBold,
      PdfFontAssets.bengaliFallback,
      PdfFontAssets.bengaliFallbackBold,
      PdfFontAssets.devanagariFallback,
      PdfFontAssets.devanagariFallbackBold,
      PdfFontAssets.malayalamFallback,
      PdfFontAssets.malayalamFallbackBold,
      PdfFontAssets.tamilFallback,
      PdfFontAssets.tamilFallbackBold,
      PdfFontAssets.kannadaFallback,
      PdfFontAssets.kannadaFallbackBold,
      PdfFontAssets.teluguFallback,
      PdfFontAssets.teluguFallbackBold,
      PdfFontAssets.thaiFallback,
      PdfFontAssets.thaiFallbackBold,
      PdfFontAssets.khmerFallback,
      PdfFontAssets.khmerFallbackBold,
      PdfFontAssets.georgianFallback,
      PdfFontAssets.georgianFallbackBold,
      PdfFontAssets.armenianFallback,
      PdfFontAssets.armenianFallbackBold,
      PdfFontAssets.myanmarFallback,
      PdfFontAssets.myanmarFallbackBold,
      PdfFontAssets.tibetanFallback,
      PdfFontAssets.tibetanFallbackBold,
      PdfFontAssets.symbolsFallback,
      PdfFontAssets.interRegular,
    ].map((assetPath) {
      return TtfGlyphCoverage.fromBytes(File(assetPath).readAsBytesSync());
    }).toList();

    for (final currency in SupportedCurrencies.all) {
      for (final rune in currency.symbol.runes) {
        final supported = _isIgnorableRune(rune) ||
            fontCoverages.any((coverage) => coverage.supportsRune(rune));

        expect(
          supported,
          isTrue,
          reason: '${currency.code} (${currency.symbol}) contains unsupported '
              'rune U+${rune.toRadixString(16).toUpperCase()}',
        );
      }
    }
  });
}

bool _isIgnorableRune(int rune) {
  return rune == 0x20 || rune == 0x09 || rune == 0x0a || rune == 0x0d;
}
