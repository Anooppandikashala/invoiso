

import 'package:flutter/material.dart';
import 'package:invoiceapp/models/invoice.dart';
import 'package:invoiceapp/services/pdf_service.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../database/database_helper.dart';
import '../screens/pdf_view_screen.dart';

class InvoiceServices
{
  static Future<void>  generatePDF(BuildContext context,Invoice invoice) async {
    try {
      final pdf = await PDFService.generateInvoicePDF(invoice);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  static Future<void>  viewPDF(BuildContext context,Invoice invoice) async {
    try {
      final pdf = await PDFService.generateInvoicePDF(invoice);
      final bytes = await pdf.save();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(pdfBytes: bytes, invoiceId: invoice.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error previewing PDF: $e')),
      );
    }
  }

  static Future<void> previewPDF(BuildContext context, Invoice invoice) async {
    try {
      final pdf = await PDFService.generateInvoicePDF(invoice);
      final bytes = await pdf.save();
      PDFService.showCenteredPDFViewer(context, bytes, invoice.id);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => PDFViewerScreen(pdfBytes: bytes, invoiceId: invoice.id),
      //   ),
      // );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error previewing PDF: $e')),
      );
    }
  }

  static Future<void> deleteInvoice(BuildContext context,Invoice invoice) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteInvoice(invoice.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting PDF: $e')));
    }
  }

  static Future<void> showInvoiceDetails(BuildContext context,Invoice invoice) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice #${invoice.id}'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${invoice.customer.name}'),
              Text('Date: ${invoice.date.toString().split(' ')[0]}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice.items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.product.name} x${item.quantity}'),
                    Text(item.total.toStringAsFixed(2)),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(invoice.subtotal.toStringAsFixed(2)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(invoice.tax.toStringAsFixed(2)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(invoice.total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(invoice.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  static Future<String> generateNextInvoiceNumber() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Fetch latest invoice ID (assumed to be stored as a string of digits or with a prefix)
    final result = await db.rawQuery(
        "SELECT id FROM invoices ORDER BY id DESC LIMIT 1"
    );

    int nextNumber = 1;

    if (result.isNotEmpty) {
      final lastNumberStr = result.first['id'] as String;

      // Extract numeric part
      final numericPart = int.tryParse(lastNumberStr.replaceAll(RegExp(r'\D'), ''));
      if (numericPart != null) {
        nextNumber = numericPart + 1;
      }
    }

    // Format to 8 digits
    final formatted = nextNumber.toString().padLeft(8, '0');
    return formatted;
  }

}


