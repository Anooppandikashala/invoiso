import 'package:flutter/material.dart';
import 'package:invoiceapp/database/database_helper.dart';
import 'package:invoiceapp/models/customer.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class CustomerManagement extends StatefulWidget {
  @override
  _CustomerManagementState createState() => _CustomerManagementState();
}

class _CustomerManagementState extends State<CustomerManagement> {
  final dbHelper = DatabaseHelper();
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  String searchQuery = '';
  String sortBy = 'name'; // default sort

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final data = await dbHelper.getAllCustomers();
    setState(() {
      customers = data;
      _filterAndSort();
    });
  }

  void _filterAndSort() {
    filteredCustomers = customers.where((c) {
      final query = searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query);
    }).toList();

    filteredCustomers.sort((a, b) {
      if (sortBy == 'name') return a.name.compareTo(b.name);
      if (sortBy == 'email') return a.email.compareTo(b.email);
      return 0;
    });
  }

  void _handleAddOrUpdateCustomer([Customer? customer]) async {
    final newCustomer = Customer(
      id: customer?.id ?? const Uuid().v4(),
      name: nameController.text,
      email: emailController.text,
      phone: phoneController.text,
      address: addressController.text,
    );

    if (customer == null) {
      await dbHelper.insertCustomer(newCustomer);
    } else {
      await dbHelper.insertCustomer(newCustomer);
    }

    nameController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();

    await _loadCustomers();
  }

  void _populateForm(Customer customer) {
    nameController.text = customer.name;
    emailController.text = customer.email;
    phoneController.text = customer.phone;
    addressController.text = customer.address;
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final db = await dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [customer.id]);
    await _loadCustomers();
  }

  Future<void> _exportToCSV() async {
    List<List<String>> csvData = [
      ['Name', 'Email', 'Phone', 'Address'],
      ...filteredCustomers.map((c) => [c.name, c.email, c.phone, c.address]),
    ];

    String csv = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/customers.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Customer List (CSV)');
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ['Name', 'Email', 'Phone', 'Address'],
            data: filteredCustomers.map((c) => [c.name, c.email, c.phone, c.address]).toList(),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/customers.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Customer List (PDF)');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Add Customer form
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Add Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                    TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _handleAddOrUpdateCustomer(),
                      child: const Text('Add Customer'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Customer table and controls
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer Management',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ElevatedButton(onPressed: _exportToCSV, child: const Text('Export CSV')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _exportToPDF, child: const Text('Export PDF')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search + Sort
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            _filterAndSort();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: sortBy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            sortBy = value;
                            _filterAndSort();
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                        DropdownMenuItem(value: 'email', child: Text('Sort by Email')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Table
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Address')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredCustomers.map((customer) {
                        return DataRow(cells: [
                          DataCell(Text(customer.name)),
                          DataCell(Text(customer.email)),
                          DataCell(Text(customer.phone)),
                          DataCell(Text(customer.address)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _populateForm(customer);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteCustomer(customer),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
