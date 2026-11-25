import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoiso/services/licensing/licence_api.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/licensing/licence_store.dart';

const _code = 'ABCD-EFGH-JKMN-PQRS';

/// Signs tokens the way the server does, with a test key pair.
class _Signer {
  late SimpleKeyPair _pair;
  late String publicKey;

  Future<void> init() async {
    _pair = await Ed25519().newKeyPair();
    publicKey = base64.encode((await _pair.extractPublicKey()).bytes);
  }

  Future<String> sign(String prefix, Map<String, dynamic> payload) async {
    final part = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
    final sig = await Ed25519().sign(utf8.encode('$prefix.$part'), keyPair: _pair);
    return '$prefix.$part.${base64Url.encode(sig.bytes).replaceAll('=', '')}';
  }

  Future<String> licence({String lid = 'L001001', List<String> tids = const ['gst-tax-invoice'], String code = _code, String? vu}) =>
      sign('INVS1', {'v': 1, 'lid': lid, 'tids': tids, 'code': code, 'name': 'Shop', 'gstin': null, 'vu': vu, 'iat': 0});

  Future<String> lease(DateTime checked, {String lid = 'L001001', String code = _code}) =>
      sign('INVL1', {'v': 1, 'lid': lid, 'code': code, 'chk': checked.millisecondsSinceEpoch ~/ 1000});
}

class _FakeApi extends LicenceApi {
  LicenceApiResult activateResult = const LicenceApiResult.error('network');
  LicenceApiResult verifyResult = const LicenceApiResult.error('network');
  LicenceApiResult deactivateResult = const LicenceApiResult.ok({'ok': true});
  int verifyCalls = 0;

  @override
  Future<LicenceApiResult> activate({required String key, required String activationCode, String? businessName, String? gstin, String? appVersion}) async =>
      activateResult;

  @override
  Future<LicenceApiResult> verify(String licence) async {
    verifyCalls++;
    return verifyResult;
  }

  @override
  Future<LicenceApiResult> deactivate(String licence) async => deactivateResult;
}

