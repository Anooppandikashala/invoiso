import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/supported_currencies.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/common/constants.dart';

class InvoiceSettingsScreenV2 extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCustomization;

  const InvoiceSettingsScreenV2({super.key, this.onNavigateToCustomization});

  @override
  ConsumerState<InvoiceSettingsScreenV2> createState() =>
      _InvoiceSettingsScreenV2State();
}

class _InvoiceSettingsScreenV2State
    extends ConsumerState<InvoiceSettingsScreenV2> {
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
  bool _showTimeInPdf = true;
  String _pdfTimeFormat = '24';
  bool _showGstFields = true;
  bool _showSlNoInPdf = true;
  bool _fractionalQuantity = false;
  bool _showQuantity = true;
  bool _showDiscount = true;
  bool _showTypeTag = true;
  bool _showPreviousBalance = false;
  bool _showAliasNameInPdf = false;
  bool _showDescriptionInPdf = false;
  bool _descriptionNewLineInPdf = false;
  bool _showCustomerBusinessName = true;
  bool _showCustomerAddress = true;
  bool _showCustomerPhone = true;
  bool _showCustomerEmail = true;
  bool _showCustomerGstin = true;
  bool _showTaxButtonInInvoicePage = true;
  bool _hideInvoiceNumberByDefault = false;
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
  bool _invoiceLeadingZeros = true;
  int _invoiceCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _customFieldsEnabled = false;
  List<CustomFieldDef> _customFieldDefs = [];
  final TextEditingController _newCustomFieldController =
      TextEditingController();

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
      settingsRepo.getSetting(SettingKey.invoiceLeadingZeros),
      settingsRepo.getHideInvoiceNumberByDefault(),
      settingsRepo.getSetting(SettingKey.showDescriptionInPdf),
      settingsRepo.getSetting(SettingKey.descriptionNewLineInPdf),
      settingsRepo.getShowCustomerBusinessName(),
      settingsRepo.getShowCustomerAddress(),
      settingsRepo.getShowCustomerPhone(),
      settingsRepo.getShowCustomerEmail(),
      settingsRepo.getShowCustomerGstin(),
      settingsRepo.getShowTimeInPdf(),
      settingsRepo.getPdfTimeFormat(),
      settingsRepo.getShowSlNoInPdf(),
    ]);

    if (!mounted) return;

    final customFieldsEnabledStr =
        await settingsRepo.getSetting(SettingKey.customFieldsEnabled);
    final customFieldDefs = await settingsRepo.getCustomFieldDefs();
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
      _invoiceLeadingZeros = (results[29] as String?) != 'false';
      _hideInvoiceNumberByDefault = results[30] as bool;
      _showDescriptionInPdf = (results[31] as String?) == 'true';
      _descriptionNewLineInPdf = (results[32] as String?) == 'true';
      _showCustomerBusinessName = results[33] as bool;
      _showCustomerAddress = results[34] as bool;
      _showCustomerPhone = results[35] as bool;
      _showCustomerEmail = results[36] as bool;
      _showCustomerGstin = results[37] as bool;
      _showTimeInPdf = results[38] as bool;
      _pdfTimeFormat = results[39] as String;
      _showSlNoInPdf = results[40] as bool;
      _customFieldsEnabled = customFieldsEnabledStr == 'true';
      _customFieldDefs = customFieldDefs;
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
            SettingKey.invoiceLeadingZeros, _invoiceLeadingZeros.toString()),
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
        settingsRepo.setSetting(SettingKey.hideInvoiceNumberByDefault,
            _hideInvoiceNumberByDefault.toString()),
        settingsRepo.setSetting(
            SettingKey.showDescriptionInPdf, _showDescriptionInPdf.toString()),
        settingsRepo.setSetting(SettingKey.descriptionNewLineInPdf,
            _descriptionNewLineInPdf.toString()),
        settingsRepo.setShowCustomerBusinessName(_showCustomerBusinessName),
        settingsRepo.setShowCustomerAddress(_showCustomerAddress),
        settingsRepo.setShowCustomerPhone(_showCustomerPhone),
        settingsRepo.setShowCustomerEmail(_showCustomerEmail),
        settingsRepo.setShowCustomerGstin(_showCustomerGstin),
        settingsRepo.setShowTimeInPdf(_showTimeInPdf),
        settingsRepo.setPdfTimeFormat(_pdfTimeFormat),
        settingsRepo.setShowSlNoInPdf(_showSlNoInPdf),
        settingsRepo.setSetting(
            SettingKey.customFieldsEnabled, _customFieldsEnabled.toString()),
        settingsRepo.setCustomFieldDefs(_customFieldDefs),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.invoiceSettingsSavedMessage),
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .invoiceSettingsSignatureTooLargeMessage)),
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .invoiceSettingsWatermarkTooLargeMessage)),
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

  static const List<IconData> _navSectionIconsV2 = [
    Icons.settings_outlined,
    Icons.image_outlined,
    Icons.percent_rounded,
    Icons.view_list_rounded,
    Icons.person_outline,
    Icons.table_chart_outlined,
    Icons.dashboard_customize_outlined,
  ];

  String _navSectionLabelV2(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    return switch (index) {
      0 => l10n.invoiceSettingsSectionGeneral,
      1 => l10n.invoiceSettingsSectionBranding,
      2 => l10n.invoiceSettingsSectionTax,
      3 => l10n.invoiceSettingsSectionItems,
      4 => l10n.invoiceSettingsSectionCustomer,
      5 => l10n.invoiceSettingsSectionColumns,
      _ => 'Custom Fields',
    };
  }

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

  static const double _longTextDialogMinWidth = 320;
  static const double _longTextDialogMaxWidth = 800;
  static const double _longTextDialogMinHeight = 200;
  static const double _longTextDialogMaxHeight = 600;

  // Same resizable large-editor dialog as the "expand" button on the Notes
  // field in create_invoice_screen_v2.dart, generalized for any long-text
  // settings field (title/controller/maxLength instead of hardcoded Notes).
  Future<void> _editLongTextDialogV2({
    required String title,
    required TextEditingController controller,
    required int maxLength,
  }) async {
    final dialogController = TextEditingController(text: controller.text);
    double dialogWidth = 480;
    double dialogHeight = 320;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TextField(
                    controller: dialogController,
                    maxLength: maxLength,
                    expands: true,
                    maxLines: null,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        setDialogState(() {
                          dialogWidth = (dialogWidth + details.delta.dx).clamp(
                              _longTextDialogMinWidth, _longTextDialogMaxWidth);
                          dialogHeight = (dialogHeight + details.delta.dy)
                              .clamp(_longTextDialogMinHeight,
                                  _longTextDialogMaxHeight);
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.south_east, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, dialogController.text),
              child: Text(AppLocalizations.of(context)!.actionSave),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => controller.text = result);
    }
  }

  Widget _toggleCardV2({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
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
        onChanged: onChanged == null
            ? null
            : (val) {
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
  Widget _fieldWrapV2(
      List<Widget> halfWidthChildren, List<Widget> fullWidthChildren) {
    return LayoutBuilder(builder: (context, constraints) {
      final singleColumn = constraints.maxWidth < 480;
      final fieldWidth =
          singleColumn ? constraints.maxWidth : constraints.maxWidth / 2 - 12;
      return Wrap(
        spacing: 24,
        runSpacing: 20,
        children: [
          for (final child in halfWidthChildren)
            SizedBox(width: fieldWidth, child: child),
          for (final child in fullWidthChildren)
            SizedBox(width: constraints.maxWidth, child: child),
        ],
      );
    });
  }

  Widget _sectionGeneralV2() {
    final l10n = AppLocalizations.of(context)!;
    return _fieldWrapV2(
      [
        TextField(
          controller: invoicePrefixController,
          maxLength: 25,
          decoration: _fieldDecorationV2(context,
              label: l10n.invoiceSettingsPrefixLabel,
              prefixIcon: const Icon(Icons.confirmation_number)),
        ),
        _invoiceCount == 0
            ? TextField(
                controller: invoiceStartingNumberController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: _fieldDecorationV2(context,
                    label: l10n.onboardingInvoiceStartingNumberLabel,
                    prefixIcon: const Icon(Icons.looks_one_outlined),
                    helperText: l10n.invoiceSettingsStartingNumberHelper),
              )
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
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
                        l10n.invoiceSettingsStartingNumberLockedMessage,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
        _toggleCardV2(
          title: l10n.onboardingLeadingZerosLabel,
          subtitle: l10n.onboardingLeadingZerosSubtitle,
          icon: Icons.pin_outlined,
          value: _invoiceLeadingZeros,
          onChanged: (val) => setState(() => _invoiceLeadingZeros = val),
        ),
        _buildCurrencyField(),
        DropdownButtonFormField<DateFormatOption>(
          isExpanded: true,
          value: _selectedDateFormat,
          decoration: _fieldDecorationV2(context,
              label: l10n.onboardingDateFormatLabel,
              prefixIcon: const Icon(Icons.calendar_today)),
          items: DateFormatOption.values.map((opt) {
            return DropdownMenuItem<DateFormatOption>(
              value: opt,
              child: Text(dateFormatOptionLabel(context, opt),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return DateFormatOption.values.map((opt) {
              return Text(opt.key,
                  maxLines: 1, overflow: TextOverflow.ellipsis);
            }).toList();
          },
          onChanged: (value) {
            if (!mounted) return;
            setState(() => _selectedDateFormat = value!);
          },
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _pdfTimeFormat,
          decoration: _fieldDecorationV2(context,
              label: l10n.invoiceSettingsTimeFormatLabel,
              prefixIcon: const Icon(Icons.schedule)),
          items: [
            DropdownMenuItem(
                value: '24', child: Text(l10n.invoiceSettingsTimeFormat24)),
            DropdownMenuItem(
                value: '12', child: Text(l10n.invoiceSettingsTimeFormat12)),
          ],
          onChanged: (value) {
            if (!mounted) return;
            setState(() => _pdfTimeFormat = value!);
          },
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowTimeInPdfLabel,
          subtitle: l10n.invoiceSettingsShowTimeInPdfSubtitle,
          icon: Icons.access_time,
          value: _showTimeInPdf,
          onChanged: (val) => setState(() => _showTimeInPdf = val),
        ),
        TextField(
          controller: quantityLabelController,
          maxLength: 30,
          decoration: _fieldDecorationV2(context,
              label: l10n.invoiceSettingsQuantityColumnLabel,
              hint: l10n.invoiceSettingsQuantityColumnHint,
              helperText: l10n.invoiceSettingsQuantityColumnHelper,
              prefixIcon: const Icon(Icons.tag)),
        ),
      ],
      [
        TextField(
          controller: additionalInfoController,
          maxLength: DefaultValues.additionalNotesLength,
          maxLines: 3,
          decoration: _fieldDecorationV2(context,
                  label: l10n.invoiceSettingsAdditionalInfoLabel,
                  prefixIcon: const Icon(Icons.info_outline))
              .copyWith(
                  alignLabelWithHint: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.open_in_full, size: 18),
                    tooltip: l10n.tooltipEditInLargerView,
                    onPressed: () => _editLongTextDialogV2(
                      title: l10n.invoiceSettingsAdditionalInfoLabel,
                      controller: additionalInfoController,
                      maxLength: DefaultValues.additionalNotesLength,
                    ),
                  )),
        ),
        TextField(
          controller: thankYouController,
          maxLength: 300,
          maxLines: 3,
          decoration: _fieldDecorationV2(context,
                  label: l10n.invoiceSettingsThankYouNoteLabel,
                  prefixIcon: const Icon(Icons.favorite_outline))
              .copyWith(
                  alignLabelWithHint: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.open_in_full, size: 18),
                    tooltip: l10n.tooltipEditInLargerView,
                    onPressed: () => _editLongTextDialogV2(
                      title: l10n.invoiceSettingsThankYouNoteLabel,
                      controller: thankYouController,
                      maxLength: 300,
                    ),
                  )),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsHideInvoiceNumberLabel,
          subtitle: l10n.invoiceSettingsHideInvoiceNumberSubtitle,
          icon: Icons.confirmation_number_outlined,
          value: _hideInvoiceNumberByDefault,
          onChanged: (val) => setState(() => _hideInvoiceNumberByDefault = val),
        ),
      ],
    );
  }

  Widget _sectionTaxV2() {
    final l10n = AppLocalizations.of(context)!;
    return _fieldWrapV2(
      [
        TextField(
          controller: defaultTaxRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 5,
          decoration: _fieldDecorationV2(context,
              label: l10n.onboardingDefaultTaxRateLabel,
              hint: l10n.invoiceSettingsTaxRateHint,
              helperText: l10n.invoiceSettingsTaxRateHelper,
              prefixIcon: const Icon(Icons.percent)),
        ),
      ],
      [
        _toggleCardV2(
          title: l10n.invoiceSettingsTaxEnabledLabel,
          subtitle: l10n.invoiceSettingsTaxEnabledSubtitle,
          icon: Icons.percent_rounded,
          value: _showTaxButtonInInvoicePage,
          onChanged: (val) => setState(() => _showTaxButtonInInvoicePage = val),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.invoiceSettingsTaxModeLabel),
              Text(l10n.invoiceSettingsAppliesNewInvoicesOnly,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                      value: false,
                      icon: const Icon(Icons.percent, size: 16),
                      label: Text(l10n.invoiceSettingsTaxModeGlobal)),
                  ButtonSegment<bool>(
                      value: true,
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: Text(l10n.invoiceSettingsTaxModePerItem)),
                ],
                selected: {_defaultTaxMode == 'perItem'},
                onSelectionChanged: (selection) {
                  if (!mounted) return;
                  setState(() =>
                      _defaultTaxMode = selection.first ? 'perItem' : 'global');
                },
              ),
            ],
          ),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowGstFieldsLabel,
          subtitle: l10n.invoiceSettingsShowGstFieldsSubtitle,
          icon: Icons.receipt_long_rounded,
          value: _showGstFields,
          onChanged: (val) => setState(() => _showGstFields = val),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  _showGstFields
                      ? l10n.invoiceSettingsDefaultGstTitleLabel
                      : l10n.invoiceSettingsDefaultTaxTitleLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                _showGstFields
                    ? l10n.invoiceSettingsGstTitleHelperGst
                    : l10n.invoiceSettingsGstTitleHelperGeneric,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                value: _defaultInvoiceTitle,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xsmall)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.labelInvoice)),
                  DropdownMenuItem(
                      value: 'Tax Invoice',
                      child: Text(l10n.gstTitleTaxInvoiceLabel)),
                  DropdownMenuItem(
                      value: 'Bill of Supply',
                      child: Text(l10n.gstTitleBillOfSupplyLabel)),
                  DropdownMenuItem(
                      value: 'Invoice-cum-Bill of Supply',
                      child: Text(l10n.gstTitleInvoiceCumBillLabel)),
                  DropdownMenuItem(
                      value: 'Cash Bill',
                      child: Text(l10n.gstTitleCashBillLabel)),
                  DropdownMenuItem(
                      value: 'Credit Note',
                      child: Text(l10n.gstTitleCreditNoteLabel)),
                  DropdownMenuItem(
                      value: 'Debit Note',
                      child: Text(l10n.gstTitleDebitNoteLabel)),
                  DropdownMenuItem(
                      value: 'Revised Invoice',
                      child: Text(l10n.gstTitleRevisedInvoiceLabel)),
                ],
                onChanged: _setDefaultInvoiceTitle,
              ),
            ],
          ),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowRoundOffLabel,
          subtitle: l10n.invoiceSettingsShowRoundOffSubtitle,
          icon: Icons.currency_rupee_rounded,
          value: _showRoundOff,
          onChanged: (val) => setState(() => _showRoundOff = val),
        ),
      ],
    );
  }

  // The two description toggles read as one setting: the second only makes
  // sense when the first is on, so they're boxed together and the "new line"
  // toggle is indented under its parent.
  Widget _descriptionGroupV2(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _toggleCardV2(
            title: l10n.invoiceSettingsShowDescriptionLabel,
            subtitle: l10n.invoiceSettingsShowDescriptionSubtitle,
            icon: Icons.notes_outlined,
            value: _showDescriptionInPdf,
            onChanged: (val) => setState(() => _showDescriptionInPdf = val),
          ),
          if (_showDescriptionInPdf) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _toggleCardV2(
                title: l10n.invoiceSettingsDescriptionNewLineLabel,
                subtitle: l10n.invoiceSettingsDescriptionNewLineSubtitle,
                icon: Icons.subdirectory_arrow_right_outlined,
                value: _descriptionNewLineInPdf,
                onChanged: (val) =>
                    setState(() => _descriptionNewLineInPdf = val),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionItemsV2() {
    final l10n = AppLocalizations.of(context)!;
    return _fieldWrapV2(
      [],
      [
        _toggleCardV2(
          title: l10n.invoiceSettingsShowAliasNameLabel,
          subtitle: l10n.invoiceSettingsShowAliasNameSubtitle,
          icon: Icons.translate_outlined,
          value: _showAliasNameInPdf,
          onChanged: (val) => setState(() => _showAliasNameInPdf = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsAllowFractionalQtyLabel,
          subtitle: l10n.invoiceSettingsAllowFractionalQtySubtitle,
          icon: Icons.pin_outlined,
          value: _fractionalQuantity,
          onChanged: (val) => setState(() => _fractionalQuantity = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowTypeTagLabel,
          subtitle: l10n.invoiceSettingsShowTypeTagSubtitle,
          icon: Icons.label_outline,
          value: _showTypeTag,
          onChanged: (val) => setState(() => _showTypeTag = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsAllowDuplicateItemsLabel,
          subtitle: l10n.invoiceSettingsAllowDuplicateItemsSubtitle,
          icon: Icons.content_copy_outlined,
          value: _allowDuplicateInvoiceItems,
          onChanged: (val) => setState(() => _allowDuplicateInvoiceItems = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowPrevBalanceLabel,
          subtitle: l10n.invoiceSettingsShowPrevBalanceSubtitle,
          icon: Icons.account_balance_wallet_outlined,
          value: _showPreviousBalance,
          onChanged: (val) => setState(() => _showPreviousBalance = val),
        ),
      ],
    );
  }

  Widget _sectionBrandingV2() {
    final l10n = AppLocalizations.of(context)!;
    return _fieldWrapV2(
      [
        DropdownButtonFormField<String>(
          value: _selectedLogoPosition,
          isExpanded: true,
          decoration: _fieldDecorationV2(context,
              label: l10n.invoiceSettingsLogoPositionLabel),
          items: [
            DropdownMenuItem(value: 'left', child: Text(l10n.commonLeftLabel)),
            DropdownMenuItem(
                value: 'right', child: Text(l10n.commonRightLabel)),
          ],
          onChanged: (value) {
            if (!mounted) return;
            setState(() => _selectedLogoPosition = value!);
          },
        ),
        DropdownButtonFormField<String>(
          value: _selectedLogoSize,
          isExpanded: true,
          decoration: _fieldDecorationV2(context,
              label: l10n.invoiceSettingsLogoSizeLabel),
          items: [
            for (final size in LogoSize.values)
              DropdownMenuItem(
                  value: size.key, child: Text(logoSizeLabel(context, size))),
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
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.invoiceSettingsSignatureImageLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(l10n.invoiceSettingsSignatureImageSubtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(l10n.invoiceSettingsImageFormatHint,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              if (_signatureBase64 != null && _signatureBase64!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child:
                      Image.memory(base64Decode(_signatureBase64!), height: 60),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickSignature,
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: Text(
                        _signatureBase64 != null && _signatureBase64!.isNotEmpty
                            ? l10n.invoiceSettingsChangeSignatureButton
                            : l10n.invoiceSettingsUploadSignatureButton),
                  ),
                  if (_signatureBase64 != null &&
                      _signatureBase64!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearSignature,
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.red),
                      label: Text(l10n.tooltipRemove,
                          style: const TextStyle(color: Colors.red)),
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
                          label: l10n.invoiceSettingsSignatureSizeLabel,
                          prefixIcon: const Icon(
                              Icons.photo_size_select_small_outlined)),
                      items: [
                        for (final size in SignatureSize.values)
                          DropdownMenuItem(
                              value: size.key,
                              child: Text(signatureSizeLabel(context, size))),
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
                          label: l10n.invoiceSettingsSignaturePositionLabel,
                          prefixIcon:
                              const Icon(Icons.format_align_left_outlined)),
                      items: [
                        DropdownMenuItem(
                            value: 'left', child: Text(l10n.commonLeftLabel)),
                        DropdownMenuItem(
                            value: 'right', child: Text(l10n.commonRightLabel)),
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
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.invoiceSettingsWatermarkImageLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(l10n.invoiceSettingsWatermarkImageSubtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(l10n.invoiceSettingsImageFormatHint,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              if (_watermarkBase64 != null && _watermarkBase64!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child:
                      Image.memory(base64Decode(_watermarkBase64!), height: 60),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickWatermark,
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: Text(
                        _watermarkBase64 != null && _watermarkBase64!.isNotEmpty
                            ? l10n.invoiceSettingsChangeWatermarkButton
                            : l10n.invoiceSettingsUploadWatermarkButton),
                  ),
                  if (_watermarkBase64 != null &&
                      _watermarkBase64!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearWatermark,
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.red),
                      label: Text(l10n.tooltipRemove,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
              if (_watermarkBase64 != null && _watermarkBase64!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                    l10n.invoiceSettingsOpacityLabel(
                        (_watermarkOpacity * 100).round()),
                    style: const TextStyle(fontSize: 13)),
                Slider(
                  value: _watermarkOpacity,
                  min: 0.02,
                  max: 0.6,
                  divisions: 29,
                  label: l10n.invoiceSettingsPercentValueLabel(
                      (_watermarkOpacity * 100).round()),
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

  // The invoice PDF items-table columns, all in one checklist. Item Name,
  // Price and Total are structural and always print, so they show as locked
  // rows. HSN/SAC mirrors the Show GST Fields toggle (which also controls the
  // GSTIN header fields, so it stays in the Tax section too).
  Widget _sectionColumnsV2() {
    final l10n = AppLocalizations.of(context)!;
    return _fieldWrapV2(
      [],
      [
        Text(l10n.invoiceSettingsColumnsSectionHint,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowSlNoLabel,
          subtitle: l10n.invoiceSettingsShowSlNoSubtitle,
          icon: Icons.format_list_numbered,
          value: _showSlNoInPdf,
          onChanged: (val) => setState(() => _showSlNoInPdf = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsColumnItemNameLabel,
          subtitle: l10n.invoiceSettingsColumnRequiredSubtitle,
          icon: Icons.check_circle_outline,
          value: true,
          onChanged: null,
        ),
        _descriptionGroupV2(l10n),
        _toggleCardV2(
          title: l10n.invoiceSettingsColumnHsnLabel,
          subtitle: l10n.invoiceSettingsColumnHsnSubtitle,
          icon: Icons.receipt_long_rounded,
          value: _showGstFields,
          onChanged: (val) => setState(() => _showGstFields = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowQuantityLabel,
          subtitle: l10n.invoiceSettingsShowQuantitySubtitle,
          icon: Icons.onetwothree_rounded,
          value: _showQuantity,
          onChanged: (val) => setState(() => _showQuantity = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsColumnPriceLabel,
          subtitle: l10n.invoiceSettingsColumnRequiredSubtitle,
          icon: Icons.check_circle_outline,
          value: true,
          onChanged: null,
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsColumnTaxLabel,
          subtitle: l10n.invoiceSettingsColumnTaxSubtitle,
          icon: Icons.percent_rounded,
          value: _showCgstSgst,
          onChanged: (val) => setState(() => _showCgstSgst = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowDiscountLabel,
          subtitle: l10n.invoiceSettingsShowDiscountSubtitle,
          icon: Icons.discount_outlined,
          value: _showDiscount,
          onChanged: (val) => setState(() => _showDiscount = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsColumnTotalLabel,
          subtitle: l10n.invoiceSettingsColumnRequiredSubtitle,
          icon: Icons.check_circle_outline,
          value: true,
          onChanged: null,
        ),
      ],
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
      case 4:
        return _sectionCustomerV2();
      case 5:
        return _sectionColumnsV2();
      default:
        return _sectionCustomFieldsV2();
    }
  }

  // User-defined per-invoice fields (e.g. Vehicle No, Delivery Note) — not
  // tied to the customer. Off by default; when on, seeded with a starting
  // set of fields matching a typical GST transport invoice, all freely
  // renameable/deletable. Rename/reorder mutate _customFieldDefs directly
  // without setState — nothing else on screen reflects a label mid-edit, so
  // there's no need to rebuild (and TextFormField keeps its own text/cursor
  // state via the ValueKey below). Add/remove/reorder do call setState since
  // the list itself changes shape.
  void _addCustomField() {
    final label = _newCustomFieldController.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _customFieldDefs.add(CustomFieldDef(
        id: 'cf-${DateTime.now().microsecondsSinceEpoch}',
        label: label,
        sortOrder: _customFieldDefs.length,
      ));
      _newCustomFieldController.clear();
    });
  }

  void _removeCustomField(int index) {
    setState(() => _customFieldDefs.removeAt(index));
  }

  void _renameCustomField(int index, String label) {
    final def = _customFieldDefs[index];
    _customFieldDefs[index] =
        CustomFieldDef(id: def.id, label: label, sortOrder: def.sortOrder);
  }

  void _moveCustomField(int oldIndex, int newIndex) {
    setState(() {
      final item = _customFieldDefs.removeAt(oldIndex);
      _customFieldDefs.insert(newIndex, item);
      for (var i = 0; i < _customFieldDefs.length; i++) {
        final def = _customFieldDefs[i];
        _customFieldDefs[i] =
            CustomFieldDef(id: def.id, label: def.label, sortOrder: i);
      }
    });
  }

  Widget _sectionCustomFieldsV2() {
    return _fieldWrapV2(
      [],
      [
        Text(
          'Define fields once here (e.g. Vehicle No, Delivery Note), then fill their values on each invoice. Not tied to the customer.',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        _toggleCardV2(
          title: 'Enable Custom Fields',
          subtitle:
              'Show a Custom Fields section on the create-invoice screen',
          icon: Icons.dashboard_customize_outlined,
          value: _customFieldsEnabled,
          onChanged: (val) => setState(() => _customFieldsEnabled = val),
        ),
        if (_customFieldsEnabled) ...[
          const SizedBox(height: 12),
          for (var index = 0; index < _customFieldDefs.length; index++)
            Padding(
              key: ValueKey(_customFieldDefs[index].id),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Move up',
                    onPressed: index == 0
                        ? null
                        : () => _moveCustomField(index, index - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Move down',
                    onPressed: index == _customFieldDefs.length - 1
                        ? null
                        : () => _moveCustomField(index, index + 1),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextFormField(
                      initialValue: _customFieldDefs[index].label,
                      decoration: _fieldDecorationV2(context, label: 'Field label'),
                      onChanged: (val) => _renameCustomField(index, val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete field',
                    onPressed: () => _removeCustomField(index),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _newCustomFieldController,
                  decoration: _fieldDecorationV2(context,
                      label: 'New field label', hint: 'e.g. Vehicle No'),
                  onSubmitted: (_) => _addCustomField(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addCustomField,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Customer details visibility on PDFs / thermal receipts. Each field is only
  // ever printed when it's toggled on AND the customer actually has a value —
  // toggling on never forces an empty line. Name is always shown.
  Widget _sectionCustomerV2() {
    final l10n = AppLocalizations.of(context)!;
    return _fieldWrapV2(
      [],
      [
        Text(l10n.invoiceSettingsCustomerSectionHint,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowCustomerBusinessNameLabel,
          subtitle: l10n.invoiceSettingsShowCustomerBusinessNameSubtitle,
          icon: Icons.business_outlined,
          value: _showCustomerBusinessName,
          onChanged: (val) => setState(() => _showCustomerBusinessName = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowCustomerAddressLabel,
          subtitle: l10n.invoiceSettingsShowCustomerAddressSubtitle,
          icon: Icons.location_on_outlined,
          value: _showCustomerAddress,
          onChanged: (val) => setState(() => _showCustomerAddress = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowCustomerPhoneLabel,
          subtitle: l10n.invoiceSettingsShowCustomerPhoneSubtitle,
          icon: Icons.phone_outlined,
          value: _showCustomerPhone,
          onChanged: (val) => setState(() => _showCustomerPhone = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowCustomerEmailLabel,
          subtitle: l10n.invoiceSettingsShowCustomerEmailSubtitle,
          icon: Icons.email_outlined,
          value: _showCustomerEmail,
          onChanged: (val) => setState(() => _showCustomerEmail = val),
        ),
        _toggleCardV2(
          title: l10n.invoiceSettingsShowCustomerGstinLabel,
          subtitle: l10n.invoiceSettingsShowCustomerGstinSubtitle,
          icon: Icons.badge_outlined,
          value: _showCustomerGstin,
          onChanged: (val) => setState(() => _showCustomerGstin = val),
        ),
      ],
    );
  }

  Widget _promoCardV2() {
    if (widget.onNavigateToCustomization == null)
      return const SizedBox.shrink();
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
                  AppLocalizations.of(context)!.invoiceSettingsPromoTitle,
                  style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.w600,
                      color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.invoiceSettingsPromoBody,
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
              label: Text(
                  AppLocalizations.of(context)!.invoiceSettingsPromoButton,
                  style: const TextStyle(
                      fontSize: AppFontSize.xsmall,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.small)),
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
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_rounded),
        label: Text(_isSaving
            ? AppLocalizations.of(context)!.createInvoiceSavingEllipsisLabel
            : AppLocalizations.of(context)!.actionSave),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.small)),
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
                itemCount: _navSectionIconsV2.length,
                itemBuilder: (context, index) {
                  final selected = _selectedSectionV2 == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: selected
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.small),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.small),
                        onTap: () => setState(() => _selectedSectionV2 = index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(_navSectionIconsV2[index],
                                  size: 19,
                                  color: selected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _navSectionLabelV2(context, index),
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
            for (int i = 0; i < _navSectionIconsV2.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_navSectionLabelV2(context, i)),
                  avatar: Icon(_navSectionIconsV2[i], size: 16),
                  selected: _selectedSectionV2 == i,
                  onSelected: (_) => setState(() => _selectedSectionV2 = i),
                  selectedColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    fontWeight: _selectedSectionV2 == i
                        ? FontWeight.w700
                        : FontWeight.w500,
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
                  _navSectionLabelV2(context, _selectedSectionV2),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
          title: Text(AppLocalizations.of(context)!.invoiceSettingsAppBarTitle),
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
        title: Text(AppLocalizations.of(context)!.invoiceSettingsAppBarTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            // Stretch so the scroll area fills the full height; otherwise the
            // Row centers a short section vertically and it jumps around when
            // switching sections.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _navRailV2(),
              VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  // Fresh scroll view per section → each opens scrolled to top
                  // instead of inheriting the previous section's offset.
                  key: ValueKey(_selectedSectionV2),
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Align(
                    alignment: Alignment.topCenter,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _narrowTabsV2(),
            Divider(
                height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(_selectedSectionV2),
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _sectionCardV2(),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border(
                  top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
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
            labelText: AppLocalizations.of(context)!.onboardingCurrencyLabel,
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
