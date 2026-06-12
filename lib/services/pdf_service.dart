import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:qr/qr.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/services/pdf_font_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';

import 'package:invoiso/models/invoice.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../common.dart';

/// All per-session settings needed to render a PDF.
/// Fetch once via [PDFService.fetchPdfSettings], reuse for every invoice in a batch.
class PdfGenerationSettings {
  final CompanyInfo? company;
  final InvoiceTemplate template;
  final String invoicePrefix;
  final bool showGst;
  final bool showQuantity;
  final bool showDiscount;
  final bool showTypeTag;
  final BusinessType businessType;
  final List<UpiEntry> upiEntries;
  final String? showQrStr;
  final bool showBankDetails;
  final List<BankAccount> bankAccounts;
  final LogoPosition logoPosition;
  final double logoSizePx;
  final Uint8List? logoBytes;
  final String thankYouNote;
  final String datePattern;
  final bool showFooterBranding;
  final PdfColor? themeColor;
  final Uint8List? signatureBytes;
  final String signaturePosition;
  final bool showPreviousBalance;
  final PdfPageFormat pageFormat;
  final bool showTotalQuantity;
  final pw.ThemeData pdfTheme;

  const PdfGenerationSettings({
    required this.company,
    required this.template,
    required this.invoicePrefix,
    required this.showGst,
    required this.showQuantity,
    required this.showDiscount,
    required this.showTypeTag,
    required this.businessType,
    required this.upiEntries,
    required this.showQrStr,
    required this.showBankDetails,
    required this.bankAccounts,
    required this.logoPosition,
    required this.logoSizePx,
    required this.logoBytes,
    required this.thankYouNote,
    required this.datePattern,
    required this.showFooterBranding,
    required this.themeColor,
    required this.showPreviousBalance,
    required this.pageFormat,
    required this.showTotalQuantity,
    required this.pdfTheme,
    this.signatureBytes,
    this.signaturePosition = 'left',
  });
}

// PDF Generation Service
class PDFService {
  // Logo bytes cache — avoids re-decoding base64 on every preview open.
  static Uint8List? _logoBytesCache;
  static String? _logoBase64Cache;

  static Uint8List? _cachedLogoBytes(String? base64Logo) {
    if (base64Logo == null || base64Logo.isEmpty) {
      _logoBytesCache = null;
      _logoBase64Cache = null;
      return null;
    }
    if (base64Logo == _logoBase64Cache && _logoBytesCache != null) {
      return _logoBytesCache;
    }
    _logoBase64Cache = base64Logo;
    _logoBytesCache = base64Decode(base64Logo);
    return _logoBytesCache;
  }

  /// Call to invalidate the logo cache when the user changes their logo.
  static void clearLogoCache() {
    _logoBytesCache = null;
    _logoBase64Cache = null;
  }

  /// Fetch all PDF generation settings in one parallel batch.
  /// Call once before a bulk export, then pass to [generateInvoicePDFWithSettings].
  static Future<PdfGenerationSettings> fetchPdfSettings({
    String datePattern = 'dd/MM/yyyy',
  }) async {
    final results = await Future.wait<dynamic>([
      CompanyInfoService.getCompanyInfo(), // 0
      SettingsService.getInvoiceTemplate(), // 1
      SettingsService.getSetting(SettingKey.invoicePrefix), // 2
      SettingsService.getShowGstFields(), // 3
      SettingsService.getShowQuantity(), // 4
      SettingsService.getShowDiscount(), // 5
      SettingsService.getShowTypeTag(), // 6
      SettingsService.getBusinessType(), // 7
      SettingsService.getUpiIds(), // 8
      SettingsService.getSetting(SettingKey.showUpiQr), // 9
      SettingsService.getShowBankDetails(), // 10
      SettingsService.getBankAccounts(), // 11
      SettingsService.getLogoPosition(), // 12
      SettingsService.getLogoSize(), // 13
      SettingsService.getCompanyLogo(), // 14
      SettingsService.getSetting(SettingKey.thankYouNote), // 15
      SettingsService.getShowInvoiceFooterBranding(), // 16
      SettingsService.getPdfThemeColor(), // 17
      SettingsService.getSignatureImage(), // 18
      SettingsService.getSignaturePosition(), // 19
      SettingsService.getShowPreviousBalance(), // 20
      SettingsService.getPageSize(), // 21
      SettingsService.getShowTotalQuantity(), // 22
    ]);

    final rawPrefix = (results[2] as String?) ?? 'INV';
    final pageSize = results[21] as PageSize;
    final template = effectiveInvoiceTemplateForPageSize(
      results[1] as InvoiceTemplate,
      pageSize,
    );
    final base64Logo = results[14] as String?;
    final themeColorHex = results[17] as String?;
    final base64Sig = results[18] as String?;
    final sigBytes = (base64Sig != null && base64Sig.isNotEmpty)
        ? base64Decode(base64Sig)
        : null;
    final pdfTheme = await PdfFontService.loadTheme();

    return PdfGenerationSettings(
      company: results[0] as CompanyInfo?,
      template: template,
      invoicePrefix: rawPrefix.isNotEmpty ? '$rawPrefix-' : '',
      showGst: results[3] as bool,
      showQuantity: results[4] as bool,
      showDiscount: results[5] as bool,
      showTypeTag: results[6] as bool,
      businessType: results[7] as BusinessType,
      upiEntries: results[8] as List<UpiEntry>,
      showQrStr: results[9] as String?,
      showBankDetails: results[10] as bool,
      bankAccounts: results[11] as List<BankAccount>,
      logoPosition: results[12] as LogoPosition,
      logoSizePx: _logoSizePx(results[13] as String),
      logoBytes: _cachedLogoBytes(base64Logo),
      thankYouNote: (results[15] as String?) ?? DefaultValues.thankYouNote,
      datePattern: datePattern,
      showFooterBranding: results[16] as bool,
      themeColor:
          themeColorHex == null ? null : PdfColor.fromHex(themeColorHex),
      signatureBytes: sigBytes,
      signaturePosition: results[19] as String,
      showPreviousBalance: results[20] as bool,
      pageFormat: _pageSizeToFormat(pageSize),
      showTotalQuantity: results[22] as bool,
      pdfTheme: pdfTheme,
    );
  }

