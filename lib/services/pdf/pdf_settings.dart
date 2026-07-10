import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common.dart';
import 'package:invoiso/models/company_info.dart';

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
  final PageSize pageSize;
  final String thermalItemLayout;

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
    required this.pageSize,
    required this.showTotalQuantity,
    required this.pdfTheme,
    this.thermalItemLayout = 'table',
    this.signatureBytes,
    this.signaturePosition = 'left',
  });
}
