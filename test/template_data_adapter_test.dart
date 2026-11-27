import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/customer_field_settings.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/services/gst/gstr1_builder.dart';
import 'package:invoiso/services/pdf/pdf_preview_sample.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';
import 'package:invoiso/services/pdf/template_data_adapter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

PdfGenerationSettings _settings({
  bool showGst = true,
  bool showPhone = true,
  bool showCustomerPhone = true,
  bool showDiscount = true,
  bool showRoundOff = false,
  BusinessType businessType = BusinessType.both,
  LogoPosition logoPosition = LogoPosition.left,
  Map<String, bool> metadataColumns = const {},
  CustomerFieldSettings customerFields = const CustomerFieldSettings(),
}) =>
    PdfGenerationSettings(
      company: PdfPreviewSample.fallbackCompany(),
      template: InvoiceTemplate.classic,
      invoicePrefix: 'INV-',
      showGst: showGst,
      showQuantity: true,
      showDiscount: showDiscount,
      showTypeTag: true,
      businessType: businessType,
      upiEntries: const [],
      showQrStr: 'false',
      showBankDetails: true,
      bankAccounts: const [],
      logoPosition: logoPosition,
      logoSizePx: 80,
      logoBytes: null,
      thankYouNote: '',
      datePattern: 'dd/MM/yyyy',
      showFooterBranding: true,
      themeColor: null,
      showPreviousBalance: true,
      pageFormat: PdfPageFormat.a4,
      pageSize: PageSize.a4,
      showTotalQuantity: true,
      pdfTheme: pw.ThemeData(),
      showCgstSgst: true,
      showPhone: showPhone,
      showCustomerPhone: showCustomerPhone,
      showRoundOff: showRoundOff,
      metadataColumns: metadataColumns,
      customerFields: customerFields,
    );

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

