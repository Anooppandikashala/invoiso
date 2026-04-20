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
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';

import 'package:invoiso/models/invoice.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../common.dart';

// PDF Generation Service
class PDFService {
  static Future<pw.Document> generateInvoicePDF(Invoice invoice) async
  {
    final pdf = pw.Document();
    final company = await CompanyInfoService.getCompanyInfo();
    final selectedTemplate = await SettingsService.getInvoiceTemplate();
    final currencySymbol = invoice.currencySymbol;
    final rawPrefix = await SettingsService.getSetting(SettingKey.invoicePrefix) ?? 'INV';
    final invoicePrefix = rawPrefix.isNotEmpty ? '$rawPrefix-' : '';
    final showGst = await SettingsService.getShowGstFields();
    final showQuantity = await SettingsService.getShowQuantity();
    final businessType = await SettingsService.getBusinessType();

    // UPI QR settings — use the per-invoice UPI ID; fall back to the default
    // UPI from settings so that invoices created before this feature still
    // show a QR code when the global toggle is on.
    String? effectiveUpiId = invoice.upiId;
    if (effectiveUpiId == null || effectiveUpiId.trim().isEmpty) {
      final upiEntries = await SettingsService.getUpiIds();
      final fallback = upiEntries.where((e) => e.isDefault).firstOrNull
          ?? upiEntries.firstOrNull;
      effectiveUpiId = fallback?.id;
    } else {
      effectiveUpiId = effectiveUpiId.trim();
    }
    final showQrStr = await SettingsService.getSetting(SettingKey.showUpiQr);
    final showUpiQr =
        showQrStr == 'true' && effectiveUpiId != null && effectiveUpiId.isNotEmpty;

    // Bank account — resolve from per-invoice ID, fall back to default.
    BankAccount? effectiveBank;
    final showBankDetails = await SettingsService.getShowBankDetails();
    if (showBankDetails) {
      final bankAccounts = await SettingsService.getBankAccounts();
      final savedId = invoice.bankAccountId;
      if (savedId != null && savedId.isNotEmpty) {
        effectiveBank = bankAccounts
            .where((e) => e.accountNumber == savedId)
            .firstOrNull;
      }
      effectiveBank ??= bankAccounts.where((e) => e.isDefault).firstOrNull
          ?? bankAccounts.firstOrNull;
    }

    switch (selectedTemplate) {
      case InvoiceTemplate.classic:
        pdf.addPage(await _buildClassicTemplate(
          invoice, company, currencySymbol, invoicePrefix,
          upiId: effectiveUpiId, showUpiQr: showUpiQr, showGst: showGst,
          showQuantity: showQuantity, businessType: businessType,
          bankAccount: effectiveBank,
        ));
        break;
      case InvoiceTemplate.modern:
        pdf.addPage(await _buildModernTemplate(
          invoice, company, currencySymbol, invoicePrefix,
          upiId: effectiveUpiId, showUpiQr: showUpiQr, showGst: showGst,
          showQuantity: showQuantity, businessType: businessType,
          bankAccount: effectiveBank,
        ));
        break;
      case InvoiceTemplate.minimal:
        pdf.addPage(await _buildMinimalTemplate(
          invoice, company, currencySymbol, invoicePrefix,
          upiId: effectiveUpiId, showUpiQr: showUpiQr, showGst: showGst,
          showQuantity: showQuantity, businessType: businessType,
          bankAccount: effectiveBank,
        ));
        break;
    }

    return pdf;
  }

