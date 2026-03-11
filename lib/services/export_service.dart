import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';

class ExportService {
  static Future<String> exportInvoicesToCsv(List<Invoice> invoices) async {
    final rows = <List<dynamic>>[
      ['Invoice ID', 'Date', 'Customer', 'Type', 'Subtotal', 'Tax', 'Total', 'Currency'],
      ...invoices.map((inv) => [
        inv.id,
        AppFormatters.formatShortDate(inv.date),
        inv.customer.name,
        inv.type,
        inv.subtotal.toStringAsFixed(2),
        inv.tax.toStringAsFixed(2),
        inv.total.toStringAsFixed(2),
        inv.currencyCode,
      ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'invoices_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Generates a PDF for each invoice in [invoices], saves them all into a
  /// timestamped subfolder of the Documents directory, and returns the folder
  /// path.  [onProgress] is called after each PDF is written.
  static Future<String> exportInvoicesToPdfFolder(
    List<Invoice> invoices, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final timestamp =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportDir =
        Directory('${docsDir.path}/invoice_pdfs_$timestamp');
    await exportDir.create(recursive: true);

    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final pdf = await PDFService.generateInvoicePDF(invoice);
      final bytes = await pdf.save();
      // Sanitise the invoice ID so it is safe as a filename on all platforms.
      final safeName =
          invoice.id.replaceAll(RegExp(r'[^\w\-]'), '_');
      final file =
          File('${exportDir.path}/Invoice_$safeName.pdf');
      await file.writeAsBytes(bytes);
      onProgress?.call(i + 1, invoices.length);
    }

    return exportDir.path;
  }
}
