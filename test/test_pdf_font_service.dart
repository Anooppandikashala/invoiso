// Test-only stand-in for PdfFontService.loadTheme().
//
// flutter_test's mocked asset bundle returns corrupted (empty) results when
// multiple rootBundle.load() calls are fired concurrently (e.g. via
// Future.wait) — a flutter_test binary-messenger quirk, not a bug in the
// real app (production's real AssetBundle handles concurrent loads fine).
// This loads the same fonts sequentially so PDF-generating tests don't hit
// that quirk, without changing the production loading strategy.
import 'package:flutter/services.dart' show rootBundle;
import 'package:invoiso/services/pdf_font_assets.dart';
import 'package:pdf/widgets.dart' as pw;

class TestPdfFontService {
  static Future<pw.ThemeData> loadTheme() async {
    final regular = pw.Font.ttf(await rootBundle.load(PdfFontAssets.regular));
    final bold = pw.Font.ttf(await rootBundle.load(PdfFontAssets.bold));
    final italic = pw.Font.ttf(await rootBundle.load(PdfFontAssets.italic));
    final boldItalic =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.boldItalic));
    final sinhalaFallback =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.sinhalaFallback));
    final malayalam =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.malayalamFallback));
    final malayalamBold = pw.Font.ttf(
        await rootBundle.load(PdfFontAssets.malayalamFallbackBold));
    final devanagari =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.devanagariFallback));
    final devanagariBold = pw.Font.ttf(
        await rootBundle.load(PdfFontAssets.devanagariFallbackBold));
    final tamil =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.tamilFallback));
    final tamilBold =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.tamilFallbackBold));
    final kannada =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.kannadaFallback));
    final kannadaBold =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.kannadaFallbackBold));
    final telugu =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.teluguFallback));
    final teluguBold =
        pw.Font.ttf(await rootBundle.load(PdfFontAssets.teluguFallbackBold));

    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
      fontFallback: [
        sinhalaFallback,
        malayalam,
        malayalamBold,
        devanagari,
        devanagariBold,
        tamil,
        tamilBold,
        kannada,
        kannadaBold,
        telugu,
        teluguBold,
      ],
    );
  }
}
