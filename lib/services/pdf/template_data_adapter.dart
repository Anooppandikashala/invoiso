import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/utils/amount_in_words.dart';
import 'pdf_settings.dart';
import 'pdf_widgets.dart';

/// Invoice + PDF settings → the template engine's data map. The engine never
/// sees app classes (contract: `packages/invoiso_template_engine`).
///
/// Settings parity: every show/hide setting is applied here the same way the
/// built-in templates apply it — a hidden value comes through empty, so any
/// layout line showing only hidden values disappears. Column / row switches
/// are exposed as `settings.*` for layout `if` conditions.
Map<String, dynamic> buildTemplateData(
  Invoice invoice,
  PdfGenerationSettings s, {
  BankAccount? bankAccount,
  String? upiId,
  bool showUpiQr = false,
  String? qrLabel,
  double previousBalanceDue = 0,
  bool showCgstSgst = false,
  bool showIgst = false,
}) {
  final company = s.company;
  String show(bool on, String? value) => on ? (value ?? '') : '';
  String customField(List<String> labels) {
    for (final field in invoice.customFields) {
      final label = field.label.toLowerCase();
      if (labels.any((keyword) => label.contains(keyword))) return field.value;
    }
    return '';
  }

  final customer = invoice.customer;
  final interState = invoice.isInterState;
  // Per-line HSN / rate / taxable / tax exactly as the GST reports compute
  // them (items first, then taxable charges).
  final hsnLines = Gstr1Builder.hsnLines(invoice);
  ({double cgst, double sgst, double igst}) split(double tax) => interState
      ? (cgst: 0, sgst: 0, igst: tax)
      : (cgst: tax / 2, sgst: tax / 2, igst: 0);
  final taxSummary = <String, Map<String, dynamic>>{};
  for (final l in hsnLines) {
    final row = taxSummary.putIfAbsent('${l.hsn}|${l.rate}', () => {
          'hsn': l.hsn,
          'rate': l.rate,
          'cgstRate': interState ? 0.0 : l.rate / 2,
          'sgstRate': interState ? 0.0 : l.rate / 2,
          'igstRate': interState ? l.rate : 0.0,
          'taxable': 0.0, 'cgst': 0.0, 'sgst': 0.0, 'igst': 0.0, 'totalTax': 0.0,
        });
    final t = split(l.tax);
    row['taxable'] += l.taxable;
    row['cgst'] += t.cgst;
    row['sgst'] += t.sgst;
    row['igst'] += t.igst;
    row['totalTax'] += l.tax;
  }
  final totalDue = invoice.total + previousBalanceDue;
  final net = roundNetTotal(previousBalanceDue > 0 ? totalDue : invoice.total);
  final taxSplit = split(invoice.tax);
  final indianWords = invoice.currencyCode == 'INR';
  String stateName(String code) => GstUtils.states[code] ?? '';
  final companyState = GstUtils.stateCodeFromGstin(company?.gstin) ?? '';
  final shipTo = showShipTo(customer, s.customerFields);
  final pos = invoice.placeOfSupply ?? '';
  final taxColumnOn = s.showTaxColumn && invoice.taxMode != TaxMode.none;
  final metaKeys = pdfMetadataColumnKeys
      .where((k) => s.metadataColumns[k] == true)
      .toList();
  return {
    'company': company == null
        ? <String, dynamic>{}
        : {
            'name': show(s.showCompanyName, company.name),
            'address': show(s.showAddress, company.address),
            'phone': show(s.showPhone, company.phone),
            'email': show(s.showEmail, company.email),
            'website': show(s.showWebsite, company.website),
            'gstin': show(s.showGst, company.gstin),
            'pan': show(s.showPan, company.panNumber),
            'fssai': show(s.showFssai, company.fssaiCode),
            'country': company.country,
            'stateCode': companyState,
            'state': stateName(companyState),
            'taxLabel': taxLabel(company.country),
            'panLabel': panLabel(company.country),
          },
    'customer': {
      'name': customer.name,
      'businessName':
          show(s.showCustomerBusinessName, customer.businessName),
      'address': show(s.showCustomerAddress, customer.address),
      'phone': show(s.showCustomerPhone, customer.phone),
      'email': show(s.showCustomerEmail, customer.email),
      'gstin': show(s.showGst && s.showCustomerGstin, customer.gstin),
      'stateCode': customer.stateCode,
      'state': stateName(customer.stateCode),
      // Additional fields (age / DOB / gender + custom fields, per-field
      // "show in PDF"): as label/value cells, or as the built-ins' lines.
      'fields': [
        for (final f in customerExtraFields(
            customer, s.customerFields, invoice.date, s.datePattern))
          {'label': f.$1, 'value': f.$2},
      ],
      'extraLines': customerExtraLines(
          customer, s.customerFields, invoice.date, s.datePattern),
    },
    // Only when the built-ins would print Ship To (feature on, not same as
    // billing, has an address).
    'shipTo': {
      'name': shipTo ? customer.shippingName.trim() : '',
      'phone': shipTo ? customer.shippingPhone.trim() : '',
      'address': shipTo ? customer.shippingAddress.trim() : '',
      'lines': shipTo ? shipToLines(customer) : const <String>[],
    },
    'invoice': {
      'number': invoice.pdfNumberText(s.prefixFor(invoice.type),
              showLeadingZeros: s.showLeadingZeros) ??
          '',
      'title': invoice.invoiceTitle?.isNotEmpty == true
          ? invoice.invoiceTitle!
          : invoice.type,
      'type': invoice.type,
      // "Invoice No." / "Quotation No." / "Credit Note No." / "Receipt No." …
      'numberLabel': '${invoice.type} No.',
      'status': invoice.status ?? '',
      'notes': invoice.notes ?? '',
      'paymentMethod': invoice.payments.isEmpty
          ? ''
          : (invoice.payments.last.paymentMethod ?? ''),
      'salesperson': customField(['salesperson', 'sales person', 'sales']),
      'poNumber': customField(['po', 'purchase order', 'po number']),
      'date': invoice.date.toIso8601String(),
      'dueDate': invoice.dueDate?.toIso8601String(),
      'isInterState': interState,
      'placeOfSupplyCode': pos,
      'placeOfSupply': pos.isEmpty ? '' : GstUtils.stateLabel(pos),
      'custom': {for (final f in invoice.customFields) f.label: f.value},
      'customFields': [
        for (final f in invoice.customFields)
          if (f.value.trim().isNotEmpty) {'label': f.label, 'value': f.value},
      ],
      // Number, date (+ time per setting) and due date only.
      'keyFields': [
        {
          'label': '${invoice.type} No.',
          'value': invoice.pdfNumberText(s.prefixFor(invoice.type),
                  showLeadingZeros: s.showLeadingZeros) ??
              '-',
        },
        {
          'label': 'Dated',
          'value': formatPdfDateTime(invoice.date, s.datePattern,
              showTime: s.showTimeInPdf, timeFormat: s.pdfTimeFormat),
        },
        if (invoice.dueDate != null)
          {
            'label': 'Due Date',
            'value': formatPdfDate(invoice.dueDate!, s.datePattern),
          },
      ],
      // Voucher cells as the GST template prints them: number (labelled by
      // document type), date (+ time
      // per setting), due date, then the filled custom fields.
      'headerFields': [
        {
          'label': '${invoice.type} No.',
          'value': invoice.pdfNumberText(s.prefixFor(invoice.type),
                  showLeadingZeros: s.showLeadingZeros) ??
              '-',
        },
        {
          'label': 'Dated',
          'value': formatPdfDateTime(invoice.date, s.datePattern,
              showTime: s.showTimeInPdf, timeFormat: s.pdfTimeFormat),
        },
        if (invoice.dueDate != null)
          {
            'label': 'Due Date',
            'value': formatPdfDate(invoice.dueDate!, s.datePattern),
          },
        for (final f in invoice.customFields)
          if (f.value.trim().isNotEmpty) {'label': f.label, 'value': f.value},
      ],
      // Place of supply / reverse charge (GST rule 46), as the built-ins.
      'gstLines': [
        for (final l in gstSupplyLines(invoice, showGst: s.showGst))
          {'label': l.$1, 'value': l.$2},
      ],
      // Credit / debit note return + refund lines.
      'returnLines': returnInfoLines(invoice),
    },
    'items': [
      for (var i = 0; i < invoice.items.length; i++)
        () {
          final item = invoice.items[i];
          final line = hsnLines[i];
          final t = split(line.tax);
          return {
            'slNo': i + 1,
            'name': item.product.name,
            'alias': item.product.aliasName ?? '',
            'description': item.printedDescription,
            'typeTag': item.product.type,
            'hsn': item.product.hsncode,
            'qty': item.quantity,
            'unit': item.effectiveUnit,
            'rate': item.effectivePrice,
            'discount': item.totalDiscount,
            'tax': item.taxAmount,
            'amount': item.total,
            'taxRate': line.rate,
            'cgstRate': interState ? 0.0 : line.rate / 2,
            'sgstRate': interState ? 0.0 : line.rate / 2,
            'igstRate': interState ? line.rate : 0.0,
            'taxable': line.taxable,
            'cgst': t.cgst,
            'sgst': t.sgst,
            'igst': t.igst,
            'meta': {
              for (final k in metaKeys)
                k: pdfMetaCellValue(item, k, s.datePattern),
            },
          };
        }(),
    ],
    'taxSummary': taxSummary.values.toList(),
    'charges': [
      for (final c in invoice.additionalCosts)
        {'label': c.label, 'amount': c.amount},
    ],
    'totals': {
      'subtotal': invoice.subtotal,
      'grossSubtotal': invoice.grossSubtotal,
      'discount': invoice.totalDiscount + invoice.invoiceDiscountAmount,
      'tax': invoice.tax,
      'total': invoice.total,
      'amountPaid': invoice.amountPaid,
      'balance': invoice.outstandingBalance,
      'previousBalance': invoice.previousBalance,
      'amountInWords': AmountInWords.amount(invoice.total),
      'taxable': hsnLines.fold<double>(0, (sum, l) => sum + l.taxable),
      'cgst': taxSplit.cgst,
      'sgst': taxSplit.sgst,
      'igst': taxSplit.igst,
      'totalQty': invoice.items.fold<double>(0, (sum, i) => sum + i.quantity),
      'charges': invoice.additionalCosts.fold<double>(0, (sum, c) => sum + c.amount),
      'previousBalanceDue': previousBalanceDue,
      'totalDue': totalDue,
      'roundedTotal': s.showRoundOff
          ? net.rounded
          : (previousBalanceDue > 0 ? totalDue : invoice.total),
      'roundOff': s.showRoundOff ? net.roundOff : 0.0,
      // Like the built-in templates: words only with round-off on, for the
      // rounded total (#116).
      'totalInWords': s.showRoundOff ? AmountInWords.amount(net.rounded, indian: indianWords) : '',
      'taxInWords': AmountInWords.amount(invoice.tax, indian: indianWords),
    },
    'payment': {
      // Same UPI link as the built-in templates' QR (amount = balance due).
      'upiPayload': showUpiQr && (upiId ?? '').trim().isNotEmpty
          ? 'upi://pay?pa=${upiId!.trim()}'
              '&pn=${Uri.encodeComponent(company?.name ?? '')}'
              '&am=${invoice.outstandingBalance.toStringAsFixed(2)}'
              '&cu=${invoice.currencyCode.toUpperCase()}'
              '&tn=${Uri.encodeComponent('Invoice ${invoice.id}')}'
          : '',
      'upiAmount': invoice.outstandingBalance,
      'qrLabel': qrLabel ?? '',
      // QR box title: the uploaded QR's label, else "Pay via UPI"; empty when
      // no QR prints.
      'qrTitle': !showUpiQr ? '' : (qrLabel ?? 'Pay via UPI'),
    },
    'bank': {
      'name': bankAccount?.bankName ?? '',
      'account': bankAccount?.accountNumber ?? '',
      'ifsc': bankAccount?.ifscCode ?? '',
      'iban': bankAccount?.iban ?? '',
      'upi': show(showUpiQr, upiId),
    },
    // Column / row switches for layout `if` conditions.
    'settings': {
      'showGst': s.showGst,
      'showQuantity': s.showQuantity,
      'showDiscount': s.showDiscount,
      // Like the built-ins: the Product/Service tag only when the business
      // sells both.
      'showTypeTag':
          s.showTypeTag && s.businessType == BusinessType.both,
      'showSlNo': s.showSlNo,
      'showTaxColumn': taxColumnOn,
      'showCgstSgst': taxColumnOn && showCgstSgst,
      'showIgst': taxColumnOn && showIgst,
      'showTotalQuantity': s.showTotalQuantity,
      'showRoundOff': s.showRoundOff,
      'showDescription': s.showDescription,
      'descriptionNewLine': s.descriptionNewLine,
      'showBankDetails': s.showBankDetails,
      'showUpiQr': showUpiQr,
      'thankYouNote': s.thankYouNote,
      'logoPosition': s.logoPosition.name, // 'left' | 'right'
      'metadataColumns': [
        for (final k in metaKeys)
          {'key': k, 'label': pdfMetaHeaderText(k), 'width': pdfMetaColFlex(k)},
      ],
    },
  };
}
