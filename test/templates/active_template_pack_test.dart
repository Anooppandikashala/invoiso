import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/templates/active_template_pack.dart';
import 'package:invoiso/services/templates/template_pack.dart';
import 'package:invoiso/services/templates/template_pack_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Licences extends LicenceService {
  LicenceWatermark watermark = LicenceWatermark.preview;

  @override
  Future<LicenceWatermark> watermarkFor(String templateId) async => watermark;
}

Uint8List _pack({String id = 'gst-tax-invoice', bool free = false, int minEngine = 2}) =>
    Uint8List.fromList(utf8.encode('INVDEV1\n${jsonEncode({
          'manifest': {'templateId': id, 'name': 'GST', 'version': 1, 'free': free, 'minEngine': minEngine},
          'layout': {'engine': 2, 'layout': [{'type': 'text', 'value': 'Hi'}]},
        })}'));

void main() {
  const dev = DevPackDecoder(NoPackDecoder(), enabled: true);
  late Directory dir;
  late TemplatePackStore store;
  late _Licences licences;

  Future<ActiveTemplatePack?> load(String? id, {TemplatePackDecoder decoder = dev}) =>
      loadActiveTemplatePack(id, store: store, decoder: decoder, licences: licences);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('active-pack');
    store = TemplatePackStore(decoder: dev, baseDir: () async => dir, isLicensed: (_) async => true);
    licences = _Licences();
  });
  tearDown(() => dir.delete(recursive: true));

  test('no template set → built-in', () async {
    expect(await load(null), isNull);
    expect(await load(''), isNull);
  });

  test('watermark follows the licence; free templates never get one', () async {
    await store.install(_pack());
    licences.watermark = LicenceWatermark.none;
    final licensed = await load('gst-tax-invoice');
    expect(licensed!.layout['engine'], 2);
    expect(licensed.overlayText, isNull);

    licences.watermark = LicenceWatermark.preview;
    expect((await load('gst-tax-invoice'))!.overlayText, 'PREVIEW');

    licences.watermark = LicenceWatermark.verificationPending;
    expect((await load('gst-tax-invoice'))!.overlayText, 'LICENCE VERIFICATION PENDING');

    await store.install(_pack(id: 'teal-services', free: true));
    licences.watermark = LicenceWatermark.preview;
    expect((await load('teal-services'))!.overlayText, isNull);
  });

  test('falls back to built-in: missing file, no decoder, needs newer engine', () async {
    expect(await load('gst-tax-invoice'), isNull);

    await store.install(_pack());
    expect(await load('gst-tax-invoice', decoder: const NoPackDecoder()), isNull);

    // A file that slipped past install (e.g. restored from a backup).
    File('${dir.path}/templates/gst-tax-invoice.invoiso').writeAsBytesSync(_pack(minEngine: 99));
    expect(await load('gst-tax-invoice'), isNull);
  });

  test('a file that is not the selected template is not used', () async {
    await store.install(_pack());
    File('${dir.path}/templates/gst-tax-invoice.invoiso').writeAsBytesSync(_pack(id: 'other-template'));
    expect(await load('gst-tax-invoice'), isNull);
  });
}
