import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:invoiso/utils/machine_id.dart';

/// This computer's activation code, e.g. `7KQ2-M9XD-4TRB-0HZC`
/// (PaidTemplatesPlan.md §17.2). A licence is bound to it on the server,
/// so one licence = one computer.
///
/// Derived from the machine ID, so a reinstall on the same computer gives the
/// same code. When no machine ID is available a random code is kept in
/// shared_prefs instead (then a reinstall changes it).
class ActivationCode {
  ActivationCode._();

  static const _fallbackPrefsKey = 'licence_activation_code_fallback';
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford base32

  /// Server accepts `^[A-Z0-9]{4}(-[A-Z0-9]{4}){2,4}$`; we always use 4 groups.
  static final pattern = RegExp(r'^[A-Z0-9]{4}(-[A-Z0-9]{4}){3}$');

  static Future<String> current() async {
    final machine = await machineIdHash();
    if (machine != null) return fromMachineId(machine);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_fallbackPrefsKey);
    if (stored != null && pattern.hasMatch(stored)) return stored;
    final random = Random.secure();
    final code = _format(List.generate(10, (_) => random.nextInt(256)));
    await prefs.setString(_fallbackPrefsKey, code);
    return code;
  }

  /// 80 bits of a hash of the (already salted) machine ID, as 16 base32 chars.
  static String fromMachineId(String machineIdHash) =>
      _format(sha256.convert(utf8.encode('invoiso-activation:$machineIdHash')).bytes.sublist(0, 10));

  static String _format(List<int> bytes) {
    var bits = 0;
    var value = 0;
    final out = StringBuffer();
    for (final b in bytes) {
      value = (value << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(_alphabet[(value >> bits) & 31]);
      }
      value &= (1 << bits) - 1; // keep only unused bits (no 64-bit overflow)
    }
    final s = out.toString(); // 80 bits → exactly 16 chars
    return '${s.substring(0, 4)}-${s.substring(4, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}';
  }
}
