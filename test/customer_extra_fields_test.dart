import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/customer_field_settings.dart';
import 'package:invoiso/widgets/customer_extra_fields.dart';

Customer _base() => Customer(
    id: 'c1', name: 'Asha', email: '', phone: '111', address: 'Bill St', gstin: '');

const _defs = [
  CustomFieldDef(id: 'ccf-1', label: 'Patient ID', sortOrder: 0),
  CustomFieldDef(id: 'ccf-2', label: 'Blood Group', sortOrder: 1),
];

void main() {
  group('CustomerExtraFieldsController', () {
    test('settings off: stored values carried through unchanged', () {
      final stored = _base()
        ..shippingSameAsBilling = false
        ..shippingAddress = 'Warehouse'
        ..dob = '1990-06-15'
        ..age = 30
        ..gender = 'female'
        ..customFields = const [
          CustomFieldValue(defId: 'gone', label: 'Old', value: 'x'),
        ];
      final c = CustomerExtraFieldsController()..load(stored);
      final out = c.applyTo(_base(), const CustomerFieldSettings());

      expect(out.shippingSameAsBilling, isFalse);
      expect(out.shippingAddress, 'Warehouse');
      expect(out.dob, '1990-06-15');
      expect(out.age, 30);
      expect(out.gender, 'female');
      expect(out.customFields.single.defId, 'gone'); // not dropped while off
    });

    test('custom fields on: current defs only, current label, empties dropped', () {
      final stored = _base()
        ..customFields = const [
          CustomFieldValue(defId: 'ccf-1', label: 'Old label', value: 'P-7'),
          CustomFieldValue(defId: 'deleted', label: 'Deleted', value: 'x'),
        ];
      final c = CustomerExtraFieldsController()..load(stored);
      final out = c.applyTo(_base(),
          const CustomerFieldSettings(customFields: true, customFieldDefs: _defs));

      expect(out.customFields, hasLength(1));
      expect(out.customFields.single.label, 'Patient ID');
      expect(out.customFields.single.value, 'P-7');
    });

    test('keepFrom: switched-off fields come from the overwritten customer, not the form',
        () {
      // Blank invoice form (nothing loaded), user saves over an existing
      // customer found by phone: DOB/shipping/custom off must not be wiped.
      final existing = _base()
        ..shippingSameAsBilling = false
        ..shippingAddress = 'Warehouse'
        ..dob = '1990-06-15'
        ..gender = 'male'
        ..customFields = const [
          CustomFieldValue(defId: 'ccf-1', label: 'Patient ID', value: 'P-7'),
        ];
      final c = CustomerExtraFieldsController()..load(null);
      c.gender = 'female'; // gender switched on and edited in the form
      final out = c.applyTo(_base(), const CustomerFieldSettings(gender: true),
          keepFrom: existing);

      expect(out.gender, 'female');
      expect(out.shippingSameAsBilling, isFalse);
      expect(out.shippingAddress, 'Warehouse');
      expect(out.dob, '1990-06-15');
      expect(out.customFields.single.value, 'P-7');
    });

    test('load(null) resets to new-customer defaults', () {
      final c = CustomerExtraFieldsController()
        ..load(_base()..shippingSameAsBilling = false..age = 5);
      c.load(null);
      final out = c.applyTo(_base(), const CustomerFieldSettings());
      expect(out.shippingSameAsBilling, isTrue);
      expect(out.age, isNull);
    });
  });

  group('CustomerExtraFields widget', () {
    late CustomerExtraFieldsController ctrl;
    late GlobalKey<FormState> formKey;
    final billingName = TextEditingController(text: 'Asha');
    final billingPhone = TextEditingController(text: '111');
    final billingAddress = TextEditingController(text: 'Bill St');

    Future<void> pump(WidgetTester tester, CustomerFieldSettings s,
        {bool readOnly = false}) async {
      formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: CustomerExtraFields(
                controller: ctrl,
                settings: s,
                readOnly: readOnly,
                billingName: billingName,
                billingPhone: billingPhone,
                billingAddress: billingAddress,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    setUp(() => ctrl = CustomerExtraFieldsController());

    testWidgets('all settings off renders nothing', (tester) async {
      await pump(tester, const CustomerFieldSettings());
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('same-as-billing hides Ship To; unticking shows it and requires address',
        (tester) async {
      await pump(tester, const CustomerFieldSettings(shipping: true));
      expect(find.text('SHIP TO'), findsOneWidget); // group header always
      expect(find.text('Shipping Address'), findsNothing);
      expect(find.text('Copy from billing'), findsNothing);
      expect(formKey.currentState!.validate(), isTrue);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('Shipping Address'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);

      await tester.tap(find.text('Copy from billing'));
      await tester.pumpAndSettle();
      expect(ctrl.shippingName.text, 'Asha');
      expect(ctrl.shippingPhone.text, '111');
      expect(ctrl.shippingAddress.text, 'Bill St');
      expect(formKey.currentState!.validate(), isTrue);
      expect(ctrl.applyTo(_base(), const CustomerFieldSettings(shipping: true))
          .shippingSameAsBilling, isFalse);
    });

    testWidgets('age validation rejects > 150', (tester) async {
      await pump(tester, const CustomerFieldSettings(age: true));
      await tester.enterText(find.byType(TextFormField), '151');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(find.byType(TextFormField), '42');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('stored DOB makes age read-only and computed from it',
        (tester) async {
      final dob = DateTime(DateTime.now().year - 40, 1, 1);
      ctrl.load(_base()
        ..dob = '${dob.year}-01-01'
        ..age = 99);
      await pump(tester, const CustomerFieldSettings(age: true, dob: true));
      expect(find.text('40'), findsOneWidget);
      expect(find.text('99'), findsNothing);
      expect(find.byTooltip('Calculated from date of birth'), findsOneWidget);
      expect(find.text('01/01/${dob.year}'), findsOneWidget); // app date pattern, with year
    });

    testWidgets('gender dropdown writes code', (tester) async {
      await pump(tester, const CustomerFieldSettings(gender: true));
      expect(find.text('Not specified'), findsNothing); // unset = label only
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female').last);
      await tester.pumpAndSettle();
      expect(ctrl.gender, 'female');
    });

    testWidgets('custom fields render one input per def with its label',
        (tester) async {
      await pump(tester,
          const CustomerFieldSettings(customFields: true, customFieldDefs: _defs));
      expect(find.text('ADDITIONAL DETAILS'), findsOneWidget);
      expect(find.text('PERSONAL DETAILS'), findsNothing); // no personal fields on
      expect(find.text('Patient ID'), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);
    });

    testWidgets('inline puts DOB, Age, Gender in one row with custom decoration',
        (tester) async {
      formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: CustomerExtraFields(
              controller: ctrl,
              settings: const CustomerFieldSettings(age: true, dob: true, gender: true),
              inline: true,
              decoration: (label) =>
                  InputDecoration(labelText: label, hintText: 'flat'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      final dobY = tester.getTopLeft(fields.at(0)).dy;
      expect(tester.getTopLeft(fields.at(1)).dy, dobY);
      expect(tester.getTopLeft(find.byType(DropdownButtonFormField<String>)).dy, dobY);
      expect(find.byIcon(Icons.cake_outlined), findsNothing); // custom decoration, no prefix icon
    });

    testWidgets('narrow form (360px): Ship To header wraps, no overflow',
        (tester) async {
      ctrl.load(_base()..shippingSameAsBilling = false);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: CustomerExtraFields(
                controller: ctrl,
                settings: const CustomerFieldSettings(
                    shipping: true, age: true, dob: true, gender: true),
                inline: true,
                billingName: billingName,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Copy from billing'), findsOneWidget);
    });

    testWidgets('readOnly disables checkbox and hides copy button',
        (tester) async {
      ctrl.load(_base()..shippingSameAsBilling = false..shippingAddress = 'W');
      await pump(tester, const CustomerFieldSettings(shipping: true), readOnly: true);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(find.text('Copy from billing'), findsNothing);
    });
  });

  group('applyCustomerCsvExtraFields', () {
    Customer run(Map<String, String> row, {Customer? existing}) {
      final c = _base();
      applyCustomerCsvExtraFields(c, row.keys.toList(), (col) => row[col] ?? '',
          existing, _defs);
      return c;
    }

    test('parses valid values; custom header matched case-insensitively', () {
      final c = run({
        'shipping_name': 'Ravi',
        'shipping_address': 'Warehouse',
        'dob': '1990-06-15',
        'age': '30',
        'gender': 'Female',
        'custom:patient id': 'P-7',
        'custom:unknown': 'ignored',
      });
      expect(c.shippingSameAsBilling, isFalse);
      expect(c.shippingName, 'Ravi');
      expect(c.dob, '1990-06-15');
      expect(c.age, 30);
      expect(c.gender, 'female');
      expect(c.customFields.single.label, 'Patient ID');
    });

    test('invalid dob/age/gender import as blank', () {
      final c = run({'dob': '15/06/1990', 'age': '200', 'gender': 'x'});
      expect(c.dob, '');
      expect(c.age, isNull);
      expect(c.gender, '');
    });

    test('future dob imports as blank', () {
      expect(run({'dob': '${DateTime.now().year + 1}-01-01'}).dob, '');
    });

    test('empty shipping_address = same as billing', () {
      expect(run({'shipping_address': ''}).shippingSameAsBilling, isTrue);
    });

    test('missing columns keep the existing customer values', () {
      final existing = _base()
        ..shippingSameAsBilling = false
        ..shippingAddress = 'Warehouse'
        ..dob = '1990-06-15'
        ..gender = 'male'
        ..customFields = const [
          CustomFieldValue(defId: 'ccf-1', label: 'Patient ID', value: 'P-7'),
          CustomFieldValue(defId: 'ccf-2', label: 'Blood Group', value: 'O+'),
        ];
      final c = run({'custom:blood group': ''}, existing: existing);
      expect(c.shippingSameAsBilling, isFalse);
      expect(c.shippingAddress, 'Warehouse');
      expect(c.dob, '1990-06-15');
      expect(c.gender, 'male');
      // Present-but-empty custom column clears that value only.
      expect(c.customFields.map((v) => v.defId), ['ccf-1']);
    });
  });
}
