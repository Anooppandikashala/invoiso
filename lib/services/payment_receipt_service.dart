import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_payment.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PaymentReceiptService {
  // ─── Public entry point ───────────────────────────────────────────────────

  /// Opens the system print/save-as-PDF dialog for the given payment receipt.
  static Future<void> printOrDownload(
    BuildContext context,
    Invoice invoice,
    InvoicePayment payment,
  ) async {
    try {
      final pdf = await _generatePDF(invoice, payment);
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: '${payment.receiptNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating receipt: $e')),
        );
      }
    }
  }

  // ─── PDF generation ───────────────────────────────────────────────────────

  static Future<pw.Document> _generatePDF(
    Invoice invoice,
    InvoicePayment payment,
  ) async {
    final pdf = pw.Document();
    final company = await CompanyInfoService.getCompanyInfo();
    final base64Logo = await SettingsService.getCompanyLogo();
    final logoImage =
        base64Logo != null ? pw.MemoryImage(base64Decode(base64Logo)) : null;
    final sym = invoice.currencySymbol;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => _buildReceiptBody(
          company: company,
          invoice: invoice,
          payment: payment,
          sym: sym,
          logoImage: logoImage,
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _buildReceiptBody({
    required dynamic company,
    required Invoice invoice,
    required InvoicePayment payment,
    required String sym,
    required pw.MemoryImage? logoImage,
  }) {
    const accentColor = PdfColors.indigo800;
    final isPaidInFull = payment.balanceAfter <= 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Header: company info + logo ──────────────────────────────────
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company details
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company?.name ?? '',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  if ((company?.address ?? '').isNotEmpty)
                    pw.Text(company!.address,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.phone ?? '').isNotEmpty)
                    pw.Text(company!.phone,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.email ?? '').isNotEmpty)
                    pw.Text(company!.email,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.gstin ?? '').isNotEmpty)
                    pw.Text('${taxLabel(company?.country)}: ${company!.gstin}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            // Logo
            if (logoImage != null)
              pw.Container(
                width: 70,
                height: 70,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
          ],
        ),

        pw.SizedBox(height: 16),
        pw.Divider(color: accentColor, thickness: 1.5),
        pw.SizedBox(height: 10),

        // ── Title ────────────────────────────────────────────────────────
        pw.Center(
          child: pw.Text(
            'PAYMENT RECEIPT',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 2,
            ),
          ),
        ),

        pw.SizedBox(height: 14),

        // ── Receipt meta: number, invoice, date ───────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _metaRow('Receipt #', payment.receiptNumber),
                  pw.SizedBox(height: 4),
                  _metaRow('Invoice #', invoice.id),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _metaRow('Date', _formatDate(payment.datePaid)),
                  if ((payment.paymentMethod ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _metaRow('Method', payment.paymentMethod!),
                  ],
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 14),

        // ── Bill to ──────────────────────────────────────────────────────
        pw.Text('BILL TO',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
                letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Text(invoice.customer.name,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold)),
        if (invoice.customer.businessName.isNotEmpty)
          pw.Text(invoice.customer.businessName,
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        if (invoice.customer.address.isNotEmpty)
          pw.Text(invoice.customer.address,
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        if (invoice.customer.phone.isNotEmpty)
          pw.Text(invoice.customer.phone,
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        if (invoice.customer.gstin.isNotEmpty)
          pw.Text('${taxLabel(company?.country)}: ${invoice.customer.gstin}',
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),

        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),

        // ── Balance summary table ─────────────────────────────────────────
        pw.Text('BALANCE SUMMARY',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
                letterSpacing: 1)),
        pw.SizedBox(height: 8),

        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              _summaryRow(
                  'Invoice Total', '$sym ${_fmt(invoice.total)}'),
              _summaryRow(
                  'Previously Paid', '$sym ${_fmt(payment.previouslyPaid)}'),
              _summaryRow(
                  'This Payment',
                  '$sym ${_fmt(payment.amountPaid)}',
                  bold: true,
                  highlight: PdfColors.indigo50),
              // Final row: balance due or paid in full
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: isPaidInFull
                      ? PdfColors.green700
                      : PdfColors.orange,
                  borderRadius: const pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isPaidInFull ? 'PAID IN FULL' : 'Balance Due',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white),
                    ),
                    if (!isPaidInFull)
                      pw.Text(
                        '$sym ${_fmt(payment.balanceAfter)}',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Tax covered ──────────────────────────────────────────────────
        if (payment.taxAmountPaid > 0) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Tax covered by this payment: $sym ${_fmt(payment.taxAmountPaid)}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600),
          ),
        ],

        // ── Notes ────────────────────────────────────────────────────────
        if ((payment.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          pw.Text('Notes',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(payment.notes!,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey800)),
        ],

        pw.Spacer(),

        // ── Footer ───────────────────────────────────────────────────────
        pw.Divider(color: PdfColors.grey300),
        pw.Center(
          child: pw.Text(
            'Thank you for your payment!',
            style: pw.TextStyle(
                fontSize: 9,
                color: accentColor,
                fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    );
  }

  // ─── Helper widgets ───────────────────────────────────────────────────────

  static pw.Widget _metaRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, String value,
      {bool bold = false, PdfColor? highlight}) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      color: highlight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(2);

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
