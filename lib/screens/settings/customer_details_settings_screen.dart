import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/common/setting_key.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/widgets/custom_field_defs_editor.dart';

/// Settings → Customer Details: which extra fields customers have (shipping
/// address, date of birth, age, gender, custom fields) and whether each
/// prints on PDFs. Same layout as Product Details; moved here from Invoice
/// Settings (the "show customer … on invoice" switches stay there).
class CustomerDetailsSettingsScreen extends ConsumerStatefulWidget {
  const CustomerDetailsSettingsScreen({super.key});

  @override
  ConsumerState<CustomerDetailsSettingsScreen> createState() =>
      _CustomerDetailsSettingsScreenState();
}

class _CustomerDetailsSettingsScreenState
    extends ConsumerState<CustomerDetailsSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _shippingAddressEnabled = false;
  bool _customerDobEnabled = false;
  bool _customerAgeEnabled = false;
  bool _customerGenderEnabled = false;
  bool _customerCustomFieldsEnabled = false;
  bool _showShipToInPdf = true;
  bool _showCustomerDobInPdf = true;
  bool _showCustomerAgeInPdf = true;
  bool _showCustomerGenderInPdf = true;
  List<CustomFieldDef> _customerCustomFieldDefs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final f = await Future.wait([
      settingsRepo.getSetting(SettingKey.customerAgeEnabled),
      settingsRepo.getSetting(SettingKey.customerDobEnabled),
      settingsRepo.getSetting(SettingKey.customerGenderEnabled),
      settingsRepo.getSetting(SettingKey.shippingAddressEnabled),
      settingsRepo.getSetting(SettingKey.customerCustomFieldsEnabled),
      settingsRepo.getSetting(SettingKey.showCustomerAgeInPdf),
      settingsRepo.getSetting(SettingKey.showCustomerDobInPdf),
      settingsRepo.getSetting(SettingKey.showCustomerGenderInPdf),
      settingsRepo.getSetting(SettingKey.showShipToInPdf),
    ]);
    final defs = await settingsRepo.getCustomerCustomFieldDefs();
    if (!mounted) return;
    setState(() {
      _customerAgeEnabled = f[0] == 'true';
      _customerDobEnabled = f[1] == 'true';
      _customerGenderEnabled = f[2] == 'true';
      _shippingAddressEnabled = f[3] == 'true';
      _customerCustomFieldsEnabled = f[4] == 'true';
      _showCustomerAgeInPdf = f[5] != 'false';
      _showCustomerDobInPdf = f[6] != 'false';
      _showCustomerGenderInPdf = f[7] != 'false';
      _showShipToInPdf = f[8] != 'false';
      _customerCustomFieldDefs = defs;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await Future.wait([
        settingsRepo.setSetting(
            SettingKey.customerAgeEnabled, _customerAgeEnabled.toString()),
        settingsRepo.setSetting(
            SettingKey.customerDobEnabled, _customerDobEnabled.toString()),
        settingsRepo.setSetting(SettingKey.customerGenderEnabled,
            _customerGenderEnabled.toString()),
        settingsRepo.setSetting(SettingKey.shippingAddressEnabled,
            _shippingAddressEnabled.toString()),
        settingsRepo.setSetting(SettingKey.customerCustomFieldsEnabled,
            _customerCustomFieldsEnabled.toString()),
        settingsRepo.setCustomerCustomFieldDefs(_customerCustomFieldDefs),
        settingsRepo.setSetting(
            SettingKey.showCustomerAgeInPdf, _showCustomerAgeInPdf.toString()),
        settingsRepo.setSetting(
            SettingKey.showCustomerDobInPdf, _showCustomerDobInPdf.toString()),
        settingsRepo.setSetting(SettingKey.showCustomerGenderInPdf,
            _showCustomerGenderInPdf.toString()),
        settingsRepo.setSetting(
            SettingKey.showShipToInPdf, _showShipToInPdf.toString()),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customerDetailsSavedMessage)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Same tile / sub-tile look as Product Details.
  Widget _tile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(
          icon,
          color: value
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // "Print on PDF" under an enabled field — it can be recorded without
  // being printed.
  Widget _printOnPdf(bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 4),
      child: SwitchListTile(
        dense: true,
        title: Text(AppLocalizations.of(context)!.invoiceSettingsPrintOnPdfLabel,
            style: const TextStyle(fontSize: AppFontSize.small)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  InputDecoration _decoration(String label, String? hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appBar = AppBar(
      title: Text(l10n.customerDetailsScreenTitle),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    );
    final background =
        Theme.of(context).brightness == Brightness.dark ? null : Colors.grey[50];
    if (_isLoading) {
      return Scaffold(
        backgroundColor: background,
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: appBar,
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
                        onPressed: _isSaving ? null : _save,
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
                              l10n.invoiceSettingsCustomerFieldsHint,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ),
                          _tile(
                            title: l10n.invoiceSettingsShippingAddressLabel,
                            subtitle: l10n.invoiceSettingsShippingAddressSubtitle,
                            icon: Icons.local_shipping_outlined,
                            value: _shippingAddressEnabled,
                            onChanged: (v) =>
                                setState(() => _shippingAddressEnabled = v),
                          ),
                          if (_shippingAddressEnabled)
                            _printOnPdf(_showShipToInPdf,
                                (v) => setState(() => _showShipToInPdf = v)),
                          _tile(
                            title: l10n.invoiceSettingsCustomerDobLabel,
                            subtitle: l10n.invoiceSettingsCustomerDobSubtitle,
                            icon: Icons.cake_outlined,
                            value: _customerDobEnabled,
                            onChanged: (v) =>
                                setState(() => _customerDobEnabled = v),
                          ),
                          if (_customerDobEnabled)
                            _printOnPdf(_showCustomerDobInPdf,
                                (v) => setState(() => _showCustomerDobInPdf = v)),
                          _tile(
                            title: l10n.invoiceSettingsCustomerAgeLabel,
                            subtitle: l10n.invoiceSettingsCustomerAgeSubtitle,
                            icon: Icons.numbers_outlined,
                            value: _customerAgeEnabled,
                            onChanged: (v) =>
                                setState(() => _customerAgeEnabled = v),
                          ),
                          if (_customerAgeEnabled)
                            _printOnPdf(_showCustomerAgeInPdf,
                                (v) => setState(() => _showCustomerAgeInPdf = v)),
                          _tile(
                            title: l10n.invoiceSettingsCustomerGenderLabel,
                            subtitle: l10n.invoiceSettingsCustomerGenderSubtitle,
                            icon: Icons.wc_outlined,
                            value: _customerGenderEnabled,
                            onChanged: (v) =>
                                setState(() => _customerGenderEnabled = v),
                          ),
                          if (_customerGenderEnabled)
                            _printOnPdf(_showCustomerGenderInPdf,
                                (v) => setState(() => _showCustomerGenderInPdf = v)),
                          _tile(
                            title: l10n.invoiceSettingsCustomerCustomFieldsLabel,
                            subtitle:
                                l10n.invoiceSettingsCustomerCustomFieldsSubtitle,
                            icon: Icons.dashboard_customize_outlined,
                            value: _customerCustomFieldsEnabled,
                            onChanged: (v) =>
                                setState(() => _customerCustomFieldsEnabled = v),
                          ),
                          if (_customerCustomFieldsEnabled)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 4),
                              child: CustomFieldDefsEditor(
                                defs: _customerCustomFieldDefs,
                                onChanged: (defs) => setState(
                                    () => _customerCustomFieldDefs = defs),
                                idPrefix: 'ccf',
                                showPdfToggle: true,
                                maxFields: 5,
                                newFieldHint:
                                    l10n.invoiceSettingsCustomerCustomFieldHint,
                                decoration: _decoration,
                              ),
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