  static Future<pw.MultiPage> _buildClassicTemplate(
    Invoice invoice, CompanyInfo? company, String currencySymbol, String invoicePrefix, {
    String? upiId, bool showUpiQr = false, bool showGst = true,
    bool showQuantity = true, BusinessType businessType = BusinessType.both,
    BankAccount? bankAccount,
  }) async
  {
    final accentColor = PdfColors.indigo900; // Use a strong accent color
    final LogoPosition logoPosition = await SettingsService.getLogoPosition();
    final logoSizePx = _logoSizePx(await SettingsService.getLogoSize());
    final base64Logo = await SettingsService.getCompanyLogo();
    final logoImage = base64Logo != null ? pw.MemoryImage(base64Decode(base64Logo)) : null;
    final String thankyouNote = await SettingsService.getSetting(SettingKey.thankYouNote) ?? DefaultValues.thankYouNote;

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Text(
          "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        // 1. Header with Logo and Company Details
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null && logoPosition == LogoPosition.left) _buildCompanyLogo(logoImage, size: logoSizePx),
            // Company Info Block
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: accentColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(company?.address ?? '', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Phone: ${company?.phone ?? ''}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Email: ${company?.email ?? ''}', style: const pw.TextStyle(fontSize: 10)),
                  if ((company?.website ?? '').isNotEmpty) pw.Text('Web: ${company!.website}', style: const pw.TextStyle(fontSize: 10)),
                  if (showGst) pw.Text('${taxLabel(company?.country)}: ${company?.gstin ?? ''}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ),
            if (logoImage != null && logoPosition == LogoPosition.right) _buildCompanyLogo(logoImage, size: logoSizePx),
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
                pw.Text("Invoice #: $invoicePrefix${invoice.id}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text("Date: ${_formatDate(invoice.date)}", style: const pw.TextStyle(fontSize: 10)),
                if (invoice.dueDate != null)
                  pw.Text("Due Date: ${_formatDate(invoice.dueDate!)}", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),

        // 3. Customer Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              color: PdfColors.grey200,
              child: pw.Text("BILL TO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 5),
                    pw.Text(invoice.customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    if (invoice.customer.businessName.isNotEmpty)
                      pw.Text(invoice.customer.businessName, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(invoice.customer.address, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(invoice.customer.phone, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(invoice.customer.email, style: const pw.TextStyle(fontSize: 10)),
                    if (showGst) pw.Text("${taxLabel(company?.country)}: ${invoice.customer.gstin}", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey600)),
                  ]
              )
            )
          ],
        ),

        pw.SizedBox(height: 25),

        // 4. Items Table
        _buildInvoiceTable(invoice, headerColor: accentColor, textColor: PdfColors.white, showGst: showGst, showQuantity: showQuantity, businessType: businessType),

        pw.SizedBox(height: 20),

        // 5. Totals, Notes and optional UPI QR
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildAdditionalNotes(invoice),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildEnhancedTotals(invoice, PdfColors.grey200, PdfColors.black, accentColor, currencySymbol),
                if (showUpiQr && upiId != null) ...[
                  pw.SizedBox(height: 12),
                  _buildUpiQrSection(
                    upiId: upiId,
                    companyName: company?.name ?? '',
                    amount: invoice.total,
                    currencyCode: invoice.currencyCode,
                    invoiceId: invoice.id,
                    accentColor: accentColor,
                  ),
                ],
                if (bankAccount != null) ...[
                  pw.SizedBox(height: 12),
                  _buildBankDetailsSection(bankAccount: bankAccount, accentColor: accentColor),
                ],
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text(thankyouNote,
              style: pw.TextStyle(fontSize: 14, color: accentColor, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static Future<pw.MultiPage> _buildMinimalTemplate(
    Invoice invoice, CompanyInfo? company, String currencySymbol, String invoicePrefix, {
    String? upiId, bool showUpiQr = false, bool showGst = true,
    bool showQuantity = true, BusinessType businessType = BusinessType.both,
    BankAccount? bankAccount,
  }) async
  {
    final accentColor = PdfColors.grey700; // Use a strong, neutral accent
    final LogoPosition logoPosition = await SettingsService.getLogoPosition();
    final logoSizePx = _logoSizePx(await SettingsService.getLogoSize());
    final base64Logo = await SettingsService.getCompanyLogo();
    final logoImage = base64Logo != null ? pw.MemoryImage(base64Decode(base64Logo)) : null;
    final String thankyouNote = await SettingsService.getSetting(SettingKey.thankYouNote) ?? "";

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(45), // Increased margin for more whitespace
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 20),
        child: pw.Text(
          "Page ${context.pageNumber} of ${context.pagesCount}",
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        // 1. Header (Invoice Title & Numbers)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if(logoImage != null && logoPosition == LogoPosition.left) _buildCompanyLogo(logoImage, size: logoSizePx),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Invoice #", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
                pw.Text("$invoicePrefix${invoice.id}", style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 5),
                pw.Text("DATE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
                pw.Text(_formatDate(invoice.date), style: const pw.TextStyle(fontSize: 12)),
                if (invoice.dueDate != null) ...[
                  pw.SizedBox(height: 5),
                  pw.Text("DUE DATE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
                  pw.Text(_formatDate(invoice.dueDate!), style: const pw.TextStyle(fontSize: 12)),
                ],
              ],
            ),
            if(logoImage != null && logoPosition == LogoPosition.right) _buildCompanyLogo(logoImage, size: logoSizePx),
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
                pw.Text("FROM", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentColor)),
                pw.SizedBox(height: 5),
                pw.Text(company?.name ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(company?.address ?? '', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(company?.phone ?? '', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(company?.email ?? '', style: const pw.TextStyle(fontSize: 10)),
                if ((company?.website ?? '').isNotEmpty) pw.Text(company!.website, style: const pw.TextStyle(fontSize: 10)),
                if (showGst) pw.Text("${taxLabel(company?.country)}: ${company?.gstin ?? ''}",style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9)),
              ],
            ),

            // BILL TO (Customer Info)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("BILL TO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentColor)),
                pw.SizedBox(height: 5),
                pw.Text(invoice.customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                if (invoice.customer.businessName.isNotEmpty)
                  pw.Text(invoice.customer.businessName, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.address, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.phone, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.email, style: const pw.TextStyle(fontSize: 10)),
                if (showGst) pw.Text("${taxLabel(company?.country)}: ${invoice.customer.gstin}",style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 30),

        // 3. Table (Clean, no external borders)
        _buildInvoiceTable(invoice, headerColor: PdfColors.grey100, textColor: PdfColors.black, showGst: showGst, showQuantity: showQuantity, businessType: businessType),

        pw.SizedBox(height: 20),

        // 4. Notes + Totals + optional UPI QR
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildAdditionalNotes(invoice),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildEnhancedTotals(invoice, PdfColors.grey200, PdfColors.black, accentColor, currencySymbol),
                  if (showUpiQr && upiId != null) ...[
                    pw.SizedBox(height: 12),
                    _buildUpiQrSection(
                      upiId: upiId,
                      companyName: company?.name ?? '',
                      amount: invoice.total,
                      currencyCode: invoice.currencyCode,
                      invoiceId: invoice.id,
                      accentColor: accentColor,
                    ),
                  ],
                  if (bankAccount != null) ...[
                    pw.SizedBox(height: 12),
                    _buildBankDetailsSection(bankAccount: bankAccount, accentColor: accentColor),
                  ],
                ],
              ),
            ]
        ),

        pw.SizedBox(height: 30),

        // 5. Footer
        pw.Center(
          child: pw.Text(thankyouNote,
              style: pw.TextStyle(color: accentColor, fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static Future<pw.MultiPage> _buildModernTemplate(
    Invoice invoice, CompanyInfo? company, String currencySymbol, String invoicePrefix, {
    String? upiId, bool showUpiQr = false, bool showGst = true,
    bool showQuantity = true, BusinessType businessType = BusinessType.both,
    BankAccount? bankAccount,
  }) async
  {
    final accentColor = PdfColors.blue600;
    final LogoPosition logoPosition = await SettingsService.getLogoPosition();
    final logoSizePx = _logoSizePx(await SettingsService.getLogoSize());
    final base64Logo = await SettingsService.getCompanyLogo();
    final logoImage = base64Logo != null ? pw.MemoryImage(base64Decode(base64Logo)) : null;
    final String thankyouNote = await SettingsService.getSetting(SettingKey.thankYouNote) ?? "";

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          "Page ${context.pageNumber} of ${context.pagesCount} - Generated by Invoiso",
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
              if (logoImage != null && logoPosition == LogoPosition.left) _buildCompanyLogo(logoImage, size: logoSizePx),
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
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    pw.Text('Phone: ${company?.phone ?? ''}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    pw.Text('Email: ${company?.email ?? ''}',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    if ((company?.website ?? '').isNotEmpty) pw.Text(company!.website,
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    if (showGst) pw.Text('${taxLabel(company?.country)}: ${company?.gstin ?? ''}',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 10)),
                  ],
                ),
              ),
              // Logo
              if (logoImage != null && logoPosition == LogoPosition.right) _buildCompanyLogo(logoImage, size: logoSizePx),
            ],
          ),
        ),