  /// Build a PDF document using pre-fetched settings — no DB reads.
  /// Use this in batch exports to avoid redundant settings fetches per invoice.
  static pw.Document generateInvoicePDFWithSettings(
      Invoice invoice, PdfGenerationSettings s,
      {double previousBalanceDue = 0.0}) {
    final pdf = pw.Document(theme: s.pdfTheme);
    final currencySymbol = invoice.currencySymbol;
    final effectivePreviousBalance =
        s.showPreviousBalance ? previousBalanceDue : 0.0;
    final pdfTheme = s.pdfTheme;

    String? effectiveUpiId = invoice.upiId;
    if (effectiveUpiId == null || effectiveUpiId.trim().isEmpty) {
      final fallback = s.upiEntries.where((e) => e.isDefault).firstOrNull ??
          s.upiEntries.firstOrNull;
      effectiveUpiId = fallback?.id;
    } else {
      effectiveUpiId = effectiveUpiId.trim();
    }
    final showUpiQr = s.showQrStr == 'true' &&
        effectiveUpiId != null &&
        effectiveUpiId.isNotEmpty;

    BankAccount? effectiveBank;
    if (s.showBankDetails) {
      final savedId = invoice.bankAccountId;
      if (savedId != null && savedId.isNotEmpty) {
        effectiveBank =
            s.bankAccounts.where((e) => e.accountNumber == savedId).firstOrNull;
      }
      effectiveBank ??= s.bankAccounts.where((e) => e.isDefault).firstOrNull ??
          s.bankAccounts.firstOrNull;
    }

    switch (s.template) {
      case InvoiceTemplate.classic:
        pdf.addPage(_buildClassicTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          businessType: s.businessType,
          bankAccount: effectiveBank,
          datePattern: s.datePattern,
          logoPosition: s.logoPosition,
          logoSizePx: s.logoSizePx,
          logoBytes: s.logoBytes,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          signatureBytes: s.signatureBytes,
          signaturePosition: s.signaturePosition,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
        ));
      case InvoiceTemplate.modern:
        pdf.addPage(_buildModernTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          businessType: s.businessType,
          bankAccount: effectiveBank,
          datePattern: s.datePattern,
          logoPosition: s.logoPosition,
          logoSizePx: s.logoSizePx,
          logoBytes: s.logoBytes,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          signatureBytes: s.signatureBytes,
          signaturePosition: s.signaturePosition,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
        ));
      case InvoiceTemplate.minimal:
        pdf.addPage(_buildMinimalTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          businessType: s.businessType,
          bankAccount: effectiveBank,
          datePattern: s.datePattern,
          logoPosition: s.logoPosition,
          logoSizePx: s.logoSizePx,
          logoBytes: s.logoBytes,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          signatureBytes: s.signatureBytes,
          signaturePosition: s.signaturePosition,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
        ));
      case InvoiceTemplate.executive:
        pdf.addPage(_buildExecutiveTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          businessType: s.businessType,
          bankAccount: effectiveBank,
          datePattern: s.datePattern,
          logoPosition: s.logoPosition,
          logoSizePx: s.logoSizePx,
          logoBytes: s.logoBytes,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          signatureBytes: s.signatureBytes,
          signaturePosition: s.signaturePosition,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
        ));
      case InvoiceTemplate.compact:
        pdf.addPage(_buildCompactTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          businessType: s.businessType,
          bankAccount: effectiveBank,
          datePattern: s.datePattern,
          logoPosition: s.logoPosition,
          logoSizePx: s.logoSizePx,
          logoBytes: s.logoBytes,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          signatureBytes: s.signatureBytes,
          signaturePosition: s.signaturePosition,
          previousBalanceDue: effectivePreviousBalance,
          showTotalQuantity: s.showTotalQuantity,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
        ));
    }
    return pdf;
  }

  static Future<pw.Document> generateInvoicePDF(Invoice invoice,
      {String datePattern = 'dd/MM/yyyy'}) async {
    final settings = await fetchPdfSettings(datePattern: datePattern);
    final previousBalanceDue = settings.showPreviousBalance
        ? await InvoiceService.getPreviousBalanceDueForInvoice(invoice)
        : 0.0;
    return generateInvoicePDFWithSettings(
      invoice,
      settings,
      previousBalanceDue: previousBalanceDue,
    );
  }

  static pw.MultiPage _buildClassicTemplate(
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
    double previousBalanceDue = 0.0,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.ThemeData? pdfTheme,
  }) {
    final accentColor = themeColor ?? PdfColors.indigo900;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final signatureImage =
        signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;
    final thankyouNote = thankYouNote;

    return pw.MultiPage(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: pw.EdgeInsets.all(PdfLayout.defaultMargin),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Text(
          showFooterBranding
              ? "Page ${context.pageNumber} of ${context.pagesCount}  -  Generated by Invoiso"
              : "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        // 1. Header with Logo and Company Details
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null && logoPosition == LogoPosition.left)
              _buildCompanyLogo(logoImage, size: logoSizePx),
            // Company Info Block
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                // Subtle background for company info
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(company?.name ?? '',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(company?.address ?? '',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Phone: ${company?.phone ?? ''}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Email: ${company?.email ?? ''}',
                      style: const pw.TextStyle(fontSize: 10)),
                  if ((company?.website ?? '').isNotEmpty)
                    pw.Text('Web: ${company!.website}',
                        style: const pw.TextStyle(fontSize: 10)),
                  if (showGst)
                    pw.Text(
                        '${taxLabel(company?.country)}: ${company?.gstin ?? ''}',
                        style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 10,
                            color: PdfColors.grey700)),
                ],
              ),
            ),
            if (logoImage != null && logoPosition == LogoPosition.right)
              _buildCompanyLogo(logoImage, size: logoSizePx),
          ],
        ),

        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1, color: accentColor),
        pw.SizedBox(height: 10),

        // 2. Invoice Title and Number/Date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("${invoice.type} #: $invoicePrefix${invoice.id}",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text("Date: ${_formatDate(invoice.date, datePattern)}",
                    style: const pw.TextStyle(fontSize: 10)),
                if (invoice.dueDate != null)
                  pw.Text(
                      "Due Date: ${_formatDate(invoice.dueDate!, datePattern)}",
                      style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),

        // 3. Customer Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              color: PdfColors.grey200,
              child: pw.Text("BILL TO",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.grey700)),
            ),
            pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 5),
                      pw.Text(invoice.customer.name,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      if (invoice.customer.businessName.isNotEmpty)
                        pw.Text(invoice.customer.businessName,
                            style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(invoice.customer.address,
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(invoice.customer.phone,
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(invoice.customer.email,
                          style: const pw.TextStyle(fontSize: 10)),
                      if (showGst)
                        pw.Text(
                            "${taxLabel(company?.country)}: ${invoice.customer.gstin}",
                            style: pw.TextStyle(
                                fontStyle: pw.FontStyle.italic,
                                fontSize: 10,
                                color: PdfColors.grey600)),
                    ]))
          ],
        ),

        pw.SizedBox(height: 25),

        // 4. Items Table
        _buildInvoiceTable(invoice,
            headerColor: accentColor,
            textColor: PdfColors.white,
            showGst: showGst,
            showQuantity: showQuantity,
            showDiscount: showDiscount,
            showTypeTag: showTypeTag,
            businessType: businessType),

        pw.SizedBox(height: 20),

        // 5. Notes + Totals (side by side)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: _buildAdditionalNotes(invoice)),
            pw.SizedBox(width: 20),
            _buildEnhancedTotals(
              invoice,
              PdfColors.grey200,
              PdfColors.black,
              accentColor,
              currencySymbol,
              previousBalanceDue: previousBalanceDue,
            ),
          ],
        ),

        if (signatureImage != null) ...[
          pw.SizedBox(height: 16),
          _buildSignatureWidget(signatureImage, signaturePosition),
        ],

        if (showUpiQr && upiId != null || bankAccount != null)
          pw.SizedBox(height: 12),

        // 5c. QR + Bank Details
        if (showUpiQr && upiId != null || bankAccount != null)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (showUpiQr && upiId != null)
                  _buildUpiQrSection(
                    upiId: upiId,
                    companyName: company?.name ?? '',
                    amount: invoice.total,
                    currencyCode: invoice.currencyCode,
                    invoiceId: invoice.id,
                    accentColor: accentColor,
                  ),
                if (bankAccount != null) ...[
                  if (showUpiQr && upiId != null) pw.SizedBox(height: 12),
                  _buildBankDetailsSection(
                      bankAccount: bankAccount, accentColor: accentColor),
                ],
              ],
            ),
          ),

        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text(thankyouNote,
              style: pw.TextStyle(
                  fontSize: 14,
                  color: accentColor,
                  fontStyle: pw.FontStyle.italic,
                  fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.MultiPage _buildMinimalTemplate(
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
    double previousBalanceDue = 0.0,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.ThemeData? pdfTheme,
  }) {
    final accentColor = themeColor ?? PdfColors.grey700;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final signatureImage =
        signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;
    final thankyouNote = thankYouNote;

    return pw.MultiPage(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: pw.EdgeInsets.all(PdfLayout.defaultMargin), // Increased margin for more whitespace
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Text(
          showFooterBranding
              ? "Page ${context.pageNumber} of ${context.pagesCount}  -  Generated by Invoiso"
              : "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        // 1. Header (Invoice Title & Numbers)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (logoImage != null && logoPosition == LogoPosition.left)
              _buildCompanyLogo(logoImage, size: logoSizePx),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("${invoice.type} #: ",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: accentColor)),
                pw.Text("$invoicePrefix${invoice.id}",
                    style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 5),
                pw.Text("DATE",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: accentColor)),
                pw.Text(_formatDate(invoice.date, datePattern),
                    style: const pw.TextStyle(fontSize: 12)),
                if (invoice.dueDate != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Text("DUE DATE",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: accentColor)),
                  pw.Text(_formatDate(invoice.dueDate!, datePattern),
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ],
            ),
            if (logoImage != null && logoPosition == LogoPosition.right)
              _buildCompanyLogo(logoImage, size: logoSizePx),
          ],
        ),

        pw.SizedBox(height: 10),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 20),

        // 2. Company Info (From) & Customer Info (Bill To)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // FROM (Company Info)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("FROM",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: accentColor)),
                pw.SizedBox(height: 5),
                pw.Text(company?.name ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(company?.address ?? '',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(company?.phone ?? '',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(company?.email ?? '',
                    style: const pw.TextStyle(fontSize: 10)),
                if ((company?.website ?? '').isNotEmpty)
                  pw.Text(company!.website,
                      style: const pw.TextStyle(fontSize: 10)),
                if (showGst)
                  pw.Text(
                      "${taxLabel(company?.country)}: ${company?.gstin ?? ''}",
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic, fontSize: 9)),
              ],
            ),

            // BILL TO (Customer Info)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("BILL TO",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: accentColor)),
                pw.SizedBox(height: 5),
                pw.Text(invoice.customer.name,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                if (invoice.customer.businessName.isNotEmpty)
                  pw.Text(invoice.customer.businessName,
                      style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.address,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.phone,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.email,
                    style: const pw.TextStyle(fontSize: 10)),
                if (showGst)
                  pw.Text(
                      "${taxLabel(company?.country)}: ${invoice.customer.gstin}",
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic, fontSize: 9)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 30),

        // 3. Table (Clean, no external borders)
        _buildInvoiceTable(invoice,
            headerColor: PdfColors.grey100,
            textColor: PdfColors.black,
            showGst: showGst,
            showQuantity: showQuantity,
            showDiscount: showDiscount,
            showTypeTag: showTypeTag,
            businessType: businessType),

        pw.SizedBox(height: 20),

        // 4. Notes + Totals (side by side)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: _buildAdditionalNotes(invoice)),
            pw.SizedBox(width: 20),
            _buildEnhancedTotals(
              invoice,
              PdfColors.grey200,
              PdfColors.black,
              accentColor,
              currencySymbol,
              previousBalanceDue: previousBalanceDue,
            ),
          ],
        ),

        if (signatureImage != null) ...[
          pw.SizedBox(height: 16),
          _buildSignatureWidget(signatureImage, signaturePosition),
        ],

        if (showUpiQr && upiId != null || bankAccount != null)
          pw.SizedBox(height: 12),

        // 4c. QR + Bank Details
        if (showUpiQr && upiId != null || bankAccount != null)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (showUpiQr && upiId != null)
                  _buildUpiQrSection(
                    upiId: upiId,
                    companyName: company?.name ?? '',
                    amount: invoice.total,
                    currencyCode: invoice.currencyCode,
                    invoiceId: invoice.id,
                    accentColor: accentColor,
                  ),
                if (bankAccount != null) ...[
                  if (showUpiQr && upiId != null) pw.SizedBox(height: 12),
                  _buildBankDetailsSection(
                      bankAccount: bankAccount, accentColor: accentColor),
                ],
              ],
            ),
          ),

        pw.SizedBox(height: 30),

        // 5. Footer
        pw.Center(
          child: pw.Text(thankyouNote,
              style: pw.TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.MultiPage _buildModernTemplate(
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
    double previousBalanceDue = 0.0,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.ThemeData? pdfTheme,
  }) {
    final accentColor = themeColor ?? PdfColors.blue600;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final signatureImage =
        signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;
    final thankyouNote = thankYouNote;

    return pw.MultiPage(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: const pw.EdgeInsets.all(0),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          showFooterBranding
              ? "Page ${context.pageNumber} of ${context.pagesCount}  -  Generated by Invoiso"
              : "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        // 1. Header with Color Block
        pw.Container(
          color: accentColor,
          padding: const pw.EdgeInsets.all(30), // Increased padding
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoImage != null && logoPosition == LogoPosition.left)
                _buildCompanyLogo(logoImage, size: logoSizePx),
              // Company Info
              pw.Expanded(
                flex: 2,
                fit: pw.FlexFit.loose,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company?.name ?? '',
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold, // Use extraBold
                            color: PdfColors.white)),
                    pw.SizedBox(height: 8),
                    pw.Text(company?.address ?? '',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 10)),
                    pw.Text('Phone: ${company?.phone ?? ''}',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 10)),
                    pw.Text('Email: ${company?.email ?? ''}',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 10)),
                    if ((company?.website ?? '').isNotEmpty)
                      pw.Text(company!.website,
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    if (showGst)
                      pw.Text(
                          '${taxLabel(company?.country)}: ${company?.gstin ?? ''}',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontStyle: pw.FontStyle.italic,
                              fontSize: 10)),
                  ],
                ),
              ),
              // Logo
              if (logoImage != null && logoPosition == LogoPosition.right)
                _buildCompanyLogo(logoImage, size: logoSizePx),
            ],
          ),
        ),

        // 2. Invoice Title and Number/Date
        pw.Padding(
          padding: pw.EdgeInsets.fromLTRB(
              PdfLayout.defaultMargin, 10, PdfLayout.defaultMargin, 10), // Padding for this section
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Invoice Tag
              // pw.Text('INVOICE',
              //     style: pw.TextStyle(
              //         fontSize: 30,
              //         color: accentColor,
              //         fontWeight: pw.FontWeight.bold)),

              // Invoice Number and Date
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("${invoice.type} #: $invoicePrefix${invoice.id}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text("Date: ${_formatDate(invoice.date, datePattern)}",
                      style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.dueDate != null)
                    pw.Text(
                        "Due Date: ${_formatDate(invoice.dueDate!, datePattern)}",
                        style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        // 3. Bill To section
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: PdfLayout.defaultMargin),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("BILL TO",
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor)),
                pw.SizedBox(height: 6),
                pw.Text(invoice.customer.name,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (invoice.customer.businessName.isNotEmpty)
                  pw.Text(invoice.customer.businessName,
                      style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.address,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.phone,
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.email,
                    style: const pw.TextStyle(fontSize: 10)),
                if (showGst)
                  pw.Text(
                      "${taxLabel(company?.country)}: ${invoice.customer.gstin}",
                      style: pw.TextStyle(
                          fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 25),

        // 4. Table Section
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: PdfLayout.defaultMargin),
          child: _buildInvoiceTable(invoice,
              headerColor: accentColor,
              textColor: PdfColors.white,
              showGst: showGst,
              showQuantity: showQuantity,
              showDiscount: showDiscount,
              showTypeTag: showTypeTag,
              businessType: businessType),
        ),

        pw.SizedBox(height: 25),

        // 5. Notes + Totals (side by side)
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: PdfLayout.defaultMargin),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: _buildAdditionalNotes(invoice)),
              pw.SizedBox(width: 20),
              _buildEnhancedTotals(
                invoice,
                PdfColors.blue200,
                PdfColors.black,
                accentColor,
                currencySymbol,
                previousBalanceDue: previousBalanceDue,
              ),
            ],
          ),
        ),

        if (signatureImage != null) ...[
          pw.SizedBox(height: 16),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfLayout.defaultMargin),
          child:_buildSignatureWidget(signatureImage, signaturePosition)),
        ],

        if (showUpiQr && upiId != null || bankAccount != null)
          pw.SizedBox(height: 12),

        // 5c. QR + Bank Details
        if (showUpiQr && upiId != null || bankAccount != null)
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfLayout.defaultMargin),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (showUpiQr && upiId != null)
                    _buildUpiQrSection(
                      upiId: upiId,
                      companyName: company?.name ?? '',
                      amount: invoice.total,
                      currencyCode: invoice.currencyCode,
                      invoiceId: invoice.id,
                      accentColor: accentColor,
                    ),
                  if (bankAccount != null) ...[
                    if (showUpiQr && upiId != null) pw.SizedBox(height: 12),
                    _buildBankDetailsSection(
                        bankAccount: bankAccount, accentColor: accentColor),
                  ],
                ],
              ),
            ),
          ),

        pw.Spacer(),

        // 6. Footer thank-you
        pw.Container(
          color: accentColor,
          padding: pw.EdgeInsets.all((PdfLayout.defaultMargin-12)),
          child: pw.Center(
            child: pw.Text(thankyouNote,
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  static pw.MultiPage _buildExecutiveTemplate(
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
    double previousBalanceDue = 0.0,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    pw.ThemeData? pdfTheme,
  }) {
    final accentColor = themeColor ?? PdfColors.blueGrey800;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final signatureImage =
        signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;

    pw.Widget partyBlock(String title, List<String> lines,
        {pw.CrossAxisAlignment alignment = pw.CrossAxisAlignment.start}) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
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
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            ...lines.where((line) => line.trim().isNotEmpty).map((line) =>
                pw.Text(line, style: const pw.TextStyle(fontSize: 9))),
          ],
        ),
      );
    }

    final companyLines = [
      company?.name ?? '',
      company?.address ?? '',
      'Phone: ${company?.phone ?? ''}',
      'Email: ${company?.email ?? ''}',
      if ((company?.website ?? '').isNotEmpty) 'Web: ${company!.website}',
      if (showGst) '${taxLabel(company?.country)}: ${company?.gstin ?? ''}',
    ];
    final customerLines = [
      invoice.customer.name,
      if (invoice.customer.businessName.isNotEmpty)
        invoice.customer.businessName,
      invoice.customer.address,
      invoice.customer.phone,
      invoice.customer.email,
      if (showGst) '${taxLabel(company?.country)}: ${invoice.customer.gstin}',
    ];

    return pw.MultiPage(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: pw.EdgeInsets.all(PdfLayout.defaultMargin),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 16),
        child: pw.Text(
          showFooterBranding
              ? "Page ${context.pageNumber} of ${context.pagesCount}  -  Generated by Invoiso"
              : "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 8, height: 96, color: accentColor),
            pw.SizedBox(width: 14),
            if (logoImage != null && logoPosition == LogoPosition.left) ...[
              _buildCompanyLogo(logoImage, size: logoSizePx),
              pw.SizedBox(width: 14),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company?.name ?? '',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(company?.address ?? '',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Phone: ${company?.phone ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Email: ${company?.email ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                  if ((company?.website ?? '').isNotEmpty)
                    pw.Text(company!.website,
                        style: const pw.TextStyle(fontSize: 9)),
                  if (showGst)
                    pw.Text(
                        '${taxLabel(company?.country)}: ${company?.gstin ?? ''}',
                        style: const pw.TextStyle(fontSize: 9))
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (logoImage != null && logoPosition == LogoPosition.right)
                  _buildCompanyLogo(logoImage, size: logoSizePx),
                pw.Text(
                  invoice.type.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text('# $invoicePrefix${invoice.id}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${_formatDate(invoice.date, datePattern)}',
                    style: const pw.TextStyle(fontSize: 9)),
                if (invoice.dueDate != null)
                  pw.Text('Due: ${_formatDate(invoice.dueDate!, datePattern)}',
                      style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 22),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // pw.Expanded(child: partyBlock('FROM', companyLines)),
            // pw.SizedBox(width: 16),
            // Empty left half
            pw.Expanded(
              child: partyBlock('BILL TO', customerLines),
              flex: 1,
            ),
            pw.Expanded(flex: 1, child: pw.Container()),
          ],
        ),
        pw.SizedBox(height: 24),
        _buildInvoiceTable(
          invoice,
          headerColor: accentColor,
          textColor: PdfColors.white,
          showGst: showGst,
          showQuantity: showQuantity,
          showDiscount: showDiscount,
          showTypeTag: showTypeTag,
          businessType: businessType,
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: _buildAdditionalNotes(invoice)),
            pw.SizedBox(width: 20),
            _buildEnhancedTotals(
              invoice,
              PdfColors.grey200,
              PdfColors.black,
              accentColor,
              currencySymbol,
              previousBalanceDue: previousBalanceDue,
            ),
          ],
        ),
        if (signatureImage != null) ...[
          pw.SizedBox(height: 16),
          _buildSignatureWidget(signatureImage, signaturePosition),
        ],
        if (showUpiQr && upiId != null || bankAccount != null)
          pw.SizedBox(height: 12),
        if (showUpiQr && upiId != null || bankAccount != null)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (showUpiQr && upiId != null)
                  _buildUpiQrSection(
                    upiId: upiId,
                    companyName: company?.name ?? '',
                    amount: invoice.total,
                    currencyCode: invoice.currencyCode,
                    invoiceId: invoice.id,
                    accentColor: accentColor,
                  ),
                if (bankAccount != null) ...[
                  if (showUpiQr && upiId != null) pw.SizedBox(height: 12),
                  _buildBankDetailsSection(
                      bankAccount: bankAccount, accentColor: accentColor),
                ],
              ],
            ),
          ),
        pw.SizedBox(height: 26),
        pw.Container(height: 2, color: accentColor),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            thankYouNote,
            style: pw.TextStyle(
              color: accentColor,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static PdfPageFormat _pageSizeToFormat(PageSize size) {
    switch (size) {
      case PageSize.a6:
        return PdfPageFormat.a6;
      case PageSize.a4:
        return PdfPageFormat.a4;
    }
  }

  static pw.MultiPage _buildCompactTemplate(
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
    BusinessType businessType = BusinessType.both,
    BankAccount? bankAccount,
    String datePattern = 'dd/MM/yyyy',
    LogoPosition logoPosition = LogoPosition.left,
    double logoSizePx = 60,
    Uint8List? logoBytes,
    String thankYouNote = '',
    bool showFooterBranding = false,
    PdfColor? themeColor,
    Uint8List? signatureBytes,
    String signaturePosition = 'left',
    double previousBalanceDue = 0.0,
    bool showTotalQuantity = false,
    PdfPageFormat pageFormat = PdfPageFormat.a6,
    pw.ThemeData? pdfTheme,
  }) {
    final accentColor = themeColor ?? PdfColors.black;
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final signatureImage =
        signatureBytes != null ? pw.MemoryImage(signatureBytes) : null;

    final double fontScale = pageFormat == PdfPageFormat.a6 ? 0.78 : 1.0;
    final double tableFontSize = pageFormat == PdfPageFormat.a6
        ? compactPdfLayoutStyle.tableFontSize
        : 10 * fontScale;
    final double cellPaddingH = pageFormat == PdfPageFormat.a6
        ? compactPdfLayoutStyle.tableHorizontalPadding
        : 6.0;
    final double cellPaddingV = pageFormat == PdfPageFormat.a6
        ? compactPdfLayoutStyle.tableVerticalPadding
        : (8 * fontScale).clamp(4.0, 8.0);
    final double totalsFontSize = 10 * fontScale;
    final double headerFont = 13 * fontScale;
    final double labelFont = 14 * fontScale;
    final double addressFont = 8 * fontScale;
    final double sectionHeaderFont = 8 * fontScale;
    final double bodyFont = 9 * fontScale;
    final double pageMargin = pageFormat == PdfPageFormat.a6 ? 16.0 : 20.0;

    final totalQty = showTotalQuantity
        ? invoice.items.fold<double>(0, (s, i) => s + i.quantity)
        : 0.0;
    final qtyLabel = (invoice.quantityLabel?.isNotEmpty == true)
        ? invoice.quantityLabel!
        : 'Qty';
    final compactLogoSize = pageFormat == PdfPageFormat.a6
        ? logoSizePx * compactPdfLayoutStyle.logoScale
        : logoSizePx;

    return pw.MultiPage(
      pageFormat: pageFormat,
      theme: pdfTheme,
      margin: pw.EdgeInsets.all(pageMargin),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: pw.EdgeInsets.only(top: compactPdfLayoutStyle.footerTopMargin),
        child: pw.Text(
          showFooterBranding
              ? "Page ${context.pageNumber} of ${context.pagesCount}  -  Generated by Invoiso"
              : "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(
            fontSize: compactPdfLayoutStyle.footerBrandingFontSize,
            color: PdfColors.grey600,
          ),
        ),
      ),
      build: (context) => [
        // ── Header + invoice details ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null && logoPosition == LogoPosition.left) ...[
              _buildCompanyLogo(logoImage, size: compactLogoSize),
              pw.SizedBox(width: compactPdfLayoutStyle.headerGap),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              company?.name ?? '',
                              style: pw.TextStyle(
                                  fontSize: headerFont,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                            if ((company?.address ?? '').isNotEmpty)
                              pw.Text(company!.address,
                                  style: pw.TextStyle(
                                      fontSize: addressFont,
                                      color: PdfColors.grey700)),
                            if ((company?.phone ?? '').isNotEmpty)
                              pw.Text('Phone: ${company!.phone}',
                                  style: pw.TextStyle(
                                      fontSize: addressFont,
                                      color: PdfColors.grey700)),
                            if (showGst && (company?.gstin ?? '').isNotEmpty)
                              pw.Text(
                                  '${taxLabel(company?.country)}: ${company!.gstin}',
                                  style: pw.TextStyle(
                                      fontSize: addressFont,
                                      color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Text(
                        invoice.type,
                        style: pw.TextStyle(
                          fontSize: labelFont,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border:
                          pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: pw.EdgeInsets.all(
                                compactPdfLayoutStyle.headerPadding),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(
                                    color: PdfColors.grey400, width: 0.5),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Bill To:',
                                    style: pw.TextStyle(
                                        fontSize: sectionHeaderFont,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 1),
                                pw.Text(invoice.customer.name,
                                    style: pw.TextStyle(fontSize: bodyFont)),
                                if (invoice.customer.businessName.isNotEmpty)
                                  pw.Text(invoice.customer.businessName,
                                      style: pw.TextStyle(
                                          fontSize: addressFont,
                                          color: PdfColors.grey700)),
                                if (invoice.customer.address.isNotEmpty)
                                  pw.Text(invoice.customer.address,
                                      style: pw.TextStyle(
                                          fontSize: addressFont,
                                          color: PdfColors.grey700)),
                                if (showGst &&
                                    invoice.customer.gstin.isNotEmpty)
                                  pw.Text(
                                      '${taxLabel(company?.country)}: ${invoice.customer.gstin}',
                                      style: pw.TextStyle(
                                          fontSize: addressFont,
                                          color: PdfColors.grey700)),
                              ],
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Padding(
                            padding: pw.EdgeInsets.all(
                                compactPdfLayoutStyle.headerPadding),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Invoice Details:',
                                    style: pw.TextStyle(
                                        fontSize: sectionHeaderFont,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 1),
                                pw.Text('No: $invoicePrefix${invoice.id}',
                                    style: pw.TextStyle(fontSize: addressFont)),
                                pw.Text(
                                    'Date: ${_formatDate(invoice.date, datePattern)}',
                                    style: pw.TextStyle(fontSize: addressFont)),
                                if (invoice.dueDate != null)
                                  pw.Text(
                                      'Due: ${_formatDate(invoice.dueDate!, datePattern)}',
                                      style:
                                          pw.TextStyle(fontSize: addressFont)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (logoImage != null && logoPosition == LogoPosition.right) ...[
              pw.SizedBox(width: compactPdfLayoutStyle.headerGap),
              _buildCompanyLogo(logoImage, size: compactLogoSize),
            ],
          ],
        ),
        pw.SizedBox(height: 6),

        // ── Items Table ──
        _buildInvoiceTable(
          invoice,
          headerColor: PdfColors.grey200,
          textColor: PdfColors.black,
          showGst: showGst,
          showQuantity: showQuantity,
          showDiscount: showDiscount,
          showTypeTag: showTypeTag,
          businessType: businessType,
          tableFontSize: tableFontSize,
          cellPaddingH: cellPaddingH,
          cellPaddingV: cellPaddingV,
          totalQuantityText: showTotalQuantity && showQuantity
              ? '${totalQty == totalQty.roundToDouble() ? totalQty.toInt() : totalQty} $qtyLabel'
              : null,
        ),

        pw.SizedBox(height: 6),

        // ── Totals ──
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: _buildEnhancedTotals(
            invoice,
            PdfColors.grey100,
            PdfColors.black,
            accentColor,
            currencySymbol,
            previousBalanceDue: previousBalanceDue,
            fontSize: totalsFontSize,
            compact: true,
          ),
        ),

        // ── Signature ──
        if (signatureImage != null) ...[
          pw.SizedBox(height: compactPdfLayoutStyle.signatureTopGap),
          _buildSignatureWidget(
            signatureImage,
            signaturePosition,
            imageHeight: compactPdfLayoutStyle.signatureImageHeight,
            labelGap: compactPdfLayoutStyle.signatureLabelGap,
            labelFontSize: compactPdfLayoutStyle.signatureLabelFontSize,
          ),
        ],

        // ── UPI + Bank (optional) ──
        if ((showUpiQr && upiId != null) || bankAccount != null)
          pw.SizedBox(height: 10),
        if ((showUpiQr && upiId != null) || bankAccount != null)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (showUpiQr && upiId != null)
                  _buildUpiQrSection(
                    upiId: upiId,
                    companyName: company?.name ?? '',
                    amount: invoice.total,
                    currencyCode: invoice.currencyCode,
                    invoiceId: invoice.id,
                    accentColor: accentColor,
                  ),
                if (bankAccount != null) ...[
                  if (showUpiQr && upiId != null) pw.SizedBox(height: 8),
                  _buildBankDetailsSection(
                      bankAccount: bankAccount, accentColor: accentColor),
                ],
              ],
            ),
          ),

        if (thankYouNote.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(thankYouNote,
                style: pw.TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildSignatureWidget(
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

  static pw.Widget _buildBankDetailsSection({
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

  // UPI QR Code Section
  // Renders a bordered box containing a QR code, the UPI ID, and the amount.
  // Uses pw.CustomPaint to draw the QR matrix pixel-by-pixel — no Flutter
  // widget dependency, works entirely within the pdf package.
  static pw.Widget _buildUpiQrSection({
    required String upiId,
    required String companyName,
    required double amount,
    required String currencyCode,
    required String invoiceId,
    required PdfColor accentColor,
  }) {
    const double qrSize = 90.0;
    // Build a URI that any UPI-capable app can handle.
    final encodedName = Uri.encodeComponent(companyName);
    final encodedNote = Uri.encodeComponent('Invoice $invoiceId');
    final upiUri = 'upi://pay?pa=$upiId&pn=$encodedName'
        '&am=${amount.toStringAsFixed(2)}'
        '&cu=${currencyCode.toUpperCase()}'
        '&tn=$encodedNote';

    // Generate the QR matrix. QrCode.fromData auto-selects the version.
    // Wrapped in try/catch — if the URI is somehow unrepresentable we skip
    // the QR silently rather than crashing PDF generation.
    QrCode? qrCode;
    try {
      qrCode = QrCode.fromData(
        data: upiUri,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
    } catch (_) {
      return pw.SizedBox(); // fallback: render nothing
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

          // QR matrix rendered with CustomPaint
          pw.CustomPaint(
            size: PdfPoint(qrSize, qrSize),
            painter: (canvas, size) {
              final double moduleSize = qrSize / moduleCount;
              canvas.setFillColor(PdfColors.black);
              for (int row = 0; row < moduleCount; row++) {
                for (int col = 0; col < moduleCount; col++) {
                  if (qrImage.isDark(row, col)) {
                    final double x = col * moduleSize;
                    // PDF coordinate origin is bottom-left; flip the row axis.
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

  /// Shows a save-file dialog so the user can choose where to store the PDF.
  static Future<void> _downloadWithPicker(
      BuildContext context, Uint8List pdfBytes, Invoice invoice) async {
    final filename = buildPdfFilename(invoice);
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Invoice PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (savePath == null) return; // user cancelled
    final file = File(savePath);
    await file.writeAsBytes(pdfBytes);
    await OpenFile.open(file.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: $savePath'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Generates the PDF for [invoice] and opens a save-file dialog.
  /// Call this directly from the invoice list to download without opening preview.
  static Future<void> downloadPDF(BuildContext context, Invoice invoice) async {
    try {
      final pdf = await generateInvoicePDF(invoice);
      final bytes = await pdf.save();
      if (context.mounted) {
        await _downloadWithPicker(context, bytes, invoice);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading PDF: $e')),
        );
      }
    }
  }

  // Company Logo Builder
  static pw.Widget _buildCompanyLogo(pw.MemoryImage image, {double size = 90}) {
    return pw.Container(
      width: size,
      height: size,
      child: pw.Image(image, fit: pw.BoxFit.contain),
    );
  }

  static double _logoSizePx(String sizeKey) {
    switch (sizeKey) {
      case 'small':
        return 60;
      case 'large':
        return 120;
      default:
        return 90;
    }
  }

  // Enhanced totals with highlighted total - MODIFIED
  static pw.Widget _buildEnhancedTotals(
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
    final highlightFontSize = compactStyle?.highlightFontSize ?? fontSize * 1.2;
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
          _totalRow(
            "Subtotal",
            "$currencySymbol ${(invoice.totalDiscount > 0 ? invoice.grossSubtotal : invoice.subtotal).toStringAsFixed(2)}",
            fontSize: rowFontSize,
            horizontalPadding: rowHorizontalPadding,
            verticalPadding: rowVerticalPadding,
          ),
          if (invoice.totalDiscount > 0)
            _totalRow(
              "Discount",
              "-$currencySymbol ${invoice.totalDiscount.toStringAsFixed(2)}",
              color: PdfColors.orange800,
              fontSize: rowFontSize,
              horizontalPadding: rowHorizontalPadding,
              verticalPadding: rowVerticalPadding,
            ),
          if (invoice.taxMode != TaxMode.none)
            _totalRow(_taxLabel(invoice),
                "$currencySymbol ${invoice.tax.toStringAsFixed(2)}",
                fontSize: rowFontSize,
                horizontalPadding: rowHorizontalPadding,
                verticalPadding: rowVerticalPadding),
          ...invoice.additionalCosts.map((c) => _totalRow(
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
            _totalRow(
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
            _totalRow(
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

  static String _taxLabel(Invoice invoice) {
    switch (invoice.taxMode) {
      case TaxMode.global:
        return "Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%)";
      case TaxMode.perItem:
        return "Tax (per item)";
      case TaxMode.none:
        return "Tax";
    }
  }

  static pw.Widget _totalRow(String label, String value,
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

  // Build Invoice Table - MODIFIED
  static pw.Widget _buildInvoiceTable(Invoice invoice,
      {PdfColor headerColor = PdfColors.grey200,
      PdfColor textColor = PdfColors.black,
      bool showGst = true,
      bool showQuantity = true,
      bool showDiscount = true,
      bool showTypeTag = true,
      BusinessType businessType = BusinessType.both,
      double tableFontSize = 10,
      double cellPaddingH = 6,
      double cellPaddingV = 8,
      String? totalQuantityText}) {
    final bool showItemTax = invoice.taxMode == TaxMode.perItem;
    final String priceHeader = showQuantity ? 'Price' : 'Rate';

    // Build column widths dynamically based on which columns are visible
    int col = 0;
    final Map<int, pw.TableColumnWidth> colWidths = {
      col++: const pw.FlexColumnWidth(1), // Sl No
      col++: const pw.FlexColumnWidth(3), // Item Name
      if (showGst) col: const pw.FlexColumnWidth(2), // HSN Code
    };
    if (showGst) col++;
    if (showQuantity) colWidths[col++] = const pw.FlexColumnWidth(1); // Qty
    colWidths[col++] = const pw.FlexColumnWidth(1.5); // Price/Rate
    if (showItemTax) colWidths[col++] = const pw.FlexColumnWidth(1); // Tax %
    if (showDiscount) {
      colWidths[col++] = const pw.FlexColumnWidth(1.5); // Discount
    }
    colWidths[col++] = const pw.FlexColumnWidth(1.5); // Total
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
            _buildTableCell('Sl No',
                isHeader: true,
                textColor: textColor,
                fontSize: tableFontSize,
                cellPaddingH: cellPaddingH,
                cellPaddingV: cellPaddingV),
            _buildTableCell('Item Name',
                isHeader: true,
                textColor: textColor,
                fontSize: tableFontSize,
                cellPaddingH: cellPaddingH,
                cellPaddingV: cellPaddingV),
            if (showGst)
              _buildTableCell('HSN Code',
                  isHeader: true,
                  textColor: textColor,
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            if (showQuantity)
              _buildTableCell(
                  invoice.quantityLabel?.isNotEmpty == true
                      ? invoice.quantityLabel!
                      : 'Qty',
                  isHeader: true,
                  textColor: textColor,
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            _buildTableCell(priceHeader,
                isHeader: true,
                textColor: textColor,
                fontSize: tableFontSize,
                cellPaddingH: cellPaddingH,
                cellPaddingV: cellPaddingV),
            if (showItemTax)
              _buildTableCell('Tax %',
                  isHeader: true,
                  textColor: textColor,
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            if (showDiscount)
              _buildTableCell('Discount',
                  isHeader: true,
                  textColor: textColor,
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            _buildTableCell('Total',
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
              _buildTableCell('${index + 1}',
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
                    pw.Text(item.product.name,
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
                _buildTableCell(item.product.hsncode,
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              if (showQuantity)
                _buildTableCell(
                    item.quantity == item.quantity.roundToDouble()
                        ? item.quantity.toInt().toString()
                        : item.quantity.toString(),
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              _buildTableCell(
                  showDiscount
                      ? item.effectivePrice.toStringAsFixed(2)
                      : (item.total / item.quantity).toStringAsFixed(2),
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
              if (showItemTax)
                _buildTableCell('${item.product.tax_rate}%',
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              if (showDiscount)
                _buildTableCell(item.totalDiscount.toStringAsFixed(2),
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              _buildTableCell(item.total.toStringAsFixed(2),
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
              _buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
              _buildTableCell('Total',
                  isHeader: true,
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
              if (showGst)
                _buildTableCell('',
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              if (showQuantity)
                _buildTableCell(totalQuantityText,
                    isHeader: true,
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              _buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
              if (showItemTax)
                _buildTableCell('',
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              if (showDiscount)
                _buildTableCell('',
                    fontSize: tableFontSize,
                    cellPaddingH: cellPaddingH,
                    cellPaddingV: cellPaddingV),
              _buildTableCell('',
                  fontSize: tableFontSize,
                  cellPaddingH: cellPaddingH,
                  cellPaddingV: cellPaddingV),
            ],
          ),
        if (totalQuantityText != null) dividerRow(),
      ],
    );
  }

// Build Table Cell - MODIFIED
  static pw.Widget _buildTableCell(String text,
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

  static pw.Widget _buildAdditionalNotes(Invoice invoice) {
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

  static String _formatDate(DateTime date, String pattern) {
    return DateFormat(pattern).format(date);
  }

  static String buildPdfFilename(Invoice invoice) {
    final rawNumber = invoice.id.replaceAll(RegExp(r'^0+'), '');
    final invoiceNumber = rawNumber.isEmpty ? '0' : rawNumber;
    final fullName = invoice.customer.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final date = DateFormat('yyyyMMdd').format(invoice.date);
    return 'inv-$invoiceNumber-$fullName-$date.pdf';
  }

  static Future<void> showCenteredPDFViewer(
      BuildContext context, Uint8List pdfBytes, Invoice invoice) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: (MediaQuery.sizeOf(dialogContext).width * 0.8)
              .clamp(300.0, AppLayout.maxWidthNarrow),
          height: (MediaQuery.sizeOf(dialogContext).height * 0.9)
              .clamp(400.0, 1000.0),
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: Text('${invoice.type} #${invoice.id}'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Print',
                    onPressed: () async {
                      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Download',
                    onPressed: () =>
                        _downloadWithPicker(context, pdfBytes, invoice),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              Expanded(
                child: SfPdfViewer.memory(
                  pdfBytes,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  canShowPageLoadingIndicator: false,
                  canShowScrollStatus: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
