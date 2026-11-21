import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/utils/amount_in_words.dart';
import 'pdf_widgets.dart' show roundNetTotal;

/// Invoice + company + bank → the template engine's data map. The engine
/// never sees app classes; see
/// `packages/invoiso_template_engine/README.md` ("Data contract").
Map<String, dynamic> buildTemplateData(
  Invoice invoice,
  CompanyInfo? company, {
  required String invoicePrefix,
  required bool showLeadingZeros,
  BankAccount? bankAccount,
  String? upiId,
  double previousBalanceDue = 0,
}) {
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
  final shipSame = customer.shippingSameAsBilling;
  final pos = invoice.placeOfSupply ?? '';
  return {
    'company': company == null
        ? <String, dynamic>{}
        : {
            'name': company.name,
            'address': company.address,
            'phone': company.phone,
            'email': company.email,
            'website': company.website,
            'gstin': company.gstin,
            'pan': company.panNumber,
            'fssai': company.fssaiCode,
            'country': company.country,
            'stateCode': companyState,
            'state': stateName(companyState),
          },
    'customer': {
      'name': customer.name,
      'businessName': customer.businessName,
      'address': customer.address,
      'phone': customer.phone,
      'email': customer.email,
      'gstin': customer.gstin,
      'stateCode': customer.stateCode,
      'state': stateName(customer.stateCode),
      'custom': {for (final f in customer.customFields) f.label: f.value},
    },
    'shipTo': {
      'name': shipSame ? customer.name : customer.shippingName,
      'phone': shipSame ? customer.phone : customer.shippingPhone,
      'address': shipSame ? customer.address : customer.shippingAddress,
    },
    'invoice': {
      'number': invoice.pdfNumberText(invoicePrefix,
              showLeadingZeros: showLeadingZeros) ??
          '',
      'title': invoice.invoiceTitle?.isNotEmpty == true
          ? invoice.invoiceTitle!
          : invoice.type,
      'type': invoice.type,
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
            'taxable': line.taxable,
            'cgst': t.cgst,
            'sgst': t.sgst,
            'igst': t.igst,
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
      'roundedTotal': net.rounded,
      'roundOff': net.roundOff,
      'totalInWords': AmountInWords.amount(net.rounded, indian: indianWords),
      'taxInWords': AmountInWords.amount(invoice.tax, indian: indianWords),
    },
    'bank': {
      'name': bankAccount?.bankName ?? '',
      'account': bankAccount?.accountNumber ?? '',
      'ifsc': bankAccount?.ifscCode ?? '',
      'iban': bankAccount?.iban ?? '',
      'upi': upiId ?? '',
    },
  };
}