        // 2. Invoice Title and Number/Date
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 10, 30, 10), // Padding for this section
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
                  pw.Text("Invoice #: $invoicePrefix${invoice.id}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text("Date: ${_formatDate(invoice.date)}", style: const pw.TextStyle(fontSize: 10)),
                  if (invoice.dueDate != null)
                    pw.Text("Due Date: ${_formatDate(invoice.dueDate!)}", style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        // 3. Bill To section
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 30),
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
                pw.Text(invoice.customer.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (invoice.customer.businessName.isNotEmpty)
                  pw.Text(invoice.customer.businessName, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.address, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.phone, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.email, style: const pw.TextStyle(fontSize: 10)),
                if (showGst) pw.Text("${taxLabel(company?.country)}: ${invoice.customer.gstin}",
                    style: pw.TextStyle(
                        fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 25),

        // 4. Table Section
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 30),
          child: _buildInvoiceTable(invoice, headerColor: accentColor, textColor: PdfColors.white, showGst: showGst, showQuantity: showQuantity, businessType: businessType),
        ),

        pw.SizedBox(height: 25),

        // 5. Notes + Totals + optional UPI QR
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 30),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildAdditionalNotes(invoice),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildEnhancedTotals(invoice, PdfColors.blue200, PdfColors.black, accentColor, currencySymbol),
                  if (showUpiQr && upiId != null) ...[
                    pw.SizedBox(height: 12),
                    _buildUpiQrSection(
                      upiId: upiId,
                      companyName: company?.name ?? '',
                      amount: invoice.total,
                      currencyCode: invoice.currencyCode,
                      invoiceId: invoice.id,
                      accentColor: accentColor,
                    ),
                  ],
                  if (bankAccount != null) ...[
                    pw.SizedBox(height: 12),
                    _buildBankDetailsSection(bankAccount: bankAccount, accentColor: accentColor),
                  ],
                ],
              ),
            ],
          ),
        ),

        pw.Spacer(),

        // 6. Footer thank-you
        pw.Container(
          color: accentColor,
          padding: const pw.EdgeInsets.all(18),
          child: pw.Center(
            child: pw.Text(thankyouNote,
                style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
          ),
        ),
      ],
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
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
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
          if (bankAccount.label.isNotEmpty) row('Account Name', bankAccount.label),
          if (bankAccount.bankName.isNotEmpty) row('Bank', bankAccount.bankName),
          row('Account No.', bankAccount.accountNumber),
          if (bankAccount.ifscCode.isNotEmpty) row('IFSC Code', bankAccount.ifscCode),
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
    final upiUri =
        'upi://pay?pa=$upiId&pn=$encodedName'
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
      case 'small':  return 60;
      case 'large':  return 120;
      default:       return 90;
    }
  }

  // Enhanced totals with highlighted total - MODIFIED
  static pw.Widget _buildEnhancedTotals(Invoice invoice, PdfColor accentRowColor, PdfColor primaryColor, PdfColor totalHighlightColor, String currencySymbol) {
    final hasPaid = invoice.amountPaid > 0;
    final isPaidInFull = invoice.outstandingBalance <= 0;

    return pw.Container(
      width: 250,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _totalRow("Subtotal", "$currencySymbol ${invoice.subtotal.toStringAsFixed(2)}"),
          if (invoice.taxMode != TaxMode.none)
            _totalRow(
                _taxLabel(invoice),
                "$currencySymbol ${invoice.tax.toStringAsFixed(2)}"),
          ...invoice.additionalCosts.map((c) => _totalRow(
                c.label.isEmpty ? 'Extra Cost' : c.label,
                "$currencySymbol ${c.amount.toStringAsFixed(2)}",
              )),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: totalHighlightColor,
              borderRadius: hasPaid
                  ? pw.BorderRadius.zero
                  : const pw.BorderRadius.vertical(bottom: pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total",
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text("$currencySymbol ${invoice.total.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ],
            ),
          ),
          if (hasPaid) ...[
            _totalRow(
              "Amount Paid",
              "$currencySymbol ${invoice.amountPaid.toStringAsFixed(2)}",
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: isPaidInFull ? PdfColors.green700 : PdfColors.orange,
                borderRadius: const pw.BorderRadius.vertical(bottom: pw.Radius.circular(5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    isPaidInFull ? "PAID IN FULL" : "Amount Due",
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white),
                  ),
                  if (!isPaidInFull)
                    pw.Text(
                      "$currencySymbol ${invoice.outstandingBalance.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                          fontSize: 12,
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

// Total Row helper - UNCHANGED
  static pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // Build Invoice Table - MODIFIED
  static pw.Widget _buildInvoiceTable(Invoice invoice, {PdfColor headerColor = PdfColors.grey200, PdfColor textColor = PdfColors.black, bool showGst = true, bool showQuantity = true, BusinessType businessType = BusinessType.both})
  {
    final bool showItemTax = invoice.taxMode == TaxMode.perItem;
    final String priceHeader = showQuantity ? 'Price' : 'Rate';

    // Build column widths dynamically based on which columns are visible
    int col = 0;
    final Map<int, pw.TableColumnWidth> colWidths = {
      col++: const pw.FlexColumnWidth(1),    // Sl No
      col++: const pw.FlexColumnWidth(3),    // Item Name
      if (showGst) col: const pw.FlexColumnWidth(2),  // HSN Code
    };
    if (showGst) col++;
    if (showQuantity) colWidths[col++] = const pw.FlexColumnWidth(1);    // Qty
    colWidths[col++] = const pw.FlexColumnWidth(1.5);  // Price/Rate
    if (showItemTax) colWidths[col++] = const pw.FlexColumnWidth(1); // Tax %
    colWidths[col++] = const pw.FlexColumnWidth(1.5);  // Discount
    colWidths[col++] = const pw.FlexColumnWidth(1.5);  // Total

    return pw.Table(
      columnWidths: colWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _buildTableCell('Sl No', isHeader: true, textColor: textColor),
            _buildTableCell('Item Name', isHeader: true, textColor: textColor),
            if (showGst) _buildTableCell('HSN Code', isHeader: true, textColor: textColor),
            if (showQuantity) _buildTableCell(invoice.quantityLabel?.isNotEmpty == true ? invoice.quantityLabel! : 'Qty', isHeader: true, textColor: textColor),
            _buildTableCell(priceHeader, isHeader: true, textColor: textColor),
            if (showItemTax) _buildTableCell('Tax %', isHeader: true, textColor: textColor),
            _buildTableCell('Discount', isHeader: true, textColor: textColor),
            _buildTableCell('Total', isHeader: true, textColor: textColor),
          ],
        ),
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: index % 2 == 0 ? const pw.BoxDecoration(color: PdfColors.white) : const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              _buildTableCell('${index + 1}'),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.product.name, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              if (showGst) _buildTableCell(item.product.hsncode),
              if (showQuantity) _buildTableCell(item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toString()),
              _buildTableCell(item.effectivePrice.toStringAsFixed(2)),
              if (showItemTax) _buildTableCell('${item.product.tax_rate}%'),
              _buildTableCell(item.discount.toStringAsFixed(2)),
              _buildTableCell(item.total.toStringAsFixed(2)),
            ],
          );
        }),
        pw.TableRow(
          children: [
            pw.Container(height: 1, color: PdfColors.grey400),
            pw.Container(height: 1, color: PdfColors.grey400),
            if (showGst) pw.Container(height: 1, color: PdfColors.grey400),
            if (showQuantity) pw.Container(height: 1, color: PdfColors.grey400),
            pw.Container(height: 1, color: PdfColors.grey400),
            if (showItemTax) pw.Container(height: 1, color: PdfColors.grey400),
            pw.Container(height: 1, color: PdfColors.grey400),
            pw.Container(height: 1, color: PdfColors.grey400),
          ],
        ),
      ],
    );
  }

