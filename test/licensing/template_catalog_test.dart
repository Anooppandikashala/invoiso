import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoiso/services/licensing/template_catalog.dart';

final _body = jsonEncode({
  'version': 1,
  'contact': {'email': 'shop@example.com'},
  'templates': [
    {'id': 'teal', 'name': 'Teal', 'free': true, 'featured': false, 'status': 'available'},
    {'id': 'gst', 'name': 'GST Tax Invoice', 'free': false, 'featured': true, 'status': 'available', 'price': {'INR': 499, 'USD': 9}},
  ],
});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parses contact, prices and puts featured first', () async {
    final c = await TemplateCatalogService(client: MockClient((_) async => http.Response(_body, 200))).refresh();
    expect(c!.contactEmail, 'shop@example.com');
    expect(c.templates.map((t) => t.id), ['gst', 'teal']);
    expect(c.templates.first.priceLabel(), '₹499 · \$9');
    expect(c.templates.last.priceLabel(), '');
    expect(c.nameOf('gst'), 'GST Tax Invoice');
    expect(c.nameOf('unknown'), 'unknown');
  });

  test('MRP and season offer: offer price through the last day, then the regular price', () {
    final t = StoreTemplate.fromJson({
      'id': 'gst', 'name': 'GST', 'free': false, 'price': {'INR': 799, 'USD': 12}, 'mrp': {'INR': 999, 'USD': 15},
      'offer': {'price': {'INR': 499, 'USD': 7}, 'until': '2026-12-31'},
    });
    final lastDay = DateTime.utc(2026, 12, 31, 23, 59);
    expect(t.offerRunning(lastDay), isTrue);
    expect(t.priceLabel(lastDay), '₹499 · \$7');
    expect(t.crossedPriceLabel(lastDay), 'MRP ₹999 · \$15');
    final after = DateTime.utc(2027, 1, 1);
    expect(t.offerRunning(after), isFalse);
    expect(t.priceLabel(after), '₹799 · \$12');
    expect(t.crossedPriceLabel(after), 'MRP ₹999 · \$15');
    // No MRP: the regular price is crossed out only during the offer.
    final noMrp = StoreTemplate.fromJson({
      'id': 'x', 'free': false, 'price': {'INR': 799, 'USD': 12},
      'offer': {'price': {'INR': 499, 'USD': 7}, 'until': '2026-12-31'},
    });
    expect(noMrp.crossedPriceLabel(lastDay), '₹799 · \$12');
    expect(noMrp.crossedPriceLabel(after), '');
    // Broken offer → plain price.
    final plain = StoreTemplate.fromJson({'id': 'y', 'free': false, 'price': {'INR': 799, 'USD': 12}, 'offer': {'until': 'soon'}});
    expect(plain.priceLabel(), '₹799 · \$12');
    expect(plain.crossedPriceLabel(), '');
  });

  test('offline or bad reply falls back to the last good copy', () async {
    await TemplateCatalogService(client: MockClient((_) async => http.Response(_body, 200))).refresh();
    final offline = TemplateCatalogService(client: MockClient((_) async => throw Exception('offline')));
    expect((await offline.refresh())!.templates.length, 2);
    final broken = TemplateCatalogService(client: MockClient((_) async => http.Response('<html>', 200)));
    expect((await broken.refresh())!.templates.length, 2);
  });

  test('never fetched and offline → null', () async {
    final offline = TemplateCatalogService(client: MockClient((_) async => http.Response('', 503)));
    expect(await offline.refresh(), isNull);
    expect(await offline.cached(), isNull);
  });
}
