import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Verifies developer-issued password reset codes.
///
/// Challenge-response: the locked-out user shares their installationId
/// out-of-band; the developer signs `installationId:utcDayBucket` with a
/// private Ed25519 key (never shipped with the app) and returns the
/// base64 signature as the "response code". This file only holds the
/// public key, so it can't be used to forge codes even if decompiled.
class ResetCodeVerifier {
  ResetCodeVerifier._();

  /// Ed25519 public key bytes. Safe to ship - cannot sign, only verify.
  static const List<int> _publicKeyBytes = [
    32, 32, 192, 59, 67, 127, 76, 119, 253, 86, 122, 201, 212, 124, 139, 248,
    245, 252, 254, 202, 107, 96, 145, 66, 60, 35, 245, 73, 2, 24, 122, 160,
  ];

  /// Days since Unix epoch, computed from UTC. Must match the signer
  /// script's formula exactly.
  static int utcDayBucket([DateTime? now]) {
    final utcNow = (now ?? DateTime.now()).toUtc();
    return utcNow.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  /// Verifies [responseCode] (base64 Ed25519 signature) against
  /// [installationId], trying today/yesterday/day-before UTC day buckets
  /// for ~3 day validity. Returns false on any mismatch or malformed input.
  static Future<bool> verifyResetCode({
    required String installationId,
    required String responseCode,
  }) async {
    late final List<int> signatureBytes;
    try {
      signatureBytes = base64.decode(responseCode.trim());
    } catch (_) {
      return false;
    }

    final algorithm = Ed25519();
    final publicKey = SimplePublicKey(_publicKeyBytes, type: KeyPairType.ed25519);
    final today = utcDayBucket();

    for (final offset in [0, -1, -2]) {
      final bucket = today + offset;
      final payload = utf8.encode('$installationId:$bucket');
      final signature = Signature(signatureBytes, publicKey: publicKey);
      try {
        final valid = await algorithm.verify(payload, signature: signature);
        if (valid) return true;
      } catch (_) {
        // Malformed signature bytes - treat as invalid, keep trying offsets.
      }
    }
    return false;
  }
}