// Build Table Cell - MODIFIED
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor textColor = PdfColors.black})
  {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8), // Increased vertical padding
      child: pw.Text(
        text,
        textAlign: isHeader ? pw.TextAlign.left : pw.TextAlign.left,
        style: pw.TextStyle(
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: 10,
            color: textColor // Use the provided color for header text
        ),
      ),
    );
  }

  static pw.Widget _buildAdditionalNotes(Invoice invoice)
  {
    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(invoice.notes ?? '' ,
        style: pw.TextStyle(fontStyle: pw.FontStyle.italic,
            fontWeight: pw.FontWeight.normal,
            fontSize: 10,
            color: PdfColors.grey700),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String buildPdfFilename(Invoice invoice) {
    final rawNumber = invoice.id.replaceAll(RegExp(r'^0+'), '');
    final invoiceNumber = rawNumber.isEmpty ? '0' : rawNumber;
    final fullName = invoice.customer.name.trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final date = DateFormat('yyyyMMdd').format(invoice.date);
    return 'inv-$invoiceNumber-$fullName-$date.pdf';
  }

  static Future<void> showCenteredPDFViewer(BuildContext context, Uint8List pdfBytes, Invoice invoice) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.sizeOf(dialogContext).width * 0.75,
          height: MediaQuery.sizeOf(dialogContext).height * 0.8,
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: Text('Invoice #${invoice.id}'),
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
                    onPressed: () => _downloadWithPicker(context, pdfBytes, invoice),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              Expanded(
                child: SfPdfViewer.memory(pdfBytes),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
