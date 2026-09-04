import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'pdf_widgets.dart';

/// Clean corporate A4 invoice: logo + company identity, a right-aligned
/// contact block, a big "INVOICE" title, a label/value "Invoice To" panel,
/// a navy items table, payment + totals, then terms and a signature.
/// Accent colour = the PDF theme colour (defaults to navy).
pw.MultiPage buildCorporateTemplate(
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
  pw.ThemeData? pdfTheme,
  Uint8List? watermarkBytes,
  double watermarkOpacity = 0.12,
  bool showCgstSgst = false,
  bool showIgst = false,
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
  final style = corporatePdfStyle;
  final accent = themeColor ?? PdfColor.fromHex('#1F3864');
  final onAccent =
      accent.luminance > 0.55 ? PdfColor.fromHex('#1A1A1A') : PdfColors.white;
  final ink = PdfColor.fromHex('#1F2430');
  final muted = PdfColor.fromHex('#6B7280');
  final surface = PdfColor.fromHex('#F3F4F6');
  final line = PdfColor.fromHex('#E5E7EB');

  final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
  final signatureImage =
      signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;
  final bool hasLogo = showLogo && logoImage != null;
  final bool logoOnRight = hasLogo && logoPosition == LogoPosition.right;

  final numberText =
      invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros);
  final titleText = (invoice.invoiceTitle ?? invoice.type).toUpperCase();
  final dueTotal =
      invoice.outstandingBalance > 0 ? invoice.outstandingBalance : invoice.total;

  final gstin = company?.gstin ?? '';
  final gstLabel = taxLabel(company?.country);
  final panNumber = company?.panNumber ?? '';
  final fssaiCode = company?.fssaiCode ?? '';

  final contactLines = [
    if (showAddress && (company?.address ?? '').isNotEmpty) company!.address,
    if (showPhone && (company?.phone ?? '').isNotEmpty) company!.phone,
    if (showEmail && (company?.email ?? '').isNotEmpty) company!.email,
    if (showWebsite && (company?.website ?? '').isNotEmpty) company!.website,
    if (showGst && gstin.isNotEmpty) '$gstLabel: $gstin',
    if (showPan && panNumber.isNotEmpty)
      '${panLabel(company?.country)}: $panNumber',
    if (showFssai && fssaiCode.isNotEmpty) 'FSSAI: $fssaiCode',
  ];

  // "Invoice To" label/value rows.
  final billToRows = <List<String>>[
    ['Name', invoice.customer.name],
    if (showCustomerBusinessName && invoice.customer.businessName.isNotEmpty)
      ['Company', invoice.customer.businessName],
    if (showCustomerEmail && invoice.customer.email.isNotEmpty)
      ['Email', invoice.customer.email],
    if (showCustomerPhone && invoice.customer.phone.isNotEmpty)
      ['Phone', invoice.customer.phone],
    if (showCustomerAddress && invoice.customer.address.isNotEmpty)
      ['Address', invoice.customer.address],
    if (showGst && showCustomerGstin && invoice.customer.gstin.isNotEmpty)
      [taxLabel(company?.country), invoice.customer.gstin],
  ];

  pw.Widget logoWidget(pw.Alignment align) => pw.Container(
        alignment: align,
        child: pw.ConstrainedBox(
          constraints:
              pw.BoxConstraints(maxWidth: 200, maxHeight: logoSizePx),
          child: pw.Image(logoImage!, fit: pw.BoxFit.contain),
        ),
      );

  pw.Widget sectionLabel(String text) => pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          color: accent,
          fontSize: style.labelFontSize,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1,
        ),
      );

  // The contact side carries the company name (bold) + all contact/tax
  // lines; the identity side is just the logo. When there's no logo the
  // contact block goes to the left, full width.
  final bool contactAlignEnd = hasLogo && !logoOnRight;
  final pw.TextAlign contactTextAlign =
      contactAlignEnd ? pw.TextAlign.right : pw.TextAlign.left;

  final pw.Widget? identityBlock = !hasLogo
      ? null
      : logoWidget(logoOnRight
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft);

  final contactBlock = pw.Column(
    crossAxisAlignment: contactAlignEnd
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start,
    children: [
      if (showCompanyName && (company?.name ?? '').isNotEmpty) ...[
        pw.Text(company!.name,
            textAlign: contactTextAlign,
            style: pw.TextStyle(
                color: accent, fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
      ],
      ...contactLines.where((l) => l.trim().isNotEmpty).map((l) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(l,
                textAlign: contactTextAlign,
                style: pw.TextStyle(
                    color: muted, fontSize: style.subtitleFontSize)),
          )),
    ],
  );

  pw.Widget metaLine(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.RichText(
          textAlign: pw.TextAlign.right,
          text: pw.TextSpan(children: [
            pw.TextSpan(
                text: '$label ',
                style: pw.TextStyle(
                    color: muted,
                    fontSize: style.subtitleFontSize,
                    fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                    color: ink, fontSize: style.subtitleFontSize)),
          ]),
        ),
      );

  final invoiceMetaBlock = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Text(titleText,
          style: pw.TextStyle(
              color: accent,
              fontSize: style.titleFontSize,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1)),
      pw.SizedBox(height: 8),
      if (numberText != null) metaLine('$titleText NO:', numberText),
      metaLine(
          'DATE:',
          formatPdfDateTime(invoice.date, datePattern,
              showTime: showTimeInPdf, timeFormat: pdfTimeFormat)),
      if (invoice.dueDate != null)
        metaLine('DUE DATE:', formatPdfDate(invoice.dueDate!, datePattern)),
      pw.SizedBox(height: 6),
      pw.Text('DUE TOTAL: $currencySymbol${dueTotal.toStringAsFixed(2)}',
          style: pw.TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold)),
    ],
  );

  return pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: pw.EdgeInsets.all(PdfLayout.defaultHMargin + 8),
    ),
    footer: (context) => pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 14),
      child: pw.Text(
        showFooterBranding
            ? 'Page ${context.pageNumber} of ${context.pagesCount}   ·   Generated by Invoiso'
            : 'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: style.footerFontSize, color: muted),
      ),
    ),
    build: (context) => [
      // ── Header: logo (one side) + company name & contact ────────
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: identityBlock == null
            ? [pw.Expanded(child: contactBlock)]
            : logoOnRight
                ? [
                    pw.Expanded(child: contactBlock),
                    pw.SizedBox(width: 24),
                    identityBlock,
                  ]
                : [
                    identityBlock,
                    pw.SizedBox(width: 24),
                    pw.Expanded(child: contactBlock),
                  ],
      ),
      pw.SizedBox(height: style.sectionPadding + 6),
      // ── Invoice To + invoice meta ──────────────────────────────
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                sectionLabel('$titleText to :'),
                pw.SizedBox(height: 6),
                ...billToRows.map((r) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 62,
                            child: pw.Text(r[0],
                                style: pw.TextStyle(
                                    color: ink,
                                    fontSize: style.subtitleFontSize,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Expanded(
                            child: pw.Text(r[1],
                                style: pw.TextStyle(
                                    color: muted,
                                    fontSize: style.subtitleFontSize)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          invoiceMetaBlock,
        ],
      ),
      pw.SizedBox(height: style.sectionPadding + 6),
      // ── Items ──────────────────────────────────────────────────
      buildInvoiceTable(
        invoice,
        InvoiceTemplate.corporate,
        pageFormat,
        headerColor: accent,
        textColor: onAccent,
        showGst: showGst,
        showSlNo: showSlNo,
        showQuantity: showQuantity,
        showDiscount: showDiscount,
        showTypeTag: showTypeTag,
        showAliasName: showAliasName,
        showDescription: showDescription,
        descriptionNewLine: descriptionNewLine,
        businessType: businessType,
        tableFontSize: style.tableFontSize,
        cellPaddingH: style.cellPaddingH,
        cellPaddingV: style.cellPaddingV,
        watermarkBytes: watermarkBytes,
        watermarkOpacity: watermarkOpacity,
        showCgstSgst: showCgstSgst,
        showIgst: showIgst,
        bodyTextColor: ink,
        mutedTextColor: muted,
        rowColorEven: PdfColors.white,
        rowColorOdd: surface,
        dividerColor: line,
      ),
      pw.SizedBox(height: style.sectionPadding + 6),
      // ── Payment (left) + totals (right) ────────────────────────
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: (bankAccount != null || (showUpiQr && upiId != null))
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      sectionLabel('Payment'),
                      pw.SizedBox(height: 6),
                      buildBankUpiRow(
                        bankAccount: bankAccount,
                        showUpiQr: showUpiQr,
                        upiId: upiId,
                        companyName: company?.name ?? '',
                        amount: invoice.total,
                        currencyCode: invoice.currencyCode,
                        invoiceId: invoice.id,
                        accentColor: accent,
                        labelColor: muted,
                        alignment: pw.MainAxisAlignment.start,
                      ),
                    ],
                  )
                : pw.SizedBox(),
          ),
          pw.SizedBox(width: 24),
          buildEnhancedTotals(
            invoice,
            surface,
            ink,
            accent,
            currencySymbol,
            previousBalanceDue: previousBalanceDue,
            showCgstSgst: showCgstSgst,
            showIgst: showIgst,
            showRoundOff: showRoundOff,
            fontSize: style.totalsFontSize,
            borderColor: line,
            labelColor: ink,
            highlightTextColor: onAccent,
          ),
        ],
      ),
      // ── Terms (left) + signature (right) ───────────────────────
      if ((invoice.notes ?? '').trim().isNotEmpty || signatureImage != null) ...[
        pw.SizedBox(height: style.sectionPadding + 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: () {
            final termsW = (invoice.notes ?? '').trim().isNotEmpty
                ? pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        sectionLabel('Terms & Conditions :'),
                        pw.SizedBox(height: 5),
                        pw.Text(invoice.notes!,
                            style: pw.TextStyle(
                                color: muted,
                                fontSize: style.bodyFontSize,
                                lineSpacing: 2)),
                      ],
                    ),
                  )
                : pw.Expanded(child: pw.SizedBox());
            final sigW = signatureImage != null
                ? buildSignatureWidget(signatureImage, signaturePosition,
                    imageHeight: signatureSizePx, labelColor: muted)
                : pw.SizedBox();
            return signaturePosition == 'left'
                ? [sigW, pw.SizedBox(width: 28), termsW]
                : [termsW, pw.SizedBox(width: 28), sigW];
          }(),
        ),
      ],
      if (thankYouNote.trim().isNotEmpty) ...[
        pw.SizedBox(height: style.sectionPadding + 8),
        pw.Container(height: 0.7, color: line),
        pw.SizedBox(height: style.sectionPadding),
        pw.Center(
          child: pw.Text(thankYouNote,
              style: pw.TextStyle(
                  color: accent,
                  fontSize: PdfLayout.thankYouNoteFontSize,
                  fontWeight: pw.FontWeight.bold)),
        ),
      ],
    ],
  );
}
