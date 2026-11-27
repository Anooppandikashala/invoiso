import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  const templateDefault = pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20);

  test('template preset keeps each template\'s own margins', () {
    expect(const PdfPageMargins().apply(templateDefault), templateDefault);
  });

  test('presets set all four sides', () {
    final wide = const PdfPageMargins(preset: 'wide').apply(templateDefault);
    expect([wide.left, wide.top, wide.right, wide.bottom], everyElement(closeTo(15 * PdfPageFormat.mm, 0.01)));
    expect(const PdfPageMargins(preset: 'narrow').presetPoints, closeTo(5 * PdfPageFormat.mm, 0.01));
    expect(const PdfPageMargins(preset: 'normal').presetPoints, closeTo(8 * PdfPageFormat.mm, 0.01));
  });

  test('letterhead space adds to the top only', () {
    final m = const PdfPageMargins(letterheadTopMm: 30).apply(templateDefault);
    expect(m.top, closeTo(12 + 30 * PdfPageFormat.mm, 0.01));
    expect([m.left, m.right, m.bottom], [20, 20, 12]);
  });

  test('stored values: unknown preset → template, letterhead clamped to 0–80', () {
    expect(PdfPageMargins.fromSettings('huge', '500'), const PdfPageMargins(letterheadTopMm: 80));
    expect(PdfPageMargins.fromSettings(null, 'x'), const PdfPageMargins());
    expect(PdfPageMargins.fromSettings('narrow', '25'), const PdfPageMargins(preset: 'narrow', letterheadTopMm: 25));
  });
}
