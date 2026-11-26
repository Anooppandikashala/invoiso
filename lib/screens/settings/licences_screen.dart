import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/settings/template_store_dialog.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/licensing/template_catalog.dart';

/// Settings → Licences: this computer's activation code and the template
/// licences held on it (PaidTemplatesPlan.md §17.3). Device-level, so the
/// same for every company on this computer.
class LicencesScreen extends ConsumerStatefulWidget {
  /// Open the Enter licence key dialog right away (from PDF Settings).
  final bool openEnterKey;
  final LicenceService? service;

  const LicencesScreen({super.key, this.openEnterKey = false, this.service});

  @override
  ConsumerState<LicencesScreen> createState() => _LicencesScreenState();
}

class _LicencesScreenState extends ConsumerState<LicencesScreen> {
  late final LicenceService _service = widget.service ?? LicenceService();
  String _code = '';
  List<HeldLicence> _licences = [];
  StoreCatalog? _catalog;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCatalog();
    if (widget.openEnterKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enterKey());
    }
  }

  Future<void> _load() async {
    final code = await _service.activationCode();
    final licences = await _service.licences();
    if (!mounted) return;
    setState(() {
      _code = code;
      _licences = licences;
    });
  }

  // Template names only; the screen works without them (ids shown).
  Future<void> _loadCatalog() async {
    final service = TemplateCatalogService();
    final cached = await service.cached();
    if (mounted && cached != null) setState(() => _catalog = cached);
    final fresh = await service.refresh();
    if (mounted && fresh != null) setState(() => _catalog = fresh);
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _enterKey() async {
    final l10n = AppLocalizations.of(context)!;
    final keyController = TextEditingController();
    final emailController = TextEditingController();
    bool filled() => keyController.text.trim().isNotEmpty && emailController.text.trim().isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.licencesKeyDialogTitle),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.licencesKeyHelp),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: l10n.licencesKeyLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: l10n.licencesEmailLabel,
                    helperText: l10n.licencesEmailHelp,
                    border: const OutlineInputBorder()),
                onSubmitted: (_) {
                  if (filled()) Navigator.pop(ctx, true);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () {
                if (filled()) Navigator.pop(ctx, true);
              },
              child: Text(l10n.licencesActivate)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final company = await ref.read(companyInfoRepositoryProvider).getCompanyInfo();
      final error = await _service.activate(keyController.text, emailController.text,
          businessName: company?.name,
          gstin: company?.gstin,
          appVersion: ref.read(appEditionConfigProvider).version);
      if (!mounted) return;
      _snack(error == null ? l10n.licencesActivated : licenceErrorText(l10n, error));
    });
  }

  Future<void> _checkNow() => _run(() async {
        await _service.checkAll();
        await _loadCatalog();
        if (mounted) _snack(AppLocalizations.of(context)!.licencesChecked);
      });

  Future<void> _renewOffline(HeldLicence l) async {
    final l10n = AppLocalizations.of(context)!;
    final request = await _service.renewalRequest(l.lid);
    final controller = TextEditingController();
    if (!mounted) return;
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.licencesRenewTitle),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.licencesRenewStep1),
              const SizedBox(height: 8),
              _copyRow(request),
              const SizedBox(height: 16),
              Text(l10n.licencesRenewStep2),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                // Wraps so the long code is visible, but Enter applies: codes
                // never contain line breaks.
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => Navigator.pop(ctx, v),
                decoration: InputDecoration(
                    labelText: l10n.licencesRenewCodeLabel, border: const OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(l10n.actionApply)),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    await _run(() async {
      final error = await _service.renewOffline(l.lid, code);
      if (mounted) _snack(error == null ? l10n.licencesRenewed : licenceErrorText(l10n, error));
    });
  }

  Future<void> _deactivate(HeldLicence l) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.licencesDeactivate),
        content: Text(l10n.licencesDeactivateConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.licencesDeactivate)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final error = await _service.deactivate(l.lid);
      if (mounted) _snack(error == null ? l10n.licencesDeactivated : licenceErrorText(l10n, error));
    });
  }

  Widget _copyRow(String text, {TextStyle? style}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        // Flexible (not Expanded): copy button sits right after the code.
        Flexible(
          child: SelectableText(text,
              style: style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: l10n.licencesCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            _snack(l10n.copiedToClipboardMessage(text));
          },
        ),
      ],
    );
  }

  Card _card(Widget child) => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final pending = _licences.any((l) => l.status == LicenceStatus.verificationPending);
    final overdue = _licences.any((l) => l.status == LicenceStatus.checkOverdue);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? null : Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.licencesTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: _busy
            ? const PreferredSize(preferredSize: Size.fromHeight(3), child: LinearProgressIndicator(minHeight: 3))
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pending || overdue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MaterialBanner(
                      backgroundColor: Colors.orange.withValues(alpha: 0.12),
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      content: Text(pending ? l10n.licencesPendingBanner : l10n.licencesOverdueBanner),
                      actions: [
                        TextButton(onPressed: _busy ? null : _checkNow, child: Text(l10n.licencesCheckNow)),
                      ],
                    ),
                  ),
                Text(l10n.licencesThisComputer,
                    style: const TextStyle(fontSize: AppFontSize.large, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.licencesActivationCodeLabel,
                        style: TextStyle(fontSize: AppFontSize.xsmall, color: scheme.onSurfaceVariant)),
                    // App font, not 'monospace' (OS-dependent, hard to read on Linux);
                    // Crockford base32 has no I/L/O/U, so nothing looks alike.
                    _copyRow(_code,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            fontFeatures: [FontFeature.tabularFigures()])),
                    const SizedBox(height: 4),
                    Text(l10n.licencesActivationCodeHelp,
                        style: TextStyle(fontSize: AppFontSize.xsmall, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy ? null : _enterKey,
                          icon: const Icon(Icons.key_rounded, size: 18),
                          label: Text(l10n.licencesEnterKey),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showTemplateStoreDialog(context),
                          icon: const Icon(Icons.storefront_outlined, size: 18),
                          label: Text(l10n.licencesGetMore),
                        ),
                      ],
                    ),
                  ],
                )),
                const SizedBox(height: 28),
                Text(l10n.licencesTitle,
                    style: const TextStyle(fontSize: AppFontSize.large, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_licences.isEmpty)
                  _card(Text(l10n.licencesEmpty, style: TextStyle(color: scheme.onSurfaceVariant)))
                else
                  for (final l in _licences)
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: _licenceCard(l, l10n, scheme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _licenceCard(HeldLicence l, AppLocalizations l10n, ColorScheme scheme) {
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final ids = l.licence.templateIds;
    final names = ids.contains('ALL')
        ? l10n.licencesTemplatesAll
        : ids.map((id) => _catalog?.nameOf(id) ?? id).join(', ');
    final (statusText, statusColor) = _statusLabel(l.status, l10n);
    final usable = l.status == LicenceStatus.active ||
        l.status == LicenceStatus.checkOverdue ||
        l.status == LicenceStatus.verificationPending;
    final meta = [
      if (l.lastCheck != null) l10n.licencesLastCheck(dateFormat.format(l.lastCheck!.toLocal())),
      if (l.licence.validUntil != null) l10n.licencesValidUntil(dateFormat.format(l.licence.validUntil!.toLocal())),
    ];

    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(names, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusText,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final m in meta)
          Text(m, style: TextStyle(fontSize: AppFontSize.xsmall, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            if (usable) ...[
              TextButton.icon(
                onPressed: _busy ? null : _checkNow,
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: Text(l10n.licencesCheckNow),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _renewOffline(l),
                icon: const Icon(Icons.wifi_off_rounded, size: 16),
                label: Text(l10n.licencesRenewOffline),
              ),
            ],
            TextButton.icon(
              onPressed: _busy ? null : () => _deactivate(l),
              icon: const Icon(Icons.link_off_rounded, size: 16),
              label: Text(usable ? l10n.licencesDeactivate : l10n.licencesRemove),
            ),
          ],
        ),
      ],
    ));
  }

  (String, Color) _statusLabel(LicenceStatus s, AppLocalizations l10n) => switch (s) {
        LicenceStatus.active => (l10n.licencesStatusActive, Colors.green),
        LicenceStatus.checkOverdue => (l10n.licencesStatusOverdue, Colors.orange),
        LicenceStatus.verificationPending => (l10n.licencesStatusPending, Colors.orange),
        LicenceStatus.revoked => (l10n.licencesStatusRevoked, Colors.red),
        LicenceStatus.refunded => (l10n.licencesStatusRefunded, Colors.red),
        LicenceStatus.expired => (l10n.licencesStatusExpired, Colors.blueGrey),
        LicenceStatus.moved => (l10n.licencesStatusMoved, Colors.blueGrey),
      };
}

/// Plain-words text for a licence server / service error code.
String licenceErrorText(AppLocalizations l10n, String code) => switch (code) {
      'invalid_key' => l10n.licenceErrInvalidKey,
      'active_elsewhere' => l10n.licenceErrActiveElsewhere,
      'bad_gstin' => l10n.licenceErrBadGstin,
      'bad_activation_code' => l10n.licenceErrBadActivationCode,
      'too_many_moves' => l10n.licenceErrTooManyMoves,
      'licence_revoked' => l10n.licenceErrRevoked,
      'invalid_licence' => l10n.licenceErrInvalidLicence,
      'licence_refunded' => l10n.licenceErrRefunded,
      'licence_expired' => l10n.licenceErrExpired,
      'moved' => l10n.licenceErrMoved,
      'rate_limited' => l10n.licenceErrRateLimited,
      'network' => l10n.licenceErrNetwork,
      'invalid_code' => l10n.licenceErrInvalidRenewal,
      'wrong_licence' => l10n.licenceErrWrongLicence,
      _ => l10n.licenceErrUnknown(code),
    };
