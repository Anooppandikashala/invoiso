import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/templates/template_pack.dart';
import 'package:invoiso_template_engine/invoiso_template_engine.dart' show kTemplateEngineVersion;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An installed template, from the index (no decoding needed to list it).
class InstalledPack {
  final String templateId;
  final String name;
  final int version;
  final bool free;
  final DateTime installedAt;

  const InstalledPack({
    required this.templateId,
    required this.name,
    required this.version,
    required this.free,
    required this.installedAt,
  });

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'name': name,
        'version': version,
        'free': free,
        'installedAt': installedAt.toIso8601String(),
      };

  factory InstalledPack.fromJson(Map<String, dynamic> j) => InstalledPack(
        templateId: j['templateId'] as String,
        name: j['name'] as String,
        version: j['version'] as int,
        free: j['free'] == true,
        installedAt: DateTime.tryParse('${j['installedAt']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

enum PackInstallStatus {
  installed,
  updated,
  alreadyInstalled,

  /// A newer version of this template is installed; nothing changed.
  olderThanInstalled,

  /// This build cannot open template files (public-source build).
  notSupported,
  notGenuine,

  /// Needs a newer template engine (app update).
  needsAppUpdate,

  /// Update of a paid template without a valid licence: old version kept.
  licenceNeededForUpdate,
}

class PackInstallResult {
  final PackInstallStatus status;
  final PackManifest? manifest;

  /// Version that was installed before (update / refusal).
  final int? previousVersion;

  const PackInstallResult(this.status, {this.manifest, this.previousVersion});
}

/// Installed `.invoiso` templates, once per computer (PaidTemplatesPlan.md
/// §17.8 P2, §17.9 Q1). Files are kept exactly as received (still
/// encrypted); the decoded layout is never written anywhere (§9.5b).
class TemplatePackStore {
  static const _indexKey = 'template_packs';

  final TemplatePackDecoder _decoder;
  final Future<Directory> Function() _baseDir;
  final Future<bool> Function(String templateId) _isLicensed;
  final DateTime Function() _now;

  TemplatePackStore({
    TemplatePackDecoder? decoder,
    Future<Directory> Function()? baseDir,
    Future<bool> Function(String templateId)? isLicensed,
    DateTime Function()? now,
  })  : _decoder = decoder ?? appPackDecoder(),
        _baseDir = baseDir ?? getApplicationSupportDirectory,
        _isLicensed = isLicensed ??
            ((id) async => await LicenceService().accessFor(id) == TemplateAccess.open),
        _now = now ?? DateTime.now;

  Future<List<InstalledPack>> list() async {
    final raw = (await SharedPreferences.getInstance()).getString(_indexKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => InstalledPack.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<InstalledPack?> find(String templateId) async =>
      (await list()).where((p) => p.templateId == templateId).firstOrNull;

  /// Checks [bytes] and installs or updates the template (§13.4 rules).
  Future<PackInstallResult> install(Uint8List bytes) async {
    final decoded = await _decoder.decode(bytes);
    if (decoded.failure == PackFailure.notSupported) return const PackInstallResult(PackInstallStatus.notSupported);
    final m = decoded.pack?.manifest;
    if (m == null) return const PackInstallResult(PackInstallStatus.notGenuine);
    if (m.minEngine > kTemplateEngineVersion) return PackInstallResult(PackInstallStatus.needsAppUpdate, manifest: m);

    final existing = await find(m.templateId);
    if (existing != null) {
      final previous = existing.version;
      if (m.version == previous) {
        return PackInstallResult(PackInstallStatus.alreadyInstalled, manifest: m, previousVersion: previous);
      }
      if (m.version < previous) {
        return PackInstallResult(PackInstallStatus.olderThanInstalled, manifest: m, previousVersion: previous);
      }
      if (!m.free && !await _isLicensed(m.templateId)) {
        return PackInstallResult(PackInstallStatus.licenceNeededForUpdate, manifest: m, previousVersion: previous);
      }
    }

    // Write beside, then rename: a crash never leaves a half-written template.
    final file = await _file(m.templateId);
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);

    final entry = InstalledPack(
      templateId: m.templateId,
      name: m.name,
      version: m.version,
      free: m.free,
      installedAt: _now(),
    );
    await _saveIndex([...(await list()).where((p) => p.templateId != m.templateId), entry]);
    return PackInstallResult(
      existing == null ? PackInstallStatus.installed : PackInstallStatus.updated,
      manifest: m,
      previousVersion: existing?.version,
    );
  }

  /// The installed file exactly as received, or null if missing.
  Future<Uint8List?> bytesOf(String templateId) async {
    final file = await _file(templateId);
    return await file.exists() ? file.readAsBytes() : null;
  }

  Future<void> remove(String templateId) async {
    final file = await _file(templateId);
    if (await file.exists()) await file.delete();
    await _saveIndex((await list()).where((p) => p.templateId != templateId).toList());
  }

  // templateId is checked by PackManifest (a-z, 0-9, dashes): safe as a file name.
  Future<File> _file(String templateId) async =>
      File('${(await _baseDir()).path}${Platform.pathSeparator}templates${Platform.pathSeparator}$templateId.invoiso');

  Future<void> _saveIndex(List<InstalledPack> packs) async => (await SharedPreferences.getInstance())
      .setString(_indexKey, jsonEncode(packs.map((p) => p.toJson()).toList()));
}
