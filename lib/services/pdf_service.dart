import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoiceapp/database/database_helper.dart';
import 'package:invoiceapp/models/company_info.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

import 'package:invoiceapp/models/invoice.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// PDF Generation Service
class PDFService {
  static Future<pw.Document> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();
    final dbHelper = DatabaseHelper();
    final company = await dbHelper.getCompanyInfo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      company?.name ?? '',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(company?.address ?? ''),
                    pw.Text(company?.phone ?? ''),
                    pw.Text(company?.email ?? ''),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Invoice #: ${invoice.id}'),
                    pw.Text('Date: ${_formatDate(invoice.date)}'),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Customer Information
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(invoice.customer.name),
                      pw.Text(invoice.customer.address),
                      pw.Text(invoice.customer.phone),
                      pw.Text(invoice.customer.email),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Invoice Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Sl No', isHeader: true),
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Qty', isHeader: true),
                    _buildTableCell('Price', isHeader: true),
                    _buildTableCell('Discount', isHeader: true),
                    _buildTableCell('Total', isHeader: true),
                  ],
                ),
                // Items
                ...invoice.items.asMap().entries.map((entry)
                {
                    final index = entry.key;        // Serial number starts from 0
                    final item = entry.value;
                    return pw.TableRow(
                    children: [
                        _buildTableCell('${index + 1}'),
                        _buildTableCell(item.product.name),
                        _buildTableCell(item.quantity.toString()),
                        _buildTableCell(
                            '${item.product.price.toStringAsFixed(2)}'),
                        _buildTableCell(
                            '${item.discount.toStringAsFixed(2)}'),
                        _buildTableCell('${item.total.toStringAsFixed(2)}'),
                      ],
                    );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(width: 100, child: pw.Text('Subtotal:')),
                        pw.SizedBox(
                            width: 80,
                            child: pw.Text(
                                'Rs ${invoice.subtotal.toStringAsFixed(2)}')),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(
                            width: 100,
                            child: pw.Text(
                                'Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%):')),
                        pw.SizedBox(
                            width: 80,
                            child:
                            pw.Text('Rs ${invoice.tax.toStringAsFixed(2)}')),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.SizedBox(
                          width: 100,
                          child: pw.Text(
                            'Total:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(
                          width: 80,
                          child: pw.Text(
                            'Rs ${invoice.total.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.Text(
                'Notes:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(invoice.notes!),
              pw.SizedBox(height: 20),
            ],

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
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
        insetPadding: const EdgeInsets.all(24),
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
