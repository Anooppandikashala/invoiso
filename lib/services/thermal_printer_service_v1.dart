import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:invoiso/services/backend_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_widgets.dart'
    show
        invoiceTaxLabel,
        customerExtraLines,
        shipToLines,
        showShipTo,
        returnInfoLines,
        roundNetTotal;
import 'package:invoiso/utils/amount_in_words.dart';
import 'package:invoiso/utils/formatters.dart';
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
    final dateFmt = await BackendServices.settings.getDateFormat();
    await AmountFormat.load(); // Number format setting
    final settings = await PDFService.fetchPdfSettings(datePattern: dateFmt.key);
    await PDFService.attachReturnInfo(invoice);
    final previousBalanceDue = settings.showPreviousBalance
        ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
        : 0.0;
    final effectivePreviousBalance =
    settings.showPreviousBalance ? previousBalanceDue : 0.0;

    final is58 = settings.pageSize == PageSize.thermal58;

    // Trim a few chars off the textbook 32/48 — real hardware often
    // physically clips the last column(s) on full-width lines. Adjustable
    // per-install via SettingKey.thermalWidthMargin since printer models vary
    // (e.g. WOOSIM WSP-R241 needed 1).
    final marginStr = await BackendServices.settings.getSetting(SettingKey.thermalWidthMargin);
    final margin = int.tryParse(marginStr ?? '') ?? 1;
    final itemLayout =
        await BackendServices.settings.getSetting(SettingKey.thermalItemLayout) ?? 'table';
    if(kDebugMode) print(margin);
    final width = (is58 ? 32 : 48) - margin;
    if(kDebugMode)  print(width);
    final profile = await CapabilityProfile.load();
    final generator = Generator(is58 ? PaperSize.mm58 : PaperSize.mm80, profile,spaceBetweenRows: 1);
    final currency = invoice.currencySymbol;
    final company = settings.company;

    final showItemTax =
        invoice.taxMode == TaxMode.perItem && settings.showTaxColumn;
    final qtyLabel = invoice.quantityLabel?.isNotEmpty == true
        ? invoice.quantityLabel!
        : 'Qty';
    List<int> bytes = [];

    // ESC/POS only has fixed glyph sizes, so map the company-name size
    // setting onto them; 'medium' keeps the previous double-height default.
    final nameSize = thermalCompanyNameSizeFromKey(settings.thermalCompanyNameSize);
    final headHeight = nameSize == ThermalCompanyNameSize.medium ||
            nameSize == ThermalCompanyNameSize.large
        ? PosTextSize.size2
        : PosTextSize.size1;
    final headWidth = nameSize == ThermalCompanyNameSize.large
        ? PosTextSize.size2
        : PosTextSize.size1;
    final headFont = nameSize == ThermalCompanyNameSize.xsmall
        ? PosFontType.fontB
        : PosFontType.fontA;

    void line(String text, {PosAlign align = PosAlign.left, bool bold = false,bool isHead = false})
    {
      if(isHead) {
        bytes += generator.text(text, styles: PosStyles(align: align, bold: bold,height: headHeight,width: headWidth,fontType: headFont,));
      } else {
        bytes += generator.text(text, styles: PosStyles(align: align, bold: bold,));
      }
    }

    void twoCol(String left, String right, {bool bold = false}) {
      final pad = width - left.length - right.length;
      final text = pad > 0 ? '$left${' ' * pad}$right' : '$left $right';
      line(text, bold: bold);
    }

    /*
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
    */

    void hr() {bytes+=generator.hr();}

    //void hr2() => line('-' * width);

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
    if (settings.showCompanyName && (company?.name ?? '').isNotEmpty) {
      line(company!.name, align: PosAlign.center, bold: true,isHead: true);
    }
    if (settings.showAddress && (company?.address ?? '').isNotEmpty) {
      line(company!.address, align: PosAlign.center);
    }
    // Items share a centred line joined by ' | '; whole items wrap onto the
    // next line when they don't fit the paper width.
    void packedLine(List<String> items) {
      var cur = '';
      for (final item in items) {
        if (cur.isNotEmpty && cur.length + 3 + item.length > width) {
          line(cur, align: PosAlign.center);
          cur = '';
        }
        cur = cur.isEmpty ? item : '$cur | $item';
      }
      if (cur.isNotEmpty) line(cur, align: PosAlign.center);
    }

    packedLine([
      if (settings.showPhone && (company?.phone ?? '').isNotEmpty)
        'Ph: ${company!.phone}',
      if (settings.showEmail && (company?.email ?? '').isNotEmpty)
        company!.email,
      if (settings.showWebsite && (company?.website ?? '').isNotEmpty)
        company!.website,
    ]);
    packedLine([
      if (settings.showGst && (company?.gstin ?? '').isNotEmpty)
        '${taxLabel(company?.country)}: ${company!.gstin}',
      if (settings.showPan && (company?.panNumber ?? '').isNotEmpty)
        'PAN: ${company!.panNumber}',
      if (settings.showFssai &&
          (company?.fssaiCode ?? '').isNotEmpty &&
          isIndiaCountry(company?.country))
        'FSSAI: ${company!.fssaiCode}',
    ]);
    hr();
    line((invoice.invoiceTitle ?? invoice.type).toUpperCase(), align: PosAlign.center, bold: true);
    if (invoice.status == 'declined') {
      line('*** DECLINED ***', align: PosAlign.center, bold: true);
    }
    hr();

    // ── Invoice meta ──
    final dateFormatter = DateFormat(dateFmt.key, 'en_US');
    final dateStr = settings.showTimeInPdf
        ? '${dateFormatter.format(invoice.date)} ${DateFormat(settings.pdfTimeFormat == '12' ? 'h:mm a' : 'HH:mm', 'en_US').format(invoice.date)}'
        : dateFormatter.format(invoice.date);
    final numberText = invoice.pdfNumberText(settings.prefixFor(invoice.type),
        showLeadingZeros: settings.showLeadingZeros);
    twoCol(numberText != null ? '${invoice.thermalNumberLabel}: $numberText' : '', 'Date: $dateStr');
    if (invoice.dueDate != null) {
      twoCol('Due:', dateFormatter.format(invoice.dueDate!));
    }
    hr();

    // ── Customer ──
    line('Name: ${invoice.customer.name}', bold: true);
    if (settings.showCustomerBusinessName &&
        invoice.customer.businessName.isNotEmpty) {
      line(invoice.customer.businessName);
    }
    if (settings.showCustomerAddress && invoice.customer.address.isNotEmpty) {
      line(invoice.customer.address);
    }
    if (settings.showCustomerPhone && invoice.customer.phone.isNotEmpty) {
      line('Ph: ${invoice.customer.phone}');
    }
    if (settings.showCustomerEmail && invoice.customer.email.isNotEmpty) {
      line(invoice.customer.email);
    }
    if (settings.showGst &&
        settings.showCustomerGstin &&
        invoice.customer.gstin.isNotEmpty) {
      line('${taxLabel(company?.country)}: ${invoice.customer.gstin}');
    }
    // ASCII separator: '·' isn't in every ESC/POS code page.
    for (final l in customerExtraLines(invoice.customer,
        settings.customerFields, invoice.date, settings.datePattern,
        separator: ' | ')) {
      line(l);
    }
    if (showShipTo(invoice.customer, settings.customerFields)) {
      line('Ship To:', bold: true);
      for (final l in shipToLines(invoice.customer, phonePrefix: 'Ph: ')) {
        line(l);
      }
    }
    hr();

    // ── Items ──
    // Table layout: compact column widths, tight enough to still fit on
    // 58mm (31 chars) while leaving extra room for the name on 80mm.
    final slW = settings.showSlNo ? 2 : 0;
    final qtyW = settings.showQuantity ? 4 : 0;
    final rates = [for (final i in invoice.items) AmountFormat.money(i.effectivePrice)];
    final totals = [for (final i in invoice.items) AmountFormat.money(i.total)];
    // Widen rate/total to the longest amount: padLeft cuts from the left, so a
    // narrow column would silently drop leading digits (1,250.00 → ,250.00).
    int widest(List<String> l, int min) =>
        l.fold(min, (m, s) => s.length > m ? s.length : m);
    final rateW = widest(rates, 6), totalW = widest(totals, 7);
    const gstW = 4;
    // One space between each printed column (name, rate, total always print).
    final gaps = 2 +
        (settings.showSlNo ? 1 : 0) +
        (settings.showQuantity ? 1 : 0) +
        (showItemTax ? 1 : 0);
    final nameW = (width - slW - qtyW - rateW - (showItemTax ? gstW : 0) - totalW - gaps)
        .clamp(1, 999);
    final useTable = itemLayout != 'detailed';

    String singleLineRow(String sl, String name, String qty, String rate,
        String? gst, String total) {
      final parts = <String>[
        if (settings.showSlNo) padRight(sl, slW),
        padRight(name, nameW),
        if (settings.showQuantity) padCenter(qty, qtyW),
        padLeft(rate, rateW),
      ];
      if (gst != null) parts.add(padLeft(gst, gstW));
      parts.add(padLeft(total, totalW));
      return parts.join(' ');
    }

    if (useTable) {
      line(
          singleLineRow('Sl', 'Description', qtyLabel, 'Rate',
              showItemTax ? 'GST%' : null, 'Total'),
          bold: true);
    } else {
      twoCol(settings.showSlNo ? '# Item' : 'Item', 'Total', bold: true);
    }
    hr();
    var totalQuantity = 0.0;
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      totalQuantity += item.quantity;
      final qtyNum = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(2);
      final qtyUnit = item.effectiveUnit.trim().isEmpty
          ? qtyNum
          : '$qtyNum ${item.effectiveUnit}';
      // Table qty column is only qtyW chars — drop the unit rather than truncate it.
      final qty = !useTable || qtyUnit.length <= qtyW ? qtyUnit : qtyNum;
      final rate = rates[i];
      final total = totals[i];

      if (useTable) {
        line(singleLineRow('${i + 1}', item.product.name, qty, rate,
            showItemTax ? '${item.product.tax_rate}%' : null, total));
      } else {
        line(settings.showSlNo
            ? '${i + 1} ${item.product.name}'
            : item.product.name, bold: true);
        final detailParts = [
          if (settings.showQuantity) '$qtyLabel:$qty',
          'Rate:$rate',
        ];
        if (showItemTax) detailParts.add('${item.product.tax_rate}%');
        detailParts.add(total);
        line('  ${detailParts.join('  ')}');
      }
      if (settings.showGst && item.product.hsncode.trim().isNotEmpty) {
        line('  HSN: ${item.product.hsncode}');
      }
      if (settings.showDescription && item.printedDescription.isNotEmpty) {
        line('  ${item.printedDescription}');
      }
      if (settings.showDiscount && item.totalDiscount > 0) {
        line('  Disc: -${AmountFormat.money(item.totalDiscount)}'
            '${item.discountIsPercent ? ' (${item.discount == item.discount.roundToDouble() ? item.discount.toInt() : item.discount}%)' : ''}');
      }
    }
    hr();
    // Total qty sits under the Qty column (table) / the "Qty:" text (detailed).
    if (settings.showTotalQuantity && settings.showQuantity) {
      final totalQtyStr = totalQuantity == totalQuantity.roundToDouble()
          ? totalQuantity.toInt().toString()
          : totalQuantity.toStringAsFixed(2);
      if (useTable) {
        // Label spans the Sl + Description columns; columns right of Qty are
        // empty, so a total wider than qtyW can overflow instead of truncating.
        final labelW = slW + (settings.showSlNo ? 1 : 0) + nameW;
        final totalLabel = 'Total $qtyLabel';
        line('${padRight(labelW >= totalLabel.length ? totalLabel : 'Total', labelW)} '
            '${totalQtyStr.length >= qtyW ? totalQtyStr : padCenter(totalQtyStr, qtyW)}',
            bold: true);
      } else {
        line('  Total $qtyLabel:$totalQtyStr', bold: true);
      }
      hr();
    }

    // ── Totals ──
    if (invoice.totalDiscount > 0) {
      twoCol('Subtotal:', '$currency ${AmountFormat.money(invoice.grossSubtotal)}');
      twoCol('Discount:', '-$currency ${AmountFormat.money(invoice.totalDiscount)}');
    }
    if (invoice.taxMode != TaxMode.none) {
      twoCol(invoiceTaxLabel(invoice), '$currency ${AmountFormat.money(invoice.tax)}');
    }
    for (final c in invoice.additionalCosts) {
      twoCol(
          c.label.isEmpty ? 'Extra Cost' : c.label,
          c.amount < 0
              ? '-$currency ${AmountFormat.money(-c.amount)}'
              : '$currency ${AmountFormat.money(c.amount)}');
    }
    if (invoice.invoiceDiscountAmount > 0) {
      twoCol(
          invoice.invoiceDiscountType == InvoiceDiscountType.percent
              ? 'Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%)'
              : 'Extra Discount',
          '-$currency ${AmountFormat.money(invoice.invoiceDiscountAmount)}');
    }
    twoCol(
      'TOTAL',
      '$currency ${AmountFormat.money(invoice.total)}',
      bold: true,
    );
    if (effectivePreviousBalance > 0) {
      twoCol('Prev Balance Due:',
          '$currency ${AmountFormat.money(effectivePreviousBalance)}');
      twoCol('Total Due',
          '$currency ${AmountFormat.money(invoice.total + effectivePreviousBalance)}',
          bold: true);
    }
    if (settings.showRoundOff) {
      final netTotal = roundNetTotal(invoice.total + effectivePreviousBalance);
      twoCol('Round off:', '$currency ${AmountFormat.money(netTotal.roundOff)}');
      twoCol('NET AMOUNT', '$currency ${AmountFormat.money(netTotal.rounded)}',
          bold: true);
      line(AmountInWords.amount(netTotal.rounded,
          indian: invoice.currencyCode == 'INR'));
    }

    if (invoice.taxMode != TaxMode.none && invoice.tax > 0) {
      final isIndia = (company?.country ?? '').isEmpty ||
          company!.country.toLowerCase() == 'india';
      hr();
      line('=== TAX SUMMARY ===', align: PosAlign.center, bold: true);
      twoCol('Taxable Amt:', '$currency ${AmountFormat.money(invoice.subtotal)}');
      if (settings.showCgstSgst && isIndia && invoice.isInterState) {
        twoCol('IGST:', '$currency ${AmountFormat.money(invoice.tax)}');
      } else if (settings.showCgstSgst && isIndia) {
        twoCol('SGST:', '$currency ${AmountFormat.money(invoice.tax / 2)}');
        twoCol('CGST:', '$currency ${AmountFormat.money(invoice.tax / 2)}');
      }
      twoCol('Total Tax:', '$currency ${AmountFormat.money(invoice.tax)}');
    }

    if (invoice.amountPaid > 0) {
      hr();
      twoCol('Paid:', '$currency ${AmountFormat.money(invoice.amountPaid)}');
      if (invoice.outstandingBalance <= 0) {
        twoCol('PAID IN FULL', '', bold: true);
      } else {
        twoCol('Balance Due', '$currency ${AmountFormat.money(invoice.outstandingBalance)}',
            bold: true);
      }
    }

    // ── Credit / Debit Note info (against invoice, reason, refunds) ──
    final returnLines = returnInfoLines(invoice);
    if (returnLines.isNotEmpty) {
      hr();
      for (final l in returnLines) {
        line(l, bold: true);
      }
    }

    // ── Notes ──
    if ((invoice.notes ?? '').isNotEmpty) {
      hr();
      line('NOTES', bold: true);
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

    // generator.cut() forces 5 blank lines internally before cutting, with
    // no way to configure that. Reverse-feed 3 lines first to shrink the
    // net visible gap to ~2 lines. Requires printer support for ESC/POS
    // reverse feed (most auto-cutter printers have it, but not guaranteed).
    bytes += generator.reverseFeed(3);
    bytes += generator.cut();
    return _stripKanjiCancel(bytes);
  }

  /// The ESC/POS library emits `FS .` (bytes 0x1C 0x2E — "Cancel Kanji
  /// Character Mode") before every single text call, unconditionally, even
  /// though we never use Kanji mode. Some printers (e.g. WOOSIM WSP-R241)
  /// don't recognize 0x1C as a command byte, drop it, and print the
  /// following 0x2E as a literal '.' — showing up as a stray dot at the
  /// start of every line. Safe to strip: 0x1C never appears in our own
  /// text content (it's a non-printable control byte).
  static List<int> _stripKanjiCancel(List<int> bytes) {
    final result = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0x1C && i + 1 < bytes.length && bytes[i + 1] == 0x2E) {
        i++;
        continue;
      }
      result.add(bytes[i]);
    }
    return result;
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
