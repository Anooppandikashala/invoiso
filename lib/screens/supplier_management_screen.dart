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

  // Add/Edit overlay panel state
  bool _showAddPanelV2 = false;
  String? _editingSupplierId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _notesController = TextEditingController();

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

  void _openAddPanelV2() {
    _clearForm();
    setState(() {
      _editingSupplierId = null;
      _showAddPanelV2 = true;
    });
  }

  void _editSupplierV2(Supplier supplier) {
    _nameController.text = supplier.name;
    _businessNameController.text = supplier.businessName;
    _phoneController.text = supplier.phone;
    _emailController.text = supplier.email;
    _addressController.text = supplier.address;
    _gstinController.text = supplier.gstin;
    _notesController.text = supplier.notes;
    setState(() {
      _editingSupplierId = supplier.id;
      _showAddPanelV2 = true;
    });
  }

  Future<void> _saveSupplierV2() async {
    if (!_formKey.currentState!.validate() || !mounted) return;
    setState(() => _isLoading = true);
    final wasAdding = _editingSupplierId == null;
    try {
      final supplier = Supplier(
        id: _editingSupplierId ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstin: _gstinController.text.trim(),
        notes: _notesController.text.trim(),
      );
      if (wasAdding) {
        await ref.read(supplierRepositoryProvider).insertSupplier(supplier);
      } else {
        await ref.read(supplierRepositoryProvider).updateSupplier(supplier);
      }
      ref.read(suppliersProvider.notifier).refresh();
      _clearForm();
      if (!mounted) return;
      setState(() => _showAddPanelV2 = false);
      await _loadPage();
      if (mounted) {
        AppError.showSuccess(context,
            wasAdding ? 'Supplier added successfully!' : 'Supplier updated successfully!');
      }
    } catch (e) {
      if (mounted) AppError.show(context, 'Error saving supplier: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showViewSupplierDialogV2(Supplier supplier) {
    final balance = _balances[supplier.id] ?? 0.0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal.withValues(alpha: 0.12),
              child: Text(
                supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(supplier.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (supplier.businessName.isNotEmpty)
                _infoRowV2(Icons.business_center, supplier.businessName),
              if (supplier.phone.isNotEmpty) _infoRowV2(Icons.phone, supplier.phone),
              if (supplier.email.isNotEmpty) _infoRowV2(Icons.email, supplier.email),
              if (supplier.gstin.isNotEmpty)
                _infoRowV2(Icons.receipt_long, supplier.gstin),
              if (supplier.address.isNotEmpty)
                _infoRowV2(Icons.location_on, supplier.address),
              if (supplier.notes.isNotEmpty) _infoRowV2(Icons.notes, supplier.notes),
              const SizedBox(height: 8),
              _infoRowV2(
                Icons.account_balance_wallet_outlined,
                'Outstanding: ${balance.toStringAsFixed(2)}',
                color: balance > 0 ? Colors.red[700] : Colors.green[700],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRowV2(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
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

  Future<void> _confirmSoftDelete(Supplier supplier) async {
    final confirmed = await AppError.confirm(
      context,
      title: 'Move to Trash',
      message:
          'Move "${supplier.name}" to trash? Existing purchase bills keep showing their snapshotted supplier name.',
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

  // ============================================================
  // V2 layout — flat header/search/table (matching
  // CustomerManagementScreenV2 and UserManagementScreenV2): the Add/Edit
  // form floats as a scrim-backed overlay instead of a fixed side panel
  // stealing width from the table, and the pagination row scrolls
  // horizontally instead of overflowing on narrow windows.
  // ============================================================

  BoxDecoration _flatCardDecorationV2(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );

  Widget _actionButtonV2({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
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
              Row(
                children: [
                  Text('Suppliers',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_totalCount',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Manage the suppliers you purchase stock from',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              IconButton(
                onPressed: _showTrashDialog,
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Trash',
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadPage,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              FilledButton.icon(
                onPressed: _openAddPanelV2,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Supplier'),
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
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search suppliers by name, phone, or GSTIN...',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _currentPage = 0;
        });
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 400), _loadPage);
      },
    );
  }

  Widget _tableHeaderRowV2() {
    final style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Supplier', style: style)),
          Expanded(flex: 2, child: Text('Phone', style: style)),
          Expanded(flex: 2, child: Text('GSTIN', style: style)),
          Expanded(flex: 2, child: Text('Outstanding', style: style)),
          const SizedBox(width: 136, child: Text('')),
        ],
      ),
    );
  }

  Widget _tableRowV2(Supplier supplier) {
    final balance = _balances[supplier.id] ?? 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.teal.withValues(alpha: 0.12),
                    child: Text(
                      supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplier.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (supplier.businessName.trim().isNotEmpty)
                        Text(supplier.businessName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(supplier.phone.isEmpty ? '—' : supplier.phone)),
          Expanded(
              flex: 2,
              child: Text(supplier.gstin.isEmpty ? '—' : supplier.gstin,
                  overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Text(
              balance.toStringAsFixed(2),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: balance > 0 ? Colors.red[700] : Colors.green[700]),
            ),
          ),
          SizedBox(
            width: 136,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButtonV2(
                  icon: Icons.visibility_outlined,
                  color: Colors.green,
                  tooltip: 'View',
                  onPressed: () => _showViewSupplierDialogV2(supplier),
                ),
                const SizedBox(width: 6),
                _actionButtonV2(
                  icon: Icons.edit_outlined,
                  color: Colors.blue,
                  tooltip: 'Edit',
                  onPressed: () => _editSupplierV2(supplier),
                ),
                if (widget.user.isAdmin()) ...[
                  const SizedBox(width: 6),
                  _actionButtonV2(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    tooltip: 'Delete',
                    onPressed: () => _confirmSoftDelete(supplier),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A plain Row with no Expanded/Wrap would overflow horizontally on a
  // narrow window. A horizontally-scrolling Row keeps this bar's height
  // constant and never overflows regardless of how narrow it gets.
  Widget _paginationV2() {
    final totalPages = _totalPages == 0 ? 1 : _totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Rows per page:',
                style: TextStyle(
                    fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _pageSize,
              underline: const SizedBox(),
              items: [10, 25, 50, 100]
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
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
            Text('Total: $_totalCount',
                style: TextStyle(
                    fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(width: 24),
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
              onPressed:
                  _currentPage < totalPages - 1 ? () => _changePage(_currentPage + 1) : null,
              icon: const Icon(Icons.chevron_right),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  // Sizes itself naturally instead of relying on `Expanded` to fill
  // whatever space a bounded ancestor gives it — the page itself is a
  // CustomScrollView (see _buildV2), so the list here is shrink-wrapped
  // (its own scrolling disabled) and the page just scrolls further if the
  // natural content (header + rows + pagination) doesn't fit the viewport.
  Widget _tableSectionV2() {
    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tableHeaderRowV2(),
          _isLoading && _suppliers.isEmpty
              ? const SizedBox(
                  height: 240, child: Center(child: CircularProgressIndicator()))
              : _suppliers.isEmpty
                  ? SizedBox(
                      height: 240,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No suppliers yet'
                                  : 'No suppliers match your search',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suppliers.length,
                      itemBuilder: (context, index) => _tableRowV2(_suppliers[index]),
                    ),
          _paginationV2(),
        ],
      ),
    );
  }

  Widget _addPanelV2() {
    final isAdding = _editingSupplierId == null;
    final primaryColor = Theme.of(context).primaryColor;
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
                Text(isAdding ? 'Add New Supplier' : 'Edit Supplier',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _clearForm();
                    setState(() => _showAddPanelV2 = false);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: Row(
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
                    onPressed: _isLoading ? null : _saveSupplierV2,
                    style: FilledButton.styleFrom(backgroundColor: primaryColor),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(isAdding ? Icons.add : Icons.check, size: 18),
                    label: Text(isAdding ? 'Add Supplier' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth < 750
                ? constraints.maxWidth - 32
                : (constraints.maxWidth * 0.42).clamp(520.0, 680.0);

            return Stack(
              children: [
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: _flatCardDecorationV2(context),
                              child: _searchFilterRowV2(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(child: _tableSectionV2()),
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
