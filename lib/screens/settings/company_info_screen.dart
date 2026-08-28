import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/widgets/language_picker.dart';
import 'package:invoiso/common/invoiso_colors.dart';
import 'package:invoiso/models/company_info.dart';

import 'package:invoiso/common/app_countries.dart';

class CompanyInfoScreen extends ConsumerStatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  ConsumerState<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends ConsumerState<CompanyInfoScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();
  final gstinController = TextEditingController();
  final panController = TextEditingController();
  final fssaiController = TextEditingController();
  bool _isSaving = false;
  String _selectedCountry = 'India';
  int _companyInfoLoadCount =
      0; // incremented once when DB data arrives; forces Autocomplete reinit
  final List<({TextEditingController label, TextEditingController id})>
      _upiControllers = [];
  int? _defaultUpiIndex;

  final List<
      ({
        TextEditingController label,
        TextEditingController bankName,
        TextEditingController accountNumber,
        TextEditingController ifscCode,
      })> _bankControllers = [];
  int? _defaultBankIndex;

  CompanyInfo? _companyInfo;
  bool _showUpiQr = false;
  bool _showBankDetails = false;
  bool _showPhone = true;
  bool _showEmail = true;
  bool _showCompanyName = true;
  bool _showPan = true;
  bool _showFssai = true;
  bool _showWebsite = true;
  bool _showAddress = true;
  bool _showLogo = true;
  BusinessType _businessType = BusinessType.both;

  File? _selectedLogoFile;
  String? _base64Logo;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    final companyRepo = ref.read(companyInfoRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    final results = await Future.wait([
      companyRepo.getCompanyInfo(),
      settingsRepo.getCompanyLogo(),
      settingsRepo.getUpiIds(),
      settingsRepo.getBankAccounts(),
      settingsRepo.getSetting(SettingKey.showUpiQr),
      settingsRepo.getShowBankDetails(),
      settingsRepo.getBusinessType(),
      settingsRepo.getShowPhone(),
      settingsRepo.getShowEmail(),
      settingsRepo.getShowCompanyName(),
      settingsRepo.getShowPan(),
      settingsRepo.getShowFssai(),
      settingsRepo.getShowWebsite(),
      settingsRepo.getShowAddress(),
      settingsRepo.getShowLogo(),
    ]);

    if (!mounted) return;

    final info = results[0] as CompanyInfo?;
    final base64Logo = results[1] as String?;
    final upiEntries = results[2] as List<UpiEntry>;
    final bankEntries = results[3] as List<BankAccount>;
    final showQrStr = results[4] as String?;
    final showBankDetails = results[5] as bool;
    final businessType = results[6] as BusinessType;
    final showPhone = results[7] as bool;
    final showEmail = results[8] as bool;
    final showCompanyName = results[9] as bool;
    final showPan = results[10] as bool;
    final showFssai = results[11] as bool;
    final showWebsite = results[12] as bool;
    final showAddress = results[13] as bool;
    final showLogo = results[14] as bool;

    if (info == null) return;

    setState(() {
      _companyInfo = info;

      nameController.text = info.name;
      addressController.text = info.address;
      phoneController.text = info.phone;
      emailController.text = info.email;
      websiteController.text = info.website;
      gstinController.text = info.gstin;
      panController.text = info.panNumber;
      fssaiController.text = info.fssaiCode;

      _selectedCountry = info.country.isEmpty ? 'India' : info.country;
      _companyInfoLoadCount++;

      _showUpiQr = showQrStr == 'true';
      _showBankDetails = showBankDetails;
      _businessType = businessType;
      _showPhone = showPhone;
      _showEmail = showEmail;
      _showCompanyName = showCompanyName;
      _showPan = showPan;
      _showFssai = showFssai;
      _showWebsite = showWebsite;
      _showAddress = showAddress;
      _showLogo = showLogo;

      if (base64Logo != null && base64Logo.isNotEmpty) {
        _base64Logo = base64Logo;
      }

      // Dispose existing UPI controllers
      for (final row in _upiControllers) {
        row.label.dispose();
        row.id.dispose();
      }

      _upiControllers.clear();
      _defaultUpiIndex = null;

      for (int i = 0; i < upiEntries.length; i++) {
        final entry = upiEntries[i];

        _upiControllers.add((
          label: TextEditingController(text: entry.label),
          id: TextEditingController(text: entry.id),
        ));

        if (entry.isDefault) {
          _defaultUpiIndex = i;
        }
      }

      // Dispose existing Bank controllers
      for (final row in _bankControllers) {
        row.label.dispose();
        row.bankName.dispose();
        row.accountNumber.dispose();
        row.ifscCode.dispose();
      }

      _bankControllers.clear();
      _defaultBankIndex = null;

      for (int i = 0; i < bankEntries.length; i++) {
        final entry = bankEntries[i];

        _bankControllers.add((
          label: TextEditingController(text: entry.label),
          bankName: TextEditingController(text: entry.bankName),
          accountNumber: TextEditingController(text: entry.accountNumber),
          ifscCode: TextEditingController(text: entry.ifscCode),
        ));

        if (entry.isDefault) {
          _defaultBankIndex = i;
        }
      }
    });
  }

  Future<void> _saveCompanyInfo() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final newInfo = CompanyInfo(
          id: _companyInfo?.id,
          name: nameController.text,
          address: addressController.text,
          phone: phoneController.text,
          email: emailController.text,
          website: websiteController.text,
          gstin: gstinController.text,
          panNumber: panController.text,
          fssaiCode: fssaiController.text,
          country: _selectedCountry);

      final upiEntries = <UpiEntry>[];
      for (int i = 0; i < _upiControllers.length; i++) {
        final id = _upiControllers[i].id.text.trim();
        if (id.isEmpty) continue;
        upiEntries.add(UpiEntry(
          label: _upiControllers[i].label.text.trim(),
          id: id,
          isDefault: i == _defaultUpiIndex,
        ));
      }

      final bankAccounts = <BankAccount>[];
      for (int i = 0; i < _bankControllers.length; i++) {
        final accountNum = _bankControllers[i].accountNumber.text.trim();
        if (accountNum.isEmpty) continue;
        bankAccounts.add(BankAccount(
          label: _bankControllers[i].label.text.trim(),
          bankName: _bankControllers[i].bankName.text.trim(),
          accountNumber: accountNum,
          ifscCode: _bankControllers[i].ifscCode.text.trim(),
          isDefault: i == _defaultBankIndex,
        ));
      }

      final companyInfoRepo = ref.read(companyInfoRepositoryProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await Future.wait([
        _companyInfo == null
            ? companyInfoRepo.insertCompanyInfo(newInfo)
            : companyInfoRepo.updateCompanyInfo(newInfo),
        if (_base64Logo != null) settingsRepo.setCompanyLogo(_base64Logo!),
        settingsRepo.setUpiIds(upiEntries),
        settingsRepo.setSetting(SettingKey.showUpiQr, _showUpiQr.toString()),
        settingsRepo.setBankAccounts(bankAccounts),
        settingsRepo.setShowBankDetails(_showBankDetails),
        settingsRepo.setBusinessType(_businessType),
        settingsRepo.setShowPhone(_showPhone),
        settingsRepo.setShowEmail(_showEmail),
        settingsRepo.setShowCompanyName(_showCompanyName),
        settingsRepo.setShowPan(_showPan),
        settingsRepo.setShowFssai(_showFssai),
        settingsRepo.setShowWebsite(_showWebsite),
        settingsRepo.setShowAddress(_showAddress),
        settingsRepo.setShowLogo(_showLogo),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.companyInfoSavedSuccessMessage)),
      );

      setState(() {
        _companyInfo = newInfo;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    gstinController.dispose();
    panController.dispose();
    fssaiController.dispose();
    for (final row in _upiControllers) {
      row.label.dispose();
      row.id.dispose();
    }
    for (final row in _bankControllers) {
      row.label.dispose();
      row.bankName.dispose();
      row.accountNumber.dispose();
      row.ifscCode.dispose();
    }
    super.dispose();
  }

  Future<void> _clearLogo() async {
    await ref.read(settingsRepositoryProvider).setCompanyLogo('');
    setState(() {
      _selectedLogoFile = null;
      _base64Logo = null;
    });
  }

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    // Validate file size (2MB limit)
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.companyInfoImageTooLargeMessage)),
        );
      }
      return;
    }

    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.companyInfoInvalidImageMessage)),
      );
      return;
    }

    // Validate dimensions
    if (decodedImage.width > 1080 || decodedImage.height > 1080) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.companyInfoImageDimensionsMessage),
        ),
      );
      return;
    }

    setState(() {
      _selectedLogoFile = file;
      _base64Logo = base64Encode(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    final logoContent = _selectedLogoFile != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            child: Image.file(_selectedLogoFile!, fit: BoxFit.contain),
          )
        : (_base64Logo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                child: Image.memory(base64Decode(_base64Logo!),
                    fit: BoxFit.contain),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined,
                        size: 36, color: primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.companyInfoUploadLogoLabel,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: AppFontSize.small,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(l10n.companyInfoClickToBrowseLabel,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: AppFontSize.xsmall)),
                ],
              ));

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: Text(l10n.companyInfoAppBarTitle),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: LanguagePicker(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    tooltip: l10n.themeLight),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    tooltip: l10n.themeDark),
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    tooltip: l10n.themeSystem),
              ],
              selected: {ref.watch(themeModeProvider)},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.white,
                selectedForegroundColor: Theme.of(context).primaryColor,
                selectedBackgroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              onSelectionChanged: (selection) {
                final mode = selection.first;
                ref.read(themeModeProvider.notifier).state = mode;
                ref
                    .read(settingsRepositoryProvider)
                    .setThemeMode(themeModeToKey(mode));
              },
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left panel ──────────────────────────────────────────────
          SizedBox(
            width: 240,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _sectionLabel(l10n.companyInfoLogoSectionLabel),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickLogo,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                ),
                                child: logoContent,
                              ),
                            ),
                          ),
                          if (_selectedLogoFile != null ||
                              _base64Logo != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _clearLogo,
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red),
                              label: Text(l10n.companyInfoRemoveLogoButton,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13)),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.companyInfoShowOnPdfLabel,
                                  style: TextStyle(
                                      fontSize: AppFontSize.xsmall,
                                      color: CompanyInfoScreenColors
                                          .sectionHeadingColor)),
                              _pdfVisibilityToggle(_showLogo,
                                  (val) => setState(() => _showLogo = val)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Live company name preview
                          ValueListenableBuilder(
                            valueListenable: nameController,
                            builder: (_, value, __) {
                              final name = value.text.trim();
                              if (name.isEmpty) return const SizedBox.shrink();
                              return Text(
                                name,
                                style: const TextStyle(
                                  fontSize: AppFontSize.large,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.companyInfoLogoRequirementsHint,
                            style: TextStyle(
                              fontSize: AppFontSize.xsmall,
                              color:
                                  CompanyInfoScreenColors.sectionHeadingColor,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Save button pinned at bottom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveCompanyInfo,
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
                          backgroundColor: primaryColor,
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

          // ── Right: scrollable form ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(l10n.companyInfoDetailsSectionLabel),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: nameController,
                                label: l10n.onboardingCompanyNameLabel,
                                icon: Icons.business_rounded,
                                maxLength: 50,
                                trailing: _pdfVisibilityToggle(
                                    _showCompanyName,
                                    (val) =>
                                        setState(() => _showCompanyName = val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: gstinController,
                                label: _selectedCountry == 'India' ||
                                        _selectedCountry.isEmpty
                                    ? l10n.fieldGstinLabel
                                    : l10n.fieldTaxVatNoLabel,
                                icon: Icons.receipt_long_rounded,
                                maxLength: 50,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: panController,
                                label: (_selectedCountry == 'India' ||
                                        _selectedCountry.isEmpty)
                                    ? l10n.fieldPanLabel
                                    : l10n.fieldTinLabel,
                                icon: Icons.credit_card_rounded,
                                maxLength: 20,
                                hint: (_selectedCountry == 'India' ||
                                        _selectedCountry.isEmpty)
                                    ? 'ABCDE1234F'
                                    : null,
                                trailing: _pdfVisibilityToggle(_showPan,
                                    (val) => setState(() => _showPan = val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: fssaiController,
                                label: l10n.companyInfoFssaiCodeLabel,
                                icon: Icons.verified_rounded,
                                maxLength: 14,
                                hint: '12345678901234',
                                trailing: _pdfVisibilityToggle(_showFssai,
                                    (val) => setState(() => _showFssai = val)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildCountryField()),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: phoneController,
                                label: l10n.fieldPhoneLabel,
                                icon: Icons.phone_rounded,
                                maxLength: 60,
                                keyboardType: TextInputType.phone,
                                hint: '+91 9876543210',
                                helper: l10n.companyInfoPhoneHelperText,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9+\s\-()\,]')),
                                ],
                                trailing: _pdfVisibilityToggle(_showPhone,
                                    (val) => setState(() => _showPhone = val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                controller: emailController,
                                label: l10n.fieldEmailLabel,
                                icon: Icons.email_rounded,
                                maxLength: 100,
                                keyboardType: TextInputType.emailAddress,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9@._\-]')),
                                ],
                                trailing: _pdfVisibilityToggle(_showEmail,
                                    (val) => setState(() => _showEmail = val)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: websiteController,
                          label: l10n.fieldWebsiteLabel,
                          icon: Icons.language_rounded,
                          maxLength: 100,
                          keyboardType: TextInputType.url,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9:/.%-]')),
                          ],
                          trailing: _pdfVisibilityToggle(_showWebsite,
                              (val) => setState(() => _showWebsite = val)),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: addressController,
                          label: l10n.fieldAddressLabel,
                          icon: Icons.location_on_rounded,
                          maxLength: 100,
                          maxLines: 3,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_full, size: 18),
                                tooltip: l10n.tooltipEditInLargerView,
                                onPressed: () => _editLongTextDialog(
                                  title: l10n.fieldAddressLabel,
                                  controller: addressController,
                                  maxLength: 100,
                                ),
                              ),
                              _pdfVisibilityToggle(_showAddress,
                                  (val) => setState(() => _showAddress = val)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _sectionLabel(l10n.companyInfoBusinessTypeSectionLabel),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xsmall),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.category_outlined,
                                      color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 12),
                                  Text(l10n.companyInfoBusinessTypeTitle,
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.companyInfoBusinessTypeSubtitle,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<BusinessType>(
                                segments: [
                                  ButtonSegment(
                                    value: BusinessType.product,
                                    label: Text(l10n.labelProduct),
                                    icon: const Icon(Icons.inventory_2_outlined,
                                        size: 16),
                                  ),
                                  ButtonSegment(
                                    value: BusinessType.service,
                                    label: Text(l10n.labelService),
                                    icon: const Icon(
                                        Icons.design_services_outlined,
                                        size: 16),
                                  ),
                                  ButtonSegment(
                                    value: BusinessType.both,
                                    label: Text(l10n.labelBoth),
                                    icon: const Icon(Icons.all_inclusive,
                                        size: 16),
                                  ),
                                ],
                                selected: {_businessType},
                                onSelectionChanged: (val) =>
                                    setState(() => _businessType = val.first),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _sectionLabel(
                            l10n.companyInfoPaymentSettingsSectionLabel),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xsmall),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: SwitchListTile(
                            title: Text(l10n.companyInfoShowQrToggleTitle),
                            subtitle: Text(
                              l10n.companyInfoShowQrToggleSubtitle,
                              style:
                                  const TextStyle(fontSize: AppFontSize.small),
                            ),
                            value: _showUpiQr,
                            onChanged: (val) =>
                                setState(() => _showUpiQr = val),
                            activeColor: primaryColor,
                            secondary: Icon(
                              Icons.payment_rounded,
                              color: _showUpiQr
                                  ? primaryColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(l10n.companyInfoUpiAccountsSectionLabel),
                        const SizedBox(height: 10),
                        ..._upiControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          final isDefault = index == _defaultUpiIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                // Default star
                                Tooltip(
                                  message: isDefault
                                      ? l10n.dashboardLayoutDefaultTitle
                                      : l10n.companyInfoSetAsDefaultTooltip,
                                  child: IconButton(
                                    icon: Icon(
                                      isDefault
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: isDefault
                                          ? Colors.amber[700]
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                    onPressed: () => setState(
                                        () => _defaultUpiIndex = index),
                                  ),
                                ),
                                SizedBox(
                                  width: 160,
                                  child: _buildField(
                                    controller: row.label,
                                    label: l10n.fieldLabelLabel,
                                    icon: Icons.label_outline_rounded,
                                    hint: l10n.companyInfoHintExampleBankName,
                                    maxLength: 40,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildField(
                                    controller: row.id,
                                    label: l10n.companyInfoUpiIdLabel,
                                    icon: Icons.qr_code_rounded,
                                    hint: 'yourname@bankname',
                                    maxLength: 100,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: l10n.tooltipRemove,
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _upiControllers[index].label.dispose();
                                      _upiControllers[index].id.dispose();
                                      _upiControllers.removeAt(index);
                                      if (_defaultUpiIndex == index) {
                                        _defaultUpiIndex = null;
                                      } else if (_defaultUpiIndex != null &&
                                          _defaultUpiIndex! > index) {
                                        _defaultUpiIndex =
                                            _defaultUpiIndex! - 1;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _upiControllers.add((
                                  label: TextEditingController(),
                                  id: TextEditingController(),
                                ));
                              });
                            },
                            icon: Icon(Icons.add_circle_outline,
                                color: primaryColor, size: 18),
                            label: Text(l10n.companyInfoAddUpiAccountButton,
                                style: TextStyle(color: primaryColor)),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Bank Details ─────────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xsmall),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: SwitchListTile(
                            title: Text(
                                l10n.companyInfoShowBankDetailsToggleTitle),
                            subtitle: Text(
                              l10n.companyInfoShowBankDetailsToggleSubtitle,
                              style:
                                  const TextStyle(fontSize: AppFontSize.small),
                            ),
                            value: _showBankDetails,
                            onChanged: (val) =>
                                setState(() => _showBankDetails = val),
                            activeColor: primaryColor,
                            secondary: Icon(
                              Icons.account_balance_outlined,
                              color: _showBankDetails
                                  ? primaryColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel(l10n.companyInfoBankAccountsSectionLabel),
                        const SizedBox(height: 10),
                        ..._bankControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          final isDefault = index == _defaultBankIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Default star
                                  Tooltip(
                                    message: isDefault
                                        ? l10n.dashboardLayoutDefaultTitle
                                        : l10n.companyInfoSetAsDefaultTooltip,
                                    child: IconButton(
                                      icon: Icon(
                                        isDefault
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: isDefault
                                            ? Colors.amber[700]
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                      onPressed: () => setState(
                                          () => _defaultBankIndex = index),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 130,
                                    child: _buildField(
                                      controller: row.label,
                                      label: l10n.fieldLabelLabel,
                                      icon: Icons.label_outline_rounded,
                                      hint: l10n
                                          .companyInfoHintExampleAccountLabel,
                                      maxLength: 40,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 140,
                                    child: _buildField(
                                      controller: row.bankName,
                                      label: l10n.fieldBankNameLabel,
                                      icon: Icons.account_balance_outlined,
                                      hint: l10n.companyInfoHintExampleBankName,
                                      maxLength: 60,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 180,
                                    child: _buildField(
                                      controller: row.accountNumber,
                                      label: l10n.fieldAccountNumberLabel,
                                      icon: Icons.numbers_outlined,
                                      hint: '123456789012',
                                      maxLength: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 130,
                                    child: _buildField(
                                      controller: row.ifscCode,
                                      label: l10n.fieldIfscCodeLabel,
                                      icon: Icons.code_outlined,
                                      hint: 'HDFC0001234',
                                      maxLength: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: l10n.tooltipRemove,
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _bankControllers[index].label.dispose();
                                        _bankControllers[index]
                                            .bankName
                                            .dispose();
                                        _bankControllers[index]
                                            .accountNumber
                                            .dispose();
                                        _bankControllers[index]
                                            .ifscCode
                                            .dispose();
                                        _bankControllers.removeAt(index);
                                        if (_defaultBankIndex == index) {
                                          _defaultBankIndex = null;
                                        } else if (_defaultBankIndex != null &&
                                            _defaultBankIndex! > index) {
                                          _defaultBankIndex =
                                              _defaultBankIndex! - 1;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _bankControllers.add((
                                  label: TextEditingController(),
                                  bankName: TextEditingController(),
                                  accountNumber: TextEditingController(),
                                  ifscCode: TextEditingController(),
                                ));
                              });
                            },
                            icon: Icon(Icons.add_circle_outline,
                                color: primaryColor, size: 18),
                            label: Text(l10n.companyInfoAddBankAccountButton,
                                style: TextStyle(color: primaryColor)),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
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

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppFontSize.xsmall,
        fontWeight: FontWeight.w600,
        color: CompanyInfoScreenColors.sectionHeadingColor,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCountryField() {
    final primaryColor = Theme.of(context).primaryColor;
    return Autocomplete<String>(
      key: ValueKey(_companyInfoLoadCount),
      initialValue: TextEditingValue(text: _selectedCountry),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return AppCountries.all;
        return AppCountries.all.where(
          (c) => c.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: (String country) {
        setState(() => _selectedCountry = country);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: AppFontSize.medium),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.onboardingCountryLabel,
            prefixIcon: const Icon(Icons.public_rounded, size: 20),
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
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final country = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(country,
                        style: const TextStyle(fontSize: AppFontSize.medium)),
                    onTap: () => onSelected(country),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLength = 100,
    int maxLines = 1,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? trailing,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(fontSize: AppFontSize.medium),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: trailing,
        alignLabelWithHint: maxLines > 1,
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
        counterText: '',
      ),
    );
  }

  static const double _longTextDialogMinWidth = 320;
  static const double _longTextDialogMaxWidth = 800;
  static const double _longTextDialogMinHeight = 200;
  static const double _longTextDialogMaxHeight = 600;

  // Same resizable large-editor dialog as the "expand" button on the Notes
  // field in create_invoice_screen_v2.dart / invoice_settings_screen_v2.dart.
  Future<void> _editLongTextDialog({
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

  /// Compact "show on invoice PDF" toggle used as a field's trailing icon.
  Widget _pdfVisibilityToggle(bool value, ValueChanged<bool> onChanged) {
    return Tooltip(
      message: AppLocalizations.of(context)!.tooltipShowOnInvoicePdf,
      child: Transform.scale(
        scale: 0.75,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
