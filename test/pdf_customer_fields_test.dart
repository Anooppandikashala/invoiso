import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'test_pdf_font_service.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/customer_field_settings.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/services/pdf/pdf_service.dart';
import 'package:invoiso/services/pdf/pdf_settings.dart';
import 'package:invoiso/services/pdf/pdf_widgets.dart';

Customer _customer({bool sameAsBilling = false}) => Customer(
      id: 'c1',
      name: 'ASHA MENON',
      email: 'asha@example.com',
      phone: '9876543210',
      address: 'BILLING STREET 1',
      gstin: '',
      shippingSameAsBilling: sameAsBilling,
      shippingName: 'RAVI (WAREHOUSE)',
      shippingPhone: '9000000001',
      shippingAddress: 'WAREHOUSE 4, PORT ROAD',
      dob: '1990-06-15',
      gender: 'female',
      customFields: const [
        CustomFieldValue(defId: 'ccf-1', label: 'Patient ID', value: 'P-7'),
        CustomFieldValue(defId: 'ccf-2', label: 'Blood Group', value: ''),
      ],
    );

const _allOn = CustomerFieldSettings(
    age: true, dob: true, gender: true, shipping: true, customFields: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('showShipTo', () {
    test('only when enabled, not same-as-billing, and has an address', () {
      expect(showShipTo(_customer(), _allOn), isTrue);
      expect(showShipTo(_customer(), const CustomerFieldSettings()), isFalse);
      expect(showShipTo(_customer(sameAsBilling: true), _allOn), isFalse);
      expect(showShipTo(_customer()..shippingAddress = '  ', _allOn), isFalse);
    });
  });

  test('showShipTo respects the Print-on-PDF switch', () {
    expect(
        showShipTo(_customer(),
            const CustomerFieldSettings(shipping: true, shipToInPdf: false)),
        isFalse);
  });

  test('shipToLines skips empty name/phone and applies phone prefix', () {
    expect(shipToLines(_customer(), phonePrefix: 'Ph: '),
        ['RAVI (WAREHOUSE)', 'Ph: 9000000001', 'WAREHOUSE 4, PORT ROAD']);
    expect(shipToLines(_customer()
          ..shippingName = ''
          ..shippingPhone = ''),
        ['WAREHOUSE 4, PORT ROAD']);
  });

  group('customerExtraLines', () {
    final date = DateTime(2026, 6, 14); // day before 36th birthday

    test('all on: personal line then filled custom fields', () {
      expect(customerExtraLines(_customer(), _allOn, date, 'dd/MM/yyyy'), [
        'Age: 35 · DOB: 15/06/1990 · Gender: Female',
        'Patient ID: P-7',
      ]);
    });

    test('Print-on-PDF switches off: recorded but not printed', () {
      expect(
          customerExtraLines(
              _customer(),
              const CustomerFieldSettings(
                  age: true, dob: true, gender: true,
                  ageInPdf: false, dobInPdf: false, genderInPdf: false),
              date, 'dd/MM/yyyy'),
          isEmpty);
      expect(
          customerExtraLines(
              _customer(),
              const CustomerFieldSettings(
                  age: true, dob: true, gender: true, dobInPdf: false),
              date, 'dd/MM/yyyy'),
          ['Age: 35 · Gender: Female']);
    });

    test('custom field definition with showInPdf false is not printed', () {
      final c = _customer()
        ..customFields = const [
          CustomFieldValue(defId: 'ccf-1', label: 'Patient ID', value: 'P-7'),
          CustomFieldValue(defId: 'ccf-2', label: 'Internal Note', value: 'VIP'),
          CustomFieldValue(defId: 'gone', label: 'Old Field', value: 'x'),
        ];
      expect(
          customerExtraLines(
              c,
              const CustomerFieldSettings(customFields: true, customFieldDefs: [
                CustomFieldDef(id: 'ccf-1', label: 'Patient ID', sortOrder: 0),
                CustomFieldDef(
                    id: 'ccf-2', label: 'Internal Note', sortOrder: 1, showInPdf: false),
              ]),
              date, 'dd/MM/yyyy'),
          ['Patient ID: P-7', 'Old Field: x']); // deleted defs still print
    });

    test('all off: nothing', () {
      expect(
          customerExtraLines(
              _customer(), const CustomerFieldSettings(), date, 'dd/MM/yyyy'),
          isEmpty);
    });

    test('each part independently; manual age when no DOB; separator', () {
      final c = _customer()
        ..dob = ''
        ..age = 42;
      expect(
          customerExtraLines(c, const CustomerFieldSettings(age: true, gender: true),
              date, 'dd/MM/yyyy', separator: ' | '),
          ['Age: 42 | Gender: Female']);
      expect(
          customerExtraLines(_customer()..gender = '',
              const CustomerFieldSettings(gender: true), date, 'dd/MM/yyyy'),
          isEmpty);
    });
  });

  // Renders every template through the real dispatcher with every customer
  // field on (Ship To different from billing) and with everything off.
  // PDFs land in output/customer_fields_test/ for a visual check.
  for (final template in InvoiceTemplate.values) {
    for (final (label, fields) in [('all_on', _allOn), ('all_off', const CustomerFieldSettings())]) {
      test('${template.name} renders customer fields ($label)', () async {
        final pageSize = switch (template) {
          InvoiceTemplate.compact => PageSize.a6,
          InvoiceTemplate.thermal => PageSize.thermal80,
          _ => PageSize.a4,
        };
        final settings = PdfGenerationSettings(
          company: CompanyInfo(
              name: 'TEST CLINIC', address: 'MAIN ROAD', phone: '1', email: '',
              website: '', gstin: '', country: 'India'),
          template: template,
          invoicePrefix: 'INV-',
          showGst: true,
          showQuantity: true,
          showDiscount: true,
          showTypeTag: true,
          businessType: BusinessType.both,
          upiEntries: const [],
          showQrStr: 'false',
          showBankDetails: false,
          bankAccounts: const [],
          logoPosition: LogoPosition.left,
          logoSizePx: 80,
          logoBytes: null,
          thankYouNote: 'Thanks',
          datePattern: 'dd/MM/yyyy',
          showFooterBranding: false,
          themeColor: null,
          showPreviousBalance: false,
          pageFormat: PDFService.pageSizeToFormat(pageSize),
          pageSize: pageSize,
          showTotalQuantity: true,
          pdfTheme: await TestPdfFontService.loadTheme(),
          showCgstSgst: false,
          customerFields: fields,
        );
        final invoice = Invoice(
          id: 'inv1',
          invoiceNumber: '7',
          customer: _customer(),
          items: [
            InvoiceItem(
                product: Product(id: 'p1', name: 'CONSULTATION', description: '', price: 500,
                    stock: 0, hsncode: '', tax_rate: 0),
                quantity: 1),
          ],
          date: DateTime(2026, 6, 14),
          type: 'Invoice',
        );
        final bytes = await PDFService.generateInvoicePDFWithSettings(
                invoice, settings)
            .save();
        expect(bytes, isNotEmpty);
        final out = File(
            'output/customer_fields_test/${template.name}_$label.pdf');
        await out.parent.create(recursive: true);
        await out.writeAsBytes(bytes);
      });
    }
  }
}
