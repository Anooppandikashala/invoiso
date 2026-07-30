import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/constants.dart';

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
    setState(() => _isSaving = true);
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.setProductColumnsConfig(_config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product columns saved.')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : Colors.grey[50],
        appBar: AppBar(
          title: const Text('Customize Product Details'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Customize Product Details'),
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
                        label: Text(_isSaving ? 'Saving...' : 'Save'),
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
                              'Choose which fields appear on the product add/edit forms, '
                              'the product list, and invoice line items. Name, Price, '
                              'and Stock are always required.',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ),
                          _tile(
                            title: 'Name',
                            subtitle: 'Always shown — required.',
                            icon: Icons.label_outline,
                            value: true,
                            onChanged: null,
                          ),
                          _tile(
                            title: 'Price',
                            subtitle: 'Always shown — required.',
                            icon: Icons.currency_rupee,
                            value: true,
                            onChanged: null,
                          ),
                          _tile(
                            title: 'Stock',
                            subtitle: 'Always shown — required.',
                            icon: Icons.inventory_2_outlined,
                            value: true,
                            onChanged: null,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Product fields',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _tile(
                            title: 'Alias Name',
                            subtitle:
                                'Local-language display name for PDFs/printing.',
                            icon: Icons.translate,
                            value: _config.aliasName,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(aliasName: v)),
                          ),
                          _tile(
                            title: 'Tax Rate',
                            subtitle: 'Per-product tax percentage.',
                            icon: Icons.percent_rounded,
                            value: _config.taxRate,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(taxRate: v)),
                          ),
                          _tile(
                            title: 'HSN/SAC',
                            subtitle: 'HSN or SAC code field.',
                            icon: Icons.qr_code_2,
                            value: _config.hsncode,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(hsncode: v)),
                          ),
                          _tile(
                            title: 'Description',
                            subtitle: 'Free-text product description.',
                            icon: Icons.notes,
                            value: _config.description,
                            onChanged: (v) => setState(() =>
                                _config = _config.copyWith(description: v)),
                          ),
                          _tile(
                            title: 'Purchase Price',
                            subtitle: 'Cost price, for margin tracking.',
                            icon: Icons.shopping_cart_outlined,
                            value: _config.purchasePrice,
                            onChanged: (v) => setState(() =>
                                _config = _config.copyWith(purchasePrice: v)),
                          ),
                          _tile(
                            title: 'Default Discount',
                            subtitle:
                                'Pre-filled discount when adding this product to an invoice.',
                            icon: Icons.discount_outlined,
                            value: _config.defaultDiscount,
                            onChanged: (v) => setState(() =>
                                _config = _config.copyWith(defaultDiscount: v)),
                          ),
                          _tile(
                            title: 'Unit',
                            subtitle: 'Unit of measure (pcs, kg, hrs...).',
                            icon: Icons.straighten,
                            value: _config.unit,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(unit: v)),
                          ),
                          _tile(
                            title: 'Product/Service Type',
                            subtitle: 'Segmented Product vs Service selector.',
                            icon: Icons.category_outlined,
                            value: _config.type,
                            onChanged: (v) => setState(
                                () => _config = _config.copyWith(type: v)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Invoice',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _tile(
                            title: 'Extra Cost',
                            subtitle:
                                'Optional flat extra charge on an invoice line item.',
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
