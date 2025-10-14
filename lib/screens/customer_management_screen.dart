import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/database_helper.dart';
import 'package:invoiso/models/customer.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  _CustomerManagementScreenState createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  String searchQuery = '';
  String sortBy = 'name';
  final int _pageSize = 10;
  int _currentPage = 0;
  int _totalCustomerCount = 0;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final gstinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    gstinController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final data = await CustomerService.getAllCustomers();
    final count = await CustomerService.getTotalCustomerCount();
    setState(() {
      customers = data;
      _totalCustomerCount = count;
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

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if ((_currentPage + 1) * _pageSize < filteredCustomers.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _handleAddOrUpdateCustomer([Customer? customer]) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final gstin = gstinController.text.trim();

    // Optional: Basic validation
    if (name.isEmpty)
    {
      _showError('Please enter a customer name.');
      return;
    }

    final newCustomer = Customer(
      id: customer?.id ?? const Uuid().v4(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      gstin: gstin,
    );

    if (customer == null) {
      await CustomerService.insertCustomer(newCustomer);
    } else {
      await CustomerService.updateCustomer(newCustomer);
    }

    // Clear controllers
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();
    gstinController.clear();

    // Refresh UI after database update
    await _loadCustomers();

    if (mounted) {
      setState(() {});
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showCustomerEditDialog(Customer customer, bool isViewOnly) {
    final nameCtrl = TextEditingController(text: customer.name);
    final emailCtrl = TextEditingController(text: customer.email);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final addressCtrl = TextEditingController(text: customer.address);
    final gstinCtrl = TextEditingController(text: customer.gstin);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: isViewOnly
              ? const Text('View Customer')
              : const Text('Edit Customer'),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  maxLength: 50,
                  readOnly: isViewOnly ? true : false,
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  maxLength: 50,
                  readOnly: isViewOnly ? true : false,
                ),
                TextField(
                  controller: phoneCtrl,
                  readOnly: isViewOnly ? true : false,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  maxLength: 12,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                  maxLength: 100,
                  readOnly: isViewOnly ? true : false,
                ),
                TextField(
                  controller: gstinCtrl,
                  decoration: const InputDecoration(labelText: 'GSTIN'),
                  maxLength: 50,
                  readOnly: isViewOnly ? true : false,
                ),
              ],
            ),
          ),
          actions: !isViewOnly
              ? [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () async {
                      final updatedCustomer = Customer(
                        id: customer.id,
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        address: addressCtrl.text,
                        gstin: gstinCtrl.text
                      );
                      await CustomerService.updateCustomer(updatedCustomer);
                      await _loadCustomers();
                      Navigator.pop(context);
                    },
                    child: const Text('Update'),
                  ),
                ]
              : [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                ]),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async 
  {
    await CustomerService.deleteCustomer(customer.id);
    await _loadCustomers();
  }

  Future<void> _exportToCSV() async {
    List<List<String>> csvData = [
      ['Name', 'Email', 'Phone','GSTIN', 'Address'],
      ...filteredCustomers.map((c) => [c.name, c.email, c.phone, c.gstin ,c.address]),
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
            headers: ['Name', 'Email', 'Phone', 'GSTIN' ,'Address'],
            data: filteredCustomers
                .map((c) => [c.name, c.email, c.phone, c.gstin ,c.address])
                .toList(),
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
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    final currentPageCustomers = filteredCustomers.sublist(
      start,
      end > filteredCustomers.length ? filteredCustomers.length : end,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Left form panel
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: 300,maxWidth: 300),
              child: Card(
                color: Colors.white,
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add New Customer',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.hMedium,
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                              controller: nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
                              maxLength: 50,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                          TextField(
                              controller: emailController,
                              decoration:
                                  const InputDecoration(labelText: 'Email'),
                              maxLength: 50,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                          TextField(
                            controller: phoneController,
                            decoration:
                                const InputDecoration(labelText: 'Phone'),
                            maxLength: 12,
                            style: TextStyle(fontSize: 16, color: Colors.black),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                          TextField(
                              controller: addressController,
                              decoration:
                                  const InputDecoration(labelText: 'Address'),
                              maxLength: 100,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                          TextField(
                              controller: gstinController,
                              decoration:
                              const InputDecoration(labelText: 'GSTIN'),
                              maxLength: 50,
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
                          AppSpacing.hMedium,
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _handleAddOrUpdateCustomer(),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add Customer'),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            AppSpacing.wMedium,
            // Right table panel
            Expanded(
              flex: 4,
              child: Card(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Icon(Icons.people,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Customers ($_totalCustomerCount)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                    onPressed: _exportToCSV,
                                    child: const Text('Export CSV')),
                                AppSpacing.wSmall,
                                ElevatedButton(
                                    onPressed: _exportToPDF,
                                    child: const Text('Export PDF')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search and Sort
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
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
                          AppSpacing.wMedium,
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
                              DropdownMenuItem(
                                  value: 'name', child: Text('Sort by Name')),
                              DropdownMenuItem(
                                  value: 'email', child: Text('Sort by Email')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.hMedium,
                    // Table
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              return Theme.of(context)
                                  .primaryColor; // Set your desired color here
                            },
                          ),
                          headingTextStyle: TextStyle(color: Colors.white),
                          columns: const [
                            DataColumn(label: Text('Sl. No')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('GSTIN')),
                            DataColumn(label: Text('Address')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: List.generate(currentPageCustomers.length,
                              (index) {
                            final customer = currentPageCustomers[index];
                            final serial =
                                (_currentPage * _pageSize) + index + 1;
                            return DataRow(
                                color: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    return (index + 1).isEven
                                        ? Colors.grey.shade200
                                        : Colors.white;
                                  },
                                ),
                                cells: [
                                  DataCell(Text(serial.toString())),
                                  DataCell(Text(customer.name)),
                                  DataCell(Text(customer.email)),
                                  DataCell(Text(customer.phone)),
                                  DataCell(Text(customer.gstin)),
                                  DataCell(
                                    Text(
                                      customer.address.length > 50
                                          ? '${customer.address.substring(0, 50)}...'
                                          : customer.address,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines:
                                          1, // Show up to 2 lines, then truncate
                                      softWrap: true,
                                    ),
                                  ),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          icon: const Icon(
                                            Icons.visibility,
                                            color: Colors.green,
                                          ),
                                          onPressed: () =>
                                              _showCustomerEditDialog(
                                                  customer, true)),
                                      IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () =>
                                              _showCustomerEditDialog(
                                                  customer, false)),
                                      IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteCustomer(customer)),
                                    ],
                                  )),
                                ]);
                          }),
                        ),
                      ),
                    ),
                    // Pagination Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: _prevPage,
                            icon: const Icon(Icons.chevron_left)),
                        Text(
                            'Page ${_currentPage + 1} of ${(filteredCustomers.length / _pageSize).ceil()}'),
                        IconButton(
                            onPressed: _nextPage,
                            icon: const Icon(Icons.chevron_right)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
