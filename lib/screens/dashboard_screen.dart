import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/screens/settings_screen.dart';
import 'package:invoiso/services/invoice_services.dart';

import '../models/user.dart';
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

  Invoice? invoiceToEdit;

  Widget buildScreen()
  {
    if(_selectedIndex !=1)
    {
      setState(() {
        invoiceToEdit = null;// Switch to "New Invoice" tab
      });
    }
    switch (_selectedIndex) {
      case 0:
        return DashboardHome(onEditInvoice: editInvoice);
      case 1:
        return CreateInvoiceScreen(invoiceToEdit:invoiceToEdit,);
      case 2:
        return InvoiceManagementScreen(onEditInvoice: editInvoice);
      case 3:
        return CustomerManagementScreen();
      case 4:
        return ProductManagementScreen();
      case 5:
        return SettingsScreen(currentUser: widget.loggedInUser,);
      default:
        return const Center(child: Text("Unknown tab"));
    }
  }

  void editInvoice(Invoice invoice) {
    setState(() {
      _selectedIndex = 1;
      invoiceToEdit = invoice;// Switch to "New Invoice" tab
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
              Icon(Icons.person,color: Theme.of(context).primaryColor,),
              AppSpacing.wSmall,
              Text("Hi ${widget.loggedInUser.username}",style: TextStyle(fontSize: 18),),
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
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard),
                selectedIcon: Icon(Icons.dashboard,color: Colors.blue[900],),
                label: const Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.receipt),
                selectedIcon: Icon(Icons.receipt,color: Colors.blue[900],),
                label: const Text('New Invoice'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.list),
                selectedIcon: Icon(Icons.list,color: Colors.blue[900],),
                label: const Text('Invoices'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people),
                selectedIcon: Icon(Icons.people,color: Colors.blue[900],),
                label: const Text('Customers'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.inventory),
                selectedIcon: Icon(Icons.inventory,color: Colors.blue[900],),
                label: const Text('Products'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings,color: Colors.blue[900],),
                label: const Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: buildScreen() ),
        ],
      ),
    );
  }
}

// Dashboard Home
class DashboardHome extends StatefulWidget {
  final Function(Invoice) onEditInvoice;
  const DashboardHome({required this.onEditInvoice, Key? key}) : super(key: key);
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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final customers = await dbHelper.getAllCustomers();
    final products = await dbHelper.getAllProducts();
    final List<Invoice> invoices = await dbHelper.getAllInvoices();

    setState(() {
      totalCustomers = customers.length;
      totalProducts = products.length;
      totalInvoices = invoices.length;
      totalRevenue = invoices.fold(0.0, (sum, inv) => sum + inv.total);
      recentInvoices = invoices.length > 5
          ? invoices.sublist(0, 5)
          : invoices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.hMedium,
            Row(
              children: [
                _buildStatCard('Total Customers', totalCustomers.toString(), Colors.blue),
                AppSpacing.wMedium,
                _buildStatCard('Total Products', totalProducts.toString(), Colors.green),
                AppSpacing.wMedium,
                _buildStatCard('Total Invoices', totalInvoices.toString(), Colors.orange),
                AppSpacing.wMedium,
                _buildStatCard('Total Revenue', 'Rs ${totalRevenue.toStringAsFixed(2)}', Colors.purple),
              ],
            ),
            AppSpacing.hMedium,
            Divider(thickness: 3,),
            AppSpacing.hMedium,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Recent Invoices',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppSpacing.hMedium,
            Expanded(
              child: recentInvoices.isEmpty
                  ? const Center(child: Text('No invoices yet'))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width*0.7,
                        child: ListView.builder(
                                      itemCount: recentInvoices.length,
                                      itemBuilder: (context, index) {
                        final invoice = recentInvoices[index];
                        return Card(
                          child: ListTile(
                            leading: Text("${index+1}",style: TextStyle(fontSize: 24),),
                            title: Text('Invoice #${invoice.id}',style: TextStyle(fontSize: 20),),
                            subtitle: Text('${invoice.customer.name} - ${invoice.date.toString().split(' ')[0]}',style: TextStyle(fontSize: 18),),
                            trailing: SizedBox(
                            width: MediaQuery.sizeOf(context).width*0.25, // adjust as needed
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rs: ${(invoice.total).toStringAsFixed(2)}',style: TextStyle(fontSize: 24),),
                                IconButton(
                                  icon: const Icon(Icons.visibility,color: Colors.green,),
                                  onPressed: () => InvoiceServices.showInvoiceDetails(context, invoice),
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => widget.onEditInvoice(invoice),
                                  tooltip: 'Edit Invoice',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf,color: Colors.purple),
                                  onPressed: () => InvoiceServices.previewPDF(context, invoice),
                                  tooltip: 'Preview PDF',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.print,color: Colors.black),
                                  onPressed: () => InvoiceServices.generatePDF(context, invoice),
                                  tooltip: 'Print PDF',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,color: Colors.red,),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Invoice'),
                                      content: const Text('Are you sure you want to delete this invoice?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            InvoiceServices.deleteInvoice(context, invoice);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),

                          ),
                        );
                                      },
                                    ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              AppSpacing.hSmall,
              Text(value,
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
