import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:invoiso/constants.dart';
import 'package:invoiso/services/backend_services.dart';

class CloudflareAnalyticsService {
  static Future<void> sendHeartbeat() async {
    try {
      final installationId =
      await BackendServices.installation.getOrCreateInstallationId();

      await http
          .post(
        Uri.parse(_heartbeatUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "installationId": installationId,
          "platform": Platform.operatingSystem,
          "appVersion": AppConfig.version,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      if(kDebugMode) {
        debugPrint("Analytics heartbeat failed: $e");
      }
    }
  }

  static const _heartbeatUrl = AnalyticsConfig.heartbeatUrl;
}