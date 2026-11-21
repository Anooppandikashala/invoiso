import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/utils/amount_in_words.dart';

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
}) {
  String customField(List<String> labels) {
    for (final field in invoice.customFields) {
      final label = field.label.toLowerCase();
      if (labels.any((keyword) => label.contains(keyword))) return field.value;
    }
    return '';
  }

  final customer = invoice.customer;
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
          },
    'customer': {
      'name': customer.name,
      'businessName': customer.businessName,
      'address': customer.address,
      'phone': customer.phone,
      'email': customer.email,
      'gstin': customer.gstin,
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
      'isInterState': invoice.isInterState,
    },
    'items': [
      for (final item in invoice.items)
        {
          'name': item.product.name,
          'alias': item.product.aliasName ?? '',
          'description': item.printedDescription,
          'hsn': item.product.hsncode,
          'qty': item.quantity,
          'unit': item.effectiveUnit,
          'rate': item.effectivePrice,
          'discount': item.totalDiscount,
          'tax': item.taxAmount,
          'amount': item.total,
        },
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
