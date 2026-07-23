import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/constants.dart';

class InvoiceSettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCustomization;

  const InvoiceSettingsScreen({super.key, this.onNavigateToCustomization});

  @override
  ConsumerState<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends ConsumerState<InvoiceSettingsScreen> {
  final TextEditingController invoicePrefixController = TextEditingController();
  final TextEditingController invoiceStartingNumberController = TextEditingController();
  final TextEditingController additionalInfoController =
      TextEditingController();
  final TextEditingController thankYouController = TextEditingController();
  final TextEditingController quantityLabelController = TextEditingController();
  final TextEditingController defaultTaxRateController = TextEditingController();

  String _selectedLogoPosition = 'left';
  String _selectedCurrencyCode = 'INR';
  String _selectedLogoSize = 'medium';
  DateFormatOption _selectedDateFormat = DateFormatOption.ddmmyyyy;
  bool _showGstFields = true;
  bool _fractionalQuantity = false;
  bool _showQuantity = true;
  bool _showDiscount = true;
  bool _showTypeTag = true;
  bool _showPreviousBalance = false;
  bool _showAliasNameInPdf = false;
  bool _showTaxButtonInInvoicePage = true;
  String? _signatureBase64;
  String _signaturePosition = 'left';
  String _selectedSignatureSize = 'medium';
  int _invoiceCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final invoiceRepo = ref.read(invoiceRepositoryProvider);

    final results = await Future.wait([
      settingsRepo.getSetting(SettingKey.logoPosition),
      settingsRepo.getSetting(SettingKey.invoicePrefix),
      settingsRepo.getSetting(SettingKey.additionalInfo),
      settingsRepo.getSetting(SettingKey.thankYouNote),
      settingsRepo.getCurrency(),
      settingsRepo.getDateFormat(),
      settingsRepo.getShowGstFields(),
      settingsRepo.getFractionalQuantity(),
      settingsRepo.getQuantityLabel(),
      settingsRepo.getLogoSize(),
      settingsRepo.getShowQuantity(),
      settingsRepo.getShowDiscount(),
      settingsRepo.getShowTypeTag(),
      settingsRepo.getShowPreviousBalance(),
      settingsRepo.getSignatureImage(),
      settingsRepo.getSignaturePosition(),
      invoiceRepo.getTotalInvoiceCountIncludingTrashed(),
      settingsRepo.getSetting(SettingKey.invoiceStartingNumber),
      settingsRepo.getSetting(SettingKey.defaultTaxRate),
      settingsRepo.getSetting(SettingKey.showAliasNameInPdf),
      settingsRepo.getShowTaxButtonInInvoicePage(),
      settingsRepo.getSignatureSize(),
    ]);

    if (!mounted) return;

    setState(() {
      _selectedLogoPosition = (results[0] as String?) ?? 'left';
      invoicePrefixController.text = (results[1] as String?) ?? 'INV';
      additionalInfoController.text = (results[2] as String?) ?? '';
      thankYouController.text = (results[3] as String?) ?? '';

      _selectedCurrencyCode = (results[4] as CurrencyOption).code;
      _selectedDateFormat = results[5] as DateFormatOption;
      _showGstFields = results[6] as bool;
      _fractionalQuantity = results[7] as bool;
      quantityLabelController.text = results[8] as String;
      _selectedLogoSize = results[9] as String;
      _showQuantity = results[10] as bool;
      _showDiscount = results[11] as bool;
      _showTypeTag = results[12] as bool;
      _showPreviousBalance = results[13] as bool;
      _signatureBase64 = results[14] as String?;
      _signaturePosition = results[15] as String;
      _invoiceCount = results[16] as int;
      invoiceStartingNumberController.text =
          (results[17] as String?) ?? '1';
      defaultTaxRateController.text =
          (results[18] as String?) ?? '18';
      _showAliasNameInPdf = (results[19] as String?) == 'true';
      _showTaxButtonInInvoicePage = results[20] as bool;
      _selectedSignatureSize = results[21] as String;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    if(mounted) {
      setState(() => _isSaving = true);
    }
    try {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final taxRateVal = double.tryParse(defaultTaxRateController.text.trim()) ?? 18.0;
    await Future.wait([
      settingsRepo.setSetting(SettingKey.logoSize, _selectedLogoSize),
      settingsRepo.setSetting(SettingKey.logoPosition, _selectedLogoPosition),
      settingsRepo.setSetting(SettingKey.invoicePrefix, invoicePrefixController.text),
      if (_invoiceCount == 0)
        settingsRepo.setSetting(SettingKey.invoiceStartingNumber,
            (int.tryParse(invoiceStartingNumberController.text.trim()) ?? 1)
                .clamp(1, 99999999)
                .toString()),
      settingsRepo.setSetting(SettingKey.additionalInfo, additionalInfoController.text),
      settingsRepo.setSetting(SettingKey.thankYouNote, thankYouController.text),
      settingsRepo.setCurrency(_selectedCurrencyCode),
      settingsRepo.setDateFormat(_selectedDateFormat),
      settingsRepo.setSetting(SettingKey.showGstFields, _showGstFields.toString()),
      settingsRepo.setSetting(SettingKey.fractionalQuantity, _fractionalQuantity.toString()),
      settingsRepo.setSetting(SettingKey.quantityLabel, quantityLabelController.text.trim()),
      settingsRepo.setSetting(
          SettingKey.defaultTaxRate, taxRateVal.clamp(0, 100).toStringAsFixed(1)),
      settingsRepo.setShowQuantity(_showQuantity),
      settingsRepo.setShowDiscount(_showDiscount),
      settingsRepo.setShowTypeTag(_showTypeTag),
      settingsRepo.setShowPreviousBalance(_showPreviousBalance),
      settingsRepo.setSetting(SettingKey.signaturePosition, _signaturePosition),
      settingsRepo.setSetting(SettingKey.signatureSize, _selectedSignatureSize),
      settingsRepo.setSetting(
          SettingKey.showAliasNameInPdf, _showAliasNameInPdf.toString()),
      settingsRepo.setSetting(
          SettingKey.showTaxButtonInInvoicePage, _showTaxButtonInInvoicePage.toString()),
    ]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice settings saved successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickSignature() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;
    final bytes = await File(result.files.single.path!).readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Signature image must be less than 2 MB.')),
        );
      }
      return;
    }
    final base64Sig = base64Encode(bytes);
    await ref.read(settingsRepositoryProvider).setSignatureImage(base64Sig);
    if(mounted) {
      setState(() => _signatureBase64 = base64Sig);
    }
  }

  Future<void> _clearSignature() async {
    await ref.read(settingsRepositoryProvider).setSignatureImage('');
    if(!mounted) return;
    setState(() => _signatureBase64 = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Invoice Settings'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invoice Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              elevation: 4,
              color: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Invoice Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldWidth = constraints.maxWidth / 2 - 12;
                        return Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            // Invoice Prefix
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: invoicePrefixController,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  labelText: 'Invoice Prefix',
                                  prefixIcon:
                                      const Icon(Icons.confirmation_number),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),

                            // Invoice Starting Number
                            SizedBox(
                              width: fieldWidth,
                              child: _invoiceCount == 0
                                  ? TextField(
                                      controller: invoiceStartingNumberController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 8,
                                      decoration: InputDecoration(
                                        labelText: 'Invoice Starting Number',
                                        prefixIcon: const Icon(Icons.looks_one_outlined),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide:
                                              BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color: Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        counterText: '',
                                        helperText: 'First invoice will start from this number',
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(color: Colors.orange[200]!),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.lock_outline,
                                              size: 16, color: Colors.orange[700]),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Invoice starting number cannot be changed while invoices exist. '
                                              'Please permanently delete all invoices/quotations (including trash) and try again.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[800],
                                                  height: 1.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            // Company Logo Position
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedLogoPosition,
                                decoration: InputDecoration(
                                  labelText: 'Company Logo Position',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'left', child: Text('Left')),
                                  DropdownMenuItem(
                                      value: 'right', child: Text('Right')),
                                ],
                                onChanged: (value) {
                                  if(!mounted) return;
                                  setState(() {
                                    _selectedLogoPosition = value!;
                                  });
                                },
                              ),
                            ),

                            // Company Logo Size
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedLogoSize,
                                decoration: InputDecoration(
                                  labelText: 'Company Logo Size',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: [
                                  for (final size in LogoSize.values)
                                    DropdownMenuItem(
                                        value: size.key,
                                        child: Text(size.label)),
                                ],
                                onChanged: (value) {
                                  if(!mounted) return;
                                  setState(() => _selectedLogoSize = value!);
                                },
                              ),
                            ),

                            // Quantity Column Label
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: quantityLabelController,
                                maxLength: 30,
                                decoration: InputDecoration(
                                  labelText: 'Quantity Column Label',
                                  hintText: 'e.g. Words, Hours, Units',
                                  helperText:
                                      'Leave blank to use default "Qty"',
                                  prefixIcon: const Icon(Icons.tag),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),

                            // Currency
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCurrencyCode,
                                decoration: InputDecoration(
                                  labelText: 'Currency',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: SupportedCurrencies.all.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c.code,
                                    child: Text(
                                        '${c.symbol}  ${c.name} (${c.code})'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if(!mounted) return;
                                  setState(() {
                                    _selectedCurrencyCode = value!;
                                  });
                                },
                              ),
                            ),

                            // Date Format
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<DateFormatOption>(
                                value: _selectedDateFormat,
                                decoration: InputDecoration(
                                  labelText: 'Date Format',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: DateFormatOption.values.map((opt) {
                                  return DropdownMenuItem<DateFormatOption>(
                                    value: opt,
                                    child: Text(opt.label),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if(!mounted) return;
                                  setState(() => _selectedDateFormat = value!);
                                },
                              ),
                            ),

                            // Default Tax Rate
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: defaultTaxRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                maxLength: 5,
                                decoration: InputDecoration(
                                  labelText: 'Default Tax Rate (%)',
                                  hintText: 'e.g. 18',
                                  helperText: 'Applied to new invoices',
                                  prefixIcon: const Icon(Icons.percent),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Tax Enabled by Default Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Tax Enabled by Default'),
                                  subtitle: const Text(
                                    "Enable the Tax toggle by default when creating new invoices.",
                                  ),
                                  secondary: Icon(
                                    Icons.percent_rounded,
                                    color: _showTaxButtonInInvoicePage
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showTaxButtonInInvoicePage,
                                  onChanged: (val) {
                                    if(!mounted) return;
                                    setState(() => _showTaxButtonInInvoicePage = val);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // GST Fields Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Show GST Fields'),
                                  subtitle: const Text(
                                    'Display GSTIN fields (HSN Code) on invoices, PDFs, and CSV exports',
                                  ),
                                  secondary: Icon(
                                    Icons.receipt_long_rounded,
                                    color: _showGstFields
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showGstFields,
                                  onChanged: (val) {
                                    if(!mounted) return;
                                    setState(() => _showGstFields = val);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Fractional Quantity Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title:
                                      const Text('Allow Fractional Quantities'),
                                  subtitle: const Text(
                                    'Enable decimal quantities (e.g. 1.5 hrs, 0.5 kg)',
                                  ),
                                  secondary: Icon(
                                    Icons.pin_outlined,
                                    color: _fractionalQuantity
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _fractionalQuantity,
                                  onChanged: (val) {
                                      if(!mounted) return;
                                      setState(() => _fractionalQuantity = val);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Show Quantity Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Show Quantity Field'),
                                  subtitle: const Text(
                                    'Hide quantity for service-based billing; price column becomes "Rate"',
                                  ),
                                  secondary: Icon(
                                    Icons.onetwothree_rounded,
                                    color: _showQuantity
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showQuantity,
                                  onChanged: (val) {
                                    if(!mounted) return;
                                    setState(() {
                                      _showQuantity = val;
                                    });
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Show Discount Column Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Show Discount Column'),
                                  subtitle: const Text(
                                    'Hide discount column for clients who don\'t use item-level discounts',
                                  ),
                                  secondary: Icon(
                                    Icons.discount_outlined,
                                    color: _showDiscount
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showDiscount,
                                  onChanged: (val) {
                                    if(!mounted) return;
                                    setState(() => _showDiscount = val);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            // Show Product/Service Tag Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Show Product/Service Tag'),
                                  subtitle: const Text(
                                    'Show or hide the Product/Service label on each invoice item',
                                  ),
                                  secondary: Icon(
                                    Icons.label_outline,
                                    color: _showTypeTag
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showTypeTag,
                                  onChanged: (val) {
                                    if(!mounted) return;
                                    setState(() => _showTypeTag = val);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            // Previous Balance Due Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title:
                                      const Text('Show Previous Balance Due'),
                                  subtitle: const Text(
                                    'Show calculated prior outstanding balance on invoice PDFs',
                                  ),
                                  secondary: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: _showPreviousBalance
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showPreviousBalance,
                                  onChanged: (val) {
                                    if(!mounted) return;
                                    setState(() => _showPreviousBalance = val);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Alias Name Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Show Alias Name in PDF'),
                                  subtitle: const Text(
                                    "Print a product's local-language alias (if set) instead of its actual name on PDFs",
                                  ),
                                  secondary: Icon(
                                    Icons.translate_outlined,
                                    color: _showAliasNameInPdf
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showAliasNameInPdf,
                                  onChanged: (val) {
                                    if(!mounted) return;
                                    setState(() => _showAliasNameInPdf = val);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            // Signature Image
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Signature Image',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Printed on invoices as Authorised Signature',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const Text(
                                      'PNG, JPG or JPEG — max 2 MB',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_signatureBase64 != null &&
                                        _signatureBase64!.isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.memory(
                                          base64Decode(_signatureBase64!),
                                          height: 60,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _pickSignature,
                                          icon: const Icon(
                                              Icons.upload_outlined,
                                              size: 16),
                                          label: Text(_signatureBase64 !=
                                                      null &&
                                                  _signatureBase64!.isNotEmpty
                                              ? 'Change Signature'
                                              : 'Upload Signature'),
                                        ),
                                        if (_signatureBase64 != null &&
                                            _signatureBase64!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: _clearSignature,
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: Colors.red),
                                            label: const Text('Remove',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedSignatureSize,
                                            decoration: InputDecoration(
                                              labelText: 'Signature Size',
                                              prefixIcon: const Icon(
                                                  Icons.photo_size_select_small_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    AppBorderRadius.xsmall),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    AppBorderRadius.xsmall),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            items: [
                                              for (final size in SignatureSize.values)
                                                DropdownMenuItem(
                                                    value: size.key,
                                                    child: Text(size.label)),
                                            ],
                                            onChanged: (val) {
                                              if(!mounted) return;
                                              setState(
                                                      () => _selectedSignatureSize = val!);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _signaturePosition,
                                            decoration: InputDecoration(
                                              labelText: 'Signature Position',
                                              prefixIcon: const Icon(
                                                  Icons.format_align_left_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    AppBorderRadius.xsmall),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    AppBorderRadius.xsmall),
                                                borderSide: BorderSide(
                                                    color: Colors.grey[300]!),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'left', child: Text('Left')),
                                              DropdownMenuItem(
                                                  value: 'right',
                                                  child: Text('Right')),
                                            ],
                                            onChanged: (val) {
                                              if(!mounted) return;
                                              setState(
                                                      () => _signaturePosition = val!);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            // Additional Info
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextField(
                                controller: additionalInfoController,
                                maxLength: DefaultValues.additionalNotesLength,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Additional Information',
                                  prefixIcon: const Icon(Icons.info_outline),
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),

                            // Thank You Note
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextField(
                                controller: thankYouController,
                                maxLength: 300,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Thank You Note',
                                  prefixIcon:
                                      const Icon(Icons.favorite_outline),
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── Custom fields promo ──────────────────────────────
                    if (widget.onNavigateToCustomization != null)
                      Builder(builder: (context) {
                        final primaryColor = Theme.of(context).primaryColor;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.06),
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.small),
                            border: Border.all(
                                color: primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.small),
                                ),
                                child: Icon(Icons.tune_rounded,
                                    size: 18, color: primaryColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need more fields on your invoices?',
                                      style: TextStyle(
                                        fontSize: AppFontSize.small,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Add PO number, project code, department, or any custom field.',
                                      style: TextStyle(
                                        fontSize: AppFontSize.xsmall,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: widget.onNavigateToCustomization,
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    size: 14),
                                label: const Text(
                                  'See Options',
                                  style: TextStyle(
                                    fontSize: AppFontSize.xsmall,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(
                                      color:
                                          primaryColor.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.small),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xsmall),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Invoice Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
