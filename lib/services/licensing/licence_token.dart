import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Signed tokens issued by the marketplace server (PaidTemplatesPlan.md §17.1).
///
/// Format: `PREFIX.<base64url JSON payload>.<base64url Ed25519 signature>`,
/// signature over the ASCII text `PREFIX.<payload part>`.
///  - `INVS1` offline licence: {v, lid, tids, code, name, gstin, vu, iat}
///  - `INVL1` lease (last successful check): {v, lid, code, chk}
/// Only the public key ships with the app; it can verify, never sign.
class LicenceToken {
  /// Marketplace licence public key (Ed25519, raw 32 bytes, base64).
  static const productionPublicKey = 'HAcOr4nvsvCIDLCpbTAPTCdv9etgpez8EFdByie86Dw=';

  static const licencePrefix = 'INVS1';
  static const leasePrefix = 'INVL1';

  final String raw;
  final String prefix;
  final Map<String, dynamic> payload;

  const LicenceToken._(this.raw, this.prefix, this.payload);

  /// Returns the token if [raw] has [expectedPrefix] and a valid signature
  /// from [publicKeyB64]; null for anything malformed, tampered or foreign.
  static Future<LicenceToken?> verify(
    String raw,
    String expectedPrefix, {
    String publicKeyB64 = productionPublicKey,
  }) async {
    final text = raw.trim();
    final parts = text.split('.');
    if (parts.length != 3 || parts[0] != expectedPrefix) return null;
    try {
      final payloadBytes = _b64urlDecode(parts[1]);
      final signatureBytes = _b64urlDecode(parts[2]);
      final publicKey = SimplePublicKey(base64.decode(publicKeyB64), type: KeyPairType.ed25519);
      final ok = await Ed25519().verify(
        utf8.encode('${parts[0]}.${parts[1]}'),
        signature: Signature(signatureBytes, publicKey: publicKey),
      );
      if (!ok) return null;
      final payload = jsonDecode(utf8.decode(payloadBytes));
      if (payload is! Map<String, dynamic> || payload['v'] != 1) return null;
      return LicenceToken._(text, parts[0], payload);
    } catch (_) {
      return null;
    }
  }

  String get lid => payload['lid'] as String? ?? '';
  String get activationCode => payload['code'] as String? ?? '';

  // INVS1 fields
  List<String> get templateIds => (payload['tids'] as List?)?.whereType<String>().toList() ?? const [];
  String get businessName => payload['name'] as String? ?? '';
  String get gstin => payload['gstin'] as String? ?? '';

  /// 7-day trial (signed into the licence, and into each lease since T1b).
  bool get trial => payload['trial'] == true;

  /// End date: Pass or trial (null = forever). Leases carry the server's current
  /// value since T1b.
  DateTime? get validUntil {
    final vu = payload['vu'];
    return vu is String ? DateTime.tryParse(vu) : null;
  }

  // INVL1 field: server time of the last successful check.
  DateTime? get checkedAt {
    final chk = payload['chk'];
    return chk is int ? DateTime.fromMillisecondsSinceEpoch(chk * 1000, isUtc: true) : null;
  }

  /// Offline renewal request the user sends to us: `INVR1.<b64url {lid, code}>`.
  /// The admin page answers with a new INVL1 lease.
  static String renewalRequest(String lid, String activationCode) =>
      'INVR1.${base64Url.encode(utf8.encode(jsonEncode({'lid': lid, 'code': activationCode}))).replaceAll('=', '')}';

  /// `lid` from a payload part without checking the signature — only for
  /// finding entries that were verified when they were stored.
  static String lidFromPayloadPart(String payloadPart) {
    try {
      final p = jsonDecode(utf8.decode(_b64urlDecode(payloadPart)));
      return p is Map && p['lid'] is String ? p['lid'] as String : '';
    } catch (_) {
      return '';
    }
  }

  static List<int> _b64urlDecode(String s) => base64Url.decode(base64Url.normalize(s));
}
