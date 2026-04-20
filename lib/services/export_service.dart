import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/settings_service.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';

class ExportService {
  static Future<String> exportInvoicesToCsv(List<Invoice> invoices,
      {String type = 'Invoice'}) async {
    final showGst = await SettingsService.getShowGstFields();

    // Build header row
    final header = <String>[
      '$type ID',
      'Date',
      'Due Date',
      'Customer',
      'Phone',
      'Address',
      if (showGst) 'Customer GSTIN',
      'Type',
      'Subtotal',
      'Tax',
      'Total',
      'Currency',
      'UPI',
      'Items',
    ];

    // Sort oldest → newest so records append naturally in spreadsheets
    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => a.id.compareTo(b.id));

    final dataRows = sorted.map((inv) {
      final itemsSummary = inv.items.map((item) {
        final qty = item.quantity == item.quantity.roundToDouble()
            ? item.quantity.toInt().toString()
            : item.quantity.toString();
        final unitPrice = item.effectivePrice.toStringAsFixed(2);
        return '${item.product.name} x$qty @${inv.currencyCode} $unitPrice';
      }).join('; ');

      return <dynamic>[
        inv.id,
        AppFormatters.formatShortDate(inv.date),
        inv.dueDate != null ? AppFormatters.formatShortDate(inv.dueDate!) : '',
        inv.customer.name,
        inv.customer.phone,
        inv.customer.address,
        if (showGst) inv.customer.gstin,
        inv.type,
        inv.subtotal.toStringAsFixed(2),
        inv.tax.toStringAsFixed(2),
        inv.total.toStringAsFixed(2),
        inv.currencyCode,
        inv.upiId ?? '',
        itemsSummary,
      ];
    }).toList();

    final rows = <List<dynamic>>[header, ...dataRows];
    final csv = buildQuotedCsv(rows);
    // Prepend UTF-8 BOM so Excel and other apps render Unicode correctly
    final dir = await getApplicationDocumentsDirectory();
    final prefix = '${type.toLowerCase()}s'; // 'invoices' or 'quotations'
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(utf8.encode('\uFEFF$csv'));
    return file.path;
  }

  /// Generates a PDF for each invoice in [invoices], saves them into
  /// [outputDirectory] (or a timestamped subfolder of Documents if null),
  /// and returns the folder path.  [onProgress] is called after each PDF.
  static Future<String> exportInvoicesToPdfFolder(
    List<Invoice> invoices, {
    void Function(int completed, int total)? onProgress,
    String? outputDirectory,
  }) async {
    final Directory exportDir;
    if (outputDirectory != null) {
      exportDir = Directory(outputDirectory);
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      exportDir = Directory('${docsDir.path}/invoice_pdfs_$timestamp');
    }
    await exportDir.create(recursive: true);

    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final pdf = await PDFService.generateInvoicePDF(invoice);
      final bytes = await pdf.save();
      final filename = PDFService.buildPdfFilename(invoice);
      final file = File('${exportDir.path}/$filename');
      await file.writeAsBytes(bytes);
      onProgress?.call(i + 1, invoices.length);
    }

    return exportDir.path;
  }

  /// Generates a PDF for each invoice, bundles them into a single ZIP file
  /// written to [savePath], and returns that path.
  /// [onProgress] is called after each PDF is added to the archive.
  static Future<String> exportInvoicesToZip(
    List<Invoice> invoices,
    String savePath, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final archive = Archive();

    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final pdf = await PDFService.generateInvoicePDF(invoice);
      final bytes = await pdf.save();
      final filename = PDFService.buildPdfFilename(invoice);
      archive.addFile(ArchiveFile(filename, bytes.length, Uint8List.fromList(bytes)));
      onProgress?.call(i + 1, invoices.length);
    }

    final zipBytes = ZipEncoder().encode(archive);
    await File(savePath).writeAsBytes(zipBytes);
    return savePath;
  }
}
