import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/invoice.dart';
import 'pdf_widgets.dart';

pw.MultiPage buildExecutiveTemplate(
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
  BusinessType businessType = BusinessType.both,
  BankAccount? bankAccount,
  String datePattern = 'dd/MM/yyyy',
  LogoPosition logoPosition = LogoPosition.left,
  double logoSizePx = 90,
  Uint8List? logoBytes,
  String thankYouNote = '',
  bool showFooterBranding = true,
  PdfColor? themeColor,
  Uint8List? signatureBytes,
  String signaturePosition = 'left',
  double signatureSizePx = 50,
  double previousBalanceDue = 0.0,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
  Map<String, bool> metadataColumns = const {},
  double fontSizeScale = 1.0,
  // Per-section scales; each replaces fontSizeScale for its section.
  double companyNameScale = 1.0,
  double docTitleScale = 1.0,
  double tableHeaderScale = 1.0,
  double tableItemsScale = 1.0,
  double totalsScale = 1.0,
  pw.ThemeData? pdfTheme,
  Uint8List? watermarkBytes,
  double watermarkOpacity = 0.12,
  bool watermarkFullPage = false,
  bool showCgstSgst = false,
  bool showIgst = false,
  bool showTaxColumn = true,
  bool showRoundOff = false,
  bool showLeadingZeros = true,
  bool showPhone = true,
  bool showEmail = true,
  bool showCompanyName = true,
  bool showPan = true,
  bool showFssai = true,
  bool showWebsite = true,
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
  // User's PDF text size scales every font; paddings/gaps unchanged.
  final style = executivePdfStyle.scaled(fontSizeScale);
  final accentColor = themeColor ?? PdfColors.blueGrey800;
  final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
  final signatureImage =
      signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;

  pw.Widget partyBlock(String title, List<String> lines,
      {pw.CrossAxisAlignment alignment = pw.CrossAxisAlignment.start}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(style.sectionPadding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: alignment,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: accentColor,
              fontSize: style.bodyFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          ...lines.where((line) => line.trim().isNotEmpty).map((line) =>
              pw.Text(line, style: pw.TextStyle(fontSize: style.bodyFontSize))),
        ],
      ),
    );
  }

  final gstin = company?.gstin ?? '';
  final gstLabel = taxLabel(company?.country);
  final panNumber = company?.panNumber ?? '';
  final fssaiCode = company?.fssaiCode ?? '';
  final companyIdParts = <String>[
    if (showGst && gstin.isNotEmpty) '$gstLabel: $gstin',
    if (showPan && panNumber.isNotEmpty) '${panLabel(company?.country)}: $panNumber',
    if (showFssai && fssaiCode.isNotEmpty && isIndiaCountry(company?.country))
      'FSSAI: $fssaiCode',
  ];
  // GSTIN + PAN + FSSAI all present → one joined line; fewer → line by line.
  final allCompanyIds = companyIdParts.length == 3;
  final companyIdLine = companyIdParts.join('   ');

  pw.Widget customFieldsCard() {
    final filled = invoice.customFields
        .where((f) => f.value.trim().isNotEmpty)
        .toList();
    if (filled.isEmpty) return pw.Container();
    pw.Widget fieldCell(CustomFieldValue? f) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: f == null
              ? null
              : pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(f.label,
                        style: pw.TextStyle(
                            fontSize: style.bodyFontSize - 1,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.Text(f.value,
                        style: pw.TextStyle(fontSize: style.bodyFontSize)),
                  ],
                ),
        );
    return pw.Container(
      padding: pw.EdgeInsets.all(style.sectionPadding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Table(
        columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
        children: [
          for (var i = 0; i < filled.length; i += 2)
            pw.TableRow(children: [
              fieldCell(filled[i]),
              fieldCell(i + 1 < filled.length ? filled[i + 1] : null),
            ]),
        ],
      ),
    );
  }

  final customerLines = [
    invoice.customer.name,
    if (showCustomerBusinessName && invoice.customer.businessName.isNotEmpty)
      invoice.customer.businessName,
    if (showCustomerAddress && invoice.customer.address.isNotEmpty)
      invoice.customer.address,
    if (showCustomerPhone && invoice.customer.phone.isNotEmpty)
      invoice.customer.phone,
    if (showCustomerEmail && invoice.customer.email.isNotEmpty)
      invoice.customer.email,
    if (showGst && showCustomerGstin && invoice.customer.gstin.isNotEmpty)
      '${taxLabel(company?.country)}: ${invoice.customer.gstin}',
  ];

  final fullPageWatermark = watermarkFullPage && watermarkBytes != null;
  return pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: pw.EdgeInsets.all(PdfLayout.defaultHMargin),
      buildBackground: fullPageWatermark
          ? (context) =>
              buildFullPageWatermark(watermarkBytes, watermarkOpacity)
          : null,
      buildForeground: invoice.status == 'declined'
          ? (context) => buildDeclinedStamp()
          : null,
    ),
    footer: (context) => pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        showFooterBranding
            ? "Page ${context.pageNumber} of ${context.pagesCount}  -  Generated by Invoiso"
            : "Page ${context.pageNumber} of ${context.pagesCount}",
        style: pw.TextStyle(fontSize: PdfLayout.footerBrandingFontSize * fontSizeScale, color: PdfColors.grey600),
      ),
    ),
    build: (context) => [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 8, height: 96, color: accentColor),
          pw.SizedBox(width: 14),
          if (showLogo && logoImage != null && logoPosition == LogoPosition.left) ...[
            buildCompanyLogo(logoImage, size: logoSizePx),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  showCompanyName ? (company?.name ?? '') : '',
                  style: pw.TextStyle(
                    fontSize: executivePdfStyle.titleFontSize * companyNameScale,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: style.headerGap),
                if (showAddress)
                  pw.Text(company?.address ?? '',
                      style: pw.TextStyle(fontSize: style.subtitleFontSize)),
                if (showPhone)
                  pw.Text('Phone: ${company?.phone ?? ''}',
                      style: pw.TextStyle(fontSize: style.subtitleFontSize)),
                if (showEmail)
                  pw.Text('Email: ${company?.email ?? ''}',
                      style: pw.TextStyle(fontSize: style.subtitleFontSize)),
                if (showWebsite && (company?.website ?? '').isNotEmpty)
                  pw.Text(company!.website,
                      style: pw.TextStyle(fontSize: style.subtitleFontSize)),
                for (final line
                    in allCompanyIds ? [companyIdLine] : companyIdParts)
                  pw.Text(line, style: pw.TextStyle(fontSize: style.subtitleFontSize)),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (showLogo && logoImage != null && logoPosition == LogoPosition.right)
                buildCompanyLogo(logoImage, size: logoSizePx),
              pw.SizedBox(height: style.headerGap),
              if (invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros) != null)
                pw.Text(
                    '# ${invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros)}',
                    style: pw.TextStyle(
                        fontSize: style.bodyFontSize, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  'Date: ${formatPdfDateTime(invoice.date, datePattern, showTime: showTimeInPdf, timeFormat: pdfTimeFormat)}',
                  style: pw.TextStyle(fontSize: style.bodyFontSize)),
              if (invoice.dueDate != null)
                pw.Text('Due: ${formatPdfDate(invoice.dueDate!, datePattern)}',
                    style: pw.TextStyle(fontSize: style.bodyFontSize)),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Center(child: pw.Text(
        (invoice.invoiceTitle ?? invoice.type).toUpperCase(),
        style: pw.TextStyle(
          fontSize: executivePdfStyle.typeFont * docTitleScale,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
        ),
      ),),
      pw.SizedBox(height: 3),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: partyBlock('BILL TO', customerLines),
            flex: 1,
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(flex: 1, child: customFieldsCard()),
        ],
      ),
      pw.SizedBox(height: 5),
      buildInvoiceTable(
        invoice,
        InvoiceTemplate.executive,
        pageFormat,
        headerColor: accentColor,
        textColor: PdfColors.white,
        showGst: showGst,
        showSlNo: showSlNo,
        showQuantity: showQuantity,
        showDiscount: showDiscount,
        showTypeTag: showTypeTag,
        showAliasName: showAliasName,
        showDescription: showDescription,
        descriptionNewLine: descriptionNewLine,
        businessType: businessType,
        watermarkBytes: fullPageWatermark ? null : watermarkBytes,
        watermarkOpacity: watermarkOpacity,
        showCgstSgst: showCgstSgst, showIgst: showIgst,
        showTaxColumn: showTaxColumn,
        tableFontSize: executivePdfStyle.tableFontSize * tableItemsScale,
        tableHeaderFontSize: executivePdfStyle.tableFontSize * tableHeaderScale,
        columnScale: tableItemsScale > tableHeaderScale ? tableItemsScale : tableHeaderScale,
        metadataColumns: metadataColumns,
        metadataDatePattern: datePattern,
      ),
      pw.SizedBox(height: 5),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: buildAdditionalNotes(invoice, fontSize: 10 * fontSizeScale, accentColor: accentColor)),
          pw.SizedBox(width: 20),
          buildEnhancedTotals(
            invoice,
            PdfColors.grey200,
            PdfColors.black,
            accentColor,
            currencySymbol,
            previousBalanceDue: previousBalanceDue,
            showCgstSgst: showCgstSgst, showIgst: showIgst,
            showRoundOff: showRoundOff,
            fontSize: executivePdfStyle.totalsFontSize * totalsScale
          ),
        ],
      ),
      if (signatureImage != null || (showUpiQr && upiId != null) || bankAccount != null) ...[
        pw.SizedBox(height: 5),
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
                    amount: invoice.outstandingBalance,
                    currencyCode: invoice.currencyCode,
                    invoiceId: invoice.id,
                    accentColor: accentColor,
                    bankFontSize: 7.5 * fontSizeScale,
                    sectionTitleFontSize: 8 * fontSizeScale,
                    upiIdFontSize: 7 * fontSizeScale,
                    upiAmountFontSize: 7 * fontSizeScale,
                  ),
                  signatureImage != null
                      ? buildSignatureWidget(signatureImage, signaturePosition,
                          imageHeight: signatureSizePx,
                          labelFontSize: 9 * fontSizeScale)
                      : pw.SizedBox(),
                ]
              : [
                  signatureImage != null
                      ? buildSignatureWidget(signatureImage, signaturePosition,
                          imageHeight: signatureSizePx,
                          labelFontSize: 9 * fontSizeScale)
                      : pw.SizedBox(),
                  buildBankUpiRow(
                    bankAccount: bankAccount,
                    showUpiQr: showUpiQr,
                    upiId: upiId,
                    companyName: company?.name ?? '',
                    amount: invoice.outstandingBalance,
                    currencyCode: invoice.currencyCode,
                    invoiceId: invoice.id,
                    accentColor: accentColor,
                    bankFontSize: 7.5 * fontSizeScale,
                    sectionTitleFontSize: 8 * fontSizeScale,
                    upiIdFontSize: 7 * fontSizeScale,
                    upiAmountFontSize: 7 * fontSizeScale,
                  ),
                ],
        ),
      ],
      pw.SizedBox(height: 5),
      pw.Container(height: 2, color: accentColor),
      pw.SizedBox(height: 5),
      pw.Center(
        child: pw.Text(
          thankYouNote,
          style: pw.TextStyle(
            color: accentColor,
            fontSize: PdfLayout.thankYouNoteFontSize * fontSizeScale,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
