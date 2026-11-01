import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/utils/billing_fields_reference.dart';

void main() {
  test('billing field reference lists the supported placeholders', () {
    const text = BillingFieldsReference.text;

    // Document, customer, seller, item, total and payment fields.
    expect(text, contains('invoice.number'));
    expect(text, contains('invoice.date'));
    expect(text, contains('customer.name'));
    expect(text, contains('company.name'));
    expect(text, contains('description'));
    expect(text, contains('amount'));
    expect(text, contains('subtotal'));
    expect(text, contains('total'));
    expect(text, contains('balance'));
    expect(text, contains('bank.upi'));
    expect(text, contains('CUSTOM FIELDS'));

    // It is a reference only — no settings or layout JSON is embedded.
    expect(text, isNot(contains('"layout"')));
  });
}
