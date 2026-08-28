import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/widgets/discovery_banner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/app_config.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/services/update_service.dart';
import 'package:invoiso/widgets/update_dialog.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/domain/customer_identity.dart';
import 'package:invoiso/common/invoiso_colors.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/screens/settings/settings_screen.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart';
import 'package:invoiso/widgets/customer_info_button.dart';
import 'package:invoiso/utils/session_manager.dart';

import 'package:invoiso/models/user.dart';
// import 'package:invoiso/screens/customer_management_screen.dart';
import 'package:invoiso/screens/customer_management_screen_v2.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/screens/screens_v1/create_invoice_screen.dart' as v1;
import 'package:invoiso/screens/create_invoice_screen_v2.dart';
// import 'package:invoiso/screens/product_management_screen.dart';
import 'package:invoiso/screens/product_management_screen_v2.dart';
// import 'package:invoiso/screens/invoice_management_screen.dart';
import 'package:invoiso/screens/invoice_management_screen_v2.dart';
import 'package:invoiso/screens/auth/login_screen.dart';
import 'package:invoiso/screens/reports_screen.dart';

// invoice.type is a raw internal value ('Invoice'/'Quotation'/'Receipt') used
// for comparisons throughout this file — only the displayed label is localized.
String _invoiceTypeLabel(BuildContext context, String type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case 'Quotation':
      return l10n.labelQuotation;
    case 'Receipt':
      return l10n.labelReceipt;
    default:
      return l10n.labelInvoice;
  }
}

// Dashboard Screen
class DashboardScreen extends ConsumerStatefulWidget {
  final User loggedInUser;

