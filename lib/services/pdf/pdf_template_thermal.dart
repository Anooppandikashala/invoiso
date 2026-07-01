import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:invoiso/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'pdf_widgets.dart';

const double _thermalMargin = 4 * PdfPageFormat.mm;

pw.Page buildThermalTemplate(
  Invoice invoice,
  CompanyInfo? company,
  String currencySymbol,
  String invoicePrefix, {
  bool showGst = true,
  bool showQuantity = true,
  bool showDiscount = true,
  String datePattern = 'dd/MM/yyyy',
  String thankYouNote = '',
  bool showFooterBranding = false,
  PdfColor? themeColor,
  double previousBalanceDue = 0.0,
  PdfPageFormat pageFormat = PdfPageFormat.roll80,
  PageSize pageSize = PageSize.a4,
  pw.ThemeData? pdfTheme,
}) {
  const double bodyFs = 6;
  const double smallFs = 5.5;
  const double boldFs = 6;
  const double titleFs = 8.5;

  final is58 = pageSize == PageSize.thermal58;
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

  pw.Widget labelValue(String label, String value, {double fontSize = bodyFs}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey700)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  final showItemTax = invoice.taxMode == TaxMode.perItem;

  List<pw.Widget> buildItemRows() {
    final rows = <pw.Widget>[];
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      final qty = item.quantity == item.quantity.roundToDouble()
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(2);
      totalQuantity += item.quantity;
      final rate = item.effectivePrice.toStringAsFixed(2);
      final total = item.total.toStringAsFixed(2);

      if (is58) {
        // 58mm: line1 = sl+name, line2 = qty/rate/gst%/total
        rows.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 12,
                    child: pw.Text('${i + 1}',
                        style: const pw.TextStyle(fontSize: smallFs)),
                  ),
                  pw.Expanded(
                    child: pw.Text(item.product.name,
                        style: pw.TextStyle(
                            fontSize: smallFs,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12),
                child: pw.Row(
                  children: [
                    pw.Text('Qty:$qty',
                        style: const pw.TextStyle(fontSize: smallFs)),
                    pw.SizedBox(width: 4),
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
              if (showDiscount && item.totalDiscount > 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12),
                  child: pw.Text(
                    'Disc: -${item.totalDiscount.toStringAsFixed(2)}',
                    style: const pw.TextStyle(
                        fontSize: smallFs, color: PdfColors.orange800),
                  ),
                ),
            ],
          ),
        ));
      } else {
        // 80mm: single-line row
        rows.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 14,
                    child: pw.Text('${i + 1}',
                        style: const pw.TextStyle(fontSize: smallFs)),
                  ),
                  pw.Expanded(
                    child: pw.Text(item.product.name,
                        style: pw.TextStyle(fontSize: smallFs)),
                  ),
                  pw.SizedBox(
                    width: 30,
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
              if (showDiscount && item.totalDiscount > 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 14),
                  child: pw.Text(
                    'Discount: -${item.totalDiscount.toStringAsFixed(2)}',
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
          '$currencySymbol ${totalTaxable.toStringAsFixed(2)}',
          fontSize: smallFs),
      if (isIndia) ...[
        labelValue('SGST:', '$currencySymbol ${(totalTax / 2).toStringAsFixed(2)}',
            fontSize: smallFs),
        labelValue('CGST:', '$currencySymbol ${(totalTax / 2).toStringAsFixed(2)}',
            fontSize: smallFs),
      ],
      labelValue('Total Tax:', '$currencySymbol ${totalTax.toStringAsFixed(2)}',
          fontSize: smallFs),
    ];
  }

  List<pw.Widget> buildPdfBody() {
    final dateStr = DateFormat(datePattern).format(invoice.date);
    return [
      // ── Business Header ──
      centerText(company?.name ?? '', fontSize: titleFs, bold: true),
      pw.SizedBox(height: 2),
      if ((company?.address ?? '').isNotEmpty)
        centerText(company!.address, fontSize: smallFs),
      if ((company?.phone ?? '').isNotEmpty)
        centerText('Ph: ${company!.phone}', fontSize: smallFs),
      if (showGst && (company?.gstin ?? '').isNotEmpty)
        centerText('${taxLabel(company?.country)}: ${company!.gstin}',
            fontSize: smallFs),
      pw.SizedBox(height: 3),
      sp(),
      centerText(invoice.type.toUpperCase(), fontSize: boldFs, bold: true),
      sp(),
      pw.SizedBox(height: 3),
      // ── Invoice meta ──
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Inv No: $invoicePrefix${invoice.id}',
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
            pw.Text(DateFormat(datePattern).format(invoice.dueDate!),
                style: const pw.TextStyle(fontSize: bodyFs)),
          ],
        ),
      sp(),
      pw.SizedBox(height: 2),

      // ── Customer ──
      pw.Text('Name: ${invoice.customer.name}',
          style: pw.TextStyle(
              fontSize: bodyFs, fontWeight: pw.FontWeight.bold)),
      if (invoice.customer.businessName.isNotEmpty)
        pw.Text(invoice.customer.businessName,
            style: const pw.TextStyle(fontSize: smallFs)),
      if (invoice.customer.phone.isNotEmpty)
        pw.Text('Ph: ${invoice.customer.phone}',
            style: const pw.TextStyle(fontSize: smallFs)),
      if (showGst && invoice.customer.gstin.isNotEmpty)
        pw.Text('${taxLabel(company?.country)}: ${invoice.customer.gstin}',
            style: const pw.TextStyle(fontSize: smallFs)),
      pw.SizedBox(height: 3),

      // ── Items header ──
      sp(),
      if (is58)
        pw.Row(
          children: [
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
            pw.SizedBox(
                width: 14,
                child: pw.Text('Sl',
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            pw.Expanded(
                child: pw.Text('Description',
                    style: pw.TextStyle(
                        fontSize: smallFs, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(
                width: 30,
                child: pw.Text('Qty',
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

      // ── Totals ──
      pw.SizedBox(height: 2),
      if (invoice.totalDiscount > 0)
        labelValue('Subtotal:',
            '$currencySymbol ${invoice.grossSubtotal.toStringAsFixed(2)}'),
      if (invoice.totalDiscount > 0)
        labelValue('Discount:',
            '-$currencySymbol ${invoice.totalDiscount.toStringAsFixed(2)}'),
      if (invoice.taxMode != TaxMode.none)
        labelValue(invoiceTaxLabel(invoice),
            '$currencySymbol ${invoice.tax.toStringAsFixed(2)}'),
      for (final c in invoice.additionalCosts)
        labelValue(c.label.isEmpty ? 'Extra Cost' : c.label,
            '$currencySymbol ${c.amount.toStringAsFixed(2)}'),
      if (previousBalanceDue > 0)
        labelValue('Prev Balance:',
            '$currencySymbol ${previousBalanceDue.toStringAsFixed(2)}'),

      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL',
              style: pw.TextStyle(
                  fontSize: boldFs, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(
              width: 30,
              child: pw.Text(
                  totalQuantity == totalQuantity.roundToDouble()
                      ? totalQuantity.toInt().toString()
                      : totalQuantity.toStringAsFixed(2),
                  textAlign: pw.TextAlign.end,
                  style: pw.TextStyle(
                      fontSize: boldFs, fontWeight: pw.FontWeight.bold))),
          pw.Text(
              '$currencySymbol ${(invoice.total + previousBalanceDue).toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontSize: boldFs, fontWeight: pw.FontWeight.bold)),
        ],
      ),

      if (invoice.amountPaid > 0) ...[
        pw.SizedBox(height: 2),
        labelValue('Paid:',
            '$currencySymbol ${invoice.amountPaid.toStringAsFixed(2)}'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                invoice.outstandingBalance <= 0 ? 'PAID IN FULL' : 'Balance Due',
                style: pw.TextStyle(
                    fontSize: bodyFs, fontWeight: pw.FontWeight.bold)),
            if (invoice.outstandingBalance > 0)
              pw.Text(
                  '$currencySymbol ${invoice.outstandingBalance.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: bodyFs, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],

      // ── Tax summary ──
      ...buildTaxSummary(),

      // ── Notes ──
      if ((invoice.notes ?? '').isNotEmpty) ...[
        pw.SizedBox(height: 4),
        dashedSep(),
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
