import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/utils/amount_in_words.dart';
import 'package:invoiso/models/customer_field_settings.dart';
import 'pdf_widgets.dart';
import 'package:invoiso/utils/formatters.dart';

const double _thermalMargin = 4 * PdfPageFormat.mm;

pw.Page buildThermalTemplate(
  Invoice invoice,
  CompanyInfo? company,
  String currencySymbol,
  String invoicePrefix, {
  bool showGst = true,
  bool showQuantity = true,
  bool showDiscount = true,
  bool showAliasName = false,
  bool showDescription = false,
  String datePattern = 'dd/MM/yyyy',
  String thankYouNote = '',
  bool showFooterBranding = false,
  PdfColor? themeColor,
  double previousBalanceDue = 0.0,
  PdfPageFormat pageFormat = PdfPageFormat.roll80,
  PageSize pageSize = PageSize.a4,
  pw.ThemeData? pdfTheme,
  String itemLayout = 'table',
  bool showRoundOff = false,
  bool showLeadingZeros = true,
  bool showPhone = true,
  bool showCompanyName = true,
  bool showAddress = true,
  bool showCustomerBusinessName = true,
  bool showCustomerPhone = true,
  bool showCustomerGstin = true,
  CustomerFieldSettings customerFields = const CustomerFieldSettings(),
  bool showTimeInPdf = true,
  String pdfTimeFormat = '24',
  String companyNameSize = 'medium',
  bool showTotalQuantity = false,
  bool showSlNo = true,
  bool showTaxColumn = true,
  bool showCgstSgst = false,
  bool showCustomerAddress = true,
  bool showCustomerEmail = true,
  bool showPan = true,
  bool showFssai = true,
}) {
  const double bodyFs = 6;
  const double smallFs = 5.5;
  const double boldFs = 6;
  const double titleFs = 8.5;

  final is58 = pageSize == PageSize.thermal58;
  final useDetailedLayout = itemLayout == 'detailed';
  final totalColumnWidth = is58 ? 28.0 : 40.0;

  var totalQuantity = 0.0;

  pw.Widget sp() =>
      pw.Divider(thickness: 0.5, color: PdfColors.grey600, height: 3);

  pw.Widget dashedSep() => pw.Divider(
        thickness: 0.5,
        color: PdfColors.grey600,
        height: 3,
        borderStyle: pw.BorderStyle.dashed,
      );

  pw.Widget centerText(String text,
      {double fontSize = bodyFs,
      bool bold = false,
      PdfColor color = PdfColors.black}) {
    return pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget labelValue(String label, String value, {double fontSize = bodyFs,bool valueIsBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey800)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: fontSize, fontWeight: valueIsBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  final showItemTax = invoice.taxMode == TaxMode.perItem && showTaxColumn;
  final qtyLabel = invoice.quantityLabel?.isNotEmpty == true
      ? invoice.quantityLabel!
      : 'Qty';
  // Sub-lines indent past the Sl column; flush left when it's hidden.
  final detailIndent = showSlNo ? 12.0 : 0.0;
  final tableIndent = showSlNo ? 14.0 : 0.0;

  pw.Widget? hsnLine(String hsn, double indent) => showGst &&
          hsn.trim().isNotEmpty
      ? pw.Padding(
          padding: pw.EdgeInsets.only(left: indent),
          child: pw.Text('HSN: $hsn',
              style: const pw.TextStyle(
                  fontSize: smallFs, color: PdfColors.grey700)),
        )
      : null;

  List<pw.Widget> buildItemRows() {
    final rows = <pw.Widget>[];
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final qty = '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(2)}'
          '${item.effectiveUnit.trim().isEmpty ? '' : ' ${item.effectiveUnit}'}';
      totalQuantity += item.quantity;
      final rate = AmountFormat.money(item.effectivePrice);
      final total = AmountFormat.money(item.total);

      if (useDetailedLayout) {
        // Detailed: line1 = sl+name, line2 = qty/rate/gst%/total
        rows.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (showSlNo)
                  pw.SizedBox(
                    width: 12,
                    child: pw.Text('${i + 1}',
                        style: const pw.TextStyle(fontSize: smallFs)),
                  ),
                  pw.Expanded(
                    child: pw.Text(item.product.displayName(showAliasName),
                        style: pw.TextStyle(
                            fontSize: smallFs,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(left: detailIndent),
                child: pw.Row(
                  children: [
                    if (showQuantity) ...[
                      pw.Text('$qtyLabel:$qty',
                          style: const pw.TextStyle(fontSize: smallFs)),
                      pw.SizedBox(width: 4),
                    ],
                    pw.Expanded(
                      child: pw.Text('Rate:$rate',
                          style: const pw.TextStyle(fontSize: smallFs)),
                    ),
                    if (showItemTax) ...[
                      pw.Text('${item.product.tax_rate}%',
                          style: const pw.TextStyle(fontSize: smallFs)),
                      pw.SizedBox(width: 4),
                    ],
                    pw.Text(total,
                        style: pw.TextStyle(
                            fontSize: smallFs,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              if (hsnLine(item.product.hsncode, detailIndent) != null)
                hsnLine(item.product.hsncode, detailIndent)!,
              if (showDescription && item.printedDescription.isNotEmpty)
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: detailIndent),
                  child: pw.Text(
                    item.printedDescription,
                    style: const pw.TextStyle(
                        fontSize: smallFs, color: PdfColors.grey700),
                  ),
                ),
              if (showDiscount && item.totalDiscount > 0)
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: detailIndent),
                  child: pw.Text(
                    'Disc: -${AmountFormat.money(item.totalDiscount)}'
                    '${item.discountIsPercent ? ' (${item.discount == item.discount.roundToDouble() ? item.discount.toInt() : item.discount}%)' : ''}',
                    style: const pw.TextStyle(
                        fontSize: smallFs, color: PdfColors.orange800),
                  ),
                ),
            ],
          ),
        ));
      } else {
        // Table: single-line row
        rows.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (showSlNo)
                  pw.SizedBox(
                    width: 14,
                    child: pw.Text('${i + 1}',
                        style: const pw.TextStyle(fontSize: smallFs)),
                  ),
                  pw.Expanded(
                    child: pw.Text(item.product.displayName(showAliasName),
                        style: pw.TextStyle(fontSize: smallFs)),
                  ),
                  if (showQuantity)
                  pw.SizedBox(
                    width: 36,
                    child: pw.Text(qty,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: smallFs)),
                  ),
                  pw.SizedBox(
                    width: 30,
                    child: pw.Text(rate,
                        style: pw.TextStyle(fontSize: smallFs)),
                  ),
                  if (showItemTax)
                    pw.SizedBox(
                      width: 18,
                      child: pw.Text('${item.product.tax_rate}%',
                          style: const pw.TextStyle(fontSize: smallFs)),
                    ),
                  pw.SizedBox(
                    width: totalColumnWidth,
                    child: pw.Text(total,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: smallFs)),
                  ),
                ],
              ),
              if (hsnLine(item.product.hsncode, tableIndent) != null)
                hsnLine(item.product.hsncode, tableIndent)!,
              if (showDescription && item.printedDescription.isNotEmpty)
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: tableIndent),
                  child: pw.Text(
                    item.printedDescription,
                    style: const pw.TextStyle(
                        fontSize: smallFs, color: PdfColors.grey700),
                  ),
                ),
              if (showDiscount && item.totalDiscount > 0)
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: tableIndent),
                  child: pw.Text(
                    'Discount: -${AmountFormat.money(item.totalDiscount)}'
                    '${item.discountIsPercent ? ' (${item.discount == item.discount.roundToDouble() ? item.discount.toInt() : item.discount}%)' : ''}',
                    style: const pw.TextStyle(
                        fontSize: smallFs, color: PdfColors.orange800),
                  ),
                ),
            ],
          ),
        ));
      }
    }
    return rows;
  }

  List<pw.Widget> buildTaxSummary() {
    if (invoice.taxMode == TaxMode.none || invoice.tax <= 0) return [];
    final totalTaxable = invoice.subtotal;
    final totalTax = invoice.tax;
    final isIndia = (company?.country ?? '').isEmpty ||
        company!.country.toLowerCase() == 'india';

    return [
      pw.SizedBox(height: 4),
      centerText('=== TAX SUMMARY ===', fontSize: smallFs, bold: true),
      pw.SizedBox(height: 2),
      labelValue('Taxable Amt:',
          '$currencySymbol ${AmountFormat.money(totalTaxable)}',
          fontSize: smallFs),
      if (showCgstSgst && isIndia && invoice.isInterState)
        labelValue('IGST:', '$currencySymbol ${AmountFormat.money(totalTax)}',
            fontSize: smallFs)
      else if (showCgstSgst && isIndia) ...[
        labelValue('SGST:', '$currencySymbol ${AmountFormat.money(totalTax / 2)}',
            fontSize: smallFs),
        labelValue('CGST:', '$currencySymbol ${AmountFormat.money(totalTax / 2)}',
            fontSize: smallFs),
      ],
      labelValue('Total Tax:', '$currencySymbol ${AmountFormat.money(totalTax)}',
          fontSize: smallFs),
    ];
  }

  List<pw.Widget> buildPdfBody() {
    final dateStr = formatPdfDateTime(invoice.date, datePattern,
        showTime: showTimeInPdf, timeFormat: pdfTimeFormat);
    final netTotal = roundNetTotal(invoice.total + previousBalanceDue);
    return [
      if (invoice.status == 'declined')
        centerText('*** DECLINED ***', fontSize: titleFs, bold: true),
      // ── Business Header ──
      // Scaled relative to 'medium' so the default size stays at titleFs.
      centerText(showCompanyName ? (company?.name ?? '') : '',
          fontSize: titleFs *
              thermalCompanyNameSizeFromKey(companyNameSize).scale /
              ThermalCompanyNameSize.medium.scale,
          bold: true),
      pw.SizedBox(height: 2),
      if (showAddress && (company?.address ?? '').isNotEmpty)
        centerText(company!.address, fontSize: smallFs),
      if (showPhone && (company?.phone ?? '').isNotEmpty)
        centerText('Ph: ${company!.phone}', fontSize: smallFs),
      if (showGst && (company?.gstin ?? '').isNotEmpty)
        centerText('${taxLabel(company?.country)}: ${company!.gstin}',
            fontSize: smallFs),
      if (showPan && (company?.panNumber ?? '').isNotEmpty)
        centerText('PAN: ${company!.panNumber}', fontSize: smallFs),
      if (showFssai &&
          (company?.fssaiCode ?? '').isNotEmpty &&
          isIndiaCountry(company?.country))
        centerText('FSSAI: ${company!.fssaiCode}', fontSize: smallFs),
      pw.SizedBox(height: 3),
      sp(),
      centerText((invoice.invoiceTitle ?? invoice.type).toUpperCase(), fontSize: boldFs, bold: true),
      sp(),
      pw.SizedBox(height: 3),
      // ── Invoice meta ──
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros) != null)
            pw.Text(
                '${invoice.thermalNumberLabel}: ${invoice.pdfNumberText(invoicePrefix, showLeadingZeros: showLeadingZeros)}',
                style: const pw.TextStyle(fontSize: bodyFs)),
          pw.Text('Date: $dateStr',
              style: const pw.TextStyle(fontSize: bodyFs)),
        ],
      ),
      if (invoice.dueDate != null)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Due:', style: const pw.TextStyle(fontSize: bodyFs)),
            pw.Text(DateFormat(datePattern, 'en_US').format(invoice.dueDate!),
                style: const pw.TextStyle(fontSize: bodyFs)),
          ],
        ),
      sp(),
      pw.SizedBox(height: 2),

      // ── Customer ──
      pw.Text('Name: ${invoice.customer.name}',
          style: pw.TextStyle(
              fontSize: bodyFs, fontWeight: pw.FontWeight.bold)),
      if (showCustomerBusinessName && invoice.customer.businessName.isNotEmpty)
        pw.Text(invoice.customer.businessName,
            style: const pw.TextStyle(fontSize: smallFs)),
      if (showCustomerAddress && invoice.customer.address.isNotEmpty)
        pw.Text(invoice.customer.address,
            style: const pw.TextStyle(fontSize: smallFs)),
      if (showCustomerPhone && invoice.customer.phone.isNotEmpty)
        pw.Text('Ph: ${invoice.customer.phone}',
            style: const pw.TextStyle(fontSize: smallFs)),
      if (showCustomerEmail && invoice.customer.email.isNotEmpty)
        pw.Text(invoice.customer.email,
            style: const pw.TextStyle(fontSize: smallFs)),
      if (showGst && showCustomerGstin && invoice.customer.gstin.isNotEmpty)
        pw.Text('${taxLabel(company?.country)}: ${invoice.customer.gstin}',
            style: const pw.TextStyle(fontSize: smallFs)),
      for (final line in customerExtraLines(
          invoice.customer, customerFields, invoice.date, datePattern))
        pw.Text(line, style: const pw.TextStyle(fontSize: smallFs)),
      if (showShipTo(invoice.customer, customerFields)) ...[
        pw.SizedBox(height: 2),
        pw.Text('Ship To:',
            style: pw.TextStyle(
                fontSize: bodyFs, fontWeight: pw.FontWeight.bold)),
        for (final line in shipToLines(invoice.customer, phonePrefix: 'Ph: '))
          pw.Text(line, style: const pw.TextStyle(fontSize: smallFs)),
      ],
      pw.SizedBox(height: 3),

      // ── Items header ──
      sp(),
      if (useDetailedLayout)
        pw.Row(
          children: [
            if (showSlNo)
            pw.SizedBox(
                width: 12,
                child: pw.Text('#',
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(
                child: pw.Text('Item',
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            pw.Text('Total',
                style: pw.TextStyle(
                    fontSize: smallFs, fontWeight: pw.FontWeight.bold)),
          ],
        )
      else
        pw.Row(
          children: [
            if (showSlNo)
            pw.SizedBox(
                width: 14,
                child: pw.Text('Sl',
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(
                child: pw.Text('Description',
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            if (showQuantity)
            pw.SizedBox(
                width: 36,
                child: pw.Text(qtyLabel,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(
                width: 30,
                child: pw.Text('Rate',
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            if (showItemTax)
              pw.SizedBox(
                  width: 18,
                  child: pw.Text('GST%',
                      style: pw.TextStyle(
                          fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(
                width: totalColumnWidth,
                child: pw.Text('Total',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
          ],
        ),
      sp(),

      // ── Item rows ──
      ...buildItemRows(),
      dashedSep(),
      // Total qty sits under the Qty column (table) / the "Qty:" text (detailed).
      if (showTotalQuantity && showQuantity) ...[
        if (useDetailedLayout)
          pw.Padding(
            padding: pw.EdgeInsets.only(left: detailIndent),
            child: pw.Text(
                'Total $qtyLabel:${totalQuantity == totalQuantity.roundToDouble() ? totalQuantity.toInt().toString() : totalQuantity.toStringAsFixed(2)}',
                style: pw.TextStyle(
                    fontSize: smallFs, fontWeight: pw.FontWeight.bold)),
          )
        else
          pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text('Total $qtyLabel',
                      style: pw.TextStyle(
                          fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(
                  width: 36,
                  child: pw.Text(
                      totalQuantity == totalQuantity.roundToDouble()
                          ? totalQuantity.toInt().toString()
                          : totalQuantity.toStringAsFixed(2),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(width: 30),
              if (showItemTax) pw.SizedBox(width: 18),
              pw.SizedBox(width: totalColumnWidth),
            ],
          ),
        dashedSep(),
      ],

      // ── Totals ──
      pw.SizedBox(height: 2),
      if (invoice.totalDiscount > 0)
        labelValue('Subtotal:',
            '$currencySymbol ${AmountFormat.money(invoice.grossSubtotal)}'),
      if (invoice.totalDiscount > 0)
        labelValue('Discount:',
            '-$currencySymbol ${AmountFormat.money(invoice.totalDiscount)}'),
      if (invoice.taxMode != TaxMode.none)
        labelValue(invoiceTaxLabel(invoice),
            '$currencySymbol ${AmountFormat.money(invoice.tax)}'),
      for (final c in invoice.additionalCosts)
        labelValue(c.label.isEmpty ? 'Extra Cost' : c.label,
            c.amount < 0
                ? '-$currencySymbol ${AmountFormat.money(-c.amount)}'
                : '$currencySymbol ${AmountFormat.money(c.amount)}'),
      if (invoice.invoiceDiscountAmount > 0)
        labelValue(invoice.invoiceDiscountType == InvoiceDiscountType.percent
            ? "Extra Discount (${invoice.invoiceDiscountValue.toStringAsFixed(1)}%)"
            : "Extra Discount ",
          "-$currencySymbol ${AmountFormat.money(invoice.invoiceDiscountAmount)}",),

      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL',
              style: pw.TextStyle(
                  fontSize: boldFs, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              '$currencySymbol ${AmountFormat.money(invoice.total)}',
              style: pw.TextStyle(
                  fontSize: boldFs, fontWeight: pw.FontWeight.bold)),
        ],
      ),
      if (previousBalanceDue > 0) ...[
        labelValue('Prev Balance Due:',
            '$currencySymbol ${AmountFormat.money(previousBalanceDue)}'),
        labelValue('Total Due',
            '$currencySymbol ${AmountFormat.money(invoice.total + previousBalanceDue)}',
            valueIsBold: true),
      ],
      if (showRoundOff) ...[
        pw.SizedBox(height: 2),
        labelValue('Round off:',
            '$currencySymbol ${AmountFormat.money(netTotal.roundOff)}'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('NET AMOUNT',
                style: pw.TextStyle(
                    fontSize: boldFs, fontWeight: pw.FontWeight.bold)),
            pw.Text('$currencySymbol ${AmountFormat.money(netTotal.rounded)}',
                style: pw.TextStyle(
                    fontSize: boldFs, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text(AmountInWords.amount(netTotal.rounded,
                indian: invoice.currencyCode == 'INR'),
            style: pw.TextStyle(
                fontSize: bodyFs - 1, fontStyle: pw.FontStyle.italic)),
      ],

      if (invoice.amountPaid > 0) ...[
        pw.SizedBox(height: 2),
        labelValue('Paid:',
            '$currencySymbol ${AmountFormat.money(invoice.amountPaid)}'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                invoice.outstandingBalance <= 0 ? 'PAID IN FULL' : 'Balance Due',
                style: pw.TextStyle(
                    fontSize: bodyFs, fontWeight: pw.FontWeight.bold)),
            if (invoice.outstandingBalance > 0)
              pw.Text(
                  '$currencySymbol ${AmountFormat.money(invoice.outstandingBalance)}',
                  style: pw.TextStyle(
                      fontSize: bodyFs, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],

      // ── Tax summary ──
      ...buildTaxSummary(),

      // ── Credit / Debit Note info (against invoice, reason, refunds) ──
      if (returnInfoLines(invoice).isNotEmpty) ...[
        pw.SizedBox(height: 4),
        dashedSep(),
        for (final l in returnInfoLines(invoice))
          pw.Text(l,
              style: pw.TextStyle(
                  fontSize: smallFs, fontWeight: pw.FontWeight.bold)),
      ],

      // ── Notes ──
      if ((invoice.notes ?? '').isNotEmpty) ...[
        pw.SizedBox(height: 4),
        dashedSep(),
        pw.Text('NOTES',
            style: pw.TextStyle(
                fontSize: smallFs, fontWeight: pw.FontWeight.bold)),
        pw.Text(invoice.notes!,
            style: pw.TextStyle(
                fontSize: smallFs, fontStyle: pw.FontStyle.italic)),
      ],

      // ── Thank you ──
      pw.SizedBox(height: 2),
      sp(),
      if (thankYouNote.isNotEmpty)
        centerText(thankYouNote,
            fontSize: bodyFs, bold: true, color: PdfColors.grey800),
      if (showFooterBranding) ...[
        pw.SizedBox(height: 4),
        centerText('Generated by Invoiso', fontSize: (smallFs-1), color: PdfColors.grey500),
      ],
      pw.SizedBox(height: 4),
    ];
  }

  return pw.Page(
    pageFormat: pageFormat,
    theme: pdfTheme,
    margin: const pw.EdgeInsets.all(_thermalMargin),
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: buildPdfBody(),
    ),
  );
}
