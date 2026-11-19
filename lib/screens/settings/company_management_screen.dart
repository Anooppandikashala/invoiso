import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/common/setting_key.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/database/user_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/company_profile.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/locale_provider.dart';
import 'package:invoiso/providers/purchase_bills_settings_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/utils/company_switch_navigation.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/utils/window_title.dart';
import 'package:invoiso/widgets/company_avatar.dart';

/// Lists every company registered on this device, with actions to switch,
/// create, or (self-only) rename/delete. Reused from two entry points:
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
  // Keeps this screen from stretching edge-to-edge on wide desktop windows.
  static const _maxContentWidth = 800.0;
  // Same accent as the Login screen's Sign in button.
  static const _accent = Color(0xFF2563EB);

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
    final companies = await BackendServices.companyRegistry.listCompanies();
    final activeId = await BackendServices.companyRegistry.getActiveCompanyId();
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
      await BackendServices.companyRegistry.switchToCompany(id);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
          AppLocalizations.of(context)!.companyMgmtSwitchErrorMessage(e.toString()));
      return;
    }
    final themeKey = await ref.read(settingsRepositoryProvider).getThemeMode();
    final localeKey = await ref.read(settingsRepositoryProvider).getAppLocale();
    final purchaseBills = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.enablePurchaseBillsAndSuppliers);
    if (!mounted) return;
    ref.read(themeModeProvider.notifier).state = themeModeFromKey(themeKey);
    applyAppLocale(ref, localeFromKey(localeKey));
    ref.read(enablePurchaseBillsAndSuppliersProvider.notifier).state =
        purchaseBills == 'true';
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
      await BackendServices.companyRegistry.switchToCompany(company.id);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(l10n.companyMgmtSwitchErrorMessage(e.toString()));
      return;
    }
    if (!mounted) return;
    await returnToLoginAfterCompanyChange(context, ref,
        currentUser: widget.currentUser);
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
    final isCloud = ref.read(appEditionConfigProvider).isCloud;
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
                    // Cloud: the creator owns the new company with the same
                    // login — no separate admin account.
                    if (!isCloud) ...[
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

    // Cloud refuses past the plan's company limit — show its message.
    final CompanyProfile profile;
    try {
      profile = await BackendServices.companyRegistry.createCompany(name);
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
      return;
    }
    await BackendServices.companyRegistry.switchToCompany(profile.id);

    // Overwrite the seeded admin/admin login with the credentials just
    // entered, and the placeholder company name — both left behind by the
    // schema's default seed data (`_createDB`), which still needs to run
    // unchanged for the plain single-company case.
    final seededAdmin =
        isCloud ? null : await UserService.getUserByUsername('admin');
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
      final purchaseBills = await ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.enablePurchaseBillsAndSuppliers);
      if (!mounted) return;
      ref.read(themeModeProvider.notifier).state = themeModeFromKey(themeKey);
      applyAppLocale(ref, localeFromKey(localeKey));
      ref.read(enablePurchaseBillsAndSuppliersProvider.notifier).state =
          purchaseBills == 'true';
      await _load();
      return;
    }

    await returnToLoginAfterCompanyChange(context, ref,
        currentUser: widget.currentUser);
  }

  Future<void> _rename(CompanyProfile company) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: company.name);
    final formKey = GlobalKey<FormState>();
    // Same rule as New Company: names must stay unique (case-insensitive),
    // ignoring this company's own current name.
    final otherNames = {
      for (final c in _companies)
        if (c.id != company.id) c.name.trim().toLowerCase()
    };
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companyMgmtRenameTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.onboardingCompanyNameLabel),
            autofocus: true,
            validator: (v) =>
                otherNames.contains((v ?? '').trim().toLowerCase())
                    ? l10n.companyMgmtNameTakenMessage
                    : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || !mounted) return;
    await BackendServices.companyRegistry.renameCompany(company.id, newName);
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
              FilledButton(
                onPressed: matches ? () => Navigator.of(context).pop(true) : null,
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white),
                child: Text(l10n.actionDelete),
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
      await BackendServices.companyRegistry.switchToCompany(fallback.id);
    }
    await BackendServices.companyRegistry.deleteCompany(company.id);

    if (!mounted) return;

    if (isActive) {
      // Only the active company's removal touches this app instance's own
      // open DB connection — that's what actually needs a fresh login.
      await returnToLoginAfterCompanyChange(context, ref,
        currentUser: widget.currentUser);
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
    // Rename/delete only the company the admin is logged into — never
    // another company (whose own admins never authenticated here), and
    // never pre-login.
    final canManage = widget.currentUser?.isAdmin() ?? false;
    final isCloud = ref.read(appEditionConfigProvider).isCloud;
    // Cloud: only the active company's owner creates companies
    // (create_organization is owner-only).
    final canCreate = canManage || !isCloud;
    final active = _companies.where((c) => c.id == _activeId).firstOrNull;
    final others = _companies.where((c) => c.id != _activeId).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyMgmtTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                  children: [
                    _buildHeading(l10n, canCreate),
                    const SizedBox(height: 28),
                    if (_isPreLogin) ...[
                      // Pre-login: every company is a selectable card;
                      // picking one switches instantly (see [_switchTo]).
                      for (final company in _companies)
                        _companyRow(
                          company,
                          l10n,
                          selected: company.id == _activeId,
                          onTap: company.id == _activeId
                              ? null
                              : () => _switchTo(company),
                          trailing: company.id == _activeId
                              ? _selectedPill(l10n)
                              : _radioDot(),
                        ),
                      if (canCreate) _addAnotherButton(l10n),
                      const SizedBox(height: 18),
                      if (active != null) _continueBar(l10n, active),
                      const SizedBox(height: 16),
                      Text(l10n.companyMgmtRenameDeleteHint,
                          style: _mutedStyle(13)),
                    ] else ...[
                      if (active != null) ...[
                        _sectionLabel(l10n.companyMgmtSignedInTo),
                        _activeCard(active, l10n, canManage),
                        const SizedBox(height: 32),
                      ],
                      if (others.isNotEmpty || canCreate)
                        _sectionLabel(l10n.companyMgmtOtherCompanies),
                      for (final company in others)
                        _companyRow(
                          company,
                          l10n,
                          trailing: TextButton(
                            onPressed: () => _switchTo(company),
                            style: _secondaryButtonStyle(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_horiz, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.companyMgmtSwitchButton),
                              ],
                            ),
                          ),
                        ),
                      if (canCreate) _addAnotherButton(l10n),
                      if (!isCloud) ...[
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(l10n.companyMgmtSwitchSignsOutNote,
                                  style: _mutedStyle(13)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  TextStyle _mutedStyle(double size) => TextStyle(
      fontSize: size,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant);

  ButtonStyle _secondaryButtonStyle({Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton.styleFrom(
      foregroundColor: color ?? scheme.onSurface,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ).copyWith(
      side: WidgetStatePropertyAll(BorderSide(
          color: color?.withValues(alpha: 0.4) ?? scheme.outlineVariant)),
    );
  }

  Widget _buildHeading(AppLocalizations l10n, bool canCreate) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPreLogin
                    ? l10n.companyMgmtPickTitle
                    : l10n.companyMgmtHeading,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                _isPreLogin
                    ? l10n.companyMgmtPickSubtitle
                    : l10n.companyMgmtSubtitle,
                style: _mutedStyle(15),
              ),
            ],
          ),
        ),
        if (canCreate)
          FilledButton(
            onPressed: _createCompany,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(l10n.companyMgmtNewCompanyButton),
          ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );

  /// "Created 02 Mar 2026" — tells same-named companies apart.
  String _meta(CompanyProfile company, AppLocalizations l10n) =>
      l10n.companyMgmtCreatedOn(AppFormatters.formatDate(company.createdAt));

  Widget _activeCard(
      CompanyProfile company, AppLocalizations l10n, bool canManage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canDelete = _companies.length > 1;
    final info = Row(
      children: [
        CompanyAvatar(id: company.id, name: company.name, size: 56),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    company.name,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF7EA6FF)
                                : const Color(0xFF1D4ED8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.companyMgmtActiveBadge,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFA9C3FF)
                                  : const Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(_meta(company, l10n), style: _mutedStyle(13)),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton(
          onPressed: () => _rename(company),
          style: _secondaryButtonStyle(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, size: 16),
              const SizedBox(width: 8),
              Text(l10n.companyMgmtRenameTooltip),
            ],
          ),
        ),
        Tooltip(
          message: canDelete
              ? l10n.companyMgmtDeleteButton
              : l10n.companyMgmtOnlyCompanyTooltip,
          child: TextButton(
            onPressed: canDelete ? () => _deleteCompany(company) : null,
            style: _secondaryButtonStyle(color: Colors.red.shade400),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, size: 16),
                const SizedBox(width: 8),
                Text(l10n.actionDelete),
              ],
            ),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2B) : const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF2B4A8C) : const Color(0xFF93B4F5)),
      ),
      child: !canManage
          ? info
          : LayoutBuilder(
              // Buttons beside the name on desktop, below it on phones.
              builder: (context, constraints) => constraints.maxWidth >= 560
                  ? Row(
                      children: [
                        Expanded(child: info),
                        const SizedBox(width: 16),
                        actions,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [info, const SizedBox(height: 16), actions],
                    ),
            ),
    );
  }

  Widget _companyRow(CompanyProfile company, AppLocalizations l10n,
      {required Widget trailing, bool selected = false, VoidCallback? onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: selected ? _accent : scheme.outlineVariant,
              width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CompanyAvatar(id: company.id, name: company.name, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(_meta(company, l10n), style: _mutedStyle(13)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedPill(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFA9C3FF) : const Color(0xFF1E3A8A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(l10n.companyMgmtSelected,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  Widget _radioDot() => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.outline, width: 2),
        ),
      );

  Widget _addAnotherButton(AppLocalizations l10n) => SizedBox(
        height: 60,
        child: TextButton.icon(
          onPressed: _createCompany,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.companyMgmtAddAnother),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1.5),
            ),
          ),
        ),
      );

  Widget _continueBar(AppLocalizations l10n, CompanyProfile active) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Text(l10n.companyMgmtReadyToSignIn(active.name),
              style: TextStyle(fontSize: 14, color: scheme.onSurface)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.companyMgmtContinueToSignIn),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
