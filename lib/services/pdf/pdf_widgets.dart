import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/customer_field_settings.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/utils/amount_in_words.dart';
import 'package:invoiso/utils/formatters.dart';

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
  const _WatermarkStripeImage({
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

/// Full-page watermark: one copy of [bytes] scaled to fit the page,
/// centered, at [opacity]. Used when watermark mode is "full page"
/// instead of the per-row items-table strip above.
pw.Widget buildFullPageWatermark(Uint8List bytes, double opacity) {
  return pw.FullPage(
    ignoreMargins: true,
    child: pw.Opacity(
      opacity: opacity,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(48),
        child: pw.Center(
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        ),
      ),
    ),
  );
}

/// Diagonal stamp drawn over every page of a declined (voided) invoice.
pw.Widget buildDeclinedStamp() {
  return pw.FullPage(
    ignoreMargins: true,
    child: pw.Center(
      child: pw.Transform.rotateBox(
        angle: 0.6,
        child: pw.Opacity(
          opacity: 0.25,
          child: pw.Text('DECLINED',
              style: pw.TextStyle(
                  fontSize: 72,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red)),
        ),
      ),
    ),
  );
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

double getSlNumberFlex(PdfPageFormat format, InvoiceTemplate template, bool isLandscape)
{
   if(template != InvoiceTemplate.gridClassic) return 0.9;
   if(format == PdfPageFormat.a4) return isLandscape ? 0.9 : 0.6;
   if(format == PdfPageFormat.a5) return isLandscape ? 0.6 : 0.7;
   return isLandscape ? 0.7 : 0.8;
}

// ── Product-metadata snapshot columns (A4 templates only) ─────────────────

double _metaColFlex(String key) =>
    (key == 'expiryDate' || key == 'manufactureDate') ? 1.6
        : (key == 'notes') ? 2.2
        : 1.4;

String _metaHeaderText(String key, {bool short = false}) {
  switch (key) {
    case 'storageLocation':
      return 'Storage';
    case 'containerNumber':
      return 'Container No.';
    case 'batchNumber':
      return 'Batch No.';
    case 'expiryDate':
      return 'Expiry';
    case 'manufactureDate':
      return 'Mfg. Date';
    case 'manufactureName':
      return short ? 'Mfr.' : 'Mfr. Name';
    case 'supplierName':
      return 'Supplier';
    case 'skuCode':
      return 'SKU';
    case 'notes':
      return 'Notes';
    default:
      return key;
  }
}

String _metaCellValue(InvoiceItem item, String key, String datePattern) {
  final m = item.metadata;
  if (m == null) return '';
  String fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : DateFormat(datePattern).format(d);
  }

  switch (key) {
    case 'storageLocation':
      return m.storageLocation ?? '';
    case 'containerNumber':
      return m.containerNumber ?? '';
    case 'batchNumber':
      return m.batchNumber ?? '';
    case 'expiryDate':
      return fmtDate(m.expiryDate);
    case 'manufactureDate':
      return fmtDate(m.manufactureDate);
    case 'manufactureName':
      return m.manufactureName ?? '';
    case 'supplierName':
      return m.supplierName ?? '';
    case 'skuCode':
      return m.skuCode ?? '';
    case 'notes':
      return m.notes ?? '';
    default:
      return '';
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
        if (bankAccount.iban.isNotEmpty)
          row('IBAN', bankAccount.iban),
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
          '${currencyCode.toUpperCase()} ${AmountFormat.money(amount)}',
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
    double compactScale = 1.0,
    bool showCgstSgst = false,
    bool showIgst = false,
    bool showRoundOff = false}) {
  final hasPaid = invoice.amountPaid > 0;
  final isPaidInFull = invoice.outstandingBalance <= 0;
  final hasPreviousBalance = previousBalanceDue > 0;
  final totalDue = invoice.total + previousBalanceDue;
  final netTotal = roundNetTotal(hasPreviousBalance ? totalDue : invoice.total);

  final compactStyle = compact ? compactPdfTotalsStyle : null;
  // compactScale = user's PDF text size; compact style sizes are fixed otherwise.
  final totalWidth =
      compactStyle != null ? compactStyle.width * compactScale : 200.0;
  final rowFontSize = compactStyle != null
      ? compactStyle.rowFontSize * compactScale
      : fontSize;
  final highlightFontSize = compactStyle != null
      ? compactStyle.highlightFontSize * compactScale
      : fontSize * 1.05;
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
          "$currencySymbol ${AmountFormat.money(invoice.totalDiscount > 0 ? invoice.grossSubtotal : invoice.subtotal)}",
          fontSize: rowFontSize,
          horizontalPadding: rowHorizontalPadding,
          verticalPadding: rowVerticalPadding,
        ),
        if (invoice.totalDiscount > 0)
          pdfTotalRow(
            "Discount",
            "-$currencySymbol ${AmountFormat.money(invoice.totalDiscount)}",
            color: PdfColors.orange800,
            fontSize: rowFontSize,
            horizontalPadding: rowHorizontalPadding,
            verticalPadding: rowVerticalPadding,
          ),
        if (invoice.taxMode != TaxMode.none && !showCgstSgst && !showIgst)
          pdfTotalRow(invoiceTaxLabel(invoice),
              "$currencySymbol ${AmountFormat.money(invoice.tax)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
        if (invoice.taxMode != TaxMode.none && showIgst)
          pdfTotalRow("IGST", "$currencySymbol ${AmountFormat.money(invoice.tax)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
        if (invoice.taxMode != TaxMode.none && showCgstSgst && !showIgst) ...[
          pdfTotalRow("CGST", "$currencySymbol ${AmountFormat.money(invoice.tax / 2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
          pdfTotalRow("SGST", "$currencySymbol ${AmountFormat.money(invoice.tax / 2)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding),
        ],
        ...invoice.additionalCosts.map((c) => pdfTotalRow(
              c.label.isEmpty ? 'Extra Cost' : c.label,
              c.amount < 0
                  ? "-$currencySymbol ${AmountFormat.money(-c.amount)}"
                  : "$currencySymbol ${AmountFormat.money(c.amount)}",
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding,
            )),
        if (invoice.invoiceDiscountAmount > 0)
          pdfTotalRow(
            invoice.invoiceDiscountType == InvoiceDiscountType.percent
                ? "Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%)"
                : "Extra Discount ",
            "-$currencySymbol ${AmountFormat.money(invoice.invoiceDiscountAmount)}",
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
                : pw.BorderRadius.vertical(
                    bottom: pw.Radius.circular(borderRadius)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total",
                  style: pw.TextStyle(
                      fontSize: highlightFontSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.Text("$currencySymbol ${AmountFormat.money(invoice.total)}",
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
            "$currencySymbol ${AmountFormat.money(previousBalanceDue)}",
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
                  : pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(borderRadius)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Due",
                    style: pw.TextStyle(
                        fontSize: highlightFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text("$currencySymbol ${AmountFormat.money(totalDue)}",
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
            "$currencySymbol ${AmountFormat.money(netTotal.roundOff)}",
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
                  : pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(borderRadius)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Net Amount",
                    style: pw.TextStyle(
                        fontSize: highlightFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text("$currencySymbol ${AmountFormat.money(netTotal.rounded)}",
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
            "$currencySymbol ${AmountFormat.money(invoice.amountPaid)}",
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
              borderRadius: pw.BorderRadius.vertical(
                  bottom: pw.Radius.circular(borderRadius)),
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
                    "$currencySymbol ${AmountFormat.money(invoice.outstandingBalance)}",
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
    PdfPageFormat pageFormat,
    {PdfColor headerColor = PdfColors.grey200,
    PdfColor textColor = PdfColors.black,
    bool showGst = true,
    bool showSlNo = true,
    bool showQuantity = true,
    bool showDiscount = true,
    bool showTypeTag = true,
    bool showAliasName = false,
    bool showDescription = false,
    bool descriptionNewLine = false,
    BusinessType businessType = BusinessType.both,
    double tableFontSize = 10,
    double? tableHeaderFontSize,
    double columnScale = 1.0,
    double cellPaddingH = 6,
    double cellPaddingV = 8,
    String? totalQuantityText,
    pw.TableBorder? border,
    Uint8List? watermarkBytes,
    double watermarkOpacity = 0.12,
    bool showCgstSgst = false,
    bool showIgst = false,
    bool showTaxColumn = true,
    bool isLandscape = false,
    Map<String, bool> metadataColumns = const {},
    String metadataDatePattern = 'dd/MM/yyyy'}) {
  // Optional product-metadata snapshot columns — any A4 template. Order is
  // fixed; only the keys the user enabled are kept.
  final List<String> metaKeys = (pageFormat == PdfPageFormat.a4)
      ? const [
          'storageLocation',
          'containerNumber',
          'batchNumber',
          'manufactureName',
          'manufactureDate',
          'expiryDate',
          'supplierName',
          'skuCode',
          'notes',
        ].where((k) => metadataColumns[k] == true).toList()
      : const <String>[];
  // Metadata columns eat into table width in portrait. Shorten the Discount
  // header to claw back space whenever any are on.
  final bool shortDiscountHeader = !isLandscape && metaKeys.isNotEmpty;
  final bool isGlobalTaxMode = invoice.taxMode == TaxMode.global;
  final bool taxColumnOn = showTaxColumn && invoice.taxMode != TaxMode.none;
  final bool splitCgstSgst = taxColumnOn && showCgstSgst && !showIgst;
  final bool showIgstCol = taxColumnOn && showIgst;
  final double globalTaxRatePercent = invoice.taxRate * 100;
  final watermarkImage =
      watermarkBytes != null ? pw.MemoryImage(watermarkBytes) : null;
  final watermarkCursor = _WatermarkCursor();
  final String priceHeader = showQuantity ? 'Price' : 'Rate';
  // gridClassic centers its Sl No/Qty/Price/Tax columns and right-aligns
  // Discount/Total; every other template keeps the default left alignment
  // unchanged.
  final pw.TextAlign centerOnGridClassic =
      template == InvoiceTemplate.gridClassic ? pw.TextAlign.center : pw.TextAlign.left;
  final pw.TextAlign rightOnGridClassic =
      template == InvoiceTemplate.gridClassic ? pw.TextAlign.right : pw.TextAlign.left;

  int col = 0;
  final Map<int, pw.TableColumnWidth> colWidths = {
    if (showSlNo) col++: pw.FlexColumnWidth(getSlNumberFlex(pageFormat,template,isLandscape)),
    col++: showGst ? const pw.FlexColumnWidth(3) : const pw.FlexColumnWidth(4),
    if (showGst) col: const pw.FlexColumnWidth(1.4),
  };
  if (showGst) col++;
  for (final k in metaKeys) {
    colWidths[col++] = pw.FlexColumnWidth(_metaColFlex(k));
  }
  if (showQuantity) colWidths[col++] = const pw.FlexColumnWidth(1);
  colWidths[col++] = const pw.FlexColumnWidth(1.5);
  if (splitCgstSgst) {
    colWidths[col++] = const pw.FlexColumnWidth(1.2);
    colWidths[col++] = const pw.FlexColumnWidth(1.2);
  } else if (showIgstCol) {
    colWidths[col++] = const pw.FlexColumnWidth(1.2);
  } else if (taxColumnOn) {
    colWidths[col++] = const pw.FlexColumnWidth(1);
  }
  if (showDiscount) {
    colWidths[col++] = const pw.FlexColumnWidth(1.2);
  }
  colWidths[col++] = const pw.FlexColumnWidth(1.5);
  // Bigger table text (PDF text size) needs wider number columns; Item Name,
  // which wraps by word, gives up the space. 1.0 = original widths.
  if (columnScale != 1.0) {
    final itemNameCol = showSlNo ? 1 : 0;
    for (final k in colWidths.keys.toList()) {
      if (k == itemNameCol) continue;
      colWidths[k] = pw.FlexColumnWidth(
          (colWidths[k]! as pw.FlexColumnWidth).flex * columnScale);
    }
  }

  // Each logical row (header/item/totals) is its own single-row Table
  // sharing colWidths (FlexColumnWidth ratios are content-independent, so
  // widths still line up) + border. Adjacent mini-tables' borders land on
  // the same pixels, so a bordered template (gridClassic) still reads as
  // one continuous grid.
  pw.Widget rowTable(pw.TableRow tableRow, {pw.TableBorder? borderOverride}) =>
      pw.Table(
        columnWidths: colWidths,
        border: borderOverride ?? border,
        children: [tableRow],
      );

  // An item row that carries its own new-line description row drops its
  // bottom rule; the description row then draws the horizontal only across
  // the Item Name→Total span (not the Sl No cell), so the Sl No number
  // reads as one tall cell spanning both rows.
  final itemBorderNoBottom = border == null
      ? null
      : pw.TableBorder(
          left: border.left,
          right: border.right,
          top: border.top,
          verticalInside: border.verticalInside,
        );

  // Sl No column's flex vs. the rest, ×100 so two-decimal FlexColumnWidth
  // values (e.g. 1.4, or 1.68 after columnScale) stay exact as ints. Used to indent the new-line
  // description under "Item Name" while keeping the grid border aligned.
  // When the Sl No column is hidden, slNoFlex is 0 and the description row is
  // rendered as a single full-width column instead.
  final slNoFlex = showSlNo
      ? ((colWidths[0]! as pw.FlexColumnWidth).flex * 100).round()
      : 0;
  final restFlex = colWidths.values.fold<int>(
          0, (sum, w) => sum + ((w as pw.FlexColumnWidth).flex * 100).round()) -
      slNoFlex;

  pw.Widget dividerLine({bool isCompact = false}) => pw.Container(height: isCompact ? 0.5 : 1, color: PdfColors.grey400);

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

  // Header row can be sized separately (PDF section size); defaults to rows.
  final headerFontSize = tableHeaderFontSize ?? tableFontSize;
  final headerRow = pw.TableRow(
    decoration: (template == InvoiceTemplate.gridClassic) ? null : pw.BoxDecoration(color: headerColor),
    children: [
      if (showSlNo)
        buildTableCell('Sl No',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: centerOnGridClassic),
      buildTableCell('Item Name',
          isHeader: true,
          textColor: textColor,
          fontSize: headerFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV),
      if (showGst)
        buildTableCell('HSN/SAC',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      for (final k in metaKeys)
        buildTableCell(_metaHeaderText(k, short: !isLandscape),
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV),
      if (showQuantity)
        buildTableCell(
            invoice.quantityLabel?.isNotEmpty == true
                ? invoice.quantityLabel!
                : 'Qty',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: centerOnGridClassic),
      buildTableCell(priceHeader,
          isHeader: true,
          textColor: textColor,
          fontSize: headerFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV,
          textAlign: centerOnGridClassic),
      if (splitCgstSgst) ...[
        buildTableCell('CGST',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: centerOnGridClassic),
        buildTableCell('SGST',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: centerOnGridClassic),
      ] else if (showIgstCol)
        buildTableCell('IGST',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: centerOnGridClassic)
      else if (taxColumnOn)
        buildTableCell('Tax',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: centerOnGridClassic),
      if (showDiscount)
        buildTableCell(shortDiscountHeader ? 'Disc.' : 'Discount',
            isHeader: true,
            textColor: textColor,
            fontSize: headerFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: rightOnGridClassic),
      buildTableCell('Total',
          isHeader: true,
          textColor: textColor,
          fontSize: headerFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV,
          textAlign: rightOnGridClassic),
    ],
  );

  final itemWidgets = <pw.Widget>[];
  invoice.items.asMap().forEach((index, item) {
    final rowColor = (template == InvoiceTemplate.gridClassic)
        ? null
        : (index % 2 == 0 ? PdfColors.white : PdfColors.grey100);
    // Per-line note if typed, else the product's snapshotted description.
    // Printed either as a line under the item name or, when descriptionNewLine
    // is set, as a full-width row below the item.
    final description = item.printedDescription;
    final hasDescription = showDescription && description.isNotEmpty;
    final showItemDescription = hasDescription && !descriptionNewLine;
    final newLineDescription = hasDescription && descriptionNewLine;
    itemWidgets.add(rowTable(pw.TableRow(
      decoration: rowDecoration(rowColor),
      children: [
        if (showSlNo)
          buildTableCell('${index + 1}',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV,
              textAlign: centerOnGridClassic),
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(
            horizontal: cellPaddingH,
            vertical: (showItemDescription ||
                    showTypeTag && businessType == BusinessType.both ||
                    showDiscount &&
                        !item.discountIsPercent &&
                        item.discountPerUnit &&
                        item.discount > 0)
                ? cellPaddingV * 0.5
                : cellPaddingV,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(item.product.displayName(showAliasName),
                  style: pw.TextStyle(fontSize: tableFontSize * 0.9)),
              if (showItemDescription)
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: tableFontSize * 0.75,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
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
                  !item.discountIsPercent &&
                  item.discountPerUnit &&
                  item.discount > 0)
                pw.Text(
                  '(${AmountFormat.money(item.effectivePrice)} - ${AmountFormat.money(item.discount)} = ${AmountFormat.money(item.effectivePrice - item.discount)}/item)',
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
        for (final k in metaKeys)
          buildTableCell(_metaCellValue(item, k, metadataDatePattern),
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV),
        if (showQuantity)
          buildTableCell(
              '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toString()}'
              '${item.effectiveUnit.trim().isEmpty ? '' : ' ${item.effectiveUnit}'}',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV,
              textAlign: centerOnGridClassic),
        buildTableCell(
            showDiscount
                ? AmountFormat.money(item.effectivePrice)
                : AmountFormat.money(item.total / item.quantity),
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: centerOnGridClassic),
        if (splitCgstSgst) ...[
          buildTableCell(
              '${AmountFormat.money(isGlobalTaxMode ? (invoice.subtotal > 0 ? invoice.tax * (item.total / invoice.subtotal) / 2 : 0.0) : item.taxAmount / 2)}\n(${(isGlobalTaxMode ? globalTaxRatePercent : item.product.tax_rate) / 2}%)',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV,
              textAlign: centerOnGridClassic),
          buildTableCell(
              '${AmountFormat.money(isGlobalTaxMode ? (invoice.subtotal > 0 ? invoice.tax * (item.total / invoice.subtotal) / 2 : 0.0) : item.taxAmount / 2)}\n(${(isGlobalTaxMode ? globalTaxRatePercent : item.product.tax_rate) / 2}%)',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV,
              textAlign: centerOnGridClassic),
        ] else if (showIgstCol)
          buildTableCell(
              '${AmountFormat.money(isGlobalTaxMode ? (invoice.subtotal > 0 ? invoice.tax * (item.total / invoice.subtotal) : 0.0) : item.taxAmount)}\n(${isGlobalTaxMode ? globalTaxRatePercent : item.product.tax_rate}%)',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV,
              textAlign: centerOnGridClassic)
        else if (taxColumnOn)
          buildTableCell(
              '${AmountFormat.money(isGlobalTaxMode ? (invoice.subtotal > 0 ? invoice.tax * (item.total / invoice.subtotal) : 0.0) : item.taxAmount)}\n(${isGlobalTaxMode ? globalTaxRatePercent : item.product.tax_rate}%)',
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV,
              textAlign: centerOnGridClassic),
        if (showDiscount)
          buildTableCell(
              item.discountIsPercent && item.discount > 0
                  ? '${AmountFormat.money(item.totalDiscount)}\n(${item.discount == item.discount.roundToDouble() ? item.discount.toInt() : item.discount}%)'
                  : AmountFormat.money(item.totalDiscount),
              fontSize: tableFontSize,
              cellPaddingH: cellPaddingH,
              cellPaddingV: cellPaddingV,
              textAlign: rightOnGridClassic),
        buildTableCell(AmountFormat.money(item.total),
            fontSize: tableFontSize,
            cellPaddingH: cellPaddingH,
            cellPaddingV: cellPaddingV,
            textAlign: rightOnGridClassic),
      ],
    ), borderOverride: newLineDescription ? itemBorderNoBottom : null));

    if (newLineDescription) {
      // Its own single-row Table on the Sl No / rest flex split. The table
      // draws only the left/right edges + the Sl No vertical rule; the
      // horizontal rule over the description sits on the description cell
      // itself, so it spans Item Name→Total but NOT the Sl No cell — the
      // Sl No number then reads as one tall cell across both rows. The rule
      // below comes from the next row's top border (or, on the last item,
      // this table's own bottom).
      final isLastItem = index == invoice.items.length - 1;
      final descBorder = border == null
          ? null
          : pw.TableBorder(
              left: border.left,
              right: border.right,
              verticalInside: border.verticalInside,
              bottom: isLastItem ? border.bottom : pw.BorderSide.none,
            );
      itemWidgets.add(pw.Table(
        columnWidths: showSlNo
            ? {
                0: pw.FlexColumnWidth(slNoFlex.toDouble()),
                1: pw.FlexColumnWidth(restFlex.toDouble()),
              }
            : {0: pw.FlexColumnWidth(restFlex.toDouble())},
        border: descBorder,
        children: [
          pw.TableRow(
            decoration: rowDecoration(rowColor),
            children: [
              if (showSlNo) pw.SizedBox(),
              pw.Container(
                decoration: border == null
                    ? null
                    : pw.BoxDecoration(border: pw.Border(top: border.top)),
                padding: pw.EdgeInsets.fromLTRB(cellPaddingH,
                    border == null ? 0 : cellPaddingV * 0.5, cellPaddingH, cellPaddingV),
                child: pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: tableFontSize * 0.85,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ));
    }
  });

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      rowTable(headerRow),
      ...itemWidgets,
      if (template != InvoiceTemplate.gridClassic)
        dividerLine(isCompact: template == InvoiceTemplate.compact),
      if (totalQuantityText != null)
        rowTable(pw.TableRow(
          children: [
            if (showSlNo)
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
            for (final _ in metaKeys)
              buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            if (showQuantity)
              buildTableCell(totalQuantityText,
                  isHeader: true,
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV,
                  textAlign: centerOnGridClassic),
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
            ] else if (taxColumnOn)
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
      if (totalQuantityText != null && template != InvoiceTemplate.gridClassic) dividerLine(isCompact: (template == InvoiceTemplate.compact)),
    ],
  );
}

pw.Widget buildTableCell(String text,
    {bool isHeader = false,
    PdfColor textColor = PdfColors.black,
    double fontSize = 10,
    double cellPaddingH = 6,
    double cellPaddingV = 8,
    pw.TextAlign textAlign = pw.TextAlign.left}) {
  final label = pw.Text(
    text,
    textAlign: textAlign,
    style: pw.TextStyle(
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontSize: fontSize,
        color: textColor),
  );
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(
        horizontal: cellPaddingH, vertical: cellPaddingV),
    // Header labels stay on one line: shrink only when the column is too
    // narrow (small pages / big PDF text size) instead of breaking mid-word.
    child: isHeader
        ? pw.Align(
            alignment: textAlign == pw.TextAlign.center
                ? pw.Alignment.center
                : textAlign == pw.TextAlign.right
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
            child: pw.FittedBox(fit: pw.BoxFit.scaleDown, child: label))
        : label,
  );
}

pw.Widget buildAdditionalNotes(Invoice invoice,
    {double fontSize = 10, PdfColor accentColor = PdfColors.grey700}) {
  final notes = invoice.notes ?? '';
  final returnLines = returnInfoLines(invoice);
  if (notes.isEmpty && returnLines.isEmpty) return pw.SizedBox();
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
        for (final line in returnLines) ...[
          pw.Text(line,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: fontSize,
                  color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
        ],
        if (notes.isNotEmpty) ...[
          if (returnLines.isNotEmpty) pw.SizedBox(height: 4),
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
      ],
    ),
  );
}

/// Reference lines printed on a Credit / Debit Note PDF — original invoice
/// link, reason, and (credit notes) how the value was settled. Empty for a
/// plain invoice / quotation / receipt.
List<String> returnInfoLines(Invoice invoice) {
  if (invoice.type != 'Credit Note' && invoice.type != 'Debit Note') {
    return const [];
  }
  final lines = <String>[];
  if ((invoice.originalInvoiceNumber ?? '').isNotEmpty) {
    final date = invoice.originalInvoiceDate;
    final against =
        invoice.originalInvoiceType == 'Receipt' ? 'Receipt' : 'Invoice';
    lines.add('Against $against: ${invoice.originalInvoiceNumber}'
        '${date != null ? ' dated ${formatPdfDate(date, 'dd MMM yyyy')}' : ''}');
  }
  if ((invoice.returnReason ?? '').trim().isNotEmpty) {
    lines.add('Reason: ${invoice.returnReason!.trim()}');
  }
  switch (invoice.creditSettlement) {
    case CreditSettlement.reduceInvoice:
      lines.add('Adjusted against the invoice balance');
    case CreditSettlement.refund:
      lines.add('Refunded to the customer');
    case CreditSettlement.customerCredit:
      lines.add('Credited to the customer account');
    case null:
      break;
  }
  for (final r in invoice.refunds) {
    lines.add('Refund ${r.receiptNumber}: '
        '${invoice.currencySymbol}${AmountFormat.money(r.amount)} on '
        '${formatPdfDate(r.dateRefunded, 'dd MMM yyyy')}'
        '${(r.refundMethod ?? '').isNotEmpty ? ' via ${r.refundMethod}' : ''}');
  }
  return lines;
}

// Locale pinned to 'en_US' regardless of the app's UI language: PDF dates
// must stay stable for the recipient, and DateFormat with no explicit
// locale follows Intl.defaultLocale (set to the app language, e.g. 'bo' for
// Tibetan) — 'bo' has no intl locale data at all, so that throws.
String formatPdfDate(DateTime date, String pattern) {
  return DateFormat(pattern, 'en_US').format(date);
}

/// Invoice date, optionally with the creation time appended.
/// [timeFormat] '12' → h:mm a (e.g. "2:30 PM"), anything else → HH:mm (24h).
String formatPdfDateTime(DateTime date, String pattern,
    {bool showTime = true, String timeFormat = '24'}) {
  final dateStr = formatPdfDate(date, pattern);
  if (!showTime) return dateStr;
  final timePattern = timeFormat == '12' ? 'h:mm a' : 'HH:mm';
  return '$dateStr ${DateFormat(timePattern, 'en_US').format(date)}';
}

String formatInvoiceNumberForDisplay(String number, bool showLeadingZeros) {
  if (showLeadingZeros) return number;
  final stripped = number.replaceFirst(RegExp(r'^0+'), '');
  return stripped.isEmpty ? '0' : stripped;
}

/// Ship To prints only when the feature is on, the invoice isn't
/// same-as-billing and has a shipping address — otherwise every template
/// shows just the Bill To block, exactly as before.
bool showShipTo(Customer c, CustomerFieldSettings s) =>
    s.shipping &&
    s.shipToInPdf &&
    !c.shippingSameAsBilling &&
    c.shippingAddress.trim().isNotEmpty;

/// Ship To block lines: recipient name, phone, address (empties skipped).
List<String> shipToLines(Customer c, {String phonePrefix = ''}) => [
      if (c.shippingName.trim().isNotEmpty) c.shippingName.trim(),
      if (c.shippingPhone.trim().isNotEmpty)
        '$phonePrefix${c.shippingPhone.trim()}',
      c.shippingAddress.trim(),
    ];

const _pdfGenderLabels = {'male': 'Male', 'female': 'Female', 'other': 'Other'};

/// Extra lines under Bill To: one "Age: 34 · DOB: 15/06/1990 · Gender: Female"
/// line (switched-off or empty parts skipped), then "Label: value" per filled
/// customer custom field. Age is at the invoice date (from DOB when set).
/// Custom field labels come from the invoice snapshot, so renaming a field
/// later doesn't relabel old invoices.
List<String> customerExtraLines(Customer c, CustomerFieldSettings s,
    DateTime invoiceDate, String datePattern, {String separator = ' · '}) {
  final age = s.age && s.ageInPdf ? c.ageOn(invoiceDate) : null;
  final dob = s.dob && s.dobInPdf ? DateTime.tryParse(c.dob) : null;
  final gender = s.gender && s.genderInPdf ? _pdfGenderLabels[c.gender] : null;
  // Per-definition print flag; values of since-deleted definitions still
  // print (nothing says otherwise).
  final hidden = {
    for (final d in s.customFieldDefs)
      if (!d.showInPdf) d.id,
  };
  final personal = [
    if (age != null) 'Age: $age',
    if (dob != null) 'DOB: ${formatPdfDate(dob, datePattern)}',
    if (gender != null) 'Gender: $gender',
  ].join(separator);
  return [
    if (personal.isNotEmpty) personal,
    if (s.customFields)
      for (final v in c.customFields)
        if (v.value.trim().isNotEmpty && !hidden.contains(v.defId))
          '${v.label}: ${v.value.trim()}',
  ];
}
