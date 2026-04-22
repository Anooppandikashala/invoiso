import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common.dart';
import '../constants.dart';
import '../database/settings_service.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;

  const UpdateInfo({required this.latestVersion, required this.currentVersion});

  bool get hasUpdate => _isNewer(latestVersion, currentVersion);

  static bool _isNewer(String latest, String current) {
    final l = _parse(latest);
    final c = _parse(current);
    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final clean = version.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}

class UpdateService {
  static const _apiUrl =
      'https://api.github.com/repos/Anooppandikashala/invoiso/releases/latest';
  static const _checkIntervalHours = 24;

  /// Returns [UpdateInfo] if a check was performed (or cached).
  /// Returns null silently on network failure.
  /// Pass [force] to bypass the 24h cache and call the API immediately.
  static Future<UpdateInfo?> checkForUpdate({bool force = false}) async {
    try {
      if (!force) {
        final lastCheck = await SettingsService.getSetting(SettingKey.lastUpdateCheck);
        if (lastCheck != null) {
          final last = DateTime.tryParse(lastCheck);
          final withinWindow = last != null &&
              DateTime.now().difference(last).inHours < _checkIntervalHours;
          if (withinWindow) {
            final cached = await SettingsService.getSetting(SettingKey.lastKnownLatestVersion);
            if (cached != null && cached.isNotEmpty) {
              return UpdateInfo(latestVersion: cached, currentVersion: AppConfig.version);
            }
          }
        }
      }

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final latestTag = (data['tag_name'] as String? ?? '').trim();

        await SettingsService.setSetting(
            SettingKey.lastUpdateCheck, DateTime.now().toIso8601String());
        if (latestTag.isNotEmpty) {
          await SettingsService.setSetting(
              SettingKey.lastKnownLatestVersion, latestTag);
        }

        return UpdateInfo(latestVersion: latestTag, currentVersion: AppConfig.version);
      }
    } catch (_) {
      // Never crash the app over an update check
    }
    return null;
  }

  /// Returns true if the update dialog should be shown for [info].
  static Future<bool> shouldNotify(UpdateInfo info) async {
    if (!info.hasUpdate) return false;
    final last = await SettingsService.getSetting(SettingKey.lastNotifiedVersion);
    return last != info.latestVersion;
  }

  /// Call when the user dismisses the dialog so it won't show again for this version.
  static Future<void> markNotified(String version) async {
    await SettingsService.setSetting(SettingKey.lastNotifiedVersion, version);
  }
}
