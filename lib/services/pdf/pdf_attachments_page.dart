import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_attachment.dart';

/// "Attachments" section appended to the end of a template's page flow: the
/// customer photos in [Invoice.pdfAttachments], as a grid or one per row with
/// its caption. It starts right after the invoice when the page has room and
/// continues on new pages; every row is its own MultiPage child so pages
/// break between rows, never inside one. Empty when there are no photos.
List<pw.Widget> buildAttachmentsSection(
  Invoice invoice, {
  required PdfPageFormat pageFormat,
  required bool asList,
  double fontSizeScale = 1.0,
}) {
  final photos = invoice.pdfAttachments;
  if (photos.isEmpty) return const [];

  final small = pageFormat.width < PdfPageFormat.a5.width + 1; // A6
  final landscape = pageFormat.width > pageFormat.height;
  final usable = pageFormat.height - 2 * PdfLayout.defaultHMargin;
  // A6 text follows the smaller page like the templates' own A6 text
  // (A4-sized heading/captions dwarf it).
  final pageScale = small ? 0.6 : 1.0;
  final captionFs = 9 * fontSizeScale * pageScale;
  // A6 grid columns are narrow: allow one more caption line.
  final captionLines = asList ? 8 : (small ? 3 : 2);

  // Grid: columns × rows per page from the page size (A4 2×3, landscape 3×2,
  // A5 2×2, A6 2×2). List: rows per page; the photo takes ~40% of the width.
  final cols = asList ? 1 : (landscape ? 3 : 2);
  final rowsPerPage = asList
      ? (small ? 2 : (landscape ? 2 : 3))
      : (small ? 2 : (landscape || pageFormat.height < PdfPageFormat.a4.height ? 2 : 3));
  // Leave room for the heading and footer; each row = photo + caption + gap.
  final rowHeight = (usable - 90) / rowsPerPage;
  final imageHeight =
      rowHeight - 10 - (asList ? 0 : 3 + captionLines * captionFs * 1.4);

  // Photo at its own aspect ratio, capped at imageHeight — no frame, so the
  // caption sits right under the picture.
  pw.Widget image(PdfAttachmentImage a) => pw.ConstrainedBox(
        constraints: pw.BoxConstraints(maxHeight: imageHeight),
        child: pw.Image(pw.MemoryImage(a.bytes), fit: pw.BoxFit.contain),
      );

  pw.Widget caption(String? text) => (text == null || text.trim().isEmpty)
      ? pw.SizedBox()
      : pw.Text(text.trim(),
          maxLines: captionLines,
          textAlign: asList ? pw.TextAlign.left : pw.TextAlign.center,
          style: pw.TextStyle(
              fontSize: captionFs,
              fontStyle: asList ? pw.FontStyle.normal : pw.FontStyle.italic,
              color: PdfColors.grey700));

  final rows = <pw.Widget>[];
  for (var i = 0; i < photos.length; i += cols) {
    final chunk = photos.skip(i).take(cols).toList();
    rows.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: asList
          ? pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    flex: 4,
                    child: pw.Align(
                        alignment: pw.Alignment.topLeft,
                        child: image(chunk.single))),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${i + 1}.',
                          style: pw.TextStyle(
                              fontSize: captionFs,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      caption(chunk.single.caption),
                    ],
                  ),
                ),
              ],
            )
          : pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < cols; c++) ...[
                  if (c > 0) pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: c < chunk.length
                        ? pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              image(chunk[c]),
                              pw.SizedBox(height: 4),
                              caption(chunk[c].caption),
                            ],
                          )
                        : pw.SizedBox(),
                  ),
                ],
              ],
            ),
    ));
  }

  // Heading travels with the first row so it's never left alone at the
  // bottom of a page. Inseparable: MultiPage would otherwise split the
  // Column (and any Container around it) across pages.
  return [
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 14 * pageScale),
          pw.Text('Attachments',
              style: pw.TextStyle(
                  fontSize: 12 * fontSizeScale * pageScale,
                  fontWeight: pw.FontWeight.bold)),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400, height: 12 * pageScale),
          rows.first,
        ],
      ),
    ),
    ...rows.skip(1),
  ];
}

/// "N photo(s) attached" line for the invoice body (beside / under the
/// totals), pointing at the Attachments section.
String attachedPhotosNote(int count) =>
    '$count photo${count == 1 ? '' : 's'} attached - see Attachments below';
