import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/services/templates/template_pack.dart';
import 'package:invoiso/services/templates/template_pack_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _pack({String id = 'gst-tax-invoice', int version = 1, bool free = false, int minEngine = 2}) =>
    Uint8List.fromList(utf8.encode('INVDEV1\n${jsonEncode({
          'manifest': {'templateId': id, 'name': 'GST Tax Invoice', 'version': version, 'free': free, 'minEngine': minEngine},
          'layout': {'engine': 2, 'layout': [{'type': 'text', 'value': 'SECRET-LAYOUT-TEXT'}]},
        })}'));

void main() {
  late Directory dir;
  var licensed = false;

  TemplatePackStore store({TemplatePackDecoder decoder = const DevPackDecoder(NoPackDecoder(), enabled: true)}) =>
      TemplatePackStore(
        decoder: decoder,
        baseDir: () async => dir,
        isLicensed: (_) async => licensed,
        now: () => DateTime.utc(2026, 11, 26),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('packs');
    licensed = false;
  });
  tearDown(() => dir.delete(recursive: true));

  test('installs: file is the original bytes, index lists it', () async {
    final bytes = _pack();
    final r = await store().install(bytes);
    expect(r.status, PackInstallStatus.installed);
    expect(await store().bytesOf('gst-tax-invoice'), bytes);
    final listed = (await store().list()).single;
    expect([listed.templateId, listed.name, listed.version, listed.free], ['gst-tax-invoice', 'GST Tax Invoice', 1, false]);
    expect(File('${dir.path}/templates/gst-tax-invoice.invoiso').existsSync(), isTrue);
  });

  test('nothing decoded is stored: index has no layout content', () async {
    await store().install(_pack());
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      expect('${prefs.get(key)}', isNot(contains('SECRET-LAYOUT-TEXT')), reason: key);
    }
    final others = dir.listSync(recursive: true).whereType<File>().where((f) => !f.path.endsWith('.invoiso'));
    expect(others, isEmpty);
  });

  test('same version: already installed; older: refused, newer kept', () async {
    await store().install(_pack(version: 2, free: true));
    expect((await store().install(_pack(version: 2, free: true))).status, PackInstallStatus.alreadyInstalled);
    final older = await store().install(_pack(version: 1, free: true));
    expect(older.status, PackInstallStatus.olderThanInstalled);
    expect(older.previousVersion, 2);
    expect((await store().find('gst-tax-invoice'))!.version, 2);
  });

  test('free template updates without a licence', () async {
    await store().install(_pack(version: 1, free: true));
    final r = await store().install(_pack(version: 2, free: true));
    expect(r.status, PackInstallStatus.updated);
    expect(r.previousVersion, 1);
    expect((await store().list()).length, 1);
  });

  test('paid template: first install allowed (preview), update needs a licence', () async {
    expect((await store().install(_pack(version: 1))).status, PackInstallStatus.installed);
    expect((await store().install(_pack(version: 2))).status, PackInstallStatus.licenceNeededForUpdate);
    expect((await store().find('gst-tax-invoice'))!.version, 1);
    licensed = true;
    expect((await store().install(_pack(version: 2))).status, PackInstallStatus.updated);
    expect((await store().bytesOf('gst-tax-invoice')), _pack(version: 2));
  });

  test('refuses: no decoder, not genuine, needs a newer engine', () async {
    expect((await store(decoder: const NoPackDecoder()).install(_pack())).status, PackInstallStatus.notSupported);
    expect((await store().install(Uint8List.fromList(utf8.encode('INVDEV1\n{}')))).status, PackInstallStatus.notGenuine);
    expect((await store().install(_pack(minEngine: 99))).status, PackInstallStatus.needsAppUpdate);
    expect(await store().list(), isEmpty);
  });

  test('remove deletes the file and the index entry', () async {
    await store().install(_pack());
    await store().install(_pack(id: 'teal-services', free: true));
    await store().remove('gst-tax-invoice');
    expect((await store().list()).map((p) => p.templateId), ['teal-services']);
    expect(await store().bytesOf('gst-tax-invoice'), isNull);
  });
}
