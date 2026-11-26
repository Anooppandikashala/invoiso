import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:invoiso/services/templates/official_pack_decoder.dart';

/// The decoder the app uses: dev packs in debug builds, then the official one.
TemplatePackDecoder appPackDecoder() => DevPackDecoder(officialPackDecoder());

/// What an `.invoiso` template file says about itself (PaidTemplatesPlan.md
/// §4.2, §13.3). The licence covers [templateId]; [version] only orders updates.
class PackManifest {
  final String templateId;
  final String name;
  final int version;
  final int minEngine;
  final String minAppVersion;
  final bool free;

  const PackManifest({
    required this.templateId,
    required this.name,
    required this.version,
    this.minEngine = 1,
    this.minAppVersion = '',
    this.free = false,
  });

  static final _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  /// Null when a required field is missing or malformed.
  static PackManifest? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['templateId'];
    final name = j['name'];
    final version = j['version'];
    if (id is! String || !_idPattern.hasMatch(id)) return null;
    if (name is! String || name.trim().isEmpty) return null;
    if (version is! int || version < 1) return null;
    final minEngine = j['minEngine'];
    return PackManifest(
      templateId: id,
      name: name.trim(),
      version: version,
      minEngine: minEngine is int ? minEngine : 1,
      minAppVersion: j['minAppVersion'] is String ? j['minAppVersion'] as String : '',
      free: j['free'] == true,
    );
  }
}

/// A decoded template. [layout] is the engine document: it lives in memory
/// only while rendering and is never saved, logged or shown (§9.5b).
class DecodedPack {
  final PackManifest manifest;
  final Map<String, dynamic> layout;

  const DecodedPack(this.manifest, this.layout);
}

enum PackFailure {
  /// This build cannot open `.invoiso` files (built from the public source).
  notSupported,

  /// Damaged, tampered with, or not made by us.
  notGenuine,
}

class PackDecodeResult {
  final DecodedPack? pack;
  final PackFailure? failure;

  const PackDecodeResult.ok(DecodedPack this.pack) : failure = null;
  const PackDecodeResult.failed(PackFailure this.failure) : pack = null;
}

/// Opens `.invoiso` bytes. The real decoder (encryption + signature, §4.2) is
/// private and added to official builds by CI (official_pack_decoder.dart).
abstract class TemplatePackDecoder {
  Future<PackDecodeResult> decode(Uint8List bytes);
}

/// Public-source builds: no template file can be opened.
class NoPackDecoder implements TemplatePackDecoder {
  const NoPackDecoder();

  @override
  Future<PackDecodeResult> decode(Uint8List bytes) async =>
      const PackDecodeResult.failed(PackFailure.notSupported);
}

/// Debug builds only: also opens "dev packs" (`INVDEV1` + plain JSON
/// `{manifest, layout}`, made with tool/make_dev_pack.dart) so the template
/// screens can be tried before the private decoder exists (§17.9 Q5).
/// Release builds never accept them; anything else goes to [next].
class DevPackDecoder implements TemplatePackDecoder {
  static const magic = 'INVDEV1\n';

  final TemplatePackDecoder next;
  final bool enabled;

  const DevPackDecoder(this.next, {this.enabled = kDebugMode});

  @override
  Future<PackDecodeResult> decode(Uint8List bytes) async {
    if (!enabled || !_isDevPack(bytes)) return next.decode(bytes);
    try {
      final j = jsonDecode(utf8.decode(bytes.sublist(magic.length)));
      final manifest = PackManifest.fromJson(j is Map ? j['manifest'] : null);
      final layout = j is Map ? j['layout'] : null;
      if (manifest == null || layout is! Map<String, dynamic>) {
        return const PackDecodeResult.failed(PackFailure.notGenuine);
      }
      return PackDecodeResult.ok(DecodedPack(manifest, layout));
    } catch (_) {
      return const PackDecodeResult.failed(PackFailure.notGenuine);
    }
  }

  static bool _isDevPack(Uint8List bytes) {
    final m = utf8.encode(magic);
    if (bytes.length < m.length) return false;
    for (var i = 0; i < m.length; i++) {
      if (bytes[i] != m[i]) return false;
    }
    return true;
  }
}
