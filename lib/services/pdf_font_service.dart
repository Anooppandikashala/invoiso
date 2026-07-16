import 'package:flutter/services.dart' show rootBundle;
import 'package:invoiso/services/pdf_font_assets.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFontService {
  static Future<pw.ThemeData> loadTheme() async {
    final fonts = await Future.wait([
      rootBundle.load(PdfFontAssets.regular),
      rootBundle.load(PdfFontAssets.bold),
      rootBundle.load(PdfFontAssets.italic),
      rootBundle.load(PdfFontAssets.boldItalic),
      rootBundle.load(PdfFontAssets.sinhalaFallback),
      rootBundle.load(PdfFontAssets.malayalamFallback),
      rootBundle.load(PdfFontAssets.malayalamFallbackBold),
      rootBundle.load(PdfFontAssets.devanagariFallback),
      rootBundle.load(PdfFontAssets.devanagariFallbackBold),
      rootBundle.load(PdfFontAssets.tamilFallback),
      rootBundle.load(PdfFontAssets.tamilFallbackBold),
      rootBundle.load(PdfFontAssets.kannadaFallback),
      rootBundle.load(PdfFontAssets.kannadaFallbackBold),
      rootBundle.load(PdfFontAssets.teluguFallback),
      rootBundle.load(PdfFontAssets.teluguFallbackBold),
    ]);

    final regular = pw.Font.ttf(fonts[0]);
    final bold = pw.Font.ttf(fonts[1]);
    final italic = pw.Font.ttf(fonts[2]);
    final boldItalic = pw.Font.ttf(fonts[3]);
    final sinhalaFallback = pw.Font.ttf(fonts[4]);
    final malayalam = pw.Font.ttf(fonts[5]);
    final malayalamBold = pw.Font.ttf(fonts[6]);
    final devanagari = pw.Font.ttf(fonts[7]);
    final devanagariBold = pw.Font.ttf(fonts[8]);
    final tamil = pw.Font.ttf(fonts[9]);
    final tamilBold = pw.Font.ttf(fonts[10]);
    final kannada = pw.Font.ttf(fonts[11]);
    final kannadaBold = pw.Font.ttf(fonts[12]);
    final telugu = pw.Font.ttf(fonts[13]);
    final teluguBold = pw.Font.ttf(fonts[14]);

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
