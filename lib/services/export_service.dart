import 'dart:convert';
import 'package:invoiso/services/backend_services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';

class ExportService {
  static Future<String> exportInvoicesToCsv(List<Invoice> invoices,
      {String type = 'Invoice'}) async {
    final showGst = await BackendServices.settings.getShowGstFields();

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
  /// Pass [settings] to skip redundant DB reads when bulk-exporting.
  static Future<String> exportInvoicesToPdfFolder(
    List<Invoice> invoices, {
    void Function(int completed, int total)? onProgress,
    String? outputDirectory,
    PdfGenerationSettings? settings,
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

    final s = settings ?? await PDFService.fetchPdfSettings();
    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final previousBalanceDue = s.showPreviousBalance
          ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
          : 0.0;
      final pdf = PDFService.generateInvoicePDFWithSettings(
        invoice,
        s,
        previousBalanceDue: previousBalanceDue,
      );
      final bytes = await pdf.save();
      final filename = PDFService.buildPdfFilename(invoice);
      await File('${exportDir.path}/$filename').writeAsBytes(bytes);
      onProgress?.call(i + 1, invoices.length);
    }

    return exportDir.path;
  }

  /// Generates a PDF for each invoice, streams them directly into a ZIP file
  /// at [savePath] — never holds more than one PDF in memory at a time.
  /// Pass [settings] to skip redundant DB reads when bulk-exporting.
  static Future<String> exportInvoicesToZip(
    List<Invoice> invoices,
    String savePath, {
    void Function(int completed, int total)? onProgress,
    PdfGenerationSettings? settings,
  }) async {
    final s = settings ?? await PDFService.fetchPdfSettings();
    final output = OutputFileStream(savePath);
    final encoder = ZipEncoder()..startEncode(output);

    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final previousBalanceDue = s.showPreviousBalance
          ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
          : 0.0;
      final pdf = PDFService.generateInvoicePDFWithSettings(
        invoice,
        s,
        previousBalanceDue: previousBalanceDue,
      );
      final bytes = await pdf.save();
      final filename = PDFService.buildPdfFilename(invoice);
      encoder
          .add(ArchiveFile(filename, bytes.length, Uint8List.fromList(bytes)));
      onProgress?.call(i + 1, invoices.length);
    }

    encoder.endEncode();
    await output.close();
    return savePath;
  }
}
