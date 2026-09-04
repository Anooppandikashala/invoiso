import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'pdf_widgets.dart';

/// Resolved colour set for the Elegant Dark template. Two palettes ('dark' |
/// 'light') sharing the same roles; the gold/silver look is just [accent]
/// (picked via the existing PDF theme-colour setting).
class _ElegantPalette {
  final PdfColor pageBg;
  final PdfColor surface; // zebra rows, notes / bank / totals boxes
  final PdfColor surfaceLine; // hairline dividers, box borders
  final PdfColor textPrimary;
  final PdfColor textMuted;
  final PdfColor accent;
  final PdfColor accentText; // text sitting on an [accent] fill
  final PdfColor plate; // light plate behind QR / signature (dark mode)

  const _ElegantPalette({
    required this.pageBg,
    required this.surface,
    required this.surfaceLine,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentText,
    required this.plate,
  });

  bool get isLight => pageBg.luminance > 0.5;

  factory _ElegantPalette.resolve(String mode, PdfColor accent) {
    // White on the accent fill only when the accent is genuinely dark.
    final onAccent =
        accent.luminance > 0.32 ? PdfColor.fromHex('#161310') : PdfColors.white;
    if (mode == 'light') {
      return _ElegantPalette(
        pageBg: PdfColor.fromHex('#FBF9F4'),
        surface: PdfColor.fromHex('#F1ECE0'),
        surfaceLine: PdfColor.fromHex('#E0D9C8'),
        textPrimary: PdfColor.fromHex('#1E1B14'),
        textMuted: PdfColor.fromHex('#6B655A'),
        accent: accent,
        accentText: onAccent,
        plate: PdfColors.white,
      );
    }
    return _ElegantPalette(
      pageBg: PdfColor.fromHex('#14161A'),
      surface: PdfColor.fromHex('#1E2127'),
      surfaceLine: PdfColor.fromHex('#2C3038'),
      textPrimary: PdfColor.fromHex('#F3EFE6'),
      textMuted: PdfColor.fromHex('#A9A79F'),
      accent: accent,
      accentText: onAccent,
      plate: PdfColor.fromHex('#F3EFE6'),
    );
  }
}

