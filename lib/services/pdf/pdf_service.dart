import 'dart:convert';
import 'package:invoiso/services/backend_services.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf/pdf_font_service.dart';
import 'package:invoiso/services/thermal_printer_service_v1.dart';
import 'pdf_settings.dart';
import 'pdf_widgets.dart';
import 'pdf_template_classic.dart';
import 'pdf_template_minimal.dart';
import 'pdf_template_modern.dart';
import 'pdf_template_executive.dart';
import 'pdf_template_compact.dart';
import 'pdf_template_thermal.dart';
import 'pdf_template_gridclassic.dart';

class PDFService {
  static Uint8List? _logoBytesCache;
  static String? _logoBase64Cache;
  static Uint8List? _watermarkBytesCache;
  static String? _watermarkBase64Cache;

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

  static void clearLogoCache() {
    _logoBytesCache = null;
    _logoBase64Cache = null;
  }

  static Uint8List? _cachedWatermarkBytes(String? base64Watermark) {
    if (base64Watermark == null || base64Watermark.isEmpty) {
      _watermarkBytesCache = null;
      _watermarkBase64Cache = null;
      return null;
    }
    if (base64Watermark == _watermarkBase64Cache && _watermarkBytesCache != null) {
      return _watermarkBytesCache;
    }
    _watermarkBase64Cache = base64Watermark;
    _watermarkBytesCache = base64Decode(base64Watermark);
    return _watermarkBytesCache;
  }

  static void clearWatermarkCache() {
    _watermarkBytesCache = null;
    _watermarkBase64Cache = null;
  }

