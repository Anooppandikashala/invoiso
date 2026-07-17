import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/models/invoice.dart';

pw.Widget buildCompanyLogo(pw.MemoryImage image, {double size = 90}) {
  return pw.Container(
    width: size,
    height: size,
    child: pw.Image(image, fit: pw.BoxFit.contain),
  );
}

double logoSizePx(String sizeKey) {
  switch (sizeKey) {
    case 'small':
      return 60;
    case 'large':
      return 120;
    default:
      return 90;
  }
}

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

pw.Widget buildBankDetailsSection({
  required BankAccount bankAccount,
  required PdfColor accentColor,
}) {
  pw.Widget row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
              ),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                    fontSize: 7.5, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
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
            fontSize: 8,
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
}) {
  const double qrSize = 90.0;
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
    padding: const pw.EdgeInsets.all(8),
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
            fontSize: 8,
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
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          '${currencyCode.toUpperCase()} ${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );
}

pw.Widget buildEnhancedTotals(
    Invoice invoice,
    PdfColor accentRowColor,
    PdfColor primaryColor,
    PdfColor totalHighlightColor,
    String currencySymbol,
    {double previousBalanceDue = 0.0,
    double fontSize = 10,
    bool compact = false}) {
  final hasPaid = invoice.amountPaid > 0;
  final isPaidInFull = invoice.outstandingBalance <= 0;
  final hasPreviousBalance = previousBalanceDue > 0;
  final totalDue = invoice.total + previousBalanceDue;

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

  return pw.Container(
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
        if (invoice.taxMode != TaxMode.none)
          pdfTotalRow(invoiceTaxLabel(invoice),
              "$currencySymbol ${invoice.tax.toStringAsFixed(2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
        ...invoice.additionalCosts.map((c) => pdfTotalRow(
              c.label.isEmpty ? 'Extra Cost' : c.label,
              "$currencySymbol ${c.amount.toStringAsFixed(2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding,
            )),
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
}

/// Tax line label for invoice totals (e.g. "Tax (18%)", "Tax (per item)").
/// Not to be confused with [taxLabel] from common.dart (company GSTIN label).
String invoiceTaxLabel(Invoice invoice) {
  switch (invoice.taxMode) {
    case TaxMode.global:
      return "Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%)";
    case TaxMode.perItem:
      return "Tax (per item)";
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
  final p = (fontSize * 0.8).clamp(5.0, 8.0);
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(
      horizontal: horizontalPadding ?? p,
      vertical: verticalPadding ?? p * 0.75,
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}

pw.Widget buildInvoiceTable(Invoice invoice,
    {PdfColor headerColor = PdfColors.grey200,
    PdfColor textColor = PdfColors.black,
    bool showGst = true,
    bool showQuantity = true,
    bool showDiscount = true,
    bool showTypeTag = true,
    bool showAliasName = false,
    BusinessType businessType = BusinessType.both,
    double tableFontSize = 10,
    double cellPaddingH = 6,
    double cellPaddingV = 8,
    String? totalQuantityText}) {
  final bool showItemTax = invoice.taxMode == TaxMode.perItem;
  final String priceHeader = showQuantity ? 'Price' : 'Rate';

  int col = 0;
  final Map<int, pw.TableColumnWidth> colWidths = {
    col++: const pw.FlexColumnWidth(1),
    col++: const pw.FlexColumnWidth(3),
    if (showGst) col: const pw.FlexColumnWidth(2),
  };
  if (showGst) col++;
  if (showQuantity) colWidths[col++] = const pw.FlexColumnWidth(1);
  colWidths[col++] = const pw.FlexColumnWidth(1.5);
  if (showItemTax) colWidths[col++] = const pw.FlexColumnWidth(1);
  if (showDiscount) {
    colWidths[col++] = const pw.FlexColumnWidth(1.5);
  }
  colWidths[col++] = const pw.FlexColumnWidth(1.5);
  final columnCount = col;

  pw.TableRow dividerRow() {
    return pw.TableRow(
      children: List.generate(
        columnCount,
        (_) => pw.Container(height: 1, color: PdfColors.grey400),
      ),
    );
  }

  return pw.Table(
    columnWidths: colWidths,
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: headerColor),
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
            buildTableCell('HSN Code',
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
          if (showItemTax)
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
      ),
      ...invoice.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return pw.TableRow(
          decoration: index % 2 == 0
              ? const pw.BoxDecoration(color: PdfColors.white)
              : const pw.BoxDecoration(color: PdfColors.grey100),
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
                  item.quantity == item.quantity.roundToDouble()
                      ? item.quantity.toInt().toString()
                      : item.quantity.toString(),
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
            if (showItemTax)
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
        );
      }),
      dividerRow(),
      if (totalQuantityText != null)
        pw.TableRow(
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
            if (showItemTax)
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
        ),
      if (totalQuantityText != null) dividerRow(),
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

pw.Widget buildAdditionalNotes(Invoice invoice) {
  return pw.Align(
    alignment: pw.Alignment.centerLeft,
    child: pw.Text(
      invoice.notes ?? '',
      style: pw.TextStyle(
          fontStyle: pw.FontStyle.italic,
          fontWeight: pw.FontWeight.normal,
          fontSize: 10,
          color: PdfColors.grey700),
    ),
  );
}

String formatPdfDate(DateTime date, String pattern) {
  return DateFormat(pattern).format(date);
}
