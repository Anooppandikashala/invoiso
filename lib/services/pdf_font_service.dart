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
    ]);

    final regular = pw.Font.ttf(fonts[0]);
    final bold = pw.Font.ttf(fonts[1]);
    final italic = pw.Font.ttf(fonts[2]);
    final boldItalic = pw.Font.ttf(fonts[3]);
    final sinhalaFallback = pw.Font.ttf(fonts[4]);

    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
      fontFallback: [sinhalaFallback],
    );
  }
}
