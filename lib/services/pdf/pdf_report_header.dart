import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared professional header for report-style PDFs (customer statement,
/// daily report, ...): company block on the left, report title + generation
/// date on the right, under an accent divider. Callers append their own
/// report-specific content (subject line, date range, ...) below it.
class PdfReportHeader {
  static const accentColor = PdfColors.indigo800;

  static pw.Widget build({
    required CompanyInfo? company,
    required String title,
    required String generatedOn,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(company?.name ?? '',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold, color: accentColor)),
                  if ((company?.address ?? '').isNotEmpty)
                    pw.Text(company!.address,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.phone ?? '').isNotEmpty)
                    pw.Text('Phone: ${company!.phone}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.email ?? '').isNotEmpty)
                    pw.Text('Email: ${company!.email}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.website ?? '').isNotEmpty)
                    pw.Text(company!.website,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.gstin ?? '').isNotEmpty)
                    pw.Text('${taxLabel(company?.country)}: ${company!.gstin}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold, color: accentColor)),
                pw.SizedBox(height: 4),
                pw.Text('Date: $generatedOn',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: accentColor, thickness: 1.2),
        pw.SizedBox(height: 5),
      ],
    );
  }
}
