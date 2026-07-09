import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_widgets.dart' show invoiceTaxLabel;
import 'package:invoiso/database/settings_service.dart';
import 'package:thermal_printer/thermal_printer.dart';

/// Prints receipts as raw ESC/POS commands sent directly to the printer,
/// instead of rendering a PDF and letting the OS/GDI driver rasterize it.
/// This is what fixes garbled thermal output — the printer gets its native
/// command language instead of a rasterized page the driver may mishandle.
class ThermalPrinterService {
  static Future<void> printInvoice(
      BuildContext context, Invoice invoice) async {
    final discovered = await UsbPrinterConnector.discoverPrinters();
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Print Receipt'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('USB Printers',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (discovered.isEmpty)
                const Text('No USB printers found.')
              else
                ...discovered.map((p) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.name),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        final input = UsbPrinterInput(
                          name: p.detail.name,
                          vendorId: p.detail.vendorId,
                          productId: p.detail.productId,
                        );
                        await _printToDevice(
                            type: PrinterType.usb, model: input, invoice: invoice);
                      },
                    )),
              if (kDebugMode) ...[
                const Divider(height: 24),
                const Text('Test via network (e.g. local ESC/POS listener)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _NetworkPrintRow(invoice: invoice),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Future<void> _printToDevice({
    required PrinterType type,
    required BasePrinterInput model,
    required Invoice invoice,
  }) async {
    final manager = PrinterManager.instance;
    final bytes = await _buildReceiptBytes(invoice);
    await manager.connect(type: type, model: model);
    await manager.send(type: type, bytes: bytes);
    await manager.disconnect(type: type);
  }

  /// Mirrors [PDFService.generateInvoicePDF]'s content exactly (same
  /// settings fetch, same fields shown/hidden) so the ESC/POS printout
  /// matches the PDF preview. Deliberately avoids the ESC/POS library's
  /// row()/absolute-column-position feature — that's what produced the
  /// broken layout on real/virtual printers; plain text lines with manual
  /// space padding render correctly everywhere.
  static Future<List<int>> _buildReceiptBytes(Invoice invoice) async {
    final dateFmt = await SettingsService.getDateFormat();
    final settings = await PDFService.fetchPdfSettings(datePattern: dateFmt.key);
    final previousBalanceDue = settings.showPreviousBalance
        ? await InvoiceService.getPreviousBalanceDueForInvoice(invoice)
        : 0.0;
    final effectivePreviousBalance =
        settings.showPreviousBalance ? previousBalanceDue : 0.0;

    final is58 = settings.pageSize == PageSize.thermal58;

    //final width = is58 ? PaperSize.mm58.width : PaperSize.mm80.width;
    final width = is58 ? 32 : 48;
    //final width = is58 ? 42 : 64;
    final profile = await CapabilityProfile.load();
    final generator = Generator(is58 ? PaperSize.mm58 : PaperSize.mm80, profile);
    final currency = invoice.currencySymbol;
    final company = settings.company;

    final showItemTax = invoice.taxMode == TaxMode.perItem;
    List<int> bytes = [];

    void line(String text, {PosAlign align = PosAlign.left, bool bold = false,bool isHead = false})
    {
      if(isHead) {
        bytes += generator.text(text, styles: PosStyles(align: align, bold: bold,height: PosTextSize.size2,width: PosTextSize.size1,));
      } else {
        bytes += generator.text(text, styles: PosStyles(align: align, bold: bold,));
      }
    }

    void twoCol(String left, String right, {bool bold = false}) {
      final pad = width - left.length - right.length;
      final text = pad > 0 ? '$left${' ' * pad}$right' : '$left $right';
      line(text, bold: bold);
    }

    void twoCol2(String left, String right, {bool bold = false}) {
      bytes += generator.row(
          [
        PosColumn(
          text: left,
          width: 7,
          styles: PosStyles(align: PosAlign.left, underline: false, bold: bold,fontType: PosFontType.fontB),
        ),
        PosColumn(
          text: right,
          width: 5,
          styles: PosStyles(align: PosAlign.right, underline: false, bold: bold,fontType: PosFontType.fontB),
        ),
      ]);
    }

    void hr() {bytes+=generator.hr();}

    String padRight(String s, int w) =>
        s.length >= w ? s.substring(0, w) : s + ' ' * (w - s.length);
    String padLeft(String s, int w) =>
        s.length >= w ? s.substring(s.length - w) : ' ' * (w - s.length) + s;
    String padCenter(String s, int w) {
      if (s.length >= w) return s.substring(0, w);
      final totalPad = w - s.length;
      final left = totalPad ~/ 2;
      return ' ' * left + s + ' ' * (totalPad - left);
    }

    // ── Business header ──
    if ((company?.name ?? '').isNotEmpty) {
      line(company!.name, align: PosAlign.center, bold: true,isHead: true);
    }
    if ((company?.address ?? '').isNotEmpty) {
      line(company!.address, align: PosAlign.center);
    }
    if ((company?.phone ?? '').isNotEmpty) {
      line('Ph: ${company!.phone}', align: PosAlign.center);
    }
    if (settings.showGst && (company?.gstin ?? '').isNotEmpty) {
      line('${taxLabel(company?.country)}: ${company!.gstin}',
          align: PosAlign.center);
    }
    hr();
    line(invoice.type.toUpperCase(), align: PosAlign.center, bold: true);
    hr();

    // ── Invoice meta ──
    final dateFormatter = DateFormat(dateFmt.key);
    final dateStr = dateFormatter.format(invoice.date);
    twoCol('Inv No: ${settings.invoicePrefix}${invoice.invoiceNumber ?? invoice.id}',
        'Date: $dateStr');
    if (invoice.dueDate != null) {
      twoCol('Due:', dateFormatter.format(invoice.dueDate!));
    }
    hr();

    // ── Customer ──
    line('Name: ${invoice.customer.name}', bold: true);
    if (invoice.customer.businessName.isNotEmpty) {
      line(invoice.customer.businessName);
    }
    if (invoice.customer.phone.isNotEmpty) {
      line('Ph: ${invoice.customer.phone}');
    }
    if (settings.showGst && invoice.customer.gstin.isNotEmpty) {
      line('${taxLabel(company?.country)}: ${invoice.customer.gstin}');
    }
    hr();

    // ── Items ──
    // Column widths for the single-line (80mm-style) layout.
    const slW = 3, qtyW = 5, rateW = 8, gstW = 5, totalW = 9;
    final gaps = showItemTax ? 5 : 4;
    final nameW = width - slW - qtyW - rateW - (showItemTax ? gstW : 0) - totalW - gaps;

    String singleLineRow(String sl, String name, String qty, String rate,
        String? gst, String total) {
      final parts = <String>[
        padRight(sl, slW),
        padRight(name, nameW),
        padCenter(qty, qtyW),
        padLeft(rate, rateW),
      ];
      if (gst != null) parts.add(padLeft(gst, gstW));
      parts.add(padLeft(total, totalW));
      return parts.join(' ');
    }

    if (is58) {
      twoCol('# Item', 'Total', bold: true);
    } else {
      line(
          singleLineRow('Sl', 'Description', 'Qty', 'Rate',
              showItemTax ? 'GST%' : null, 'Total'),
          bold: true);
    }
    hr();
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final qty = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(2);
      final rate = item.effectivePrice.toStringAsFixed(2);
      final total = item.total.toStringAsFixed(2);

      if (is58) {
        line('${i + 1} ${item.product.name}', bold: true);
        final detailParts = ['Qty:$qty', 'Rate:$rate'];
        if (showItemTax) detailParts.add('${item.product.tax_rate}%');
        detailParts.add(total);
        line('  ${detailParts.join('  ')}');
      } else {
        line(singleLineRow('${i + 1}', item.product.name, qty, rate,
            showItemTax ? '${item.product.tax_rate}%' : null, total));
      }
      if (settings.showDiscount && item.totalDiscount > 0) {
        line('  Disc: -${item.totalDiscount.toStringAsFixed(2)}');
      }
    }
    hr();

    // ── Totals ──
    if (invoice.totalDiscount > 0) {
      twoCol('Subtotal:', '$currency ${invoice.grossSubtotal.toStringAsFixed(2)}');
      twoCol('Discount:', '-$currency ${invoice.totalDiscount.toStringAsFixed(2)}');
    }
    if (invoice.taxMode != TaxMode.none) {
      twoCol(invoiceTaxLabel(invoice), '$currency ${invoice.tax.toStringAsFixed(2)}');
    }
    for (final c in invoice.additionalCosts) {
      twoCol(c.label.isEmpty ? 'Extra Cost' : c.label,
          '$currency ${c.amount.toStringAsFixed(2)}');
    }
    if (effectivePreviousBalance > 0) {
      twoCol('Prev Balance:',
          '$currency ${effectivePreviousBalance.toStringAsFixed(2)}');
    }
    twoCol(
      'TOTAL',
      '$currency ${(invoice.total + effectivePreviousBalance).toStringAsFixed(2)}',
      bold: true,
    );

    if(invoice.tax > 0)
    {
      hr();
      line("==== TAX SUMMARY ====",align: PosAlign.center,bold: true);
      if(company?.country.toLowerCase() == "india")
      {
        twoCol('Taxable Amnt', '$currency ${invoice.grossSubtotal}');
        twoCol('Total Tax', '$currency ${invoice.tax}');
      }
      else
      {
        twoCol('Taxable Amnt', '$currency ${invoice.grossSubtotal}');
        twoCol('Total Tax', '$currency ${invoice.tax}');
      }
    }

    if (invoice.amountPaid > 0) {
      hr();
      twoCol('Paid:', '$currency ${invoice.amountPaid.toStringAsFixed(2)}');
      if (invoice.outstandingBalance <= 0) {
        twoCol('PAID IN FULL', '', bold: true);
      } else {
        twoCol('Balance Due', '$currency ${invoice.outstandingBalance.toStringAsFixed(2)}',
            bold: true);
      }
    }

    // ── Notes ──
    if ((invoice.notes ?? '').isNotEmpty) {
      hr();
      line(invoice.notes!);
    }

    // ── Footer ──
    hr();
    if (settings.thankYouNote.isNotEmpty) {
      line(settings.thankYouNote, align: PosAlign.center, bold: true);
    }
    if (settings.showFooterBranding) {
      line('Generated by Invoiso', align: PosAlign.center);
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }
}

class _NetworkPrintRow extends StatefulWidget {
  final Invoice invoice;
  const _NetworkPrintRow({required this.invoice});

  @override
  State<_NetworkPrintRow> createState() => _NetworkPrintRowState();
}

class _NetworkPrintRowState extends State<_NetworkPrintRow> {
  final _ipController = TextEditingController(text: '0.0.0.0');
  final _portController = TextEditingController(text: '9200');
  bool _sending = false;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final input = TcpPrinterInput(
        ipAddress: _ipController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 9100,
      );
      await ThermalPrinterService._printToDevice(
        type: PrinterType.network,
        model: input,
        invoice: widget.invoice,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text('Sent to network printer/listener.')),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _ipController,
            decoration: const InputDecoration(labelText: 'IP address'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _portController,
            decoration: const InputDecoration(labelText: 'Port'),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }
}
