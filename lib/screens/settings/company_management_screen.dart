import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/database/company_registry_service.dart';
import 'package:invoiso/database/user_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/company_profile.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/locale_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/utils/window_title.dart';
import 'package:invoiso/widgets/restart_required_dialog.dart';

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
    await CompanyRegistryService.switchToCompany(id);
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

    await CompanyRegistryService.switchToCompany(company.id);
    if (!mounted) return;
    showRestartRequiredDialog(context,
        title: l10n.companyMgmtSwitchRestartTitle,
        body: l10n.companyMgmtSwitchRestartBody);
  }

  Future<void> _createCompany() async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companyMgmtNewCompanyTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration:
                    InputDecoration(labelText: l10n.onboardingCompanyNameLabel),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.fieldRequiredMessage(l10n.onboardingCompanyNameLabel)
                    : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.companyMgmtAdminAccountSectionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: usernameController,
                decoration:
                    InputDecoration(labelText: l10n.userMgmtUsernameRequiredLabel),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.userMgmtUsernameRequiredMessage
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.userMgmtPasswordRequiredLabel),
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.userMgmtPasswordRequiredMessage
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
            },
            child: Text(l10n.companyMgmtCreateButton),
          ),
        ],
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

    showRestartRequiredDialog(context,
        title: l10n.companyMgmtCreateRestartTitle,
        body: l10n.companyMgmtCreateRestartBody);
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

  Future<void> _deleteActiveCompany(CompanyProfile company) async {
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

    // The active company is being removed — hand off to whichever other
    // company remains before deleting, so the app always has one to load.
    final remaining = _companies.where((c) => c.id != company.id).toList();
    final fallback = remaining.first;
    await CompanyRegistryService.switchToCompany(fallback.id);
    await CompanyRegistryService.deleteCompany(company.id);

    if (!mounted) return;
    showRestartRequiredDialog(context,
        title: l10n.companyMgmtDeleteRestartTitle,
        body: l10n.companyMgmtDeleteRestartBody);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canDelete = widget.currentUser?.isAdmin() ?? false;

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
                        child: ListTile(
                          title: Text(company.name),
                          subtitle: company.id == _activeId
                              ? Text(l10n.companyMgmtActiveBadge)
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
                              if (company.id == _activeId && canDelete)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: _companies.length > 1
                                      ? l10n.companyMgmtDeleteButton
                                      : l10n.companyMgmtOnlyCompanyTooltip,
                                  onPressed: _companies.length > 1
                                      ? () => _deleteActiveCompany(company)
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
