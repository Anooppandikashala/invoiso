import 'package:flutter/material.dart';
import 'package:invoiso/services/thermal_printer_service.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../common.dart';
import '../database/database_helper.dart';
import '../database/settings_service.dart';
import '../utils/formatters.dart';

class InvoicePdfServices {
  static Future<void> generatePDF(BuildContext context, Invoice invoice) async {
    try {
      final template = await SettingsService.getInvoiceTemplate();
      if (template == InvoiceTemplate.thermal) {
        if (!context.mounted) return;
        await ThermalPrinterService.printInvoice(context, invoice);
      } else {
        final dateFmt = await SettingsService.getDateFormat();
        final pdf = await PDFService.generateInvoicePDF(invoice,
            datePattern: dateFmt.key);
        await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save());
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  static Future<void> previewPDF(BuildContext context, Invoice invoice) async {
    try {
      final dateFmt = await SettingsService.getDateFormat();
      final pdf = await PDFService.generateInvoicePDF(invoice,
          datePattern: dateFmt.key);
      final bytes = await pdf.save();
      if (context.mounted) {
        PDFService.showCenteredPDFViewer(context, bytes, invoice);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error previewing PDF: $e')),
        );
      }
    }
  }

  static Future<void> deleteInvoice(
      BuildContext context, Invoice invoice) async {
    try {
      await InvoiceService.deleteInvoice(invoice.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting PDF: $e')));
      }
    }
  }

  static Future<void> showInvoiceDetails(
      BuildContext context, Invoice invoice) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice #${invoice.invoiceNumber ?? invoice.id}'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${invoice.customer.name}'),
              Text('Date: ${AppFormatters.formatShortDate(invoice.date)}'),
              const SizedBox(height: 16),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice.items.map((item) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${item.product.name} x${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity}'),
                        Text(
                            '${invoice.currencySymbol} ${item.total.toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      '${invoice.currencySymbol} ${invoice.subtotal.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_taxLabel(invoice),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      '${invoice.currencySymbol} ${invoice.tax.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      '${invoice.currencySymbol} ${invoice.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(invoice.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  static String _taxLabel(Invoice invoice) {
    switch (invoice.taxMode) {
      case TaxMode.global:
        return 'Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%):';
      case TaxMode.perItem:
        return 'Tax (per item):';
      case TaxMode.none:
        return 'Tax:';
    }
  }

  /// Generates the next `id` (primary key) — global sequence across all
  /// types, unchanged from before. Other queries (e.g. "recent invoices")
  /// rely on `id` sorting as a single monotonic sequence, so this must never
  /// be scoped by type.
  static Future<String> generateNextId() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final result =
        await db.rawQuery("SELECT id FROM invoices ORDER BY id DESC LIMIT 1");

    int nextNumber;
    if (result.isNotEmpty) {
      final lastNumberStr = result.first['id'] as String;
      final numericPart =
          int.tryParse(lastNumberStr.replaceAll(RegExp(r'\D'), ''));
      nextNumber = (numericPart != null) ? numericPart + 1 : 1;
    } else {
      final startStr = await SettingsService.getSetting(SettingKey.invoiceStartingNumber);
      nextNumber = int.tryParse(startStr ?? '') ?? 1;
      if (nextNumber < 1) nextNumber = 1;
    }

    return nextNumber.toString().padLeft(8, '0');
  }

  /// Generates the next **display** number for [type] ('Invoice' |
  /// 'Quotation' | 'Receipt') — each type has its own independent sequence.
  /// This is separate from `id` (the PK, always global) and is stored in the
  /// `invoice_number` column purely for display.
  ///
  /// Derived from existing rows rather than a persisted counter: takes the
  /// max of the legacy `id` sequence (pre-migration rows, shared across all
  /// types) and the new `invoice_number` column (post-migration, per-type)
  /// for this type, so upgrading preserves numbering continuity for existing
  /// customers without any data migration.
  static Future<String> generateNextInvoiceNumber(String type) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final idResult = await db.rawQuery(
        "SELECT id FROM invoices WHERE type = ? ORDER BY id DESC LIMIT 1",
        [type]);
    final numResult = await db.rawQuery(
        "SELECT invoice_number FROM invoices WHERE type = ? AND invoice_number IS NOT NULL ORDER BY invoice_number DESC LIMIT 1",
        [type]);

    int fromId = 0;
    if (idResult.isNotEmpty) {
      final idStr = idResult.first['id'] as String;
      fromId = int.tryParse(idStr.replaceAll(RegExp(r'\D'), '')) ?? 0;
    }
    int fromNum = 0;
    if (numResult.isNotEmpty) {
      final numStr = numResult.first['invoice_number'] as String;
      fromNum = int.tryParse(numStr.replaceAll(RegExp(r'\D'), '')) ?? 0;
    }

    int nextNumber;
    if (fromId == 0 && fromNum == 0) {
      if (type == 'Invoice') {
        final startStr =
            await SettingsService.getSetting(SettingKey.invoiceStartingNumber);
        nextNumber = int.tryParse(startStr ?? '') ?? 1;
        if (nextNumber < 1) nextNumber = 1;
      } else {
        nextNumber = 1;
      }
    } else {
      nextNumber = (fromId > fromNum ? fromId : fromNum) + 1;
    }

    return nextNumber.toString().padLeft(8, '0');
  }
}
