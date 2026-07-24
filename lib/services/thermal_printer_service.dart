import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:invoiso/services/backend_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_widgets.dart' show invoiceTaxLabel;
import 'package:thermal_printer/thermal_printer.dart';
import 'package:invoiso/constants.dart';

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
    final settings = await PDFService.fetchPdfSettings(datePattern: dateFmt.key);
    final previousBalanceDue = settings.showPreviousBalance
        ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
        : 0.0;
    final effectivePreviousBalance =
        settings.showPreviousBalance ? previousBalanceDue : 0.0;

    final is58 = settings.pageSize == PageSize.thermal58;
    final bool showNameAlias = await BackendServices.settings.getShowAliasNameInPdf();

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

    final showItemTax = invoice.taxMode == TaxMode.perItem;
    List<int> bytes = [];

    // Printer's codepage (CP437/1252 etc) can't encode most local-language
    // scripts (Devanagari, Tamil, Arabic...) — generator.text() throws
    // "Contains invalid characters" for them. For those lines only, render
    // the text to a bitmap (any Unicode font Flutter can shape) and send it
    // as an image instead; plain ASCII/Latin1 lines keep the fast text path.
    bool hasNonLatin1(String s) => s.codeUnits.any((c) => c > 0xFF);

    // Must be a multiple of 8 — flutter_esc_pos_utils' _toRasterFormat()
    // rebuilds its byte buffer as a fixed-length list when width % 8 != 0,
    // then keeps appending to it, throwing "Cannot add to a fixed-length list".
    final widthPx = ((is58 ? 372 : 558) / 8).ceil() * 8;
    const supersample = 2;
    const nameFontScale = 1.18;

    Future<void> textLine(String text, {PosAlign align = PosAlign.left, bool bold = false,bool isHead = false})
    {
      if(isHead) {
        bytes += generator.text(text, styles: PosStyles(align: align, bold: bold,height: PosTextSize.size2,width: PosTextSize.size1,));
      } else {
        bytes += generator.text(text, styles: PosStyles(align: align, bold: bold,));
      }
      return Future.value();
    }

    // ESC/POS Font A default row = 24 dots tall; isHead uses PosTextSize.size2
    // (double height) = 48 dots. Render bitmap rows to those exact heights,
    // vertically centering the glyph, so image rows match plain-text rows
    // instead of towering over them.
    // Rendered at [supersample]x then downscaled with area-averaging before
    // the ESC/POS lib's hard 127 b/w threshold — anti-aliased glyph edges
    // land on a cleaner cutoff instead of the ragged/blurry look a direct
    // 1x render+threshold produces on thermal hardware.
    Future<void> imageLine(String text, {PosAlign align = PosAlign.left, bool bold = false, double rowHeightPx = PdfLayout.thermalPrinterItemFontSize, double fontScale = 1.0}) async {
      final uiAlign = align == PosAlign.center
          ? ui.TextAlign.center
          : align == PosAlign.right
              ? ui.TextAlign.right
              : ui.TextAlign.left;
      final renderWidthPx = widthPx * supersample;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: rowHeightPx * 0.72 * supersample * fontScale,
            height: 1.0,
            color: Colors.black,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textAlign: uiAlign,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: renderWidthPx.toDouble());

      final h = max(rowHeightPx * supersample, painter.height).ceilToDouble();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(Rect.fromLTWH(0, 0, renderWidthPx.toDouble(), h), Paint()..color = Colors.white);
      painter.paint(canvas, Offset(0, (h - painter.height) / 2));
      final uiImage = await recorder.endRecording().toImage(renderWidthPx, h.ceil());
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final png = byteData!.buffer.asUint8List();
      final decoded = img.decodePng(Uint8List.fromList(png));
      if (decoded != null) {
        final resized = img.copyResize(decoded,
            width: widthPx,
            height: (h / supersample).ceil(),
            interpolation: img.Interpolation.average);
        bytes += generator.imageRaster(resized, align: align);
      }
    }

    // Multi-column item row (Sl/Name/Qty/Rate/[GST]/Total) rendered as one
    // bitmap when the name has non-Latin1 chars. singleLineRow()'s space
    // padding assumes 1 char == 1 fixed-width column, which only holds for
    // generator.text()'s monospace font — a proportional font (needed to
    // shape Devanagari etc) breaks that assumption and drifts columns out
    // of alignment. Fix: give every cell its own pixel-exact column box
    // (charWidthPx = widthPx / width) instead of relying on padded spaces.
    // Same supersample-then-average-downscale trick as imageLine(), plus
    // an optional per-cell font bump (used to make the product name column
    // read a little larger than Sl/Qty/Rate/Total without resizing the row).
    Future<void> imageTableRow(
        List<(String text, int startChar, int widthChar, ui.TextAlign align)> cells,
        {bool bold = false, double rowHeightPx = PdfLayout.thermalPrinterItemFontSize,
        int nameCellIndex = -1, double nameFontScale = 1.0}) async {
      final renderWidthPx = widthPx * supersample;
      final charWidthPx = renderWidthPx / width;
      final baseFontPx = rowHeightPx * 0.72 * supersample;
      final nameFontPx = baseFontPx * nameFontScale;

      final painters = <TextPainter>[];
      double maxHeight = rowHeightPx * supersample;
      for (var idx = 0; idx < cells.length; idx++) {
        final cell = cells[idx];
        final colWidthPx = cell.$3 * charWidthPx;
        final painter = TextPainter(
          text: TextSpan(
            text: cell.$1,
            style: TextStyle(
              fontSize: idx == nameCellIndex ? nameFontPx : baseFontPx,
              height: 1.0,
              color: Colors.black,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textAlign: cell.$4,
          textDirection: ui.TextDirection.ltr,
          // No maxLines/ellipsis — a cell too wide for its column (long
          // name, or a number with more digits than expected) wraps onto a
          // second line within the column instead of losing characters;
          // maxHeight below grows to fit it.
        )..layout(minWidth: colWidthPx, maxWidth: colWidthPx);
        painters.add(painter);
        if (painter.height > maxHeight) maxHeight = painter.height;
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(Rect.fromLTWH(0, 0, renderWidthPx.toDouble(), maxHeight),
          Paint()..color = Colors.white);
      for (var idx = 0; idx < cells.length; idx++) {
        final cell = cells[idx];
        final painter = painters[idx];
        painter.paint(canvas,
            Offset(cell.$2 * charWidthPx, (maxHeight - painter.height) / 2));
      }
      final uiImage =
          await recorder.endRecording().toImage(renderWidthPx.round(), maxHeight.ceil());
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      final png = byteData!.buffer.asUint8List();
      final decoded = img.decodePng(Uint8List.fromList(png));
      if (decoded != null) {
        final resized = img.copyResize(decoded,
            width: widthPx,
            height: (maxHeight / supersample).ceil(),
            interpolation: img.Interpolation.average);
        bytes += generator.imageRaster(resized, align: PosAlign.left);
      }
    }

    Future<void> line(String text, {PosAlign align = PosAlign.left, bool bold = false, bool isHead = false, double fontScale = 1.0}) {
      return hasNonLatin1(text)
          ? imageLine(text,
              align: align,
              bold: bold,
              rowHeightPx: isHead ? PdfLayout.thermalPrinterHeadFontSize : PdfLayout.thermalPrinterItemFontSize,
              fontScale: fontScale)
          : textLine(text, align: align, bold: bold, isHead: isHead);
    }

    Future<void> twoCol(String left, String right, {bool bold = false}) {
      final pad = width - left.length - right.length;
      final text = pad > 0 ? '$left${' ' * pad}$right' : '$left $right';
      return line(text, bold: bold);
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
    // Never cut qty/rate/total — dropping leading digits silently changes
    // the value shown on the invoice. Pad when it fits; let it run past
    // the column (shifting later cells on that one row) when it doesn't.
    String padLeft(String s, int w) =>
        s.length >= w ? s : ' ' * (w - s.length) + s;
    String padCenter(String s, int w) {
      if (s.length >= w) return s;
      final totalPad = w - s.length;
      final left = totalPad ~/ 2;
      return ' ' * left + s + ' ' * (totalPad - left);
    }

    // ── Business header ──
    if ((company?.name ?? '').isNotEmpty) {
      await line(company!.name, align: PosAlign.center, bold: true,isHead: true);
    }
    if ((company?.address ?? '').isNotEmpty) {
      await line(company!.address, align: PosAlign.center);
    }
    if ((company?.phone ?? '').isNotEmpty) {
      await line('Ph: ${company!.phone}', align: PosAlign.center);
    }
    if (settings.showGst && (company?.gstin ?? '').isNotEmpty) {
      await line('${taxLabel(company?.country)}: ${company!.gstin}',
          align: PosAlign.center);
    }
    hr();
    await line(invoice.type.toUpperCase(), align: PosAlign.center, bold: true);
    hr();

    // ── Invoice meta ──
    final dateFormatter = DateFormat(dateFmt.key);
    final dateStr = dateFormatter.format(invoice.date);
    await twoCol('Inv No: ${settings.invoicePrefix}${invoice.invoiceNumber ?? invoice.id}',
        'Date: $dateStr');
    if (invoice.dueDate != null) {
      await twoCol('Due:', dateFormatter.format(invoice.dueDate!));
    }
    hr();

    // ── Customer ──
    await line('Name: ${invoice.customer.name}', bold: true);
    if (invoice.customer.businessName.isNotEmpty) {
      await line(invoice.customer.businessName);
    }
    if (invoice.customer.phone.isNotEmpty) {
      await line('Ph: ${invoice.customer.phone}');
    }
    if (settings.showGst && invoice.customer.gstin.isNotEmpty) {
      await line('${taxLabel(company?.country)}: ${invoice.customer.gstin}');
    }
    hr();

    // ── Items ──
    // Table layout: compact column widths, tight enough to still fit on
    // 58mm (31 chars). Tune these to rebalance space between the fixed
    // Sl/Qty/Rate/GST/Total columns and the product name. Name doesn't need
    // generous room any more — it wraps/overflows onto its own line when it
    // doesn't fit (see the `name.length > nameW` branch below) — so
    // `nameWMax` caps it and any leftover width goes to the numeric columns
    // instead of just padding the name.
    const slW = 3;
    const qtyW = 5;
    const rateW = 10;
    const gstW = 4;
    const totalW = 10;
    const nameWMax = 18;
    final gaps = showItemTax ? 5 : 4;
    final nameW = (width - slW - qtyW - rateW - (showItemTax ? gstW : 0) - totalW - gaps)
        .clamp(1, nameWMax);
    final useTable = itemLayout != 'detailed';

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

    if (useTable) {
      await line(
          singleLineRow('Sl', 'Description', 'Qty', 'Rate',
              showItemTax ? 'GST%' : null, 'Total'),
          bold: true);
    } else {
      await twoCol('# Item', 'Total', bold: true);
    }
    hr();
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final unit = item.effectiveUnit.trim().isEmpty ? '' : item.effectiveUnit;
      final qty = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString() + unit
          : item.quantity.toStringAsFixed(2) + unit;
      final rate = item.effectivePrice.toStringAsFixed(2);
      final total = item.total.toStringAsFixed(2);

      if (useTable) {
        final name = item.product.displayName(showNameAlias);
        final gstStr = showItemTax ? '${item.product.tax_rate}%' : null;
        if (name.length > nameW) {
          // Name doesn't fit its column — show it in full on its own line,
          // then Qty/Rate/[GST]/Total on the next line, still lined up
          // under their normal columns.
          if (hasNonLatin1(name)) {
            // Same pixel-exact column math as the normal row below (not
            // imageLine()+padRight — that pads with proportional-font space
            // characters, which doesn't land on the same pixel column as
            // the fixed-width cells elsewhere).
            await imageTableRow([
              ('${i + 1}', 0, slW, ui.TextAlign.left),
              (name, slW + 1, width - slW - 1, ui.TextAlign.left),
            ], bold: false, nameCellIndex: 1, nameFontScale: nameFontScale);
          } else {
            // Plain ASCII — generator.text()'s monospace font makes
            // char-count padding already pixel-exact.
            await line('${padRight('${i + 1}', slW)} $name');
          }
          await line(singleLineRow('', '', qty, rate, gstStr, total));
        } else if (hasNonLatin1(name)) {
          int col = 0;
          final slStart = col; col += slW + 1;
          final nameStart = col; col += nameW + 1;
          final qtyStart = col; col += qtyW + 1;
          final rateStart = col; col += rateW + 1;
          int gstStart = col;
          if (showItemTax) col += gstW + 1;
          final totalStart = col;
          await imageTableRow([
            ('${i + 1}', slStart, slW, ui.TextAlign.left),
            (name, nameStart, nameW, ui.TextAlign.left),
            (qty, qtyStart, qtyW, ui.TextAlign.center),
            (rate, rateStart, rateW, ui.TextAlign.right),
            if (gstStr != null)
              (gstStr, gstStart, gstW, ui.TextAlign.right),
            (total, totalStart, totalW, ui.TextAlign.right),
          ],
          bold: false, nameCellIndex: 1, nameFontScale: nameFontScale);
        } else {
          await line(singleLineRow('${i + 1}', name, qty, rate, gstStr, total));
        }
      } else {
        try
        {
          await line('${i + 1} ${item.product.displayName(showNameAlias)}', bold: false, fontScale: nameFontScale);
        }
        catch(e)
        {
          if(kDebugMode)print(e);
          await line('${i + 1} ${item.product.displayName(false)}', bold: false, fontScale: nameFontScale);
        }
        final detailParts = ['Qty:$qty', 'Rate:$rate'];
        if (showItemTax) detailParts.add('${item.product.tax_rate}%');
        detailParts.add(total);
        await line('  ${detailParts.join('  ')}');
      }
      if (settings.showDiscount && item.totalDiscount > 0) {
        await line('  Disc: -${item.totalDiscount.toStringAsFixed(2)}');
      }
    }
    hr();

    // ── Totals ──
    if (invoice.totalDiscount > 0) {
      await twoCol('Subtotal:', '$currency ${invoice.grossSubtotal.toStringAsFixed(2)}');
      await twoCol('Discount:', '-$currency ${invoice.totalDiscount.toStringAsFixed(2)}');
    }
    if (invoice.taxMode != TaxMode.none) {
      await twoCol(invoiceTaxLabel(invoice), '$currency ${invoice.tax.toStringAsFixed(2)}');
    }
    for (final c in invoice.additionalCosts) {
      await twoCol(c.label.isEmpty ? 'Extra Cost' : c.label,
          '$currency ${c.amount.toStringAsFixed(2)}');
    }
    if (effectivePreviousBalance > 0) {
      await twoCol('Prev Balance:',
          '$currency ${effectivePreviousBalance.toStringAsFixed(2)}');
    }
    await twoCol(
      'TOTAL',
      '$currency ${(invoice.total + effectivePreviousBalance).toStringAsFixed(2)}',
      bold: true,
    );

    if (invoice.taxMode != TaxMode.none && invoice.tax > 0) {
      final isIndia = (company?.country ?? '').isEmpty ||
          company!.country.toLowerCase() == 'india';
      hr();
      await line('=== TAX SUMMARY ===', align: PosAlign.center, bold: true);
      await twoCol('Taxable Amt:', '$currency ${invoice.subtotal.toStringAsFixed(2)}');
      if (isIndia) {
        await twoCol('SGST:', '$currency ${(invoice.tax / 2).toStringAsFixed(2)}');
        await twoCol('CGST:', '$currency ${(invoice.tax / 2).toStringAsFixed(2)}');
      }
      await twoCol('Total Tax:', '$currency ${invoice.tax.toStringAsFixed(2)}');
    }

    if (invoice.amountPaid > 0) {
      hr();
      await twoCol('Paid:', '$currency ${invoice.amountPaid.toStringAsFixed(2)}');
      if (invoice.outstandingBalance <= 0) {
        await twoCol('PAID IN FULL', '', bold: true);
      } else {
        await twoCol('Balance Due', '$currency ${invoice.outstandingBalance.toStringAsFixed(2)}',
            bold: true);
      }
    }

    // ── Notes ──
    if ((invoice.notes ?? '').isNotEmpty) {
      hr();
      await line(invoice.notes!);
    }

    // ── Footer ──
    hr();
    if (settings.thankYouNote.isNotEmpty) {
      await line(settings.thankYouNote, align: PosAlign.center, bold: true);
    }
    if (settings.showFooterBranding) {
      await line('Generated by Invoiso', align: PosAlign.center);
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
      if(kDebugMode)print(e);
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
