import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/screens/settings_screen.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart';
import 'package:invoiso/utils/session_manager.dart';

import '../models/user.dart';
import '../database/user_service.dart';
import 'customer_management_screen.dart';
import '../database/database_helper.dart';
import 'create_invoice_screen.dart';
import 'product_management_screen.dart';
import 'invoice_management_screen.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentUser = widget.loggedInUser;
    SessionManager.initialize(_onSessionTimeout);
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
    if (_selectedIndex != 1) {
      setState(() {
        invoiceToEdit = null;
        _invoiceToClone = null;
      });
    }
    switch (_selectedIndex) {
      case 0:
        return DashboardHome(onEditInvoice: editInvoice, onCloneInvoice: cloneInvoice, user: _currentUser);
      case 1:
        return CreateInvoiceScreen(
          key: ValueKey('create_invoice_${invoiceToEdit?.id ?? 'new'}_${_invoiceToClone?.id ?? ''}'),
          invoiceToEdit: invoiceToEdit,
          cloneFrom: _invoiceToClone,
          cloneType: _invoiceToClone != null ? _cloneType : null,
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
        return SettingsScreen(currentUser: _currentUser);
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  void editInvoice(Invoice invoice) {
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = invoice;
      _invoiceToClone = null;
    });
  }

  void cloneInvoice(Invoice invoice, String type) {
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = null;
      _invoiceToClone = invoice;
      _cloneType = type;
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
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                  _buildNavItem(1, Icons.receipt_outlined, Icons.receipt, 'New Invoice'),
                  _buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long, 'Invoices'),
                  _buildNavItem(3, Icons.request_quote_outlined, Icons.request_quote, 'Quotations'),
                  _buildNavItem(4, Icons.people_outline, Icons.people, 'Customers'),
                  _buildNavItem(5, Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
                  _buildNavItem(6, Icons.settings_outlined, Icons.settings, 'Settings'),
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
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        child: Text(
                          _currentUser.username.isNotEmpty
                              ? _currentUser.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: primary, fontSize: 12, fontWeight: FontWeight.bold),
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
                                  color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500),
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
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                                color: primary, fontSize: 12, fontWeight: FontWeight.bold),
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
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()));
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.logout_rounded,
                                color: Color(0xFF64748B), size: 18),
                          ),
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
      ),  // ClipRect
    );
  }

  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final selected = _selectedIndex == index;
    final primary = Theme.of(context).primaryColor;

    void onTap() {
      if (_selectedIndex == 6 && index != 6) _refreshUser();
      setState(() => _selectedIndex = index);
    }

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
                      color: selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      selected ? filledIcon : outlinedIcon,
                      color: selected ? primary : const Color(0xFF64748B),
                      size: 20,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? filledIcon : outlinedIcon,
                      color: selected ? primary : const Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? primary : const Color(0xFF64748B),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
  List<Invoice> recentInvoices = [];
  String _currencySymbol = '₹';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    final customers = await CustomerService.getAllCustomers();
    final products = await ProductService.getAllProducts();
    final List<Invoice> invoices = await InvoiceService.getAllInvoices();
    final currency = await SettingsService.getCurrency();

    setState(() {
      totalCustomers = customers.length;
      totalProducts = products.length;
      totalInvoices = invoices.length;
      totalRevenue = invoices.fold(0.0, (sum, inv) => sum + inv.total);
      recentInvoices = invoices.length > 5 ? invoices.sublist(0, 5) : invoices;
      _currencySymbol = currency.symbol;
      isLoading = false;
    });
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting Banner ──────────────────────────────
                  _buildGreetingBanner(),

                  const SizedBox(height: 28),

                  // ── Stats Row ────────────────────────────────────
                  Row(
                    children: [
                      _buildStatCard('Customers', totalCustomers.toString(), const Color(0xFF1565C0), Icons.people_outline),
                      const SizedBox(width: 16),
                      _buildStatCard('Products', totalProducts.toString(), const Color(0xFF2E7D32), Icons.inventory_2_outlined),
                      const SizedBox(width: 16),
                      _buildStatCard('Invoices', totalInvoices.toString(), const Color(0xFFE65100), Icons.receipt_long_outlined),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Total Revenue',
                        '$_currencySymbol ${totalRevenue.toStringAsFixed(2)}',
                        const Color(0xFF6A1B9A),
                        Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),

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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3),
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
                                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No invoices yet',
                                        style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Create your first invoice to see it here',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
                                        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Theme.of(context).primaryColor,
                                                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
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

                                            const SizedBox(width: 16),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          '${invoice.type} #${invoice.id}',
                                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: invoice.type == 'Invoice'
                                                              ? Colors.indigo.withValues(alpha:0.1)
                                                              : Colors.orange.withValues(alpha:0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: invoice.type == 'Invoice'
                                                                ? Colors.indigo.withValues(alpha:0.35)
                                                                : Colors.orange.withValues(alpha:0.35),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          invoice.type,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: invoice.type == 'Invoice'
                                                                ? Colors.indigo[700]
                                                                : Colors.orange[800],
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                      if (invoice.type == 'Invoice') ...[
                                                        const SizedBox(width: 8),
                                                        _buildPaymentStatusChip(invoice.paymentStatus),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            invoice.customer.name,
                                                            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            invoice.date.toString().split(' ')[0],
                                                            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                                                          ),
                                                        ],
                                                      ),
                                                      if (invoice.dueDate != null)
                                                        () {
                                                          final now = DateTime.now();
                                                          final today = DateTime(now.year, now.month, now.day);
                                                          final due = DateTime(invoice.dueDate!.year, invoice.dueDate!.month, invoice.dueDate!.day);
                                                          final isOverdue = due.isBefore(today) && invoice.paymentStatus != PaymentStatus.paid;
                                                          final color = isOverdue ? Colors.red[700]! : Colors.grey[600]!;
                                                          return Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.event_outlined, size: 16, color: color),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                'Due: ${invoice.dueDate!.toString().split(' ')[0]}',
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  color: color,
                                                                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                                                                ),
                                                              ),
                                                              if (isOverdue) ...[
                                                                const SizedBox(width: 6),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.red.withValues(alpha: 0.1),
                                                                    borderRadius: BorderRadius.circular(4),
                                                                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                                                  ),
                                                                  child: Text(
                                                                    'Overdue',
                                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red[700]),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          );
                                                        }(),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withValues(alpha:0.1),
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
                                                _buildActionButton(Icons.visibility_outlined, Colors.green, 'View',
                                                    () => InvoicePdfServices.showInvoiceDetails(context, invoice)),
                                                const SizedBox(width: 8),
                                                _buildActionButton(Icons.edit_outlined, Colors.blue, 'Edit',
                                                    () => widget.onEditInvoice(invoice)),
                                                const SizedBox(width: 8),
                                                _buildActionButton(Icons.copy_all_outlined, Colors.teal, 'Duplicate',
                                                    () => _showCloneDialog(invoice)),
                                                const SizedBox(width: 8),
                                                _buildActionButton(Icons.picture_as_pdf_outlined, Colors.orange, 'PDF Preview',
                                                    () => InvoicePdfServices.previewPDF(context, invoice)),
                                                const SizedBox(width: 8),
                                                _buildActionButton(Icons.download_outlined, Colors.deepPurple, 'Download PDF',
                                                    () => PDFService.downloadPDF(context, invoice)),
                                                const SizedBox(width: 8),
                                                _buildActionButton(Icons.print_outlined, Colors.blueGrey, 'Print',
                                                    () => InvoicePdfServices.generatePDF(context, invoice)),
                                                const SizedBox(width: 8),
                                                _buildActionButton(Icons.payments_outlined, Colors.purple, 'Payment',
                                                    invoice.type == 'Invoice'
                                                        ? () => showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              builder: (_) => ApplyPaymentDialog(
                                                                invoice: invoice,
                                                                onPaymentRecorded: () => setState(() {}),
                                                              ),
                                                            )
                                                        : null),
                                                const SizedBox(width: 8),
                                                _buildActionButton(Icons.delete_outline, Colors.red, 'Delete',
                                                    widget.user.isAdmin() ? () => _showDeleteDialog(invoice) : null),
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
    );
  }

  Widget _buildGreetingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
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
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.72)),
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
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, yyyy').format(DateTime.now()),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(Icons.trending_up_rounded, color: color.withValues(alpha: 0.3), size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.1)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback? onPressed) {
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
              decoration: BoxDecoration(color: Colors.red.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
