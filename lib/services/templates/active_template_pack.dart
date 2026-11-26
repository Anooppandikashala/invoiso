import 'package:flutter/foundation.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/templates/template_pack.dart';
import 'package:invoiso/services/templates/template_pack_store.dart';
import 'package:invoiso_template_engine/invoiso_template_engine.dart' show kTemplateEngineVersion;

/// The installed template a company prints with, ready for the engine.
/// [layout] is decoded in memory for this print only (§9.5b).
class ActiveTemplatePack {
  final String templateId;
  final Map<String, dynamic> layout;

  /// Engine `overlayText`: only "LICENCE VERIFICATION PENDING" (paid licence
  /// 60+ days without a check); null when free or licensed.
  final String? overlayText;

  const ActiveTemplatePack(this.templateId, this.layout, this.overlayText);
}

/// Loads the company's active `.invoiso` template ([templateId] from the
/// `activeTemplatePack` setting). Returns null — and printing falls back to
/// the built-in template — when none is set or it can't be used (file
/// missing, this build can't open it, not genuine, needs a newer engine).
/// Never throws; logs only the template id and the reason.
Future<ActiveTemplatePack?> loadActiveTemplatePack(
  String? templateId, {
  TemplatePackStore? store,
  TemplatePackDecoder? decoder,
  LicenceService? licences,
}) async {
  if (templateId == null || templateId.isEmpty) return null;
  try {
    final bytes = await (store ?? TemplatePackStore()).bytesOf(templateId);
    if (bytes == null) return _skip(templateId, 'file missing');
    final decoded = await (decoder ?? appPackDecoder()).decode(bytes);
    final pack = decoded.pack;
    if (pack == null) return _skip(templateId, decoded.failure?.name ?? 'not decoded');
    if (pack.manifest.templateId != templateId) return _skip(templateId, 'id mismatch');
    if (pack.manifest.minEngine > kTemplateEngineVersion) return _skip(templateId, 'needs newer engine');
    if (pack.manifest.free) return ActiveTemplatePack(templateId, pack.layout, null);
    // No valid licence (or trial ended / not checked in 24 h): not used at all.
    final access = await (licences ?? LicenceService()).accessFor(templateId);
    if (access == TemplateAccess.locked) return _skip(templateId, 'no valid licence');
    return ActiveTemplatePack(templateId, pack.layout, access.overlayText);
  } catch (e) {
    return _skip(templateId, e.runtimeType.toString());
  }
}

ActiveTemplatePack? _skip(String templateId, String reason) {
  debugPrint('Template $templateId not used: $reason');
  return null;
}
