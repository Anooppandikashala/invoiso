import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/settings/accessibility_screen.dart';
import 'package:invoiso/screens/settings/backup_management_screen.dart';
// import 'package:invoiso/screens/settings/invoice_settings_screen.dart';
import 'package:invoiso/screens/settings/invoice_settings_screen_v2.dart';
// import 'package:invoiso/screens/settings/pdf_settings_screen.dart';
import 'package:invoiso/screens/settings/pdf_settings_screen_v2.dart';
import 'package:invoiso/screens/settings/product_columns_settings_screen.dart';
import 'package:invoiso/screens/settings/app_info_screen.dart';
import 'package:invoiso/screens/settings/company_info_screen.dart';
import 'package:invoiso/screens/settings/company_management_screen.dart';
import 'package:invoiso/screens/settings/customization_screen.dart';
// import 'package:invoiso/screens/settings/user_management_screen.dart';
import 'package:invoiso/screens/settings/user_management_screen_v2.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final User currentUser;
  // Bump this (e.g. a counter) each time the caller wants to force-navigate
  // to the Accessibility tab, even if this screen is already mounted.
  final Object? openAccessibilityToken;
  const SettingsScreen(
      {super.key, required this.currentUser, this.openAccessibilityToken});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Canonical content ids, independent of rail position (which shifts
  // depending on edition/extra-tab). Used as the switch keys in
  // _buildContent; _railOrder below maps a rail position to one of these.
  static const _idCompanyInfo = 0;
  static const _idBackup = 1;
  static const _idUsers = 2;
  static const _idPdf = 3;
  static const _idInvoice = 4;
  static const _idSoftwareInfo = 5;
  static const _idCustomize = 6;
  static const _idExtra = 7;
  static const _idProductColumns = 8;
  static const _idAccessibility = 9;
  static const _idCompanies = 10;

  int _selectedIndex = 0;
  int? _highlightCustomIndex;
  Object? _handledAccessibilityToken;

  // Update check state — shared between the NavigationRail badge and
  // AppInfoScreen, so it lives here rather than duplicated in both.
  UpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;
  bool _updateCheckFailed = false;

  @override
  void initState() {
    super.initState();
    // Company Info is the default landing tab; Companies (rail position 0
    // on offline editions) is opened explicitly, not landed on by default.
    _selectedIndex =
        _railOrder(ref.read(appEditionConfigProvider)).indexOf(_idCompanyInfo);
    if (ref.read(appEditionConfigProvider).enableUpdateCheck) {
      _loadCachedUpdateInfo();
    }
    _maybeJumpToAccessibility();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openAccessibilityToken != oldWidget.openAccessibilityToken) {
      setState(_maybeJumpToAccessibility);
    }
  }

  // Content ids in rail-position order — must mirror NavigationRail's
  // `destinations` list in build() exactly, entry for entry, so a raw
  // _selectedIndex can be mapped back to a canonical content id (and vice
  // versa) with no hand-derived offset arithmetic to keep in sync.
  List<int> _railOrder(AppEditionConfig cfg) {
    final hasExtraTab = cfg.extraSettingsTab != null;
    return [
      if (!cfg.isCloud) _idCompanies,
      _idCompanyInfo,
      if (hasExtraTab) _idExtra,
      if (!cfg.isCloud) _idBackup,
      if (!cfg.isCloud) _idUsers,
      _idPdf,
      _idInvoice,
      _idProductColumns,
      _idCustomize,
      _idAccessibility,
      _idSoftwareInfo,
    ];
  }

  // Rail position of the Accessibility tab — mirrors the layout built in
  // NavigationRail's `destinations` / _buildContent's index math below.
  void _maybeJumpToAccessibility() {
    if (widget.openAccessibilityToken == null ||
        widget.openAccessibilityToken == _handledAccessibilityToken) {
      return;
    }
    _handledAccessibilityToken = widget.openAccessibilityToken;
    final cfg = ref.read(appEditionConfigProvider);
    _selectedIndex = _railOrder(cfg).indexOf(_idAccessibility);
  }

  Future<void> _loadCachedUpdateInfo() async {
    final cached = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.lastKnownLatestVersion);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _updateInfo = UpdateInfo(
            latestVersion: cached,
            currentVersion: ref.read(appEditionConfigProvider).version);
      });
    }
  }

  Future<void> _checkForUpdatesNow() async {
    if (_isCheckingUpdate) return;
    setState(() {
      _isCheckingUpdate = true;
      _updateCheckFailed = false;
    });
    final info = await UpdateService.checkForUpdate(force: true);
    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = false;
      if (info != null) {
        _updateInfo = info;
        _updateCheckFailed = false;
      } else {
        _updateCheckFailed = true;
      }
    });
  }

  Widget _buildAppInfoScreen() {
    return AppInfoScreen(
      updateInfo: _updateInfo,
      isCheckingUpdate: _isCheckingUpdate,
      updateCheckFailed: _updateCheckFailed,
      onCheckForUpdates: _checkForUpdatesNow,
    );
  }

  Widget _buildDummySection(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline,
                  size: 64, color: Colors.blueGrey),
              AppSpacing.hMedium,
              Text(
                  AppLocalizations.of(context)!
                      .settingsOptionsComingSoonMessage,
                  style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppEditionConfig cfg) {
    final railOrder = _railOrder(cfg);
    final int idx = _selectedIndex < railOrder.length
        ? railOrder[_selectedIndex]
        : -1;
    final int customizeIndex = railOrder.indexOf(_idCustomize);

    switch (idx) {
      case _idCompanyInfo:
        return const CompanyInfoScreen();
      case _idBackup:
        return BackupManagementScreen();
      case _idUsers:
        return UserManagementScreenV2(
          currentUser: widget.currentUser,
        );
      case _idExtra:
        return cfg.extraSettingsTab!(context);
      case _idPdf:
        return PdfSettingsScreenV2(
          onNavigateToCustomization: () {
            setState(() {
              _selectedIndex = customizeIndex;
              _highlightCustomIndex = 0;
            });
          },
        );
      case _idInvoice:
        return InvoiceSettingsScreenV2(
          onNavigateToCustomization: () {
            setState(() {
              _selectedIndex = customizeIndex;
              _highlightCustomIndex = 1;
            });
          },
        );
      case _idSoftwareInfo:
        return _buildAppInfoScreen();
      case _idCustomize:
        return CustomizationScreen(highlightIndex: _highlightCustomIndex);
      case _idProductColumns:
        return const ProductColumnsSettingsScreen();
      case _idAccessibility:
        return const AccessibilityScreen();
      case _idCompanies:
        return CompanyManagementScreen(currentUser: widget.currentUser);
      default:
        return _buildDummySection(
            AppLocalizations.of(context)!.invoiceSettingsAppBarTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(appEditionConfigProvider);
    if (!widget.currentUser.isAdmin()) {
      return _buildAppInfoScreen();
    }
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              if (!cfg.isCloud)
                NavigationRailDestination(
                  icon: const Icon(Icons.corporate_fare),
                  label: Text(l10n.settingsNavCompaniesLabel),
                ),
              NavigationRailDestination(
                icon: const Icon(Icons.business),
                label: Text(l10n.settingsNavCompanyInfoLabel),
              ),
              if (cfg.extraSettingsTab != null)
                NavigationRailDestination(
                  icon: Icon(cfg.extraSettingsTabIcon ?? Icons.group),
                  label: Text(
                      cfg.extraSettingsTabLabel ?? l10n.settingsNavTeamLabel),
                ),
              if (!cfg.isCloud)
                NavigationRailDestination(
                  icon: const Icon(Icons.backup),
                  label: Text(l10n.settingsNavBackupLabel),
                ),
              if (!cfg.isCloud)
                NavigationRailDestination(
                  icon: const Icon(Icons.people),
                  label: Text(l10n.settingsNavUsersLabel),
                ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings),
                label: Text(l10n.pdfSettingsTitle),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.file_present),
                label: Text(l10n.invoiceSettingsAppBarTitle),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.view_column_outlined),
                label: Text(l10n.settingsNavProductDetailsLabel),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.tune_rounded),
                label: Text(l10n.settingsNavCustomizeLabel),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.accessibility_new_rounded),
                label: Text(l10n.settingsNavAccessibilityLabel),
              ),
              NavigationRailDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.info_outline),
                    if (cfg.enableUpdateCheck && _updateInfo?.hasUpdate == true)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: Text(l10n.settingsNavSoftwareInfoLabel),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildContent(cfg)),
        ],
      ),
    );
  }
}
