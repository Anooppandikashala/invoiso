import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:invoiso/services/backend_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyDownEvent;
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/network/network_print_result.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';
import 'package:invoiso/services/pdf/pdf_widgets.dart' show invoiceTaxLabel, roundNetTotal;
import 'package:invoiso/utils/amount_in_words.dart';
import 'package:invoiso/common/constants.dart';

/// Prints receipts by rendering a real Flutter widget tree to a bitmap and
/// sending it as an ESC/POS raster image, instead of building ESC/POS text
/// commands by hand. This is what fixes both: 1) tables — Flutter's own
/// Table/Text layout replaces manual char-grid math and
/// generator.row()/PosColumn (which produced broken layout on real
/// printers); 2) character encoding — Flutter renders any Unicode script
/// the app's fonts support, so there's no ESC/POS codepage limitation to
/// work around for non-Latin1 text.
class ThermalPrinterService {
  // Populated by _deviceCacheSub as scans complete, so re-opening the print
  // dialog can show known devices instantly instead of forcing a fresh scan
  // every time.
  static List<Printer> _cachedDevices = [];
  static StreamSubscription<List<Printer>>? _deviceCacheSub;

  static void _ensureDeviceCacheListener(FlutterThermalPrinter printer) {
    _deviceCacheSub ??= printer.devicesStream.listen((devices) {
      _cachedDevices = devices;
    });
  }

