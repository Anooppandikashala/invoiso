import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:invoiso/services/licensing/activation_code.dart';
import 'package:invoiso/services/licensing/licence_token.dart';

// Tokens in the fixture were signed by the marketplace server code
// (supabase/functions/_shared/licence.ts) with a throwaway test key pair,
// so these tests prove the app reads exactly what the server writes.
void main() {
  final fixture = jsonDecode(File('test/fixtures/licence_tokens.json').readAsStringSync()) as Map<String, dynamic>;
  final testKey = fixture['publicKey'] as String;
  final licence = fixture['licence'] as String;
  final lease = fixture['lease'] as String;

  group('LicenceToken', () {
    test('accepts a server-signed licence and reads its fields', () async {
      final t = await LicenceToken.verify(licence, LicenceToken.licencePrefix, publicKeyB64: testKey);
      expect(t, isNotNull);
      expect(t!.lid, 'L001234');
      expect(t.templateIds, ['gst-tax-invoice']);
      expect(t.activationCode, 'ABCD-EFGH-JKMN-PQRS');
      expect(t.businessName, 'Test Traders');
      expect(t.gstin, '32ABCDE1234F1Z5');
      expect(t.validUntil, isNull);
    });

    test('accepts a server-signed lease and reads the check time', () async {
      final t = await LicenceToken.verify(lease, LicenceToken.leasePrefix, publicKeyB64: testKey);
      expect(t, isNotNull);
      expect(t!.lid, 'L001234');
      expect(t.checkedAt, DateTime.utc(2026, 11, 25));
    });

    test('rejects a token signed with another key', () async {
      expect(await LicenceToken.verify(fixture['licenceOtherKey'] as String, 'INVS1', publicKeyB64: testKey), isNull);
      // and the real production key does not accept test tokens
      expect(await LicenceToken.verify(licence, 'INVS1'), isNull);
    });

    test('rejects a tampered payload', () async {
      final parts = licence.split('.');
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      payload['tids'] = ['gst-tax-invoice', 'ALL'];
      final forged = '${parts[0]}.${base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '')}.${parts[2]}';
      expect(await LicenceToken.verify(forged, 'INVS1', publicKeyB64: testKey), isNull);
    });

    test('rejects the wrong prefix and malformed input', () async {
      expect(await LicenceToken.verify(lease, 'INVS1', publicKeyB64: testKey), isNull);
      expect(await LicenceToken.verify(licence, 'INVL1', publicKeyB64: testKey), isNull);
      for (final bad in ['', 'INVS1', 'INVS1..', 'INVS1.%%%.%%%', 'INVS1.e30.AAAA']) {
        expect(await LicenceToken.verify(bad, 'INVS1', publicKeyB64: testKey), isNull, reason: bad);
      }
    });

    test('accepts surrounding whitespace (pasted renewal codes)', () async {
      expect(await LicenceToken.verify('  $lease\n', 'INVL1', publicKeyB64: testKey), isNotNull);
    });

    test('renewal request is INVR1 with lid and code', () {
      final r = LicenceToken.renewalRequest('L001234', 'ABCD-EFGH-JKMN-PQRS');
      expect(r, startsWith('INVR1.'));
      final json = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(r.split('.')[1]))));
      expect(json, {'lid': 'L001234', 'code': 'ABCD-EFGH-JKMN-PQRS'});
    });
  });

  group('ActivationCode', () {
    test('is stable for a machine and matches the server format', () {
      final a = ActivationCode.fromMachineId('11111111-2222-3333-4444-555555555555');
      expect(a, ActivationCode.fromMachineId('11111111-2222-3333-4444-555555555555'));
      expect(ActivationCode.pattern.hasMatch(a), isTrue, reason: a);
      expect(RegExp(r'^[A-Z0-9]{4}(-[A-Z0-9]{4}){2,4}$').hasMatch(a), isTrue);
    });

    test('differs between machines', () {
      final codes = {for (var i = 0; i < 50; i++) ActivationCode.fromMachineId('machine-$i')};
      expect(codes.length, 50);
    });
  });
}
