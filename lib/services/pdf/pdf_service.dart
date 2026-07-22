import 'dart:convert';
import 'package:flutter/services.dart';
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
import 'package:invoiso/common.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf_font_service.dart';
import 'package:invoiso/services/thermal_printer_service.dart';

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
      showPreviousBalance: results[20] as bool,
      pageFormat: pageSizeToFormat(pageSize),
      pageSize: pageSize,
      showTotalQuantity: results[22] as bool,
      pdfTheme: pdfTheme,
      thermalItemLayout: (results[23] as String?) ?? 'table',
      showAliasName: (results[24] as String?) == 'true',
    );
  }

  /// Build a PDF document using pre-fetched settings — no DB reads.
  /// Use this in batch exports to avoid redundant settings fetches per invoice.
  static pw.Document generateInvoicePDFWithSettings(
      Invoice invoice, PdfGenerationSettings s,
      {double previousBalanceDue = 0.0, int copies = 1}) {
    final pdf = pw.Document(theme: s.pdfTheme);
    late final pw.Page page;
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
        page = buildClassicTemplate(
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
          showAliasName: s.showAliasName,
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
          copies: copies,
        );
      case InvoiceTemplate.modern:
        page = buildModernTemplate(
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
          showAliasName: s.showAliasName,
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
          copies: copies,
        );
      case InvoiceTemplate.minimal:
        page = buildMinimalTemplate(
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
          showAliasName: s.showAliasName,
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
          copies: copies,
        );
      case InvoiceTemplate.executive:
        page = buildExecutiveTemplate(
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
          showAliasName: s.showAliasName,
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
          copies: copies,
        );
      case InvoiceTemplate.compact:
        page = buildCompactTemplate(
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
          showAliasName: s.showAliasName,
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
          copies: copies,
        );
      case InvoiceTemplate.thermal:
        page = buildThermalTemplate(
          invoice,
          s.company,
          currencySymbol,
          s.invoicePrefix,
          showGst: s.showGst,
          showQuantity: s.showQuantity,
          showDiscount: s.showDiscount,
          showAliasName: s.showAliasName,
          datePattern: s.datePattern,
          thankYouNote: s.thankYouNote,
          showFooterBranding: s.showFooterBranding,
          themeColor: s.themeColor,
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pageSize:s.pageSize,
          pdfTheme: pdfTheme,
          itemLayout: s.thermalItemLayout,
        );
      case InvoiceTemplate.gridClassic:
        page = buildGridClassicTemplate(
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
          showAliasName: s.showAliasName,
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
          previousBalanceDue: effectivePreviousBalance,
          pageFormat: s.pageFormat,
          pdfTheme: pdfTheme,
          copies: copies,
          logoPosition: s.logoPosition
        );
    }
    for (var i = 0; i < copies; i++) {
      pdf.addPage(page);
    }
    return pdf;
  }

  static Future<pw.Document> generateInvoicePDF(Invoice invoice,
      {String datePattern = 'dd/MM/yyyy', int copies = 1}) async {
    final settings = await fetchPdfSettings(datePattern: datePattern);
    final previousBalanceDue = settings.showPreviousBalance
        ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
        : 0.0;
    return generateInvoicePDFWithSettings(
      invoice,
      settings,
      previousBalanceDue: previousBalanceDue,
      copies: copies,
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
    );
    if (savePath == null) return;
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

  static String buildPdfFilename(Invoice invoice) {
    final rawNumber =
        (invoice.invoiceNumber ?? invoice.id).replaceAll(RegExp(r'^0+'), '');
    final invoiceNumber = rawNumber.isEmpty ? '0' : rawNumber;
    final fullName = invoice.customer.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final date = DateFormat('yyyyMMdd').format(invoice.date);
    return 'inv-$invoiceNumber-$fullName-$date.pdf';
  }

  /// Prompts for number of copies (workaround for the Windows print dialog
  /// burying the copies field under Printer Properties > Advanced).
  /// Returns null if the user cancels.
  static Future<int?> askPrintCopies(BuildContext context) {
    int selectedCopies = 1;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Number of copies'),
          content: DropdownButtonFormField<int>(
            value: selectedCopies,
            decoration: const InputDecoration(
              labelText: 'Copies',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              DefaultValues.maxNumberOfPDFCopies,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}'),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedCopies = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, selectedCopies),
              child: const Text('Print'),
            ),
          ],
        ),
      ),
    );
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
                title: Text('${invoice.type} #${invoice.invoiceNumber ?? invoice.id}'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Print',
                    onPressed: () async {
                      final template = await BackendServices.settings.getInvoiceTemplate();
                      int copies = 1;
                      if (template != InvoiceTemplate.thermal) {
                        if (!dialogContext.mounted) return;
                        final picked = await askPrintCopies(dialogContext);
                        if (picked == null) return;
                        copies = picked;
                      }
                      // Close the preview before printing: on Windows, the
                      // native print dialog opening while SfPdfViewer's
                      // texture is still live crashes the app on later close.
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      if (template == InvoiceTemplate.thermal) {
                        if (!context.mounted) return;
                        await ThermalPrinterService.printInvoice(
                            context, invoice);
                      } else {
                        final dateFmt = await BackendServices.settings.getDateFormat();
                        final pdf = await generateInvoicePDF(invoice,
                            datePattern: dateFmt.key, copies: copies);
                        await Printing.layoutPdf(
                            onLayout: (_) async => pdf.save());
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