  static Future<void> _saveLastUsedPrinter(Printer p) async {
    try {
      await BackendServices.settings
          .setSetting(SettingKey.lastUsedThermalPrinter, jsonEncode(p.toJson()));
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  static Future<String?> _getLastUsedPrinterAddress() async {
    final raw = await BackendServices.settings
        .getSetting(SettingKey.lastUsedThermalPrinter);
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)['address'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> printInvoice(
      BuildContext context, Invoice invoice) async {
    final printer = FlutterThermalPrinter.instance;
    _ensureDeviceCacheListener(printer);
    // Skip the auto-scan if we already have devices from a previous scan
    // this session — manual "Rescan" button covers switching printers.
    final scanDone = ValueNotifier<bool>(_cachedDevices.isNotEmpty);
    final lastUsedAddress = await _getLastUsedPrinterAddress();
    if (!context.mounted) return;

    Future<void> scan() {
      scanDone.value = false;
      return printer
          .getPrinters(connectionTypes: [ConnectionType.USB])
          .catchError((e) {
        if (kDebugMode) print(e);
        if (!context.mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Failed to scan for printers: $e')),
        );
      }).whenComplete(() => scanDone.value = true);
    }

    if (_cachedDevices.isEmpty) {
      unawaited(scan());
    }

    var useTextMode = false;
    var showDummyPrinter = false;
    var selectedIndex = 0;
    final listFocusNode = FocusNode();
    final dummyPrinter = Printer(
      address: 'DUMMY-TEST-PRINTER',
      name: 'Test Printer (dummy)',
      connectionType: ConnectionType.USB,
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Print Receipt')),
            ValueListenableBuilder<bool>(
              valueListenable: scanDone,
              builder: (context, done, _) => IconButton(
                tooltip: 'Rescan for printers',
                onPressed: done ? () => unawaited(scan()) : null,
                icon: done
                    ? const Icon(Icons.refresh)
                    : const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kDebugMode)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Text mode (test)'),
                  subtitle: const Text('generator.text()/row() instead of image widget'),
                  value: useTextMode,
                  onChanged: (v) => setState(() => useTextMode = v),
                ),
              if (kDebugMode)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show dummy printer (debug)'),
                  subtitle: const Text(
                      'Fake "last used" entry, to check UI without real hardware'),
                  value: showDummyPrinter,
                  onChanged: (v) => setState(() => showDummyPrinter = v),
                ),
              const Text('USB Printers',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<Printer>>(
                stream: printer.devicesStream,
                initialData: _cachedDevices,
                builder: (context, snapshot) {
                  final discovered =
                      List<Printer>.from(snapshot.data ?? const <Printer>[]);
                  if (kDebugMode && showDummyPrinter) {
                    discovered.add(dummyPrinter);
                  }
                  final effectiveLastUsedAddress = (kDebugMode && showDummyPrinter)
                      ? dummyPrinter.address
                      : lastUsedAddress;
                  if (effectiveLastUsedAddress != null) {
                    discovered.sort((a, b) {
                      if (a.address == effectiveLastUsedAddress) return -1;
                      if (b.address == effectiveLastUsedAddress) return 1;
                      return 0;
                    });
                  }
                  if (discovered.isEmpty) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: scanDone,
                      builder: (context, done, _) {
                        if (done) {
                          return const Text('No USB printers found.');
                        }
                        return const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Scanning for USB printers...'),
                          ],
                        );
                      },
                    );
                  }
                  if (selectedIndex >= discovered.length) selectedIndex = 0;

                  Future<void> selectPrinter(Printer p) async {
                    Navigator.pop(dialogContext);
                    if (kDebugMode && p.address == dummyPrinter.address) {
                      // Dummy entry — just for checking the
                      // "Last used" highlight UI, no real device
                      // to print to.
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Dummy printer tapped — highlight UI check only, not a real print.')),
                      );
                      return;
                    }
                    _ReceiptSettings settings;
                    try {
                      settings = await _fetchReceiptSettings(invoice);
                    } catch (e) {
                      if (kDebugMode) print(e);
                      if (!context.mounted) return;
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text('Print failed: $e')),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    // useTextMode (debug-only) forces plain
                    // ESC/POS text regardless of content, for
                    // manually testing that path. Otherwise
                    // auto-pick: image widget only when the
                    // receipt actually has non-Latin1 text.
                    final useImage = useTextMode ? false : true;
                    // TODO - We can use this later if any user complaint about the printing speed
                    //_receiptHasNonLatin1(invoice, settings);
                    if (useImage) {
                      await _printToDevice(
                          context: context,
                          device: p,
                          invoice: invoice,
                          settingsOverride: settings);
                    } else {
                      await _printToDeviceText(
                          context: context,
                          device: p,
                          invoice: invoice,
                          settingsOverride: settings);
                    }
                  }

                  return Focus(
                    focusNode: listFocusNode,
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() =>
                            selectedIndex = (selectedIndex + 1) % discovered.length);
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() => selectedIndex =
                            (selectedIndex - 1 + discovered.length) % discovered.length);
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                        unawaited(selectPrinter(discovered[selectedIndex]));
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: discovered
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final p = entry.value;
                            final isLastUsed = p.address == effectiveLastUsedAddress;
                            final isKeyboardSelected = index == selectedIndex;
                            return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                selected: isKeyboardSelected,
                                selectedTileColor:
                                    Theme.of(context).primaryColor.withValues(alpha: 0.08),
                                tileColor: isLastUsed
                                    ? Colors.green.withValues(alpha: 0.08)
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: isKeyboardSelected
                                      ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
                                      : isLastUsed
                                          ? BorderSide(
                                              color: Colors.green.withValues(alpha: 0.4))
                                          : BorderSide.none,
                                ),
                                leading: isLastUsed
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20)
                                    : const SizedBox(width: 20),
                                title: Text(p.name ?? 'Unknown printer'),
                                subtitle: isLastUsed
                                    ? const Text('Last used',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600))
                                    : null,
                                onTap: () {
                                  setState(() => selectedIndex = index);
                                  unawaited(selectPrinter(p));
                                },
                              );
                          })
                          .toList(),
                    ),
                  );
                },
              ),
              if (kDebugMode) ...[
                const Divider(height: 24),
                const Text('Test via network (e.g. local ESC/POS listener)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _NetworkPrintRow(invoice: invoice, useTextMode: useTextMode),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              printer.stopScan().catchError((e) {
                if (kDebugMode) print(e);
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Close'),
          ),
        ],
        ),
      ),
    );
    listFocusNode.dispose();
  }

  static Future<void> _printToDevice({
    required BuildContext context,
    required Printer device,
    required Invoice invoice,
    _ReceiptSettings? settingsOverride,
  }) async {
    final printer = FlutterThermalPrinter.instance;
    try {
      final settings = settingsOverride ?? await _fetchReceiptSettings(invoice);
      if (!context.mounted) return;
      final widget = await _buildReceiptWidget(invoice, settings);
      if (!context.mounted) return;
      await printer.connect(device);
      if (!context.mounted) return;
      await printer.printWidget(
        context,
        printer: device,
        widget: widget,
        paperSize: settings.paperSize,
      );
      await printer.disconnect(device);
      unawaited(_saveLastUsedPrinter(device));
    } catch (e) {
      if (kDebugMode) print(e);
      // Device may have been unplugged/removed since it was cached — drop
      // the cache so the next dialog open does a real rescan instead of
      // showing this dead entry again.
      _cachedDevices = [];
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
              'Print failed: $e\nCheck the printer is connected, then try again.'),
        ),
      );
    }
  }

  /// TEST-ONLY: plain ESC/POS text printing (generator.text()/row()),
  /// instead of the image-widget path above. Toggle "Text mode (test)" in
  /// the print dialog to try this instead — lets you compare on real
  /// hardware whether generator.row()/PosColumn table layout (broken on
  /// real printers in the old thermal_printer lib) works now, and whether
  /// generator.text() throws on non-Latin1 content in this lib too.
  static Future<void> _printToDeviceText({
    required BuildContext context,
    required Printer device,
    required Invoice invoice,
    _ReceiptSettings? settingsOverride,
  }) async
  {
    final printer = FlutterThermalPrinter.instance;
    try {
      final settings = settingsOverride ?? await _fetchReceiptSettings(invoice);
      final bytes = await _buildReceiptBytesText(invoice, settings);
      await printer.connect(device);
      await printer.printData(device, bytes);
      await printer.disconnect(device);
      unawaited(_saveLastUsedPrinter(device));
    } catch (e) {
      if (kDebugMode) print(e);
      // Device may have been unplugged/removed since it was cached — drop
      // the cache so the next dialog open does a real rescan instead of
      // showing this dead entry again.
      _cachedDevices = [];
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
              'Print failed: $e\nCheck the printer is connected, then try again.'),
        ),
      );
    }
  }

  static Future<void> _printToNetworkText({
    required String ip,
    required int port,
    required Invoice invoice,
    _ReceiptSettings? settingsOverride,
  }) async {
    final settings = settingsOverride ?? await _fetchReceiptSettings(invoice);
    final bytes = await _buildReceiptBytesText(invoice, settings);
    final result =
        await FlutterThermalPrinterNetwork(ip, port: port).printTicket(bytes);
    if (result != NetworkPrintResult.success) {
      throw Exception('Network print failed: $result');
    }
  }

  static Future<List<int>> _buildReceiptBytesText(
      Invoice invoice, _ReceiptSettings s) async
{
    final settings = s.pdf;
    final currency = invoice.currencySymbol;
    final company = settings.company;
    final isIndia = (company?.country ?? '').isEmpty ||
        company!.country.toLowerCase() == 'india';

    final profile = await CapabilityProfile.load();
    final generator = Generator(s.paperSize, profile);
    List<int> bytes = [];

    final title = (invoice.invoiceTitle?.trim().isNotEmpty ?? false)
        ? invoice.invoiceTitle!.toUpperCase()
        : invoice.type.toUpperCase();

    void line(String text, {PosAlign align = PosAlign.left, bool bold = false}) {
      bytes += generator.text(text, styles: PosStyles(align: align, bold: bold));
    }

    void twoCol(String left, String right, {bool bold = false}) {
      bytes += generator.row([
        PosColumn(
            text: left,
            width: 8,
            styles: PosStyles(align: PosAlign.left, bold: bold)),
        PosColumn(
            text: right,
            width: 4,
            styles: PosStyles(align: PosAlign.right, bold: bold)),
      ]);
    }

    void hr() => bytes += generator.hr();

    if ((company?.name ?? '').isNotEmpty) {
      line(company!.name, align: PosAlign.center, bold: true);
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
    line(title, align: PosAlign.center, bold: true);
    hr();

    twoCol('Inv No: ${settings.invoicePrefix}${invoice.invoiceNumber ?? invoice.id}',
        'Date: ${s.dateFmt.format(invoice.date)}');
    if (invoice.dueDate != null) {
      twoCol('Due:', s.dateFmt.format(invoice.dueDate!));
    }
    hr();

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

    // Item table via generator.row()/PosColumn — the feature the old lib
    // broke on real hardware. Testing whether it works here.
    bytes += generator.row([
      PosColumn(text: 'Sl', width: 1, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Item', width: 5, styles: const PosStyles(bold: true)),
      PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(
          text: 'Rate',
          width: 2,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(
          text: 'Total',
          width: 2,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    hr();
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final unit = item.effectiveUnit.trim().isEmpty ? '' : item.effectiveUnit;
      final qty = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString() + unit
          : item.quantity.toStringAsFixed(2) + unit;
      final rate = item.effectivePrice.toStringAsFixed(2);
      final total = item.total.toStringAsFixed(2);
      final name = item.product.displayName(s.showNameAlias);
      try {
        bytes += generator.row([
          PosColumn(text: '${i + 1}', width: 1),
          PosColumn(text: name, width: 5),
          PosColumn(text: qty, width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: rate, width: 2, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: total, width: 2, styles: const PosStyles(align: PosAlign.right)),
        ]);
      } catch (e) {
        // generator.text()/row() throws on non-Latin1 content (codepage
        // limitation) — exactly the case this test function exists to
        // surface, so log instead of silently rendering blank.
        if (kDebugMode) print('row failed for "$name": $e');
        line('${i + 1} $name (encoding failed: $e)');
      }
      if (settings.showDiscount && item.totalDiscount > 0) {
        line('  Disc: -${item.totalDiscount.toStringAsFixed(2)}');
      }
    }
    hr();

    if (invoice.totalDiscount > 0) {
      twoCol('Subtotal:', '$currency ${invoice.grossSubtotal.toStringAsFixed(2)}');
      twoCol('Discount:', '-$currency ${invoice.totalDiscount.toStringAsFixed(2)}');
    }
    if (invoice.taxMode != TaxMode.none) {
      twoCol(invoiceTaxLabel(invoice), '$currency ${invoice.tax.toStringAsFixed(2)}');
    }
    if (invoice.taxMode != TaxMode.none && isIndia && settings.showCgstSgst) {
      twoCol('SGST:', '$currency ${(invoice.tax / 2).toStringAsFixed(2)}');
      twoCol('CGST:', '$currency ${(invoice.tax / 2).toStringAsFixed(2)}');
    }
    for (final c in invoice.additionalCosts) {
      twoCol(c.label.isEmpty ? 'Extra Cost' : c.label,
          '$currency ${c.amount.toStringAsFixed(2)}');
    }
    if (s.previousBalance > 0) {
      twoCol('Prev Balance:', '$currency ${s.previousBalance.toStringAsFixed(2)}');
    }
    if (invoice.invoiceDiscountAmount > 0)
    {
      twoCol(invoice.invoiceDiscountType == InvoiceDiscountType.percent
          ? "Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%)"
          : "Extra Discount ",
          "-$currency ${invoice.invoiceDiscountAmount.toStringAsFixed(2)}");
    }
    twoCol('TOTAL', '$currency ${(invoice.total + s.previousBalance).toStringAsFixed(2)}',
        bold: true);

    if (settings.showRoundOff) {
      final net = roundNetTotal(invoice.total + s.previousBalance);
      twoCol('Round off:', '$currency ${net.roundOff.toStringAsFixed(2)}');
      twoCol('Net Amount:', '$currency ${net.rounded.toStringAsFixed(2)}', bold: true);
      hr();
      line(AmountInWords.amount(net.rounded), align: PosAlign.left);
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

    hr();
    if (settings.thankYouNote.isNotEmpty) {
      line(settings.thankYouNote, align: PosAlign.center, bold: true);
    }
    if (settings.showFooterBranding) {
      line('Generated by Invoiso', align: PosAlign.center);
    }

    bytes += generator.cut();
    return bytes;
  }

  static Future<void> _printToNetwork({
    required BuildContext context,
    required String ip,
    required int port,
    required Invoice invoice,
    _ReceiptSettings? settingsOverride,
  }) async
  {
    final settings = settingsOverride ?? await _fetchReceiptSettings(invoice);
    if (!context.mounted) return;
    final widget = await _buildReceiptWidget(invoice, settings);
    if (!context.mounted) return;
    final profile = await CapabilityProfile.load();
    final generator = Generator(settings.paperSize, profile);
    if (!context.mounted) return;
    final bytes = await FlutterThermalPrinter.instance.screenShotWidget(
      context,
      widget: widget,
      paperSize: settings.paperSize,
      customWidth: settings.widthPx,
      generator: generator,
    );
    final result = await FlutterThermalPrinterNetwork(ip, port: port)
        .printTicket([...bytes, ...generator.cut()]);
    if (result != NetworkPrintResult.success) {
      throw Exception('Network print failed: $result');
    }
  }

  /// Mirrors [PDFService.generateInvoicePDF]'s content exactly (same
  /// settings fetch, same fields shown/hidden) so the printout matches the
  /// PDF preview.
  static Future<_ReceiptSettings> _fetchReceiptSettings(
      Invoice invoice) async {
    final dateFmt = await BackendServices.settings.getDateFormat();
    final settings =
        await PDFService.fetchPdfSettings(datePattern: dateFmt.key);
    final previousBalanceDue = settings.showPreviousBalance
        ? await BackendServices.invoices.getPreviousBalanceDueForInvoice(invoice)
        : 0.0;

    final is58 = settings.pageSize == PageSize.thermal58;
    final showNameAlias = await BackendServices.settings.getShowAliasNameInPdf();
    final itemLayout =
        await BackendServices.settings.getSetting(SettingKey.thermalItemLayout) ?? 'table';

    // 384/576 px = the real dot-width of 58mm/80mm printer heads at 203dpi.
    // Must be a multiple of 8 (thermal raster requirement).
    final widthPx = ((is58 ? 384 : 576) / 8).ceil() * 8;

    return _ReceiptSettings(
      pdf: settings,
      dateFmt: DateFormat(dateFmt.key),
      previousBalance: settings.showPreviousBalance ? previousBalanceDue : 0.0,
      is58: is58,
      showNameAlias: showNameAlias,
      useTable: itemLayout != 'detailed',
      widthPx: widthPx,
      paperSize: is58 ? PaperSize.mm58 : PaperSize.mm80,
    );
  }

  static bool _hasNonLatin1(String s) => s.codeUnits.any((c) => c > 0xFF);

  /// Plain ESC/POS text printing is faster and uses the printer's native
  /// font, but generator.text()/row() throws on any non-Latin1 script
  /// (codepage limitation). Scanning every user-editable text field up
  /// front — not just alias names, since customer names/notes/etc. can
  /// contain local-language text too — decides which path is actually
  /// safe for this specific receipt, instead of trusting a settings flag
  /// that could drift out of sync with what's actually typed.
  static bool _receiptHasNonLatin1(Invoice invoice, _ReceiptSettings s) {
    final company = s.pdf.company;
    final fields = <String?>[
      company?.name,
      company?.address,
      company?.phone,
      company?.gstin,
      invoice.customer.name,
      invoice.customer.businessName,
      invoice.customer.phone,
      invoice.customer.gstin,
      invoice.notes,
      s.pdf.thankYouNote,
      for (final item in invoice.items) item.product.displayName(s.showNameAlias),
    ];
    return fields.any((f) => f != null && _hasNonLatin1(f));
  }

  static Future<Widget> _buildReceiptWidget(
      Invoice invoice, _ReceiptSettings s) async {
    final settings = s.pdf;
    final currency = invoice.currencySymbol;
    final company = settings.company;
    final showItemTax = invoice.taxMode == TaxMode.perItem;

    final headFontSize = PdfLayout.thermalPrinterHeadFontSize *
        thermalCompanyNameSizeFromKey(settings.thermalCompanyNameSize).scale;
    const itemFontSize = PdfLayout.thermalPrinterItemFontSize * 0.85;

    final title = (invoice.invoiceTitle?.trim().isNotEmpty ?? false)
        ? invoice.invoiceTitle!.toUpperCase()
        : invoice.type.toUpperCase();

    Widget text(String text,
        {TextAlign align = TextAlign.left,
        bool bold = false,
        double fontSize = itemFontSize,
        bool needDarkerText = false,
        bool isTotal = false,
        bool isItalic = false}) {
      return Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isTotal ? fontSize + 3 : fontSize,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          fontWeight: bold ? FontWeight.bold : needDarkerText ? FontWeight.w500 : FontWeight.normal,
          color: Colors.black,
        ),
      );
    }

    Widget twoCol(String left, String right, {bool bold = false, bool needDarkerText = false, bool isTotal = false}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: text(left, bold: bold,needDarkerText: needDarkerText)),
          const SizedBox(width: 6),
          text(right, bold: bold, align: TextAlign.right,needDarkerText: needDarkerText,isTotal:isTotal),
        ],
      );
    }

    Widget hr() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0, dashGap = 2.0;
              final count =
                  (constraints.maxWidth / (dashWidth + dashGap)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(width: dashWidth, height: 1, color: Colors.black),
                ),
              );
            },
          ),
        );

    // ── Item table column widths, in fractions of paper width ──
    const slW = 3.0, qtyW = 5.0, rateW = 10.0, gstW = 4.0, totalW = 10.0;
    const nameWMax = 18.0;
    final charWidth = s.is58 ? 32.0 : 48.0;
    final gaps = showItemTax ? 5.0 : 4.0;
    final nameW =
        (charWidth - slW - qtyW - rateW - (showItemTax ? gstW : 0) - totalW - gaps)
            .clamp(1.0, nameWMax);

    Map<int, TableColumnWidth> tableWidths(bool withGst) {
      final widths = <int, TableColumnWidth>{
        0: FractionColumnWidth(slW / charWidth),
        1: FractionColumnWidth(nameW / charWidth),
        2: FractionColumnWidth(qtyW / charWidth),
        3: FractionColumnWidth(rateW / charWidth),
      };
      var idx = 4;
      if (withGst) widths[idx++] = FractionColumnWidth(gstW / charWidth);
      widths[idx] = FractionColumnWidth(totalW / charWidth);
      return widths;
    }

    List<Widget> itemTableRow(
        String sl, String name, String qty, String rate, String? gst, String total,
        {bool bold = false}) {
      Widget cell(String v, TextAlign align, {bool bold_ = false,bool needDarkerText = false} ) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: text(v, align: align, bold: bold || bold_, needDarkerText :needDarkerText),
          );
      return [
        cell(sl, TextAlign.left,needDarkerText: true),
        cell(name, TextAlign.left,bold_: true),
        cell(qty, TextAlign.center,needDarkerText: true),
        cell(rate, TextAlign.right,needDarkerText: true),
        if (gst != null) cell(gst, TextAlign.right,needDarkerText: true),
        cell(total, TextAlign.right,needDarkerText: true),
      ];
    }

    final headerCells = itemTableRow(
        'Sl', 'Description', 'Qty', 'Rate', showItemTax ? 'GST%' : null, 'Total',
        bold: true);
    final itemRows = <TableRow>[
      TableRow(children: headerCells),
      TableRow(
        children: List.generate(headerCells.length, (_) => hr()),
      ),
    ];
    final detailedRows = <Widget>[];

    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final unit = item.effectiveUnit.trim().isEmpty ? '' : item.effectiveUnit;
      final qty = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString() + unit
          : item.quantity.toStringAsFixed(2) + unit;
      final rate = item.effectivePrice.toStringAsFixed(2);
      final total = item.total.toStringAsFixed(2);
      final name = item.product.displayName(s.showNameAlias);
      final gstStr = showItemTax ? '${item.product.tax_rate}%' : null;

      if (s.useTable) {
        itemRows.add(TableRow(
          children: itemTableRow('${i + 1}', name, qty, rate, gstStr, total),
        ));
        if (settings.showDiscount && item.totalDiscount > 0) {
          itemRows.add(TableRow(children: [
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: text('Disc: -${item.totalDiscount.toStringAsFixed(2)}'),
            ),
            const SizedBox(),
            const SizedBox(),
            if (showItemTax) const SizedBox(),
            const SizedBox(),
          ]));
        }
      } else {
        final detailParts = ['Qty:$qty', 'Rate:$rate'];
        if (showItemTax) detailParts.add('${item.product.tax_rate}%');
        detailParts.add(total);
        detailedRows.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text('${i + 1} $name',bold: true),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final part in detailParts) text(part),
                  ],
                ),
              ),
              if (settings.showDiscount && item.totalDiscount > 0)
                text('  Disc: -${item.totalDiscount.toStringAsFixed(2)}'),
            ],
          ),
        ));
      }
    }

    // ── Tax summary ──
    final isIndia = (company?.country ?? '').isEmpty ||
        company!.country.toLowerCase() == 'india';
    final showTaxSummary = invoice.taxMode != TaxMode.none && invoice.tax > 0;

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: Container(
          width: s.widthPx.toDouble(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Business header ──
              if ((company?.name ?? '').isNotEmpty)
                text(company!.name,
                    align: TextAlign.center, bold: true, fontSize: headFontSize),
              if ((company?.address ?? '').isNotEmpty)
                text(company!.address, align: TextAlign.center,needDarkerText: true),
              if ((company?.phone ?? '').isNotEmpty)
                text('Ph: ${company!.phone}', align: TextAlign.center,needDarkerText: true),
              if (settings.showGst && (company?.gstin ?? '').isNotEmpty)
                text('${taxLabel(company?.country)}: ${company!.gstin}',
                    align: TextAlign.center),
              hr(),
              text(title, align: TextAlign.center, bold: true),
              hr(),

              // ── Invoice meta ──
              twoCol(
                  'Inv No: ${settings.invoicePrefix}${invoice.invoiceNumber ?? invoice.id}',
                  'Date: ${s.dateFmt.format(invoice.date)}',needDarkerText: true),
              if (invoice.dueDate != null)
                twoCol('Due:', s.dateFmt.format(invoice.dueDate!)),
              hr(),

              // ── Customer ──
              text('Name: ${invoice.customer.name}', bold: true),
              if (invoice.customer.businessName.isNotEmpty)
                text(invoice.customer.businessName),
              if (invoice.customer.phone.isNotEmpty)
                text('Ph: ${invoice.customer.phone}'),
              if (settings.showGst && invoice.customer.gstin.isNotEmpty)
                text('${taxLabel(company?.country)}: ${invoice.customer.gstin}'),
              hr(),

              // ── Items ──
              if (s.useTable)
                Table(
                  columnWidths: tableWidths(showItemTax),
                  children: itemRows,
                )
              else
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  twoCol('# Item', 'Total', bold: true),
                  hr(),
                  ...detailedRows,
                ]),
              hr(),

              // ── Totals ──
              if (invoice.totalDiscount > 0) ...[
                twoCol('Subtotal:', '$currency ${invoice.grossSubtotal.toStringAsFixed(2)}'),
                twoCol('Discount:', '-$currency ${invoice.totalDiscount.toStringAsFixed(2)}'),
              ],
              if (invoice.taxMode != TaxMode.none)
                twoCol(invoiceTaxLabel(invoice), '$currency ${invoice.tax.toStringAsFixed(2)}'),
              for (final c in invoice.additionalCosts)
                twoCol(c.label.isEmpty ? 'Extra Cost' : c.label,
                    '$currency ${c.amount.toStringAsFixed(2)}'),
              if (s.previousBalance > 0)
                twoCol('Prev Balance:', '$currency ${s.previousBalance.toStringAsFixed(2)}'),
              if (invoice.invoiceDiscountAmount > 0)
                twoCol(invoice.invoiceDiscountType == InvoiceDiscountType.percent
                ? "Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%)"
                    : "Extra Discount ",
                "-$currency ${invoice.invoiceDiscountAmount.toStringAsFixed(2)}"),
              twoCol('TOTAL',
                  '$currency ${(invoice.total + s.previousBalance).toStringAsFixed(2)}',
                  bold: true,isTotal:true),

              if (settings.showRoundOff) ...[
                Builder(builder: (_) {
                  final net = roundNetTotal(invoice.total + s.previousBalance);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      twoCol('Round off:', '$currency ${net.roundOff.toStringAsFixed(2)}'),
                      twoCol('Net Amount:', '$currency ${net.rounded.toStringAsFixed(2)}', bold: true),
                      hr(),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: text(AmountInWords.amount(net.rounded), align: TextAlign.left,fontSize: itemFontSize-2,isItalic: true),
                      ),
                    ],
                  );
                }),
              ],

              if (showTaxSummary) ...[
                hr(),
                text('=== TAX SUMMARY ===', align: TextAlign.center, bold: true),
                twoCol('Taxable Amt:', '$currency ${invoice.subtotal.toStringAsFixed(2)}'),
                if (isIndia && settings.showCgstSgst) ...[
                  twoCol('SGST:', '$currency ${(invoice.tax / 2).toStringAsFixed(2)}'),
                  twoCol('CGST:', '$currency ${(invoice.tax / 2).toStringAsFixed(2)}'),
                ],
                twoCol('Total Tax:', '$currency ${invoice.tax.toStringAsFixed(2)}'),
              ],

              if (invoice.amountPaid > 0) ...[
                hr(),
                twoCol('Paid:', '$currency ${invoice.amountPaid.toStringAsFixed(2)}'),
                if (invoice.outstandingBalance <= 0)
                  twoCol('PAID IN FULL', '', bold: true)
                else
                  twoCol('Balance Due',
                      '$currency ${invoice.outstandingBalance.toStringAsFixed(2)}', bold: true),
              ],

              // ── Notes ──
              if ((invoice.notes ?? '').isNotEmpty) ...[
                hr(),
                text(invoice.notes!),
              ],

              // ── Footer ──
              hr(),
              if (settings.thankYouNote.isNotEmpty)
                text(settings.thankYouNote, align: TextAlign.center, bold: true),
              if (settings.showFooterBranding)
                text('Generated by Invoiso', align: TextAlign.center),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptSettings {
  final PdfGenerationSettings pdf;
  final DateFormat dateFmt;
  final double previousBalance;
  final bool is58;
  final bool showNameAlias;
  final bool useTable;
  final int widthPx;
  final PaperSize paperSize;

  _ReceiptSettings({
    required this.pdf,
    required this.dateFmt,
    required this.previousBalance,
    required this.is58,
    required this.showNameAlias,
    required this.useTable,
    required this.widthPx,
    required this.paperSize,
  });
}

class _NetworkPrintRow extends StatefulWidget {
  final Invoice invoice;
  final bool useTextMode;
  const _NetworkPrintRow({required this.invoice, this.useTextMode = false});

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
      final settings =
          await ThermalPrinterService._fetchReceiptSettings(widget.invoice);
      final useImage = kDebugMode ? (widget.useTextMode ? false : true) : true;
      // TODO - We can use it later if user complaint about the printing speed!
      //ThermalPrinterService._receiptHasNonLatin1(widget.invoice, settings);
      if (!useImage) {
        await ThermalPrinterService._printToNetworkText(
          ip: _ipController.text.trim(),
          port: int.tryParse(_portController.text.trim()) ?? 9100,
          invoice: widget.invoice,
          settingsOverride: settings,
        );
      } else {
        if (!mounted) return;
        await ThermalPrinterService._printToNetwork(
          context: context,
          ip: _ipController.text.trim(),
          port: int.tryParse(_portController.text.trim()) ?? 9100,
          invoice: widget.invoice,
          settingsOverride: settings,
        );
      }
      messenger?.showSnackBar(
        const SnackBar(content: Text('Sent to network printer/listener.')),
      );
    } catch (e) {
      if (kDebugMode) print(e);
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
