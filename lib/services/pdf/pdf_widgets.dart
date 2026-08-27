import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/utils/amount_in_words.dart';

/// Tracks how much table-row height has been painted so far, so the
/// watermark image reads as one continuous strip running down the items
/// table (and across page breaks) instead of resetting per row/page.
class _WatermarkCursor {
  double value = 0;
}

/// Paints a vertical slice of [image] into each row's box, using [cursor]
/// to pick up where the previous row left off. Draws two copies scaledH
/// apart so a row straddling the image's repeat seam is still covered
/// seamlessly by the clip.
class _WatermarkStripeImage extends pw.DecorationGraphic {
  _WatermarkStripeImage({
    required this.image,
    required this.opacity,
    required this.cursor,
  });

  final pw.ImageProvider image;
  final double opacity;
  final _WatermarkCursor cursor;

  @override
  void paint(pw.Context context, PdfRect box) {
    if (box.width <= 0 || box.height <= 0) return;
    final resolved = image.resolve(context, box.size);
    final imgW = resolved.width.toDouble();
    final imgH = resolved.height.toDouble();
    if (imgW <= 0 || imgH <= 0) return;

    final scale = box.width / imgW;
    final scaledH = imgH * scale;
    if (scaledH <= 0) return;

    final topDepth = cursor.value % scaledH;
    cursor.value += box.height;

    final rowTopY = box.y + box.height;
    final originY = rowTopY + topDepth - scaledH;

    context.canvas
      ..saveContext()
      ..drawBox(box)
      ..clipPath()
      ..setGraphicState(PdfGraphicState(opacity: opacity))
      ..drawImage(resolved, box.x, originY, box.width, scaledH)
      ..drawImage(resolved, box.x, originY - scaledH, box.width, scaledH)
      ..restoreContext();
  }
}

pw.Widget buildCompanyLogo(pw.MemoryImage image, {double size = 90}) {
  final iw = image.width;
  final ih = image.height;
  final aspect = (iw != null && ih != null && ih > 0) ? iw / ih : 1.0;
  final width = (size * aspect).clamp(size * 0.6, size * 3.5);
  return pw.Container(
    width: width,
    height: size,
    child: pw.Image(image, fit: pw.BoxFit.contain),
  );
}

double logoSizePx(String sizeKey) => logoSizeFromKey(sizeKey).pixelSize;

double signatureSizePx(String sizeKey) => signatureSizeFromKey(sizeKey).pixelHeight;

pw.Widget buildSignatureWidget(
  pw.ImageProvider signatureImage,
  String position, {
  double imageHeight = 50,
  double labelGap = 4,
  double labelFontSize = 9,
}) {
  final isLeft = position != 'right';
  return pw.Align(
    alignment: isLeft ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
    child: pw.Column(
      crossAxisAlignment:
          isLeft ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
      children: [
        pw.Image(signatureImage, height: imageHeight),
        pw.SizedBox(height: labelGap),
        pw.Text('Authorised Signature',
            style: pw.TextStyle(
                fontSize: labelFontSize, color: PdfColors.grey600)),
      ],
    ),
  );
}

pw.Widget buildBankUpiRow({
  BankAccount? bankAccount,
  bool showUpiQr = false,
  String? upiId,
  required String companyName,
  required double amount,
  required String currencyCode,
  required String invoiceId,
  required PdfColor accentColor,
  double gap = 12,
  double qrSize = 90.0,
  double bankFontSize = 7.5,
  double sectionTitleFontSize = 8,
  double sectionPadding = 8,
  double upiIdFontSize = 7,
  double upiAmountFontSize = 7,
}) {
  if (bankAccount == null && !(showUpiQr && upiId != null)) {
    return pw.SizedBox();
  }
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (bankAccount != null)
        buildBankDetailsSection(
          bankAccount: bankAccount,
          accentColor: accentColor,
          titleFontSize: sectionTitleFontSize,
          rowFontSize: bankFontSize,
          padding: sectionPadding,
        ),
      if (showUpiQr && upiId != null) ...[
        pw.SizedBox(width: gap),
        buildUpiQrSection(
          upiId: upiId,
          companyName: companyName,
          amount: amount,
          currencyCode: currencyCode,
          invoiceId: invoiceId,
          accentColor: accentColor,
          qrSize: qrSize,
          titleFontSize: sectionTitleFontSize,
          padding: sectionPadding,
          idFontSize: upiIdFontSize,
          amountFontSize: upiAmountFontSize,
        ),
      ],
    ],
  );
}