pw.MultiPage buildElegantDarkTemplate(
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
  String elegantPalette = 'dark',
}) {
  final p = _ElegantPalette.resolve(
      elegantPalette, themeColor ?? PdfColor.fromHex('#C9A227'));
  final style = elegantPdfStyle;
  final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
  final signatureImage =
      signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;

  // ── Geometry ──────────────────────────────────────────────────────
  // The left rail is a page-1-only band at the top of the flowing content;
  // the items table and everything below it run full page width and
  // paginate normally, so pages 2+ have no reserved left column.
  const double railWidth = 150;
  const double edge = 30; // page margin
  const double railInnerPad = 14;

  pw.Widget railHeading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(
            color: p.accent,
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
      );

  pw.Widget railLine(String text, {bool strong = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: strong ? p.textPrimary : p.textMuted,
            fontSize: 8,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  pw.Widget railSection(String title, List<String> lines,
      {bool strongFirst = true,
      pw.CrossAxisAlignment align = pw.CrossAxisAlignment.start}) {
    final visible = lines.where((l) => l.trim().isNotEmpty).toList();
    if (visible.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: align,
        children: [
          railHeading(title),
          for (var i = 0; i < visible.length; i++)
            railLine(visible[i], strong: i == 0 && strongFirst),
        ],
      ),
    );
  }

  final gstin = company?.gstin ?? '';
  final gstLabel = taxLabel(company?.country);
  final panNumber = company?.panNumber ?? '';
  final fssaiCode = company?.fssaiCode ?? '';
  final companyIdLines = [
    if (showGst && gstin.isNotEmpty) '$gstLabel: $gstin',
    if (showPan && panNumber.isNotEmpty)
      '${panLabel(company?.country)}: $panNumber',
    if (showFssai && fssaiCode.isNotEmpty) 'FSSAI: $fssaiCode',
  ];

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

  final fromLines = [
    if (showCompanyName && (company?.name ?? '').isNotEmpty) company!.name,
    if (showAddress && (company?.address ?? '').isNotEmpty) company!.address,
    if (showPhone && (company?.phone ?? '').isNotEmpty) company!.phone,
    if (showEmail && (company?.email ?? '').isNotEmpty) company!.email,
    if (showWebsite && (company?.website ?? '').isNotEmpty) company!.website,
    ...companyIdLines,
  ];

  final numberText =
      invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros);
  final titleText = (invoice.invoiceTitle ?? invoice.type).toUpperCase();

  // ── Logo (height follows the Logo Size setting: xsmall 40 → large 120,
  // width capped so it can't overflow its column) ──────────────────
  final bool hasLogo = showLogo && logoImage != null;
  final bool logoOnRight = hasLogo && logoPosition == LogoPosition.right;

  pw.Widget logoWidget(double maxWidth, pw.Alignment align) => pw.Container(
        alignment: align,
        child: pw.ConstrainedBox(
          constraints:
              pw.BoxConstraints(maxWidth: maxWidth, maxHeight: logoSizePx),
          child: pw.Image(logoImage!, fit: pw.BoxFit.contain),
        ),
      );

  // ── The logo rail (page 1 only). Sits on the left, or mirrors to
  //    the right when Logo Position is "right". Null when no logo. ─
  final pw.Widget? rail = !hasLogo
      ? null
      : pw.Container(
    width: railWidth,
    padding: logoOnRight
        ? pw.EdgeInsets.only(left: railInnerPad)
        : pw.EdgeInsets.only(right: railInnerPad),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: logoOnRight
            ? pw.BorderSide(color: p.surfaceLine, width: 0.7)
            : pw.BorderSide.none,
        right: logoOnRight
            ? pw.BorderSide.none
            : pw.BorderSide(color: p.surfaceLine, width: 0.7),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: logoOnRight
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        logoWidget(
            railWidth - railInnerPad,
            logoOnRight
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft),
        pw.SizedBox(height: 6),
        pw.Container(width: 44, height: 2, color: p.accent),
        pw.SizedBox(height: 20),
        if (numberText != null)
          railSection(titleText, ['# $numberText'],
              strongFirst: false,
              align: logoOnRight
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start),
      ],
    ),
  );

  pw.Widget dateMetaRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(label.toUpperCase(),
                style: pw.TextStyle(
                    color: p.textMuted,
                    fontSize: 7,
                    letterSpacing: 1.2)),
            pw.SizedBox(width: 8),
            pw.Text(value,
                style: pw.TextStyle(
                    color: p.textPrimary,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  return pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: pw.EdgeInsets.all(edge),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: p.pageBg),
      ),
    ),
    footer: (context) => pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 14),
      child: pw.Text(
        showFooterBranding
            ? 'Page ${context.pageNumber} of ${context.pagesCount}   ·   Generated by Invoiso'
            : 'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: style.footerFontSize, color: p.textMuted),
      ),
    ),
    build: (context) => [
      // ── Header: logo rail (left, or right-mirrored) + meta block ──
      //    (dates; invoice no. joins it when there's no rail) ───────
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (rail != null && !logoOnRight) ...[rail, pw.SizedBox(width: 24)],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment:
                  logoOnRight ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
              children: [
                if (!hasLogo && numberText != null)
                  dateMetaRow('$titleText No.', numberText),
                dateMetaRow(
                    'Date',
                    formatPdfDateTime(invoice.date, datePattern,
                        showTime: showTimeInPdf, timeFormat: pdfTimeFormat)),
                if (invoice.dueDate != null)
                  dateMetaRow('Due Date',
                      formatPdfDate(invoice.dueDate!, datePattern)),
                pw.SizedBox(height: 16),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: railSection('From', fromLines)),
                    pw.SizedBox(width: 24),
                    pw.Expanded(child: railSection('Bill To', customerLines)),
                  ],
                ),
              ],
            ),
          ),
          if (rail != null && logoOnRight) ...[pw.SizedBox(width: 24), rail],
        ],
      ),
      pw.SizedBox(height: style.sectionPadding + 6),
      // ── Items ─────────────────────────────────────────────────────
      buildInvoiceTable(
        invoice,
        InvoiceTemplate.elegantDark,
        pageFormat,
        headerColor: p.accent,
        textColor: p.accentText,
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
        cellPaddingH: 6,
        cellPaddingV: style.cellPaddingV,
        watermarkBytes: watermarkBytes,
        watermarkOpacity: watermarkOpacity,
        showCgstSgst: showCgstSgst,
        showIgst: showIgst,
        bodyTextColor: p.textPrimary,
        mutedTextColor: p.textMuted,
        rowColorEven: p.pageBg,
        rowColorOdd: p.surface,
        dividerColor: p.surfaceLine,
      ),
      pw.SizedBox(height: style.sectionPadding + 6),
      // ── Payment terms (left) + totals (right) ───────────────────
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: (bankAccount != null || (showUpiQr && upiId != null))
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      railHeading('Payment Terms'),
                      pw.SizedBox(height: 6),
                      buildBankUpiRow(
                        bankAccount: bankAccount,
                        showUpiQr: showUpiQr,
                        upiId: upiId,
                        companyName: company?.name ?? '',
                        amount: invoice.total,
                        currencyCode: invoice.currencyCode,
                        invoiceId: invoice.id,
                        accentColor: p.accent,
                        surfaceColor: p.surface,
                        labelColor: p.textMuted,
                        valueColor: p.textPrimary,
                        alignment: pw.MainAxisAlignment.start,
                      ),
                    ],
                  )
                : pw.SizedBox(),
          ),
          pw.SizedBox(width: 24),
          buildEnhancedTotals(
            invoice,
            p.surface,
            p.textPrimary,
            p.accent,
            currencySymbol,
            previousBalanceDue: previousBalanceDue,
            showCgstSgst: showCgstSgst,
            showIgst: showIgst,
            showRoundOff: showRoundOff,
            fontSize: style.totalsFontSize,
            borderColor: p.pageBg,
            labelColor: p.textMuted,
            highlightTextColor: p.accentText,
          ),
        ],
      ),
      // ── Notes (left) + signature (right) ────────────────────────
      if ((invoice.notes ?? '').trim().isNotEmpty || signatureImage != null) ...[
        pw.SizedBox(height: style.sectionPadding + 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: () {
            final notesW = (invoice.notes ?? '').trim().isNotEmpty
                ? pw.Expanded(
                    child: buildAdditionalNotes(
                      invoice,
                      fontSize: style.bodyFontSize,
                      accentColor: p.accent,
                      backgroundColor: p.surface,
                      textColor: p.textMuted,
                    ),
                  )
                : pw.Expanded(child: pw.SizedBox());
            final sigW = signatureImage != null
                ? buildSignatureWidget(signatureImage, signaturePosition,
                    imageHeight: signatureSizePx,
                    labelColor: p.textMuted,
                    plateColor: p.isLight ? null : p.plate)
                : pw.SizedBox();
            return signaturePosition == 'left'
                ? [sigW, pw.SizedBox(width: 28), notesW]
                : [notesW, pw.SizedBox(width: 28), sigW];
          }(),
        ),
      ],
      // ── Thank-you ────────────────────────────────────────────────
      if (thankYouNote.trim().isNotEmpty) ...[
        pw.SizedBox(height: style.sectionPadding + 8),
        pw.Container(height: 0.7, color: p.surfaceLine),
        pw.SizedBox(height: style.sectionPadding),
        pw.Text(
          thankYouNote,
          style: pw.TextStyle(
            color: p.accent,
            fontSize: PdfLayout.thankYouNoteFontSize,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ],
  );
}
