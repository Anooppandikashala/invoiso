import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/services/backend_services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/utils/fs_utils.dart';

/// Invoice CSV export columns, in file order.
enum InvoiceCsvColumn {
  id,
  date,
  dueDate,
  customer,
  phone,
  address,
  customerGstin, // only exported while GST fields are on
  type,
  status,
  subtotal,
  tax,
  total,
  currency,
  upi,
  items,
  notes,
  privateNotes;

  /// The fixed columns exported before the picker existed.
  static const defaults = [
    id, date, dueDate, customer, phone, address, customerGstin, type,
    status, subtotal, tax, total, currency, upi, items,
  ];

  /// CSV header (also the picker label); [docType] names the ID column.
  String header(String docType) => switch (this) {
        id => '$docType ID',
        date => 'Date',
        dueDate => 'Due Date',
        customer => 'Customer',
        phone => 'Phone',
        address => 'Address',
        customerGstin => 'Customer GSTIN',
        type => 'Type',
        status => 'Status',
        subtotal => 'Subtotal',
        tax => 'Tax',
        total => 'Total',
        currency => 'Currency',
        upi => 'UPI',
        items => 'Items',
        notes => 'Notes',
        privateNotes => 'Private Notes',
      };
}

class ExportService {
  /// Builds the invoice CSV, prompts the user for a save location (a native
  /// "Save As" dialog on desktop; the platform save flow on Android), writes
  /// the file there and returns its path. Returns null if the user cancels.
  /// [columns] defaults to the user's saved choice ([loadCsvColumns]).
  static Future<String?> exportInvoicesToCsv(List<Invoice> invoices,
      {String type = 'Invoice', List<InvoiceCsvColumn>? columns}) async {
    final csv = await buildInvoicesCsv(invoices,
        type: type, columns: columns ?? await loadCsvColumns());
    // Prepend UTF-8 BOM so Excel and other apps render Unicode correctly.
    final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csv'));
    final prefix =
        '${type.toLowerCase().replaceAll(' ', '_')}s'; // 'invoices', 'credit_notes'
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.csv';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $type CSV',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: Platform.isAndroid ? bytes : null,
    );
    if (savePath == null) return null;
    if (!Platform.isAndroid) {
      await File(savePath).writeAsBytes(bytes);
    }
    return savePath;
  }

  /// The user's saved CSV column choice; [InvoiceCsvColumn.defaults] when
  /// nothing (or nothing usable) is saved.
  static Future<List<InvoiceCsvColumn>> loadCsvColumns() async {
    final raw =
        await BackendServices.settings.getSetting(SettingKey.invoiceCsvColumns);
    if (raw == null || raw.isEmpty) return InvoiceCsvColumn.defaults;
    try {
      final names = (jsonDecode(raw) as List).cast<String>().toSet();
      final columns =
          InvoiceCsvColumn.values.where((c) => names.contains(c.name)).toList();
      return columns.isEmpty ? InvoiceCsvColumn.defaults : columns;
    } catch (_) {
      return InvoiceCsvColumn.defaults;
    }
  }

  static Future<void> saveCsvColumns(List<InvoiceCsvColumn> columns) =>
      BackendServices.settings.setSetting(SettingKey.invoiceCsvColumns,
          jsonEncode(columns.map((c) => c.name).toList()));

  @visibleForTesting
  static Future<String> buildInvoicesCsv(List<Invoice> invoices,
      {String type = 'Invoice',
      List<InvoiceCsvColumn> columns = InvoiceCsvColumn.defaults}) async {
    final showGst = await BackendServices.settings.getShowGstFields();
    final cols = columns
        .where((c) => showGst || c != InvoiceCsvColumn.customerGstin)
        .toList();

    final header = cols.map((c) => c.header(type)).toList();

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
        for (final c in cols)
          switch (c) {
            InvoiceCsvColumn.id => inv.id,
            InvoiceCsvColumn.date => AppFormatters.formatShortDate(inv.date),
            InvoiceCsvColumn.dueDate => inv.dueDate != null
                ? AppFormatters.formatShortDate(inv.dueDate!)
                : '',
            InvoiceCsvColumn.customer => inv.customer.name,
            InvoiceCsvColumn.phone => inv.customer.phone,
            InvoiceCsvColumn.address => inv.customer.address,
            InvoiceCsvColumn.customerGstin => inv.customer.gstin,
            InvoiceCsvColumn.type => inv.type,
            InvoiceCsvColumn.status =>
              inv.status ?? (inv.type == 'Quotation' ? 'draft' : ''),
            InvoiceCsvColumn.subtotal => inv.subtotal.toStringAsFixed(2),
            InvoiceCsvColumn.tax => inv.tax.toStringAsFixed(2),
            InvoiceCsvColumn.total => inv.total.toStringAsFixed(2),
            InvoiceCsvColumn.currency => inv.currencyCode,
            InvoiceCsvColumn.upi => inv.upiId ?? '',
            InvoiceCsvColumn.items => itemsSummary,
            InvoiceCsvColumn.notes => inv.notes ?? '',
            InvoiceCsvColumn.privateNotes => inv.privateNotes ?? '',
          },
      ];
    }).toList();

    final rows = <List<dynamic>>[header, ...dataRows];
    return buildQuotedCsv(rows);
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
    final String exportPath;
    if (outputDirectory != null) {
      exportPath = outputDirectory;
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss', 'en_US').format(DateTime.now());
      exportPath = p.join(docsDir.path, 'invoice_pdfs_$timestamp');
    }
    final exportDir = await ensureDirectory(exportPath);

    final s = settings ?? await PDFService.fetchPdfSettings(datePattern: (await BackendServices.settings.getDateFormat()).key);
    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final previousBalanceDue = s.showPreviousBalance
          ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
          : 0.0;
      await PDFService.attachReturnInfo(invoice);
      await PDFService.attachPdfAttachments(invoice);
      final pdf = PDFService.generateInvoicePDFWithSettings(
        invoice,
        s,
        previousBalanceDue: previousBalanceDue,
      );
      final bytes = await pdf.save();
      final filename = PDFService.buildPdfFilename(invoice);
      await File(p.join(exportDir.path, filename)).writeAsBytes(bytes);
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
    final s = settings ?? await PDFService.fetchPdfSettings(datePattern: (await BackendServices.settings.getDateFormat()).key);
    final output = OutputFileStream(savePath);
    final encoder = ZipEncoder()..startEncode(output);

    for (int i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final previousBalanceDue = s.showPreviousBalance
          ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
          : 0.0;
      await PDFService.attachReturnInfo(invoice);
      await PDFService.attachPdfAttachments(invoice);
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
