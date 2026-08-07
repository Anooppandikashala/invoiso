import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/invoiso_colors.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/user.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class CustomerManagementScreenV2 extends ConsumerStatefulWidget {
  final User user;
  const CustomerManagementScreenV2({super.key, required this.user});

  @override
  ConsumerState<CustomerManagementScreenV2> createState() =>
      _CustomerManagementScreenV2State();
}

class _CustomerManagementScreenV2State extends ConsumerState<CustomerManagementScreenV2> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _isAscending = true;
  int _pageSize = 10;
  int _currentPage = 0;
  int _totalCustomerCount = 0;
  bool _isLoading = false;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _horizontalScrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── V2 state ──────────────────────────────────────────────────────────
  int _activeTabV2 = 0; // 0 all, 1 businesses, 2 individuals, 3 gst reg, 4 without gst
  bool _showAddPanelV2 = false;
  bool _addAnotherAfterSavingV2 = false;
  final Map<String, bool> _visibleColumnsV2 = {
    'phone': true,
    'email': true,
    'gstin': true,
    'address': true,
  };

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
    _businessNameController.dispose();
    _searchFocusNode.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      if(!mounted) return;
      final customerRepo = ref.read(customerRepositoryProvider);
      final results = await Future.wait([
        customerRepo.getAllCustomers(),
        customerRepo.getTotalCustomerCount(),
      ]);
      final data = results[0] as List<Customer>;
      final count = results[1] as int;
      if(!mounted) return;
      setState(() {
        _customers = data;
        _totalCustomerCount = count;
        _filterAndSort();
      });
    } catch (e) {
      _showSnackBar('Error loading customers: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAndSort() {
    _filteredCustomers = _customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.businessName.toLowerCase().contains(query) ||
          c.address.toLowerCase().contains(query) ||
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
    if(!mounted) return;
    setState(() {
      _isAscending = !_isAscending;
      _filterAndSort();
    });
  }

  void _changePage(int page) {
    if(!mounted) return;
    setState(() => _currentPage = page);
  }

  Future<void> _handleAddOrUpdateCustomer([Customer? customer]) async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final newCustomer = Customer(
        id: customer?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gstin: _gstinController.text.trim(),
        businessName: _businessNameController.text.trim(),
      );

      if (customer == null) {
        await ref.read(customerRepositoryProvider).insertCustomer(newCustomer);
        _showSnackBar('Customer added successfully!');
      } else {
        await ref.read(customerRepositoryProvider).updateCustomer(newCustomer);
        _showSnackBar('Customer updated successfully!');
      }

      _clearForm();
      await _loadCustomers();
    } catch (e) {
      _showSnackBar('Error saving customer: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _gstinController.clear();
    _businessNameController.clear();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showCustomerDialog(Customer customer, bool isEdit) async {
    //final isEdit = customer != null;
    final nameCtrl = TextEditingController(text: customer.name);
    final emailCtrl = TextEditingController(text: customer.email);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final addressCtrl = TextEditingController(text: customer.address);
    final gstinCtrl = TextEditingController(text: customer.gstin);
    final businessNameCtrl = TextEditingController(text: customer.businessName);
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
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
                  _buildDialogTextField(businessNameCtrl, 'Business Name', Icons.business_center,
                      readOnly: !isEdit, maxLength: 100),
                  const SizedBox(height: 16),
                  _buildDialogTextField(emailCtrl, 'Email', Icons.email,
                      readOnly: !isEdit, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildDialogTextField(phoneCtrl, 'Phone', Icons.phone,
                      readOnly: !isEdit,
                      keyboardType: TextInputType.phone,
                      maxLength: 12),
                  const SizedBox(height: 16),
                  _buildDialogTextField(gstinCtrl, 'Tax/VAT Number (GSTIN)', Icons.receipt_long,
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
              onPressed: isSaving ? null : () async {
                if (!dialogFormKey.currentState!.validate()) return;
                setDialogState(() => isSaving = true);
                try {
                  final updatedCustomer = Customer(
                    id: customer.id,
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    gstin: gstinCtrl.text.trim(),
                    businessName: businessNameCtrl.text.trim(),
                  );

                  await ref.read(customerRepositoryProvider).updateCustomer(updatedCustomer);
                  await _loadCustomers();
                  if (context.mounted) Navigator.pop(context);
                  _showSnackBar('Customer updated successfully!');
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              icon: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Saving...' : 'Update'),
            ),
        ],
        );
        });
      },
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        filled: readOnly,
        fillColor: readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
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
      await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
      await _loadCustomers();
      _showSnackBar('Customer deleted successfully!');
    }
  }

  Future<void> _downloadSampleCSV() async {
    const sample = '"name","email","phone","address","business_name","tax_number"\n'
        '"John Smith","john@example.com","+27821234567","123 Main St, Cape Town","Acme (Pty) Ltd","ZA123456789"\n'
        '"Jane Doe","jane@example.com","+27831234567","456 Oak Ave, Johannesburg","",""\n';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Sample CSV',
      fileName: 'customers_sample.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (savePath == null) return;

    try {
      await File(savePath).writeAsBytes(utf8.encode('\uFEFF$sample'));
      _showSnackBar('Sample CSV saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving sample: $e', isError: true);
    }
  }

  // ── CSV Import ────────────────────────────────────────────────────────────

  static const _csvMaxRows = 200;
  static const _csvHeaders = ['name', 'email', 'phone', 'address', 'business_name', 'tax_number'];

  Future<void> _showImportDialog() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            const Text('Import Customers from CSV'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your CSV file must use the following column headers (exact spelling, any order):',
                ),
                const SizedBox(height: 12),
                // Columns table
                Table(
                  border: TableBorder.all(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(6)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.4),
                    1: FlexColumnWidth(0.7),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      children: const [
                        _TableHeader('Column'),
                        _TableHeader('Required'),
                        _TableHeader('Description'),
                      ],
                    ),
                    _csvRuleRow(context, 'name',          'Yes', 'Customer full name'),
                    _csvRuleRow(context, 'email',         'No',  'Email address'),
                    _csvRuleRow(context, 'phone',         'No',  'Phone number'),
                    _csvRuleRow(context, 'address',       'No',  'Full address'),
                    _csvRuleRow(context, 'business_name', 'No',  'Company / business name'),
                    _csvRuleRow(context, 'tax_number',    'No',  'Tax / VAT / GSTIN number'),
                  ],
                ),
                const SizedBox(height: 16),
                // Notes
                _ruleNote(context, Icons.info_outline, 'Maximum $_csvMaxRows rows per import.'),
                _ruleNote(context, Icons.info_outline, 'Duplicates are detected by email or phone. You will be asked to overwrite or skip each one.'),
                _ruleNote(context, Icons.info_outline, 'Rows missing a name are skipped and reported at the end.'),
                _ruleNote(context, Icons.info_outline, 'UTF-8 encoding recommended. Excel BOM is handled automatically.'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx, false);
                    await _downloadSampleCSV();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Sample CSV'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose File'),
          ),
        ],
      ),
    );
    if (proceed == true) await _importFromCSV();
  }

  static TableRow _csvRuleRow(BuildContext context, String col, String req, String desc) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(col, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            req,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: req == 'Yes' ? Colors.red.shade700 : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(desc, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  static Widget _ruleNote(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface))),
        ],
      ),
    );
  }

  Future<void> _importFromCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Select Customer CSV',
    );
    if (result == null || result.files.single.path == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await File(result.files.single.path!).readAsBytes();
      // Strip UTF-8 BOM if present
      final content = utf8.decode(
        bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF
            ? bytes.sublist(3)
            : bytes,
      );

      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) {
        _showSnackBar('CSV file is empty.', isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // Parse and validate headers
      final headers = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
      if (!headers.contains('name')) {
        _showSnackBar('CSV missing required column: "name"', isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      for (final col in headers) {
        if (!_csvHeaders.contains(col)) {
          _showSnackBar('Unknown column "$col". Expected: ${_csvHeaders.join(', ')}', isError: true);
          if(!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
      }

      final dataRows = rows.skip(1).toList();

      // Hard limit
      if (dataRows.length > _csvMaxRows) {
        _showSnackBar('CSV has ${dataRows.length} rows. Maximum is $_csvMaxRows. Please split the file.', isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      String getField(List<dynamic> row, String col) {
        final i = headers.indexOf(col);
        return i < 0 || i >= row.length ? '' : row[i].toString().trim();
      }

      // Categorise rows
      final List<Customer> valid = [];
      final List<Customer> duplicates = [];
      final List<String> errors = [];

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final name = getField(row, 'name');
        if (name.isEmpty) {
          errors.add('Row ${i + 2}: missing name — skipped');
          continue;
        }
        final email = getField(row, 'email');
        final phone = getField(row, 'phone');
        final existing = await ref.read(customerRepositoryProvider).findDuplicate(email, phone);
        final customer = Customer(
          id: existing?.id ?? const Uuid().v4(),
          name: name,
          email: email,
          phone: phone,
          address: getField(row, 'address'),
          gstin: getField(row, 'tax_number'),
          businessName: getField(row, 'business_name'),
        );
        if (existing != null) {
          duplicates.add(customer);
        } else {
          valid.add(customer);
        }
      }
      if(!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      await _showImportPreviewDialog(valid, duplicates, errors);
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error reading CSV: $e', isError: true);
    }
  }

  Future<void> _showImportPreviewDialog(
    List<Customer> newCustomers,
    List<Customer> duplicates,
    List<String> errors,
  ) async {
    // Per-row overwrite flags: true = overwrite, false = skip
    final overwriteFlags = List<bool>.filled(duplicates.length, false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = newCustomers.length + overwriteFlags.where((f) => f).length;

          return AlertDialog(
            title: const Text('Import Preview'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('${newCustomers.length} new'),
                          backgroundColor: Colors.green.shade100,
                          avatar: const Icon(Icons.person_add, size: 16),
                        ),
                        Chip(
                          label: Text('${duplicates.length} duplicates'),
                          backgroundColor: Colors.orange.shade100,
                          avatar: const Icon(Icons.warning_amber, size: 16),
                        ),
                        if (errors.isNotEmpty)
                          Chip(
                            label: Text('${errors.length} errors'),
                            backgroundColor: Colors.red.shade100,
                            avatar: const Icon(Icons.error_outline, size: 16),
                          ),
                      ],
                    ),

                    if (duplicates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Duplicates (matched by email or phone):',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) { overwriteFlags[i] = true; }
                            }),
                            child: const Text('Overwrite All'),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) { overwriteFlags[i] = false; }
                            }),
                            child: const Text('Skip All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(duplicates.length, (i) {
                        final c = duplicates[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text('${c.name}${c.businessName.isNotEmpty ? ' — ${c.businessName}' : ''}'),
                            subtitle: Text('${c.email} · ${c.phone}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Skip', style: TextStyle(fontSize: 12)),
                                Switch(
                                  value: overwriteFlags[i],
                                  onChanged: (v) => setDialogState(() => overwriteFlags[i] = v),
                                ),
                                const Text('Overwrite', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Skipped rows (errors):',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      ...errors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $e',
                                style: const TextStyle(fontSize: 12, color: Colors.red)),
                          )),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      'Will import $total customer${total == 1 ? '' : 's'}.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: total == 0
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _executeImport(newCustomers, duplicates, overwriteFlags);
                      },
                icon: const Icon(Icons.upload),
                label: Text('Import $total'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeImport(
    List<Customer> newCustomers,
    List<Customer> duplicates,
    List<bool> overwriteFlags,
  ) async {
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (newCustomers.isNotEmpty) {
        await ref.read(customerRepositoryProvider).insertBatch(newCustomers);
      }
      for (int i = 0; i < duplicates.length; i++) {
        if (overwriteFlags[i]) {
          await ref.read(customerRepositoryProvider).updateCustomer(duplicates[i]);
        }
      }
      await _loadCustomers();
      final imported = newCustomers.length + overwriteFlags.where((f) => f).length;
      _showSnackBar('Imported $imported customer${imported == 1 ? '' : 's'} successfully!');
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Import error: $e', isError: true);
    }
  }

  // ── Delete All ────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAll() async {
    if (_customers.isEmpty) {
      _showSnackBar('No customers to delete.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Customers'),
        content: Text(
          'This will permanently delete all ${_customers.length} customer${_customers.length == 1 ? '' : 's'}. '
          'Existing invoices are not affected. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(customerRepositoryProvider).deleteAllCustomers();
      await _loadCustomers();
      _showSnackBar('All customers deleted.');
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error deleting customers: $e', isError: true);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<String>> csvData = [
        ['name', 'email', 'phone', 'address', 'business_name', 'tax_number'],
        ..._filteredCustomers.map((c) => [
          c.name,
          c.email,
          c.phone,
          c.address,
          c.businessName,
          c.gstin,
        ]),
      ];

      final csv = buildQuotedCsv(csvData);
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Customer CSV',
        fileName: 'customers.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(utf8.encode('\uFEFF$csv'));
      _showSnackBar('CSV exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting CSV: $e', isError: true);
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final totalCount = _filteredCustomers.length;
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Customer Export - $totalCount customer${totalCount == 1 ? '' : 's'}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated by Invoiso',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['#', 'Name', 'Business Name', 'Email', 'Phone', 'Tax/VAT No', 'Address'],
                ..._filteredCustomers.indexed.map(((int, dynamic) e) => [
                      e.$1 + 1,
                      e.$2.name,
                      e.$2.businessName,
                      e.$2.email,
                      e.$2.phone,
                      e.$2.gstin,
                      e.$2.address,
                    ]),
              ],
            ),
          ],
        ),
      );

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Customer PDF',
        fileName: 'customers.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(await pdf.save());
      _showSnackBar('PDF exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting PDF: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) => _buildV2(context);

  // ============================================================
  // V2 — flat / modern layout. Reuses all v1 state, controllers,
  // validation, and repository calls (_customers, _filterAndSort,
  // _handleAddOrUpdateCustomer, _showCustomerDialog, _confirmDelete,
  // import/export methods are all untouched). New pieces: tab-based
  // filtering layered on top of _filterAndSort, stat cards, a
  // slide-out "New Customer" panel, and a flat table.
  // ============================================================

  int get _businessesCountV2 =>
      _customers.where((c) => c.businessName.trim().isNotEmpty).length;
  int get _individualsCountV2 =>
      _customers.where((c) => c.businessName.trim().isEmpty).length;
  int get _gstRegisteredCountV2 =>
      _customers.where((c) => c.gstin.trim().isNotEmpty).length;
  int get _withoutGstCountV2 => _customers.length - _gstRegisteredCountV2;

  // Runs the existing search+sort (_filterAndSort) then layers the active
  // tab's business/individual/GST filter on top of its result.
  void _applyFilterV2() {
    _filterAndSort();
    Iterable<Customer> list = _filteredCustomers;
    switch (_activeTabV2) {
      case 1:
        list = list.where((c) => c.businessName.trim().isNotEmpty);
        break;
      case 2:
        list = list.where((c) => c.businessName.trim().isEmpty);
        break;
      case 3:
        list = list.where((c) => c.gstin.trim().isNotEmpty);
        break;
      case 4:
        list = list.where((c) => c.gstin.trim().isEmpty);
        break;
    }
    _filteredCustomers = list.toList();
  }

  void _onSearchChangedV2(String value) {
    if (!mounted) return;
    setState(() {
      _searchQuery = value;
      _applyFilterV2();
    });
  }

  void _onSortSelectionV2(String field, bool ascending) {
    if (!mounted) return;
    setState(() {
      _sortBy = field;
      _isAscending = ascending;
      _applyFilterV2();
    });
  }

  void _selectTabV2(int index) {
    if (!mounted) return;
    setState(() {
      _activeTabV2 = index;
      _currentPage = 0;
      _applyFilterV2();
    });
  }

  Future<void> _addCustomerV2() async {
    final nameBefore = _nameController.text;
    await _handleAddOrUpdateCustomer();
    final succeeded = _nameController.text.isEmpty && nameBefore.trim().isNotEmpty;
    if (succeeded) {
      if (!mounted) return;
      setState(() {
        _applyFilterV2();
        if (!_addAnotherAfterSavingV2) _showAddPanelV2 = false;
      });
    }
  }

  Future<void> _viewCustomerV2(Customer c) async {
    await _showCustomerDialog(c, false);
  }

  Future<void> _editCustomerV2(Customer c) async {
    await _showCustomerDialog(c, true);
    // _showCustomerDialog already reloads _customers + runs the plain
    // _filterAndSort internally on save; re-apply the active tab filter
    // on top so it doesn't get lost after an edit.
    if (!mounted) return;
    setState(_applyFilterV2);
  }

  Future<void> _deleteCustomerV2(Customer c) async {
    await _confirmDelete(c);
    if (!mounted) return;
    setState(_applyFilterV2);
  }

  BoxDecoration _flatCardDecorationV2(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );

  // A PopupMenuButton's `child` should stay non-interactive (PopupMenuButton
  // itself provides the tap-to-open handling) — a real OutlinedButton with
  // onPressed: null there would render as visually disabled/greyed out.
  Widget _menuButtonLookV2(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _statCardV2({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.all(16),
      decoration: _flatCardDecorationV2(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _statCardsRowV2() {
    final cards = [
      _statCardV2(
        label: 'Total Customers',
        value: '${_customers.length}',
        subtitle: 'All customers',
        icon: Icons.groups_outlined,
        accent: Theme.of(context).primaryColor,
      ),
      _statCardV2(
        label: 'Businesses',
        value: '$_businessesCountV2',
        subtitle: 'Registered businesses',
        icon: Icons.apartment_outlined,
        accent: Colors.green,
      ),
      _statCardV2(
        label: 'Individuals',
        value: '$_individualsCountV2',
        subtitle: 'Individual customers',
        icon: Icons.person_outline,
        accent: Colors.deepPurple,
      ),
      _statCardV2(
        label: 'GST Registered',
        value: '$_gstRegisteredCountV2',
        subtitle: 'With GST number',
        icon: Icons.receipt_long_outlined,
        accent: Colors.orange,
      ),
    ];

    // Responsive: fit as many equal-width cards per row as the available
    // width allows (min ~170px each), wrapping to additional rows instead
    // of squeezing/overflowing on narrow screens.
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minCardWidth = 170.0;
        final perRow = (constraints.maxWidth + spacing) ~/ (minCardWidth + spacing);
        final columns = perRow.clamp(1, cards.length);
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _headerBarV2() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer Management',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text('Manage your customers and contact details',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _showImportDialog,
              icon: const Icon(Icons.upload_file_outlined, size: 16),
              label: const Text('Import'),
            ),
            OutlinedButton.icon(
              onPressed: _exportToCSV,
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export'),
            ),
            if (widget.user.isAdmin())
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) {
                  if (value == 'export_pdf') _exportToPDF();
                  if (value == 'delete_all') _confirmDeleteAll();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem<String>(
                    value: 'export_pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Export PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete All Customers',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: _menuButtonLookV2(Icons.more_horiz, 'More'),
              ),
            IconButton(
              onPressed: _isLoading ? null : _loadCustomers,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            FilledButton.icon(
              onPressed: () => setState(() => _showAddPanelV2 = true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Customer'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
              ),
            ),
          ],
        ),
        ),
      ],
    );
  }

  Widget _searchFilterRowV2() {
    const sortOptions = [
      {'label': 'Name A-Z', 'field': 'name', 'asc': true},
      {'label': 'Name Z-A', 'field': 'name', 'asc': false},
      {'label': 'ID (oldest first)', 'field': 'id', 'asc': true},
      {'label': 'ID (newest first)', 'field': 'id', 'asc': false},
    ];
    final currentLabel = sortOptions.firstWhere(
      (o) => o['field'] == _sortBy && o['asc'] == _isAscending,
      orElse: () => sortOptions.first,
    )['label'] as String;

    return Row(
      children: [
        Expanded(
          child: TextField(
            focusNode: _searchFocusNode,
            onChanged: _onSearchChangedV2,
            decoration: InputDecoration(
              hintText: 'Search customers by name, business, phone, GST, email…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Filter',
                onSelected: (value) {
                  if (!mounted) return;
                  setState(() {
                    _currentPage = 0;
                    _activeTabV2 = switch (value) {
                      'gst' => 3,
                      'no_gst' => 4,
                      _ => _activeTabV2 >= 3 ? 0 : _activeTabV2,
                    };
                    _applyFilterV2();
                  });
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'all', child: Text('All GST statuses')),
                  PopupMenuItem(value: 'gst', child: Text('GST registered')),
                  PopupMenuItem(value: 'no_gst', child: Text('Without GST')),
                ],
                child: _menuButtonLookV2(Icons.filter_list, 'Filter'),
              ),
              PopupMenuButton<Map<String, Object>>(
                tooltip: 'Sort',
                onSelected: (opt) =>
                    _onSortSelectionV2(opt['field'] as String, opt['asc'] as bool),
                itemBuilder: (ctx) => sortOptions
                    .map((o) => PopupMenuItem(value: o, child: Text(o['label'] as String)))
                    .toList(),
                child: _menuButtonLookV2(Icons.swap_vert, 'Sort: $currentLabel'),
              ),
              PopupMenuButton<String>(
                tooltip: 'Columns',
                onSelected: (key) {
                  if (!mounted) return;
                  setState(() =>
                      _visibleColumnsV2[key] = !(_visibleColumnsV2[key] ?? true));
                },
                itemBuilder: (ctx) => [
                  _columnMenuItemV2('phone', 'Phone'),
                  _columnMenuItemV2('email', 'Email'),
                  _columnMenuItemV2('gstin', 'GST / VAT No'),
                  _columnMenuItemV2('address', 'Address'),
                ],
                child: _menuButtonLookV2(Icons.view_column_outlined, 'Columns'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _columnMenuItemV2(String key, String label) {
    final visible = _visibleColumnsV2[key] ?? true;
    return PopupMenuItem<String>(
      value: key,
      child: Row(
        children: [
          Icon(visible ? Icons.check_box : Icons.check_box_outline_blank, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _tabChipV2(String label, int count, int index) {
    final selected = _activeTabV2 == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: () => _selectTabV2(index),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Theme.of(context).primaryColor : null,
          foregroundColor:
              selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
              color: selected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
        child: Text('$label ($count)'),
      ),
    );
  }

  Widget _tabsRowV2() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChipV2('All', _customers.length, 0),
          _tabChipV2('Businesses', _businessesCountV2, 1),
          _tabChipV2('Individuals', _individualsCountV2, 2),
          _tabChipV2('GST Registered', _gstRegisteredCountV2, 3),
          _tabChipV2('Without GST', _withoutGstCountV2, 4),
        ],
      ),
    );
  }

  static const List<MaterialColor> _avatarColorsV2 = [
    Colors.blue,
    Colors.green,
    Colors.deepPurple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  Widget _avatarV2(Customer c) {
    final initials = c.name.trim().isEmpty
        ? '?'
        : c.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((s) => s.isNotEmpty ? s[0] : '')
            .join()
            .toUpperCase();
    final color = _avatarColorsV2[c.name.hashCode.abs() % _avatarColorsV2.length];
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(initials,
          style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _tableRowV2(Customer c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _avatarV2(c),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (c.businessName.trim().isNotEmpty)
                        Text(c.businessName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_visibleColumnsV2['phone'] ?? true)
            Expanded(
              flex: 2,
              child: Text(c.phone.isEmpty ? '—' : c.phone),
            ),
          if (_visibleColumnsV2['email'] ?? true)
            Expanded(
              flex: 3,
              child: Text(c.email.isEmpty ? '—' : c.email,
                  overflow: TextOverflow.ellipsis),
            ),
          if (_visibleColumnsV2['gstin'] ?? true)
            Expanded(
              flex: 2,
              child: Text(c.gstin.isEmpty ? '—' : c.gstin,
                  overflow: TextOverflow.ellipsis),
            ),
          if (_visibleColumnsV2['address'] ?? true)
            Expanded(
              flex: 3,
              child: Text(c.address.isEmpty ? '—' : c.address,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          SizedBox(
            width: 120,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _viewCustomerV2(c),
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editCustomerV2(c),
                  tooltip: 'Edit',
                ),
                if (widget.user.isAdmin())
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _deleteCustomerV2(c),
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderRowV2() {
    TextStyle style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NAME / BUSINESS', style: style)),
          if (_visibleColumnsV2['phone'] ?? true)
            Expanded(flex: 2, child: Text('PHONE', style: style)),
          if (_visibleColumnsV2['email'] ?? true)
            Expanded(flex: 3, child: Text('EMAIL', style: style)),
          if (_visibleColumnsV2['gstin'] ?? true)
            Expanded(flex: 2, child: Text('GST / VAT NO', style: style)),
          if (_visibleColumnsV2['address'] ?? true)
            Expanded(flex: 3, child: Text('ADDRESS', style: style)),
          SizedBox(width: 120, child: Text('ACTIONS', style: style)),
        ],
      ),
    );
  }

  Widget _paginationV2(List<Customer> pageItems, int totalPages) {
    final total = _filteredCustomers.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      // A plain Row with no Expanded/Wrap will overflow horizontally on a
      // narrow table. A horizontally-scrolling Row keeps this bar's height
      // constant and never overflows regardless of how narrow it gets.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Text(
            'Showing ${total == 0 ? 0 : _currentPage * _pageSize + 1} to '
            '${(_currentPage * _pageSize + _pageSize).clamp(0, total)} of $total customers',
            style: TextStyle(
                fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              Text('Rows per page',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox(),
                itemHeight: 48,
                items: [10, 25, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (n) {
                  if (n == null || !mounted) return;
                  setState(() {
                    _pageSize = n;
                    _currentPage = 0;
                  });
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_currentPage + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              Text('of $totalPages',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              IconButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => _changePage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  // This widget sizes itself naturally instead of relying on `Expanded` to
  // fill whatever space a bounded ancestor gives it — the page itself is a
  // CustomScrollView (see _buildV2), so the list here is shrink-wrapped
  // (its own scrolling disabled) and the page just scrolls further if the
  // natural content (header + rows + pagination) doesn't fit the viewport.
  Widget _tableSectionV2() {
    final totalPages =
        _filteredCustomers.isEmpty ? 1 : (_filteredCustomers.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredCustomers.length);
    final pageItems = start < end ? _filteredCustomers.sublist(start, end) : <Customer>[];

    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tableHeaderRowV2(),
          _isLoading && _customers.isEmpty
              ? const SizedBox(
                  height: 240, child: Center(child: CircularProgressIndicator()))
              : pageItems.isEmpty
                  ? SizedBox(height: 240, child: _buildEmptyState())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) => _tableRowV2(pageItems[index]),
                    ),
          _paginationV2(pageItems, totalPages),
        ],
      ),
    );
  }

  // ── Slide-out "New Customer" panel ──────────────────────────────────
  // The customer model only has these six fields — there's no secondary
  // "advanced" data set the way products have metadata/discount/tax, so
  // this is a single section rather than a tabbed panel.

  Widget _addPanelV2() {
    // Width is now controlled by the Positioned wrapper in _buildV2 (scales
    // with the window, capped between 520–680px, full width on narrow
    // screens), so this no longer hardcodes its own width.
    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            child: Row(
              children: [
                const Text('New Customer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _showAddPanelV2 = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: FocusTraversalGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(_nameController, 'Name', Icons.person, true,
                          maxLength: 50),
                      const SizedBox(height: 16),
                      _buildFormField(_businessNameController, 'Business Name',
                          Icons.business_center, false,
                          maxLength: 100),
                      const SizedBox(height: 16),
                      _buildFormField(_phoneController, 'Phone', Icons.phone, true,
                          keyboardType: TextInputType.phone, maxLength: 12),
                      const SizedBox(height: 16),
                      _buildFormField(_emailController, 'Email', Icons.email, false,
                          maxLength: 100, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildFormField(_gstinController, 'GST / VAT Number',
                          Icons.receipt_long, false,
                          maxLength: 50),
                      const SizedBox(height: 16),
                      _buildFormField(_addressController, 'Address', Icons.location_on,
                          false,
                          maxLines: 3, maxLength: 500),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _addAnotherAfterSavingV2,
                      onChanged: (v) =>
                          setState(() => _addAnotherAfterSavingV2 = v ?? false),
                    ),
                    const Expanded(child: Text('Add another after saving')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearForm();
                          setState(() => _showAddPanelV2 = false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _addCustomerV2,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save Customer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildV2(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Add/Edit panel width: was a flat 400px, squeezed into a Row
            // next to the main content (which could force the main
            // content's Expanded to near-zero on narrow windows). Now the
            // panel floats as an overlay instead, so it never steals width
            // from the table, and its own width scales a bit with the
            // window on large screens (capped so it doesn't get unwieldy)
            // while dropping to full width (minus margins) on narrow ones.
            final panelWidth = constraints.maxWidth < 750
                ? constraints.maxWidth - 32
                : (constraints.maxWidth * 0.42).clamp(520.0, 680.0);

            return Stack(
              children: [
                // The table section no longer relies on `Expanded` to fill
                // leftover space — it sizes itself naturally (header row +
                // actual row heights + pagination row), and sits in a plain
                // SliverToBoxAdapter below the rest of the page's content,
                // inside this CustomScrollView. Nothing here is forced into
                // a box smaller than it needs, so there's nothing to
                // overflow: if the natural content is taller than the
                // visible viewport, the page scrolls further to show it,
                // and if it fits (only a couple of customers), it fits with
                // no extra scrolling.
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headerBarV2(),
                            const SizedBox(height: 12),
                            _statCardsRowV2(),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: _flatCardDecorationV2(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _searchFilterRowV2(),
                                  const SizedBox(height: 10),
                                  _tabsRowV2(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: _tableSectionV2(),
                      ),
                    ),
                  ],
                ),
                if (_showAddPanelV2) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _showAddPanelV2 = false),
                      child: Container(color: Colors.black.withValues(alpha: 0.3)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    bottom: 16,
                    width: panelWidth,
                    child: _addPanelV2(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // Original v1 layout, kept for reference; no longer called.
  Widget _buildV1UnusedLayout(BuildContext context) {
    final totalPages = (_filteredCustomers.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredCustomers.length);
    final currentPageCustomers = _filteredCustomers.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: SingleChildScrollView(child: _buildAddCustomerCard()),
            ),
            const SizedBox(width: 16),
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
              gradient: CustomerManagementScreenColors.topBarBackgroundGradientColor,
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
            child: FocusTraversalGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormField(_nameController, 'Name', Icons.person, true, maxLength: 50),
                    const SizedBox(height: 16),
                    _buildFormField(_businessNameController, 'Business Name', Icons.business_center, false, maxLength: 100),
                    const SizedBox(height: 16),
                    _buildFormField(_emailController, 'Email', Icons.email, false, maxLength: 100,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildFormField(_phoneController, 'Phone', Icons.phone, false,
                        keyboardType: TextInputType.phone, maxLength: 12),
                    const SizedBox(height: 16),
                    _buildFormField(_gstinController, 'Tax/VAT Number (GSTIN)', Icons.receipt_long, false,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 12,
                    radius: const Radius.circular(6),
                    interactive: true,
                    notificationPredicate: (notif) => notif.depth == 1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 800),
                          child: _buildDataTable(customers),
                        ),
                      ),
                    ),
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
        gradient: CustomerManagementScreenColors.topBarBackgroundGradientColor,
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
                onPressed: _showImportDialog,
                icon: const Icon(Icons.upload_file),
                tooltip: 'Import CSV',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _exportToCSV,
                icon: const Icon(Icons.file_download),
                tooltip: 'Export CSV',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              if (widget.user.isAdmin()) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'More actions',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                  onSelected: (value) {
                    if (value == 'delete_all') _confirmDeleteAll();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<String>(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete All Customers',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                if(!mounted) return;
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
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    if(!mounted) return;
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
          Icon(Icons.person_off, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first customer to get started'
                : 'Try adjusting your search',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Customer> customers) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        Theme.of(context).primaryColor.withValues(alpha: 0.1),
      ),
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columns: [
        const DataColumn(label: Text('Sl. No', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Business Name', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Tax/VAT No', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: List.generate(customers.length, (index) {
        final customer = customers[index];
        final serial = (_currentPage * _pageSize) + index + 1;
        return DataRow(
          color: WidgetStateProperty.all(
            index.isEven ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          cells: [
            DataCell(Text(serial.toString())),
            DataCell(Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(customer.businessName)),
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
                  if (widget.user.isAdmin())
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('Rows per page:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox(),
                items: [10, 25, 50, 100].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                onChanged: (n) {
                  if (n == null || !mounted) return;
                  setState(() {
                    _pageSize = n;
                    _currentPage = 0;
                  });
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Showing ${_currentPage * _pageSize + 1} - ${(_currentPage * _pageSize + _pageSize).clamp(0, _filteredCustomers.length)} of ${_filteredCustomers.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
//                                         ? Theme.of(context).colorScheme.outlineVariant
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
