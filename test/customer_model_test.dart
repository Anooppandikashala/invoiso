import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer.dart';

void main() {
  test('toMap/fromMap round trip keeps shipping, personal and custom fields',
      () {
    final c = Customer(
      id: 'c1',
      name: 'Asha',
      email: '',
      phone: '',
      address: 'Billing St',
      gstin: '',
      shippingSameAsBilling: false,
      shippingName: 'Ravi',
      shippingPhone: '999',
      shippingAddress: 'Warehouse 4',
      dob: '1990-06-15',
      age: 20,
      gender: 'female',
      customFields: const [
        CustomFieldValue(defId: 'ccf-1', label: 'Patient ID', value: 'P-7'),
      ],
    );

    final r = Customer.fromMap(c.toMap());

    expect(r.shippingSameAsBilling, isFalse);
    expect(r.shippingName, 'Ravi');
    expect(r.shippingPhone, '999');
    expect(r.shippingAddress, 'Warehouse 4');
    expect(r.dob, '1990-06-15');
    expect(r.age, 20);
    expect(r.gender, 'female');
    expect(r.customFields.single.label, 'Patient ID');
    expect(r.customFields.single.value, 'P-7');
  });

  test('fromMap on a pre-v50 row (missing keys) uses defaults', () {
    final r = Customer.fromMap({
      'id': 'c1',
      'name': 'Old',
      'email': '',
      'phone': '',
      'address': 'Addr',
      'gstin': '',
    });

    expect(r.shippingSameAsBilling, isTrue);
    expect(r.shippingAddress, '');
    expect(r.dob, '');
    expect(r.age, isNull);
    expect(r.gender, '');
    expect(r.customFields, isEmpty);
  });

  group('ageOn', () {
    Customer make({String dob = '', int? age}) => Customer(
        id: 'c', name: 'n', email: '', phone: '', address: '', gstin: '',
        dob: dob, age: age);

    test('uses dob when set, ignoring manual age', () {
      final c = make(dob: '1990-06-15', age: 99);
      expect(c.ageOn(DateTime(2026, 6, 14)), 35); // day before birthday
      expect(c.ageOn(DateTime(2026, 6, 15)), 36); // birthday
      expect(c.ageOn(DateTime(2026, 1, 1)), 35);
    });

    test('falls back to manual age when dob empty', () {
      expect(make(age: 42).ageOn(DateTime(2026, 1, 1)), 42);
    });

    test('null when neither set', () {
      expect(make().ageOn(DateTime(2026, 1, 1)), isNull);
    });
  });
}
