import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/refund.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/services/thermal_printer_service_v1.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:invoiso/common/common.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/widgets/return_l10n.dart';

class InvoicePdfServices {
  static Future<void> generatePDF(BuildContext context, Invoice invoice) async {
    try {
      final template = await BackendServices.settings.getInvoiceTemplate();
      if (template == InvoiceTemplate.thermal) {
        if (!context.mounted) return;
        await ThermalPrinterService.printInvoice(context, invoice);
      } else {
        final dateFmt = await BackendServices.settings.getDateFormat();
        final pdf = await PDFService.generateInvoicePDF(invoice,
            datePattern: dateFmt.key);
        final pageSize = await BackendServices.settings.getPageSize();
        await Printing.layoutPdf(
            format: PDFService.pageSizeToFormat(pageSize),
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
      final dateFmt = await BackendServices.settings.getDateFormat();
      final pdf = await PDFService.generateInvoicePDF(invoice,
          datePattern: dateFmt.key);
      final bytes = await pdf.save();
      if (context.mounted) {
        PDFService.showCenteredPDFViewer(context, bytes, invoice);
      }
    } catch (e) {
      if (context.mounted) {
        if(kDebugMode) print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error previewing PDF: $e')),
        );
      }
    }
  }

  static Future<void> deleteInvoice(
      BuildContext context, Invoice invoice) async {
    try {
      await BackendServices.invoices.deleteInvoice(invoice.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting PDF: $e')));
      }
    }
  }

  /// [notes]: credit / debit notes raised against [invoice], listed under
  /// the totals when non-empty.
  static Future<void> showInvoiceDetails(
      BuildContext context, Invoice invoice,
      {List<Invoice> notes = const [],
      void Function(Invoice note)? onVoidNote,
      Map<String, List<Refund>> refundsByNote = const {},
      void Function(Invoice note, Refund refund, String action)?
          onVoucherAction}) async {
    await PDFService.attachReturnInfo(invoice);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${invoice.invoiceTitle ?? invoice.type} #${invoice.invoiceNumber ?? invoice.id}'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invoice.status == 'declined')
                const Text('DECLINED',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              Text('Customer: ${invoice.customer.name}'),
              Text('Date: ${AppFormatters.formatShortDate(invoice.date)}'),
              if (invoice.originalInvoiceNumber != null)
                Row(children: [
                  Text(
                      invoice.originalInvoiceType == 'Receipt'
                          ? AppLocalizations.of(context)!
                              .returnAgainstReceiptFull(invoice.originalInvoiceNumber!)
                          : AppLocalizations.of(context)!
                              .returnAgainstInvoiceFull(invoice.originalInvoiceNumber!),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                  _copyButton(
                      context,
                      invoice.originalInvoiceNumber!,
                      AppLocalizations.of(context)!.returnCopyInvoiceNumberTooltip,
                      AppLocalizations.of(context)!.returnInvoiceNumberCopiedMessage),
                ]),
              if (invoice.returnReason != null &&
                  invoice.returnReason!.isNotEmpty)
                Text(
                    '${AppLocalizations.of(context)!.returnReasonLabel}: ${invoice.returnReason}'),
              const SizedBox(height: 16),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice.items.map((item) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${item.product.name} x${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity}'),
                            Text(
                                '${invoice.currencySymbol} ${item.total.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (item.totalDiscount > 0)
                          Text(
                              'Discount: -${invoice.currencySymbol} ${item.totalDiscount.toStringAsFixed(2)}'
                              '${item.discountIsPercent ? ' (${item.discount == item.discount.roundToDouble() ? item.discount.toInt() : item.discount}%)' : ''}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
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
                      '${invoice.currencySymbol} ${(invoice.totalDiscount > 0 ? invoice.grossSubtotal : invoice.subtotal).toStringAsFixed(2)}'),
                ],
              ),
              if (invoice.totalDiscount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '-${invoice.currencySymbol} ${invoice.totalDiscount.toStringAsFixed(2)}'),
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
              ...invoice.additionalCosts.map((c) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${c.label.isEmpty ? 'Extra Cost' : c.label}:',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(c.amount < 0
                          ? '-${invoice.currencySymbol} ${(-c.amount).toStringAsFixed(2)}'
                          : '${invoice.currencySymbol} ${c.amount.toStringAsFixed(2)}'),
                    ],
                  )),
              if (invoice.invoiceDiscountAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        invoice.invoiceDiscountType == InvoiceDiscountType.percent
                            ? 'Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%):'
                            : 'Extra Discount:',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '-${invoice.currencySymbol} ${invoice.invoiceDiscountAmount.toStringAsFixed(2)}'),
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
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.returnNotesSectionTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ...notes.map((n) => _linkedNoteRow(context, n, onVoidNote,
                    refundsByNote[n.id] ?? const [], onVoucherAction)),
              ],
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

