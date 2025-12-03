import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../models/product.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  _ProductManagementScreenState createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<Product> _products = [];

  // Pagination
  int _currentPage = 0;
  static const int _pageSize = 10;
  int _totalProducts = 0;
  int _allProductsCount = 0;

  // Search and Sort
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _isAscending = true;
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _taxRateController.text = "18";
    _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _taxRateController.dispose();
    _hsnCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await ProductService.getProductsPaginated(
          offset: _currentPage * _pageSize,
          limit: _pageSize,
          query: _searchQuery,
          orderBy: _sortBy,
          orderASC: _isAscending);
      final count = await ProductService.getProductCount(_searchQuery);
      final allCount = await ProductService.getTotalProductCount();

      setState(() {
        _products = result;
        _totalProducts = count;
        _allProductsCount = allCount;
      });
    } catch (e) {
      _showSnackBar('Error loading products: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newProduct = Product(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        hsncode: _hsnCodeController.text.trim(),
        tax_rate: int.parse(_taxRateController.text.trim()),
      );

      await ProductService.insertProduct(newProduct);
      _clearForm();
      await _loadProducts();
      _showSnackBar('Product added successfully!');
    } catch (e) {
      _showSnackBar('Error adding product: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.clear();
    _hsnCodeController.clear();
    _taxRateController.clear();
    _taxRateController.text = "18";
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

  void _showProductDialog(Product product, bool isEdit) {
    //final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descriptionCtrl =
        TextEditingController(text: product?.description ?? '');
    final priceCtrl =
        TextEditingController(text: product?.price.toString() ?? '');
    final stockCtrl =
        TextEditingController(text: product?.stock.toString() ?? '');
    final hsnCodeCtrl = TextEditingController(text: product?.hsncode ?? '');
    final taxRateCtrl =
        TextEditingController(text: product?.tax_rate.toString() ?? '18');
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
            Text(isEdit ? 'Edit Product' : 'View Product'),
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
                  _buildDialogTextField(
                      nameCtrl, 'Product Name', Icons.inventory_2,
                      readOnly: !isEdit, maxLength: 100),
                  const SizedBox(height: 16),
                  _buildDialogTextField(hsnCodeCtrl, 'HSN Code', Icons.qr_code,
                      readOnly: !isEdit, maxLength: 100),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                      descriptionCtrl, 'Description', Icons.description,
                      readOnly: !isEdit, maxLines: 3, maxLength: 100),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                      priceCtrl, 'Price (₹)', Icons.currency_rupee,
                      readOnly: !isEdit,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      isPrice: true),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                      taxRateCtrl, 'Tax Rate (%)', Icons.percent,
                      readOnly: !isEdit,
                      keyboardType: TextInputType.number,
                      isTaxRate: true),
                  const SizedBox(height: 16),
                  _buildDialogTextField(stockCtrl, 'Stock', Icons.inventory,
                      readOnly: !isEdit,
                      keyboardType: TextInputType.number,
                      isStock: true),
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

                final updatedProduct = Product(
                  id: product.id,
                  name: nameCtrl.text.trim(),
                  description: descriptionCtrl.text.trim(),
                  price: double.parse(priceCtrl.text.trim()),
                  stock: int.parse(stockCtrl.text.trim()),
                  hsncode: hsnCodeCtrl.text.trim(),
                  tax_rate: int.parse(taxRateCtrl.text.trim()),
                );

                await ProductService.updateProduct(updatedProduct);
                await _loadProducts();
                if (context.mounted) Navigator.pop(context);
                _showSnackBar('Product updated successfully!');
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
    bool isPrice = false,
    bool isStock = false,
    bool isTaxRate = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: isPrice
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))]
          : (isStock || isTaxRate)
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          if (label.contains('Name')) return 'Please enter product name';
          if (label.contains('Price')) return 'Please enter price';
          if (label.contains('Stock')) return 'Please enter stock';
          if (label.contains('Tax')) return 'Please enter tax rate';
        }
        if (isPrice) {
          final price = double.tryParse(value!);
          if (price == null || price < 0) return 'Enter valid price';
        }
        if (isStock) {
          final stock = int.tryParse(value!);
          if (stock == null || stock < 0) return 'Enter valid stock';
        }
        if (isTaxRate) {
          final tax = int.tryParse(value!);
          if (tax == null || tax < 0 || tax > 100) return 'Tax must be 0-100';
        }
        return null;
      },
    );
  }

  Future<void> _confirmDelete(Product product) async {
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
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
      await ProductService.deleteProduct(product.id);
      await _loadProducts();
      _showSnackBar('Product deleted successfully!');
    }
  }

  Future<void> _exportToCSV() async {
    try {
      List<List<dynamic>> rows = [
        ['Name', 'HSN Code', 'Description', 'Price', 'Tax Rate', 'Stock'],
        ..._products.map((p) =>
            [p.name, p.hsncode, p.description, p.price, p.tax_rate, p.stock])
      ];
      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/products.csv');
      await file.writeAsString(csvData);
      await OpenFile.open(file.path);
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
          build: (context) => pw.Table.fromTextArray(
            context: context,
            data: [
              ['Name', 'HSN Code', 'Description', 'Price', 'Tax Rate', 'Stock'],
              ..._products.map((p) => [
                    p.name,
                    p.hsncode,
                    p.description,
                    p.price,
                    p.tax_rate,
                    p.stock
                  ]),
            ],
          ),
        ),
      );
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/products.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
      _showSnackBar('PDF exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting PDF: $e', isError: true);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentPage = 0;
      _searchQuery = query;
    });
    _loadProducts();
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        _sortBy = value;
        _currentPage = 0;
      });
      _loadProducts();
    }
  }

  void _toggleSortOrder() {
    setState(() => _isAscending = !_isAscending);
    _loadProducts();
  }

  void _changePage(int page) {
    setState(() => _currentPage = page);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalProducts / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _totalProducts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
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
                    child: SingleChildScrollView(child: _buildAddProductCard()),
                  ),
                  const SizedBox(width: 16),
                  // Right table panel
                  Expanded(child: _buildProductTable(totalPages)),
                ],
              ),
            ),
    );
  }

  Widget _buildAddProductCard() {
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
                Icon(Icons.add_box, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add New Product',
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
                  _buildFormField(
                      _nameController, 'Product Name', Icons.inventory_2,
                      maxLength: 100),
                  const SizedBox(height: 16),
                  _buildFormField(_hsnCodeController, 'HSN Code', Icons.qr_code,
                      maxLength: 100, required: false),
                  const SizedBox(height: 16),
                  _buildFormField(
                      _descriptionController, 'Description', Icons.description,
                      maxLines: 3, maxLength: 100, required: false),
                  const SizedBox(height: 16),
                  _buildFormField(
                      _priceController, 'Price (₹)', Icons.currency_rupee,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      isPrice: true),
                  const SizedBox(height: 16),
                  _buildFormField(
                      _taxRateController, 'Tax Rate (%)', Icons.percent,
                      keyboardType: TextInputType.number, isTaxRate: true),
                  const SizedBox(height: 16),
                  _buildFormField(_stockController, 'Stock', Icons.inventory,
                      keyboardType: TextInputType.number, isStock: true),
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
                          onPressed: _addProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
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
    IconData icon, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    bool required = true,
    bool isPrice = false,
    bool isStock = false,
    bool isTaxRate = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: isPrice
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))]
          : (isStock || isTaxRate)
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        counterText: '',
      ),
      validator: (value) {
        if (!required) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        if (isPrice) {
          final price = double.tryParse(value);
          if (price == null || price < 0) return 'Enter valid price';
        }
        if (isStock) {
          final stock = int.tryParse(value);
          if (stock == null || stock < 0) return 'Enter valid stock';
        }
        if (isTaxRate) {
          final tax = int.tryParse(value);
          if (tax == null || tax < 0 || tax > 100) {
            return 'Tax must be between 0-100';
          }
        }
        return null;
      },
    );
  }

  Widget _buildProductTable(int totalPages) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildTableHeader(),
          _buildSearchAndSort(),
          Expanded(
            child: _products.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                        child: _buildDataTable()),
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
              const Icon(Icons.inventory, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Products ($_allProductsCount)',
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
                labelText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: const Icon(Icons.arrow_drop_down),
                items: ['name', 'price', 'stock']
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                              'Sort by ${f[0].toUpperCase()}${f.substring(1)}'),
                        ))
                    .toList(),
                onChanged: _onSortChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _toggleSortOrder,
            icon:
                Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
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
          Icon(Icons.inventory_2_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first product to get started'
                : 'Try adjusting your search',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        Theme.of(context).primaryColor.withValues(alpha: 0.1),
      ),
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columns: const [
        DataColumn(
            label:
                Text('Sl. No', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('HSN Code',
                style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label:
                Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text('Tax Rate',
                style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label:
                Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(
            label:
                Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: List.generate(_products.length, (index) {
        final p = _products[index];
        final serialNumber = (_currentPage * _pageSize) + index + 1;
        return DataRow(
          color: WidgetStateProperty.all(
            index.isEven ? Colors.transparent : Colors.grey.shade50,
          ),
          cells: [
            DataCell(Text(serialNumber.toString())),
            DataCell(Text(
                p.name.length > 30 ? '${p.name.substring(0, 30)}...' : p.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(Text(p.hsncode)),
            DataCell(
              Tooltip(
                message: p.description,
                child: Text(
                  p.description.length > 30
                      ? '${p.description.substring(0, 30)}...'
                      : p.description,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${p.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${p.tax_rate}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.stock > 10
                      ? Colors.green.shade50
                      : p.stock > 0
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.stock.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: p.stock > 10
                        ? Colors.green.shade700
                        : p.stock > 0
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                  ),
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
                    onPressed: () => _showProductDialog(p, false),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.orange,
                    onPressed: () => _showProductDialog(p, true),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: () => _confirmDelete(p),
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
            'Showing ${_currentPage * _pageSize + 1} - ${(_currentPage * _pageSize + _pageSize).clamp(0, _totalProducts)} of $_totalProducts',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0
                    ? () => _changePage(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
