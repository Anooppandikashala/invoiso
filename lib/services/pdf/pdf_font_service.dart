import 'package:flutter/services.dart' show rootBundle;
import 'package:invoiso/services/pdf/pdf_font_assets.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFontService {
  static Future<pw.ThemeData> loadTheme() async {
    final fonts = await Future.wait([
      // 0-3: Primary fonts
      rootBundle.load(PdfFontAssets.regular),
      rootBundle.load(PdfFontAssets.bold),
      rootBundle.load(PdfFontAssets.italic),
      rootBundle.load(PdfFontAssets.boldItalic),

      // 4-5: Sinhala
      rootBundle.load(PdfFontAssets.sinhalaFallback),

      // 6-7: Arabic
      rootBundle.load(PdfFontAssets.arabicFallback),
      rootBundle.load(PdfFontAssets.arabicFallbackBold),

      // 8-9: Bengali
      rootBundle.load(PdfFontAssets.bengaliFallback),
      rootBundle.load(PdfFontAssets.bengaliFallbackBold),

      // 10-11: Devanagari
      rootBundle.load(PdfFontAssets.devanagariFallback),
      rootBundle.load(PdfFontAssets.devanagariFallbackBold),

      // 12-13: Malayalam
      rootBundle.load(PdfFontAssets.malayalamFallback),
      rootBundle.load(PdfFontAssets.malayalamFallbackBold),

      // 14-15: Tamil
      rootBundle.load(PdfFontAssets.tamilFallback),
      rootBundle.load(PdfFontAssets.tamilFallbackBold),

      // 16-17: Kannada
      rootBundle.load(PdfFontAssets.kannadaFallback),
      rootBundle.load(PdfFontAssets.kannadaFallbackBold),

      // 18-19: Telugu
      rootBundle.load(PdfFontAssets.teluguFallback),
      rootBundle.load(PdfFontAssets.teluguFallbackBold),

      // 20-21: Thai
      rootBundle.load(PdfFontAssets.thaiFallback),
      rootBundle.load(PdfFontAssets.thaiFallbackBold),

      // 22-23: Khmer
      rootBundle.load(PdfFontAssets.khmerFallback),
      rootBundle.load(PdfFontAssets.khmerFallbackBold),

      // 24-25: Georgian
      rootBundle.load(PdfFontAssets.georgianFallback),
      rootBundle.load(PdfFontAssets.georgianFallbackBold),

      // 26-27: Armenian
      rootBundle.load(PdfFontAssets.armenianFallback),
      rootBundle.load(PdfFontAssets.armenianFallbackBold),
      // 28-29: Myanmar
      rootBundle.load(PdfFontAssets.myanmarFallback),
      rootBundle.load(PdfFontAssets.myanmarFallbackBold),
      // 30-31: Tibetan
      rootBundle.load(PdfFontAssets.tibetanFallback),
      rootBundle.load(PdfFontAssets.tibetanFallbackBold),
      // 32: Symbols
      rootBundle.load(PdfFontAssets.symbolsFallback),
      // 33: Inter
      rootBundle.load(PdfFontAssets.interRegular),
    ]);

    // Primary fonts
    final regular = pw.Font.ttf(fonts[0]);
    final bold = pw.Font.ttf(fonts[1]);
    final italic = pw.Font.ttf(fonts[2]);
    final boldItalic = pw.Font.ttf(fonts[3]);

    // Fallback fonts
    final sinhala = pw.Font.ttf(fonts[4]);

    final arabic = pw.Font.ttf(fonts[5]);
    final arabicBold = pw.Font.ttf(fonts[6]);

    final bengali = pw.Font.ttf(fonts[7]);
    final bengaliBold = pw.Font.ttf(fonts[8]);

    final devanagari = pw.Font.ttf(fonts[9]);
    final devanagariBold = pw.Font.ttf(fonts[10]);

    final malayalam = pw.Font.ttf(fonts[11]);
    final malayalamBold = pw.Font.ttf(fonts[12]);

    final tamil = pw.Font.ttf(fonts[13]);
    final tamilBold = pw.Font.ttf(fonts[14]);

    final kannada = pw.Font.ttf(fonts[15]);
    final kannadaBold = pw.Font.ttf(fonts[16]);

    final telugu = pw.Font.ttf(fonts[17]);
    final teluguBold = pw.Font.ttf(fonts[18]);

    final thai = pw.Font.ttf(fonts[19]);
    final thaiBold = pw.Font.ttf(fonts[20]);

    final khmer = pw.Font.ttf(fonts[21]);
    final khmerBold = pw.Font.ttf(fonts[22]);

    final georgian = pw.Font.ttf(fonts[23]);
    final georgianBold = pw.Font.ttf(fonts[24]);

    final armenian = pw.Font.ttf(fonts[25]);
    final armenianBold = pw.Font.ttf(fonts[26]);

    final myanmar = pw.Font.ttf(fonts[27]);
    final myanmarBold = pw.Font.ttf(fonts[28]);

    final tibetan = pw.Font.ttf(fonts[29]);
    final tibetanBold = pw.Font.ttf(fonts[30]);

    final symbols = pw.Font.ttf(fonts[31]);

    final inter = pw.Font.ttf(fonts[32]);

    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,

      fontFallback: [
        // Unicode symbols / currency symbols
        symbols,
        inter,
        // Arabic
        arabic,
        arabicBold,
        // Sinhala
        sinhala,
        // Bengali
        bengali,
        bengaliBold,

        // Indian scripts
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

        // Other scripts
        thai,
        thaiBold,
        khmer,
        khmerBold,
        georgian,
        georgianBold,
        armenian,
        armenianBold,
        myanmar,
        myanmarBold,
        tibetan,
        tibetanBold,
      ],
    );
  }
}