  const DashboardScreen(this.loggedInUser, {super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  late User _currentUser;
  String? _pendingReportsStatementCustomerKey;

  Invoice? invoiceToEdit;
  Invoice? _invoiceToClone;
  String _cloneType = 'Invoice';
  bool _hasUpdate = false;
  String _createInvoiceLayout = 'v2';
  int? _accessibilityJumpToken;
  final InvoiceFormGuard _invoiceFormGuard = InvoiceFormGuard();
  final v1.InvoiceFormGuard _invoiceFormGuardV1 = v1.InvoiceFormGuard();
  final FocusNode _shortcutsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.loggedInUser;
    _loadCreateInvoiceLayout();
    SessionManager.initialize(_onSessionTimeout);
    if (ref.read(appEditionConfigProvider).enableUpdateCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
    }
    // Tab 1 (Create Invoice) owns its own autofocus/shortcuts — only claim
    // focus here for the other tabs, so it doesn't get stolen away and
    // block the Create Invoice screen's own Ctrl shortcuts from working.
    if (_selectedIndex != 1) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _shortcutsFocusNode.requestFocus());
    }
  }

  Future<void> _loadCreateInvoiceLayout() async {
    final layout = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.createInvoiceLayout);
    if (!mounted) return;
    setState(() => _createInvoiceLayout = layout ?? 'v2');
  }

  Future<void> _checkForUpdates() async {
    final info = await UpdateService.checkForUpdate();
    if (info == null) return;
    if (info.hasUpdate && mounted) setState(() => _hasUpdate = true);
    if (!await UpdateService.shouldNotify(info)) return;
    if (!mounted) return;
    await UpdateDialog.show(context, info);
  }

  @override
  void dispose() {
    SessionManager.dispose();
    _shortcutsFocusNode.dispose();
    super.dispose();
  }

  void _logoutAndResetSession() async {
    await ref.read(authRepositoryProvider).logoutAndSessionReset();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _onSessionTimeout() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context)!.dashboardSessionExpiredMessage),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _refreshUser() async {
    final cfg = ref.watch(appEditionConfigProvider);
    if (cfg.isCloud || !mounted) return;
    final fresh =
        await ref.read(authRepositoryProvider).getUserById(_currentUser.id);
    if (fresh != null && mounted) {
      setState(() => _currentUser = fresh);
    }
  }

  Widget buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardHome(
            onEditInvoice: editInvoice,
            onCloneInvoice: cloneInvoice,
            user: _currentUser);
      case 1:
        final createInvoiceKey = ValueKey(
            'create_invoice_${invoiceToEdit?.id ?? 'new'}_${_invoiceToClone?.id ?? ''}');
        void onCreateNewInvoice() {
          if (!mounted) return;
          setState(() {
            invoiceToEdit = null;
            _invoiceToClone = null;
          });
        }
        return _createInvoiceLayout == 'v1'
            ? v1.CreateInvoiceScreen(
                key: createInvoiceKey,
                invoiceToEdit: invoiceToEdit,
                cloneFrom: _invoiceToClone,
                cloneType: _invoiceToClone != null ? _cloneType : null,
                guard: _invoiceFormGuardV1,
                onCreateNewInvoice: onCreateNewInvoice,
              )
            : CreateInvoiceScreenV2(
                key: createInvoiceKey,
                invoiceToEdit: invoiceToEdit,
                cloneFrom: _invoiceToClone,
                cloneType: _invoiceToClone != null ? _cloneType : null,
                guard: _invoiceFormGuard,
                onCreateNewInvoice: onCreateNewInvoice,
              );
      case 2:
        return InvoiceManagementScreenV2(
          key: const ValueKey('invoice_list'),
          onEditInvoice: editInvoice,
          onCloneInvoice: cloneInvoice,
          user: _currentUser,
          filterType: 'Invoice',
        );
      case 3:
        return InvoiceManagementScreenV2(
          key: const ValueKey('quotation_list'),
          onEditInvoice: editInvoice,
          onCloneInvoice: cloneInvoice,
          user: _currentUser,
          filterType: 'Quotation',
        );
      case 4:
        return InvoiceManagementScreenV2(
          key: const ValueKey('receipt_list'),
          onEditInvoice: editInvoice,
          onCloneInvoice: cloneInvoice,
          user: _currentUser,
          filterType: 'Receipt',
        );
      case 5:
        return CustomerManagementScreenV2(
          user: _currentUser,
          onViewCustomerStatement: (c) {
            setState(() {
              _pendingReportsStatementCustomerKey =
                  CustomerIdentity.key(id: c.id, name: c.name);
              _selectedIndex = 7;
            });
          },
        );
      case 6:
        return ProductManagementScreenV2(user: _currentUser);
      case 7:
        final statementCustomerKey = _pendingReportsStatementCustomerKey;
        _pendingReportsStatementCustomerKey = null;
        return ReportsScreen(initialStatementCustomerKey: statementCustomerKey);
      case 8:
        return SettingsScreen(
          currentUser: _currentUser,
          openAccessibilityToken: _accessibilityJumpToken,
        );
      default:
        return Center(
            child:
                Text(AppLocalizations.of(context)!.dashboardUnknownTabLabel));
    }
  }

  Widget _buildCreateInvoiceLayoutToggle() {
    final isV2 = _createInvoiceLayout == 'v2';
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: CircleBorder(
          side:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      elevation: 2,
      child: IconButton(
        icon: Icon(isV2 ? Icons.auto_awesome : Icons.history, size: 20),
        tooltip: l10n.dashboardInvoiceLayoutTooltip(
            isV2 ? l10n.dashboardLayoutNew : l10n.dashboardLayoutClassic),
        onPressed: _showCreateInvoiceLayoutInfo,
      ),
    );
  }

  void _showCreateInvoiceLayoutInfo() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dashboardInvoiceLayoutDialogTitle),
        content: Text(l10n.dashboardInvoiceLayoutDialogBody(
            _createInvoiceLayout == 'v1'
                ? l10n.dashboardLayoutClassic
                : l10n.dashboardLayoutNew)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionClose)),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!await _canLeaveInvoiceForm()) return;
              if (!mounted) return;
              setState(() {
                _selectedIndex = 8;
                _accessibilityJumpToken = (_accessibilityJumpToken ?? 0) + 1;
              });
            },
            child: Text(l10n.dashboardOpenSettingsAction),
          ),
        ],
      ),
    );
  }

  void editInvoice(Invoice invoice) {
    _openEditInvoice(invoice);
  }

  Future<void> _openEditInvoice(Invoice invoice) async {
    if (!await _canLeaveInvoiceForm()) return;
    if (!mounted) return;
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = invoice;
      _invoiceToClone = null;
    });
    _shortcutsFocusNode.unfocus();
  }

  void cloneInvoice(Invoice invoice, String type) {
    _openCloneInvoice(invoice, type);
  }

  Future<void> _openCloneInvoice(Invoice invoice, String type) async {
    if (!await _canLeaveInvoiceForm()) return;
    if (!mounted) return;
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = null;
      _invoiceToClone = invoice;
      _cloneType = type;
    });
    _shortcutsFocusNode.unfocus();
  }

  Future<bool> _canLeaveInvoiceForm() async {
    if (_createInvoiceLayout == 'v1') {
      return await _invoiceFormGuardV1.canLeave?.call() ?? true;
    }
    return await _invoiceFormGuard.canLeave?.call() ?? true;
  }

  Future<void> _selectTab(int index) async {
    if (_selectedIndex == index) return;
    if (_selectedIndex == 1 && !await _canLeaveInvoiceForm()) return;
    if (_selectedIndex == 7 && index != 7) await _refreshUser();
    if (index == 1) await _loadCreateInvoiceLayout();
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        invoiceToEdit = null;
        _invoiceToClone = null;
      }
    });
    // See initState: only hold shortcuts focus for non-create-invoice tabs.
    // Autofocus is a no-op while this scope already has a focused node, so
    // on the way IN to tab 1 we must explicitly unfocus — otherwise Create
    // Invoice's own `Focus(autofocus: true)` never actually takes focus and
    // its Ctrl+S/N/M/O/P shortcuts silently stop firing.
    if (index == 1) {
      _shortcutsFocusNode.unfocus();
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _shortcutsFocusNode.requestFocus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: SessionManager.onUserActivity,
      onPanDown: (_) => SessionManager.onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyQ, control: true): () =>
              _selectTab(1),
        },
        child: Focus(
          focusNode: _shortcutsFocusNode,
          child: Scaffold(
            body: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: Stack(
                    children: [
                      buildScreen(),
                      if (_selectedIndex == 1)
                        Positioned(
                            bottom: 16,
                            right: 16,
                            child: _buildCreateInvoiceLayoutToggle()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final expanded = _sidebarExpanded;
    final primary = Theme.of(context).primaryColor;
    final cfg = ref.watch(appEditionConfigProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: expanded ? 210 : 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
            right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant, width: 1)),
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo + toggle ──────────────────────────
            if (expanded)
              SizedBox(
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 16,
                      right: 36,
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/images/logo_dark.png'
                            : 'assets/images/logo.png',
                        height: 36,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      child: Tooltip(
                        message: AppLocalizations.of(context)!
                            .dashboardCollapseSidebarTooltip,
                        child: InkWell(
                          onTap: () {
                            if (!mounted) return;
                            setState(() => _sidebarExpanded = false);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.chevron_left_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/images/logo_v_dark.png'
                            : 'assets/images/logo_v.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: AppLocalizations.of(context)!
                          .dashboardExpandSidebarTooltip,
                      child: InkWell(
                        onTap: () {
                          if (!mounted) return;
                          setState(() => _sidebarExpanded = true);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.chevron_right_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 1,
                thickness: 1),
            const SizedBox(height: 8),

            // ── Nav Items ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard,
                        AppLocalizations.of(context)!.navDashboard),
                    _buildNavItem(1, Icons.receipt_outlined, Icons.receipt,
                        AppLocalizations.of(context)!.navNewInvoice),
                    _buildNavItem(
                        2,
                        Icons.receipt_long_outlined,
                        Icons.receipt_long,
                        AppLocalizations.of(context)!.navInvoices),
                    _buildNavItem(
                        3,
                        Icons.request_quote_outlined,
                        Icons.request_quote,
                        AppLocalizations.of(context)!.navQuotations),
                    _buildNavItem(
                        4,
                        Icons.point_of_sale_outlined,
                        Icons.point_of_sale,
                        AppLocalizations.of(context)!.navReceipts),
                    _buildNavItem(5, Icons.people_outline, Icons.people,
                        AppLocalizations.of(context)!.navCustomers),
                    _buildNavItem(
                        6,
                        Icons.inventory_2_outlined,
                        Icons.inventory_2,
                        AppLocalizations.of(context)!.navProducts),
                    _buildNavItem(7, Icons.bar_chart_outlined, Icons.bar_chart,
                        AppLocalizations.of(context)!.navReports),
                    _buildNavItem(8, Icons.settings_outlined, Icons.settings,
                        AppLocalizations.of(context)!.navSettings,
                        showDot: _hasUpdate),
                  ],
                ),
              ),
            ),

            // ── User Info ──────────────────────────────
            Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 1,
                thickness: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                final useExpanded = constraints.maxWidth > 110;
                if (useExpanded) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: primary.withValues(alpha: 0.12),
                              child: Text(
                                _currentUser.username.isNotEmpty
                                    ? _currentUser.username[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentUser.username,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _currentUser.isAdmin()
                                        ? AppLocalizations.of(context)!
                                            .dashboardRoleAdmin
                                        : AppLocalizations.of(context)!
                                            .dashboardRoleUser,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              message: AppLocalizations.of(context)!
                                  .dashboardSupportTooltip,
                              child: InkWell(
                                onTap: () => launchUrl(
                                    Uri.parse(AppConfig.supportForm),
                                    mode: LaunchMode.externalApplication),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.support_agent_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      size: 18),
                                ),
                              ),
                            ),
                            Tooltip(
                              message: AppLocalizations.of(context)!
                                  .dashboardLogoutTooltip,
                              child: InkWell(
                                onTap: () => _logoutAndResetSession(),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.logout_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            cfg.version,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (TestBuildConfig.isTestBuild) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .dashboardTestBuildBadge,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Tooltip(
                          message: _currentUser.username,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: primary.withValues(alpha: 0.12),
                            child: Text(
                              _currentUser.username.isNotEmpty
                                  ? _currentUser.username[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Tooltip(
                          message: AppLocalizations.of(context)!
                              .dashboardSupportTooltip,
                          child: InkWell(
                            onTap: () => launchUrl(
                                Uri.parse(AppConfig.supportForm),
                                mode: LaunchMode.externalApplication),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.support_agent_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  size: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Tooltip(
                          message: AppLocalizations.of(context)!
                              .dashboardLogoutTooltip,
                          child: InkWell(
                            onTap: () => _logoutAndResetSession(),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.logout_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  size: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          cfg.version,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.outlineVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (TestBuildConfig.isTestBuild) ...[
                        const SizedBox(height: 3),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .dashboardTestBadgeShort,
                              style: TextStyle(
                                fontSize: 7,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ), // ClipRect
    );
  }

  /*
  Widget _buildComingSoonNavItem(IconData icon, String label) {
    const disabledColor = Color(0xFFCBD5E1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useExpanded = constraints.maxWidth > 110;

        if (!useExpanded) {
          return Tooltip(
            message: '$label — Coming Soon',
            preferBelow: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: disabledColor, size: 20),
              ),
            ),
          );
        }

        return Tooltip(
          message: 'Coming Soon',
          preferBelow: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icon, color: disabledColor, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: disabledColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: const Text(
                      'Soon',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: disabledColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  */

  Widget _buildNavItem(
      int index, IconData outlinedIcon, IconData filledIcon, String label,
      {bool showDot = false}) {
    final selected = _selectedIndex == index;
    final primary = Theme.of(context).primaryColor;

    Future<void> onTap() => _selectTab(index);

    // Use LayoutBuilder so the layout switches based on actual rendered width,
    // not just state — prevents overflow errors during the AnimatedContainer transition.
    return LayoutBuilder(
      builder: (context, constraints) {
        final useExpanded = constraints.maxWidth > 110;

        if (!useExpanded) {
          return Tooltip(
            message: label,
            preferBelow: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: primary.withValues(alpha: 0.06),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          selected ? filledIcon : outlinedIcon,
                          color: selected
                              ? primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        if (showDot)
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
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              hoverColor: primary.withValues(alpha: 0.06),
              splashColor: primary.withValues(alpha: 0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          selected ? filledIcon : outlinedIcon,
                          color: selected
                              ? primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        if (showDot)
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardHome extends ConsumerStatefulWidget {
  final Function(Invoice) onEditInvoice;
  final Function(Invoice, String) onCloneInvoice;
  final User user;
  const DashboardHome({
    required this.onEditInvoice,
    required this.onCloneInvoice,
    required this.user,
    super.key,
  });

  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  final dbHelper = DatabaseHelper();
  int totalCustomers = 0;
  int totalProducts = 0;
  int totalInvoices = 0;
  double totalRevenue = 0.0;
  double totalOutstanding = 0.0;
  List<Invoice> recentInvoices = [];
  List<Invoice> dueSoonInvoices = [];
  List<Product> outOfStockProducts = [];
  List<Invoice> overdueInvoices = [];
  String _currencySymbol = '₹';
  bool isLoading = true;
  String _dashboardLayout = 'default';
  bool _showLayoutBanner = false;
  bool _showThemeBanner = false;
  bool _showShortcutsBanner = false;
  bool _showSupportBanner = false;
  String _supportMilestone = '';
  List<Map<String, dynamic>> _monthlyRevenue = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final results = await Future.wait([
      ref.read(customerRepositoryProvider).getTotalCustomerCount(), // 0
      ref.read(productRepositoryProvider).getTotalProductCount(), // 1
      ref.read(invoiceRepositoryProvider).getDashboardFinancials(), // 2
      ref.read(invoiceRepositoryProvider).getRecentInvoices(limit: 5), // 3
      ref.read(invoiceRepositoryProvider).getDueSoonInvoices(), // 4
      ref.read(invoiceRepositoryProvider).getOverdueInvoices(limit: 10), // 5
      ref.read(settingsRepositoryProvider).getCurrency(), // 6
      ref.read(invoiceRepositoryProvider).getMonthlyRevenue(), // 7
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.dashboardLayout), // 8
      ref.read(invoiceRepositoryProvider).getTopCustomers(), // 9
      ref.read(invoiceRepositoryProvider).getTopProducts(), // 10
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.layoutBannerDismissed), // 11
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.supportBannerDismissed), // 12
      ref.read(productRepositoryProvider).getOutOfStockProducts(), // 13
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.themeBannerDismissed), // 14
      ref
          .read(settingsRepositoryProvider)
          .getSetting(SettingKey.shortcutsBannerDismissed), // 15
    ]);

    final customerCount = results[0] as int;
    final productCount = results[1] as int;
    final financials =
        results[2] as ({int count, double revenue, double outstanding});
    final recent = results[3] as List<Invoice>;
    final dueSoon = results[4] as List<Invoice>;
    final overdue = results[5] as List<Invoice>;
    final currency = results[6] as CurrencyOption;
    final monthly = results[7] as List<Map<String, dynamic>>;
    final layout = results[8] as String?;
    final topCust = results[9] as List<Map<String, dynamic>>;
    final topProd = results[10] as List<Map<String, dynamic>>;
    final bannerDismissed = results[11] as String?;
    final supportDismissed = results[12] as String?;
    final outOfStock = results[13] as List<Product>;
    final themeBannerDismissed = results[14] as String?;
    final shortcutsBannerDismissed =
        Platform.isAndroid ? '1' : results[15] as String?;
    final String milestone = financials.count >= 100
        ? '100'
        : financials.count >= 50
            ? '50'
            : financials.count > 10
                ? '10'
                : '';
    if (!mounted) return;
    setState(() {
      totalCustomers = customerCount;
      totalProducts = productCount;
      outOfStockProducts = outOfStock;
      totalInvoices = financials.count;
      totalRevenue = financials.revenue;
      totalOutstanding = financials.outstanding;
      recentInvoices = recent;
      dueSoonInvoices = dueSoon;
      overdueInvoices = overdue;
      _currencySymbol = currency.symbol;
      _monthlyRevenue = monthly;
      _dashboardLayout = layout ?? 'default';
      _topCustomers = topCust;
      _topProducts = topProd;
      _showLayoutBanner = bannerDismissed != '1';
      _showThemeBanner = themeBannerDismissed != '1';
      _showShortcutsBanner = shortcutsBannerDismissed != '1';
      _supportMilestone = milestone;
      _showSupportBanner =
          milestone.isNotEmpty && supportDismissed != milestone;
      isLoading = false;
    });
  }

  Future<void> _dismissSupportBanner() async {
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.supportBannerDismissed, _supportMilestone);
    if (mounted) setState(() => _showSupportBanner = false);
  }

  Future<void> _dismissLayoutBanner() async {
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.layoutBannerDismissed, '1');
    if (mounted) setState(() => _showLayoutBanner = false);
  }

  Future<void> _dismissThemeBanner() async {
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.themeBannerDismissed, '1');
    if (mounted) setState(() => _showThemeBanner = false);
  }

  Future<void> _dismissShortcutsBanner() async {
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.shortcutsBannerDismissed, '1');
    if (mounted) setState(() => _showShortcutsBanner = false);
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.keyboard_outlined),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.dashboardKeyboardShortcutsTitle),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppShortcuts.all(context)
                .map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                            ),
                            child: Text(s.$1,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s.$2,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.actionClose),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsDiscoveryBanner() {
    return DiscoveryBanner(
      visible: _showShortcutsBanner,
      icon: Icons.keyboard_outlined,
      iconColor: const Color(0xFF059669),
      backgroundColor: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFA7F3D0),
      title: Text(
        AppLocalizations.of(context)!.dashboardShortcutsBannerTitle,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF065F46)),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.dashboardShortcutsBannerSubtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF059669)),
      ),
      actionLabel: AppLocalizations.of(context)!.dashboardViewAllAction,
      onAction: _showShortcutsDialog,
      actionColor: const Color(0xFF059669),
      onDismiss: _dismissShortcutsBanner,
      dismissIconColor: const Color(0xFF6EE7B7),
    );
  }

  Widget _buildLayoutDiscoveryBanner() {
    return DiscoveryBanner(
      visible: _showLayoutBanner,
      icon: Icons.dashboard_customize_outlined,
      iconColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
      title: Text(
        AppLocalizations.of(context)!.dashboardLayoutBannerTitle,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1E40AF)),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.dashboardLayoutBannerSubtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
      ),
      actionLabel: AppLocalizations.of(context)!.actionGotIt,
      onAction: _dismissLayoutBanner,
      actionColor: const Color(0xFF2563EB),
      onDismiss: _dismissLayoutBanner,
      dismissIconColor: const Color(0xFF93C5FD),
    );
  }

  Widget _buildThemeDiscoveryBanner() {
    return DiscoveryBanner(
      visible: _showThemeBanner,
      icon: Icons.dark_mode_outlined,
      iconColor: const Color(0xFF7C3AED),
      backgroundColor: const Color(0xFFF5F3FF),
      borderColor: const Color(0xFFDDD6FE),
      title: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.dashboardThemeBannerTitle,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF5B21B6)),
          ),
          const SizedBox(width: 6),
          const _BetaTag(),
        ],
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.dashboardThemeBannerSubtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
      ),
      actionLabel: AppLocalizations.of(context)!.actionGotIt,
      onAction: _dismissThemeBanner,
      actionColor: const Color(0xFF7C3AED),
      onDismiss: _dismissThemeBanner,
      dismissIconColor: const Color(0xFFC4B5FD),
    );
  }

  Widget _buildSupportBanner() {
    final bool isReviewMilestone = _supportMilestone == '10';
    return DiscoveryBanner(
      visible: _showSupportBanner,
      margin: const EdgeInsets.only(bottom: 16),
      crossAxisAlignment: CrossAxisAlignment.start,
      icon: isReviewMilestone ? Icons.star_outline : Icons.celebration_outlined,
      iconSize: 22,
      iconColor: const Color(0xFFD97706),
      backgroundColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      title: Text(
        AppLocalizations.of(context)!
            .dashboardSupportBannerTitle(_supportMilestone),
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF92400E)),
      ),
      subtitle: Text(
        isReviewMilestone
            ? AppLocalizations.of(context)!.dashboardSupportBannerReviewSubtitle
            : AppLocalizations.of(context)!
                .dashboardSupportBannerSupportSubtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
      ),
      actionLabel: isReviewMilestone
          ? AppLocalizations.of(context)!.dashboardReviewAction
          : AppLocalizations.of(context)!.dashboardSupportAction,
      onAction: () async {
        final uri = Uri.parse(isReviewMilestone
            ? 'https://invoiso.co.in/review.html'
            : 'https://buymeacoffee.com/anoopp');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      actionColor: const Color(0xFF92400E),
      actionBackgroundColor: const Color(0xFFFDE68A),
      onDismiss: _dismissSupportBanner,
      dismissIconColor: const Color(0xFFD97706),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboardOverviewTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          _buildLayoutToggle(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: AppLocalizations.of(context)!.actionRefresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_dashboardLayout) {
      case 'classic':
        return _buildClassicLayout();
      case 'simple':
        return _buildSimpleFeedLayout();
      case 'bento':
        return _buildBentoLayout();
      default:
        return _buildDefaultLayout();
    }
  }

  Widget _buildDefaultLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLayoutDiscoveryBanner(),
              _buildThemeDiscoveryBanner(),
              _buildShortcutsDiscoveryBanner(),
              _buildSupportBanner(),
              // ── Greeting Banner ──────────────────────────────
              _buildGreetingBanner(),

              const SizedBox(height: 28),

              // ── Stats Row ────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatCard(
                        AppLocalizations.of(context)!.navCustomers,
                        totalCustomers.toString(),
                        const Color(0xFF1565C0),
                        Icons.people_outline),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      AppLocalizations.of(context)!.navProducts,
                      totalProducts.toString(),
                      const Color(0xFF2E7D32),
                      Icons.inventory_2_outlined,
                      subtitle: outOfStockProducts.isNotEmpty
                          ? AppLocalizations.of(context)!
                              .dashboardOutOfStockCountLabel(
                                  outOfStockProducts.length)
                          : null,
                      subtitleColor: Colors.red[600],
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                        AppLocalizations.of(context)!.navInvoices,
                        totalInvoices.toString(),
                        const Color(0xFFE65100),
                        Icons.receipt_long_outlined),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      AppLocalizations.of(context)!
                          .dashboardRevenueCollectedLabel,
                      '$_currencySymbol ${totalRevenue.toStringAsFixed(2)}',
                      const Color(0xFF6A1B9A),
                      Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      AppLocalizations.of(context)!.dashboardOutstandingLabel,
                      '$_currencySymbol ${totalOutstanding.toStringAsFixed(2)}',
                      const Color(0xFFC62828),
                      Icons.hourglass_top_outlined,
                      subtitle: overdueInvoices.isNotEmpty
                          ? AppLocalizations.of(context)!
                              .dashboardOverdueCountLabel(
                                  overdueInvoices.length)
                          : null,
                      subtitleColor: Colors.red[700],
                    ),
                  ],
                ),
              ),

              // ── Due Soon ─────────────────────────────────────
              if (dueSoonInvoices.isNotEmpty) ...[
                const SizedBox(height: 36),
                _buildDueSoonSection(),
              ],

              // ── Out of Stock ──────────────────────────────────
              if (outOfStockProducts.isNotEmpty) ...[
                const SizedBox(height: 36),
                _buildOutOfStockSection(),
              ],

              // ── Overdue Invoices ──────────────────────────────
              if (overdueInvoices.isNotEmpty) ...[
                const SizedBox(height: 36),
                _buildOverdueSection(),
              ],

              const SizedBox(height: 36),

              // ── Recent Invoices Header ────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    AppLocalizations.of(context)!.dashboardRecentInvoicesTitle,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3),
                  ),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context)!
                        .dashboardLastFiveInvoicesLabel,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              recentInvoices.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!
                                  .dashboardNoInvoicesYetTitle,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!
                                  .dashboardNoInvoicesYetSubtitle,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = recentInvoices[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.xsmall),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  if (invoice.dueDate == null)
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(context).primaryColor,
                                            Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.xsmall),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (invoice.dueDate != null)
                                    () {
                                      final isOverdue =
                                          InvoiceCalculator.isOverdue(
                                        dueDate: invoice.dueDate,
                                        outstanding: invoice.outstandingBalance,
                                      );
                                      return Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          gradient: isOverdue
                                              ? DashboardScreenColors
                                                  .invoiceNumberOverDueLinearGradient
                                              : LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Theme.of(context)
                                                        .primaryColor,
                                                    Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.7),
                                                  ],
                                                ),
                                          borderRadius: BorderRadius.circular(
                                              AppBorderRadius.xsmall),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }(),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              '${invoice.type} #${invoice.invoiceNumber ?? invoice.id}',
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: invoice.type == 'Invoice'
                                                    ? Colors.indigo
                                                        .withValues(alpha: 0.1)
                                                    : Colors.orange
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color:
                                                      invoice.type == 'Invoice'
                                                          ? Colors.indigo
                                                              .withValues(
                                                                  alpha: 0.35)
                                                          : Colors.orange
                                                              .withValues(
                                                                  alpha: 0.35),
                                                ),
                                              ),
                                              child: Text(
                                                _invoiceTypeLabel(
                                                    context, invoice.type),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      invoice.type == 'Invoice'
                                                          ? Colors.indigo[700]
                                                          : Colors.orange[800],
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            if (invoice.type == 'Invoice')
                                              _buildPaymentStatusChip(
                                                  invoice.paymentStatus),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.person_outline,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                    child: Text(
                                                  invoice.customer.name
                                                      .limit(15),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                                )),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                    child: Text(
                                                  invoice.date
                                                      .toString()
                                                      .split(' ')[0],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface),
                                                )),
                                              ],
                                            ),
                                            if (invoice.dueDate != null)
                                              () {
                                                final isOverdue =
                                                    InvoiceCalculator.isOverdue(
                                                  dueDate: invoice.dueDate,
                                                  outstanding: invoice
                                                      .outstandingBalance,
                                                );
                                                final color = isOverdue
                                                    ? Colors.red[700]!
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant;
                                                return ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 260),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.event_outlined,
                                                          size: 16,
                                                          color: color),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .dashboardDueDateLabel(
                                                                  AppFormatters
                                                                      .formatShortDate(
                                                                          invoice
                                                                              .dueDate)),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            color: color,
                                                            fontWeight:
                                                                isOverdue
                                                                    ? FontWeight
                                                                        .w600
                                                                    : FontWeight
                                                                        .normal,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.purple
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${invoice.currencySymbol} ${invoice.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        alignment: WrapAlignment.end,
                                        children: [
                                          _buildActionButton(
                                              Icons.visibility_outlined,
                                              Colors.green,
                                              AppLocalizations.of(context)!
                                                  .actionView,
                                              () => InvoicePdfServices
                                                  .showInvoiceDetails(
                                                      context, invoice)),
                                          _buildActionButton(
                                              Icons.edit_outlined,
                                              Colors.blue,
                                              AppLocalizations.of(context)!
                                                  .actionEdit,
                                              () => widget
                                                  .onEditInvoice(invoice)),
                                          _buildActionButton(
                                              Icons.copy_all_outlined,
                                              Colors.teal,
                                              AppLocalizations.of(context)!
                                                  .actionDuplicate,
                                              () => _showCloneDialog(invoice)),
                                          _buildActionButton(
                                              Icons.picture_as_pdf_outlined,
                                              Colors.orange,
                                              AppLocalizations.of(context)!
                                                  .actionPdfPreview,
                                              () =>
                                                  InvoicePdfServices.previewPDF(
                                                      context, invoice)),
                                          _buildActionButton(
                                              Icons.download_outlined,
                                              Colors.deepPurple,
                                              AppLocalizations.of(context)!
                                                  .actionDownloadPdf,
                                              () => PDFService.downloadPDF(
                                                  context, invoice)),
                                          _buildActionButton(
                                              Icons.print_outlined,
                                              Colors.blueGrey,
                                              AppLocalizations.of(context)!
                                                  .actionPrint,
                                              () => InvoicePdfServices
                                                  .generatePDF(
                                                      context, invoice)),
                                          _buildActionButton(
                                              Icons.payments_outlined,
                                              Colors.purple,
                                              AppLocalizations.of(context)!
                                                  .actionPayment,
                                              invoice.type == 'Invoice'
                                                  ? () => showDialog(
                                                        context: context,
                                                        barrierDismissible:
                                                            false,
                                                        builder: (_) =>
                                                            ApplyPaymentDialog(
                                                          invoice: invoice,
                                                          onPaymentRecorded:
                                                              () {
                                                            if (!mounted)
                                                              return;
                                                            setState(() {});
                                                          },
                                                        ),
                                                      )
                                                  : null),
                                          _buildActionButton(
                                              Icons.delete_outline,
                                              Colors.red,
                                              AppLocalizations.of(context)!
                                                  .actionDelete,
                                              widget.user.isAdmin()
                                                  ? () =>
                                                      _showDeleteDialog(invoice)
                                                  : null),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        gradient: DashboardScreenColors.welcomePanelBackgroundGradientColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!
                    .dashboardWelcomeBackMessage(widget.user.username),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.dashboardBusinessGlanceSubtitle,
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('EEEE').format(DateTime.now()),
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, yyyy').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDueSoonSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.notifications_active_outlined,
                color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.dashboardDueSoonTitle,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Text(
                AppLocalizations.of(context)!
                    .dashboardInvoiceCountLabel(dueSoonInvoices.length),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800]),
              ),
            ),
            const Spacer(),
            Text(
              AppLocalizations.of(context)!.dashboardTodayTomorrowLabel,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Cards
        ...dueSoonInvoices.map((invoice) {
          final due = DateTime(invoice.dueDate!.year, invoice.dueDate!.month,
              invoice.dueDate!.day);
          final isToday = due == today;
          final badgeColor = isToday ? Colors.red : Colors.orange;
          final badgeLabel = isToday
              ? AppLocalizations.of(context)!.dashboardDueTodayBadge
              : AppLocalizations.of(context)!.dashboardDueTomorrowBadge;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                side: BorderSide(
                    color: badgeColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Due badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: badgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: badgeColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Invoice ID
                    Text(
                      '#${invoice.invoiceNumber ?? invoice.id}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    // Customer
                    Icon(Icons.person_outline,
                        size: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              invoice.customer.name,
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CustomerInfoButton(customer: invoice.customer),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Outstanding amount
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_currencySymbol ${invoice.outstandingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: badgeColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Actions
                    _buildActionButton(
                        Icons.visibility_outlined,
                        Colors.green,
                        AppLocalizations.of(context)!.actionView,
                        () => InvoicePdfServices.showInvoiceDetails(
                            context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                        Icons.picture_as_pdf_outlined,
                        Colors.orange,
                        AppLocalizations.of(context)!.actionPdfPreview,
                        () => InvoicePdfServices.previewPDF(context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                        Icons.payments_outlined,
                        Colors.purple,
                        AppLocalizations.of(context)!.actionRecordPayment,
                        () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => ApplyPaymentDialog(
                                invoice: invoice,
                                onPaymentRecorded: _loadDashboardData,
                              ),
                            )),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOverdueSection() {
    final today = InvoiceCalculator.dateOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 22),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.dashboardOverdueSectionTitle,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Text(
                AppLocalizations.of(context)!
                    .dashboardInvoiceCountLabel(overdueInvoices.length),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[800]),
              ),
            ),
            const Spacer(),
            Text(
              AppLocalizations.of(context)!.dashboardOldestFirstLabel,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...overdueInvoices.map((invoice) {
          final daysOverdue = InvoiceCalculator.daysOverdue(
            dueDate: invoice.dueDate,
            asOf: today,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                side: BorderSide(
                    color: Colors.red.withValues(alpha: 0.3), width: 1),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Days overdue badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!
                            .dashboardDaysOverdueLabel(daysOverdue),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[800]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Invoice ID
                    Text(
                      '#${invoice.invoiceNumber ?? invoice.id}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    // Customer
                    Icon(Icons.person_outline,
                        size: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              invoice.customer.name,
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CustomerInfoButton(customer: invoice.customer),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Outstanding amount
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_currencySymbol ${invoice.outstandingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Actions
                    _buildActionButton(
                        Icons.visibility_outlined,
                        Colors.green,
                        AppLocalizations.of(context)!.actionView,
                        () => InvoicePdfServices.showInvoiceDetails(
                            context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                        Icons.picture_as_pdf_outlined,
                        Colors.orange,
                        AppLocalizations.of(context)!.actionPdfPreview,
                        () => InvoicePdfServices.previewPDF(context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      Icons.payments_outlined,
                      Colors.purple,
                      AppLocalizations.of(context)!.actionRecordPayment,
                      () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => ApplyPaymentDialog(
                          invoice: invoice,
                          onPaymentRecorded: _loadDashboardData,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showUpdateStockDialog(Product product) async {
    final controller = TextEditingController(text: product.stock.toString());
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.red[600], size: 20),
            const SizedBox(width: 8),
            Flexible(
                child: Text(product.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.dashboardNewStockQuantityLabel,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.add_box_outlined),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionCancel)),
          FilledButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text.trim());
              if (qty == null || qty < 0) return;
              await ref
                  .read(productRepositoryProvider)
                  .updateProductStock(product.id, qty);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadDashboardData();
            },
            child: Text(l10n.actionUpdate),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Widget _buildOutOfStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.inventory_2, color: Colors.red[600], size: 22),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.dashboardOutOfStockSectionTitle,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Text(
                AppLocalizations.of(context)!
                    .dashboardItemCountLabel(outOfStockProducts.length),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700]),
              ),
            ),
            const Spacer(),
            Text(
              AppLocalizations.of(context)!.dashboardTapToRestockLabel,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...outOfStockProducts.map((product) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3), width: 1),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2,
                            color: Colors.red[600], size: 20),
                      ),
                      const SizedBox(width: 16),
                      // Name & type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              product.type == 'service'
                                  ? AppLocalizations.of(context)!.labelService
                                  : AppLocalizations.of(context)!.labelProduct,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Price
                      Text(
                        '$_currencySymbol${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(width: 16),
                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .dashboardStockLabel(product.stock),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[700]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Update stock button
                      _buildActionButton(
                        Icons.add_box_outlined,
                        Colors.green,
                        AppLocalizations.of(context)!.actionUpdateStock,
                        () => _showUpdateStockDialog(product),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon,
      {String? subtitle, Color? subtitleColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (subtitle?.isNotEmpty ?? false) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.warning_amber_rounded,
                            size: 11, color: subtitleColor ?? Colors.red),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10,
                                color: subtitleColor ?? Colors.red,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, String tooltip, VoidCallback? onPressed) {
    final effectiveColor = onPressed != null
        ? color
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: effectiveColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final Color color;
    final String label;
    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        label = l10n.paymentStatusPaid;
      case PaymentStatus.partial:
        color = Colors.orange;
        label = l10n.paymentStatusPartial;
      case PaymentStatus.unpaid:
        color = Colors.red;
        label = l10n.paymentStatusUnpaid;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Future<void> _showCloneDialog(Invoice invoice) async {
    final l10n = AppLocalizations.of(context)!;
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.copy_all, color: Colors.teal),
            const SizedBox(width: 12),
            Text(l10n.dashboardDuplicateInvoiceTitle),
          ],
        ),
        content: Text(
          l10n.dashboardDuplicateInvoiceBody(
              invoice.invoiceNumber ?? invoice.id, invoice.customer.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Quotation'),
            icon: const Icon(Icons.request_quote_outlined),
            label: Text(l10n.labelQuotation),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.receipt),
            label: Text(l10n.labelInvoice),
          ),
        ],
      ),
    );
    if (type != null) {
      widget.onCloneInvoice(invoice, type);
    }
  }

  void _showDeleteDialog(Invoice invoice) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(l10n.dashboardDeleteInvoiceTitle),
          ],
        ),
        content: Text(
          l10n.dashboardDeleteInvoiceBody(invoice.invoiceNumber ?? invoice.id),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              InvoicePdfServices.deleteInvoice(context, invoice);
              _loadDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
  }

  // ── Layout Toggle ───────────────────────────────────────────────────────────

  Widget _buildLayoutToggle() {
    return PopupMenuButton<String>(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.dashboard_customize_outlined, size: 20),
          if (_showLayoutBanner)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      tooltip: AppLocalizations.of(context)!.dashboardLayoutTooltip,
      offset: const Offset(0, 40),
      onSelected: (value) async {
        if (!mounted) return;
        await ref
            .read(settingsRepositoryProvider)
            .setSetting(SettingKey.dashboardLayout, value);
        setState(() => _dashboardLayout = value);
        if (_showLayoutBanner) _dismissLayoutBanner();
      },
      itemBuilder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return [
          _layoutMenuItem(
              'default',
              Icons.view_agenda_outlined,
              l10n.dashboardLayoutDefaultTitle,
              l10n.dashboardLayoutDefaultSubtitle),
          _layoutMenuItem('classic', Icons.grid_view_outlined,
              l10n.dashboardLayoutClassic, l10n.dashboardLayoutClassicSubtitle),
          _layoutMenuItem(
              'bento',
              Icons.auto_awesome_mosaic_outlined,
              l10n.dashboardLayoutBentoTitle,
              l10n.dashboardLayoutBentoSubtitle),
          _layoutMenuItem(
              'simple',
              Icons.view_list_outlined,
              l10n.dashboardLayoutSimpleTitle,
              l10n.dashboardLayoutSimpleSubtitle),
        ];
      },
    );
  }

  PopupMenuItem<String> _layoutMenuItem(
      String value, IconData icon, String title, String sub) {
    final active = _dashboardLayout == value;
    final primary = Theme.of(context).primaryColor;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: active
                  ? primary
                  : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.normal,
                        color: active
                            ? primary
                            : Theme.of(context).colorScheme.onSurface)),
                Text(sub,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (active) Icon(Icons.check_rounded, size: 16, color: primary),
        ],
      ),
    );
  }

  // ── Layout: Classic ─────────────────────────────────────────────────────────

  Widget _buildClassicLayout() {
    final primary = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLayoutDiscoveryBanner(),
              _buildThemeDiscoveryBanner(),
              _buildShortcutsDiscoveryBanner(),
              _buildSupportBanner(),
              _buildGreetingBanner(),
              const SizedBox(height: 20),
              // KPI row
              Row(
                children: [
                  _buildKpiCard(
                      AppLocalizations.of(context)!
                          .dashboardRevenueCollectedLabel,
                      '$_currencySymbol ${_fmtAmt(totalRevenue)}',
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF6A1B9A)),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                      AppLocalizations.of(context)!.dashboardOutstandingLabel,
                      '$_currencySymbol ${_fmtAmt(totalOutstanding)}',
                      Icons.hourglass_top_outlined,
                      const Color(0xFFC62828)),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                      AppLocalizations.of(context)!.dashboardTotalInvoicesLabel,
                      totalInvoices.toString(),
                      Icons.receipt_long_outlined,
                      const Color(0xFFE65100)),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                      AppLocalizations.of(context)!.navCustomers,
                      totalCustomers.toString(),
                      Icons.people_outline,
                      const Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                      AppLocalizations.of(context)!.navProducts,
                      totalProducts.toString(),
                      Icons.inventory_2_outlined,
                      const Color(0xFF2E7D32)),
                ],
              ),
              const SizedBox(height: 20),
              // Charts row
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: _buildRevenueBarChart(primary)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildRevenueDonut()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Bottom row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 3, child: _buildCompactRecentInvoices(limit: 7)),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        if (dueSoonInvoices.isNotEmpty) ...[
                          _buildDueSoonCard(),
                          const SizedBox(height: 14),
                        ],
                        if (overdueInvoices.isNotEmpty) ...[
                          _buildOverdueCompactCard(),
                          const SizedBox(height: 14),
                        ],
                        if (outOfStockProducts.isNotEmpty) ...[
                          _buildOutOfStockCard(),
                          const SizedBox(height: 14),
                        ],
                        _buildQuickActionsCard(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Layout: Simple Feed ─────────────────────────────────────────────────────

  Widget _buildSimpleFeedLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLayoutDiscoveryBanner(),
              _buildThemeDiscoveryBanner(),
              _buildShortcutsDiscoveryBanner(),
              _buildSupportBanner(),
              _buildGreetingBanner(),
              const SizedBox(height: 20),
              // Mini KPI strip
              Row(
                children: [
                  _buildKpiCard(
                      AppLocalizations.of(context)!
                          .dashboardRevenueCollectedLabel,
                      '$_currencySymbol ${_fmtAmt(totalRevenue)}',
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF6A1B9A)),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                      AppLocalizations.of(context)!.dashboardOutstandingLabel,
                      '$_currencySymbol ${_fmtAmt(totalOutstanding)}',
                      Icons.hourglass_top_outlined,
                      const Color(0xFFC62828)),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                      AppLocalizations.of(context)!.navInvoices,
                      totalInvoices.toString(),
                      Icons.receipt_long_outlined,
                      const Color(0xFFE65100)),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                      AppLocalizations.of(context)!.navCustomers,
                      totalCustomers.toString(),
                      Icons.people_outline,
                      const Color(0xFF1565C0)),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    AppLocalizations.of(context)!.navProducts,
                    totalProducts.toString(),
                    Icons.inventory_2_outlined,
                    const Color(0xFF2E7D32),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Two-column body
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: recent invoices + top customers + top products
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildCompactRecentInvoices(limit: 10),
                        if (_topCustomers.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildTopCustomersCard(),
                        ],
                        if (_topProducts.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildTopProductsCard(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right sidebar
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildQuickActionsCard(),
                        const SizedBox(height: 14),
                        if (overdueInvoices.isNotEmpty) ...[
                          _buildOverdueCompactCard(),
                          const SizedBox(height: 14),
                        ],
                        if (dueSoonInvoices.isNotEmpty) ...[
                          _buildDueSoonCard(),
                          const SizedBox(height: 14),
                        ],
                        if (outOfStockProducts.isNotEmpty)
                          _buildOutOfStockCard(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared: KPI Card ────────────────────────────────────────────────────────

  Widget _buildKpiCard(String title, String value, IconData icon, Color color,
      {bool alert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: alert
              ? Border.all(color: color.withValues(alpha: 0.35), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared: Revenue Bar Chart ────────────────────────────────────────────────

  Widget _buildRevenueBarChart(Color primary) {
    final hasData = _monthlyRevenue.isNotEmpty;
    final maxY = hasData
        ? _monthlyRevenue
                .map((e) => (e['revenue'] as num).toDouble())
                .reduce((a, b) => a > b ? a : b) *
            1.25
        : 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.dashboardRevenueLast6MonthsTitle,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: hasData
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barGroups: _monthlyRevenue.asMap().entries.map((entry) {
                        final rev = (entry.value['revenue'] as num).toDouble();
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: rev,
                              gradient: LinearGradient(
                                colors: [
                                  primary,
                                  primary.withValues(alpha: 0.55)
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _monthlyRevenue.length) {
                                return const SizedBox.shrink();
                              }
                              final monthStr =
                                  _monthlyRevenue[idx]['month'] as String;
                              try {
                                final date =
                                    DateFormat('yyyy-MM').parse(monthStr);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(DateFormat('MMM').format(date),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                );
                              } catch (_) {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.grey.withValues(alpha: 0.12),
                            strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            '$_currencySymbol ${_fmtAmt(rod.toY)}',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_outlined,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.outlineVariant),
                        const SizedBox(height: 8),
                        Text(
                            AppLocalizations.of(context)!
                                .dashboardNoPaymentDataYetLabel,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 13)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Shared: Revenue Donut ────────────────────────────────────────────────────

  Widget _buildRevenueDonut() {
    final total = totalRevenue + totalOutstanding;
    final hasData = total > 0.01;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.dashboardFinancialOverviewTitle,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: hasData
                ? PieChart(
                    PieChartData(
                      centerSpaceRadius: 46,
                      sectionsSpace: 3,
                      sections: [
                        PieChartSectionData(
                          value: totalRevenue,
                          color: const Color(0xFF2E7D32),
                          title: '',
                          radius: 38,
                        ),
                        PieChartSectionData(
                          value: totalOutstanding,
                          color: const Color(0xFFC62828),
                          title: '',
                          radius: 38,
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                        AppLocalizations.of(context)!
                            .dashboardNoInvoicesYetTitle,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13))),
          ),
          const SizedBox(height: 14),
          _buildDonutLegend(
              AppLocalizations.of(context)!.dashboardCollectedLabel,
              const Color(0xFF2E7D32),
              '$_currencySymbol ${_fmtAmt(totalRevenue)}'),
          const SizedBox(height: 6),
          _buildDonutLegend(
              AppLocalizations.of(context)!.dashboardOutstandingLabel,
              const Color(0xFFC62828),
              '$_currencySymbol ${_fmtAmt(totalOutstanding)}'),
          if (overdueInvoices.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 13, color: Color(0xFFB71C1C)),
                  const SizedBox(width: 6),
                  Text(
                      AppLocalizations.of(context)!
                          .dashboardInvoiceCountOverdueLabel(
                              overdueInvoices.length),
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonutLegend(String label, Color color, String amount) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Text(amount,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  // ── Shared: Compact Recent Invoices ─────────────────────────────────────────

  Widget _buildCompactRecentInvoices({int limit = 7}) {
    final invoices = recentInvoices.take(limit).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(AppLocalizations.of(context)!.dashboardRecentInvoicesTitle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Text(AppLocalizations.of(context)!.dashboardLastNLabel(limit),
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(AppLocalizations.of(context)!.labelInvoice,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 3,
                    child: Text(AppLocalizations.of(context)!.labelCustomer,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 2,
                    child: Text(AppLocalizations.of(context)!.labelAmount,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600))),
                const SizedBox(width: 60),
              ],
            ),
          ),
          Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 4),
          if (invoices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Text(
                      AppLocalizations.of(context)!.dashboardNoInvoicesYetTitle,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13))),
            )
          else
            ...invoices.map(_buildCompactInvoiceRow),
        ],
      ),
    );
  }

  Widget _buildCompactInvoiceRow(Invoice inv) {
    final status = inv.paymentStatus;
    final Color statusColor;
    final String statusLabel;
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case PaymentStatus.paid:
        statusColor = const Color(0xFF2E7D32);
        statusLabel = l10n.paymentStatusPaid;
        break;
      case PaymentStatus.partial:
        statusColor = const Color(0xFFF57C00);
        statusLabel = l10n.paymentStatusPartial;
        break;
      default:
        final isOver = InvoiceCalculator.isOverdue(
            dueDate: inv.dueDate, outstanding: inv.outstandingBalance);
        statusColor =
            isOver ? const Color(0xFFC62828) : const Color(0xFF546E7A);
        statusLabel = isOver
            ? l10n.dashboardOverdueSectionTitle
            : l10n.paymentStatusUnpaid;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
                '#${inv.id.length > 8 ? inv.id.substring(inv.id.length - 8) : inv.id}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: Text(inv.customer.name,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text('$_currencySymbol ${_fmtAmt(inv.total)}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
                maxLines: 1),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Edit',
            child: InkWell(
              onTap: () => widget.onEditInvoice(inv),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'Download PDF',
            child: InkWell(
              onTap: () => PDFService.downloadPDF(context, inv),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.download_outlined,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared: Due Soon Card ────────────────────────────────────────────────────

  Widget _buildDueSoonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.event_outlined,
                    color: Color(0xFFF57C00), size: 15),
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.dashboardDueSoonTitle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${dueSoonInvoices.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF57C00),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...dueSoonInvoices.take(5).map((inv) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(inv.customer.name,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('$_currencySymbol ${_fmtAmt(inv.outstandingBalance)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    _buildInvoiceActionMenu(inv),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Shared: Out of Stock Card ────────────────────────────────────────────────

  Widget _buildOutOfStockCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Colors.red, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                  AppLocalizations.of(context)!.dashboardOutOfStockSectionTitle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${outOfStockProducts.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...outOfStockProducts.take(5).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(p.name,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text(AppLocalizations.of(context)!.dashboardZeroLeftLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: AppLocalizations.of(context)!.actionUpdateStock,
                      child: InkWell(
                        onTap: () => _showUpdateStockDialog(p),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_box_outlined,
                                  size: 13, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(AppLocalizations.of(context)!.labelStock,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Shared: Overdue Compact Card ─────────────────────────────────────────────

  Widget _buildOverdueCompactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFC62828).withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFC62828), size: 15),
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.dashboardOverdueSectionTitle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${overdueInvoices.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overdueInvoices.take(5).map((inv) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(inv.customer.name,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Text('$_currencySymbol ${_fmtAmt(inv.outstandingBalance)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC62828),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message:
                          AppLocalizations.of(context)!.actionRecordPayment,
                      child: InkWell(
                        onTap: () => showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => ApplyPaymentDialog(
                            invoice: inv,
                            onPaymentRecorded: _loadDashboardData,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payments_outlined,
                                  size: 13, color: Color(0xFF6A1B9A)),
                              const SizedBox(width: 4),
                              Text(AppLocalizations.of(context)!.actionPay,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6A1B9A),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    _buildPdfActionMenu(inv),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Shared: Quick Actions Card ───────────────────────────────────────────────

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.dashboardQuickActionsTitle,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          _buildQuickActionRow(
              Icons.add_circle_outline_rounded,
              AppLocalizations.of(context)!.navNewInvoice,
              Theme.of(context).primaryColor, () {
            if (!mounted) return;
            context
                .findAncestorStateOfType<_DashboardScreenState>()
                ?.setState(() {
              context
                  .findAncestorStateOfType<_DashboardScreenState>()
                  ?._selectedIndex = 1;
            });
          }),
          const SizedBox(height: 4),
          _buildQuickActionRow(
              Icons.person_add_outlined,
              AppLocalizations.of(context)!.navCustomers,
              const Color(0xFF1565C0), () {
            if (!mounted) return;
            context
                .findAncestorStateOfType<_DashboardScreenState>()
                ?.setState(() {
              context
                  .findAncestorStateOfType<_DashboardScreenState>()
                  ?._selectedIndex = 5;
            });
          }),
          const SizedBox(height: 4),
          _buildQuickActionRow(
              Icons.bar_chart_outlined,
              AppLocalizations.of(context)!.navReports,
              const Color(0xFF2E7D32), () {
            if (!mounted) return;
            context
                .findAncestorStateOfType<_DashboardScreenState>()
                ?.setState(() {
              context
                  .findAncestorStateOfType<_DashboardScreenState>()
                  ?._selectedIndex = 7;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  // ── Shared: Amount Formatter ─────────────────────────────────────────────────

  String _fmtAmt(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    }
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(2);
  }

  // ── Layout: Bento Grid ──────────────────────────────────────────────────────

  Widget _buildBentoLayout() {
    final primary = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLayoutDiscoveryBanner(),
              _buildThemeDiscoveryBanner(),
              _buildShortcutsDiscoveryBanner(),
              _buildSupportBanner(),
              _buildGreetingBanner(),
              const SizedBox(height: 20),
              // ── Top row: Hero chart + 2×2 KPI grid ──────────────────────────
              SizedBox(
                height: 290,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero: Revenue bar chart
                    Expanded(
                      flex: 3,
                      child: _buildRevenueBarChart(primary),
                    ),
                    const SizedBox(width: 14),
                    // 2×2 KPI tiles
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _buildKpiCard(
                                  AppLocalizations.of(context)!
                                      .dashboardRevenueCollectedLabel,
                                  '$_currencySymbol ${_fmtAmt(totalRevenue)}',
                                  Icons.account_balance_wallet_outlined,
                                  const Color(0xFF6A1B9A),
                                ),
                                const SizedBox(width: 14),
                                _buildKpiCard(
                                  AppLocalizations.of(context)!.navInvoices,
                                  totalInvoices.toString(),
                                  Icons.receipt_long_outlined,
                                  const Color(0xFFE65100),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                _buildKpiCard(
                                  AppLocalizations.of(context)!
                                      .dashboardOutstandingLabel,
                                  '$_currencySymbol ${_fmtAmt(totalOutstanding)}',
                                  Icons.hourglass_top_outlined,
                                  const Color(0xFFC62828),
                                ),
                                const SizedBox(width: 14),
                                _buildKpiCard(
                                  AppLocalizations.of(context)!
                                      .dashboardOverdueSectionTitle,
                                  overdueInvoices.length.toString(),
                                  Icons.warning_amber_outlined,
                                  const Color(0xFFB71C1C),
                                  alert: overdueInvoices.isNotEmpty,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                _buildKpiCard(
                                    AppLocalizations.of(context)!.navCustomers,
                                    totalCustomers.toString(),
                                    Icons.people_outline,
                                    const Color(0xFF1565C0)),
                                const SizedBox(width: 14),
                                _buildKpiCard(
                                  AppLocalizations.of(context)!.navProducts,
                                  totalProducts.toString(),
                                  Icons.inventory_2_outlined,
                                  const Color(0xFF2E7D32),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // ── Bottom row: Wide invoice table + narrow sidebar ───────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildCompactRecentInvoices(limit: 8),
                        if (_topProducts.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildTopProductsCard(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildQuickActionsCard(),
                        if (overdueInvoices.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildOverdueCompactCard(),
                        ],
                        if (dueSoonInvoices.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildDueSoonCard(),
                        ],
                        if (outOfStockProducts.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildOutOfStockCard(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared: PDF-Only Action Menu (⋯) ───────────────────────────────────────

  Widget _buildPdfActionMenu(Invoice inv) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
      iconSize: 22,
      padding: EdgeInsets.zero,
      tooltip: AppLocalizations.of(context)!.dashboardPdfActionsTooltip,
      offset: const Offset(0, 24),
      onSelected: (value) {
        if (value == 'preview') {
          InvoicePdfServices.previewPDF(context, inv);
        } else if (value == 'download') {
          PDFService.downloadPDF(context, inv);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'preview',
          child: Row(children: [
            const Icon(Icons.visibility_outlined,
                size: 16, color: Colors.green),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.actionPdfPreview,
                style: const TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'download',
          child: Row(children: [
            const Icon(Icons.download_outlined,
                size: 16, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.actionDownloadPdf,
                style: const TextStyle(fontSize: 13)),
          ]),
        ),
      ],
    );
  }

  // ── Shared: Invoice Action Menu (⋯) ────────────────────────────────────────

  Widget _buildInvoiceActionMenu(Invoice inv) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
      iconSize: 22,
      padding: EdgeInsets.zero,
      tooltip: AppLocalizations.of(context)!.dashboardActionsTooltip,
      offset: const Offset(0, 24),
      onSelected: (value) {
        switch (value) {
          case 'payment':
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => ApplyPaymentDialog(
                invoice: inv,
                onPaymentRecorded: _loadDashboardData,
              ),
            );
            break;
          case 'preview':
            InvoicePdfServices.previewPDF(context, inv);
            break;
          case 'download':
            PDFService.downloadPDF(context, inv);
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'payment',
          child: Row(children: [
            const Icon(Icons.payments_outlined,
                size: 16, color: Color(0xFF6A1B9A)),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.actionRecordPayment,
                style: const TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'preview',
          child: Row(children: [
            const Icon(Icons.visibility_outlined,
                size: 16, color: Colors.green),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.actionPdfPreview,
                style: const TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'download',
          child: Row(children: [
            const Icon(Icons.download_outlined,
                size: 16, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.actionDownloadPdf,
                style: const TextStyle(fontSize: 13)),
          ]),
        ),
      ],
    );
  }

  // ── Shared: Top Customers Card ───────────────────────────────────────────────

  Widget _buildTopCustomersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.emoji_events_outlined,
                    color: Color(0xFF1565C0), size: 15),
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.dashboardTopCustomersTitle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          ..._topCustomers.map((c) {
            final name = c['customer_name'] as String? ?? '';
            final paid = (c['total_paid'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor:
                        const Color(0xFF1565C0).withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(name,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Text('$_currencySymbol ${_fmtAmt(paid)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Shared: Top Products Card ────────────────────────────────────────────────

  Widget _buildTopProductsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.trending_up_outlined,
                    color: Color(0xFF2E7D32), size: 15),
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.dashboardTopProductsTitle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          ..._topProducts.map((p) {
            final name = p['product_name'] as String? ?? '';
            final qty = (p['total_qty'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.inventory_2_outlined,
                        size: 13, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(name,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Text(
                      AppLocalizations.of(context)!.dashboardUnitsLabel(
                          qty % 1 == 0
                              ? qty.toInt().toString()
                              : qty.toStringAsFixed(1)),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BetaTag extends StatelessWidget {
  const _BetaTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AppLocalizations.of(context)!.dashboardBetaBadge,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
