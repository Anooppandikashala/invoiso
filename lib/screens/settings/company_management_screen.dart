import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/database/company_registry_service.dart';
import 'package:invoiso/database/user_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/company_profile.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/locale_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/utils/company_switch_navigation.dart';
import 'package:invoiso/utils/window_title.dart';

/// Lists every company registered on this device, with actions to switch,
/// create, rename, or (self-only) delete. Reused from two entry points:
/// - The Login screen's gear icon, before anyone is authenticated
///   ([currentUser] is null). Switching/creating here is instant — nothing
///   has read per-company data yet (see [_liveSwitchTo]).
/// - Settings, for the currently-logged-in admin ([currentUser] set).
///   Switching/creating here needs a restart, since the Dashboard has
///   already loaded the previous company's data into memory.
/// Deleting a company is only ever available for the *active* one, and only
/// when [currentUser] is a logged-in admin — never reachable pre-login.
class CompanyManagementScreen extends ConsumerStatefulWidget {
  final User? currentUser;

  const CompanyManagementScreen({super.key, this.currentUser});

  @override
  ConsumerState<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState
    extends ConsumerState<CompanyManagementScreen> {
  // Matches the onboarding wizard's card width (lib/screens/onboarding/
  // onboarding_screen.dart) so this screen doesn't stretch edge-to-edge on
  // wide desktop windows.
  static const _maxContentWidth = 640.0;

  List<CompanyProfile> _companies = [];
  String? _activeId;
  bool _isLoading = true;

  bool get _isPreLogin => widget.currentUser == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final companies = await CompanyRegistryService.listCompanies();
    final activeId = await CompanyRegistryService.getActiveCompanyId();
    await refreshWindowTitle();
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _activeId = activeId;
      _isLoading = false;
    });
  }

  /// Safe pre-login: nothing has read per-company data yet, so the DB file
  /// can be swapped in place and this screen just refreshes its own list —
  /// no restart needed. Re-syncs the two providers loaded before Login even
  /// renders, per the same reasoning as the Login screen's own selector.
  Future<void> _liveSwitchTo(String id) async {
    try {
      await CompanyRegistryService.switchToCompany(id);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
          AppLocalizations.of(context)!.companyMgmtSwitchErrorMessage(e.toString()));
      return;
    }
    final themeKey = await ref.read(settingsRepositoryProvider).getThemeMode();
    final localeKey = await ref.read(settingsRepositoryProvider).getAppLocale();
    if (!mounted) return;
    ref.read(themeModeProvider.notifier).state = themeModeFromKey(themeKey);
    applyAppLocale(ref, localeFromKey(localeKey));
    await _load();
  }

  Future<void> _switchTo(CompanyProfile company) async {
    // Pre-login, nothing has been read yet — switching is instant and
    // reversible, so it happens straight away with no confirmation, the
    // same as picking a different entry in the Login screen's own selector.
    if (_isPreLogin) {
      await _liveSwitchTo(company.id);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companyMgmtSwitchConfirmTitle),
        content: Text(l10n.companyMgmtSwitchConfirmBody(company.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.companyMgmtSwitchButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await CompanyRegistryService.switchToCompany(company.id);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(l10n.companyMgmtSwitchErrorMessage(e.toString()));
      return;
    }
    if (!mounted) return;
    await returnToLoginAfterCompanyChange(context, ref);
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commonErrorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionOk),
          ),
        ],
      ),
    );
  }

  Future<void> _createCompany() async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fieldRadius = BorderRadius.circular(AppBorderRadius.xsmall);
    final existingNames =
        _companies.map((c) => c.name.trim().toLowerCase()).toSet();
    bool obscurePassword = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setObscureState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.corporate_fare,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.companyMgmtNewCompanyTitle,
                      style: const TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.onboardingCompanyNameLabel,
                        prefixIcon: const Icon(Icons.business_rounded),
                        border: OutlineInputBorder(borderRadius: fieldRadius),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      validator: (v) {
                        final trimmed = v?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return l10n.fieldRequiredMessage(
                              l10n.onboardingCompanyNameLabel);
                        }
                        if (existingNames.contains(trimmed.toLowerCase())) {
                          return l10n.companyMgmtNameTakenMessage;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(l10n.companyMgmtAdminAccountSectionLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: l10n.userMgmtUsernameRequiredLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: fieldRadius),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.userMgmtUsernameRequiredMessage
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.userMgmtPasswordRequiredLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setObscureState(
                              () => obscurePassword = !obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: fieldRadius),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? l10n.userMgmtPasswordRequiredMessage
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(l10n.companyMgmtCreateButton),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;

    final profile = await CompanyRegistryService.createCompany(name);
    await CompanyRegistryService.switchToCompany(profile.id);

    // Overwrite the seeded admin/admin login with the credentials just
    // entered, and the placeholder company name — both left behind by the
    // schema's default seed data (`_createDB`), which still needs to run
    // unchanged for the plain single-company case.
    final seededAdmin = await UserService.getUserByUsername('admin');
    if (seededAdmin != null) {
      await UserService.updateUser(User(
        id: seededAdmin.id,
        username: username,
        password: '',
        userType: seededAdmin.userType,
      ));
      await UserService.updatePassword(seededAdmin.id, password);
    }
    final info = await ref.read(companyInfoRepositoryProvider).getCompanyInfo();
    if (info != null) {
      await ref.read(companyInfoRepositoryProvider).updateCompanyInfo(CompanyInfo(
            id: info.id,
            name: name,
            address: info.address,
            phone: info.phone,
            email: info.email,
            website: info.website,
            gstin: info.gstin,
            panNumber: info.panNumber,
            fssaiCode: info.fssaiCode,
            country: info.country,
          ));
    }

    if (!mounted) return;

    if (_isPreLogin) {
      final themeKey = await ref.read(settingsRepositoryProvider).getThemeMode();
      final localeKey = await ref.read(settingsRepositoryProvider).getAppLocale();
      if (!mounted) return;
      ref.read(themeModeProvider.notifier).state = themeModeFromKey(themeKey);
      applyAppLocale(ref, localeFromKey(localeKey));
      await _load();
      return;
    }

    await returnToLoginAfterCompanyChange(context, ref);
  }

  Future<void> _rename(CompanyProfile company) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: company.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companyMgmtRenameTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.onboardingCompanyNameLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || !mounted) return;
    await CompanyRegistryService.renameCompany(company.id, newName);
    await _load();
  }

  Future<void> _deleteCompany(CompanyProfile company) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final matches = controller.text.trim() == company.name;
          return AlertDialog(
            title: Text(l10n.companyMgmtDeleteConfirmTitle(company.name)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.companyMgmtDeleteConfirmBody),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: company.name),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                onPressed: matches ? () => Navigator.of(context).pop(true) : null,
                child: Text(l10n.actionDelete,
                    style: const TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;

    final isActive = company.id == _activeId;
    if (isActive) {
      // Removing the active company — hand off to whichever other company
      // remains before deleting, so the app always has one to load.
      final fallback = _companies.firstWhere((c) => c.id != company.id);
      await CompanyRegistryService.switchToCompany(fallback.id);
    }
    await CompanyRegistryService.deleteCompany(company.id);

    if (!mounted) return;

    if (isActive) {
      // Only the active company's removal touches this app instance's own
      // open DB connection — that's what actually needs a fresh login.
      await returnToLoginAfterCompanyChange(context, ref);
    } else {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.companyMgmtDeletedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canDelete = widget.currentUser?.isAdmin() ?? false;
    // A light pastel green (fine against the light theme's white cards)
    // reads as a washed-out, low-contrast card against the dark theme's
    // near-black background and default light text — swap to a dark,
    // opaque green so the active card still reads as a clean highlight
    // in both themes.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCardFill = isDark ? Colors.green.shade900 : Colors.green.shade50;
    final activeCardBorder = isDark ? Colors.green.shade600 : Colors.green.shade300;
    final activeBadgeBg =
        isDark ? Colors.green.withValues(alpha: 0.25) : Colors.green.withValues(alpha: 0.12);
    final activeBadgeBorder =
        isDark ? Colors.green.shade400 : Colors.green.withValues(alpha: 0.4);
    final activeBadgeText = isDark ? Colors.green.shade300 : Colors.green;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyMgmtTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final company in _companies)
                      Card(
                        // A flat, fully-opaque pastel instead of an
                        // alpha-blended green — alpha blending combined with
                        // the card's own drop shadow read as a muddy sage
                        // rather than a clean highlight.
                        elevation: company.id == _activeId ? 0 : null,
                        color: company.id == _activeId ? activeCardFill : null,
                        shape: company.id == _activeId
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: BorderSide(color: activeCardBorder),
                              )
                            : null,
                        child: ListTile(
                          title: Text(company.name),
                          subtitle: company.id == _activeId
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: activeBadgeBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: activeBadgeBorder),
                                    ),
                                    child: Text(
                                      l10n.companyMgmtActiveBadge,
                                      style: TextStyle(
                                          color: activeBadgeText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.companyMgmtRenameTooltip,
                                onPressed: () => _rename(company),
                              ),
                              if (company.id != _activeId)
                                TextButton(
                                  onPressed: () => _switchTo(company),
                                  child: Text(l10n.companyMgmtSwitchButton),
                                ),
                              if (canDelete)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: _companies.length > 1
                                      ? l10n.companyMgmtDeleteButton
                                      : l10n.companyMgmtOnlyCompanyTooltip,
                                  onPressed: _companies.length > 1
                                      ? () => _deleteCompany(company)
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _createCompany,
                      child: Text(l10n.companyMgmtNewCompanyButton),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
