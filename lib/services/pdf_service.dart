import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
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

    switch (selectedTemplate) {
      case InvoiceTemplate.classic:
        pdf.addPage(await _buildClassicTemplate(invoice, company));
        break;
      case InvoiceTemplate.modern:
        pdf.addPage(await _buildModernTemplate(invoice, company));
        break;
      case InvoiceTemplate.minimal:
        pdf.addPage(await _buildMinimalTemplate(invoice, company));
        break;
    }

    return pdf;
  }

  static Future<pw.MultiPage> _buildClassicTemplate(Invoice invoice, CompanyInfo? company) async
  {
    final accentColor = PdfColors.indigo900; // Use a strong accent color
    final LogoPosition logoPosition = await SettingsService.getLogoPosition(); DefaultValues.logoPosition;//await SettingsService.getLogoPosition(); // "left" or "right"
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
            if (logoImage != null && logoPosition == LogoPosition.left) _buildCompanyLogo(logoImage),
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
                  pw.Text('GSTIN: ${company?.gstin ?? ''}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ),
            if (logoImage != null && logoPosition == LogoPosition.right) _buildCompanyLogo(logoImage),
          ],
        ),

        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1, color: accentColor),
        pw.SizedBox(height: 10),

        // 2. Invoice Title and Number/Date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            // pw.Text('INVOICE',
            //     style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: accentColor)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Invoice #: ${invoice.id}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text("Date: ${_formatDate(invoice.date)}", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),

        // pw.SizedBox(height: 20),

        // 3. Customer Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              color: PdfColors.grey200, // Background for the Bill To header
              child: pw.Text("BILL TO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 5),
                    pw.Text(invoice.customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text(invoice.customer.address, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(invoice.customer.phone, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(invoice.customer.email, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text("GSTIN: ${invoice.customer.gstin}", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey600)),
                  ]
              )
            )
          ],
        ),

        pw.SizedBox(height: 25),

        // 4. Items Table
        _buildInvoiceTable(invoice, headerColor: accentColor, textColor: PdfColors.white), // Using accent color for table header

        pw.SizedBox(height: 20),

        // 5. Totals and Notes
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildAdditionalNotes(invoice),
            _buildEnhancedTotals(invoice, PdfColors.grey200, PdfColors.black, accentColor), // Totals with accent
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

  static Future<pw.MultiPage> _buildMinimalTemplate(Invoice invoice, CompanyInfo? company) async
  {
    final accentColor = PdfColors.grey700; // Use a strong, neutral accent
    final LogoPosition logoPosition = await SettingsService.getLogoPosition();//await SettingsService.getLogoPosition(); // "left" or "right"
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
            if(logoImage != null && logoPosition == LogoPosition.left) _buildCompanyLogo(logoImage),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Invoice #", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
                pw.Text(invoice.id, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 5),
                pw.Text("DATE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: accentColor)),
                pw.Text(_formatDate(invoice.date), style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            if(logoImage != null && logoPosition == LogoPosition.right) _buildCompanyLogo(logoImage),
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
                pw.Text("GSTIN: ${company?.gstin ?? ''}",style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9)),
              ],
            ),

            // BILL TO (Customer Info)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end, // Align customer info to the right
              children: [
                pw.Text("BILL TO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: accentColor)),
                pw.SizedBox(height: 5),
                pw.Text(invoice.customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(invoice.customer.address, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.phone, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.email, style: const pw.TextStyle(fontSize: 10)),
                pw.Text("GSTIN: ${invoice.customer.gstin}",style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 30),

        // 3. Table (Clean, no external borders)
        _buildInvoiceTable(invoice, headerColor: PdfColors.grey100, textColor: PdfColors.black),

        pw.SizedBox(height: 20),

        // 4. Notes + Totals
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildAdditionalNotes(invoice),
              // Use the enhanced totals widget for a professional summary
              _buildEnhancedTotals(invoice, PdfColors.grey200, PdfColors.black, accentColor),
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

  static Future<pw.MultiPage> _buildModernTemplate(Invoice invoice, CompanyInfo? company) async
  {
    final accentColor = PdfColors.blue600;
    final LogoPosition logoPosition = await SettingsService.getLogoPosition();//await SettingsService.getLogoPosition(); // "left" or "right"
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
              if (logoImage != null && logoPosition == LogoPosition.left) _buildCompanyLogo(logoImage),
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
                    pw.Text('GSTIN: ${company?.gstin ?? ''}',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 10)),
                  ],
                ),
              ),
              // Logo
              if (logoImage != null && logoPosition == LogoPosition.right) _buildCompanyLogo(logoImage),
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
                  pw.Text("Invoice #: ${invoice.id}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text("Date: ${_formatDate(invoice.date)}", style: const pw.TextStyle(fontSize: 10)),
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
                pw.Text(invoice.customer.address, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.phone, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(invoice.customer.email, style: const pw.TextStyle(fontSize: 10)),
                pw.Text("GSTIN: ${invoice.customer.gstin}",
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
          child: _buildInvoiceTable(invoice, headerColor: accentColor, textColor: PdfColors.white),
        ),

        pw.SizedBox(height: 25),

        // 5. Notes + Totals
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 30),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildAdditionalNotes(invoice),
              // Updated totals box with strong accent color for total due
              _buildEnhancedTotals(invoice, PdfColors.blue200, PdfColors.black, accentColor),
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

  // Company Logo Builder
  static pw.Widget _buildCompanyLogo(pw.MemoryImage image) {
    return pw.Container(
      width: 80,
      height: 80,
      child: pw.Image(image, fit: pw.BoxFit.contain),
    );
  }

  // Enhanced totals with highlighted total - MODIFIED
  static pw.Widget _buildEnhancedTotals(Invoice invoice, PdfColor accentRowColor, PdfColor primaryColor, PdfColor totalHighlightColor) {
    return pw.Container(
      width: 250, // Slightly wider total box
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _totalRow("Subtotal", "Rs ${invoice.subtotal.toStringAsFixed(2)}"),
          _totalRow(
              "Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%)",
              "Rs ${invoice.tax.toStringAsFixed(2)}"),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              // Use totalHighlightColor for the total row background
              color: totalHighlightColor,
              borderRadius: const pw.BorderRadius.vertical(bottom: pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Due", // Changed "Total" to "Total Due"
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)), // White text on colored background
                pw.Text("Rs ${invoice.total.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
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
  static pw.Widget _buildInvoiceTable(Invoice invoice, {PdfColor headerColor = PdfColors.grey200, PdfColor textColor = PdfColors.black})
  {
    return pw.Table(
      // Removed external border for a cleaner look
      // border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _buildTableCell('Sl No', isHeader: true, textColor: textColor),
            _buildTableCell('Item Name', isHeader: true, textColor: textColor),
            _buildTableCell('HSN Code', isHeader: true, textColor: textColor),
            _buildTableCell('Qty', isHeader: true, textColor: textColor),
            _buildTableCell('Price', isHeader: true, textColor: textColor),
            _buildTableCell('Discount', isHeader: true, textColor: textColor),
            _buildTableCell('Total', isHeader: true, textColor: textColor),
          ],
        ),
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            decoration: index % 2 == 0 ? const pw.BoxDecoration(color: PdfColors.white) : const pw.BoxDecoration(color: PdfColors.grey100), // Zebra striping
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell(item.product.name),
              _buildTableCell(item.product.hsncode),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell(item.product.price.toStringAsFixed(2)),
              _buildTableCell(item.discount.toStringAsFixed(2)),
              _buildTableCell(item.total.toStringAsFixed(2)),
            ],
          );
        }),
        // Add a bottom line for professional finish
        pw.TableRow(
            children: [
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.Container(height: 1, color: PdfColors.grey400),
            ]
        )
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
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
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

  static Future<void> showCenteredPDFViewer(BuildContext context, Uint8List pdfBytes, String invoiceId) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width*0.75,  // Adjust width for desktop
          height: MediaQuery.sizeOf(context).height*0.8, // Adjust height for desktop
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: Text('Invoice #$invoiceId'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
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