  static Widget _linkedNoteRow(BuildContext context, Invoice note,
      void Function(Invoice note)? onVoidNote,
      [List<Refund> refunds = const [],
      void Function(Invoice note, Refund refund, String action)?
          onVoucherAction]) {
    final l10n = AppLocalizations.of(context)!;
    final isCredit = note.type == 'Credit Note';
    final details = [
      AppFormatters.formatShortDate(note.date),
      if (note.returnReason != null) returnReasonLabel(l10n, note.returnReason!),
      if (isCredit && note.creditSettlement != null)
        creditSettlementLabel(l10n, note.creditSettlement!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                      '${isCredit ? l10n.docTypeCreditNote : l10n.docTypeDebitNote} #${note.invoiceNumber ?? note.id}'),
                  _copyButton(context, note.invoiceNumber ?? note.id,
                      l10n.returnCopyNoteNumberTooltip,
                      l10n.returnNoteNumberCopiedMessage),
                ]),
                Text(details,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
              '${isCredit ? '−' : '+'}${note.currencySymbol} ${note.total.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCredit ? Colors.brown : Colors.indigo)),
          // The note's own PDF — the only way to get it when the Credit /
          // Debit Notes tabs are hidden (returns toggle off).
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            tooltip: l10n.returnNotePdfTooltip,
            onSelected: (a) {
              switch (a) {
                case 'preview':
                  previewPDF(context, note);
                case 'download':
                  PDFService.downloadPDF(context, note);
                case 'print':
                  generatePDF(context, note);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'preview', child: Text(l10n.actionPdfPreview)),
              PopupMenuItem(value: 'download', child: Text(l10n.actionDownloadPdf)),
              PopupMenuItem(value: 'print', child: Text(l10n.actionPrint)),
            ],
          ),
          // Refund voucher PDF — same preview / download / print as the note
          // PDF; with several refunds each gets a header row.
          if (onVoucherAction != null && refunds.isNotEmpty)
            PopupMenuButton<(Refund, String)>(
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              tooltip: l10n.returnPrintVoucher,
              onSelected: (v) => onVoucherAction(note, v.$1, v.$2),
              itemBuilder: (_) => [
                for (final r in refunds) ...[
                  if (refunds.length > 1)
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                          '${r.receiptNumber}  ·  ${note.currencySymbol}${r.amount.toStringAsFixed(2)}'),
                    ),
                  PopupMenuItem(
                      value: (r, 'preview'), child: Text(l10n.actionPdfPreview)),
                  PopupMenuItem(
                      value: (r, 'download'),
                      child: Text(l10n.actionDownloadPdf)),
                  PopupMenuItem(
                      value: (r, 'print'), child: Text(l10n.actionPrint)),
                ],
              ],
            ),
          if (isCredit && onVoidNote != null)
            IconButton(
              icon: const Icon(Icons.block_outlined, size: 18, color: Colors.red),
              tooltip: l10n.returnVoidNoteTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.of(context).pop();
                onVoidNote(note);
              },
            ),
        ],
      ),
    );
  }

  static Widget _copyButton(
      BuildContext context, String text, String tooltip, String copiedMessage) {
    return IconButton(
      icon: const Icon(Icons.copy, size: 16),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(copiedMessage)));
      },
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
  static Future<String> generateNextId() => BackendServices.invoices.generateNextId();

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
  static Future<String> generateNextInvoiceNumber(String type) =>
      BackendServices.invoices.generateNextInvoiceNumber(type);

  /// Non-consuming preview of [generateNextId] — for UI display only.
  static Future<String> peekNextId() => BackendServices.invoices.peekNextId();

  /// Non-consuming preview of [generateNextInvoiceNumber] — for UI display only.
  static Future<String> peekNextInvoiceNumber(String type) =>
      BackendServices.invoices.peekNextInvoiceNumber(type);
}
