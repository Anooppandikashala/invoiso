import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:invoiso/services/backend_services.dart';
import 'package:http/http.dart' as http;
import 'package:invoiso/common/common.dart';

class FaqService {
  static const _remoteUrl = 'https://invoiso.co.in/assets/data/faq.json';
  static const _bundledAssetPath = 'assets/data/faq.json';
  static const _refreshIntervalHours = 6;

  /// Returns the FAQ data as a decoded map ({version, categories, items}).
  /// Tries the remote copy (refreshed at most every 6h, or on [force]),
  /// falls back to the last cached copy, then to the bundled asset.
  static Future<Map<String, dynamic>> load({bool force = false}) async {
    if (!force) {
      final lastFetch = await BackendServices.settings.getSetting(SettingKey.lastFaqFetch);
      if (lastFetch != null) {
        final last = DateTime.tryParse(lastFetch);
        final withinWindow = last != null &&
            DateTime.now().difference(last).inHours < _refreshIntervalHours;
        if (withinWindow) {
          final cached = await BackendServices.settings.getSetting(SettingKey.faqCache);
          if (cached != null && cached.isNotEmpty) {
            return jsonDecode(cached) as Map<String, dynamic>;
          }
        }
      }
    }

    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        await BackendServices.settings.setSetting(SettingKey.faqCache, response.body);
        await BackendServices.settings.setSetting(
            SettingKey.lastFaqFetch, DateTime.now().toIso8601String());
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fall through to cache/bundled copy below.
    }

    final cached = await BackendServices.settings.getSetting(SettingKey.faqCache);
    if (cached != null && cached.isNotEmpty) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }

    final bundled = await rootBundle.loadString(_bundledAssetPath);
    return jsonDecode(bundled) as Map<String, dynamic>;
  }
}
