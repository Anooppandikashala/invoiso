import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/refund.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/services/pdf/pdf_font_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Single-page "REFUND VOUCHER" — the money-out mirror of a payment receipt.
/// [creditNote] is the `Invoice` row with `type == 'Credit Note'`.
class RefundReceiptService {
  static Future<void> printOrDownload(
    BuildContext context,
    Invoice creditNote,
    Refund refund, {
    double remainingCredit = 0,
  }) async {
    try {
      final pdf = await _generate(creditNote, refund, remainingCredit);
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: '${refund.receiptNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating refund voucher: $e')),
        );
      }
    }
  }

  static Future<pw.Document> _generate(
    Invoice cn,
    Refund refund,
    double remainingCredit,
  ) async {
    final pdfTheme = await PdfFontService.loadTheme();
    final pdf = pw.Document(theme: pdfTheme);
    final company = await BackendServices.companyInfo.getCompanyInfo();
    final base64Logo = await BackendServices.settings.getCompanyLogo();
    final logoImage =
        base64Logo != null ? pw.MemoryImage(base64Decode(base64Logo)) : null;
    final sym = cn.currencySymbol;
    final dateFmt = (await BackendServices.settings.getDateFormat()).key;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pdfTheme,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => _body(
          company: company,
          cn: cn,
          refund: refund,
          remainingCredit: remainingCredit,
          sym: sym,
          logoImage: logoImage,
          dateFmt: dateFmt,
        ),
      ),
    );
    return pdf;
  }

  static pw.Widget _body({
    required dynamic company,
    required Invoice cn,
    required Refund refund,
    required double remainingCredit,
    required String sym,
    required pw.MemoryImage? logoImage,
    required String dateFmt,
  }) {
    const accent = PdfColors.indigo800;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(company?.name ?? '',
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: accent)),
                  if ((company?.address ?? '').isNotEmpty)
                    pw.Text(company!.address,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.phone ?? '').isNotEmpty)
                    pw.Text(company!.phone,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  if ((company?.gstin ?? '').isNotEmpty)
                    pw.Text('${taxLabel(company?.country)}: ${company!.gstin}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            if (logoImage != null)
              pw.Container(
                  width: 70,
                  height: 70,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: accent, thickness: 1.5),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text('REFUND VOUCHER',
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                  letterSpacing: 2)),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _meta('Voucher #', refund.receiptNumber),
                  pw.SizedBox(height: 4),
                  _meta('Credit Note #', refund.creditNoteNumber),
                  if ((cn.originalInvoiceNumber ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _meta('Against Invoice', cn.originalInvoiceNumber!),
                  ],
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _meta('Date',
                      DateFormat(dateFmt, 'en_US').format(refund.dateRefunded)),
                  if ((refund.refundMethod ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _meta('Method', refund.refundMethod!),
                  ],
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text('PAID TO',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
                letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Text(cn.customer.name,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        if (cn.customer.address.isNotEmpty)
          pw.Text(cn.customer.address,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Text('REFUND SUMMARY',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
                letterSpacing: 1)),
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(
            children: [
              _row('Credit Note Total', '$sym ${_f(cn.total)}'),
              if (refund.taxAmount > 0)
                _row('Tax portion of this refund', '$sym ${_f(refund.taxAmount)}'),
              _row('Amount Refunded', '$sym ${_f(refund.amount)}',
                  bold: true, highlight: PdfColors.indigo50),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius: pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Remaining Credit',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.Text('$sym ${_f(remainingCredit)}',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if ((refund.notes ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text('Notes',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(refund.notes!,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ],
        pw.Spacer(),
        pw.Divider(color: PdfColors.grey300),
        pw.Center(
          child: pw.Text('This is a computer-generated refund voucher.',
              style: pw.TextStyle(
                  fontSize: 9,
                  color: accent,
                  fontStyle: pw.FontStyle.italic)),
        ),
      ],
    );
  }

  static pw.Widget _meta(String label, String value) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      );

  static pw.Widget _row(String label, String value,
          {bool bold = false, PdfColor? highlight}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  static String _f(double v) => v.toStringAsFixed(2);
}
