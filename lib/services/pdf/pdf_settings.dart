import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common/common.dart';
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
  final bool showAliasName;
  final bool showDescription;
  final bool descriptionNewLine;
  final BusinessType businessType;
  final List<UpiEntry> upiEntries;
  final String? showQrStr;
  final bool showBankDetails;
  final bool showPhone;
  final bool showEmail;
  final bool showCompanyName;
  final bool showPan;
  final bool showFssai;
  final bool showWebsite;
  final bool showAddress;
  final bool showLogo;
  final bool showCustomerBusinessName;
  final bool showCustomerAddress;
  final bool showCustomerPhone;
  final bool showCustomerEmail;
  final bool showCustomerGstin;
  final bool showTimeInPdf;
  final String pdfTimeFormat;
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
  final double signatureSizePx;
  final bool showPreviousBalance;
  final PdfPageFormat pageFormat;
  final bool showTotalQuantity;
  final pw.ThemeData pdfTheme;
  final PageSize pageSize;
  final String thermalItemLayout;
  final String thermalCompanyNameSize;
  final Uint8List? watermarkBytes;
  final double watermarkOpacity;
  final bool showCgstSgst;
  final bool showRoundOff;
  final bool showLeadingZeros;
  final bool showSlNo;
  final bool landscape;

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
    required this.showCgstSgst,
    this.thermalItemLayout = 'table',
    this.thermalCompanyNameSize = 'medium',
    this.signatureBytes,
    this.signaturePosition = 'left',
    this.signatureSizePx = 50,
    this.showAliasName = false,
    this.showDescription = false,
    this.descriptionNewLine = false,
    this.watermarkBytes,
    this.watermarkOpacity = 0.12,
    this.showRoundOff = false,
    this.showPhone = true,
    this.showEmail = true,
    this.showCompanyName = true,
    this.showPan = true,
    this.showFssai = true,
    this.showWebsite = true,
    this.showAddress = true,
    this.showLogo = true,
    this.showCustomerBusinessName = true,
    this.showCustomerAddress = true,
    this.showCustomerPhone = true,
    this.showCustomerEmail = true,
    this.showCustomerGstin = true,
    this.showTimeInPdf = true,
    this.pdfTimeFormat = '24',
    this.showLeadingZeros = true,
    this.showSlNo = true,
    this.landscape = false,
  });
}
