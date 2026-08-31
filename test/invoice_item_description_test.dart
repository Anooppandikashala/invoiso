// The optional per-line description added in v40. It is strictly opt-in: it
// never falls back to the product's own description, because every row that
// predates v40 has a null description alongside a populated
// product_description — falling back would print text on historical invoices
// that was not on them when they were issued.
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';

Product _product({String description = 'Portland cement, 50kg bag'}) => Product(
      id: 'p1',
      name: 'CEMENT ACC',
      description: description,
      price: 370,
      stock: 10,
      hsncode: '2523',
      tax_rate: 0,
    );

void main() {
  test('a line with no description of its own renders nothing', () {
    final item = InvoiceItem(product: _product(), quantity: 1);

    expect(item.description, isNull);
    // The product has a description; the line must still render empty.
    expect(item.effectiveDescription, isEmpty);
  });

  test('a line description is used verbatim', () {
    final item = InvoiceItem(
      product: _product(),
      quantity: 1,
      description: 'Grade 53, delivered to site',
    );

    expect(item.effectiveDescription, 'Grade 53, delivered to site');
    // The product itself is untouched — editing a line never writes back.
    expect(item.product.description, 'Portland cement, 50kg bag');
  });

  test('whitespace-only text counts as empty', () {
    final item =
        InvoiceItem(product: _product(), quantity: 1, description: '   ');

    expect(item.effectiveDescription, isEmpty);
  });

  test('every other line field is unchanged by the new one', () {
    final item = InvoiceItem(product: _product(), quantity: 2);

    expect(item.effectivePrice, 370);
    expect(item.total, 740);
  });
}
