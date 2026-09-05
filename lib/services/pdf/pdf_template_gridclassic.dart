import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/custom_field_value.dart';
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
  bool showSlNo = true,
  bool showQuantity = true,
  bool showDiscount = true,
  bool showTypeTag = true,
  bool showAliasName = false,
  bool showDescription = false,
  bool descriptionNewLine = false,
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
  bool landscape = false,
  pw.ThemeData? pdfTheme,
  Uint8List? watermarkBytes,
  double watermarkOpacity = 0.12,
  bool showCgstSgst = false,
  bool showIgst = false,
  bool showRoundOff = false,
  bool showLeadingZeros = true,
  bool showPhone = true,
  bool showCompanyName = true,
  bool showPan = true,
  bool showFssai = true,
  bool showAddress = true,
  bool showLogo = true,
  bool showCustomerBusinessName = true,
  bool showCustomerAddress = true,
  bool showCustomerPhone = true,
  bool showCustomerEmail = true,
  bool showCustomerGstin = true,
  bool showTimeInPdf = true,
  String pdfTimeFormat = '24',
}) {
  final accentColor = themeColor ?? PdfColors.black;
  final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
  final signatureImage =
      signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;
  final borderColor = PdfColors.grey800;

  // `pageFormat` stays portrait here so the isA6/isA5 checks below keep working;
  // the actual page just swaps width/height for landscape (pdf pkg keeps margins).
  final bool isA6 = pageFormat == PdfPageFormat.a6;
  final bool isA5 = pageFormat == PdfPageFormat.a5;
  final PdfPageFormat pageFmt = landscape ? pageFormat.landscape : pageFormat;
  final double fontScale = landscape
      ? (isA6 ? 0.72 : (isA5 ? 1.0 : 1.0))
      : (isA6 ? 0.60 : (isA5 ? 0.88 : 1.0));
  final double pageMarginH = landscape
      ? (isA6 ? 12.0 : (isA5 ? 18.0 : PdfLayout.defaultHMargin))
      : (isA6 ? 10.0 : (isA5 ? 15.0 : PdfLayout.defaultHMargin));
  final double pageMarginV = landscape
      ? (isA6 ? 6.0 : (isA5 ? 8.0 : 10.0))
      : (isA6 ? 5.0 : (isA5 ? 8.0 : PdfLayout.defaultVMargin));
  final double contentWidth = pageFmt.width - pageMarginH * 2;
  final double totalsBoxWidth =
      landscape ? (contentWidth * 0.32).clamp(180.0, 340.0) : 200 * fontScale;
  final double innerPad = gridClassicPdfStyle.sectionPadding * fontScale;
  final double titleFont = gridClassicPdfStyle.titleFontSize * fontScale;
  final double subFont = gridClassicPdfStyle.subtitleFontSize * fontScale;
  final double labelFont = gridClassicPdfStyle.labelFontSize * fontScale;
  final double tableFontSize = gridClassicPdfStyle.tableFontSize * fontScale;
  final double totalsFont = gridClassicPdfStyle.totalsFontSize * fontScale;
  final double netAmountFont = gridClassicPdfStyle.totalsHighlightFontSize * fontScale;
  final double cellPadH = (gridClassicPdfStyle.cellPaddingH * fontScale).clamp(3.0, 6.0);
  final double cellPadV = (gridClassicPdfStyle.cellPaddingV * fontScale).clamp(3.0, 6.0);
  // Logo height gets its own per-page-size scale (independent of fontScale) so
  // A5/A6 don't get an A4-sized logo swallowing the header.
  final double logoScale = landscape
      ? (isA6 ? 0.6 : (isA5 ? 0.9 : 1.0))
      : (isA6 ? 0.4 : (isA5 ? 0.68 : 1.0));
  final double logoSize = logoSizePx * logoScale;

  final gstin = company?.gstin ?? '';
  final gstLabel = taxLabel(company?.country);
  final panNumber = company?.panNumber ?? '';
  final fssaiCode = company?.fssaiCode ?? '';
  final companyIdLine = [
    if (showGst && gstin.isNotEmpty) '$gstLabel: $gstin',
    if (showPan && panNumber.isNotEmpty) 'PAN: $panNumber',
    if (showFssai && fssaiCode.isNotEmpty) 'FSSAI: $fssaiCode',
  ].join('   ');
  final hasPreviousBalance = previousBalanceDue > 0;
  final hasPaid = invoice.amountPaid > 0;

  final rawNet = invoice.total + (hasPreviousBalance ? previousBalanceDue : 0);
  final netTotal = roundNetTotal(rawNet);
  final roundedNet = netTotal.rounded;
  final roundOff = netTotal.roundOff;
  final payableAmount = showRoundOff ? roundedNet : rawNet;

  final totalQty = showTotalQuantity
      ? invoice.items.fold<double>(0, (s, i) => s + i.quantity)
      : 0.0;
  //final qtyLabel =
  //    (invoice.quantityLabel?.isNotEmpty == true) ? invoice.quantityLabel! : 'Qty';

  // alignEnd: shrink the row to its content so the enclosing right-hand column
  // can sit against the page's right edge while the labels stay left-aligned
  // with each other.
  pw.Widget infoRow(String k, String v, {bool alignEnd = false}) => pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 1.5 * fontScale),
        child: pw.Row(
          mainAxisSize:
              alignEnd ? pw.MainAxisSize.min : pw.MainAxisSize.max,
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
            if (showLogo && logoImage != null)...[
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if(logoPosition == LogoPosition.left)
                      buildCompanyLogo(logoImage, size: logoSize),
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(showCompanyName ? (company?.name ?? '') : '',
                            textAlign: pw.TextAlign.left,
                            style: pw.TextStyle(
                                fontSize: titleFont,
                                fontWeight: pw.FontWeight.bold,
                                color: accentColor)),
                        if (showAddress && (company?.address ?? '').isNotEmpty)
                          pw.Text(company!.address,
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(fontSize: subFont)),
                        if (showPhone && (company?.phone ?? '').isNotEmpty)
                          pw.Text('Ph: ${company!.phone}',
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(fontSize: subFont)),
                      ],
                    ),
                    if(logoPosition == LogoPosition.right)
                      buildCompanyLogo(logoImage, size: logoSize),
                  ]
              ),
              if (companyIdLine.isNotEmpty)
                pw.Center(child: pw.Text(companyIdLine,
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                        fontSize: subFont, fontWeight: pw.FontWeight.normal)),)
            ],
            if (!showLogo || logoImage == null)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(showCompanyName ? (company?.name ?? '') : '',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontSize: titleFont,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor)),
                    if (showAddress && (company?.address ?? '').isNotEmpty)
                      pw.Text(company!.address,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: subFont)),
                    if ((company?.phone ?? '').isNotEmpty)
                      pw.Text('Ph: ${company!.phone}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: subFont)),
                    if (companyIdLine.isNotEmpty)
                      pw.Text(companyIdLine,
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
                child: pw.Text((invoice.invoiceTitle ?? invoice.type).toUpperCase(),
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
                      if (showCustomerBusinessName && invoice.customer.businessName.isNotEmpty)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(left: 60 * fontScale),
                          child: pw.Text(invoice.customer.businessName,
                              style: pw.TextStyle(fontSize: labelFont)),
                        ),
                      if (showCustomerAddress && invoice.customer.address.isNotEmpty)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(left: 60 * fontScale),
                          child: pw.Text(invoice.customer.address,
                              style: pw.TextStyle(fontSize: labelFont)),
                        ),
                      if (showCustomerPhone && invoice.customer.phone.isNotEmpty)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(left: 60 * fontScale),
                          child: pw.Text('Ph: ${invoice.customer.phone}',
                              style: pw.TextStyle(fontSize: labelFont)),
                        ),
                      if (showCustomerEmail && invoice.customer.email.isNotEmpty)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(left: 60 * fontScale),
                          child: pw.Text(invoice.customer.email,
                              style: pw.TextStyle(fontSize: labelFont)),
                        ),
                      if (showGst && showCustomerGstin && invoice.customer.gstin.isNotEmpty)
                        infoRow(gstLabel, invoice.customer.gstin),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                    pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      if (invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros) != null)
                        infoRow('${invoice.invoiceTitle ?? invoice.type} No',
                            invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros)!,
                            alignEnd: true),
                      infoRow('Date', formatPdfDate(invoice.date, datePattern),
                          alignEnd: true),
                      if (showTimeInPdf)
                        infoRow(
                            'Time',
                            DateFormat(pdfTimeFormat == '12' ? 'h:mm a' : 'HH:mm',
                                    'en_US')
                                .format(invoice.date),
                            alignEnd: true),
                      if (invoice.dueDate != null)
                        infoRow('Due Date',
                            formatPdfDate(invoice.dueDate!, datePattern),
                            alignEnd: true),
                    ],
                    ),
                    ],
                  ),
                ),
              ],
            ),
            if (invoice.customFields.any((f) => f.value.trim().isNotEmpty)) ...[
              pw.SizedBox(height: 4 * fontScale),
              () {
                final filled = invoice.customFields
                    .where((f) => f.value.trim().isNotEmpty)
                    .toList();

                pw.Widget fieldCell(CustomFieldValue? f) => pw.Container(
                      padding: pw.EdgeInsets.all(3 * fontScale),
                      child: f == null
                          ? null
                          : pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(f.label,
                                    style: pw.TextStyle(
                                        fontSize: labelFont - 1,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 1),
                                pw.Text(f.value,
                                    style: pw.TextStyle(fontSize: labelFont)),
                              ],
                            ),
                    );

                return pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: borderColor),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(1),
                  },
                  children: [
                    for (var i = 0; i < filled.length; i += 3)
                      pw.TableRow(children: [
                        fieldCell(filled[i]),
                        fieldCell(i + 1 < filled.length ? filled[i + 1] : null),
                        fieldCell(i + 2 < filled.length ? filled[i + 2] : null),
                      ]),
                  ],
                );
              }(),
            ],
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
              pw.Expanded(child: buildAdditionalNotes(invoice,fontSize: gridClassicPdfStyle.bodyFontSize*fontScale, accentColor: accentColor)),
              pw.SizedBox(width: 5 * fontScale),
              pw.SizedBox(
                width: totalsBoxWidth,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    totalsRow(
                        'Subtotal',
                        '$currencySymbol ${(invoice.totalDiscount > 0 ? invoice.grossSubtotal : invoice.subtotal).toStringAsFixed(2)}'),
                    if (invoice.totalDiscount > 0)
                      totalsRow('Discount',
                          '-$currencySymbol ${invoice.totalDiscount.toStringAsFixed(2)}'),
                    if (invoice.taxMode != TaxMode.none && !showIgst)
                      totalsRow(invoiceTaxLabel(invoice),
                          '$currencySymbol ${invoice.tax.toStringAsFixed(2)}'),
                    if (invoice.taxMode != TaxMode.none && showIgst)
                      totalsRow('IGST',
                          '$currencySymbol ${invoice.tax.toStringAsFixed(2)}'),
                    if (invoice.taxMode != TaxMode.none && showCgstSgst) ...[
                      totalsRow('CGST',
                          '$currencySymbol ${(invoice.tax / 2).toStringAsFixed(2)}'),
                      totalsRow('SGST',
                          '$currencySymbol ${(invoice.tax / 2).toStringAsFixed(2)}'),
                    ],
                    ...invoice.additionalCosts.map((c) => totalsRow(
                        c.label.isEmpty ? 'Extra Cost' : c.label,
                        '$currencySymbol ${c.amount.toStringAsFixed(2)}')),
                    if (invoice.invoiceDiscountAmount > 0)
                      totalsRow(invoice.invoiceDiscountType == InvoiceDiscountType.percent
                          ? "Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%)"
                          : "Extra Discount ",
                          "-$currencySymbol ${invoice.invoiceDiscountAmount.toStringAsFixed(2)}"
                      ),
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
                    if (showRoundOff) ...[
                      totalsRow('Round off',
                          '$currencySymbol ${roundOff.toStringAsFixed(2)}'),
                      pw.Divider(thickness: 0.5, color: borderColor,height: 5),
                      totalsRow('Net Amount',
                          '$currencySymbol ${roundedNet.toStringAsFixed(2)}',
                          bold: true, size: netAmountFont),
                    ],
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
          if (showRoundOff)
            pw.Text(AmountInWords.amount(roundedNet,
                    indian: invoice.currencyCode == 'INR'),
                style: pw.TextStyle(
                    fontSize: labelFont - 1 , fontWeight: pw.FontWeight.normal, fontStyle: pw.FontStyle.italic)),

          if (signatureImage != null || (showUpiQr && upiId != null) || bankAccount != null) ...[
            pw.SizedBox(height: 16 * fontScale),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: signaturePosition == 'right'
                  ? [
                      buildBankUpiRow(
                        bankAccount: bankAccount,
                        showUpiQr: showUpiQr,
                        upiId: upiId,
                        companyName: company?.name ?? '',
                        amount: payableAmount,
                        currencyCode: invoice.currencyCode,
                        invoiceId: invoice.id,
                        accentColor: accentColor,
                        gap: 12 * fontScale,
                      ),
                      signatureImage != null
                          ? buildSignatureWidget(signatureImage, signaturePosition,
                              imageHeight: 40 * fontScale * (signatureSizePx / 50),
                              labelFontSize: labelFont)
                          : pw.SizedBox(),
                    ]
                  : [
                      signatureImage != null
                          ? buildSignatureWidget(signatureImage, signaturePosition,
                              imageHeight: 40 * fontScale * (signatureSizePx / 50),
                              labelFontSize: labelFont)
                          : pw.SizedBox(),
                      buildBankUpiRow(
                        bankAccount: bankAccount,
                        showUpiQr: showUpiQr,
                        upiId: upiId,
                        companyName: company?.name ?? '',
                        amount: payableAmount,
                        currencyCode: invoice.currencyCode,
                        invoiceId: invoice.id,
                        accentColor: accentColor,
                        gap: 12 * fontScale,
                      ),
                    ],
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
                      fontSize: gridClassicPdfStyle.footerFontSize * fontScale, color: PdfColors.grey600)),
            ),
          ],
        ],
      ),
    );
  }

  return pw.MultiPage(
    pageFormat: pageFmt,
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
        pageFormat,
        headerColor: PdfColors.grey200,
        textColor: PdfColors.black,
        showGst: showGst,
        showSlNo: showSlNo,
        showQuantity: showQuantity,
        showDiscount: showDiscount,
        showTypeTag: showTypeTag,
        showAliasName: showAliasName,
        showDescription: showDescription,
        descriptionNewLine: descriptionNewLine,
        businessType: businessType,
        tableFontSize: tableFontSize,
        cellPaddingH: cellPadH,
        cellPaddingV: cellPadV,
        border: pw.TableBorder.all(width: 0.5, color: borderColor),
        totalQuantityText: showTotalQuantity && showQuantity
            ? '${totalQty == totalQty.roundToDouble() ? totalQty.toInt() : totalQty}'
            : null,
        watermarkBytes: watermarkBytes,
        watermarkOpacity: watermarkOpacity,
        showCgstSgst: showCgstSgst,
        showIgst: showIgst,
        isLandscape: landscape,
      ),
      // ── Notes, totals, signature, footer (inset again) ──
      buildInvoiceFooter()
    ],
  );
}
