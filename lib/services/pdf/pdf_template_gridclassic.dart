import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/utils/amount_in_words.dart';
import 'pdf_widgets.dart';

/// Bordered, tabular "old style" bill — the boxed grid layout common on
/// legacy retail billing software (SI/Item/HSN/Qty/Rate/Total table inside
/// one full-page border, plain totals, amount in words). Adaptive across
/// A4/A5/A6. Respects the same settings surface as the other templates —
/// HSN/discount/tax columns, total quantity, UPI, bank details, signature,
/// additional costs and previous balance all follow their usual toggles.
pw.MultiPage buildGridClassicTemplate(
  Invoice invoice,
  CompanyInfo? company,
  String currencySymbol,
  String invoicePrefix, {
  String? upiId,
  bool showUpiQr = false,
  bool showGst = true,
  bool showQuantity = true,
  bool showDiscount = true,
  bool showTypeTag = true,
  bool showAliasName = false,
  bool showTotalQuantity = false,
  BusinessType businessType = BusinessType.both,
  BankAccount? bankAccount,
  String datePattern = 'dd/MM/yyyy',
  LogoPosition logoPosition = LogoPosition.left,
  double logoSizePx = 50,
  Uint8List? logoBytes,
  String thankYouNote = '',
  bool showFooterBranding = false,
  PdfColor? themeColor,
  Uint8List? signatureBytes,
  String signaturePosition = 'right',
  double signatureSizePx = 50,
  double previousBalanceDue = 0.0,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
  pw.ThemeData? pdfTheme,
}) {
  final accentColor = themeColor ?? PdfColors.black;
  final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
  final signatureImage =
      signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;
  final borderColor = PdfColors.grey800;

  final bool isA6 = pageFormat == PdfPageFormat.a6;
  final bool isA5 = pageFormat == PdfPageFormat.a5;
  final double fontScale = isA6 ? 0.60 : (isA5 ? 0.88 : 1.0);
  final double pageMarginH = isA6 ? 10.0 : (isA5 ? 15.0 : PdfLayout.defaultHMargin);
  final double pageMarginV = isA6 ? 5.0 : (isA5 ? 8.0 : PdfLayout.defaultVMargin);
  final double innerPad = 7 * fontScale;
  final double titleFont = 12 * fontScale;
  final double subFont = 8 * fontScale;
  final double labelFont = 7.5 * fontScale;
  final double tableFontSize = 7.5 * fontScale;
  final double totalsFont = 8 * fontScale;
  final double netAmountFont = 10 * fontScale;
  final double cellPadH = (4 * fontScale).clamp(3.0, 6.0);
  final double cellPadV = (4 * fontScale).clamp(3.0, 6.0);

  final gstin = company?.gstin ?? '';
  final gstLabel = taxLabel(company?.country);
  final hasPreviousBalance = previousBalanceDue > 0;
  final hasPaid = invoice.amountPaid > 0;

  final rawNet = invoice.total + (hasPreviousBalance ? previousBalanceDue : 0);
  final roundedNet = rawNet.floorToDouble();
  final roundOff = roundedNet - rawNet;

  final totalQty = showTotalQuantity
      ? invoice.items.fold<double>(0, (s, i) => s + i.quantity)
      : 0.0;
  final qtyLabel =
      (invoice.quantityLabel?.isNotEmpty == true) ? invoice.quantityLabel! : 'Qty';

  pw.Widget infoRow(String k, String v) => pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 1.5 * fontScale),
        child: pw.Row(
          children: [
            pw.SizedBox(
                width: 58 * fontScale,
                child: pw.Text(k,
                    style: pw.TextStyle(
                        fontSize: labelFont, fontWeight: pw.FontWeight.bold))),
            pw.Text(': ', style: pw.TextStyle(fontSize: labelFont)),
            pw.Text(v, style: pw.TextStyle(fontSize: labelFont)),
          ],
        ),
      );

  pw.Widget totalsRow(String k, String v, {bool bold = false, double? size}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(k,
                style: pw.TextStyle(
                    fontSize: size ?? totalsFont,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(v,
                style: pw.TextStyle(
                    fontSize: size ?? totalsFont,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  pw.Widget buildInvoiceHeader() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          width: 0.5,
          color: borderColor,
        ),
      ),
      padding: pw.EdgeInsets.symmetric(vertical: innerPad),
      child: pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: innerPad),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Entire logo section
            if (logoImage != null)
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if(logoPosition == LogoPosition.left)
                      buildCompanyLogo(logoImage, size: logoSizePx),
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(company?.name ?? '',
                            textAlign: pw.TextAlign.left,
                            style: pw.TextStyle(
                                fontSize: titleFont,
                                fontWeight: pw.FontWeight.bold,
                                color: accentColor)),
                        if ((company?.address ?? '').isNotEmpty)
                          pw.Text(company!.address,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(fontSize: subFont)),
                        if ((company?.phone ?? '').isNotEmpty)
                          pw.Text('Ph: ${company!.phone}',
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(fontSize: subFont)),
                        if (showGst && gstin.isNotEmpty)
                          pw.Text('$gstLabel: $gstin',
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(
                                  fontSize: subFont, fontWeight: pw.FontWeight.normal)),
                      ],
                    ),
                    if(logoPosition == LogoPosition.right)
                      buildCompanyLogo(logoImage, size: logoSizePx),
                  ]
              ),
            if (logoImage == null)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(company?.name ?? '',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontSize: titleFont,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor)),
                    if ((company?.address ?? '').isNotEmpty)
                      pw.Text(company!.address,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: subFont)),
                    if ((company?.phone ?? '').isNotEmpty)
                      pw.Text('Ph: ${company!.phone}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: subFont)),
                    if (showGst && gstin.isNotEmpty)
                      pw.Text('$gstLabel: $gstin',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: subFont, fontWeight: pw.FontWeight.normal)),
                  ],
                ),
              ),
            pw.SizedBox(height: 0.5 * fontScale),
            pw.Divider(thickness: 0.5, color: borderColor,height: 8),
            // pw.SizedBox(height: 0.5 * fontScale),
            pw.Center(
                child: pw.Text(invoice.type.toUpperCase() ?? '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                        fontSize: titleFont-2,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor))
            ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      infoRow('Customer', invoice.customer.name),
                      if (invoice.customer.address.isNotEmpty)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(left: 60 * fontScale),
                          child: pw.Text(invoice.customer.address,
                              style: pw.TextStyle(fontSize: labelFont)),
                        ),
                      if (showGst && invoice.customer.gstin.isNotEmpty)
                        infoRow(gstLabel, invoice.customer.gstin),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      infoRow('${invoice.type} No',
                          '$invoicePrefix${invoice.invoiceNumber ?? invoice.id}'),
                      infoRow('Date', formatPdfDate(invoice.date, datePattern)),
                      infoRow('Time', DateFormat('HH:mm:ss').format(invoice.date)),
                      if (invoice.dueDate != null)
                        infoRow('Due Date', formatPdfDate(invoice.dueDate!, datePattern)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget buildInvoiceFooter() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(width: 0.5),
          right: pw.BorderSide(width: 0.5),
          bottom: pw.BorderSide(width: 0.5),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: innerPad),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: buildAdditionalNotes(invoice,fontSize: 9*fontScale)),
              pw.SizedBox(width: 5 * fontScale),
              pw.SizedBox(
                width: 200 * fontScale,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    totalsRow(
                        'Subtotal',
                        '$currencySymbol ${(invoice.totalDiscount > 0 ? invoice.grossSubtotal : invoice.subtotal).toStringAsFixed(2)}'),
                    if (invoice.totalDiscount > 0)
                      totalsRow('Discount',
                          '-$currencySymbol ${invoice.totalDiscount.toStringAsFixed(2)}'),
                    if (invoice.taxMode != TaxMode.none)
                      totalsRow(invoiceTaxLabel(invoice),
                          '$currencySymbol ${invoice.tax.toStringAsFixed(2)}'),
                    ...invoice.additionalCosts.map((c) => totalsRow(
                        c.label.isEmpty ? 'Extra Cost' : c.label,
                        '$currencySymbol ${c.amount.toStringAsFixed(2)}')),
                    pw.Divider(thickness: 0.5, color: borderColor,height: 5),
                    totalsRow('Total',
                        '$currencySymbol ${invoice.total.toStringAsFixed(2)}',
                        bold: true),
                    if (hasPreviousBalance) ...[
                      totalsRow('Previous Balance Due',
                          '$currencySymbol ${previousBalanceDue.toStringAsFixed(2)}'),
                      totalsRow('Total Due',
                          '$currencySymbol ${(invoice.total + previousBalanceDue).toStringAsFixed(2)}',
                          bold: true),
                    ],
                    totalsRow('Round off',
                        '$currencySymbol ${roundOff.toStringAsFixed(2)}'),
                    pw.Divider(thickness: 0.5, color: borderColor,height: 5),
                    totalsRow('Net Amount',
                        '$currencySymbol ${roundedNet.toStringAsFixed(2)}',
                        bold: true, size: netAmountFont),
                    if (hasPaid) ...[
                      pw.SizedBox(height: 4 * fontScale),
                      totalsRow('Amount Paid',
                          '$currencySymbol ${invoice.amountPaid.toStringAsFixed(2)}'),
                      totalsRow('Balance',
                          '$currencySymbol ${invoice.outstandingBalance.toStringAsFixed(2)}'),
                    ],
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10 * fontScale),

          // ── Amount in words ──
          pw.Text(AmountInWords.amount(roundedNet),
              style: pw.TextStyle(
                  fontSize: labelFont - 1 , fontWeight: pw.FontWeight.normal, fontStyle: pw.FontStyle.italic)),

          if (signatureImage != null) ...[
            pw.SizedBox(height: 16 * fontScale),
            buildSignatureWidget(signatureImage, signaturePosition,
                imageHeight: 40 * fontScale * (signatureSizePx / 50),
                labelFontSize: labelFont),
          ],

          if ((showUpiQr && upiId != null) || bankAccount != null) ...[
            pw.SizedBox(height: 12 * fontScale),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (showUpiQr && upiId != null)
                    buildUpiQrSection(
                      upiId: upiId,
                      companyName: company?.name ?? '',
                      amount: invoice.total,
                      currencyCode: invoice.currencyCode,
                      invoiceId: invoice.id,
                      accentColor: accentColor,
                    ),
                  if (bankAccount != null) ...[
                    if (showUpiQr && upiId != null) pw.SizedBox(height: 12 * fontScale),
                    buildBankDetailsSection(
                        bankAccount: bankAccount, accentColor: accentColor),
                  ],
                ],
              ),
            ),
          ],

          if (thankYouNote.isNotEmpty) ...[
            pw.SizedBox(height: 12 * fontScale),
            pw.Center(
              child: pw.Text(thankYouNote,
                  style: pw.TextStyle(
                      fontSize: subFont,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700)),
            ),
          ],
          if (showFooterBranding) ...[
            pw.SizedBox(height: 8 * fontScale),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('Generated by Invoiso',
                  style: pw.TextStyle(
                      fontSize: 7 * fontScale, color: PdfColors.grey600)),
            ),
          ],
        ],
      ),
    );
  }

  return pw.MultiPage(
    pageFormat: pageFormat,
    theme: pdfTheme,
    margin: pw.EdgeInsets.symmetric(vertical: pageMarginV, horizontal: pageMarginH),
    header: (context) {
      if (context.pageNumber != 1) {
        return pw.SizedBox(); // Remove this if you want header on every page
      }
      return buildInvoiceHeader();
    },
    footer: (context)
    {
      // only one page we don't need total page counters
      if(context.pagesCount == 1)
      {
        return pw.SizedBox();
      }
      return pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top:5,bottom: 0,left: 0,right: 0),
        child: pw.Text(
          showFooterBranding
              ? "Page ${context.pageNumber} of ${context.pagesCount}  -  Generated by Invoiso"
              : "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(fontSize: (PdfLayout.footerBrandingFontSize-1) * fontScale, color: PdfColors.grey600),
        ),
      );
    },
    build: (context) => [
      // ── Item grid — flush with the outer border, same settings-driven
      // columns as the other templates ──
      buildInvoiceTable(
        invoice,
        InvoiceTemplate.gridClassic,
        headerColor: PdfColors.grey200,
        textColor: PdfColors.black,
        showGst: showGst,
        showQuantity: showQuantity,
        showDiscount: showDiscount,
        showTypeTag: showTypeTag,
        showAliasName: showAliasName,
        businessType: businessType,
        tableFontSize: tableFontSize,
        cellPaddingH: cellPadH,
        cellPaddingV: cellPadV,
        border: pw.TableBorder.all(width: 0.5, color: borderColor),
        totalQuantityText: showTotalQuantity && showQuantity
            ? '${totalQty == totalQty.roundToDouble() ? totalQty.toInt() : totalQty}'
            : null,
      ),
      // ── Notes, totals, signature, footer (inset again) ──
      buildInvoiceFooter()
    ],
  );
}
