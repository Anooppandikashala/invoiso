import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/invoiso_colors.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../common.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../utils/formatters.dart';

class ProductManagementScreen extends StatefulWidget {
  final User user;
  const ProductManagementScreen({super.key, required this.user});

  @override
  State<ProductManagementScreen> createState() =>
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
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _horizontalScrollController = ScrollController();
  Timer? _searchDebounce;

  // Form controllers
  final _nameController = TextEditingController();
  final _defaultDiscountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _currencySymbol = '₹';
  BusinessType _businessType = BusinessType.both;
  String _typeFilter = 'both'; // 'both' | 'product' | 'service'
  String _newItemType = 'product'; // type for the add-product form

  static const _csvMaxRows = 500;
  static const _csvHeaders = [
    'name',
    'hsn_code',
    'description',
    'price',
    'tax_rate',
    'stock'
  ];

  @override
  void initState() {
    super.initState();
    _taxRateController.text = "18";
    _loadBusinessType();
    _loadProducts();
    _loadCurrency();
  }

  Future<void> _loadBusinessType() async {
    final bt = await SettingsService.getBusinessType();
    setState(() {
      _businessType = bt;
      _typeFilter = bt == BusinessType.both ? 'both' : bt.key;
      _newItemType = bt == BusinessType.service ? 'service' : 'product';
    });
  }

  Future<void> _loadCurrency() async {
    final currency = await SettingsService.getCurrency();
    setState(() {
      _currencySymbol = currency.symbol;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _defaultDiscountController.dispose();
    _stockController.dispose();
    _taxRateController.dispose();
    _hsnCodeController.dispose();
    _searchFocusNode.dispose();
    _horizontalScrollController.dispose();
    _searchDebounce?.cancel();
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
          orderASC: _isAscending,
          type: _typeFilter);
      final count =
          await ProductService.getProductCount(_searchQuery, _typeFilter);
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
        type: _newItemType,
        defaultDiscount:
            double.tryParse(_defaultDiscountController.text.trim()) ?? 0.0,
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
    _defaultDiscountController.clear();
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showProductDialog(Product product, bool isEdit) {
    //final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product.name);
    final descriptionCtrl = TextEditingController(text: product.description);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final hsnCodeCtrl = TextEditingController(text: product.hsncode);
    final taxRateCtrl =
        TextEditingController(text: product.tax_rate.toString());
    final defaultDiscountCtrl = TextEditingController(
        text: product.defaultDiscount > 0
            ? product.defaultDiscount.toString()
            : '');
    final dialogFormKey = GlobalKey<FormState>();
    String dialogItemType = product.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.visibility,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Product/Service' : 'View Product/Service'),
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
                    if (_businessType == BusinessType.both && isEdit) ...[
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'product',
                              label: Text('Product'),
                              icon: Icon(Icons.inventory_2_outlined, size: 16)),
                          ButtonSegment(
                              value: 'service',
                              label: Text('Service'),
                              icon: Icon(Icons.design_services_outlined,
                                  size: 16)),
                        ],
                        selected: {dialogItemType},
                        onSelectionChanged: (val) =>
                            setDialogState(() => dialogItemType = val.first),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_businessType == BusinessType.both) ...[
                      Chip(
                        avatar: Icon(
                            dialogItemType == 'service'
                                ? Icons.design_services_outlined
                                : Icons.inventory_2_outlined,
                            size: 16),
                        label: Text(dialogItemType == 'service'
                            ? 'Service'
                            : 'Product'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDialogTextField(nameCtrl, 'Name', Icons.inventory_2,
                        readOnly: !isEdit, maxLength: 100),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                        hsnCodeCtrl, 'HSN Code', Icons.qr_code,
                        readOnly: !isEdit, maxLength: 100),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                        descriptionCtrl, 'Description', Icons.description,
                        readOnly: !isEdit, maxLines: 3, maxLength: 100),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                        priceCtrl, 'Price', Icons.attach_money,
                        readOnly: !isEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        isPrice: true,
                        prefixText: '$_currencySymbol '),
                    const SizedBox(height: 16),
                    _buildDialogTextField(
                        defaultDiscountCtrl, 'Default Discount', Icons.discount,
                        readOnly: !isEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        isPrice: true,
                        prefixText: '$_currencySymbol '),
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
                    type: dialogItemType,
                    defaultDiscount:
                        double.tryParse(defaultDiscountCtrl.text.trim()) ?? 0.0,
                  );

