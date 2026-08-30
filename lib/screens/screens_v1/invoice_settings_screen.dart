import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/common/constants.dart';

import 'package:invoiso/common/supported_currencies.dart';

// Legacy screen (out of i18n scope) — these mirror the English text that
// used to live in LogoSize/DateFormatOption/SignatureSize's `.label`
// getters in common.dart before those were localized.
String _legacyLogoSizeLabel(LogoSize s) {
  switch (s) {
    case LogoSize.xsmall:
      return 'X-Small';
    case LogoSize.small:
      return 'Small';
    case LogoSize.medium:
      return 'Medium';
    case LogoSize.large:
      return 'Large';
  }
}

String _legacyDateFormatOptionLabel(DateFormatOption opt) {
  switch (opt) {
    case DateFormatOption.ddmmyyyy:
      return 'DD/MM/YYYY  (e.g. 15/04/2026)';
    case DateFormatOption.mmddyyyy:
      return 'MM/DD/YYYY  (e.g. 04/15/2026)';
    case DateFormatOption.ddMmmyyyy:
      return 'DD MMM YYYY  (e.g. 15 Apr 2026)';
    case DateFormatOption.yyyymmdd:
      return 'YYYY-MM-DD  (e.g. 2026-04-15)';
  }
}

String _legacySignatureSizeLabel(SignatureSize s) {
  switch (s) {
    case SignatureSize.small:
      return 'Small';
    case SignatureSize.medium:
      return 'Medium';
    case SignatureSize.large:
      return 'Large';
  }
}

class InvoiceSettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCustomization;

  const InvoiceSettingsScreen({super.key, this.onNavigateToCustomization});

  @override
  ConsumerState<InvoiceSettingsScreen> createState() =>
      _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends ConsumerState<InvoiceSettingsScreen> {
  final TextEditingController invoicePrefixController = TextEditingController();
  final TextEditingController invoiceStartingNumberController =
      TextEditingController();
  final TextEditingController additionalInfoController =
      TextEditingController();
  final TextEditingController thankYouController = TextEditingController();
  final TextEditingController quantityLabelController = TextEditingController();
  final TextEditingController defaultTaxRateController =
      TextEditingController();

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
  bool _showCgstSgst = false;
  bool _showRoundOff = false;
  String _defaultTaxMode = 'global';
  String? _signatureBase64;
  String _signaturePosition = 'left';
  String _selectedSignatureSize = 'medium';
  String? _watermarkBase64;
  double _watermarkOpacity = 0.12;
  String? _defaultInvoiceTitle;
  bool _allowDuplicateInvoiceItems = false;
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
      settingsRepo.getWatermarkImage(),
      settingsRepo.getWatermarkOpacity(),
      settingsRepo.getDefaultInvoiceTitle(),
      settingsRepo.getAllowDuplicateInvoiceItems(),
      settingsRepo.getSetting(SettingKey.showCgstSgst),
      settingsRepo.getSetting(SettingKey.defaultTaxMode),
      settingsRepo.getSetting(SettingKey.showRoundOff),
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
      invoiceStartingNumberController.text = (results[17] as String?) ?? '1';
      defaultTaxRateController.text = (results[18] as String?) ?? '18';
      _showAliasNameInPdf = (results[19] as String?) == 'true';
      _showTaxButtonInInvoicePage = results[20] as bool;
      _selectedSignatureSize = results[21] as String;
      _watermarkBase64 = results[22] as String?;
      _watermarkOpacity = results[23] as double;
      _defaultInvoiceTitle = results[24] as String?;
      _allowDuplicateInvoiceItems = results[25] as bool;
      _showCgstSgst = (results[26] as String?) == 'true';
      _defaultTaxMode = (results[27] as String?) ?? 'global';
      _showRoundOff = (results[28] as String?) == 'true';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    if (mounted) {
      setState(() => _isSaving = true);
    }
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final taxRateVal =
          double.tryParse(defaultTaxRateController.text.trim()) ?? 18.0;
      await Future.wait([
        settingsRepo.setSetting(SettingKey.logoSize, _selectedLogoSize),
        settingsRepo.setSetting(SettingKey.logoPosition, _selectedLogoPosition),
        settingsRepo.setSetting(
            SettingKey.invoicePrefix, invoicePrefixController.text),
        if (_invoiceCount == 0)
          settingsRepo.setSetting(
              SettingKey.invoiceStartingNumber,
              (int.tryParse(invoiceStartingNumberController.text.trim()) ?? 1)
                  .clamp(1, 99999999)
                  .toString()),
        settingsRepo.setSetting(
            SettingKey.additionalInfo, additionalInfoController.text),
        settingsRepo.setSetting(
            SettingKey.thankYouNote, thankYouController.text),
        settingsRepo.setCurrency(_selectedCurrencyCode),
        settingsRepo.setDateFormat(_selectedDateFormat),
        settingsRepo.setSetting(
            SettingKey.showGstFields, _showGstFields.toString()),
        settingsRepo.setSetting(
            SettingKey.fractionalQuantity, _fractionalQuantity.toString()),
        settingsRepo.setSetting(
            SettingKey.quantityLabel, quantityLabelController.text.trim()),
        settingsRepo.setSetting(SettingKey.defaultTaxRate,
            taxRateVal.clamp(0, 100).toStringAsFixed(1)),
        settingsRepo.setShowQuantity(_showQuantity),
        settingsRepo.setShowDiscount(_showDiscount),
        settingsRepo.setShowTypeTag(_showTypeTag),
        settingsRepo.setShowPreviousBalance(_showPreviousBalance),
        settingsRepo.setSetting(
            SettingKey.signaturePosition, _signaturePosition),
        settingsRepo.setSetting(
            SettingKey.signatureSize, _selectedSignatureSize),
        settingsRepo.setSetting(
            SettingKey.showAliasNameInPdf, _showAliasNameInPdf.toString()),
        settingsRepo.setSetting(SettingKey.showTaxButtonInInvoicePage,
            _showTaxButtonInInvoicePage.toString()),
        settingsRepo.setAllowDuplicateInvoiceItems(_allowDuplicateInvoiceItems),
        settingsRepo.setSetting(
            SettingKey.showCgstSgst, _showCgstSgst.toString()),
        settingsRepo.setSetting(SettingKey.defaultTaxMode, _defaultTaxMode),
        settingsRepo.setSetting(
            SettingKey.showRoundOff, _showRoundOff.toString()),
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
    if (mounted) {
      setState(() => _signatureBase64 = base64Sig);
    }
  }

  Future<void> _clearSignature() async {
    await ref.read(settingsRepositoryProvider).setSignatureImage('');
    if (!mounted) return;
    setState(() => _signatureBase64 = null);
  }

  Future<void> _pickWatermark() async {
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
              content: Text('Watermark image must be less than 2 MB.')),
        );
      }
      return;
    }
    final base64Watermark = base64Encode(bytes);
    await ref
        .read(settingsRepositoryProvider)
        .setWatermarkImage(base64Watermark);
    if (mounted) {
      setState(() => _watermarkBase64 = base64Watermark);
    }
  }

  Future<void> _clearWatermark() async {
    await ref.read(settingsRepositoryProvider).setWatermarkImage('');
    if (!mounted) return;
    setState(() => _watermarkBase64 = null);
  }

  Future<void> _setWatermarkOpacity(double opacity) async {
    await ref.read(settingsRepositoryProvider).setWatermarkOpacity(opacity);
  }

  Future<void> _setDefaultInvoiceTitle(String? title) async {
    await ref.read(settingsRepositoryProvider).setDefaultInvoiceTitle(title);
    setState(() => _defaultInvoiceTitle = title);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: const Text('Invoice Settings'),
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
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('Invoice Settings'),
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
                  Spacer(),
                  if (widget.onNavigateToCustomization != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Builder(builder: (context) {
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
                          child: Column(
                            //crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          AppBorderRadius.small),
                                    ),
                                    child: Icon(Icons.tune_rounded,
                                        size: 18, color: primaryColor),
                                  ),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  Flexible(
                                    child: Text(
                                      'Need more fields on your invoices?',
                                      style: TextStyle(
                                        fontSize: AppFontSize.small,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Add PO number, project code, department, or any custom field.',
                                style: TextStyle(
                                  fontSize: AppFontSize.xsmall,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                    ),
                  // Save button pinned at bottom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
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
                      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                                        prefixIcon: const Icon(
                                            Icons.confirmation_number),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        counterText: '',
                                      ),
                                    ),
                                  ),

                                  // Invoice Starting Number
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _invoiceCount == 0
                                        ? TextField(
                                            controller:
                                                invoiceStartingNumberController,
                                            keyboardType: TextInputType.number,
                                            maxLength: 8,
                                            decoration: InputDecoration(
                                              labelText:
                                                  'Invoice Starting Number',
                                              prefixIcon: const Icon(
                                                  Icons.looks_one_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppBorderRadius.xsmall),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppBorderRadius.xsmall),
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outlineVariant),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppBorderRadius.xsmall),
                                                borderSide: BorderSide(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  width: 2,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              counterText: '',
                                              helperText:
                                                  'First invoice will start from this number',
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppBorderRadius.xsmall),
                                              border: Border.all(
                                                  color: Colors.orange[200]!),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.lock_outline,
                                                    size: 16,
                                                    color: Colors.orange[700]),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Invoice starting number cannot be changed while invoices exist. '
                                                    'Please permanently delete all invoices/quotations (including trash) and try again.',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.orange[800],
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
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Company Logo Position',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'left', child: Text('Left')),
                                        DropdownMenuItem(
                                            value: 'right',
                                            child: Text('Right')),
                                      ],
                                      onChanged: (value) {
                                        if (!mounted) return;
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
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Company Logo Size',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      ),
                                      items: [
                                        for (final size in LogoSize.values)
                                          DropdownMenuItem(
                                              value: size.key,
                                              child: Text(
                                                  _legacyLogoSizeLabel(size))),
                                      ],
                                      onChanged: (value) {
                                        if (!mounted) return;
                                        setState(
                                            () => _selectedLogoSize = value!);
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
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        counterText: '',
                                      ),
                                    ),
                                  ),

                                  // Currency
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _buildCurrencyField(),
                                  ),

                                  // Date Format
                                  SizedBox(
                                    width: fieldWidth,
                                    child: DropdownButtonFormField<
                                        DateFormatOption>(
                                      isExpanded: true,
                                      value: _selectedDateFormat,
                                      decoration: InputDecoration(
                                        labelText: 'Date Format',
                                        prefixIcon:
                                            const Icon(Icons.calendar_today),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      ),
                                      items: DateFormatOption.values.map((opt) {
                                        return DropdownMenuItem<
                                            DateFormatOption>(
                                          value: opt,
                                          child: Text(
                                            _legacyDateFormatOptionLabel(opt),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      selectedItemBuilder: (context) {
                                        return DateFormatOption.values
                                            .map((opt) {
                                          return Text(
                                            opt.key,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }).toList();
                                      },
                                      onChanged: (value) {
                                        if (!mounted) return;
                                        setState(
                                            () => _selectedDateFormat = value!);
                                      },
                                    ),
                                  ),

                                  // Default Tax Rate
                                  SizedBox(
                                    width: fieldWidth,
                                    child: TextField(
                                      controller: defaultTaxRateController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      maxLength: 5,
                                      decoration: InputDecoration(
                                        labelText: 'Default Tax Rate (%)',
                                        hintText: 'e.g. 18',
                                        helperText: 'Applied to new invoices',
                                        prefixIcon: const Icon(Icons.percent),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                            'Tax Enabled by Default'),
                                        subtitle: const Text(
                                          "Enable the Tax toggle by default when creating new invoices.",
                                        ),
                                        secondary: Icon(
                                          Icons.percent_rounded,
                                          color: _showTaxButtonInInvoicePage
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showTaxButtonInInvoicePage,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() =>
                                              _showTaxButtonInInvoicePage =
                                                  val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Show CGST/SGST Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text('Show CGST/SGST/IGST'),
                                        subtitle: const Text(
                                          "Split tax into CGST + SGST, or IGST for interstate invoices (India only).",
                                        ),
                                        secondary: Icon(
                                          Icons.percent_rounded,
                                          color: _showCgstSgst
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showCgstSgst,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() => _showCgstSgst = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Show Round Off Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text('Show Round Off'),
                                        subtitle: const Text(
                                          "Show a Round Off row + Net Amount (rounded to nearest) and amount in words on invoice PDFs.",
                                        ),
                                        secondary: Icon(
                                          Icons.currency_rupee_rounded,
                                          color: _showRoundOff
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showRoundOff,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() => _showRoundOff = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Default Tax Rate Mode Selector
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Default Tax Rate Mode'),
                                          const Text(
                                            'Applies to new invoices only',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          SegmentedButton<bool>(
                                            segments: const [
                                              ButtonSegment<bool>(
                                                value: false,
                                                icon: Icon(Icons.percent,
                                                    size: 16),
                                                label: Text('Global'),
                                              ),
                                              ButtonSegment<bool>(
                                                value: true,
                                                icon: Icon(Icons.list_alt,
                                                    size: 16),
                                                label: Text('Per Item'),
                                              ),
                                            ],
                                            selected: {
                                              _defaultTaxMode == 'perItem'
                                            },
                                            onSelectionChanged: (selection) {
                                              if (!mounted) return;
                                              setState(() {
                                                _defaultTaxMode =
                                                    selection.first
                                                        ? 'perItem'
                                                        : 'global';
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // GST Fields Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text('Show GST Fields'),
                                        subtitle: const Text(
                                          'Display GSTIN fields (HSN/SAC) on invoices, PDFs, and CSV exports',
                                        ),
                                        secondary: Icon(
                                          Icons.receipt_long_rounded,
                                          color: _showGstFields
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showGstFields,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() => _showGstFields = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  // Default GST Invoice Title
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              _showGstFields
                                                  ? 'Default GST Invoice Title'
                                                  : 'Default TAX Invoice Title',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _showGstFields
                                                ? 'Preselected on new invoices — e.g. "Bill of Supply" for GST Composition Scheme dealers'
                                                : 'Preselected on new invoices',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String?>(
                                            isExpanded: true,
                                            value: _defaultInvoiceTitle,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppBorderRadius
                                                              .xsmall)),
                                              filled: true,
                                              fillColor: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: null,
                                                  child: Text('Invoice')),
                                              DropdownMenuItem(
                                                  value: 'Tax Invoice',
                                                  child: Text('Tax Invoice')),
                                              DropdownMenuItem(
                                                  value: 'Bill of Supply',
                                                  child:
                                                      Text('Bill of Supply')),
                                              DropdownMenuItem(
                                                  value:
                                                      'Invoice-cum-Bill of Supply',
                                                  child: Text(
                                                      'Invoice-cum-Bill of Supply')),
                                              DropdownMenuItem(
                                                  value: 'Cash Bill',
                                                  child: Text('Cash Bill')),
                                              DropdownMenuItem(
                                                  value: 'Credit Note',
                                                  child: Text('Credit Note')),
                                              DropdownMenuItem(
                                                  value: 'Debit Note',
                                                  child: Text('Debit Note')),
                                              DropdownMenuItem(
                                                  value: 'Revised Invoice',
                                                  child:
                                                      Text('Revised Invoice')),
                                            ],
                                            onChanged: _setDefaultInvoiceTitle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Fractional Quantity Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                            'Allow Fractional Quantities'),
                                        subtitle: const Text(
                                          'Enable decimal quantities (e.g. 1.5 hrs, 0.5 kg)',
                                        ),
                                        secondary: Icon(
                                          Icons.pin_outlined,
                                          color: _fractionalQuantity
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _fractionalQuantity,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(
                                              () => _fractionalQuantity = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Show Quantity Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title:
                                            const Text('Show Quantity Field'),
                                        subtitle: const Text(
                                          'Hide quantity for service-based billing; price column becomes "Rate"',
                                        ),
                                        secondary: Icon(
                                          Icons.onetwothree_rounded,
                                          color: _showQuantity
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showQuantity,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() {
                                            _showQuantity = val;
                                          });
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Show Discount Column Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title:
                                            const Text('Show Discount Column'),
                                        subtitle: const Text(
                                          'Hide discount column for clients who don\'t use item-level discounts',
                                        ),
                                        secondary: Icon(
                                          Icons.discount_outlined,
                                          color: _showDiscount
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showDiscount,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() => _showDiscount = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  // Show Product/Service Tag Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                            'Show Product/Service Tag'),
                                        subtitle: const Text(
                                          'Show or hide the Product/Service label on each invoice item',
                                        ),
                                        secondary: Icon(
                                          Icons.label_outline,
                                          color: _showTypeTag
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showTypeTag,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() => _showTypeTag = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  // Allow Duplicate Invoice Items Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                            'Allow Duplicate Invoice Items'),
                                        subtitle: const Text(
                                          'Allow adding the same product more than once to an invoice',
                                        ),
                                        secondary: Icon(
                                          Icons.content_copy_outlined,
                                          color: _allowDuplicateInvoiceItems
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _allowDuplicateInvoiceItems,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() =>
                                              _allowDuplicateInvoiceItems =
                                                  val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  // Previous Balance Due Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                            'Show Previous Balance Due'),
                                        subtitle: const Text(
                                          'Show calculated prior outstanding balance on invoice PDFs',
                                        ),
                                        secondary: Icon(
                                          Icons.account_balance_wallet_outlined,
                                          color: _showPreviousBalance
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showPreviousBalance,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(
                                              () => _showPreviousBalance = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Alias Name Toggle
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                            'Show Alias Name in PDF'),
                                        subtitle: const Text(
                                          "Print a product's local-language alias (if set) instead of its actual name on PDFs",
                                        ),
                                        secondary: Icon(
                                          Icons.translate_outlined,
                                          color: _showAliasNameInPdf
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        value: _showAliasNameInPdf,
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(
                                              () => _showAliasNameInPdf = val);
                                        },
                                        activeColor:
                                            Theme.of(context).primaryColor,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Signature Image',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Printed on invoices as Authorised Signature',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                          Text(
                                            'PNG, JPG or JPEG — max 2 MB',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 12),
                                          if (_signatureBase64 != null &&
                                              _signatureBase64!.isNotEmpty) ...[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                                label: Text(
                                                    _signatureBase64 != null &&
                                                            _signatureBase64!
                                                                .isNotEmpty
                                                        ? 'Change Signature'
                                                        : 'Upload Signature'),
                                              ),
                                              if (_signatureBase64 != null &&
                                                  _signatureBase64!
                                                      .isNotEmpty) ...[
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
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _selectedSignatureSize,
                                                  isExpanded: true,
                                                  decoration: InputDecoration(
                                                    labelText: 'Signature Size',
                                                    prefixIcon: const Icon(Icons
                                                        .photo_size_select_small_outlined),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppBorderRadius
                                                                  .xsmall),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppBorderRadius
                                                                  .xsmall),
                                                      borderSide: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .outlineVariant),
                                                    ),
                                                    filled: true,
                                                    fillColor: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                  ),
                                                  items: [
                                                    for (final size
                                                        in SignatureSize.values)
                                                      DropdownMenuItem(
                                                          value: size.key,
                                                          child: Text(
                                                              _legacySignatureSizeLabel(
                                                                  size))),
                                                  ],
                                                  onChanged: (val) {
                                                    if (!mounted) return;
                                                    setState(() =>
                                                        _selectedSignatureSize =
                                                            val!);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _signaturePosition,
                                                  isExpanded: true,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Signature Position',
                                                    prefixIcon: const Icon(Icons
                                                        .format_align_left_outlined),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppBorderRadius
                                                                  .xsmall),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppBorderRadius
                                                                  .xsmall),
                                                      borderSide: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .outlineVariant),
                                                    ),
                                                    filled: true,
                                                    fillColor: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                        value: 'left',
                                                        child: Text('Left')),
                                                    DropdownMenuItem(
                                                        value: 'right',
                                                        child: Text('Right')),
                                                  ],
                                                  onChanged: (val) {
                                                    if (!mounted) return;
                                                    setState(() =>
                                                        _signaturePosition =
                                                            val!);
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
                                  // Watermark Image
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Watermark Image',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Shown behind the items table on invoice PDFs (not printed on thermal receipts)',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                          Text(
                                            'PNG, JPG or JPEG — max 2 MB',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 12),
                                          if (_watermarkBase64 != null &&
                                              _watermarkBase64!.isNotEmpty) ...[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.memory(
                                                base64Decode(_watermarkBase64!),
                                                height: 60,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          Row(
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: _pickWatermark,
                                                icon: const Icon(
                                                    Icons.upload_outlined,
                                                    size: 16),
                                                label: Text(
                                                    _watermarkBase64 != null &&
                                                            _watermarkBase64!
                                                                .isNotEmpty
                                                        ? 'Change Watermark'
                                                        : 'Upload Watermark'),
                                              ),
                                              if (_watermarkBase64 != null &&
                                                  _watermarkBase64!
                                                      .isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                TextButton.icon(
                                                  onPressed: _clearWatermark,
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
                                          if (_watermarkBase64 != null &&
                                              _watermarkBase64!.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                                'Opacity: ${(_watermarkOpacity * 100).round()}%',
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                            Slider(
                                              value: _watermarkOpacity,
                                              min: 0.02,
                                              max: 0.6,
                                              divisions: 29,
                                              label:
                                                  '${(_watermarkOpacity * 100).round()}%',
                                              onChanged: (val) {
                                                if (!mounted) return;
                                                setState(() =>
                                                    _watermarkOpacity = val);
                                              },
                                              onChangeEnd: _setWatermarkOpacity,
                                            ),
                                          ],
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
                                      maxLength:
                                          DefaultValues.additionalNotesLength,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        labelText: 'Additional Information',
                                        prefixIcon:
                                            const Icon(Icons.info_outline),
                                        alignLabelWithHint: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
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
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
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
                              final primaryColor =
                                  Theme.of(context).primaryColor;
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.small),
                                  border: Border.all(
                                      color:
                                          primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.small),
                                      ),
                                      child: Icon(Icons.tune_rounded,
                                          size: 18, color: primaryColor),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed:
                                          widget.onNavigateToCustomization,
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded,
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
                                            color: primaryColor.withValues(
                                                alpha: 0.5)),
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
                          // SizedBox(
                          //   width: double.infinity,
                          //   height: 56,
                          //   child: ElevatedButton(
                          //     onPressed: _isSaving ? null : _saveSettings,
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Theme.of(context).primaryColor,
                          //       foregroundColor: Colors.white,
                          //       elevation: 2,
                          //       shadowColor: Theme.of(context)
                          //           .primaryColor
                          //           .withValues(alpha: 0.4),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius:
                          //             BorderRadius.circular(AppBorderRadius.xsmall),
                          //       ),
                          //     ),
                          //     child: _isSaving
                          //         ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          //         : const Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Icon(Icons.save, size: 20),
                          //         SizedBox(width: 8),
                          //         Text(
                          //           'Save Invoice Settings',
                          //           style: TextStyle(
                          //             fontSize: 16,
                          //             fontWeight: FontWeight.w600,
                          //             letterSpacing: 0.5,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
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

  Widget _buildCurrencyField() {
    final primaryColor = Theme.of(context).primaryColor;
    final current = SupportedCurrencies.fromCode(_selectedCurrencyCode);
    return Autocomplete<CurrencyOption>(
      key: ValueKey(_selectedCurrencyCode),
      initialValue: TextEditingValue(
          text: '${current.symbol}  ${current.name} (${current.code})'),
      displayStringForOption: (c) => '${c.symbol}  ${c.name} (${c.code})',
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return SupportedCurrencies.all;
        final query = value.text.toLowerCase();
        return SupportedCurrencies.all.where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.code.toLowerCase().contains(query) ||
            c.symbol.toLowerCase().contains(query));
      },
      onSelected: (CurrencyOption c) {
        if (!mounted) return;
        setState(() => _selectedCurrencyCode = c.code);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: AppFontSize.medium),
          decoration: InputDecoration(
            labelText: 'Currency',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final c = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text('${c.symbol}  ${c.name}',
                        style: const TextStyle(fontSize: AppFontSize.medium)),
                    trailing: Text(c.code,
                        style: TextStyle(
                            fontSize: AppFontSize.xsmall,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    onTap: () => onSelected(c),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
