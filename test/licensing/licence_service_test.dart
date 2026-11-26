import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoiso/services/licensing/licence_api.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/licensing/licence_store.dart';

import 'licence_fakes.dart';

const _code = testActivationCode;

void main() {
  late TestSigner signer;
  late FakeLicenceApi api;
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
    signer = TestSigner();
    await signer.init();
    api = FakeLicenceApi();
    now = day0;
  });

  group('activate', () {
    test('stores the server tokens and the licence is active', () async {
      api.activateResult = LicenceApiResult.ok({'licence': await signer.licence(), 'lease': await signer.lease(day0)});
      expect(await service().activate('INVS-0000-0000-0000-0000', 'buyer@example.com'), isNull);
      final held = await service().licences();
      expect(held.single.lid, 'L001001');
      expect(held.single.status, LicenceStatus.active);
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.open);
    });

    test('passes the server error through', () async {
      api.activateResult = const LicenceApiResult.error('active_elsewhere');
      expect(await service().activate('INVS-0000-0000-0000-0000', 'buyer@example.com'), 'active_elsewhere');
      expect(await service().licences(), isEmpty);
    });

    test('rejects tokens bound to another computer', () async {
      api.activateResult = LicenceApiResult.ok({
        'licence': await signer.licence(code: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ'),
        'lease': await signer.lease(day0, code: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ'),
      });
      expect(await service().activate('INVS-0000-0000-0000-0000', 'buyer@example.com'), 'invalid_licence');
    });

    test('activating the same licence again replaces it', () async {
      api.activateResult = LicenceApiResult.ok({'licence': await signer.licence(), 'lease': await signer.lease(day0)});
      await service().activate('k', 'buyer@example.com');
      await service().activate('k', 'buyer@example.com');
      expect((await service().licences()).length, 1);
    });

    test('sends the buyer email with the key', () async {
      await service().activate(' INVS-0000-0000-0000-0000 ', ' buyer@example.com ');
      expect(api.lastEmail, 'buyer@example.com');
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
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.open);
    });
    test('60+ days: verification pending watermark (still prints)', () async {
      expect(await statusAfter(const Duration(days: 61)), LicenceStatus.verificationPending);
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.verificationPending);
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
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.locked);
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

  group('access', () {
    test('no licence for the template: locked', () async {
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.locked);
    });

    test('a Pass (ALL) covers every template', () async {
      await LicenceStore().save([StoredLicence(licence: await signer.licence(tids: ['ALL']), lease: await signer.lease(day0))]);
      expect(await service().accessFor('any-template'), TemplateAccess.open);
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
        expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.locked);
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
      api.verifyResult = LicenceApiResult.ok({'lease': await signer.lease(day0)});
      await service().dailyCheck();
      now = day0.add(const Duration(hours: 23));
      await service().dailyCheck();
      expect(api.verifyCalls, 1);
      now = day0.add(const Duration(hours: 25));
      await service().dailyCheck();
      expect(api.verifyCalls, 2);
    });

    test('an offline check does not block the next try', () async {
      await holdLicence(checked: day0);
      await service().dailyCheck(); // no internet
      now = day0.add(const Duration(hours: 1));
      api.verifyResult = LicenceApiResult.ok({'lease': await signer.lease(now)});
      await service().dailyCheck(); // retried an hour later
      expect(api.verifyCalls, 2);
      now = day0.add(const Duration(hours: 2));
      await service().dailyCheck(); // reached the server: wait 24 h now
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

    test('a renewal code wrapped by an email still works', () async {
      await holdLicence(checked: day0);
      now = day0.add(const Duration(days: 70));
      final code = await signer.lease(now);
      final wrapped = ' ${code.substring(0, 30)}\n${code.substring(30, 60)} \r\n${code.substring(60)}\n';
      expect(await service().renewOffline('L001001', wrapped), isNull);
      expect((await service().licences()).single.status, LicenceStatus.active);
    });

    test('rejects codes for another licence, another PC, or not from us', () async {
      await holdLicence(checked: day0);
      expect(await service().renewOffline('L001001', await signer.lease(day0, lid: 'L009999')), 'wrong_licence');
      expect(await service().renewOffline('L001001', await signer.lease(day0, code: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ')), 'wrong_licence');
      expect(await service().renewOffline('L001001', 'INVL1.abc.def'), 'invalid_code');
    });
  });

  test('watermark text for the template engine: only verification pending', () {
    expect(TemplateAccess.open.overlayText, isNull);
    expect(TemplateAccess.locked.overlayText, isNull);
    expect(TemplateAccess.verificationPending.overlayText, 'LICENCE VERIFICATION PENDING');
  });

  group('trials (7 days, must check in every 24 h)', () {
    final vu = day0.add(const Duration(days: 7)).toIso8601String();
    Future<void> holdTrial({required DateTime checked, bool leaseOnly = false, String? leaseVu}) async {
      await LicenceStore().save([
        StoredLicence(
          licence: await signer.licence(vu: leaseOnly ? null : vu, trial: !leaseOnly),
          lease: await signer.lease(checked, vu: leaseVu ?? vu, trial: true),
        ),
      ]);
    }

    test('checked within 24 h: works, no watermark', () async {
      await holdTrial(checked: day0);
      now = day0.add(const Duration(hours: 23));
      final held = (await service().licences()).single;
      expect(held.trial, isTrue);
      expect(held.status, LicenceStatus.active);
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.open);
    });

    test('24 h without a successful check: locked until a check succeeds', () async {
      await holdTrial(checked: day0);
      now = day0.add(const Duration(hours: 25));
      expect((await service().licences()).single.status, LicenceStatus.trialNeedsCheck);
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.locked);
      api.verifyResult = LicenceApiResult.ok({'lease': await signer.lease(now, vu: vu, trial: true)});
      await service().checkAll();
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.open);
    });

    test('past the end date: expired and locked (by PC clock or by server check time)', () async {
      await holdTrial(checked: day0);
      now = day0.add(const Duration(days: 7, minutes: 1));
      expect((await service().licences()).single.status, LicenceStatus.expired);
      expect(await service().accessFor('gst-tax-invoice'), TemplateAccess.locked);
      // PC clock set back before the end, but the server's check time is past it.
      await holdTrial(checked: day0.add(const Duration(days: 8)));
      now = day0.add(const Duration(days: 6));
      expect((await service().licences()).single.status, LicenceStatus.expired);
    });

    test('clock moved back: locked, no offline grace', () async {
      await holdTrial(checked: day0);
      now = day0.subtract(const Duration(days: 2));
      expect((await service().licences()).single.status, LicenceStatus.trialNeedsCheck);
    });

    test('made a trial later on the server: the signed lease says so', () async {
      // Licence issued as a normal one (no end date, no trial flag) …
      await holdTrial(checked: day0, leaseOnly: true);
      now = day0.add(const Duration(hours: 30));
      // … but the newest lease carries trial + end date: 24 h rule applies.
      expect((await service().licences()).single.trial, isTrue);
      expect((await service().licences()).single.status, LicenceStatus.trialNeedsCheck);
    });

    test('end date in the newest lease wins (e.g. Pass extended)', () async {
      await LicenceStore().save([
        StoredLicence(
          licence: await signer.licence(vu: day0.add(const Duration(days: 1)).toIso8601String()),
          lease: await signer.lease(day0, vu: day0.add(const Duration(days: 400)).toIso8601String()),
        ),
      ]);
      now = day0.add(const Duration(days: 10));
      expect((await service().licences()).single.status, LicenceStatus.active);
    });

    test('daily check runs every 6 h while a trial is held', () async {
      await holdTrial(checked: day0);
      api.verifyResult = LicenceApiResult.ok({'lease': await signer.lease(day0, vu: vu, trial: true)});
      await service().dailyCheck();
      now = day0.add(const Duration(hours: 5));
      await service().dailyCheck();
      expect(api.verifyCalls, 1);
      now = day0.add(const Duration(hours: 7));
      await service().dailyCheck();
      expect(api.verifyCalls, 2);
    });
  });

  group('ended licences (start-up message)', () {
    test('revoked / refunded / moved templates are reported with their reason', () async {
      for (final (error, status) in [
        ('licence_revoked', LicenceStatus.revoked),
        ('licence_refunded', LicenceStatus.refunded),
        ('moved', LicenceStatus.moved),
      ]) {
        await holdLicence(checked: day0, serverError: error);
        expect(await service().endedFor(['gst-tax-invoice']), {'gst-tax-invoice': status}, reason: error);
      }
    });

    test('active, overdue or pending licences and never-licensed templates are not', () async {
      await holdLicence(checked: day0);
      expect(await service().endedFor(['gst-tax-invoice']), isEmpty); // active
      now = day0.add(const Duration(days: 70));
      expect(await service().endedFor(['gst-tax-invoice']), isEmpty); // pending: own reminder
      expect(await service().endedFor(['teal-services']), isEmpty); // never licensed here
    });

    test('a revoked licence is not reported when a Pass still covers the template', () async {
      await LicenceStore().save([
        StoredLicence(
          licence: await signer.licence(lid: 'L001001'),
          lease: await signer.lease(day0, lid: 'L001001'),
          serverError: 'licence_revoked',
        ),
        StoredLicence(
          licence: await signer.licence(lid: 'L001002', tids: ['ALL']),
          lease: await signer.lease(day0, lid: 'L001002'),
        ),
      ]);
      expect(await service().endedFor(['gst-tax-invoice']), isEmpty);
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

    test('removes a licence the server revoked', () async {
      await holdLicence(checked: day0);
      api.deactivateResult = const LicenceApiResult.error('licence_revoked');
      expect(await service().deactivate('L001001'), isNull);
      expect(await service().licences(), isEmpty);
    });
  });
}
