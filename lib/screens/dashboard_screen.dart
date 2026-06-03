import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/services/update_service.dart';
import 'package:invoiso/widgets/update_dialog.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/invoiso_colors.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/screens/settings_screen.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart';
import 'package:invoiso/widgets/customer_info_button.dart';
import 'package:invoiso/utils/session_manager.dart';

import '../models/user.dart';
import '../database/user_service.dart';
import 'customer_management_screen.dart';
import '../database/database_helper.dart';
import 'create_invoice_screen.dart';
import 'product_management_screen.dart';
import 'invoice_management_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  final User loggedInUser;

  const DashboardScreen(this.loggedInUser, {super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  late User _currentUser;

  Invoice? invoiceToEdit;
  Invoice? _invoiceToClone;
  String _cloneType = 'Invoice';
  bool _hasUpdate = false;
  final InvoiceFormGuard _invoiceFormGuard = InvoiceFormGuard();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.loggedInUser;
    SessionManager.initialize(_onSessionTimeout);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
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
    super.dispose();
  }

  void _onSessionTimeout() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired due to inactivity.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _refreshUser() async {
    final fresh = await UserService.getUserById(_currentUser.id);
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
        return CreateInvoiceScreen(
          key: ValueKey(
              'create_invoice_${invoiceToEdit?.id ?? 'new'}_${_invoiceToClone?.id ?? ''}'),
          invoiceToEdit: invoiceToEdit,
          cloneFrom: _invoiceToClone,
          cloneType: _invoiceToClone != null ? _cloneType : null,
          guard: _invoiceFormGuard,
          onCreateNewInvoice: () {
            setState(() {
              invoiceToEdit = null;
              _invoiceToClone = null;
            });
          },
        );
      case 2:
        return InvoiceManagementScreen(
          key: const ValueKey('invoice_list'),
          onEditInvoice: editInvoice,
          onCloneInvoice: cloneInvoice,
          user: _currentUser,
          filterType: 'Invoice',
        );
      case 3:
        return InvoiceManagementScreen(
          key: const ValueKey('quotation_list'),
          onEditInvoice: editInvoice,
          onCloneInvoice: cloneInvoice,
          user: _currentUser,
          filterType: 'Quotation',
        );
      case 4:
        return CustomerManagementScreen(user: _currentUser);
      case 5:
        return ProductManagementScreen(user: _currentUser);
      case 6:
        return const ReportsScreen();
      case 7:
        return SettingsScreen(currentUser: _currentUser);
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  void editInvoice(Invoice invoice) {
    _openEditInvoice(invoice);
  }

  Future<void> _openEditInvoice(Invoice invoice) async {
    if (!await _canLeaveInvoiceForm()) return;
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = invoice;
      _invoiceToClone = null;
    });
  }

  void cloneInvoice(Invoice invoice, String type) {
    _openCloneInvoice(invoice, type);
  }

  Future<void> _openCloneInvoice(Invoice invoice, String type) async {
    if (!await _canLeaveInvoiceForm()) return;
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = null;
      _invoiceToClone = invoice;
      _cloneType = type;
    });
  }

  Future<bool> _canLeaveInvoiceForm() async {
    return await _invoiceFormGuard.canLeave?.call() ?? true;
  }

  Future<void> _selectTab(int index) async {
    if (_selectedIndex == index) return;
    if (_selectedIndex == 1 && !await _canLeaveInvoiceForm()) return;
    if (_selectedIndex == 7 && index != 7) await _refreshUser();
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        invoiceToEdit = null;
        _invoiceToClone = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: SessionManager.onUserActivity,
      onPanDown: (_) => SessionManager.onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(child: buildScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final expanded = _sidebarExpanded;
    final primary = Theme.of(context).primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: expanded ? 210 : 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
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
                        'assets/images/logo.png',
                        height: 36,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      child: Tooltip(
                        message: 'Collapse sidebar',
                        child: InkWell(
                          onTap: () => setState(() => _sidebarExpanded = false),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.chevron_left_rounded,
                                color: const Color(0xFF64748B), size: 20),
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
                        'assets/images/logo_v.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: 'Expand sidebar',
                      child: InkWell(
                        onTap: () => setState(() => _sidebarExpanded = true),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.chevron_right_rounded,
                              color: const Color(0xFF64748B), size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
            const SizedBox(height: 8),

            // ── Nav Items ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard,
                        'Dashboard'),
                    _buildNavItem(1, Icons.receipt_outlined, Icons.receipt,
                        'New Invoice'),
                    _buildNavItem(2, Icons.receipt_long_outlined,
                        Icons.receipt_long, 'Invoices'),
                    _buildNavItem(3, Icons.request_quote_outlined,
                        Icons.request_quote, 'Quotations'),
                    _buildNavItem(
                        4, Icons.people_outline, Icons.people, 'Customers'),
                    _buildNavItem(5, Icons.inventory_2_outlined,
                        Icons.inventory_2, 'Products'),
                    _buildNavItem(6, Icons.bar_chart_outlined, Icons.bar_chart,
                        'Reports'),
                    _buildNavItem(
                        7, Icons.settings_outlined, Icons.settings, 'Settings',
                        showDot: _hasUpdate),
                  ],
                ),
              ),
            ),

            // ── User Info ──────────────────────────────
            const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
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
                                    style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _currentUser.isAdmin() ? 'Admin' : 'User',
                                    style: const TextStyle(
                                        color: Color(0xFF64748B), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              message: 'Logout',
                              child: InkWell(
                                onTap: () {
                                  SessionManager.dispose();
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginScreen()));
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.logout_rounded,
                                      color: Color(0xFF64748B), size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            AppConfig.version,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
                          message: 'Logout',
                          child: InkWell(
                            onTap: () {
                              SessionManager.dispose();
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()));
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.logout_rounded,
                                  color: Color(0xFF64748B), size: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          AppConfig.version,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          color: selected ? primary : const Color(0xFF64748B),
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
                          color: selected ? primary : const Color(0xFF64748B),
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
                          color: selected ? primary : const Color(0xFF64748B),
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

class DashboardHome extends StatefulWidget {
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
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
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
  List<Map<String, dynamic>> _monthlyRevenue = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    final results = await Future.wait([
      CustomerService.getAllCustomers(), // 0
      ProductService.getAllProducts(), // 1
      InvoiceService.getDashboardFinancials(), // 2
      InvoiceService.getRecentInvoices(limit: 5), // 3
      InvoiceService.getDueSoonInvoices(), // 4
      InvoiceService.getOverdueInvoices(limit: 10), // 5
      SettingsService.getCurrency(), // 6
      InvoiceService.getMonthlyRevenue(), // 7
      SettingsService.getSetting(SettingKey.dashboardLayout), // 8
      InvoiceService.getTopCustomers(), // 9
      InvoiceService.getTopProducts(), // 10
      SettingsService.getSetting(SettingKey.layoutBannerDismissed), // 11
    ]);

    final customers = results[0] as List<Customer>;
    final products = results[1] as List<Product>;
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

    setState(() {
      totalCustomers = customers.length;
      totalProducts = products.length;
      outOfStockProducts = products.where((p) => p.stock <= 0).toList();
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
      isLoading = false;
    });
  }

  Future<void> _dismissLayoutBanner() async {
    await SettingsService.setSetting(SettingKey.layoutBannerDismissed, '1');
    if (mounted) setState(() => _showLayoutBanner = false);
  }

  Widget _buildLayoutDiscoveryBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _showLayoutBanner
          ? Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dashboard_customize_outlined,
                      color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New: Multiple dashboard layouts',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Switch between Default, Classic, Bento, and Simple Feed using the grid icon in the top-right.',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _dismissLayoutBanner,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Got it',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: const Color(0xFF93C5FD),
                    onPressed: _dismissLayoutBanner,
                    tooltip: 'Dismiss',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          _buildLayoutToggle(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
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
              // ── Greeting Banner ──────────────────────────────
              _buildGreetingBanner(),

              const SizedBox(height: 28),

              // ── Stats Row ────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatCard('Customers', totalCustomers.toString(),
                        const Color(0xFF1565C0), Icons.people_outline),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Products',
                      totalProducts.toString(),
                      const Color(0xFF2E7D32),
                      Icons.inventory_2_outlined,
                      subtitle: outOfStockProducts.isNotEmpty
                          ? '${outOfStockProducts.length} out of stock'
                          : null,
                      subtitleColor: Colors.red[600],
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard('Invoices', totalInvoices.toString(),
                        const Color(0xFFE65100), Icons.receipt_long_outlined),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Revenue Collected',
                      '$_currencySymbol ${totalRevenue.toStringAsFixed(2)}',
                      const Color(0xFF6A1B9A),
                      Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Outstanding',
                      '$_currencySymbol ${totalOutstanding.toStringAsFixed(2)}',
                      const Color(0xFFC62828),
                      Icons.hourglass_top_outlined,
                      subtitle: overdueInvoices.isNotEmpty
                          ? '${overdueInvoices.length} overdue'
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
                  const Text(
                    'Recent Invoices',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3),
                  ),
                  const Spacer(),
                  Text(
                    'Last 5 invoices',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No invoices yet',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first invoice to see it here',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[400]),
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
                                              '${invoice.type} #${invoice.id}',
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
                                                invoice.type,
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
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.person_outline,
                                                    size: 16,
                                                    color: Colors.grey[600]),
                                                const SizedBox(width: 6),
                                                Text(
                                                  invoice.customer.name
                                                      .limit(15),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.grey[700]),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.grey[600]),
                                                const SizedBox(width: 6),
                                                Text(
                                                  invoice.date
                                                      .toString()
                                                      .split(' ')[0],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.grey[700]),
                                                ),
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
                                                    : Colors.grey[600]!;
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
                                                          'Due: ${AppFormatters.formatShortDate(invoice.dueDate)}',
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.purple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
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
                                  const SizedBox(width: 16),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildActionButton(
                                          Icons.visibility_outlined,
                                          Colors.green,
                                          'View',
                                          () => InvoicePdfServices
                                              .showInvoiceDetails(
                                                  context, invoice)),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                          Icons.edit_outlined,
                                          Colors.blue,
                                          'Edit',
                                          () => widget.onEditInvoice(invoice)),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                          Icons.copy_all_outlined,
                                          Colors.teal,
                                          'Duplicate',
                                          () => _showCloneDialog(invoice)),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                          Icons.picture_as_pdf_outlined,
                                          Colors.orange,
                                          'PDF Preview',
                                          () => InvoicePdfServices.previewPDF(
                                              context, invoice)),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                          Icons.download_outlined,
                                          Colors.deepPurple,
                                          'Download PDF',
                                          () => PDFService.downloadPDF(
                                              context, invoice)),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                          Icons.print_outlined,
                                          Colors.blueGrey,
                                          'Print',
                                          () => InvoicePdfServices.generatePDF(
                                              context, invoice)),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                          Icons.payments_outlined,
                                          Colors.purple,
                                          'Payment',
                                          invoice.type == 'Invoice'
                                              ? () => showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (_) =>
                                                        ApplyPaymentDialog(
                                                      invoice: invoice,
                                                      onPaymentRecorded: () =>
                                                          setState(() {}),
                                                    ),
                                                  )
                                              : null),
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                          Icons.delete_outline,
                                          Colors.red,
                                          'Delete',
                                          widget.user.isAdmin()
                                              ? () => _showDeleteDialog(invoice)
                                              : null),
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
                'Welcome back, ${widget.user.username}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Here\'s your business at a glance',
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
            const Text(
              'Due Soon',
              style: TextStyle(
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
                '${dueSoonInvoices.length} invoice${dueSoonInvoices.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800]),
              ),
            ),
            const Spacer(),
            Text(
              'Today & Tomorrow',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
          final badgeLabel = isToday ? 'Due Today' : 'Due Tomorrow';

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
                      '#${invoice.id}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    // Customer
                    Icon(Icons.person_outline,
                        size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              invoice.customer.name,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
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
                        'View',
                        () => InvoicePdfServices.showInvoiceDetails(
                            context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                        Icons.picture_as_pdf_outlined,
                        Colors.orange,
                        'PDF Preview',
                        () => InvoicePdfServices.previewPDF(context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                        Icons.payments_outlined,
                        Colors.purple,
                        'Record Payment',
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
            const Text(
              'Overdue',
              style: TextStyle(
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
                '${overdueInvoices.length} invoice${overdueInvoices.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[800]),
              ),
            ),
            const Spacer(),
            Text(
              'Oldest first',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
                        '$daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[800]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Invoice ID
                    Text(
                      '#${invoice.id}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    // Customer
                    Icon(Icons.person_outline,
                        size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              invoice.customer.name,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
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
                        'View',
                        () => InvoicePdfServices.showInvoiceDetails(
                            context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                        Icons.picture_as_pdf_outlined,
                        Colors.orange,
                        'PDF Preview',
                        () => InvoicePdfServices.previewPDF(context, invoice)),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      Icons.payments_outlined,
                      Colors.purple,
                      'Record Payment',
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
              labelText: 'New Stock Quantity',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.add_box_outlined),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text.trim());
              if (qty == null || qty < 0) return;
              await ProductService.updateProductStock(product.id, qty);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadDashboardData();
            },
            child: const Text('Update'),
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
            const Text(
              'Out of Stock',
              style: TextStyle(
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
                '${outOfStockProducts.length} item${outOfStockProducts.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700]),
              ),
            ),
            const Spacer(),
            Text(
              'Tap to restock',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
                              product.type == 'service' ? 'Service' : 'Product',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
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
                            color: Colors.grey[700]),
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
                          'Stock: ${product.stock}',
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
                        'Update Stock',
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
          color: Colors.white,
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
                              color: Colors.grey[500],
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
                        color: Colors.grey[900]),
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
    final effectiveColor = onPressed != null ? color : Colors.grey[400]!;
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
    final Color color;
    final String label;
    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        label = 'Paid';
      case PaymentStatus.partial:
        color = Colors.orange;
        label = 'Partial';
      case PaymentStatus.unpaid:
        color = Colors.red;
        label = 'Unpaid';
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
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.copy_all, color: Colors.teal),
            SizedBox(width: 12),
            Text('Duplicate Invoice'),
          ],
        ),
        content: Text(
          'Create a copy of Invoice #${invoice.id}\n(${invoice.customer.name}) as:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Quotation'),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Quotation'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.receipt),
            label: const Text('Invoice'),
          ),
        ],
      ),
    );
    if (type != null) {
      widget.onCloneInvoice(invoice, type);
    }
  }

  void _showDeleteDialog(Invoice invoice) {
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
            const Text('Delete Invoice'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete Invoice #${invoice.id}? This action cannot be undone.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
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
            child: const Text('Delete'),
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
      tooltip: 'Dashboard Layout',
      offset: const Offset(0, 40),
      onSelected: (value) async {
        await SettingsService.setSetting(SettingKey.dashboardLayout, value);
        setState(() => _dashboardLayout = value);
        if (_showLayoutBanner) _dismissLayoutBanner();
      },
      itemBuilder: (ctx) => [
        _layoutMenuItem('default', Icons.view_agenda_outlined, 'Default',
            'Original layout'),
        _layoutMenuItem('classic', Icons.grid_view_outlined, 'Classic',
            'Charts + KPI grid'),
        _layoutMenuItem('bento', Icons.auto_awesome_mosaic_outlined, 'Bento',
            'Hero chart + card grid'),
        _layoutMenuItem('simple', Icons.view_list_outlined, 'Simple Feed',
            'Clean list view'),
      ],
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
          Icon(icon, size: 18, color: active ? primary : Colors.grey[600]),
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
                        color: active ? primary : Colors.grey[800])),
                Text(sub,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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
              _buildGreetingBanner(),
              const SizedBox(height: 20),
              // KPI row
              Row(
                children: [
                  _buildKpiCard(
                      'Revenue Collected',
                      '$_currencySymbol ${_fmtAmt(totalRevenue)}',
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF6A1B9A)),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                      'Outstanding',
                      '$_currencySymbol ${_fmtAmt(totalOutstanding)}',
                      Icons.hourglass_top_outlined,
                      const Color(0xFFC62828)),
                  const SizedBox(width: 10),
                  _buildKpiCard('Total Invoices', totalInvoices.toString(),
                      Icons.receipt_long_outlined, const Color(0xFFE65100)),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                      'Customers',
                      totalCustomers.toString(),
                      Icons.people_outline,
                      const Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    'Products',
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
              _buildGreetingBanner(),
              const SizedBox(height: 20),
              // Mini KPI strip
              Row(
                children: [
                  _buildKpiCard(
                      'Revenue',
                      '$_currencySymbol ${_fmtAmt(totalRevenue)}',
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF6A1B9A)),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                      'Outstanding',
                      '$_currencySymbol ${_fmtAmt(totalOutstanding)}',
                      Icons.hourglass_top_outlined,
                      const Color(0xFFC62828)),
                  const SizedBox(width: 12),
                  _buildKpiCard('Invoices', totalInvoices.toString(),
                      Icons.receipt_long_outlined, const Color(0xFFE65100)),
                  const SizedBox(width: 12),
                  _buildKpiCard('Customers', totalCustomers.toString(),
                      Icons.people_outline, const Color(0xFF1565C0)),
                  const SizedBox(width: 12),
                  _buildKpiCard(
                    'Products',
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
          color: Colors.white,
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
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900]),
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
        color: Colors.white,
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
          Text('Revenue — Last 6 Months',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800])),
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
                                          color: Colors.grey[500])),
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
                            size: 48, color: Colors.grey[200]),
                        const SizedBox(height: 8),
                        Text('No payment data yet',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
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
        color: Colors.white,
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
          Text('Financial Overview',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800])),
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
                    child: Text('No invoices yet',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 13))),
          ),
          const SizedBox(height: 14),
          _buildDonutLegend('Collected', const Color(0xFF2E7D32),
              '$_currencySymbol ${_fmtAmt(totalRevenue)}'),
          const SizedBox(height: 6),
          _buildDonutLegend('Outstanding', const Color(0xFFC62828),
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
                      '${overdueInvoices.length} invoice${overdueInvoices.length == 1 ? '' : 's'} overdue',
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
        Text(amount,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800])),
      ],
    );
  }

  // ── Shared: Compact Recent Invoices ─────────────────────────────────────────

  Widget _buildCompactRecentInvoices({int limit = 7}) {
    final invoices = recentInvoices.take(limit).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Text('Recent Invoices',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800])),
              const Spacer(),
              Text('Last $limit',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
                    child: Text('Invoice',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 3,
                    child: Text('Customer',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600))),
                Expanded(
                    flex: 2,
                    child: Text('Amount',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600))),
                const SizedBox(width: 60),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 4),
          if (invoices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Text('No invoices yet',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13))),
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
    switch (status) {
      case PaymentStatus.paid:
        statusColor = const Color(0xFF2E7D32);
        statusLabel = 'Paid';
        break;
      case PaymentStatus.partial:
        statusColor = const Color(0xFFF57C00);
        statusLabel = 'Partial';
        break;
      default:
        final isOver = InvoiceCalculator.isOverdue(
            dueDate: inv.dueDate, outstanding: inv.outstandingBalance);
        statusColor =
            isOver ? const Color(0xFFC62828) : const Color(0xFF546E7A);
        statusLabel = isOver ? 'Overdue' : 'Unpaid';
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    size: 15, color: Colors.grey[400]),
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
                    size: 15, color: Colors.grey[400]),
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
        color: Colors.white,
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
              Text('Due Soon',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800])),
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
        color: Colors.white,
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
              Text('Out of Stock',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800])),
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
                    const Text('0 left',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Update Stock',
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_box_outlined,
                                  size: 13, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Stock',
                                  style: TextStyle(
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
        color: Colors.white,
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
              Text('Overdue',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800])),
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
                      message: 'Record Payment',
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments_outlined,
                                  size: 13, color: Color(0xFF6A1B9A)),
                              SizedBox(width: 4),
                              Text('Pay',
                                  style: TextStyle(
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
        color: Colors.white,
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
          Text('Quick Actions',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800])),
          const SizedBox(height: 12),
          _buildQuickActionRow(Icons.add_circle_outline_rounded, 'New Invoice',
              Theme.of(context).primaryColor, () {
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
              Icons.person_add_outlined, 'Customers', const Color(0xFF1565C0),
              () {
            context
                .findAncestorStateOfType<_DashboardScreenState>()
                ?.setState(() {
              context
                  .findAncestorStateOfType<_DashboardScreenState>()
                  ?._selectedIndex = 4;
            });
          }),
          const SizedBox(height: 4),
          _buildQuickActionRow(
              Icons.bar_chart_outlined, 'Reports', const Color(0xFF2E7D32), () {
            context
                .findAncestorStateOfType<_DashboardScreenState>()
                ?.setState(() {
              context
                  .findAncestorStateOfType<_DashboardScreenState>()
                  ?._selectedIndex = 6;
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
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: Colors.grey[400]),
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
                                  'Revenue',
                                  '$_currencySymbol ${_fmtAmt(totalRevenue)}',
                                  Icons.account_balance_wallet_outlined,
                                  const Color(0xFF6A1B9A),
                                ),
                                const SizedBox(width: 14),
                                _buildKpiCard(
                                  'Invoices',
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
                                  'Outstanding',
                                  '$_currencySymbol ${_fmtAmt(totalOutstanding)}',
                                  Icons.hourglass_top_outlined,
                                  const Color(0xFFC62828),
                                ),
                                const SizedBox(width: 14),
                                _buildKpiCard(
                                  'Overdue',
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
                                    'Customers',
                                    totalCustomers.toString(),
                                    Icons.people_outline,
                                    const Color(0xFF1565C0)),
                                const SizedBox(width: 14),
                                _buildKpiCard(
                                  'Products',
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
      icon: Icon(Icons.more_vert_rounded, size: 15, color: Colors.grey[400]),
      iconSize: 22,
      padding: EdgeInsets.zero,
      tooltip: 'PDF Actions',
      offset: const Offset(0, 24),
      onSelected: (value) {
        if (value == 'preview') {
          InvoicePdfServices.previewPDF(context, inv);
        } else if (value == 'download') {
          PDFService.downloadPDF(context, inv);
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: 'preview',
          child: Row(children: [
            Icon(Icons.visibility_outlined, size: 16, color: Colors.green),
            SizedBox(width: 10),
            Text('Preview PDF', style: TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'download',
          child: Row(children: [
            Icon(Icons.download_outlined, size: 16, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text('Download PDF', style: TextStyle(fontSize: 13)),
          ]),
        ),
      ],
    );
  }

  // ── Shared: Invoice Action Menu (⋯) ────────────────────────────────────────

  Widget _buildInvoiceActionMenu(Invoice inv) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 15, color: Colors.grey[400]),
      iconSize: 22,
      padding: EdgeInsets.zero,
      tooltip: 'Actions',
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
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: 'payment',
          child: Row(children: [
            Icon(Icons.payments_outlined, size: 16, color: Color(0xFF6A1B9A)),
            SizedBox(width: 10),
            Text('Record Payment', style: TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'preview',
          child: Row(children: [
            Icon(Icons.visibility_outlined, size: 16, color: Colors.green),
            SizedBox(width: 10),
            Text('Preview PDF', style: TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'download',
          child: Row(children: [
            Icon(Icons.download_outlined, size: 16, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text('Download PDF', style: TextStyle(fontSize: 13)),
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
        color: Colors.white,
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
              Text('Top Customers',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800])),
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
                          color: Colors.grey[700])),
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
        color: Colors.white,
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
              Text('Top Products',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800])),
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
                      '${qty % 1 == 0 ? qty.toInt() : qty.toStringAsFixed(1)} units',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
