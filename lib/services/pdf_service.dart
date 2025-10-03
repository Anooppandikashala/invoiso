import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoiso/database/database_helper.dart';
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
    final dbHelper = DatabaseHelper();
    final company = await dbHelper.getCompanyInfo();

    final selectedTemplate = await dbHelper.getInvoiceTemplate();

    switch (selectedTemplate) {
      case InvoiceTemplate.classic:
        pdf.addPage(_buildClassicTemplate(invoice, company));
        break;
      case InvoiceTemplate.modern:
        pdf.addPage(_buildModernTemplate(invoice, company));
        break;
      case InvoiceTemplate.minimal:
        pdf.addPage(_buildMinimalTemplate(invoice, company));
        break;
    }

    return pdf;
  }

  static pw.MultiPage _buildClassicTemplate(Invoice invoice, CompanyInfo? company)
  {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company?.name ?? '',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(company?.address ?? ''),
                pw.Text(company?.phone ?? ''),
                pw.Text(company?.email ?? ''),
              ],
            ),
            pw.Text('INVOICE',
                style: pw.TextStyle(
                    fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
          ],
        ),
        pw.SizedBox(height: 30),

        // Customer
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Bill To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.customer.name),
                pw.Text(invoice.customer.address),
                pw.Text(invoice.customer.phone),
                pw.Text(invoice.customer.email),
              ]
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Invoice #: ${invoice.id}"),
                pw.Text("Date: ${_formatDate(invoice.date)}"),
              ],
            ),
          ]
        ),

        pw.SizedBox(height: 30),

        // Table
        _buildInvoiceTable(invoice),

        pw.SizedBox(height: 20),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildAdditionalNotes(invoice),
            _buildTotals(invoice),
          ]
        ),


        pw.Divider(),
        pw.Center(
          child: pw.Text("Thank you!",
              style: pw.TextStyle(color: PdfColors.blue, fontSize: 14)),
        ),
      ],
    );
  }

  static pw.MultiPage _buildModernTemplate(Invoice invoice, CompanyInfo? company)
  {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0), // full bleed look
      build: (context) => [
        // Header with color
        pw.Container(
          color: PdfColors.blue,
          padding: const pw.EdgeInsets.all(20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(company?.name ?? '',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.Text(company?.address ?? '', style: pw.TextStyle(color: PdfColors.white)),
                  pw.Text(company?.phone ?? '', style: pw.TextStyle(color: PdfColors.white)),
                  pw.Text(company?.email ?? '', style: pw.TextStyle(color: PdfColors.white)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE',
                      style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.Text("Invoice #: ${invoice.id}"),
                  pw.Text("Date: ${_formatDate(invoice.date)}"),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        // Customer info
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("BILL TO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text(invoice.customer.name),
                  pw.Text(invoice.customer.address),
                  pw.Text(invoice.customer.phone),
                  pw.Text(invoice.customer.email),
                ],
              ),
            ]
          )
        ),
        pw.SizedBox(height: 20),

        // Table
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: _buildInvoiceTable(invoice, headerColor: PdfColors.blue100),
        ),
        pw.SizedBox(height: 20),

        // Totals aligned right
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildAdditionalNotes(invoice),
                _buildTotals(invoice),
              ]
          ),
        ),

        // Footer
        pw.Spacer(),
        pw.Container(
          color: PdfColors.blue,
          padding: const pw.EdgeInsets.all(16),
          child: pw.Center(
            child: pw.Text("Thank you!", style: pw.TextStyle(color: PdfColors.white, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  static pw.MultiPage _buildMinimalTemplate(Invoice invoice, CompanyInfo? company)
  {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text('Invoice',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),

        // Company + Customer side by side
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company?.name ?? ''),
                pw.Text(company?.address ?? ''),
                pw.Text(company?.phone ?? '',),
                pw.Text(company?.email ?? '',),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Invoice #: ${invoice.id}"),
                pw.Text("Date: ${_formatDate(invoice.date)}"),
              ],
            )
          ],
        ),
        pw.SizedBox(height: 20),

        // Customer
        pw.Text("Bill To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(invoice.customer.name),
        pw.Text(invoice.customer.address),
        pw.Text(invoice.customer.phone),
        pw.Text(invoice.customer.email),
        pw.SizedBox(height: 20),

        // Table (plain)
        _buildInvoiceTable(invoice, headerColor: PdfColors.grey200),

        pw.SizedBox(height: 20),
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildAdditionalNotes(invoice),
              _buildTotals(invoice),
            ]
        ),

        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text("Thank you!",
              style: pw.TextStyle(color: PdfColors.grey600, fontSize: 12)),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceTable(Invoice invoice, {PdfColor headerColor = PdfColors.grey200})
  {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _buildTableCell('Sl No', isHeader: true),
            _buildTableCell('Item Name', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Price', isHeader: true),
            _buildTableCell('Discount', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell(item.product.name),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell(item.product.price.toStringAsFixed(2)),
              _buildTableCell(item.discount.toStringAsFixed(2)),
              _buildTableCell(item.total.toStringAsFixed(2)),
            ],
          );
        }),
      ],
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

  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220, // adjust width to fit your layout
        child: pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // label column
            1: const pw.FlexColumnWidth(1), // value column
          },
          children: [
            // Subtotal
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text("Subtotal:"),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("Rs ${invoice.subtotal.toStringAsFixed(2)}"),
                  ),
                ),
              ],
            ),
            // Tax
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text("Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%):"),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("Rs ${invoice.tax.toStringAsFixed(2)}"),
                  ),
                ),
              ],
            ),
            // Divider before total
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.Divider(thickness: 1),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.Divider(thickness: 1),
                ),
              ],
            ),
            // Total
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text(
                    "Total:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      "Rs ${invoice.total.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  static pw.Widget _buildTableCell(String text, {bool isHeader = false})
  {
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
