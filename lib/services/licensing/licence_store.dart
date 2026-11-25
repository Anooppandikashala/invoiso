import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One licence held on this computer: the signed tokens plus the last
/// definitive answer from the server (e.g. `licence_revoked`).
class StoredLicence {
  final String licence; // INVS1 token
  final String lease; // INVL1 token (last successful check)
  final String? serverError;

  const StoredLicence({required this.licence, required this.lease, this.serverError});

  Map<String, dynamic> toJson() => {
        'licence': licence,
        'lease': lease,
        if (serverError != null) 'serverError': serverError,
      };

  factory StoredLicence.fromJson(Map<String, dynamic> j) => StoredLicence(
        licence: j['licence'] as String,
        lease: j['lease'] as String,
        serverError: j['serverError'] as String?,
      );
}

/// Device-level storage (shared_prefs, like the installation id): licences
/// are bound to this computer, so they are not in the company database and
/// not in backups (PaidTemplatesPlan.md §17.5 Q3).
class LicenceStore {
  static const _licencesKey = 'template_licences';
  static const _maxSeenKey = 'licence_max_seen_time';
  static const _lastCheckKey = 'licence_last_check_attempt';

  Future<List<StoredLicence>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_licencesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => StoredLicence.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<StoredLicence> licences) async =>
      (await SharedPreferences.getInstance()).setString(_licencesKey, jsonEncode(licences.map((l) => l.toJson()).toList()));

  /// Highest clock time seen, for the clock-rollback guard.
  Future<DateTime?> maxSeen() async => _readTime(_maxSeenKey);
  Future<void> setMaxSeen(DateTime t) async => _writeTime(_maxSeenKey, t);

  /// When the daily check last ran (success or not).
  Future<DateTime?> lastCheckAttempt() async => _readTime(_lastCheckKey);
  Future<void> setLastCheckAttempt(DateTime t) async => _writeTime(_lastCheckKey, t);

  Future<DateTime?> _readTime(String key) async {
    final ms = (await SharedPreferences.getInstance()).getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> _writeTime(String key, DateTime t) async =>
      (await SharedPreferences.getInstance()).setInt(key, t.toUtc().millisecondsSinceEpoch);
}
