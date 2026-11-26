import 'package:invoiso/services/licensing/activation_code.dart';
import 'package:invoiso/services/licensing/licence_api.dart';
import 'package:invoiso/services/licensing/licence_store.dart';
import 'package:invoiso/services/licensing/licence_token.dart';

/// What a held licence currently allows (PaidTemplatesPlan.md §17.2).
enum LicenceStatus {
  /// Checked with the server in the last 30 days.
  active,

  /// 30–60 days without a successful check: still works, user is reminded.
  checkOverdue,

  /// 60+ days without a check, or the computer clock was moved back:
  /// template prints with a "Licence verification pending" watermark.
  verificationPending,

  /// The server says the licence was revoked / refunded / has expired.
  revoked,
  refunded,
  expired,

  /// The licence is now active on another computer (or these tokens were
  /// copied from one).
  moved,
}

/// Watermark a paid template must print with.
enum LicenceWatermark {
  none(null),
  verificationPending('LICENCE VERIFICATION PENDING'),
  preview('PREVIEW');

  const LicenceWatermark(this.overlayText);

  /// Text for the engine's `TemplateOptions.overlayText` (English, like the
  /// DECLINED stamp, so every PDF font can draw it).
  final String? overlayText;
}

class HeldLicence {
  final LicenceToken licence;
  final LicenceToken lease;
  final LicenceStatus status;

  const HeldLicence(this.licence, this.lease, this.status);

  String get lid => licence.lid;
  DateTime? get lastCheck => lease.checkedAt;
  bool covers(String templateId) => licence.templateIds.contains(templateId) || licence.templateIds.contains('ALL');
}

class LicenceService {
  static const overdueAfter = Duration(days: 30);
  static const pendingAfter = Duration(days: 60);
  static const _clockSlack = Duration(days: 1);

  // Server answers that are decisions about the licence (not network noise).
  static const _definitive = {
    'invalid_licence': LicenceStatus.revoked,
    'licence_revoked': LicenceStatus.revoked,
    'licence_refunded': LicenceStatus.refunded,
    'licence_expired': LicenceStatus.expired,
    'moved': LicenceStatus.moved,
  };

  final LicenceApi _api;
  final LicenceStore _store;
  final DateTime Function() _now;
  final Future<String> Function() _activationCode;
  final String _publicKey;

  LicenceService({
    LicenceApi? api,
    LicenceStore? store,
    DateTime Function()? now,
    Future<String> Function()? activationCode,
    String publicKey = LicenceToken.productionPublicKey,
  })  : _api = api ?? LicenceApi(),
        _store = store ?? LicenceStore(),
        _now = now ?? DateTime.now,
        _activationCode = activationCode ?? ActivationCode.current,
        _publicKey = publicKey;

  Future<String> activationCode() => _activationCode();

  /// All licences held on this computer with their current status.
  Future<List<HeldLicence>> licences() async {
    final now = _now().toUtc();
    final maxSeen = await _store.maxSeen();
    if (maxSeen == null || now.isAfter(maxSeen)) await _store.setMaxSeen(now);
    final clockMovedBack = maxSeen != null && now.isBefore(maxSeen.subtract(_clockSlack));
    final code = await _activationCode();

    final held = <HeldLicence>[];
    for (final s in await _store.load()) {
      final licence = await LicenceToken.verify(s.licence, LicenceToken.licencePrefix, publicKeyB64: _publicKey);
      final lease = await LicenceToken.verify(s.lease, LicenceToken.leasePrefix, publicKeyB64: _publicKey);
      if (licence == null || lease == null || lease.lid != licence.lid) continue; // tampered: ignore
      held.add(HeldLicence(licence, lease, _status(s, licence, lease, code, now, clockMovedBack)));
    }
    return held;
  }

  LicenceStatus _status(StoredLicence s, LicenceToken licence, LicenceToken lease, String code, DateTime now, bool clockMovedBack) {
    final fromServer = _definitive[s.serverError];
    if (fromServer != null) return fromServer;
    if (licence.activationCode != code || lease.activationCode != code) return LicenceStatus.moved;
    final validUntil = licence.validUntil;
    if (validUntil != null && now.isAfter(validUntil)) return LicenceStatus.expired;
    final checked = lease.checkedAt;
    // Clock behind the last server check or the highest time seen = can't trust it.
    if (checked == null || clockMovedBack || now.isBefore(checked.subtract(_clockSlack))) {
      return LicenceStatus.verificationPending;
    }
    final age = now.difference(checked);
    if (age >= pendingAfter) return LicenceStatus.verificationPending;
    if (age >= overdueAfter) return LicenceStatus.checkOverdue;
    return LicenceStatus.active;
  }

