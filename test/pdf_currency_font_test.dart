import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/services/pdf_font_assets.dart';

import '../test_support/ttf_glyph_coverage.dart';

void main() {
  test('bundled PDF fonts cover every supported currency symbol', () {
    final fontCoverages = [
      PdfFontAssets.regular,
      PdfFontAssets.bold,
      PdfFontAssets.italic,
      PdfFontAssets.boldItalic,
      PdfFontAssets.sinhalaFallback,
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