pw.Widget buildBankDetailsSection({
  required BankAccount bankAccount,
  required PdfColor accentColor,
  double titleFontSize = 8,
  double rowFontSize = 7.5,
  double padding = 8,
}) {
  pw.Widget row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontSize: rowFontSize, color: PdfColors.grey600),
              ),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                    fontSize: rowFontSize, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  return pw.Container(
    padding: pw.EdgeInsets.all(padding),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: accentColor, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          'Bank Account Details',
          style: pw.TextStyle(
            fontSize: titleFontSize,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
          ),
        ),
        pw.SizedBox(height: 5),
        if (bankAccount.label.isNotEmpty)
          row('Account Name', bankAccount.label),
        if (bankAccount.bankName.isNotEmpty)
          row('Bank', bankAccount.bankName),
        row('Account No.', bankAccount.accountNumber),
        if (bankAccount.ifscCode.isNotEmpty)
          row('IFSC Code', bankAccount.ifscCode),
      ],
    ),
  );
}

/// Renders a bordered box with QR code, UPI ID, and amount.
/// Uses pw.CustomPaint to draw QR matrix pixel-by-pixel (no Flutter widget dep).
pw.Widget buildUpiQrSection({
  required String upiId,
  required String companyName,
  required double amount,
  required String currencyCode,
  required String invoiceId,
  required PdfColor accentColor,
  double qrSize = 90.0,
  double titleFontSize = 8,
  double idFontSize = 7,
  double amountFontSize = 7,
  double padding = 8,
}) {
  final encodedName = Uri.encodeComponent(companyName);
  final encodedNote = Uri.encodeComponent('Invoice $invoiceId');
  final upiUri = 'upi://pay?pa=$upiId&pn=$encodedName'
      '&am=${amount.toStringAsFixed(2)}'
      '&cu=${currencyCode.toUpperCase()}'
      '&tn=$encodedNote';

  QrCode? qrCode;
  try {
    qrCode = QrCode.fromData(
      data: upiUri,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
  } catch (_) {
    return pw.SizedBox();
  }

  final qrImage = QrImage(qrCode);
  final int moduleCount = qrCode.moduleCount;

  return pw.Container(
    padding: pw.EdgeInsets.all(padding),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: accentColor, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Pay via UPI',
          style: pw.TextStyle(
            fontSize: titleFontSize,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.CustomPaint(
          size: PdfPoint(qrSize, qrSize),
          painter: (canvas, size) {
            final double moduleSize = qrSize / moduleCount;
            canvas.setFillColor(PdfColors.black);
            for (int row = 0; row < moduleCount; row++) {
              for (int col = 0; col < moduleCount; col++) {
                if (qrImage.isDark(row, col)) {
                  final double x = col * moduleSize;
                  final double y = (moduleCount - row - 1) * moduleSize;
                  canvas
                    ..drawRect(x, y, moduleSize, moduleSize)
                    ..fillPath();
                }
              }
            }
          },
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          upiId,
          style: pw.TextStyle(fontSize: idFontSize, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          '${currencyCode.toUpperCase()} ${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: amountFontSize,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );
}

/// Rounds [net] to the nearest whole currency unit for the "Net Amount"
/// row. Returns the rounded value and the round-off diff (rounded - net),
/// e.g. net=1234.56 -> (rounded: 1235.0, roundOff: 0.44).
({double rounded, double roundOff}) roundNetTotal(double net) {
  final rounded = net.roundToDouble();
  return (rounded: rounded, roundOff: rounded - net);
}

pw.Widget buildEnhancedTotals(
    Invoice invoice,
    PdfColor accentRowColor,
    PdfColor primaryColor,
    PdfColor totalHighlightColor,
    String currencySymbol,
    {double previousBalanceDue = 0.0,
    double fontSize = 10,
    bool compact = false,
    bool showCgstSgst = false,
    bool showRoundOff = false}) {
  final hasPaid = invoice.amountPaid > 0;
  final isPaidInFull = invoice.outstandingBalance <= 0;
  final hasPreviousBalance = previousBalanceDue > 0;
  final totalDue = invoice.total + previousBalanceDue;
  final netTotal = roundNetTotal(hasPreviousBalance ? totalDue : invoice.total);

  final compactStyle = compact ? compactPdfTotalsStyle : null;
  final totalWidth = compactStyle?.width ?? 200.0;
  final rowFontSize = compactStyle?.rowFontSize ?? fontSize;
  final highlightFontSize = compactStyle?.highlightFontSize ?? fontSize * 1.05;
  final highlightHorizontalPadding =
      compactStyle?.highlightHorizontalPadding ??
          (fontSize * 0.8).clamp(5.0, 8.0);
  final highlightVerticalPadding = compactStyle?.highlightVerticalPadding ??
      (fontSize * 0.8).clamp(5.0, 8.0);
  final rowHorizontalPadding = compactStyle?.rowHorizontalPadding;
  final rowVerticalPadding = compactStyle?.rowVerticalPadding;
  final borderRadius = compactStyle?.borderRadius ?? 6.0;

  final totalsBox = pw.Container(
    width: totalWidth,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(borderRadius),
    ),
    child: pw.Column(
      children: [
        pdfTotalRow(
          "Subtotal",
          "$currencySymbol ${(invoice.totalDiscount > 0 ? invoice.grossSubtotal : invoice.subtotal).toStringAsFixed(2)}",
          fontSize: rowFontSize,
          horizontalPadding: rowHorizontalPadding,
          verticalPadding: rowVerticalPadding,
        ),
        if (invoice.totalDiscount > 0)
          pdfTotalRow(
            "Discount",
            "-$currencySymbol ${invoice.totalDiscount.toStringAsFixed(2)}",
            color: PdfColors.orange800,
            fontSize: rowFontSize,
            horizontalPadding: rowHorizontalPadding,
            verticalPadding: rowVerticalPadding,
          ),
        if (invoice.taxMode != TaxMode.none && !showCgstSgst)
          pdfTotalRow(invoiceTaxLabel(invoice),
              "$currencySymbol ${invoice.tax.toStringAsFixed(2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
        if (invoice.taxMode != TaxMode.none && showCgstSgst) ...[
          pdfTotalRow("CGST", "$currencySymbol ${(invoice.tax / 2).toStringAsFixed(2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
          pdfTotalRow("SGST", "$currencySymbol ${(invoice.tax / 2).toStringAsFixed(2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
        ],
        ...invoice.additionalCosts.map((c) => pdfTotalRow(
              c.label.isEmpty ? 'Extra Cost' : c.label,
              "$currencySymbol ${c.amount.toStringAsFixed(2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding,
            )),
        if (invoice.invoiceDiscountAmount > 0)
          pdfTotalRow(
            invoice.invoiceDiscountType == InvoiceDiscountType.percent
                ? "Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%)"
                : "Extra Discount ",
            "-$currencySymbol ${invoice.invoiceDiscountAmount.toStringAsFixed(2)}",
            color: PdfColors.orange800,
            fontSize: rowFontSize,
            horizontalPadding: rowHorizontalPadding,
            verticalPadding: rowVerticalPadding,
          ),
        pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: highlightHorizontalPadding,
            vertical: highlightVerticalPadding,
          ),
          decoration: pw.BoxDecoration(
            color: totalHighlightColor,
            borderRadius: hasPaid || hasPreviousBalance
                ? pw.BorderRadius.zero
                : const pw.BorderRadius.vertical(
                    bottom: pw.Radius.circular(5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total",
                  style: pw.TextStyle(
                      fontSize: highlightFontSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.Text("$currencySymbol ${invoice.total.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontSize: highlightFontSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
            ],
          ),
        ),
        if (hasPreviousBalance) ...[
          pdfTotalRow(
            "Previous Balance Due",
            "$currencySymbol ${previousBalanceDue.toStringAsFixed(2)}",
            color: PdfColors.orange800,
            fontSize: rowFontSize,
            horizontalPadding: rowHorizontalPadding,
            verticalPadding: rowVerticalPadding,
          ),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(
              horizontal: highlightHorizontalPadding,
              vertical: highlightVerticalPadding,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange800,
              borderRadius: hasPaid
                  ? pw.BorderRadius.zero
                  : const pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Due",
                    style: pw.TextStyle(
                        fontSize: highlightFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text("$currencySymbol ${totalDue.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: highlightFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ],
            ),
          ),
        ],
        if (showRoundOff) ...[
          pdfTotalRow(
            "Round off",
            "$currencySymbol ${netTotal.roundOff.toStringAsFixed(2)}",
            fontSize: rowFontSize,
            horizontalPadding: rowHorizontalPadding,
            verticalPadding: rowVerticalPadding,
          ),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(
              horizontal: highlightHorizontalPadding,
              vertical: highlightVerticalPadding,
            ),
            decoration: pw.BoxDecoration(
              color: totalHighlightColor,
              borderRadius: hasPaid
                  ? pw.BorderRadius.zero
                  : const pw.BorderRadius.vertical(bottom: pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Net Amount",
                    style: pw.TextStyle(
                        fontSize: highlightFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text("$currencySymbol ${netTotal.rounded.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: highlightFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ],
            ),
          ),
        ],
        if (hasPaid) ...[
          pdfTotalRow(
            "Amount Paid",
            "$currencySymbol ${invoice.amountPaid.toStringAsFixed(2)}",
            fontSize: rowFontSize,
            horizontalPadding: rowHorizontalPadding,
            verticalPadding: rowVerticalPadding,
          ),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(
              horizontal: highlightHorizontalPadding,
              vertical: highlightVerticalPadding,
            ),
            decoration: pw.BoxDecoration(
              color: isPaidInFull ? PdfColors.green700 : PdfColors.orange,
              borderRadius: const pw.BorderRadius.vertical(
                  bottom: pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isPaidInFull ? "PAID IN FULL" : "Amount Due",
                  style: pw.TextStyle(
                      fontSize: highlightFontSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white),
                ),
                if (!isPaidInFull)
                  pw.Text(
                    "$currencySymbol ${invoice.outstandingBalance.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: highlightFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white),
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  if (!showRoundOff) return totalsBox;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      totalsBox,
      pw.SizedBox(height: 6),
      pw.SizedBox(
        width: totalWidth,
        child: pw.Text(AmountInWords.amount(netTotal.rounded,
                indian: invoice.currencyCode == 'INR'),
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
                fontSize: rowFontSize - 1,
                fontStyle: pw.FontStyle.italic)),
      ),
    ],
  );
}

/// Tax line label for invoice totals (e.g. "Tax (18%)", "Tax (per item)").
/// Not to be confused with [taxLabel] from common.dart (company GSTIN label).
String invoiceTaxLabel(Invoice invoice) {
  switch (invoice.taxMode) {
    case TaxMode.global:
      return "Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%)";
    case TaxMode.perItem:
      return "Tax";
    case TaxMode.none:
      return "Tax";
  }
}

pw.Widget pdfTotalRow(String label, String value,
    {PdfColor? color,
    double fontSize = 10,
    double? horizontalPadding,
    double? verticalPadding}) {
  final style = pw.TextStyle(fontSize: fontSize, color: color);
  final p = (fontSize * 0.5).clamp(4.0, 8.0);
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(
      horizontal: horizontalPadding ?? p,
      vertical: verticalPadding ?? p * 0.75,
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Flexible(child: pw.Text(label, style: style)),
        pw.Flexible(child: pw.Text(value, style: style)),
      ],
    ),
  );
}

pw.Widget buildInvoiceTable(Invoice invoice,
    InvoiceTemplate template,
    {PdfColor headerColor = PdfColors.grey200,
    PdfColor textColor = PdfColors.black,
    bool showGst = true,
    bool showQuantity = true,
    bool showDiscount = true,
    bool showTypeTag = true,
    bool showAliasName = false,
    bool showDescription = false,
    BusinessType businessType = BusinessType.both,
    double tableFontSize = 10,
    double cellPaddingH = 6,
    double cellPaddingV = 8,
    String? totalQuantityText,
    pw.TableBorder? border,
    Uint8List? watermarkBytes,
    double watermarkOpacity = 0.12,
    bool showCgstSgst = false,}) {
  final bool showItemTax = invoice.taxMode == TaxMode.perItem;
  final bool isGlobalTaxMode = invoice.taxMode == TaxMode.global;
  final bool splitCgstSgst =
      (showItemTax || isGlobalTaxMode) && showCgstSgst;
  final double globalTaxRatePercent = invoice.taxRate * 100;
  final watermarkImage =
      watermarkBytes != null ? pw.MemoryImage(watermarkBytes) : null;
  final watermarkCursor = _WatermarkCursor();
  final String priceHeader = showQuantity ? 'Price' : 'Rate';

  int col = 0;
  final Map<int, pw.TableColumnWidth> colWidths = {
    col++: const pw.FlexColumnWidth(1),
    col++: showGst ? const pw.FlexColumnWidth(3) : const pw.FlexColumnWidth(4),
    if (showGst) col: const pw.FlexColumnWidth(1.4),
  };
  if (showGst) col++;
  if (showQuantity) colWidths[col++] = const pw.FlexColumnWidth(1);
  colWidths[col++] = const pw.FlexColumnWidth(1.5);
  if (splitCgstSgst) {
    colWidths[col++] = const pw.FlexColumnWidth(1.2);
    colWidths[col++] = const pw.FlexColumnWidth(1.2);
  } else if (showItemTax) {
    colWidths[col++] = const pw.FlexColumnWidth(1);
  }
  if (showDiscount) {
    colWidths[col++] = const pw.FlexColumnWidth(1.2);
  }
  colWidths[col++] = const pw.FlexColumnWidth(1.5);

  // pw.Table has no colspan, so a full-width description row can't live
  // inside one Table with the item rows. Instead each logical row
  // (header/item/totals) is its own single-row Table sharing colWidths
  // (FlexColumnWidth ratios are content-independent, so widths still line
  // up) + border, with description blocks slotted between as plain
  // full-width widgets. Adjacent mini-tables' borders land on the same
  // pixels, so a bordered template (gridClassic) still reads as one
  // continuous grid.
  pw.Widget rowTable(pw.TableRow tableRow) => pw.Table(
        columnWidths: colWidths,
        border: border,
        children: [tableRow],
      );

  pw.Widget dividerLine() => pw.Container(height: 1, color: PdfColors.grey400);

  // Description rows aren't cells in a Table, so to start the text under
  // "Item Name" (not the page edge, under "Sl No") we rebuild the Sl No
  // column's share of the width as a Row flex — ×10 keeps the one-decimal
  // FlexColumnWidth values (e.g. 1.4) exact as ints, which is all Expanded
  // accepts. This only works because every column here is FlexColumnWidth.
  final slNoFlex = ((colWidths[0]! as pw.FlexColumnWidth).flex * 10).round();
  final restFlex = colWidths.values.fold<int>(
          0, (sum, w) => sum + ((w as pw.FlexColumnWidth).flex * 10).round()) -
      slNoFlex;

  pw.BoxDecoration? rowDecoration(PdfColor? rowColor) {
    if (rowColor == null && watermarkImage == null) return null;
    return pw.BoxDecoration(
      color: rowColor,
      image: watermarkImage != null
          ? _WatermarkStripeImage(
              image: watermarkImage,
              opacity: watermarkOpacity,
              cursor: watermarkCursor,
            )
          : null,
    );
  }

  final headerRow = pw.TableRow(
    decoration: (template == InvoiceTemplate.gridClassic) ? null : pw.BoxDecoration(color: headerColor),
    children: [
      buildTableCell('Sl No',
          isHeader: true,
          textColor: textColor,
          fontSize: tableFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV),
      buildTableCell('Item Name',
          isHeader: true,
          textColor: textColor,
          fontSize: tableFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV),
      if (showGst)
        buildTableCell('HSN/SAC',
            isHeader: true,
            textColor: textColor,
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      if (showQuantity)
        buildTableCell(
            invoice.quantityLabel?.isNotEmpty == true
                ? invoice.quantityLabel!
                : 'Qty',
            isHeader: true,
            textColor: textColor,
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      buildTableCell(priceHeader,
          isHeader: true,
          textColor: textColor,
          fontSize: tableFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV),
      if (splitCgstSgst) ...[
        buildTableCell('CGST',
            isHeader: true,
            textColor: textColor,
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
        buildTableCell('SGST',
            isHeader: true,
            textColor: textColor,
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      ] else if (showItemTax)
        buildTableCell('Tax %',
            isHeader: true,
            textColor: textColor,
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      if (showDiscount)
        buildTableCell('Discount',
            isHeader: true,
            textColor: textColor,
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      buildTableCell('Total',
          isHeader: true,
          textColor: textColor,
          fontSize: tableFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV),
    ],
  );

  final itemWidgets = <pw.Widget>[];
  invoice.items.asMap().forEach((index, item) {
    final rowColor = (template == InvoiceTemplate.gridClassic)
        ? null
        : (index % 2 == 0 ? PdfColors.white : PdfColors.grey100);
    itemWidgets.add(rowTable(pw.TableRow(
      decoration: rowDecoration(rowColor),
      children: [
        buildTableCell('${index + 1}',
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(
            horizontal: cellPaddingH,
            vertical: (showTypeTag && businessType == BusinessType.both || showDiscount &&
                item.discountPerUnit &&
                item.discount > 0) ? cellPaddingV * 0.5 : cellPaddingV,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(item.product.displayName(showAliasName),
                  style: pw.TextStyle(fontSize: tableFontSize * 0.9)),
              if (showTypeTag && businessType == BusinessType.both)
                pw.Text(
                  item.product.type == 'service' ? 'Service' : 'Product',
                  style: pw.TextStyle(
                    fontSize: tableFontSize * 0.7,
                    color: item.product.type == 'service'
                        ? PdfColors.purple700
                        : PdfColors.indigo700,
                  ),
                ),
              if (showDiscount &&
                  item.discountPerUnit &&
                  item.discount > 0)
                pw.Text(
                  '(${item.effectivePrice.toStringAsFixed(2)} - ${item.discount.toStringAsFixed(2)} = ${(item.effectivePrice - item.discount).toStringAsFixed(2)}/item)',
                  style: pw.TextStyle(
                      fontSize: tableFontSize * 0.7,
                      color: PdfColors.teal700),
                ),
            ],
          ),
        ),
        if (showGst)
          buildTableCell(item.product.hsncode,
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV),
        if (showQuantity)
          buildTableCell(
              '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toString()}'
              '${item.effectiveUnit.trim().isEmpty ? '' : ' ${item.effectiveUnit}'}',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV),
        buildTableCell(
            showDiscount
                ? item.effectivePrice.toStringAsFixed(2)
                : (item.total / item.quantity).toStringAsFixed(2),
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
        if (splitCgstSgst) ...[
          buildTableCell(
              '${(isGlobalTaxMode ? (invoice.subtotal > 0 ? invoice.tax * (item.total / invoice.subtotal) / 2 : 0.0) : item.taxAmount / 2).toStringAsFixed(2)}\n(${(isGlobalTaxMode ? globalTaxRatePercent : item.product.tax_rate) / 2}%)',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV),
          buildTableCell(
              '${(isGlobalTaxMode ? (invoice.subtotal > 0 ? invoice.tax * (item.total / invoice.subtotal) / 2 : 0.0) : item.taxAmount / 2).toStringAsFixed(2)}\n(${(isGlobalTaxMode ? globalTaxRatePercent : item.product.tax_rate) / 2}%)',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV),
        ] else if (showItemTax)
          buildTableCell('${item.product.tax_rate}%',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV),
        if (showDiscount)
          buildTableCell(item.totalDiscount.toStringAsFixed(2),
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV),
        buildTableCell(item.total.toStringAsFixed(2),
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      ],
    )));

    final description = item.product.description.trim();
    if (showDescription && description.isNotEmpty) {
      itemWidgets.add(pw.Container(
        decoration: rowDecoration(rowColor),
        child: pw.Row(
          children: [
            pw.Expanded(flex: slNoFlex, child: pw.SizedBox()),
            pw.Expanded(
              flex: restFlex,
              child: pw.Padding(
                padding: pw.EdgeInsets.fromLTRB(
                    cellPaddingH, 0, cellPaddingH, cellPaddingV),
                child: pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: tableFontSize * 0.85,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ));
    }
  });

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      rowTable(headerRow),
      ...itemWidgets,
      if (template != InvoiceTemplate.gridClassic) dividerLine(),
      if (totalQuantityText != null)
        rowTable(pw.TableRow(
          children: [
            buildTableCell('',
                fontSize: tableFontSize,
                cellPaddingH: cellPaddingH,
                cellPaddingV: cellPaddingV),
            buildTableCell('Total',
                isHeader: true,
                fontSize: tableFontSize,
                cellPaddingH: cellPaddingH,
                cellPaddingV: cellPaddingV),
            if (showGst)
              buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            if (showQuantity)
              buildTableCell(totalQuantityText,
                  isHeader: true,
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            buildTableCell('',
                fontSize: tableFontSize,
                cellPaddingH: cellPaddingH,
                cellPaddingV: cellPaddingV),
            if (splitCgstSgst) ...[
              buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
              buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            ] else if (showItemTax)
              buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            if (showDiscount)
              buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            buildTableCell('',
                fontSize: tableFontSize,
                cellPaddingH: cellPaddingH,
                cellPaddingV: cellPaddingV),
          ],
        )),
      if (totalQuantityText != null && template != InvoiceTemplate.gridClassic) dividerLine(),
    ],
  );
}

pw.Widget buildTableCell(String text,
    {bool isHeader = false,
    PdfColor textColor = PdfColors.black,
    double fontSize = 10,
    double cellPaddingH = 6,
    double cellPaddingV = 8}) {
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(
        horizontal: cellPaddingH, vertical: cellPaddingV),
    child: pw.Text(
      text,
      style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: fontSize,
          color: textColor),
    ),
  );
}

pw.Widget buildAdditionalNotes(Invoice invoice,
    {double fontSize = 10, PdfColor accentColor = PdfColors.grey700}) {
  final notes = invoice.notes ?? '';
  if (notes.isEmpty) return pw.SizedBox();
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border(left: pw.BorderSide(color: accentColor, width: 2.5)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('NOTES',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: fontSize - 1,
                letterSpacing: 0.8,
                color: accentColor)),
        pw.SizedBox(height: 3),
        pw.Text(
          notes,
          style: pw.TextStyle(
              fontStyle: pw.FontStyle.italic,
              fontWeight: pw.FontWeight.normal,
              fontSize: fontSize,
              color: PdfColors.grey700),
        ),
      ],
    ),
  );
}

// Locale pinned to 'en_US' regardless of the app's UI language: PDF dates
// must stay stable for the recipient, and DateFormat with no explicit
// locale follows Intl.defaultLocale (set to the app language, e.g. 'bo' for
// Tibetan) — 'bo' has no intl locale data at all, so that throws.
String formatPdfDate(DateTime date, String pattern) {
  return DateFormat(pattern, 'en_US').format(date);
}

String formatInvoiceNumberForDisplay(String number, bool showLeadingZeros) {
  if (showLeadingZeros) return number;
  final stripped = number.replaceFirst(RegExp(r'^0+'), '');
  return stripped.isEmpty ? '0' : stripped;
}
