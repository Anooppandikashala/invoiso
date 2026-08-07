import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/settings/accessibility_screen.dart';
import 'package:invoiso/screens/settings/backup_management_screen.dart';
import 'package:invoiso/screens/settings/invoice_settings_screen.dart';
import 'package:invoiso/screens/settings/pdf_settings_screen.dart';
import 'package:invoiso/screens/settings/product_columns_settings_screen.dart';
import 'package:invoiso/screens/settings/app_info_screen.dart';
import 'package:invoiso/screens/settings/company_info_screen.dart';
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

  // Rail position of the Accessibility tab — mirrors the layout built in
  // NavigationRail's `destinations` / _buildContent's index math below.
  void _maybeJumpToAccessibility() {
    if (widget.openAccessibilityToken == null ||
        widget.openAccessibilityToken == _handledAccessibilityToken) {
      return;
    }
    _handledAccessibilityToken = widget.openAccessibilityToken;
    final cfg = ref.read(appEditionConfigProvider);
    final hasExtraTab = cfg.extraSettingsTab != null;
    final productColumnsPosition =
        cfg.isCloud ? (hasExtraTab ? 4 : 3) : (hasExtraTab ? 6 : 5);
    _selectedIndex = productColumnsPosition + 2;
  }

  Future<void> _loadCachedUpdateInfo() async {
    final cached = await ref.read(settingsRepositoryProvider).getSetting(SettingKey.lastKnownLatestVersion);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _updateInfo = UpdateInfo(latestVersion: cached, currentVersion: ref.read(appEditionConfigProvider).version);
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
            children: const [
              Icon(Icons.add_circle_outline, size: 64, color: Colors.blueGrey),
              AppSpacing.hMedium,
              Text("Options coming soon...", style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppEditionConfig cfg) {
    final bool hasExtraTab = cfg.extraSettingsTab != null;
    // Rail order (after Invoice Settings): PDF, Invoice, Product Details,
    // Customize, Software Info (last). Company/Backup/Users/PDF/Invoice keep
    // their original raw positions (0-4) — only these three trailing items
    // moved, so each gets its own position variable + idx special-case below;
    // the original fallback formula still handles positions 0-4 unchanged.
    final int productColumnsPosition =
        cfg.isCloud ? (hasExtraTab ? 4 : 3) : (hasExtraTab ? 6 : 5);
    final int customizeIndex =
        cfg.isCloud ? (hasExtraTab ? 5 : 4) : (hasExtraTab ? 7 : 6);
    // Accessibility sits right before Software Info (its old slot); Software
    // Info itself shifts one further out.
    final int accessibilityPosition = customizeIndex + 1;
    final int softwareInfoPosition = customizeIndex + 2;
    // When kIsCloud, Backup (1) and Users (2) tabs are hidden. If the edition
    // also supplies an extraSettingsTab (e.g. cloud's Team Management), it
    // takes rail slot 1 and maps to canonical case 7; everything after it
    // shifts down by 1 instead of 2. Offset back to match canonical case
    // numbers used below.
    final int idx;
    if (_selectedIndex == productColumnsPosition) {
      idx = 8;
    }
    else if (_selectedIndex == customizeIndex) {
      idx = 6;
    }
    else if (_selectedIndex == accessibilityPosition) {
      idx = 9;
    }
    else if (_selectedIndex == softwareInfoPosition) {
      idx = 5;
    }
    else if (hasExtraTab && _selectedIndex == 1) {
      idx = 7;
    }
    else if (!cfg.isCloud) {
      idx = _selectedIndex;
    }
    else if (_selectedIndex == 0) {
      idx = 0;
    }
    else {
      idx = _selectedIndex + (hasExtraTab ? 1 : 2);
    }

      switch (idx) {
      case 0:
        return const CompanyInfoScreen();
      case 1:
        return BackupManagementScreen();
      case 2:
        return UserManagementScreenV2(
          currentUser: widget.currentUser,
        );
      case 7:
        return cfg.extraSettingsTab!(context);
      case 3:
        return PdfSettingsScreen(
          onNavigateToCustomization: () {
            setState(() {
              _selectedIndex = customizeIndex;
              _highlightCustomIndex = 0;
            });
          },
        );
      case 4:
        return InvoiceSettingsScreen(
          onNavigateToCustomization: () {
            setState(() {
              _selectedIndex = customizeIndex;
              _highlightCustomIndex = 1;
            });
          },
        );
      case 5:
        return _buildAppInfoScreen();
      case 6:
        return CustomizationScreen(highlightIndex: _highlightCustomIndex);
      case 8:
        return const ProductColumnsSettingsScreen();
      case 9:
        return const AccessibilityScreen();
      default:
        return _buildDummySection("Invoice Settings");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(appEditionConfigProvider);
    if (!widget.currentUser.isAdmin()) {
      return _buildAppInfoScreen();
    }

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
              const NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('Company Info'),
              ),
              if (cfg.extraSettingsTab != null)
                NavigationRailDestination(
                  icon: Icon(cfg.extraSettingsTabIcon ?? Icons.group),
                  label: Text(cfg.extraSettingsTabLabel ?? 'Team'),
                ),
              if (!cfg.isCloud)
                const NavigationRailDestination(
                  icon: Icon(Icons.backup),
                  label: Text('Backup'),
                ),
              if (!cfg.isCloud)
                const NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Users'),
                ),
              const NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('PDF Settings'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.file_present),
                label: Text('Invoice Settings'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.view_column_outlined),
                label: Text('Product Details'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.tune_rounded),
                label: Text('Customize'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.accessibility_new_rounded),
                label: Text('Accessibility'),
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
                label: const Text('Software Info'),
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