Map<String, dynamic> _data(Invoice inv,
        {double prev = 0, PdfGenerationSettings? settings}) =>
    buildTemplateData(inv, settings ?? _settings(), previousBalanceDue: prev);

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
    final data = _data(inv, prev: 50, settings: _settings(showRoundOff: true));
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
  });

  test('UPI payload matches the built-in QR link and follows the setting', () {
    final inv = _invoice();
    Map<String, dynamic> payment(bool show) => buildTemplateData(
          inv,
          _settings(),
          upiId: 'sample@upi',
          showUpiQr: show,
        )['payment'] as Map<String, dynamic>;
    final on = payment(true)['upiPayload'] as String;
    expect(on, startsWith('upi://pay?pa=sample@upi&pn='));
    expect(on, contains('&am=${inv.outstandingBalance.toStringAsFixed(2)}'));
    expect(on, contains('&cu=INR'));
    expect(payment(false)['upiPayload'], '');
  });

  test('show/hide settings come through as empty values, like built-ins', () {
    final inv = _invoice();
    final on = _data(inv);
    final off = _data(inv,
        settings: _settings(showGst: false, showPhone: false, showCustomerPhone: false));
    expect(on['company']['phone'], isNotEmpty);
    expect(off['company']['phone'], '');
    expect(off['company']['gstin'], '');
    expect(off['customer']['phone'], '');
    expect(off['customer']['gstin'], '');
    expect(off['invoice']['gstLines'], isEmpty);
    expect(on['invoice']['gstLines'], isNotEmpty);
    expect(on['company']['taxLabel'], 'GSTIN');
  });

  test('charges split like the built-ins (taxed before tax, untaxed after) + extra discount', () {
    final s = _invoice();
    final inv = Invoice(
      id: 't',
      customer: s.customer,
      items: s.items,
      date: s.date,
      type: 'Invoice',
      taxMode: TaxMode.perItem,
      additionalCosts: [
        AdditionalCost(label: 'Freight', amount: 350, taxable: true, taxRate: 18, hsn: '9965'),
        AdditionalCost(label: 'Packing', amount: 120),
      ],
      invoiceDiscountType: InvoiceDiscountType.percent,
      invoiceDiscountValue: 10,
    );
    final d = _data(inv);
    final half = inv.isInterState ? 0.0 : 31.5;
    expect(d['chargesTaxed'], [
      {
        'label': 'Freight', 'amount': inv.chargeTaxableValue(inv.additionalCosts.first), 'hsn': '9965', 'taxRate': 18.0,
        'cgstRate': inv.isInterState ? 0.0 : 9.0, 'sgstRate': inv.isInterState ? 0.0 : 9.0,
        'igstRate': inv.isInterState ? 18.0 : 0.0,
        'cgst': half, 'sgst': half, 'igst': inv.isInterState ? 63.0 : 0.0, 'tax': 63.0, 'total': 413.0,
      },
    ]);
    expect(d['chargesUntaxed'], [
      {'label': 'Packing', 'amount': 120.0},
    ]);
    final t = d['totals'] as Map<String, dynamic>;
    expect(t['extraDiscount'], inv.invoiceDiscountAmount);
    expect(t['extraDiscount'], greaterThan(0));
    expect(t['extraDiscountLabel'], 'Extra Discount (10.0%)');
  });

  test('(Incl) rate, Disc %, reverse charge for the GST grid layouts', () {
    final s = _invoice();
    final item = s.items.first;
    final rate = (_data(s)['items'] as List).first['taxRate'] as double;
    final plain = (_data(s)['items'] as List).first as Map<String, dynamic>;
    expect(plain['rateInclTax'], closeTo(item.effectivePrice * (1 + rate / 100), 1e-9));
    expect(plain['discountPercent'], isNull);
    expect(plain['rateExclTax'], item.effectivePrice, reason: 'price excludes tax');
    expect(plain['totalWithTax'], closeTo((plain['taxable'] as double) + item.taxAmount, 1e-9));
    item.discount = 5;
    item.discountIsPercent = true;
    s.reverseCharge = true;
    final d = _data(s);
    expect((d['items'] as List).first['discountPercent'], 5);
    expect(d['invoice']['reverseCharge'], true);
    expect(d['totals']['reverseChargeTax'], s.tax);
    s.reverseCharge = false;
    expect(_data(s)['totals']['reverseChargeTax'], 0.0);
  });

  test('round off off → no rounding, total stays exact', () {
    final inv = _invoice();
    final t = _data(inv)['totals'] as Map<String, dynamic>;
    expect(t['roundOff'], 0);
    expect(t['roundedTotal'], inv.total);
    expect(t['totalInWords'], '', reason: 'built-ins show words only with round-off on');
  });

  test('column switches and metadata columns reach the layout', () {
    final inv = _invoice();
    final data = _data(inv,
        settings: _settings(showDiscount: false, metadataColumns: {'batchNumber': true}));
    final settings = data['settings'] as Map<String, dynamic>;
    expect(settings['showDiscount'], false);
    expect(settings['metadataColumns'], [
      {'key': 'batchNumber', 'label': 'Batch No.', 'width': 1.4},
    ]);
    expect((data['items'] as List).first['meta'], contains('batchNumber'));
  });

  test('invoice custom fields list and ship-to only when the rule passes', () {
    final inv = _invoice();
    final data = _data(inv);
    expect(data['invoice']['customFields'], [
      {'label': 'Vehicle No', 'value': 'KL-10-AB-1234'},
    ]);
    // Ship To feature off by default → nothing to print.
    expect(data['shipTo']['address'], '');
    expect(data['shipTo']['lines'], isEmpty);
  });

  test('header fields: number, date, then filled custom fields (GST cells)', () {
    final fields = (_data(_invoice())['invoice']['headerFields'] as List)
        .cast<Map<String, dynamic>>();
    expect(fields.map((f) => f['label']).toList(),
        ['Invoice No.', 'Dated', 'Vehicle No']);
    expect(fields.first['value'], 'INV-0042');
    expect(fields.last['value'], 'KL-10-AB-1234');
  });

  test('number label follows the document type', () {
    for (final type in ['Invoice', 'Quotation', 'Credit Note', 'Receipt']) {
      final s = PdfPreviewSample.createSampleInvoice();
      final inv = Invoice(
          id: 't', invoiceNumber: '7', customer: s.customer, items: s.items,
          date: DateTime(2026, 11, 21), type: type);
      final data = _data(inv);
      expect(data['invoice']['numberLabel'], '$type No.');
      expect((data['invoice']['headerFields'] as List).first['label'], '$type No.');
    }
  });

  test('customer additional fields as label/value cells, per PDF switches', () {
    final base = _invoice();
    final inv = Invoice(
      id: 't', invoiceNumber: '1', items: base.items, date: base.date, type: 'Invoice',
      customer: Customer(
        id: 'c', name: 'C', email: '', phone: '', address: '', gstin: '',
        businessName: '', gender: 'female', age: 34,
        customFields: const [
          CustomFieldValue(defId: 'm', label: 'Member ID', value: 'M-001'),
          CustomFieldValue(defId: 'h', label: 'Hidden', value: 'X'),
        ],
      ),
    );
    final fields = (_data(inv,
            settings: _settings(
                customerFields: const CustomerFieldSettings(
                    age: true, gender: true, customFields: true, customFieldDefs: [
              CustomFieldDef(id: 'm', label: 'Member ID', sortOrder: 0),
              CustomFieldDef(id: 'h', label: 'Hidden', sortOrder: 1, showInPdf: false),
            ])))['customer']['fields'] as List)
        .cast<Map<String, dynamic>>();
    expect(fields, [
      {'label': 'Age', 'value': '34'},
      {'label': 'Gender', 'value': 'Female'},
      {'label': 'Member ID', 'value': 'M-001'},
    ]);
    // Feature switches off → nothing.
    expect(_data(inv)['customer']['fields'], isEmpty);
  });

  test('key fields: number, date, due date only (no custom fields)', () {
    final fields = (_data(_invoice())['invoice']['keyFields'] as List)
        .cast<Map<String, dynamic>>();
    expect(fields.map((f) => f['label']).toList(), ['Invoice No.', 'Dated']);
  });

  test('type tag only for product-and-service businesses; logo position', () {
    final inv = _invoice();
    expect(_data(inv)['settings']['showTypeTag'], true);
    expect(_data(inv, settings: _settings(businessType: BusinessType.product))
        ['settings']['showTypeTag'], false);
    expect(_data(inv)['settings']['logoPosition'], 'left');
    expect(_data(inv, settings: _settings(logoPosition: LogoPosition.right))
        ['settings']['logoPosition'], 'right');
  });
}
