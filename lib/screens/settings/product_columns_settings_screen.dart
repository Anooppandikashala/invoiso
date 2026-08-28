import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/common/constants.dart';

class ProductColumnsSettingsScreen extends ConsumerStatefulWidget {
  const ProductColumnsSettingsScreen({super.key});

  @override
  ConsumerState<ProductColumnsSettingsScreen> createState() =>
      _ProductColumnsSettingsScreenState();
}

class _ProductColumnsSettingsScreenState
    extends ConsumerState<ProductColumnsSettingsScreen> {
  ProductColumnsConfig _config = const ProductColumnsConfig();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final config = await settingsRepo.getProductColumnsConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.setProductColumnsConfig(_config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productColumnsSavedMessage)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: onChanged == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(
          icon,
          color: value && onChanged != null
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _subTile({
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: SwitchListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontSize: AppFontSize.small)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : Colors.grey[50],
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.productColumnsScreenTitle),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.productColumnsScreenTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                children: [
                  const Spacer(),
                  // Save button pinned at bottom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveConfig,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving
                            ? l10n.createInvoiceSavingEllipsisLabel
                            : l10n.actionSave),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.small),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(
              width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    elevation: 4,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              l10n.productColumnsIntroText,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ),
                          _tile(
                            title: l10n.productColumnsNameLabel,
                            subtitle: l10n.productColumnsAlwaysRequiredSubtitle,
                            icon: Icons.label_outline,
                            value: true,
                            onChanged: null,
                          ),
                          _tile(
                            title: l10n.productColumnsPriceLabel,
                            subtitle: l10n.productColumnsAlwaysRequiredSubtitle,
                            icon: Icons.currency_rupee,
                            value: true,
                            onChanged: null,
                          ),
                          _tile(
                            title: l10n.productColumnsStockLabel,
                            subtitle: l10n.productColumnsStockSubtitle,
                            icon: Icons.inventory_2_outlined,
                            value: _config.stock,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(stock: v)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                                l10n.productColumnsProductFieldsSectionTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          _tile(
                            title: l10n.productColumnsAliasNameLabel,
                            subtitle: l10n.productColumnsAliasNameSubtitle,
                            icon: Icons.translate,
                            value: _config.aliasName,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(aliasName: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsTaxRateLabel,
                            subtitle: l10n.productColumnsTaxRateSubtitle,
                            icon: Icons.percent_rounded,
                            value: _config.taxRate,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(taxRate: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsHsnSacLabel,
                            subtitle: l10n.productColumnsHsnSacSubtitle,
                            icon: Icons.qr_code_2,
                            value: _config.hsncode,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(hsncode: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsDescriptionLabel,
                            subtitle: l10n.productColumnsDescriptionSubtitle,
                            icon: Icons.notes,
                            value: _config.description,
                            onChanged: (v) => setState(() =>
                                _config = _config.copyWith(description: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsPurchasePriceLabel,
                            subtitle: l10n.productColumnsPurchasePriceSubtitle,
                            icon: Icons.shopping_cart_outlined,
                            value: _config.purchasePrice,
                            onChanged: (v) => setState(() =>
                                _config = _config.copyWith(purchasePrice: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsDefaultDiscountLabel,
                            subtitle:
                                l10n.productColumnsDefaultDiscountSubtitle,
                            icon: Icons.discount_outlined,
                            value: _config.defaultDiscount,
                            onChanged: (v) => setState(() =>
                                _config = _config.copyWith(defaultDiscount: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsUnitLabel,
                            subtitle: l10n.productColumnsUnitSubtitle,
                            icon: Icons.straighten,
                            value: _config.unit,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(unit: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsProductServiceTypeLabel,
                            subtitle:
                                l10n.productColumnsProductServiceTypeSubtitle,
                            icon: Icons.category_outlined,
                            value: _config.type,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(type: v)),
                          ),
                          _tile(
                            title: l10n.productColumnsMetadataLabel,
                            subtitle: l10n.productColumnsMetadataSubtitle,
                            icon: Icons.more_horiz,
                            value: _config.productMetadata,
                            onChanged: (v) => setState(() =>
                                _config = _config.copyWith(productMetadata: v)),
                          ),
                          if (_config.productMetadata) ...[
                            _subTile(
                              title:
                                  l10n.productColumnsMetaStorageLocationLabel,
                              value: _config.metaStorageLocation,
                              onChanged: (v) => setState(() => _config =
                                  _config.copyWith(metaStorageLocation: v)),
                            ),
                            _subTile(
                              title:
                                  l10n.productColumnsMetaContainerNumberLabel,
                              value: _config.metaContainerNumber,
                              onChanged: (v) => setState(() => _config =
                                  _config.copyWith(metaContainerNumber: v)),
                            ),
                            _subTile(
                              title: l10n.productColumnsMetaBatchNumberLabel,
                              value: _config.metaBatchNumber,
                              onChanged: (v) => setState(() => _config =
                                  _config.copyWith(metaBatchNumber: v)),
                            ),
                            _subTile(
                              title: l10n.productColumnsMetaExpiryDateLabel,
                              value: _config.metaExpiryDate,
                              onChanged: (v) => setState(() => _config =
                                  _config.copyWith(metaExpiryDate: v)),
                            ),
                            _subTile(
                              title:
                                  l10n.productColumnsMetaManufactureDateLabel,
                              value: _config.metaManufactureDate,
                              onChanged: (v) => setState(() => _config =
                                  _config.copyWith(metaManufactureDate: v)),
                            ),
                            _subTile(
                              title: l10n.productColumnsMetaSupplierNameLabel,
                              value: _config.metaSupplierName,
                              onChanged: (v) => setState(() => _config =
                                  _config.copyWith(metaSupplierName: v)),
                            ),
                            _subTile(
                              title: l10n.productColumnsMetaSkuCodeLabel,
                              value: _config.metaSkuCode,
                              onChanged: (v) => setState(() =>
                                  _config = _config.copyWith(metaSkuCode: v)),
                            ),
                            _subTile(
                              title: l10n.productColumnsMetaNotesLabel,
                              value: _config.metaNotes,
                              onChanged: (v) => setState(() =>
                                  _config = _config.copyWith(metaNotes: v)),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(l10n.labelInvoice,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          _tile(
                            title: l10n.productColumnsExtraCostLabel,
                            subtitle: l10n.productColumnsExtraCostSubtitle,
                            icon: Icons.add_card_outlined,
                            value: _config.extraCost,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(extraCost: v)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
