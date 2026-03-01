import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/invoice_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/screens/settings_screen.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';

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
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late User _currentUser;

  Invoice? invoiceToEdit;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.loggedInUser;
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
        invoiceToEdit = null; // Switch to "New Invoice" tab
      });
    }
    switch (_selectedIndex) {
      case 0:
        return DashboardHome(onEditInvoice: editInvoice);
      case 1:
        return CreateInvoiceScreen(
          invoiceToEdit: invoiceToEdit,
        );
      case 2:
        return InvoiceManagementScreen(onEditInvoice: editInvoice);
      case 3:
        return CustomerManagementScreen();
      case 4:
        return ProductManagementScreen();
      case 5:
        return SettingsScreen(
          currentUser: _currentUser,
        );
      default:
        return const Center(child: Text("Unknown tab"));
    }
  }

  void editInvoice(Invoice invoice) {
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = invoice; // Switch to "New Invoice" tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Image.asset(
          'assets/images/logo.png',
          width: 120,
          height: 100,
          fit: BoxFit.contain,
        ),
        actions: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
              ),
              AppSpacing.wSmall,
              Text(
                "Hi ${_currentUser.username}",
                style: TextStyle(fontSize: 18),
              ),
              AppSpacing.wMedium
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              // Refresh user when navigating away from Settings tab
              // so the header reflects any username change immediately.
              if (_selectedIndex == 5 && index != 5) {
                _refreshUser();
              }
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard),
                selectedIcon: Icon(
                  Icons.dashboard,
                  color: Colors.blue[900],
                ),
                label: const Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.receipt),
                selectedIcon: Icon(
                  Icons.receipt,
                  color: Colors.blue[900],
                ),
                label: const Text('New Invoice'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.list),
                selectedIcon: Icon(
                  Icons.list,
                  color: Colors.blue[900],
                ),
                label: const Text('Invoices'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people),
                selectedIcon: Icon(
                  Icons.people,
                  color: Colors.blue[900],
                ),
                label: const Text('Customers'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.inventory),
                selectedIcon: Icon(
                  Icons.inventory,
                  color: Colors.blue[900],
                ),
                label: const Text('Products'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings),
                selectedIcon: Icon(
                  Icons.settings,
                  color: Colors.blue[900],
                ),
                label: const Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: buildScreen()),
        ],
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  final Function(Invoice) onEditInvoice;
  const DashboardHome({required this.onEditInvoice, Key? key})
      : super(key: key);
  @override
  _DashboardHomeState createState() => _DashboardHomeState();
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
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.75,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards Section
                        Row(
                          children: [
                            _buildStatCard(
                              'Total Customers',
                              totalCustomers.toString(),
                              Colors.blue,
                              Icons.people,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Total Products',
                              totalProducts.toString(),
                              Colors.green,
                              Icons.inventory_2,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Total Invoices',
                              totalInvoices.toString(),
                              Colors.orange,
                              Icons.receipt_long,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              'Total Revenue',
                              '$_currencySymbol ${totalRevenue.toStringAsFixed(2)}',
                              Colors.purple,
                              Icons.account_balance_wallet,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Recent Invoices Section
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Recent Invoices',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // const Spacer(),
                            // if (recentInvoices.isNotEmpty)
                            //   TextButton.icon(
                            //     onPressed: () {
                            //       // Navigate to all invoices
                            //     },
                            //     icon: const Icon(Icons.arrow_forward),
                            //     label: const Text('View All'),
                            //   ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Invoices List
                        recentInvoices.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 80,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No invoices yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Create your first invoice to see it here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
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
                                    // width: MediaQuery.sizeOf(context).width*0.5,
                                    child: Card(
                                      elevation: 2,
                                      shadowColor:
                                          Colors.black.withValues(alpha: 0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Index Badge
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
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
                                                borderRadius:
                                                    BorderRadius.circular(AppBorderRadius.xsmall),
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

                                            // Invoice Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Invoice #${invoice.id}',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.green
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                            color: Colors.green
                                                                .withOpacity(
                                                                    0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'PAID',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors
                                                                .green[700],
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person_outline,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        invoice.customer.name,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        invoice.date
                                                            .toString()
                                                            .split(' ')[0],
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Amount
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.purple
                                                    .withOpacity(0.1),
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

                                            const SizedBox(width: 16),

                                            // Action Buttons
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildActionButton(
                                                  Icons.visibility_outlined,
                                                  Colors.green,
                                                  'View',
                                                  () => InvoicePdfServices
                                                      .showInvoiceDetails(
                                                    context,
                                                    invoice,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildActionButton(
                                                  Icons.edit_outlined,
                                                  Colors.blue,
                                                  'Edit',
                                                  () => widget
                                                      .onEditInvoice(invoice),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildActionButton(
                                                  Icons.picture_as_pdf_outlined,
                                                  Colors.orange,
                                                  'PDF',
                                                  () => InvoicePdfServices
                                                      .previewPDF(
                                                    context,
                                                    invoice,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildActionButton(
                                                  Icons.print_outlined,
                                                  Colors.blueGrey,
                                                  'Print',
                                                  () => InvoicePdfServices
                                                      .generatePDF(
                                                    context,
                                                    invoice,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildActionButton(
                                                  Icons.delete_outline,
                                                  Colors.red,
                                                  'Delete',
                                                  () => _showDeleteDialog(
                                                      invoice),
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
              ],
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                Icon(
                  Icons.trending_up,
                  color: color.withOpacity(0.4),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _showDeleteDialog(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
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
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Dashboard Home
// class DashboardHome1 extends StatefulWidget {
//   final Function(Invoice) onEditInvoice;
//   const DashboardHome1({required this.onEditInvoice, Key? key}) : super(key: key);
//   @override
//   _DashboardHomeState createState() => _DashboardHomeState();
// }
//
// class _DashboardHomeState1 extends State<DashboardHome1> {
//   final dbHelper = DatabaseHelper();
//   int totalCustomers = 0;
//   int totalProducts = 0;
//   int totalInvoices = 0;
//   double totalRevenue = 0.0;
//   List<Invoice> recentInvoices = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadDashboardData();
//   }
//
//   Future<void> _loadDashboardData() async {
//     final customers = await CustomerService.getAllCustomers();
//     final products = await ProductService.getAllProducts();
//     final List<Invoice> invoices = await InvoiceService.getAllInvoices();
//
//     setState(() {
//       totalCustomers = customers.length;
//       totalProducts = products.length;
//       totalInvoices = invoices.length;
//       totalRevenue = invoices.fold(0.0, (sum, inv) => sum + inv.total);
//       recentInvoices = invoices.length > 5
//           ? invoices.sublist(0, 5)
//           : invoices;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard Overview'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             AppSpacing.hMedium,
//             Row(
//               children: [
//                 _buildStatCard('Total Customers', totalCustomers.toString(), Colors.blue),
//                 AppSpacing.wMedium,
//                 _buildStatCard('Total Products', totalProducts.toString(), Colors.green),
//                 AppSpacing.wMedium,
//                 _buildStatCard('Total Invoices', totalInvoices.toString(), Colors.orange),
//                 AppSpacing.wMedium,
//                 _buildStatCard('Total Revenue', 'Rs ${totalRevenue.toStringAsFixed(2)}', Colors.purple),
//               ],
//             ),
//             AppSpacing.hMedium,
//             Divider(thickness: 3,),
//             AppSpacing.hMedium,
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'Recent Invoices',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             AppSpacing.hMedium,
//             Expanded(
//               child: recentInvoices.isEmpty
//                   ? const Center(child: Text('No invoices yet'))
//                   : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(
//                         width: MediaQuery.sizeOf(context).width*0.7,
//                         child: ListView.builder(
//                                       itemCount: recentInvoices.length,
//                                       itemBuilder: (context, index) {
//                         final invoice = recentInvoices[index];
//                         return Card(
//                           child: ListTile(
//                             leading: Text("${index+1}",style: TextStyle(fontSize: 24),),
//                             title: Text('Invoice #${invoice.id}',style: TextStyle(fontSize: 20),),
//                             subtitle: Text('${invoice.customer.name} - ${invoice.date.toString().split(' ')[0]}',style: TextStyle(fontSize: 18),),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                               children: [
//                                 Text('Rs: ${(invoice.total).toStringAsFixed(2)}',style: TextStyle(fontSize: 24),),
//                                 SizedBox(width: 20,),
//                                 IconButton(
//                                   icon: const Icon(Icons.visibility,color: Colors.green,),
//                                   onPressed: () => InvoicePdfServices.showInvoiceDetails(context, invoice),
//                                   tooltip: 'View Details',
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.edit, color: Colors.blue),
//                                   onPressed: () => widget.onEditInvoice(invoice),
//                                   tooltip: 'Edit Invoice',
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.picture_as_pdf,color: Colors.purple),
//                                   onPressed: () => InvoicePdfServices.previewPDF(context, invoice),
//                                   tooltip: 'Preview PDF',
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.print,color: Colors.black),
//                                   onPressed: () => InvoicePdfServices.generatePDF(context, invoice),
//                                   tooltip: 'Print PDF',
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete,color: Colors.red,),
//                                   onPressed: () => showDialog(
//                                     context: context,
//                                     builder: (context) => AlertDialog(
//                                       title: const Text('Delete Invoice'),
//                                       content: const Text('Are you sure you want to delete this invoice?'),
//                                       actions: [
//                                         TextButton(
//                                           onPressed: () => Navigator.pop(context),
//                                           child: const Text('Cancel'),
//                                         ),
//                                         ElevatedButton(
//                                           onPressed: () {
//                                             Navigator.pop(context);
//                                             InvoicePdfServices.deleteInvoice(context, invoice);
//                                           },
//                                           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                                           child: const Text('Delete'),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   tooltip: 'Delete',
//                                 ),
//                               ],
//                             ),
//
//                           ),
//                         );
//                                       },
//                                     ),
//                       ),
//                     ],
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatCard(String title, String value, Color color) {
//     return Expanded(
//       child: Card(
//         elevation: 4,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title,
//                   style: TextStyle(fontSize: 16, color: Colors.grey[600])),
//               AppSpacing.hSmall,
//               Text(value,
//                   style: TextStyle(
//                       fontSize: 32, fontWeight: FontWeight.bold, color: color)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
