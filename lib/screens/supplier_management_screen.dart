import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/supplier.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/supplier_provider.dart';
import 'package:invoiso/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

class SupplierManagementScreen extends ConsumerStatefulWidget {
  final User user;
  const SupplierManagementScreen({super.key, required this.user});

  @override
  ConsumerState<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState
    extends ConsumerState<SupplierManagementScreen> {
  List<Supplier> _suppliers = [];
  Map<String, double> _balances = {};
  int _totalCount = 0;
  int _currentPage = 0;
  int _pageSize = 10;
  String _searchQuery = '';
  bool _isLoading = false;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  // Form controllers (Add New Supplier card)
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalPages => (_totalCount / _pageSize).ceil();

  Future<void> _loadPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(supplierRepositoryProvider);
      final results = await Future.wait([
        repo.getSuppliersPaginated(
          offset: _currentPage * _pageSize,
          limit: _pageSize,
          query: _searchQuery,
        ),
        repo.getSupplierCount(_searchQuery),
      ]);
      final suppliers = results[0] as List<Supplier>;
      final count = results[1] as int;
      final balances = await Future.wait(
        suppliers.map((s) => repo.getOutstandingBalance(s.id)),
      );
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _totalCount = count;
        _balances = {
          for (int i = 0; i < suppliers.length; i++) suppliers[i].id: balances[i],
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppError.show(context, 'Failed to load suppliers: $e', onRetry: _loadPage);
      }
    }
  }

  void _changePage(int page) {
    if (!mounted) return;
    setState(() => _currentPage = page);
    _loadPage();
  }

  Future<void> _handleAddSupplier() async {
    if (!_formKey.currentState!.validate() || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final supplier = Supplier(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstin: _gstinController.text.trim(),
        notes: _notesController.text.trim(),
      );
      await ref.read(supplierRepositoryProvider).insertSupplier(supplier);
      ref.read(suppliersProvider.notifier).refresh();
      _clearForm();
      await _loadPage();
      if (mounted) AppError.showSuccess(context, 'Supplier added successfully!');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppError.show(context, 'Error saving supplier: $e');
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _businessNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _gstinController.clear();
    _notesController.clear();
  }

  void _showSupplierDialog(Supplier supplier, bool isEdit) {
    final nameCtrl = TextEditingController(text: supplier.name);
    final businessNameCtrl = TextEditingController(text: supplier.businessName);
    final phoneCtrl = TextEditingController(text: supplier.phone);
    final emailCtrl = TextEditingController(text: supplier.email);
    final addressCtrl = TextEditingController(text: supplier.address);
    final gstinCtrl = TextEditingController(text: supplier.gstin);
    final notesCtrl = TextEditingController(text: supplier.notes);
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.visibility,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit Supplier' : 'View Supplier'),
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
                      _buildDialogTextField(nameCtrl, 'Name', Icons.person, readOnly: !isEdit),
                      const SizedBox(height: 16),
                      _buildDialogTextField(businessNameCtrl, 'Business Name',
                          Icons.business_center, readOnly: !isEdit, maxLength: 100),
                      const SizedBox(height: 16),
                      _buildDialogTextField(phoneCtrl, 'Phone', Icons.phone,
                          readOnly: !isEdit, keyboardType: TextInputType.phone, maxLength: 15),
                      const SizedBox(height: 16),
                      _buildDialogTextField(emailCtrl, 'Email', Icons.email,
                          readOnly: !isEdit, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildDialogTextField(gstinCtrl, 'Tax/VAT Number (GSTIN)',
                          Icons.receipt_long, readOnly: !isEdit, maxLength: 50),
                      const SizedBox(height: 16),
                      _buildDialogTextField(addressCtrl, 'Address', Icons.location_on,
                          readOnly: !isEdit, maxLines: 3, maxLength: 150),
                      const SizedBox(height: 16),
                      _buildDialogTextField(notesCtrl, 'Notes', Icons.notes,
                          readOnly: !isEdit, maxLines: 3, maxLength: 200),
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
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final updated = Supplier(
                              id: supplier.id,
                              name: nameCtrl.text.trim(),
                              businessName: businessNameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              gstin: gstinCtrl.text.trim(),
                              notes: notesCtrl.text.trim(),
                            );
                            await ref.read(supplierRepositoryProvider).updateSupplier(updated);
                            ref.read(suppliersProvider.notifier).refresh();
                            await _loadPage();
                            if (context.mounted) Navigator.pop(context);
                            if (mounted) {
                              AppError.showSuccess(context, 'Supplier updated successfully!');
                            }
                          } finally {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

  Future<void> _confirmSoftDelete(Supplier supplier) async {
    final confirmed = await AppError.confirm(
      context,
      title: 'Move to Trash',
      message: 'Move "${supplier.name}" to trash? Existing purchase bills keep showing their snapshotted supplier name.',
      confirmLabel: 'Move to Trash',
      confirmColor: Colors.orange,
    );
    if (!confirmed) return;

    await ref.read(supplierRepositoryProvider).softDeleteSupplier(supplier.id);
    ref.read(suppliersProvider.notifier).refresh();
    await _loadPage();
    if (mounted) AppError.showSuccess(context, 'Supplier moved to trash.');
  }

  void _showTrashDialog() async {
    final deleted = await ref.read(supplierRepositoryProvider).getDeletedSuppliers();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _SupplierTrashDialog(
        deletedSuppliers: deleted,
        onRestored: () async {
          ref.read(suppliersProvider.notifier).refresh();
          await _loadPage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Management'),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _showTrashDialog,
            tooltip: 'Trash',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPage,
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
              child: SingleChildScrollView(child: _buildAddSupplierCard()),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildSupplierTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSupplierCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add New Supplier',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
                  _buildFormField(_nameController, 'Name', Icons.person, true, maxLength: 50),
                  const SizedBox(height: 16),
                  _buildFormField(_businessNameController, 'Business Name',
                      Icons.business_center, false, maxLength: 100),
                  const SizedBox(height: 16),
                  _buildFormField(_phoneController, 'Phone', Icons.phone, false,
                      keyboardType: TextInputType.phone, maxLength: 15),
                  const SizedBox(height: 16),
                  _buildFormField(_emailController, 'Email', Icons.email, false,
                      maxLength: 100, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildFormField(_gstinController, 'Tax/VAT Number (GSTIN)',
                      Icons.receipt_long, false, maxLength: 50),
                  const SizedBox(height: 16),
                  _buildFormField(_addressController, 'Address', Icons.location_on, false,
                      maxLines: 3, maxLength: 150),
                  const SizedBox(height: 16),
                  _buildFormField(_notesController, 'Notes', Icons.notes, false,
                      maxLines: 3, maxLength: 200),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearForm,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _handleAddSupplier,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Supplier'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        counterText: '',
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter $label';
              return null;
            }
          : null,
    );
  }

  Widget _buildSupplierTable() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildTableHeader(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suppliers.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 800),
                            child: _buildDataTable(),
                          ),
                        ),
                      ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            'Suppliers ($_totalCount)',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search suppliers...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 0;
                    });
                    _loadPage();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 0;
          });
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 400), _loadPage);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No suppliers found',
              style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? 'Add your first supplier to get started' : 'Try adjusting your search',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columns: const [
        DataColumn(label: Text('Sl. No', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Business Name', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('GSTIN', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Outstanding', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: List.generate(_suppliers.length, (index) {
        final supplier = _suppliers[index];
        final serial = (_currentPage * _pageSize) + index + 1;
        final balance = _balances[supplier.id] ?? 0.0;
        return DataRow(
          color: WidgetStateProperty.all(
            index.isEven ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          cells: [
            DataCell(Text(serial.toString())),
            DataCell(Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(supplier.businessName)),
            DataCell(Text(supplier.phone)),
            DataCell(Text(supplier.gstin)),
            DataCell(
              Text(
                balance.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: balance > 0 ? Colors.red[700] : Colors.green[700],
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
                    onPressed: () => _showSupplierDialog(supplier, false),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.orange,
                    onPressed: () => _showSupplierDialog(supplier, true),
                    tooltip: 'Edit',
                  ),
                  if (widget.user.isAdmin())
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => _confirmSoftDelete(supplier),
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

  Widget _buildPaginationControls() {
    final totalPages = _totalPages == 0 ? 1 : _totalPages;
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
                  if (n == null) return;
                  setState(() {
                    _pageSize = n;
                    _currentPage = 0;
                  });
                  _loadPage();
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Total: $_totalCount',
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
                  'Page ${_currentPage + 1} of $totalPages',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
              IconButton(
                onPressed: _currentPage < totalPages - 1 ? () => _changePage(_currentPage + 1) : null,
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

// ─────────────────────────────────────────────
// Trash Dialog
class _SupplierTrashDialog extends ConsumerStatefulWidget {
  final List<Supplier> deletedSuppliers;
  final VoidCallback onRestored;

  const _SupplierTrashDialog({required this.deletedSuppliers, required this.onRestored});

  @override
  ConsumerState<_SupplierTrashDialog> createState() => _SupplierTrashDialogState();
}

class _SupplierTrashDialogState extends ConsumerState<_SupplierTrashDialog> {
  late List<Supplier> _suppliers;

  @override
  void initState() {
    super.initState();
    _suppliers = List.from(widget.deletedSuppliers);
  }

  Future<void> _restore(Supplier supplier) async {
    await ref.read(supplierRepositoryProvider).restoreSupplier(supplier.id);
    setState(() => _suppliers.removeWhere((s) => s.id == supplier.id));
    widget.onRestored();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier restored.'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text('Trash', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            if (_suppliers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('Trash is empty',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suppliers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final s = _suppliers[index];
                    return ListTile(
                      leading: Icon(Icons.local_shipping_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      title: Text(s.name),
                      subtitle: Text(s.businessName.isNotEmpty ? s.businessName : (s.phone.isNotEmpty ? s.phone : '—')),
                      trailing: TextButton.icon(
                        onPressed: () => _restore(s),
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text('Restore'),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ),
          ],
        ),
      ),
    );
  }
}