  /// Fetch all PDF generation settings in one parallel batch.
  /// Call once before a bulk export, then pass to [generateInvoicePDFWithSettings].
  static Future<PdfGenerationSettings> fetchPdfSettings({
    String datePattern = 'dd/MM/yyyy',
  }) async {
    final results = await Future.wait<dynamic>([
      BackendServices.companyInfo.getCompanyInfo(), // 0
      BackendServices.settings.getInvoiceTemplate(), // 1
      BackendServices.settings.getSetting(SettingKey.invoicePrefix), // 2
      BackendServices.settings.getShowGstFields(), // 3
      BackendServices.settings.getShowQuantity(), // 4
      BackendServices.settings.getShowDiscount(), // 5
      BackendServices.settings.getShowTypeTag(), // 6
      BackendServices.settings.getBusinessType(), // 7
      BackendServices.settings.getUpiIds(), // 8
      BackendServices.settings.getSetting(SettingKey.showUpiQr), // 9
      BackendServices.settings.getShowBankDetails(), // 10
      BackendServices.settings.getBankAccounts(), // 11
      BackendServices.settings.getLogoPosition(), // 12
      BackendServices.settings.getLogoSize(), // 13
      BackendServices.settings.getCompanyLogo(), // 14
      BackendServices.settings.getSetting(SettingKey.thankYouNote), // 15
      BackendServices.settings.getShowInvoiceFooterBranding(), // 16
      BackendServices.settings.getPdfThemeColor(), // 17
      BackendServices.settings.getSignatureImage(), // 18
      BackendServices.settings.getSignaturePosition(), // 19
      BackendServices.settings.getShowPreviousBalance(), // 20
      BackendServices.settings.getPageSize(), // 21
      BackendServices.settings.getShowTotalQuantity(), // 22
      BackendServices.settings.getSetting(SettingKey.thermalItemLayout), // 23
      BackendServices.settings.getSetting(SettingKey.showAliasNameInPdf), // 24
      BackendServices.settings.getSignatureSize(), // 25
      BackendServices.settings.getWatermarkImage(), // 26
      BackendServices.settings.getWatermarkOpacity(), // 27
      BackendServices.settings.getSetting(SettingKey.showCgstSgst), // 28
      BackendServices.settings.getSetting(SettingKey.showRoundOff), // 29
      BackendServices.settings.getShowPhone(), // 30
      BackendServices.settings.getShowEmail(), // 31
      BackendServices.settings.getShowCompanyName(), // 32
      BackendServices.settings.getShowPan(), // 33
      BackendServices.settings.getShowFssai(), // 34
      BackendServices.settings.getShowWebsite(), // 35
      BackendServices.settings.getShowAddress(), // 36
      BackendServices.settings.getShowLogo(), // 37
      BackendServices.settings.getSetting(SettingKey.thermalCompanyNameSize), // 38
      BackendServices.settings.getSetting(SettingKey.invoiceLeadingZeros), // 39
      BackendServices.settings.getSetting(SettingKey.showDescriptionInPdf), // 40
      BackendServices.settings.getSetting(SettingKey.descriptionNewLineInPdf), // 41
      BackendServices.settings.getShowCustomerBusinessName(), // 42
      BackendServices.settings.getShowCustomerAddress(), // 43
      BackendServices.settings.getShowCustomerPhone(), // 44
      BackendServices.settings.getShowCustomerEmail(), // 45
      BackendServices.settings.getShowCustomerGstin(), // 46
      BackendServices.settings.getShowTimeInPdf(), // 47
      BackendServices.settings.getPdfTimeFormat(), // 48
      BackendServices.settings.getShowSlNoInPdf(), // 49
      BackendServices.settings.getPdfLandscape(), // 50
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
      logoSizePx: logoSizePx(results[13] as String),
      logoBytes: _cachedLogoBytes(base64Logo),
      thankYouNote: (results[15] as String?) ?? DefaultValues.thankYouNote,
      datePattern: datePattern,
      showFooterBranding: results[16] as bool,
      themeColor:
          themeColorHex == null ? null : PdfColor.fromHex(themeColorHex),
      signatureBytes: sigBytes,
      signaturePosition: results[19] as String,
      signatureSizePx: signatureSizePx(results[25] as String),
      showPreviousBalance: results[20] as bool,
      pageFormat: pageSizeToFormat(pageSize),
      pageSize: pageSize,
      showTotalQuantity: results[22] as bool,
      pdfTheme: pdfTheme,
      thermalItemLayout: (results[23] as String?) ?? 'table',
      showAliasName: (results[24] as String?) == 'true',
      watermarkBytes: _cachedWatermarkBytes(results[26] as String?),
      watermarkOpacity: results[27] as double,
      showCgstSgst: (results[28] as String?) == 'true',
      showRoundOff: (results[29] as String?) == 'true',
      showPhone: results[30] as bool,
      showEmail: results[31] as bool,
      showCompanyName: results[32] as bool,
      showPan: results[33] as bool,
      showFssai: results[34] as bool,
      showWebsite: results[35] as bool,
      showAddress: results[36] as bool,
      showLogo: results[37] as bool,
      thermalCompanyNameSize: (results[38] as String?) ?? 'medium',
      showLeadingZeros: (results[39] as String?) != 'false',
      showDescription: (results[40] as String?) == 'true',
      descriptionNewLine: (results[41] as String?) == 'true',
      showCustomerBusinessName: results[42] as bool,
      showCustomerAddress: results[43] as bool,
      showCustomerPhone: results[44] as bool,
      showCustomerEmail: results[45] as bool,
      showCustomerGstin: results[46] as bool,
      showTimeInPdf: results[47] as bool,
      pdfTimeFormat: results[48] as String,
      showSlNo: results[49] as bool,
      landscape: results[50] as bool,
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
    final gstSplitOn = s.showCgstSgst &&
        isIndiaCountry(s.company?.country) &&
        invoice.taxMode != TaxMode.none;
    // Interstate supply → one IGST line; else the CGST/SGST 50/50 split.
    final showIgst = gstSplitOn && invoice.isInterState;
    final effectiveShowCgstSgst = gstSplitOn && !invoice.isInterState;

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
        pdf.addPage(buildClassicTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showCustomerBusinessName: s.showCustomerBusinessName,
          showCustomerAddress: s.showCustomerAddress,
          showCustomerPhone: s.showCustomerPhone,
          showCustomerEmail: s.showCustomerEmail,
          showCustomerGstin: s.showCustomerGstin,
          showTimeInPdf: s.showTimeInPdf,
          pdfTimeFormat: s.pdfTimeFormat,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showSlNo: s.showSlNo,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          showAliasName: s.showAliasName,
          showDescription: s.showDescription,
          descriptionNewLine: s.descriptionNewLine,
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
          signatureSizePx: s.signatureSizePx,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
          watermarkBytes: s.watermarkBytes,
          watermarkOpacity: s.watermarkOpacity,
          showCgstSgst: effectiveShowCgstSgst,
          showIgst: showIgst,
          showRoundOff: s.showRoundOff,
          showLeadingZeros: s.showLeadingZeros,
          showPhone: s.showPhone,
          showEmail: s.showEmail,
          showCompanyName: s.showCompanyName,
          showPan: s.showPan,
          showFssai: s.showFssai,
          showWebsite: s.showWebsite,
          showAddress: s.showAddress,
          showLogo: s.showLogo,
        ));
      case InvoiceTemplate.modern:
        pdf.addPage(buildModernTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showCustomerBusinessName: s.showCustomerBusinessName,
          showCustomerAddress: s.showCustomerAddress,
          showCustomerPhone: s.showCustomerPhone,
          showCustomerEmail: s.showCustomerEmail,
          showCustomerGstin: s.showCustomerGstin,
          showTimeInPdf: s.showTimeInPdf,
          pdfTimeFormat: s.pdfTimeFormat,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showSlNo: s.showSlNo,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          showAliasName: s.showAliasName,
          showDescription: s.showDescription,
          descriptionNewLine: s.descriptionNewLine,
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
          signatureSizePx: s.signatureSizePx,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
          watermarkBytes: s.watermarkBytes,
          watermarkOpacity: s.watermarkOpacity,
          showCgstSgst: effectiveShowCgstSgst,
          showIgst: showIgst,
          showRoundOff: s.showRoundOff,
          showLeadingZeros: s.showLeadingZeros,
          showPhone: s.showPhone,
          showEmail: s.showEmail,
          showCompanyName: s.showCompanyName,
          showPan: s.showPan,
          showFssai: s.showFssai,
          showWebsite: s.showWebsite,
          showAddress: s.showAddress,
          showLogo: s.showLogo,
        ));
      case InvoiceTemplate.minimal:
        pdf.addPage(buildMinimalTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showCustomerBusinessName: s.showCustomerBusinessName,
          showCustomerAddress: s.showCustomerAddress,
          showCustomerPhone: s.showCustomerPhone,
          showCustomerEmail: s.showCustomerEmail,
          showCustomerGstin: s.showCustomerGstin,
          showTimeInPdf: s.showTimeInPdf,
          pdfTimeFormat: s.pdfTimeFormat,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showSlNo: s.showSlNo,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          showAliasName: s.showAliasName,
          showDescription: s.showDescription,
          descriptionNewLine: s.descriptionNewLine,
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
          signatureSizePx: s.signatureSizePx,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
          watermarkBytes: s.watermarkBytes,
          watermarkOpacity: s.watermarkOpacity,
          showCgstSgst: effectiveShowCgstSgst,
          showIgst: showIgst,
          showRoundOff: s.showRoundOff,
          showLeadingZeros: s.showLeadingZeros,
          showPhone: s.showPhone,
          showEmail: s.showEmail,
          showCompanyName: s.showCompanyName,
          showPan: s.showPan,
          showFssai: s.showFssai,
          showWebsite: s.showWebsite,
          showAddress: s.showAddress,
          showLogo: s.showLogo,
        ));
      case InvoiceTemplate.executive:
        pdf.addPage(buildExecutiveTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showCustomerBusinessName: s.showCustomerBusinessName,
          showCustomerAddress: s.showCustomerAddress,
          showCustomerPhone: s.showCustomerPhone,
          showCustomerEmail: s.showCustomerEmail,
          showCustomerGstin: s.showCustomerGstin,
          showTimeInPdf: s.showTimeInPdf,
          pdfTimeFormat: s.pdfTimeFormat,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showSlNo: s.showSlNo,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          showAliasName: s.showAliasName,
          showDescription: s.showDescription,
          descriptionNewLine: s.descriptionNewLine,
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
          signatureSizePx: s.signatureSizePx,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
          watermarkBytes: s.watermarkBytes,
          watermarkOpacity: s.watermarkOpacity,
          showCgstSgst: effectiveShowCgstSgst,
          showIgst: showIgst,
          showRoundOff: s.showRoundOff,
          showLeadingZeros: s.showLeadingZeros,
          showPhone: s.showPhone,
          showEmail: s.showEmail,
          showCompanyName: s.showCompanyName,
          showPan: s.showPan,
          showFssai: s.showFssai,
          showWebsite: s.showWebsite,
          showAddress: s.showAddress,
          showLogo: s.showLogo,
        ));
      case InvoiceTemplate.compact:
        pdf.addPage(buildCompactTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showCustomerBusinessName: s.showCustomerBusinessName,
          showCustomerAddress: s.showCustomerAddress,
          showCustomerGstin: s.showCustomerGstin,
          showTimeInPdf: s.showTimeInPdf,
          pdfTimeFormat: s.pdfTimeFormat,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showSlNo: s.showSlNo,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          showAliasName: s.showAliasName,
          showDescription: s.showDescription,
          descriptionNewLine: s.descriptionNewLine,
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
          signatureSizePx: s.signatureSizePx,
          previousBalanceDue: effectivePreviousBalance,
          showTotalQuantity: s.showTotalQuantity,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
          watermarkBytes: s.watermarkBytes,
          watermarkOpacity: s.watermarkOpacity,
          showCgstSgst: effectiveShowCgstSgst,
          showIgst: showIgst,
          showRoundOff: s.showRoundOff,
          showLeadingZeros: s.showLeadingZeros,
          showPhone: s.showPhone,
          showCompanyName: s.showCompanyName,
          showPan: s.showPan,
          showFssai: s.showFssai,
          showAddress: s.showAddress,
          showLogo: s.showLogo,
        ));
      case InvoiceTemplate.thermal:
        pdf.addPage(buildThermalTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showCustomerBusinessName: s.showCustomerBusinessName,
          showCustomerPhone: s.showCustomerPhone,
          showCustomerGstin: s.showCustomerGstin,
          showTimeInPdf: s.showTimeInPdf,
          pdfTimeFormat: s.pdfTimeFormat,
          showGst: s.showGst,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showAliasName: s.showAliasName,
          showDescription: s.showDescription,
          datePattern: s.datePattern,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pageSize:s.pageSize,
          pdfTheme: pdfTheme,
          itemLayout: s.thermalItemLayout,
          showRoundOff: s.showRoundOff,
          showLeadingZeros: s.showLeadingZeros,
          showPhone: s.showPhone,
          showCompanyName: s.showCompanyName,
          showAddress: s.showAddress,
        ));
      case InvoiceTemplate.gridClassic:
        pdf.addPage(buildGridClassicTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showCustomerBusinessName: s.showCustomerBusinessName,
          showCustomerAddress: s.showCustomerAddress,
          showCustomerPhone: s.showCustomerPhone,
          showCustomerEmail: s.showCustomerEmail,
          showCustomerGstin: s.showCustomerGstin,
          showTimeInPdf: s.showTimeInPdf,
          pdfTimeFormat: s.pdfTimeFormat,
          upiId: effectiveUpiId,
          showUpiQr: showUpiQr,
          showGst: s.showGst,
          showSlNo: s.showSlNo,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showTypeTag: s.showTypeTag,
          showAliasName: s.showAliasName,
          showDescription: s.showDescription,
          descriptionNewLine: s.descriptionNewLine,
          showTotalQuantity: s.showTotalQuantity,
          businessType: s.businessType,
          bankAccount: effectiveBank,
          datePattern: s.datePattern,
          logoBytes: s.logoBytes,
          logoSizePx: s.logoSizePx,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          signatureBytes: s.signatureBytes,
          signaturePosition: s.signaturePosition,
          signatureSizePx: s.signatureSizePx,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          landscape: s.landscape,
          pdfTheme: pdfTheme,
          logoPosition: s.logoPosition,
          watermarkBytes: s.watermarkBytes,
          watermarkOpacity: s.watermarkOpacity,
          showCgstSgst: effectiveShowCgstSgst,
          showIgst: showIgst,
          showRoundOff: s.showRoundOff,
          showLeadingZeros: s.showLeadingZeros,
          showPhone: s.showPhone,
          showCompanyName: s.showCompanyName,
          showPan: s.showPan,
          showFssai: s.showFssai,
          showAddress: s.showAddress,
          showLogo: s.showLogo,
        ));
    }
    return pdf;
  }

  static Future<pw.Document> generateInvoicePDF(Invoice invoice,
      {String datePattern = 'dd/MM/yyyy'}) async {
    final settings = await fetchPdfSettings(datePattern: datePattern);
    final previousBalanceDue = settings.showPreviousBalance
        ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
        : 0.0;
    return generateInvoicePDFWithSettings(
      invoice,
      settings,
      previousBalanceDue: previousBalanceDue,
    );
  }

  static PdfPageFormat pageSizeToFormat(PageSize size) {
    switch (size) {
      case PageSize.a5:
        return PdfPageFormat.a5;
      case PageSize.a6:
        return PdfPageFormat.a6;
      case PageSize.thermal80:
        return PdfPageFormat.roll80;
      case PageSize.thermal58:
        return PdfPageFormat(58 * PdfPageFormat.mm, double.infinity);
      case PageSize.a4:
        return PdfPageFormat.a4;
    }
  }

  static Future<void> _downloadWithPicker(
      BuildContext context, Uint8List pdfBytes, Invoice invoice) async {
    final filename = buildPdfFilename(invoice);
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Invoice PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: Platform.isAndroid ? pdfBytes : null,
    );
    if (savePath == null) return;
    if (!Platform.isAndroid) {
      await File(savePath).writeAsBytes(pdfBytes);
    }
    await OpenFile.open(savePath);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: $savePath'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Future<void> downloadPDF(BuildContext context, Invoice invoice) async {
    try {
      final dateFmt = await BackendServices.settings.getDateFormat();
      final pdf = await generateInvoicePDF(invoice, datePattern: dateFmt.key);
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

  static String buildPdfFilename(Invoice invoice) {
    final rawNumber =
        (invoice.invoiceNumber ?? invoice.id).replaceAll(RegExp(r'^0+'), '');
    final invoiceNumber = rawNumber.isEmpty ? '0' : rawNumber;
    final fullName = invoice.customer.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final date = DateFormat('yyyyMMdd', 'en_US').format(invoice.date);
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
                title: Text(invoice.pdfNumberText('') != null
                    ? '${invoice.invoiceTitle ?? invoice.type} #${invoice.pdfNumberText('')}'
                    : invoice.invoiceTitle ?? invoice.type),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Print',
                    onPressed: () async {
                      final template = await BackendServices.settings.getInvoiceTemplate();
                      if (template == InvoiceTemplate.thermal) {
                        if (!dialogContext.mounted) return;
                        await ThermalPrinterService.printInvoice(
                            dialogContext, invoice);
                      } else {
                        final pageSize =
                            await BackendServices.settings.getPageSize();
                        await Printing.layoutPdf(
                            format: pageSizeToFormat(pageSize),
                            onLayout: (_) async => pdfBytes);
                      }
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