void main() {
  late _Signer signer;
  late _FakeApi api;
  late DateTime now;
  final day0 = DateTime.utc(2026, 11, 25);

  LicenceService service() => LicenceService(
        api: api,
        store: LicenceStore(),
        now: () => now,
        activationCode: () async => _code,
        publicKey: signer.publicKey,
      );

  Future<void> holdLicence({required DateTime checked, String? vu, String code = _code, String? serverError}) async {
    await LicenceStore().save([
      StoredLicence(
        licence: await signer.licence(vu: vu, code: code),
        lease: await signer.lease(checked, code: code),
        serverError: serverError,
      ),
    ]);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    signer = _Signer();
    await signer.init();
    api = _FakeApi();
    now = day0;
  });

  group('activate', () {
    test('stores the server tokens and the licence is active', () async {
      api.activateResult = LicenceApiResult.ok({'licence': await signer.licence(), 'lease': await signer.lease(day0)});
      expect(await service().activate('INVS-0000-0000-0000-0000'), isNull);
      final held = await service().licences();
      expect(held.single.lid, 'L001001');
      expect(held.single.status, LicenceStatus.active);
      expect(await service().watermarkFor('gst-tax-invoice'), LicenceWatermark.none);
    });

    test('passes the server error through', () async {
      api.activateResult = const LicenceApiResult.error('active_elsewhere');
      expect(await service().activate('INVS-0000-0000-0000-0000'), 'active_elsewhere');
      expect(await service().licences(), isEmpty);
    });

    test('rejects tokens bound to another computer', () async {
      api.activateResult = LicenceApiResult.ok({
        'licence': await signer.licence(code: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ'),
        'lease': await signer.lease(day0, code: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ'),
      });
      expect(await service().activate('INVS-0000-0000-0000-0000'), 'invalid_licence');
    });

    test('activating the same licence again replaces it', () async {
      api.activateResult = LicenceApiResult.ok({'licence': await signer.licence(), 'lease': await signer.lease(day0)});
      await service().activate('k');
      await service().activate('k');
      expect((await service().licences()).length, 1);
    });
  });

  group('status from the signed lease', () {
    Future<LicenceStatus> statusAfter(Duration age) async {
      await holdLicence(checked: day0);
      now = day0.add(age);
      return (await service().licences()).single.status;
    }

    test('under 30 days: active', () async => expect(await statusAfter(const Duration(days: 29)), LicenceStatus.active));
    test('30–60 days: check overdue (still works)', () async {
      expect(await statusAfter(const Duration(days: 40)), LicenceStatus.checkOverdue);
      expect(await service().watermarkFor('gst-tax-invoice'), LicenceWatermark.none);
    });
    test('60+ days: verification pending watermark', () async {
      expect(await statusAfter(const Duration(days: 61)), LicenceStatus.verificationPending);
      expect(await service().watermarkFor('gst-tax-invoice'), LicenceWatermark.verificationPending);
    });

    test('clock moved back below the highest time seen: pending', () async {
      await holdLicence(checked: day0);
      now = day0.add(const Duration(days: 20));
      expect((await service().licences()).single.status, LicenceStatus.active); // records max seen
      now = day0.add(const Duration(days: 5)); // user sets the date back
      expect((await service().licences()).single.status, LicenceStatus.verificationPending);
    });

    test('clock behind the server check time: pending', () async {
      await holdLicence(checked: day0);
      now = day0.subtract(const Duration(days: 3));
      expect((await service().licences()).single.status, LicenceStatus.verificationPending);
    });

    test('Template Pass past its end date: expired', () async {
      await holdLicence(checked: day0, vu: '2026-11-20T23:59:59Z');
      expect((await service().licences()).single.status, LicenceStatus.expired);
      expect(await service().watermarkFor('gst-tax-invoice'), LicenceWatermark.preview);
    });

    test('tokens copied from another computer: moved', () async {
      await holdLicence(checked: day0, code: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ');
      expect((await service().licences()).single.status, LicenceStatus.moved);
    });

    test('tampered stored token is ignored', () async {
      await LicenceStore().save([StoredLicence(licence: 'INVS1.e30.AAAA', lease: await signer.lease(day0))]);
      expect(await service().licences(), isEmpty);
    });
  });

  group('watermark', () {
    test('no licence for the template: preview', () async {
      expect(await service().watermarkFor('gst-tax-invoice'), LicenceWatermark.preview);
    });

    test('a Pass (ALL) covers every template', () async {
      await LicenceStore().save([StoredLicence(licence: await signer.licence(tids: ['ALL']), lease: await signer.lease(day0))]);
      expect(await service().watermarkFor('any-template'), LicenceWatermark.none);
    });
  });

  group('daily check', () {
    test('success renews the lease', () async {
      await holdLicence(checked: day0);
      now = day0.add(const Duration(days: 45));
      api.verifyResult = LicenceApiResult.ok({'lease': await signer.lease(now)});
      await service().checkAll();
      final held = (await service().licences()).single;
      expect(held.status, LicenceStatus.active);
      expect(held.lastCheck, now);
    });

    test('no internet changes nothing', () async {
      await holdLicence(checked: day0);
      now = day0.add(const Duration(days: 45));
      await service().checkAll();
      expect((await service().licences()).single.status, LicenceStatus.checkOverdue);
    });

    test('server decisions are stored', () async {
      for (final (error, status) in [
        ('licence_revoked', LicenceStatus.revoked),
        ('licence_refunded', LicenceStatus.refunded),
        ('moved', LicenceStatus.moved),
      ]) {
        await holdLicence(checked: day0);
        api.verifyResult = LicenceApiResult.error(error);
        await service().checkAll();
        expect((await service().licences()).single.status, status, reason: error);
        expect(await service().watermarkFor('gst-tax-invoice'), LicenceWatermark.preview);
      }
    });

    test('a later success clears a stored server decision', () async {
      await holdLicence(checked: day0, serverError: 'licence_revoked');
      api.verifyResult = LicenceApiResult.ok({'lease': await signer.lease(day0)});
      await service().checkAll();
      expect((await service().licences()).single.status, LicenceStatus.active);
    });

    test('runs at most once per 24 hours', () async {
      await holdLicence(checked: day0);
      await service().dailyCheck();
      now = day0.add(const Duration(hours: 23));
      await service().dailyCheck();
      expect(api.verifyCalls, 1);
      now = day0.add(const Duration(hours: 25));
      await service().dailyCheck();
      expect(api.verifyCalls, 2);
    });
  });

  group('offline renewal', () {
    test('request code carries lid and this computer', () async {
      final r = await service().renewalRequest('L001001');
      final json = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(r.split('.')[1]))));
      expect(json, {'lid': 'L001001', 'code': _code});
    });

    test('a valid renewal code renews the lease', () async {
      await holdLicence(checked: day0);
      now = day0.add(const Duration(days: 70));
      expect(await service().renewOffline('L001001', await signer.lease(now)), isNull);
      expect((await service().licences()).single.status, LicenceStatus.active);
    });

    test('rejects codes for another licence, another PC, or not from us', () async {
      await holdLicence(checked: day0);
      expect(await service().renewOffline('L001001', await signer.lease(day0, lid: 'L009999')), 'wrong_licence');
      expect(await service().renewOffline('L001001', await signer.lease(day0, code: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ')), 'wrong_licence');
      expect(await service().renewOffline('L001001', 'INVL1.abc.def'), 'invalid_code');
    });
  });

  group('deactivate', () {
    test('frees the slot and forgets the licence', () async {
      await holdLicence(checked: day0);
      expect(await service().deactivate('L001001'), isNull);
      expect(await service().licences(), isEmpty);
    });

    test('keeps the licence when the server could not be reached', () async {
      await holdLicence(checked: day0);
      api.deactivateResult = const LicenceApiResult.error('network');
      expect(await service().deactivate('L001001'), 'network');
      expect((await service().licences()).length, 1);
    });
  });
}
