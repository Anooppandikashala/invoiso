import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// One template listed on the marketplace (catalog.json, PaidTemplatesPlan.md §17.6).
class StoreTemplate {
  final String id;
  final String name;
  final String tagline;
  final List<String> pageSizes;
  final bool free;
  final bool featured;
  final String status; // available / coming-soon / unavailable
  final int? priceInr;
  final int? priceUsd;
  /// MRP, shown crossed out (higher than the price).
  final int? mrpInr;
  final int? mrpUsd;
  /// Season offer: [offerInr]/[offerUsd] through [offerUntil] (last day,
  /// YYYY-MM-DD), then the regular price again.
  final int? offerInr;
  final int? offerUsd;
  final String? offerUntil;
  final String? page;
  final String? thumbnail;

  const StoreTemplate({
    required this.id,
    required this.name,
    this.tagline = '',
    this.pageSizes = const [],
    this.free = false,
    this.featured = false,
    this.status = 'available',
    this.priceInr,
    this.priceUsd,
    this.mrpInr,
    this.mrpUsd,
    this.offerInr,
    this.offerUsd,
    this.offerUntil,
    this.page,
    this.thumbnail,
  });

  factory StoreTemplate.fromJson(Map<String, dynamic> j) {
    final price = j['price'] is Map ? j['price'] as Map : const {};
    final offer = j['offer'] is Map ? j['offer'] as Map : const {};
    final offerPrice = offer['price'] is Map ? offer['price'] as Map : const {};
    final mrp = j['mrp'] is Map ? j['mrp'] as Map : const {};
    final until = offer['until'];
    return StoreTemplate(
      id: '${j['id']}',
      name: '${j['name'] ?? j['id']}',
      tagline: '${j['tagline'] ?? ''}',
      pageSizes: (j['pageSizes'] as List?)?.whereType<String>().toList() ?? const [],
      free: j['free'] == true,
      featured: j['featured'] == true,
      status: '${j['status'] ?? 'available'}',
      priceInr: (price['INR'] as num?)?.toInt(),
      priceUsd: (price['USD'] as num?)?.toInt(),
      mrpInr: (mrp['INR'] as num?)?.toInt(),
      mrpUsd: (mrp['USD'] as num?)?.toInt(),
      offerInr: (offerPrice['INR'] as num?)?.toInt(),
      offerUsd: (offerPrice['USD'] as num?)?.toInt(),
      offerUntil: until is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(until) ? until : null,
      page: j['page'] as String?,
      thumbnail: j['thumbnail'] as String?,
    );
  }

  bool get _hasPrice => !free && priceInr != null && priceUsd != null;

  /// Season offer still running ([now] defaults to today, compared in UTC like the website).
  bool offerRunning([DateTime? now]) =>
      _hasPrice && offerUntil != null && offerInr != null && offerUsd != null &&
      (now ?? DateTime.now()).toUtc().toIso8601String().substring(0, 10).compareTo(offerUntil!) <= 0;

  /// Price to pay now: "₹499 · $9" (the offer price while an offer runs), or
  /// "" when free / no price yet.
  String priceLabel([DateTime? now]) {
    if (!_hasPrice) return '';
    return offerRunning(now) ? '₹$offerInr · \$$offerUsd' : '₹$priceInr · \$$priceUsd';
  }

  /// Shown crossed out before the price: "MRP ₹999 · $15" when an MRP is set,
  /// else the regular price while an offer runs, else "".
  String crossedPriceLabel([DateTime? now]) {
    if (!_hasPrice) return '';
    if (mrpInr != null && mrpUsd != null) return 'MRP ₹$mrpInr · \$$mrpUsd';
    return offerRunning(now) ? '₹$priceInr · \$$priceUsd' : '';
  }
}

class StoreCatalog {
  final String contactEmail;
  final List<StoreTemplate> templates;

  const StoreCatalog({this.contactEmail = '', this.templates = const []});

  factory StoreCatalog.fromJson(Map<String, dynamic> j) {
    final list = (j['templates'] as List?)?.whereType<Map<String, dynamic>>().map(StoreTemplate.fromJson).toList() ?? [];
    // Featured first, otherwise the website's order.
    final ordered = [...list.where((t) => t.featured), ...list.where((t) => !t.featured)];
    return StoreCatalog(
      contactEmail: '${(j['contact'] as Map?)?['email'] ?? ''}',
      templates: ordered,
    );
  }

  String nameOf(String templateId) =>
      templates.where((t) => t.id == templateId).map((t) => t.name).firstOrNull ?? templateId;
}

/// Marketplace catalogue: last good copy cached on this computer
/// (shared_prefs, like the licences), never bundled in the app.
class TemplateCatalogService {
  static const url = 'https://marketplace.invoiso.co.in/catalog.json';
  static const websiteUrl = 'https://marketplace.invoiso.co.in/';
  // Bought templates are downloaded here (licence-checked; paid files are never public).
  static const accountUrl = 'https://marketplace.invoiso.co.in/account/';
  static const _cacheKey = 'store_catalog_cache';
  static const _timeout = Duration(seconds: 8);

  final http.Client _client;

  TemplateCatalogService({http.Client? client}) : _client = client ?? http.Client();

  /// Last good copy, or null if it was never fetched.
  Future<StoreCatalog?> cached() async {
    final raw = (await SharedPreferences.getInstance()).getString(_cacheKey);
    return raw == null ? null : _parse(raw);
  }

  /// Fetch the current catalogue; on any failure returns the cached copy.
  Future<StoreCatalog?> refresh() async {
    try {
      final res = await _client.get(Uri.parse(url)).timeout(_timeout);
      final parsed = res.statusCode == 200 ? _parse(res.body) : null;
      if (parsed != null) {
        await (await SharedPreferences.getInstance()).setString(_cacheKey, res.body);
        return parsed;
      }
    } catch (_) {
      // Offline / timeout: fall back to the cache.
    }
    return cached();
  }

  static StoreCatalog? _parse(String raw) {
    try {
      final j = jsonDecode(raw);
      return j is Map<String, dynamic> ? StoreCatalog.fromJson(j) : null;
    } catch (_) {
      return null;
    }
  }
}
