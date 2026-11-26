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
    expect(c.templates.first.priceLabel, '₹499 · \$9');
    expect(c.templates.last.priceLabel, '');
    expect(c.nameOf('gst'), 'GST Tax Invoice');
    expect(c.nameOf('unknown'), 'unknown');
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
