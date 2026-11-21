import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/services/pdf/pdf_preview_sample.dart';
import 'package:invoiso/services/pdf/template_data_adapter.dart';

Invoice _invoice({bool interState = false}) {
  final s = PdfPreviewSample.createSampleInvoice();
  return Invoice(
    id: 't',
    invoiceNumber: '0042',
    customer: s.customer,
    items: s.items,
    date: DateTime(2026, 11, 21, 14, 5),
    type: 'Invoice',
    taxRate: 0.18,
    taxMode: TaxMode.perItem,
    currencyCode: 'INR',
    currencySymbol: '₹',
    isInterState: interState,
    placeOfSupply: '32',
    customFields: const [
      CustomFieldValue(defId: 'v', label: 'Vehicle No', value: 'KL-10-AB-1234'),
    ],
  );
}

Map<String, dynamic> _data(Invoice inv, {double prev = 0}) => buildTemplateData(
      inv,
      PdfPreviewSample.fallbackCompany(),
      invoicePrefix: 'INV-',
      showLeadingZeros: true,
      previousBalanceDue: prev,
    );

void main() {
  test('tax summary matches the GST report lines and the invoice tax', () {
    final inv = _invoice();
    final data = _data(inv);
    final rows = (data['taxSummary'] as List).cast<Map<String, dynamic>>();
    final lines = Gstr1Builder.hsnLines(inv);

    expect(rows.map((r) => r['hsn']).toSet(), lines.map((l) => l.hsn).toSet());
    final taxable = rows.fold<double>(0, (s, r) => s + r['taxable']);
    final tax = rows.fold<double>(0, (s, r) => s + r['totalTax']);
    expect(taxable, closeTo(lines.fold<double>(0, (s, l) => s + l.taxable), 0.001));
    expect(tax, closeTo(inv.tax, 0.01));
    for (final r in rows) {
      expect(r['cgst'] + r['sgst'], closeTo(r['totalTax'], 0.001));
      expect(r['igst'], 0);
      expect(r['cgstRate'], r['rate'] / 2);
    }
    expect(data['totals']['cgst'] + data['totals']['sgst'], closeTo(inv.tax, 0.001));
  });

  test('interstate invoices put all tax in IGST', () {
    final inv = _invoice(interState: true);
    final data = _data(inv);
    final rows = (data['taxSummary'] as List).cast<Map<String, dynamic>>();
    for (final r in rows) {
      expect(r['cgst'], 0);
      expect(r['igst'], closeTo(r['totalTax'], 0.001));
      expect(r['igstRate'], r['rate']);
    }
    expect(data['totals']['igst'], closeTo(inv.tax, 0.001));
    expect(data['totals']['cgst'], 0);
    final item = (data['items'] as List).first as Map<String, dynamic>;
    expect(item['igst'], closeTo(item['tax'], 0.001));
  });

  test('totals: quantity, previous balance, rounding and words', () {
    final inv = _invoice();
    final data = _data(inv, prev: 50);
    final t = data['totals'] as Map<String, dynamic>;
    expect(t['totalQty'], inv.items.fold<double>(0, (s, i) => s + i.quantity));
    expect(t['totalDue'], closeTo(inv.total + 50, 0.001));
    expect(t['roundedTotal'], (inv.total + 50).roundToDouble());
    expect(t['roundedTotal'] - t['roundOff'], closeTo(inv.total + 50, 0.006));
    expect(t['totalInWords'], isNotEmpty);
    expect(t['taxInWords'], isNotEmpty);
  });

  test('invoice, customer and ship-to fields', () {
    final inv = _invoice();
    final data = _data(inv);
    expect(data['invoice']['number'], 'INV-0042');
    expect(data['invoice']['placeOfSupplyCode'], '32');
    expect(data['invoice']['placeOfSupply'], contains('32'));
    expect(data['invoice']['custom'], {'Vehicle No': 'KL-10-AB-1234'});
    expect((data['items'] as List).first['slNo'], 1);
    expect(data['shipTo']['name'], isNotEmpty);
  });

  test('UPI payload matches the built-in QR link and follows the setting', () {
    final inv = _invoice();
    Map<String, dynamic> payment(bool show) => buildTemplateData(
          inv,
          PdfPreviewSample.fallbackCompany(),
          invoicePrefix: 'INV-',
          showLeadingZeros: true,
          upiId: 'sample@upi',
          showUpiQr: show,
        )['payment'] as Map<String, dynamic>;
    final on = payment(true)['upiPayload'] as String;
    expect(on, startsWith('upi://pay?pa=sample@upi&pn='));
    expect(on, contains('&am=${inv.outstandingBalance.toStringAsFixed(2)}'));
    expect(on, contains('&cu=INR'));
    expect(payment(false)['upiPayload'], '');
  });
}
