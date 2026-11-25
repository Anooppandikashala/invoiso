import 'dart:convert';

import 'package:http/http.dart' as http;

/// Calls to the marketplace licence server (PaidTemplatesPlan.md §17.1).
class LicenceApi {
  static const _baseUrl = 'https://tupzziommgrciupbmarg.supabase.co/functions/v1';
  // Marketplace publishable key: public by design (also in the website's
  // JavaScript); the functions check the signed licence, not this key.
  static const _publishableKey = 'sb_publishable_UsXTcEY_N-9WzBvkd1N85g_botTVNon';
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;

  LicenceApi({http.Client? client}) : _client = client ?? http.Client();

  /// Activate a key on this computer → `{lid, templateIds, licence, lease}`.
  Future<LicenceApiResult> activate({
    required String key,
    required String activationCode,
    String? businessName,
    String? gstin,
    String? appVersion,
  }) =>
      _post('activate', {
        'key': key,
        'code': activationCode,
        if (businessName != null && businessName.isNotEmpty) 'businessName': businessName,
        if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
        if (appVersion != null) 'appVersion': appVersion,
      });

  /// Daily check → `{templateIds, validUntil, lease}`.
  Future<LicenceApiResult> verify(String licence) => _post('verify', {'licence': licence});

  /// Free this computer's slot so the key can be used on another one.
  Future<LicenceApiResult> deactivate(String licence) => _post('deactivate', {'licence': licence});

  Future<LicenceApiResult> _post(String fn, Map<String, Object> body) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/$fn'),
            headers: {'content-type': 'application/json', 'apikey': _publishableKey},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic> && data['ok'] == true) return LicenceApiResult.ok(data);
      final error = data is Map<String, dynamic> ? data['error'] : null;
      return LicenceApiResult.error(error is String ? error : 'server_error');
    } catch (_) {
      // Offline, timeout, DNS, bad JSON: nothing definitive was said.
      return LicenceApiResult.error(LicenceApiResult.network);
    }
  }
}

class LicenceApiResult {
  static const network = 'network';

  final bool ok;
  final String? error;
  final Map<String, dynamic> data;

  const LicenceApiResult.ok(this.data)
      : ok = true,
        error = null;
  const LicenceApiResult.error(this.error)
      : ok = false,
        data = const {};

  /// Not a decision about the licence (no internet, busy server).
  bool get isTransient => error == network || error == 'rate_limited' || error == 'server_error';
}