  /// Watermark for a paid template, from the best licence covering it.
  Future<LicenceWatermark> watermarkFor(String templateId) async {
    final statuses = (await licences()).where((l) => l.covers(templateId)).map((l) => l.status).toSet();
    if (statuses.contains(LicenceStatus.active) || statuses.contains(LicenceStatus.checkOverdue)) {
      return LicenceWatermark.none;
    }
    if (statuses.contains(LicenceStatus.verificationPending)) return LicenceWatermark.verificationPending;
    return LicenceWatermark.preview;
  }

  /// Activate [key] on this computer; [email] = the one used to buy it.
  /// Returns null on success, else an error code from the server
  /// (`active_elsewhere`, `invalid_key` = wrong key or email, …) or `network`.
  Future<String?> activate(String key, String email, {String? businessName, String? gstin, String? appVersion}) async {
    final code = await _activationCode();
    final r = await _api.activate(
      key: key.trim(),
      email: email.trim(),
      activationCode: code,
      businessName: businessName,
      gstin: gstin,
      appVersion: appVersion,
    );
    if (!r.ok) return r.error;
    final licence = await LicenceToken.verify('${r.data['licence']}', LicenceToken.licencePrefix, publicKeyB64: _publicKey);
    final lease = await LicenceToken.verify('${r.data['lease']}', LicenceToken.leasePrefix, publicKeyB64: _publicKey);
    if (licence == null || lease == null || licence.activationCode != code) return 'invalid_licence';
    await _replace(licence.lid, StoredLicence(licence: licence.raw, lease: lease.raw));
    return null;
  }

  /// Daily check of every licence. Network trouble changes nothing (the
  /// lease just ages); a server decision is stored and shown.
  Future<void> checkAll() async {
    final stored = await _store.load();
    var reachedServer = stored.isEmpty;
    for (var i = 0; i < stored.length; i++) {
      final s = stored[i];
      final r = await _api.verify(s.licence);
      if (r.error != LicenceApiResult.network) reachedServer = true;
      if (r.ok) {
        final lease = await LicenceToken.verify('${r.data['lease']}', LicenceToken.leasePrefix, publicKeyB64: _publicKey);
        if (lease != null) stored[i] = StoredLicence(licence: s.licence, lease: lease.raw);
      } else if (_definitive.containsKey(r.error)) {
        stored[i] = StoredLicence(licence: s.licence, lease: s.lease, serverError: r.error);
      }
    }
    await _store.save(stored);
    // Offline: don't record, so the hourly timer tries again.
    if (reachedServer) await _store.setLastCheckAttempt(_now());
  }

  /// Run [checkAll] if the last check reaching the server was 24 h+ ago (app start / timer).
  Future<void> dailyCheck() async {
    final last = await _store.lastCheckAttempt();
    if (last != null && _now().toUtc().difference(last) < const Duration(hours: 24)) return;
    await checkAll();
  }

  /// Code the user sends us when the computer has no internet.
  Future<String> renewalRequest(String lid) async => LicenceToken.renewalRequest(lid, await _activationCode());

  /// Paste the renewal code (an INVL1 lease) from us. Null on success, else
  /// `invalid_code` (not ours / tampered) or `wrong_licence` (other licence/PC).
  Future<String?> renewOffline(String lid, String renewalCode) async {
    final lease = await LicenceToken.verify(renewalCode, LicenceToken.leasePrefix, publicKeyB64: _publicKey);
    if (lease == null) return 'invalid_code';
    if (lease.lid != lid || lease.activationCode != await _activationCode()) return 'wrong_licence';
    final stored = await _store.load();
    final i = stored.indexWhere((s) => _lidOf(s.licence) == lid);
    if (i < 0) return 'wrong_licence';
    stored[i] = StoredLicence(licence: stored[i].licence, lease: lease.raw);
    await _store.save(stored);
    return null;
  }

  /// Free this computer's slot (so the key works on another PC) and forget
  /// the licence here. Null on success, else an error code.
  Future<String?> deactivate(String lid) async {
    final stored = await _store.load();
    final s = stored.where((x) => _lidOf(x.licence) == lid).firstOrNull;
    if (s == null) return null;
    final r = await _api.deactivate(s.licence);
    // not_active / moved / revoked…: the server no longer ties it to this PC anyway.
    if (!r.ok && r.error != 'not_active' && !_definitive.containsKey(r.error)) return r.error;
    await _store.save(stored.where((x) => _lidOf(x.licence) != lid).toList());
    return null;
  }

  Future<void> _replace(String lid, StoredLicence entry) async {
    final stored = (await _store.load()).where((s) => _lidOf(s.licence) != lid).toList()..add(entry);
    await _store.save(stored);
  }

  // lid without verifying (stored entries were verified when saved).
  static String _lidOf(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return '';
    return LicenceToken.lidFromPayloadPart(parts[1]);
  }
}