                  await ProductService.updateProduct(updatedProduct);
                  await _loadProducts();
                  if (context.mounted) Navigator.pop(context);
                  _showSnackBar('Product/Service updated successfully!');
                },
                icon: const Icon(Icons.save),
                label: const Text('Update'),
              ),
          ],
        ),
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
    String? prefixText,
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
        prefixIcon: prefixText == null ? Icon(icon) : null,
        prefixText: prefixText,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
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

  // ── Sample CSV ────────────────────────────────────────────────────────────

  Future<void> _downloadSampleCSV() async {
    const sample =
        '"name","hsn_code","description","price","tax_rate","stock"\n'
        '"Wireless Mouse","84716010","Ergonomic wireless mouse","599.00","18","50"\n'
        '"USB Hub","84734000","4-port USB 3.0 hub","299.00","18","100"\n';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Sample CSV',
      fileName: 'products_sample.csv',
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

  Future<void> _showImportDialog() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            const Text('Import Products from CSV'),
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
                Table(
                  border: TableBorder.all(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.4),
                    1: FlexColumnWidth(0.7),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        _TableHeader('Column'),
                        _TableHeader('Required'),
                        _TableHeader('Description'),
                      ],
                    ),
                    _csvRuleRow('name', 'Yes', 'Product name'),
                    _csvRuleRow('price', 'Yes', 'Unit price (numeric)'),
                    _csvRuleRow('hsn_code', 'No', 'HSN / SAC code'),
                    _csvRuleRow('description', 'No', 'Short description'),
                    _csvRuleRow('tax_rate', 'No', 'Tax % (0–100), default 0'),
                    _csvRuleRow('stock', 'No', 'Stock quantity, default 0'),
                  ],
                ),
                const SizedBox(height: 16),
                _ruleNote(Icons.info_outline,
                    'Maximum $_csvMaxRows rows per import.'),
                _ruleNote(Icons.info_outline,
                    'Duplicates are detected by product name (case-insensitive). You will be asked to overwrite or skip each one.'),
                _ruleNote(Icons.info_outline,
                    'Rows missing name or price are skipped and reported.'),
                _ruleNote(Icons.info_outline,
                    'UTF-8 encoding recommended. Excel BOM is handled automatically.'),
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

  static TableRow _csvRuleRow(String col, String req, String desc) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(col,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            req,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: req == 'Yes' ? Colors.red.shade700 : Colors.grey.shade600,
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

  static Widget _ruleNote(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  Future<void> _importFromCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Select Product CSV',
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await File(result.files.single.path!).readAsBytes();
      // Strip UTF-8 BOM if present
      final content = utf8.decode(
        bytes.length >= 3 &&
                bytes[0] == 0xEF &&
                bytes[1] == 0xBB &&
                bytes[2] == 0xBF
            ? bytes.sublist(3)
            : bytes,
      );

      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) {
        _showSnackBar('CSV file is empty.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Parse and validate headers
      final headers =
          rows.first.map((h) => h.toString().trim().toLowerCase()).toList();

      if (!headers.contains('name')) {
        _showSnackBar('CSV missing required column: "name"', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      if (!headers.contains('price')) {
        _showSnackBar('CSV missing required column: "price"', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      for (final col in headers) {
        if (!_csvHeaders.contains(col)) {
          _showSnackBar(
              'Unknown column "$col". Expected: ${_csvHeaders.join(', ')}',
              isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      final dataRows = rows.skip(1).toList();

      if (dataRows.length > _csvMaxRows) {
        _showSnackBar(
            'CSV has ${dataRows.length} rows. Maximum is $_csvMaxRows. Please split the file.',
            isError: true);
        setState(() => _isLoading = false);
        return;
      }

      String getField(List<dynamic> row, String col) {
        final i = headers.indexOf(col);
        return i < 0 || i >= row.length ? '' : row[i].toString().trim();
      }

      final List<Product> valid = [];
      final List<Product> duplicates = [];
      final List<String> errors = [];

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final name = getField(row, 'name');
        final priceStr = getField(row, 'price');

        if (name.isEmpty) {
          errors.add('Row ${i + 2}: missing name — skipped');
          continue;
        }
        final price = double.tryParse(priceStr);
        if (price == null || price < 0) {
          errors.add('Row ${i + 2}: invalid price "$priceStr" — skipped');
          continue;
        }

        final taxStr = getField(row, 'tax_rate');
        final stockStr = getField(row, 'stock');
        final taxRate = taxStr.isEmpty ? 0 : (int.tryParse(taxStr) ?? 0);
        final stock = stockStr.isEmpty ? 0 : (int.tryParse(stockStr) ?? 0);

        final existing = await ProductService.findDuplicateByName(name);
        final product = Product(
          id: existing?.id ?? const Uuid().v4(),
          name: name,
          hsncode: getField(row, 'hsn_code'),
          description: getField(row, 'description'),
          price: price,
          tax_rate: taxRate.clamp(0, 100),
          stock: stock < 0 ? 0 : stock,
        );

        if (existing != null) {
          duplicates.add(product);
        } else {
          valid.add(product);
        }
      }

      setState(() => _isLoading = false);

      if (!mounted) return;
      await _showImportPreviewDialog(valid, duplicates, errors);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error reading CSV: $e', isError: true);
    }
  }

  Future<void> _showImportPreviewDialog(
    List<Product> newProducts,
    List<Product> duplicates,
    List<String> errors,
  ) async {
    final overwriteFlags = List<bool>.filled(duplicates.length, false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total =
              newProducts.length + overwriteFlags.where((f) => f).length;

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
                          label: Text('${newProducts.length} new'),
                          backgroundColor: Colors.green.shade100,
                          avatar: const Icon(Icons.add_box_outlined, size: 16),
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
                            child: Text('Duplicates (matched by name):',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) {
                                overwriteFlags[i] = true;
                              }
                            }),
                            child: const Text('Overwrite All'),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) {
                                overwriteFlags[i] = false;
                              }
                            }),
                            child: const Text('Skip All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(duplicates.length, (i) {
                        final p = duplicates[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(p.name),
                            subtitle: Text(
                                '$_currencySymbol${p.price.toStringAsFixed(2)} · HSN: ${p.hsncode.isEmpty ? '—' : p.hsncode}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Skip',
                                    style: TextStyle(fontSize: 12)),
                                Switch(
                                  value: overwriteFlags[i],
                                  onChanged: (v) => setDialogState(
                                      () => overwriteFlags[i] = v),
                                ),
                                const Text('Overwrite',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Skipped rows (errors):',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      ...errors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $e',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          )),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Will import $total product${total == 1 ? '' : 's'}.',
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
                        await _executeImport(
                            newProducts, duplicates, overwriteFlags);
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
    List<Product> newProducts,
    List<Product> duplicates,
    List<bool> overwriteFlags,
  ) async {
    setState(() => _isLoading = true);
    try {
      if (newProducts.isNotEmpty) {
        await ProductService.insertBatch(newProducts);
      }
      for (int i = 0; i < duplicates.length; i++) {
        if (overwriteFlags[i]) {
          await ProductService.updateProduct(duplicates[i]);
        }
      }
      await _loadProducts();
      final imported =
          newProducts.length + overwriteFlags.where((f) => f).length;
      _showSnackBar(
          'Imported $imported product${imported == 1 ? '' : 's'} successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Import error: $e', isError: true);
    }
  }

  // ── Delete All ────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAll() async {
    if (_allProductsCount == 0) {
      _showSnackBar('No products to delete.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Products'),
        content: Text(
          'This will permanently delete all $_allProductsCount '
          'product${_allProductsCount == 1 ? '' : 's'}. '
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
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await ProductService.deleteAllProducts();
      await _loadProducts();
      _showSnackBar('All products deleted.');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error deleting products: $e', isError: true);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final allProducts = await ProductService.getAllProducts();
      final List<List<dynamic>> rows = [
        ['name', 'hsn_code', 'description', 'price', 'tax_rate', 'stock'],
        ...allProducts.map((p) =>
            [p.name, p.hsncode, p.description, p.price, p.tax_rate, p.stock]),
      ];
      final csvData = buildQuotedCsv(rows);
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Products CSV',
        fileName: 'products.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(utf8.encode('\uFEFF$csvData'));
      _showSnackBar('CSV exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting CSV: $e', isError: true);
    }
  }

  Future<void> _exportToPDF() async {
    // Ask user: current page or all products
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export to PDF'),
        content: Text(
          'Export the current page ($_pageSize products) or all $_allProductsCount products?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'page'),
            child: const Text('Current Page'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: const Text('All Products'),
          ),
        ],
      ),
    );
    if (choice == null) return;

    try {
      final productsToExport =
          choice == 'all' ? await ProductService.getAllProducts() : _products;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.TableHelper.fromTextArray(
            context: context,
            data: [
              ['Name', 'HSN Code', 'Description', 'Price', 'Tax Rate', 'Stock'],
              ...productsToExport.map((p) => [
                    p.name,
                    p.hsncode,
                    p.description,
                    p.price.toStringAsFixed(2),
                    '${p.tax_rate}%',
                    p.stock,
                  ]),
            ],
          ),
        ),
      );

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Products PDF',
        fileName: 'products.pdf',
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

  void _onSearchChanged(String query) {
    setState(() {
      _currentPage = 0;
      _searchQuery = query;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadProducts);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product/Service Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(child: _buildAddProductCard()),
                  ),
                  const SizedBox(width: 16),
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
              gradient:
                  ProductManagementScreenColors.topBarBackgroundGradientColor,
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
                    'Add New Product/Service',
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
                  if (_businessType == BusinessType.both) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'product',
                            label: Text('Product'),
                            icon: Icon(Icons.inventory_2_outlined, size: 16)),
                        ButtonSegment(
                            value: 'service',
                            label: Text('Service'),
                            icon:
                                Icon(Icons.design_services_outlined, size: 16)),
                      ],
                      selected: {_newItemType},
                      onSelectionChanged: (val) =>
                          setState(() => _newItemType = val.first),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildFormField(_nameController, 'Name', Icons.inventory_2,
                      maxLength: 100),
                  const SizedBox(height: 16),
                  _buildFormField(_hsnCodeController, 'HSN Code', Icons.qr_code,
                      maxLength: 100, required: false),
                  const SizedBox(height: 16),
                  _buildFormField(
                      _descriptionController, 'Description', Icons.description,
                      maxLines: 3, maxLength: 100, required: false),
                  const SizedBox(height: 16),
                  _buildFormField(_priceController, 'Price', Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      isPrice: true,
                      prefixText: '$_currencySymbol '),
                  const SizedBox(height: 16),
                  _buildFormField(_defaultDiscountController,
                      'Default Discount', Icons.discount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      isPrice: true,
                      required: false,
                      prefixText: '$_currencySymbol '),
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
                          label: Text(_newItemType == 'service'
                              ? 'Add Service'
                              : 'Add Product'),
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
    String? prefixText,
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
        prefixIcon: prefixText == null ? Icon(icon) : null,
        prefixText: prefixText,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
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
          if (_businessType == BusinessType.both)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'both', label: Text('All')),
                  ButtonSegment(
                      value: 'product',
                      label: Text('Products'),
                      icon: Icon(Icons.inventory_2_outlined, size: 16)),
                  ButtonSegment(
                      value: 'service',
                      label: Text('Services'),
                      icon: Icon(Icons.design_services_outlined, size: 16)),
                ],
                selected: {_typeFilter},
                onSelectionChanged: (val) {
                  setState(() {
                    _typeFilter = val.first;
                    _currentPage = 0;
                  });
                  _loadProducts();
                },
              ),
            ),
          _buildSearchAndSort(),
          Expanded(
            child: _products.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    notificationPredicate: (notif) => notif.depth == 1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: _buildDataTable(),
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
    String headText = (_typeFilter == "both"
        ? 'Products/Services'
        : (_typeFilter == "product")
            ? 'Products($_allProductsCount)'
            : 'Services($_allProductsCount)');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ProductManagementScreenColors.topBarBackgroundGradientColor,
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
                headText,
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
                          Text('Delete All Products',
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
                labelText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.xsmall)),
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
      columns: [
        const DataColumn(
            label:
                Text('Sl. No', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        if (_businessType == BusinessType.both)
          const DataColumn(
              label:
                  Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label: Text('HSN Code',
                style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label: Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label:
                Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label:
            Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label: Text('Tax Rate',
                style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label:
                Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
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
            if (_businessType == BusinessType.both)
              DataCell(Tooltip(
                message: p.type == 'service' ? 'Service' : 'Product',
                child: Chip(
                  avatar: Icon(
                    p.type == 'service'
                        ? Icons.design_services_outlined
                        : Icons.inventory_2_outlined,
                    size: 14,
                  ),
                  label: Text(p.type == 'service' ? 'Service' : 'Product',
                      style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              )),
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
                  '$_currencySymbol${p.price.toStringAsFixed(2)}',
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
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currencySymbol${p.defaultDiscount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
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
                  if (widget.user.isAdmin())
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
