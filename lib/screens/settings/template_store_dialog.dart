import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/services/licensing/licence_service.dart';
import 'package:invoiso/services/licensing/template_catalog.dart';
import 'package:invoiso/services/templates/template_pack_store.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Get more templates…": the marketplace catalogue with Buy (pre-filled
/// email request, no in-app payment) and View on website (PaidTemplatesPlan.md §17.6).
Future<void> showTemplateStoreDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _TemplateStoreDialog());

class _TemplateStoreDialog extends ConsumerStatefulWidget {
  const _TemplateStoreDialog();

  @override
  ConsumerState<_TemplateStoreDialog> createState() => _TemplateStoreDialogState();
}

class _TemplateStoreDialogState extends ConsumerState<_TemplateStoreDialog> {
  final _catalogService = TemplateCatalogService();
  final _licenceService = LicenceService();
  StoreCatalog? _catalog;
  bool _loading = true;
  Set<String> _licensedIds = {};
  bool _allLicensed = false;
  Set<String> _installedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Show the cached copy at once, then the fresh one.
    final cached = await _catalogService.cached();
    if (mounted && cached != null) setState(() => _catalog = cached);
    final held = (await _licenceService.licences()).where((l) =>
        l.status != LicenceStatus.revoked &&
        l.status != LicenceStatus.refunded &&
        l.status != LicenceStatus.expired &&
        l.status != LicenceStatus.moved);
    final installed = {for (final p in await TemplatePackStore().list()) p.templateId};
    final fresh = await _catalogService.refresh();
    if (!mounted) return;
    setState(() {
      _installedIds = installed;
      _catalog = fresh ?? _catalog;
      _licensedIds = {for (final l in held) ...l.licence.templateIds};
      _allLicensed = _licensedIds.contains('ALL');
      _loading = false;
    });
  }

  Future<void> _buy(StoreTemplate t) async {
    final l10n = AppLocalizations.of(context)!;
    final email = _catalog?.contactEmail ?? '';
    final company = await ref.read(companyInfoRepositoryProvider).getCompanyInfo();
    final code = await _licenceService.activationCode();
    // Preferred: the template's page with its "Request to buy" dialog open and
    // pre-filled. Details go after '#', so they never reach any server.
    if (t.page != null) {
      final details = Uri(queryParameters: {
        'code': code,
        if ((company?.name ?? '').isNotEmpty) 'business': company!.name,
        // Tax ID of any country (GSTIN, VAT, TRN…) and the country.
        if ((company?.gstin ?? '').isNotEmpty) 'taxid': company!.gstin,
        if ((company?.country ?? '').isNotEmpty) 'country': company!.country,
      }).query;
      _open('${t.page!.split('#').first}#buy?$details');
      return;
    }
    // No page: email us. Request goes to us (the seller), so it is in English.
    final body = [
      'Hello, I would like to buy this Invoiso template.',
      '',
      'Template: ${t.name} (${t.id})',
      if (t.priceLabel.isNotEmpty) 'Price: ${t.priceLabel}',
      'Activation code: $code',
      'Business name: ${company?.name ?? ''}',
      'GSTIN: ${company?.gstin ?? ''}',
      '',
      'Please send me the payment details.',
    ].join('\n');
    final uri = Uri.parse('mailto:$email'
        '?subject=${Uri.encodeComponent('Buy Invoiso template: ${t.name}')}'
        '&body=${Uri.encodeComponent(body)}');
    final opened = await launchUrl(uri).catchError((_) => false);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.storeNoEmailApp(email))));
    }
  }

  void _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final templates = _catalog?.templates ?? const <StoreTemplate>[];

    Widget body;
    if (templates.isEmpty && _loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (templates.isEmpty) {
      body = Center(child: Text(l10n.storeOffline, textAlign: TextAlign.center));
    } else {
      body = ListView.separated(
        itemCount: templates.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _tile(templates[i], l10n, scheme),
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.storeTitle)),
          if (_loading && templates.isNotEmpty)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
      content: SizedBox(
        width: 640,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.storeSubtitle,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Expanded(child: body),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _open(TemplateCatalogService.websiteUrl),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(l10n.storeOpenWebsite),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }

  Widget _tile(StoreTemplate t, AppLocalizations l10n, ColorScheme scheme) {
    final licensed = _allLicensed || _licensedIds.contains(t.id);
    final available = t.status == 'available';
    final price = t.free ? l10n.storeFree : t.priceLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 72,
              height: 90,
              child: t.thumbnail == null
                  ? ColoredBox(color: scheme.surfaceContainerHighest)
                  : Image.network(t.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(color: scheme.surfaceContainerHighest)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (licensed) _chip(l10n.storeLicensed, Colors.green),
                    if (_installedIds.contains(t.id)) _chip(l10n.storeInstalled, Colors.blue),
                    if (!available) _chip(l10n.storeComingSoon, Colors.blueGrey),
                  ],
                ),
                if (t.tagline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(t.tagline, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 4),
                Text([price, t.pageSizes.join(' / ')].where((s) => s.isNotEmpty).join('  ·  '),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!t.free && !licensed && available)
                FilledButton(onPressed: () => _buy(t), child: Text(l10n.storeBuy)),
              // Owners can download even if the listing is no longer available.
              if (!t.free && licensed)
                FilledButton.tonal(
                    onPressed: () => _open(TemplateCatalogService.accountUrl),
                    child: Text(l10n.storeDownloadFromAccount)),
              if (t.page != null)
                TextButton(onPressed: () => _open(t.page!), child: Text(l10n.storeViewOnWebsite)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}
