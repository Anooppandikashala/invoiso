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
  _CustomerManagementScreenState createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _isAscending = true;
  static const int _pageSize = 10;
  int _currentPage = 0;
  int _totalCustomerCount = 0;
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await CustomerService.getAllCustomers();
      final count = await CustomerService.getTotalCustomerCount();
      setState(() {
        _customers = data;
        _totalCustomerCount = count;
        _filterAndSort();
      });
    } catch (e) {
      _showSnackBar('Error loading customers: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterAndSort() {
    _filteredCustomers = _customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.gstin.toLowerCase().contains(query);
    }).toList();

    _filteredCustomers.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'id':
          result = a.id.compareTo(b.id);
          break;
        default:
          result = 0;
      }
      return _isAscending ? result : -result;
    });

    // Reset to first page when filtering
    _currentPage = 0;
  }

  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
      _filterAndSort();
    });
  }

  void _changePage(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _handleAddOrUpdateCustomer([Customer? customer]) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newCustomer = Customer(
        id: customer?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gstin: _gstinController.text.trim(),
      );

      if (customer == null) {
        await CustomerService.insertCustomer(newCustomer);
        _showSnackBar('Customer added successfully!');
      } else {
        await CustomerService.updateCustomer(newCustomer);
        _showSnackBar('Customer updated successfully!');
      }

      _clearForm();
      await _loadCustomers();
    } catch (e) {
      _showSnackBar('Error saving customer: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _gstinController.clear();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCustomerDialog(Customer customer,bool isEdit) {
    //final isEdit = customer != null;
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');
    final gstinCtrl = TextEditingController(text: customer?.gstin ?? '');
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit : Icons.visibility,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(isEdit ? 'Edit Customer' : 'View Customer'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(nameCtrl, 'Name', Icons.person,
                      readOnly: !isEdit),
                  const SizedBox(height: 16),
                  _buildDialogTextField(emailCtrl, 'Email', Icons.email,
                      readOnly: !isEdit, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildDialogTextField(phoneCtrl, 'Phone', Icons.phone,
                      readOnly: !isEdit,
                      keyboardType: TextInputType.phone,
                      maxLength: 12),
                  const SizedBox(height: 16),
                  _buildDialogTextField(gstinCtrl, 'GSTIN', Icons.business,
                      readOnly: !isEdit, maxLength: 50),
                  const SizedBox(height: 16),
                  _buildDialogTextField(addressCtrl, 'Address', Icons.location_on,
                      readOnly: !isEdit, maxLines: 3, maxLength: 100),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isEdit)
            FilledButton.icon(
              onPressed: () async {
                if (!dialogFormKey.currentState!.validate()) return;

                final updatedCustomer = Customer(
                  id: customer.id,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  gstin: gstinCtrl.text.trim(),
                );

                await CustomerService.updateCustomer(updatedCustomer);
                await _loadCustomers();
                if (context.mounted) Navigator.pop(context);
                _showSnackBar('Customer updated successfully!');
              },
              icon: const Icon(Icons.save),
              label: const Text('Update'),
            ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool readOnly = false,
        int maxLines = 1,
        int? maxLength,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
      ),
      validator: (value) {
        if (label == 'Name' && (value == null || value.trim().isEmpty)) {
          return 'Please enter a name';
        }
        return null;
      },
    );
  }

  Future<void> _confirmDelete(Customer customer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: Text('Are you sure you want to delete "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await CustomerService.deleteCustomer(customer.id);
      await _loadCustomers();
      _showSnackBar('Customer deleted successfully!');
    }
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<String>> csvData = [
        ['Name', 'Email', 'Phone', 'GSTIN', 'Address'],
        ..._filteredCustomers.map((c) => [
          c.name,
          c.email,
          c.phone,
          c.gstin,
          c.address,
        ]),
      ];

      String csv = const ListToCsvConverter().convert(csvData);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/customers.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Customer List (CSV)');
      _showSnackBar('CSV exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting CSV: $e', isError: true);
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: ['Name', 'Email', 'Phone', 'GSTIN', 'Address'],
              data: _filteredCustomers
                  .map((c) => [c.name, c.email, c.phone, c.gstin, c.address])
                  .toList(),
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/customers.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Customer List (PDF)');
      _showSnackBar('PDF exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting PDF: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredCustomers.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredCustomers.length);
    final currentPageCustomers = _filteredCustomers.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left form panel
            SizedBox(
              width: 320,
              child: SingleChildScrollView(child: _buildAddCustomerCard()),
            ),
            const SizedBox(width: 16),
            // Right table panel
            Expanded(child: _buildCustomerTable(currentPageCustomers, totalPages)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomerCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_add, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add New Customer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildFormField(_nameController, 'Name', Icons.person, true,maxLength: 50),
                  const SizedBox(height: 16),
                  _buildFormField(_emailController, 'Email', Icons.email, false,maxLength: 100,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildFormField(_phoneController, 'Phone', Icons.phone, false,
                      keyboardType: TextInputType.phone, maxLength: 12),
                  const SizedBox(height: 16),
                  _buildFormField(_gstinController, 'GSTIN', Icons.business, false,
                      maxLength: 50),
                  const SizedBox(height: 16),
                  _buildFormField(_addressController, 'Address', Icons.location_on, false,
                      maxLines: 3, maxLength: 100),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearForm,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => _handleAddOrUpdateCustomer(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customer'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(
      TextEditingController controller,
      String label,
      IconData icon,
      bool required, {
        int maxLines = 1,
        int? maxLength,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        counterText: '',
      ),
      validator: required
          ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      }
          : null,
    );
  }

  Widget _buildCustomerTable(List<Customer> customers, int totalPages) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildTableHeader(),
          _buildSearchAndSort(),
          Expanded(
            child: customers.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 800, // or any width your table needs
                  ),
                  child: _buildDataTable(customers),
                ),
              ),
            ),
          ),
          _buildPaginationControls(totalPages),
        ],
      ),
    );
  }

  Widget _buildCustomerTable1(List<Customer> customers, int totalPages) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildTableHeader(),
          _buildSearchAndSort(),
          Expanded(
            child: customers.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(customers),
            ),
          ),
          _buildPaginationControls(totalPages),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Customers ($_totalCustomerCount)',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton.filled(
                onPressed: _exportToCSV,
                icon: const Icon(Icons.file_download),
                tooltip: 'Export CSV',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterAndSort();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.arrow_drop_down),
                items: const [
                  DropdownMenuItem(value: 'id', child: Text('Sort by ID')),
                  DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                      _filterAndSort();
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _toggleSortOrder,
            icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _isAscending ? 'Ascending' : 'Descending',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first customer to get started'
                : 'Try adjusting your search',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Customer> customers) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columns: [
        const DataColumn(label: Text('Sl. No', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('GSTIN', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: List.generate(customers.length, (index) {
        final customer = customers[index];
        final serial = (_currentPage * _pageSize) + index + 1;
        return DataRow(
          color: WidgetStateProperty.all(
            index.isEven ? Colors.transparent : Colors.grey.shade50,
          ),
          cells: [
            DataCell(Text(serial.toString())),
            DataCell(Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(customer.email)),
            DataCell(Text(customer.phone)),
            DataCell(Text(customer.gstin)),
            DataCell(
              Tooltip(
                message: customer.address,
                child: Text(
                  customer.address.length > 30
                      ? '${customer.address.substring(0, 30)}...'
                      : customer.address,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    color: Colors.blue,
                    onPressed: () => _showCustomerDialog(customer,false),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.orange,
                    onPressed: () => _showCustomerDialog(customer,true),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: () => _confirmDelete(customer),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_currentPage * _pageSize + 1} - ${(_currentPage * _pageSize + _pageSize).clamp(0, _filteredCustomers.length)} of ${_filteredCustomers.length}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => _changePage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// class CustomerManagementScreen1 extends StatefulWidget {
//   const CustomerManagementScreen1({super.key});
//
//   @override
//   _CustomerManagementScreenState1 createState() => _CustomerManagementScreenState1();
// }
//
// class _CustomerManagementScreenState1 extends State<CustomerManagementScreen1> {
//   List<Customer> customers = [];
//   List<Customer> filteredCustomers = [];
//   String searchQuery = '';
//   String sortBy = 'name';
//   final int _pageSize = 10;
//   int _currentPage = 0;
//   int _totalCustomerCount = 0;
//
//   final nameController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final addressController = TextEditingController();
//   final gstinController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCustomers();
//   }
//
//   @override
//   void dispose() {
//     nameController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     addressController.dispose();
//     gstinController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadCustomers() async {
//     final data = await CustomerService.getAllCustomers();
//     final count = await CustomerService.getTotalCustomerCount();
//     setState(() {
//       customers = data;
//       _totalCustomerCount = count;
//       _filterAndSort();
//     });
//   }
//
//   void _filterAndSort() {
//     filteredCustomers = customers.where((c) {
//       final query = searchQuery.toLowerCase();
//       return c.name.toLowerCase().contains(query) ||
//           c.email.toLowerCase().contains(query) ||
//           c.phone.toLowerCase().contains(query);
//     }).toList();
//
//     filteredCustomers.sort((a, b) {
//       if (sortBy == 'name') return a.name.compareTo(b.name);
//       if (sortBy == 'email') return a.email.compareTo(b.email);
//       return 0;
//     });
//   }
//
//   void _prevPage() {
//     if (_currentPage > 0) {
//       setState(() {
//         _currentPage--;
//       });
//     }
//   }
//
//   void _nextPage() {
//     if ((_currentPage + 1) * _pageSize < filteredCustomers.length) {
//       setState(() {
//         _currentPage++;
//       });
//     }
//   }
//
//   void _handleAddOrUpdateCustomer([Customer? customer]) async {
//     final name = nameController.text.trim();
//     final email = emailController.text.trim();
//     final phone = phoneController.text.trim();
//     final address = addressController.text.trim();
//     final gstin = gstinController.text.trim();
//
//     // Optional: Basic validation
//     if (name.isEmpty)
//     {
//       _showError('Please enter a customer name.');
//       return;
//     }
//
//     final newCustomer = Customer(
//       id: customer?.id ?? const Uuid().v4(),
//       name: name,
//       email: email,
//       phone: phone,
//       address: address,
//       gstin: gstin,
//     );
//
//     if (customer == null) {
//       await CustomerService.insertCustomer(newCustomer);
//     } else {
//       await CustomerService.updateCustomer(newCustomer);
//     }
//
//     // Clear controllers
//     nameController.clear();
//     emailController.clear();
//     phoneController.clear();
//     addressController.clear();
//     gstinController.clear();
//
//     // Refresh UI after database update
//     await _loadCustomers();
//
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   void _showCustomerEditDialog(Customer customer, bool isViewOnly) {
//     final nameCtrl = TextEditingController(text: customer.name);
//     final emailCtrl = TextEditingController(text: customer.email);
//     final phoneCtrl = TextEditingController(text: customer.phone);
//     final addressCtrl = TextEditingController(text: customer.address);
//     final gstinCtrl = TextEditingController(text: customer.gstin);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//           title: isViewOnly
//               ? const Text('View Customer')
//               : const Text('Edit Customer'),
//           content: SizedBox(
//             width: MediaQuery.sizeOf(context).width * 0.3,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameCtrl,
//                   decoration: const InputDecoration(labelText: 'Name'),
//                   maxLength: 50,
//                   readOnly: isViewOnly ? true : false,
//                 ),
//                 TextField(
//                   controller: emailCtrl,
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   maxLength: 50,
//                   readOnly: isViewOnly ? true : false,
//                 ),
//                 TextField(
//                   controller: phoneCtrl,
//                   readOnly: isViewOnly ? true : false,
//                   decoration: const InputDecoration(labelText: 'Phone'),
//                   maxLength: 12,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                 ),
//                 TextField(
//                   controller: addressCtrl,
//                   decoration: const InputDecoration(labelText: 'Address'),
//                   maxLines: 3,
//                   maxLength: 100,
//                   readOnly: isViewOnly ? true : false,
//                 ),
//                 TextField(
//                   controller: gstinCtrl,
//                   decoration: const InputDecoration(labelText: 'GSTIN'),
//                   maxLength: 50,
//                   readOnly: isViewOnly ? true : false,
//                 ),
//               ],
//             ),
//           ),
//           actions: !isViewOnly
//               ? [
//                   TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cancel')),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final updatedCustomer = Customer(
//                         id: customer.id,
//                         name: nameCtrl.text,
//                         email: emailCtrl.text,
//                         phone: phoneCtrl.text,
//                         address: addressCtrl.text,
//                         gstin: gstinCtrl.text
//                       );
//                       await CustomerService.updateCustomer(updatedCustomer);
//                       await _loadCustomers();
//                       Navigator.pop(context);
//                     },
//                     child: const Text('Update'),
//                   ),
//                 ]
//               : [
//                   TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cancel')),
//                 ]),
//     );
//   }
//
//   Future<void> _deleteCustomer(Customer customer) async
//   {
//     await CustomerService.deleteCustomer(customer.id);
//     await _loadCustomers();
//   }
//
//   Future<void> _exportToCSV() async {
//     List<List<String>> csvData = [
//       ['Name', 'Email', 'Phone','GSTIN', 'Address'],
//       ...filteredCustomers.map((c) => [c.name, c.email, c.phone, c.gstin ,c.address]),
//     ];
//
//     String csv = const ListToCsvConverter().convert(csvData);
//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/customers.csv');
//     await file.writeAsString(csv);
//     await Share.shareXFiles([XFile(file.path)], text: 'Customer List (CSV)');
//   }
//
//   Future<void> _exportToPDF() async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Table.fromTextArray(
//             headers: ['Name', 'Email', 'Phone', 'GSTIN' ,'Address'],
//             data: filteredCustomers
//                 .map((c) => [c.name, c.email, c.phone, c.gstin ,c.address])
//                 .toList(),
//           );
//         },
//       ),
//     );
//
//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/customers.pdf');
//     await file.writeAsBytes(await pdf.save());
//     await Share.shareXFiles([XFile(file.path)], text: 'Customer List (PDF)');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final start = _currentPage * _pageSize;
//     final end = (_currentPage + 1) * _pageSize;
//     final currentPageCustomers = filteredCustomers.sublist(
//       start,
//       end > filteredCustomers.length ? filteredCustomers.length : end,
//     );
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Customer Management'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Row(
//           children: [
//             // Left form panel
//             ConstrainedBox(
//               constraints: BoxConstraints(minWidth: 300,maxWidth: 300),
//               child: Card(
//                 color: Colors.white,
//                 elevation: 2,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context)
//                             .primaryColor
//                             .withValues(alpha: 0.1),
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.person_add,
//                             color: Theme.of(context).primaryColor,
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             'Add New Customer',
//                             overflow: TextOverflow.ellipsis,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .titleLarge
//                                 ?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     AppSpacing.hMedium,
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           TextField(
//                               controller: nameController,
//                               decoration:
//                                   const InputDecoration(labelText: 'Name'),
//                               maxLength: 50,
//                               style:
//                                   TextStyle(fontSize: 16, color: Colors.black)),
//                           TextField(
//                               controller: emailController,
//                               decoration:
//                                   const InputDecoration(labelText: 'Email'),
//                               maxLength: 50,
//                               style:
//                                   TextStyle(fontSize: 16, color: Colors.black)),
//                           TextField(
//                             controller: phoneController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Phone'),
//                             maxLength: 12,
//                             style: TextStyle(fontSize: 16, color: Colors.black),
//                             keyboardType: TextInputType.number,
//                             inputFormatters: [
//                               FilteringTextInputFormatter.digitsOnly
//                             ],
//                           ),
//                           TextField(
//                               controller: addressController,
//                               decoration:
//                                   const InputDecoration(labelText: 'Address'),
//                               maxLength: 100,
//                               style:
//                                   TextStyle(fontSize: 16, color: Colors.black)),
//                           TextField(
//                               controller: gstinController,
//                               decoration:
//                               const InputDecoration(labelText: 'GSTIN'),
//                               maxLength: 50,
//                               style:
//                               TextStyle(fontSize: 16, color: Colors.black)),
//                           AppSpacing.hMedium,
//                           Center(
//                             child: ElevatedButton(
//                               onPressed: () => _handleAddOrUpdateCustomer(),
//                               style: ElevatedButton.styleFrom(
//                                 minimumSize: const Size(double.infinity, 50),
//                                 backgroundColor: Theme.of(context).primaryColor,
//                                 foregroundColor: Colors.white,
//                               ),
//                               child: const Text('Add Customer'),
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//             AppSpacing.wMedium,
//             // Right table panel
//             Expanded(
//               flex: 4,
//               child: Card(
//                 elevation: 2,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Header
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context)
//                             .primaryColor
//                             .withValues(alpha: 0.1),
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Row(
//                               children: [
//                                 Icon(Icons.people,
//                                     color: Theme.of(context).primaryColor),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   'Customers ($_totalCustomerCount)',
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .titleLarge
//                                       ?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8, right: 8),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 ElevatedButton(
//                                     onPressed: _exportToCSV,
//                                     child: const Text('Export CSV')),
//                                 AppSpacing.wSmall,
//                                 ElevatedButton(
//                                     onPressed: _exportToPDF,
//                                     child: const Text('Export PDF')),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Search and Sort
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               decoration: const InputDecoration(
//                                 labelText: 'Search',
//                                 prefixIcon: Icon(Icons.search),
//                                 border: OutlineInputBorder(),
//                               ),
//                               onChanged: (value) {
//                                 setState(() {
//                                   searchQuery = value;
//                                   _filterAndSort();
//                                 });
//                               },
//                             ),
//                           ),
//                           AppSpacing.wMedium,
//                           DropdownButton<String>(
//                             value: sortBy,
//                             onChanged: (value) {
//                               if (value != null) {
//                                 setState(() {
//                                   sortBy = value;
//                                   _filterAndSort();
//                                 });
//                               }
//                             },
//                             items: const [
//                               DropdownMenuItem(
//                                   value: 'name', child: Text('Sort by Name')),
//                               DropdownMenuItem(
//                                   value: 'email', child: Text('Sort by Email')),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     AppSpacing.hMedium,
//                     // Table
//                     Expanded(
//                       child: SingleChildScrollView(
//                         child: DataTable(
//                           headingRowColor:
//                               WidgetStateProperty.resolveWith<Color>(
//                             (Set<WidgetState> states) {
//                               return Theme.of(context)
//                                   .primaryColor; // Set your desired color here
//                             },
//                           ),
//                           headingTextStyle: TextStyle(color: Colors.white),
//                           columns: const [
//                             DataColumn(label: Text('Sl. No')),
//                             DataColumn(label: Text('Name')),
//                             DataColumn(label: Text('Email')),
//                             DataColumn(label: Text('Phone')),
//                             DataColumn(label: Text('GSTIN')),
//                             DataColumn(label: Text('Address')),
//                             DataColumn(label: Text('Actions')),
//                           ],
//                           rows: List.generate(currentPageCustomers.length,
//                               (index) {
//                             final customer = currentPageCustomers[index];
//                             final serial =
//                                 (_currentPage * _pageSize) + index + 1;
//                             return DataRow(
//                                 color: WidgetStateProperty.resolveWith<Color>(
//                                   (Set<WidgetState> states) {
//                                     return (index + 1).isEven
//                                         ? Colors.grey.shade200
//                                         : Colors.white;
//                                   },
//                                 ),
//                                 cells: [
//                                   DataCell(Text(serial.toString())),
//                                   DataCell(Text(customer.name)),
//                                   DataCell(Text(customer.email)),
//                                   DataCell(Text(customer.phone)),
//                                   DataCell(Text(customer.gstin)),
//                                   DataCell(
//                                     Text(
//                                       customer.address.length > 50
//                                           ? '${customer.address.substring(0, 50)}...'
//                                           : customer.address,
//                                       overflow: TextOverflow.ellipsis,
//                                       maxLines:
//                                           1, // Show up to 2 lines, then truncate
//                                       softWrap: true,
//                                     ),
//                                   ),
//                                   DataCell(Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       IconButton(
//                                           icon: const Icon(
//                                             Icons.visibility,
//                                             color: Colors.green,
//                                           ),
//                                           onPressed: () =>
//                                               _showCustomerEditDialog(
//                                                   customer, true)),
//                                       IconButton(
//                                           icon: const Icon(
//                                             Icons.edit,
//                                             color: Colors.blue,
//                                           ),
//                                           onPressed: () =>
//                                               _showCustomerEditDialog(
//                                                   customer, false)),
//                                       IconButton(
//                                           icon: const Icon(
//                                             Icons.delete,
//                                             color: Colors.red,
//                                           ),
//                                           onPressed: () =>
//                                               _deleteCustomer(customer)),
//                                     ],
//                                   )),
//                                 ]);
//                           }),
//                         ),
//                       ),
//                     ),
//                     // Pagination Controls
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         IconButton(
//                             onPressed: _prevPage,
//                             icon: const Icon(Icons.chevron_left)),
//                         Text(
//                             'Page ${_currentPage + 1} of ${(filteredCustomers.length / _pageSize).ceil()}'),
//                         IconButton(
//                             onPressed: _nextPage,
//                             icon: const Icon(Icons.chevron_right)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
