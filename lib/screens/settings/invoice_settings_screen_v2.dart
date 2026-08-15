import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/supported_currencies.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/common/constants.dart';

class InvoiceSettingsScreenV2 extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCustomization;

  const InvoiceSettingsScreenV2({super.key, this.onNavigateToCustomization});

  @override
  ConsumerState<InvoiceSettingsScreenV2> createState() => _InvoiceSettingsScreenV2State();
}

class _InvoiceSettingsScreenV2State extends ConsumerState<InvoiceSettingsScreenV2> {
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

  // ── V2 state: which settings section is currently shown ──────────────
  int _selectedSectionV2 = 0;

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
      invoiceStartingNumberController.text =
          (results[17] as String?) ?? '1';
      defaultTaxRateController.text =
          (results[18] as String?) ?? '18';
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
      settingsRepo.setAllowDuplicateInvoiceItems(_allowDuplicateInvoiceItems),
      settingsRepo.setSetting(SettingKey.showCgstSgst, _showCgstSgst.toString()),
      settingsRepo.setSetting(SettingKey.defaultTaxMode, _defaultTaxMode),
      settingsRepo.setSetting(SettingKey.showRoundOff, _showRoundOff.toString()),
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
    await ref.read(settingsRepositoryProvider).setWatermarkImage(base64Watermark);
    if(mounted) {
      setState(() => _watermarkBase64 = base64Watermark);
    }
  }

  Future<void> _clearWatermark() async {
    await ref.read(settingsRepositoryProvider).setWatermarkImage('');
    if(!mounted) return;
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
  Widget build(BuildContext context) => _buildV2(context);

  // ============================================================
  // V2 — settings grouped into sections behind a nav rail, instead of
  // one long scrolling form. All state, controllers, load/save logic,
  // and image pickers above are reused completely unchanged — this is
  // purely a presentation restructuring. Each field's exact
  // TextField/DropdownButtonFormField/SwitchListTile code is carried
  // over as-is from the original, just regrouped by topic.
  //
  // Responsive behaviour:
  //  - >= 900px: nav rail (240px) on the left, section content on the
  //    right (max width 900, centered), same as the original's overall
  //    shape but now with real navigation instead of a static promo box.
  //  - < 900px: the rail collapses into a horizontal scrollable chip
  //    row below the app bar; Save (and the custom-fields promo) move
  //    into a bottom bar so they're still always reachable without
  //    scrolling, since there's no persistent rail to pin them to.
  //  - Within every section, the field Wrap now actually collapses to
  //    a single column below 480px, instead of the original's fixed
  //    maxWidth/2 split (which stayed two-up even when that made each
  //    field too narrow to use).
  // ============================================================

  static const List<Map<String, dynamic>> _navSectionsV2 = [
    {'label': 'General', 'icon': Icons.settings_outlined},
    {'label': 'Branding', 'icon': Icons.image_outlined},
    {'label': 'Tax & GST', 'icon': Icons.percent_rounded},
    {'label': 'Invoice Items', 'icon': Icons.view_list_rounded},
    //{'label': 'Language & Notes', 'icon': Icons.translate_outlined},
  ];

  InputDecoration _fieldDecorationV2(
    BuildContext context, {
    required String label,
    String? hint,
    String? helperText,
    Widget? prefixIcon,
    int? counter,
  }) {
    final outlineVariant = Theme.of(context).colorScheme.outlineVariant;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        borderSide: BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      counterText: '',
    );
  }

  Widget _toggleCardV2({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        onChanged: (val) {
          if (!mounted) return;
          onChanged(val);
        },
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // A responsive 2-column-when-there's-room field wrap, collapsing to a
  // single column below 480px so fields never get squeezed unusably
  // narrow — this is the one real behavioural fix over the original,
  // which always split fields exactly in half regardless of how narrow
  // the container actually was.
  Widget _fieldWrapV2(List<Widget> halfWidthChildren, List<Widget> fullWidthChildren) {
    return LayoutBuilder(builder: (context, constraints) {
      final singleColumn = constraints.maxWidth < 480;
      final fieldWidth = singleColumn ? constraints.maxWidth : constraints.maxWidth / 2 - 12;
      return Wrap(
        spacing: 24,
        runSpacing: 20,
        children: [
          for (final child in halfWidthChildren) SizedBox(width: fieldWidth, child: child),
          for (final child in fullWidthChildren)
            SizedBox(width: constraints.maxWidth, child: child),
        ],
      );
    });
  }

  Widget _sectionGeneralV2() {
    return _fieldWrapV2(
      [
        TextField(
          controller: invoicePrefixController,
          maxLength: 10,
          decoration: _fieldDecorationV2(context,
              label: 'Invoice Prefix',
              prefixIcon: const Icon(Icons.confirmation_number)),
        ),
        _invoiceCount == 0
            ? TextField(
                controller: invoiceStartingNumberController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: _fieldDecorationV2(context,
                    label: 'Invoice Starting Number',
                    prefixIcon: const Icon(Icons.looks_one_outlined),
                    helperText: 'First invoice will start from this number'),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Invoice starting number cannot be changed while invoices exist. '
                        'Please permanently delete all invoices/quotations (including trash) and try again.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[800], height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
        _buildCurrencyField(),
        DropdownButtonFormField<DateFormatOption>(
          isExpanded: true,
          value: _selectedDateFormat,
          decoration: _fieldDecorationV2(context,
              label: 'Date Format', prefixIcon: const Icon(Icons.calendar_today)),
          items: DateFormatOption.values.map((opt) {
            return DropdownMenuItem<DateFormatOption>(
              value: opt,
              child: Text(opt.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return DateFormatOption.values.map((opt) {
              return Text(opt.key, maxLines: 1, overflow: TextOverflow.ellipsis);
            }).toList();
          },
          onChanged: (value) {
            if (!mounted) return;
            setState(() => _selectedDateFormat = value!);
          },
        ),
        TextField(
          controller: quantityLabelController,
          maxLength: 30,
          decoration: _fieldDecorationV2(context,
              label: 'Quantity Column Label',
              hint: 'e.g. Words, Hours, Units',
              helperText: 'Leave blank to use default "Qty"',
              prefixIcon: const Icon(Icons.tag)),
        ),
      ],
      [
        TextField(
          controller: additionalInfoController,
          maxLength: DefaultValues.additionalNotesLength,
          maxLines: 3,
          decoration: _fieldDecorationV2(context,
              label: 'Additional Information', prefixIcon: const Icon(Icons.info_outline))
              .copyWith(alignLabelWithHint: true),
        ),
        TextField(
          controller: thankYouController,
          maxLength: 300,
          maxLines: 3,
          decoration: _fieldDecorationV2(context,
              label: 'Thank You Note', prefixIcon: const Icon(Icons.favorite_outline))
              .copyWith(alignLabelWithHint: true),
        )
      ],
    );
  }

  Widget _sectionTaxV2() {
    return _fieldWrapV2(
      [
        TextField(
          controller: defaultTaxRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 5,
          decoration: _fieldDecorationV2(context,
              label: 'Default Tax Rate (%)',
              hint: 'e.g. 18',
              helperText: 'Applied to new invoices',
              prefixIcon: const Icon(Icons.percent)),
        ),
      ],
      [
        _toggleCardV2(
          title: 'Tax Enabled by Default',
          subtitle: 'Enable the Tax toggle by default when creating new invoices.',
          icon: Icons.percent_rounded,
          value: _showTaxButtonInInvoicePage,
          onChanged: (val) => setState(() => _showTaxButtonInInvoicePage = val),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Default Tax Rate Mode'),
              const Text('Applies to new invoices only', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                      value: false, icon: Icon(Icons.percent, size: 16), label: Text('Global')),
                  ButtonSegment<bool>(
                      value: true, icon: Icon(Icons.list_alt, size: 16), label: Text('Per Item')),
                ],
                selected: {_defaultTaxMode == 'perItem'},
                onSelectionChanged: (selection) {
                  if (!mounted) return;
                  setState(() => _defaultTaxMode = selection.first ? 'perItem' : 'global');
                },
              ),
            ],
          ),
        ),
        _toggleCardV2(
          title: 'Show GST Fields',
          subtitle: 'Display GSTIN fields (HSN/SAC) on invoices, PDFs, and CSV exports',
          icon: Icons.receipt_long_rounded,
          value: _showGstFields,
          onChanged: (val) => setState(() => _showGstFields = val),
        ),
        _toggleCardV2(
          title: 'Show CGST/SGST',
          subtitle: 'Split tax into CGST + SGST on invoices (India only).',
          icon: Icons.percent_rounded,
          value: _showCgstSgst,
          onChanged: (val) => setState(() => _showCgstSgst = val),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_showGstFields ? 'Default GST Invoice Title' : 'Default TAX Invoice Title',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                _showGstFields
                    ? 'Preselected on new invoices — e.g. "Bill of Supply" for GST Composition Scheme dealers'
                    : 'Preselected on new invoices',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                value: _defaultInvoiceTitle,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Invoice')),
                  DropdownMenuItem(value: 'Tax Invoice', child: Text('Tax Invoice')),
                  DropdownMenuItem(value: 'Bill of Supply', child: Text('Bill of Supply')),
                  DropdownMenuItem(
                      value: 'Invoice-cum-Bill of Supply', child: Text('Invoice-cum-Bill of Supply')),
                  DropdownMenuItem(value: 'Credit Note', child: Text('Credit Note')),
                  DropdownMenuItem(value: 'Debit Note', child: Text('Debit Note')),
                  DropdownMenuItem(value: 'Revised Invoice', child: Text('Revised Invoice')),
                ],
                onChanged: _setDefaultInvoiceTitle,
              ),
            ],
          ),
        ),
        _toggleCardV2(
          title: 'Show Round Off',
          subtitle:
          'Show a Round Off row + Net Amount (rounded to nearest) and amount in words on invoice PDFs.',
          icon: Icons.currency_rupee_rounded,
          value: _showRoundOff,
          onChanged: (val) => setState(() => _showRoundOff = val),
        ),
      ],
    );
  }
  Widget _sectionItemsV2() {
    return _fieldWrapV2(
      [],
      [
        _toggleCardV2(
          title: 'Show Alias Name in PDF',
          subtitle:
          "Print a product's local-language alias (if set) instead of its actual name on PDFs",
          icon: Icons.translate_outlined,
          value: _showAliasNameInPdf,
          onChanged: (val) => setState(() => _showAliasNameInPdf = val),
        ),
        _toggleCardV2(
          title: 'Allow Fractional Quantities',
          subtitle: 'Enable decimal quantities (e.g. 1.5 hrs, 0.5 kg)',
          icon: Icons.pin_outlined,
          value: _fractionalQuantity,
          onChanged: (val) => setState(() => _fractionalQuantity = val),
        ),
        _toggleCardV2(
          title: 'Show Quantity Field',
          subtitle: 'Hide quantity for service-based billing; price column becomes "Rate"',
          icon: Icons.onetwothree_rounded,
          value: _showQuantity,
          onChanged: (val) => setState(() => _showQuantity = val),
        ),
        _toggleCardV2(
          title: 'Show Discount Column',
          subtitle: 'Hide discount column for clients who don\'t use item-level discounts',
          icon: Icons.discount_outlined,
          value: _showDiscount,
          onChanged: (val) => setState(() => _showDiscount = val),
        ),
        _toggleCardV2(
          title: 'Show Product/Service Tag',
          subtitle: 'Show or hide the Product/Service label on each invoice item',
          icon: Icons.label_outline,
          value: _showTypeTag,
          onChanged: (val) => setState(() => _showTypeTag = val),
        ),
        _toggleCardV2(
          title: 'Allow Duplicate Invoice Items',
          subtitle: 'Allow adding the same product more than once to an invoice',
          icon: Icons.content_copy_outlined,
          value: _allowDuplicateInvoiceItems,
          onChanged: (val) => setState(() => _allowDuplicateInvoiceItems = val),
        ),
        _toggleCardV2(
          title: 'Show Previous Balance Due',
          subtitle: 'Show calculated prior outstanding balance on invoice PDFs',
          icon: Icons.account_balance_wallet_outlined,
          value: _showPreviousBalance,
          onChanged: (val) => setState(() => _showPreviousBalance = val),
        ),
      ],
    );
  }

  Widget _sectionBrandingV2() {
    return _fieldWrapV2(
      [
        DropdownButtonFormField<String>(
          value: _selectedLogoPosition,
          isExpanded: true,
          decoration: _fieldDecorationV2(context, label: 'Company Logo Position'),
          items: const [
            DropdownMenuItem(value: 'left', child: Text('Left')),
            DropdownMenuItem(value: 'right', child: Text('Right')),
          ],
          onChanged: (value) {
            if (!mounted) return;
            setState(() => _selectedLogoPosition = value!);
          },
        ),
        DropdownButtonFormField<String>(
          value: _selectedLogoSize,
          isExpanded: true,
          decoration: _fieldDecorationV2(context, label: 'Company Logo Size'),
          items: [
            for (final size in LogoSize.values)
              DropdownMenuItem(value: size.key, child: Text(size.label)),
          ],
          onChanged: (value) {
            if (!mounted) return;
            setState(() => _selectedLogoSize = value!);
          },
        ),
      ],
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Signature Image',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Printed on invoices as Authorised Signature',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('PNG, JPG or JPEG — max 2 MB',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              if (_signatureBase64 != null && _signatureBase64!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(base64Decode(_signatureBase64!), height: 60),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickSignature,
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: Text(_signatureBase64 != null && _signatureBase64!.isNotEmpty
                        ? 'Change Signature'
                        : 'Upload Signature'),
                  ),
                  if (_signatureBase64 != null && _signatureBase64!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearSignature,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
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
                      isExpanded: true,
                      decoration: _fieldDecorationV2(context,
                          label: 'Signature Size',
                          prefixIcon: const Icon(Icons.photo_size_select_small_outlined)),
                      items: [
                        for (final size in SignatureSize.values)
                          DropdownMenuItem(value: size.key, child: Text(size.label)),
                      ],
                      onChanged: (val) {
                        if (!mounted) return;
                        setState(() => _selectedSignatureSize = val!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _signaturePosition,
                      isExpanded: true,
                      decoration: _fieldDecorationV2(context,
                          label: 'Signature Position',
                          prefixIcon: const Icon(Icons.format_align_left_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'left', child: Text('Left')),
                        DropdownMenuItem(value: 'right', child: Text('Right')),
                      ],
                      onChanged: (val) {
                        if (!mounted) return;
                        setState(() => _signaturePosition = val!);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Watermark Image',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Shown behind the items table on invoice PDFs (not printed on thermal receipts)',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('PNG, JPG or JPEG — max 2 MB',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              if (_watermarkBase64 != null && _watermarkBase64!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(base64Decode(_watermarkBase64!), height: 60),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickWatermark,
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: Text(_watermarkBase64 != null && _watermarkBase64!.isNotEmpty
                        ? 'Change Watermark'
                        : 'Upload Watermark'),
                  ),
                  if (_watermarkBase64 != null && _watermarkBase64!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearWatermark,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
              if (_watermarkBase64 != null && _watermarkBase64!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Opacity: ${(_watermarkOpacity * 100).round()}%',
                    style: const TextStyle(fontSize: 13)),
                Slider(
                  value: _watermarkOpacity,
                  min: 0.02,
                  max: 0.6,
                  divisions: 29,
                  label: '${(_watermarkOpacity * 100).round()}%',
                  onChanged: (val) {
                    if (!mounted) return;
                    setState(() => _watermarkOpacity = val);
                  },
                  onChangeEnd: _setWatermarkOpacity,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLanguageV2() {
    return _fieldWrapV2(
      [],
      [],
    );
  }

  Widget _sectionContentV2(int index) {
    switch (index) {
      case 0:
        return _sectionGeneralV2();
      case 1:
        return _sectionBrandingV2();
      case 2:
        return _sectionTaxV2();
      case 3:
        return _sectionItemsV2();
      default:
        return _sectionLanguageV2();
    }
  }

  Widget _promoCardV2() {
    if (widget.onNavigateToCustomization == null) return const SizedBox.shrink();
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
                child: Icon(Icons.tune_rounded, size: 18, color: primaryColor),
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Text(
                  'Need more fields on your invoices?',
                  style: TextStyle(
                      fontSize: AppFontSize.small, fontWeight: FontWeight.w600, color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Add PO number, project code, department, or any custom field.',
            style: TextStyle(
                fontSize: AppFontSize.xsmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onNavigateToCustomization,
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text('See Options',
                  style: TextStyle(fontSize: AppFontSize.xsmall, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.small)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButtonV2() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveSettings,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_rounded),
        label: Text(_isSaving ? 'Saving...' : 'Save'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.small)),
        ),
      ),
    );
  }

  Widget _navRailV2() {
    return SizedBox(
      width: 240,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navSectionsV2.length,
                itemBuilder: (context, index) {
                  final selected = _selectedSectionV2 == index;
                  final entry = _navSectionsV2[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: selected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppBorderRadius.small),
                        onTap: () => setState(() => _selectedSectionV2 = index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(entry['icon'] as IconData,
                                  size: 19,
                                  color: selected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry['label'] as String,
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.onNavigateToCustomization != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _promoCardV2(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _saveButtonV2(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _narrowTabsV2() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (int i = 0; i < _navSectionsV2.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_navSectionsV2[i]['label'] as String),
                  avatar: Icon(_navSectionsV2[i]['icon'] as IconData, size: 16),
                  selected: _selectedSectionV2 == i,
                  onSelected: (_) => setState(() => _selectedSectionV2 = i),
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    fontWeight: _selectedSectionV2 == i ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedSectionV2 == i
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCardV2() {
    final entry = _navSectionsV2[_selectedSectionV2];
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Text(
                  entry['label'] as String,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _sectionContentV2(_selectedSectionV2),
          ],
        ),
      ),
    );
  }

  Widget _buildV2(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        appBar: AppBar(
          title: const Text('Invoice Settings'),
          backgroundColor:
              Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
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
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            children: [
              _navRailV2(),
              VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _sectionCardV2(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Narrow: rail collapses to a horizontal chip strip; Save (and the
        // custom-fields promo) move into a bottom bar so both stay
        // reachable without needing a persistent side rail.
        return Column(
          children: [
            _narrowTabsV2(),
            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: _sectionCardV2(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onNavigateToCustomization != null) ...[
                    _promoCardV2(),
                    const SizedBox(height: 12),
                  ],
                  _saveButtonV2(),
                ],
              ),
            ),
          ],
        );
      }),
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
              borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
