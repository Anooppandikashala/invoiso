import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/services/templates/template_pack.dart';

Uint8List _devPack(Object? manifest, {Object? layout = const {'engine': 2, 'layout': []}}) =>
    Uint8List.fromList(utf8.encode('INVDEV1\n${jsonEncode({'manifest': manifest, 'layout': layout})}'));

const _manifest = {'templateId': 'gst-tax-invoice', 'name': 'GST Tax Invoice', 'version': 3, 'minEngine': 2};

void main() {
  test('public-source builds cannot open any template file', () async {
    final r = await const NoPackDecoder().decode(_devPack(_manifest));
    expect(r.failure, PackFailure.notSupported);
    expect(r.pack, isNull);
  });

  test('debug build opens a dev pack', () async {
    final r = await const DevPackDecoder(NoPackDecoder(), enabled: true).decode(_devPack(_manifest));
    expect(r.pack!.manifest.templateId, 'gst-tax-invoice');
    expect(r.pack!.manifest.version, 3);
    expect(r.pack!.manifest.minEngine, 2);
    expect(r.pack!.manifest.free, isFalse);
    expect(r.pack!.layout['engine'], 2);
  });

  test('release build refuses dev packs (falls through to the real decoder)', () async {
    final r = await const DevPackDecoder(NoPackDecoder(), enabled: false).decode(_devPack(_manifest));
    expect(r.failure, PackFailure.notSupported);
  });

  test('other files go to the real decoder', () async {
    final r = await const DevPackDecoder(NoPackDecoder(), enabled: true)
        .decode(Uint8List.fromList(utf8.encode('INVT…encrypted')));
    expect(r.failure, PackFailure.notSupported);
  });

  test('broken dev packs are not genuine', () async {
    const dev = DevPackDecoder(NoPackDecoder(), enabled: true);
    for (final bytes in [
      Uint8List.fromList(utf8.encode('INVDEV1\n{not json')),
      _devPack({..._manifest, 'templateId': 'Bad Id'}),
      _devPack({..._manifest, 'version': 0}),
      _devPack({..._manifest, 'name': ' '}),
      _devPack(_manifest, layout: 'text'),
    ]) {
      expect((await dev.decode(bytes)).failure, PackFailure.notGenuine);
    }
  });
}
