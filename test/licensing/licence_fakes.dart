import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'package:invoiso/services/licensing/licence_api.dart';

const testActivationCode = 'ABCD-EFGH-JKMN-PQRS';

/// Signs tokens the way the server does, with a test key pair.
class TestSigner {
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

  Future<String> licence({String lid = 'L001001', List<String> tids = const ['gst-tax-invoice'], String code = testActivationCode, String? vu}) =>
      sign('INVS1', {'v': 1, 'lid': lid, 'tids': tids, 'code': code, 'name': 'Shop', 'gstin': null, 'vu': vu, 'iat': 0});

  Future<String> lease(DateTime checked, {String lid = 'L001001', String code = testActivationCode}) =>
      sign('INVL1', {'v': 1, 'lid': lid, 'code': code, 'chk': checked.millisecondsSinceEpoch ~/ 1000});
}

class FakeLicenceApi extends LicenceApi {
  LicenceApiResult activateResult = const LicenceApiResult.error('network');
  LicenceApiResult verifyResult = const LicenceApiResult.error('network');
  LicenceApiResult deactivateResult = const LicenceApiResult.ok({'ok': true});
  int verifyCalls = 0;
  String? lastEmail;

  @override
  Future<LicenceApiResult> activate({required String key, required String email, required String activationCode, String? businessName, String? gstin, String? appVersion}) async {
    lastEmail = email;
    return activateResult;
  }

  @override
  Future<LicenceApiResult> verify(String licence) async {
    verifyCalls++;
    return verifyResult;
  }

  @override
  Future<LicenceApiResult> deactivate(String licence) async => deactivateResult;
}
