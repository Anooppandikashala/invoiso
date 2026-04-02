import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/settings_service.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';

class ExportService {
  static Future<String> exportInvoicesToCsv(List<Invoice> invoices) async {
    final showGst = await SettingsService.getShowGstFields();

    // Build header row
    final header = <String>[
      'Invoice ID',
      'Date',
      'Customer',
      'Phone',
      'Address',
      if (showGst) 'Customer GSTIN',
      'Type',
      'Subtotal',
      'Tax',
      'Total',
      'Currency',
      'Items',
    ];

    final dataRows = invoices.map((inv) {
      final itemsSummary = inv.items.map((item) {
        final unitPrice = item.product.price.toStringAsFixed(2);
        return '${item.product.name} \u00d7${item.quantity} @${inv.currencySymbol}$unitPrice';
      }).join('; ');

      return <dynamic>[
        inv.id,
        AppFormatters.formatShortDate(inv.date),
        inv.customer.name,
        inv.customer.phone,
        inv.customer.address,
        if (showGst) inv.customer.gstin,
        inv.type,
        inv.subtotal.toStringAsFixed(2),
        inv.tax.toStringAsFixed(2),
        inv.total.toStringAsFixed(2),
        inv.currencyCode,
        itemsSummary,
      ];
    }).toList();

    final rows = <List<dynamic>>[header, ...dataRows];
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
