import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/dashboard_screen.dart';
import 'package:invoiso/screens/onboarding/onboarding_step_appearance.dart';
import 'package:invoiso/screens/onboarding/onboarding_step_company.dart';
import 'package:invoiso/screens/onboarding/onboarding_step_done.dart';
import 'package:invoiso/screens/onboarding/onboarding_step_invoice.dart';

/// One-time, skippable first-login setup wizard. Each step persists its own
/// fields immediately on "Next" so progress survives even if the app is
/// closed before the wizard is finished; "Skip" advances without saving
/// that step's fields, leaving existing defaults in place.
class OnboardingScreen extends ConsumerStatefulWidget {
  final User user;

  const OnboardingScreen(this.user, {super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _stepCount = 4;
  // Keeps form fields readable instead of stretching edge-to-edge on
  // desktop/tablet windows; has no effect once the window is narrower
  // than this (mobile just fills the available width as before).
  static const _maxContentWidth = 640.0;

  final _pageController = PageController();
  int _currentStep = 0;
  bool _isBusy = false;

  // Step 1 — Company
  final _nameController = TextEditingController();
  String _selectedCountry = 'India';
  File? _logoFile;
  String? _base64Logo;
  CompanyInfo? _existingCompanyInfo;

  // Step 2 — Invoice
  String _selectedCurrencyCode = 'INR';
  DateFormatOption _selectedDateFormat = DateFormatOption.ddmmyyyy;
  final _startingNumberController = TextEditingController(text: '1');
  bool _leadingZeros = true;
  final _taxRateController = TextEditingController(text: '18');

  // Step 3 — Appearance
  PageSize _pageSize = PageSize.a4;
  InvoiceTemplate _template = InvoiceTemplate.classic;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final companyRepo = ref.read(companyInfoRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    final results = await Future.wait([
      companyRepo.getCompanyInfo(),
      settingsRepo.getCompanyLogo(),
      settingsRepo.getCurrency(),
      settingsRepo.getDateFormat(),
      settingsRepo.getSetting(SettingKey.invoiceStartingNumber),
      settingsRepo.getSetting(SettingKey.invoiceLeadingZeros),
      settingsRepo.getSetting(SettingKey.defaultTaxRate),
      settingsRepo.getPageSize(),
      settingsRepo.getInvoiceTemplate(),
    ]);

    if (!mounted) return;
    final info = results[0] as CompanyInfo?;
    setState(() {
      _existingCompanyInfo = info;
      if (info != null) {
        _nameController.text = info.name;
        _selectedCountry = info.country.isEmpty ? 'India' : info.country;
      }
      final base64Logo = results[1] as String?;
      if (base64Logo != null && base64Logo.isNotEmpty) _base64Logo = base64Logo;
      _selectedCurrencyCode = (results[2] as CurrencyOption).code;
      _selectedDateFormat = results[3] as DateFormatOption;
      _startingNumberController.text = (results[4] as String?) ?? '1';
      _leadingZeros = (results[5] as String?) != 'false';
      _taxRateController.text = (results[6] as String?) ?? '18';
      _pageSize = results[7] as PageSize;
      _template = results[8] as InvoiceTemplate;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _startingNumberController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) return;

    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return;
    if (decodedImage.width > 1080 || decodedImage.height > 1080) return;

    setState(() {
      _logoFile = file;
      _base64Logo = base64Encode(bytes);
    });
  }

  Future<void> _saveCompanyStep() async {
    final companyRepo = ref.read(companyInfoRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final info = _existingCompanyInfo;
    final newInfo = CompanyInfo(
      id: info?.id,
      name: _nameController.text,
      address: info?.address ?? '',
      phone: info?.phone ?? '',
      email: info?.email ?? '',
      website: info?.website ?? '',
      gstin: info?.gstin ?? '',
      panNumber: info?.panNumber ?? '',
      fssaiCode: info?.fssaiCode ?? '',
      country: _selectedCountry,
    );
    await Future.wait([
      info == null
          ? companyRepo.insertCompanyInfo(newInfo)
          : companyRepo.updateCompanyInfo(newInfo),
      if (_base64Logo != null) settingsRepo.setCompanyLogo(_base64Logo!),
    ]);
    _existingCompanyInfo = newInfo;
  }

  Future<void> _saveInvoiceStep() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final taxRate = double.tryParse(_taxRateController.text.trim()) ?? 18.0;
    await Future.wait([
      settingsRepo.setCurrency(_selectedCurrencyCode),
      settingsRepo.setDateFormat(_selectedDateFormat),
      settingsRepo.setSetting(
          SettingKey.invoiceStartingNumber,
          (int.tryParse(_startingNumberController.text.trim()) ?? 1)
              .clamp(1, 99999999)
              .toString()),
      settingsRepo.setSetting(
          SettingKey.invoiceLeadingZeros, _leadingZeros.toString()),
      settingsRepo.setSetting(
          SettingKey.defaultTaxRate, taxRate.clamp(0, 100).toStringAsFixed(1)),
    ]);
  }

  Future<void> _saveAppearanceStep() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await Future.wait([
      settingsRepo.setPageSize(_pageSize),
      settingsRepo.setInvoiceTemplate(_template),
    ]);
  }

  Future<void> _goToPage(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (mounted) setState(() => _currentStep = index);
  }

  Future<void> _handleNext() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      switch (_currentStep) {
        case 0:
          await _saveCompanyStep();
        case 1:
          await _saveInvoiceStep();
        case 2:
          await _saveAppearanceStep();
      }
      if (!mounted) return;
      await _goToPage(_currentStep + 1);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleSkip() => _goToPage(_currentStep + 1);

  Future<void> _handleBack() => _goToPage(_currentStep - 1);

  Future<void> _finish() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.onboardingCompleted, 'true');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen(widget.user)),
    );
  }

  ({IconData icon, String title, String subtitle}) _headerFor(
      AppLocalizations l10n, int step) {
    return switch (step) {
      0 => (
          icon: Icons.business_rounded,
          title: l10n.onboardingStepCompanyTitle,
          subtitle: l10n.onboardingStepCompanySubtitle
        ),
      1 => (
          icon: Icons.receipt_long_rounded,
          title: l10n.onboardingStepInvoiceTitle,
          subtitle: l10n.onboardingStepInvoiceSubtitle
        ),
      _ => (
          icon: Icons.palette_rounded,
          title: l10n.onboardingStepAppearanceTitle,
          subtitle: l10n.onboardingStepAppearanceSubtitle
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // A dimmed backdrop distinct from the card's own surface color, so the
      // wizard reads as a floating panel instead of blending into the page —
      // matters most on wide desktop/tablet windows where the card no longer
      // fills the screen.
      backgroundColor: isDark
          ? Colors.black
          : Theme.of(context).colorScheme.surfaceContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _stepCount; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: i == _currentStep ? 28 : 6,
                              decoration: BoxDecoration(
                                color: i <= _currentStep
                                    ? primaryColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_currentStep < 3) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        color: primaryColor.withValues(alpha: 0.08),
                        child: Builder(builder: (context) {
                          final header = _headerFor(l10n, _currentStep);
                          return Row(
                            children: [
                              Icon(header.icon, size: 32, color: primaryColor),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(header.title,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    Text(header.subtitle,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          OnboardingStepCompany(
                            nameController: _nameController,
                            selectedCountry: _selectedCountry,
                            onCountryChanged: (c) =>
                                setState(() => _selectedCountry = c),
                            logoFile: _logoFile,
                            base64Logo: _base64Logo,
                            onPickLogo: _pickLogo,
                          ),
                          OnboardingStepInvoice(
                            selectedCurrencyCode: _selectedCurrencyCode,
                            onCurrencyChanged: (c) =>
                                setState(() => _selectedCurrencyCode = c),
                            selectedDateFormat: _selectedDateFormat,
                            onDateFormatChanged: (f) =>
                                setState(() => _selectedDateFormat = f),
                            startingNumberController: _startingNumberController,
                            leadingZeros: _leadingZeros,
                            onLeadingZerosChanged: (v) =>
                                setState(() => _leadingZeros = v),
                            taxRateController: _taxRateController,
                          ),
                          OnboardingStepAppearance(
                            pageSize: _pageSize,
                            template: _template,
                            onPageSizeChanged: (size) => setState(() {
                              _pageSize = size;
                              _template = effectiveInvoiceTemplateForPageSize(
                                  _template, size);
                            }),
                            onTemplateChanged: (t) =>
                                setState(() => _template = t),
                          ),
                          const OnboardingStepDone(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            TextButton.icon(
                              onPressed: _isBusy ? null : _handleBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(l10n.actionBack),
                            ),
                          const Spacer(),
                          if (_currentStep < 3)
                            TextButton(
                              onPressed: _isBusy ? null : _handleSkip,
                              child: Text(l10n.actionSkip),
                            ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isBusy
                                ? null
                                : (_currentStep < 3 ? _handleNext : _finish),
                            icon: _isBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(_currentStep < 3
                                    ? Icons.arrow_forward_rounded
                                    : Icons.rocket_launch_rounded),
                            label: Text(_currentStep < 3
                                ? l10n.actionNext
                                : l10n.actionGetStarted),
                          ),
                        ],
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
