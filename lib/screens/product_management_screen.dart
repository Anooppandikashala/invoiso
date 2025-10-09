import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../models/product.dart';
import '../database/database_helper.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final dbHelper = DatabaseHelper();
  List<Product> products = [];

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 10;
  int _totalProducts = 0;
  int _allProdctsCount = 0;

  // Search and Sort
  String searchQuery = '';
  String sortBy = 'name';

  // Add Product Form Controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final hsnCodeController = TextEditingController();
  final taxRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    taxRateController.text = "18";
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    taxRateController.dispose();
    hsnCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final result = await dbHelper.getProductsPaginated(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
      query: searchQuery,
      orderBy: sortBy,
    );
    final count = await dbHelper.getProductCount(searchQuery);
    final allCount = await dbHelper.getTotalProductCount();
    setState(() {
      products = result;
      _totalProducts = count;
      _allProdctsCount = allCount;
    });
  }

  Future<void> _addProduct() async {
    // Trim spaces from inputs
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final priceText = priceController.text.trim();
    final stockText = stockController.text.trim();
    final hsnCode = hsnCodeController.text.trim();
    final taxText = taxRateController.text.trim();

    // Validation checks
    if (name.isEmpty) {
      _showError('Product name cannot be empty');
      return;
    }

    if (priceText.isEmpty) {
      _showError('Price cannot be empty');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      _showError('Enter a valid non-negative price');
      return;
    }

    final stock = int.tryParse(stockText);
    if (stock == null || stock < 0) {
      _showError('Enter a valid non-negative stock');
      return;
    }

    final taxRate = int.tryParse(taxText);
    if (taxRate == null || taxRate < 0 || taxRate > 100) {
      _showError('Enter a valid tax rate between 0 and 100');
      return;
    }

    // ✅ Passed all checks — insert the product
    final newProduct = Product(
      id: const Uuid().v4(),
      name: name,
      description: description,
      price: price,
      stock: stock,
      hsncode: hsnCode,
      tax_rate: taxRate,
    );

    await dbHelper.insertProduct(newProduct);
    await _loadProducts();

    // Clear inputs
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    stockController.clear();
    hsnCodeController.clear();
    taxRateController.clear();
    taxRateController.text = "18";

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully!')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showProductDialog(Product product, bool isViewOnly) {
    final nameCtrl = TextEditingController(text: product.name);
    final descriptionCtrl = TextEditingController(text: product.description);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final hsnCodeCtrl = TextEditingController(text: product.hsncode.toString());
    final taxRateCtrl = TextEditingController(text: product.tax_rate.toString());

    String? priceError;
    String? stockError;
    String? taxError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: isViewOnly ? const Text('View Product') : const Text('Edit Product'),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  maxLines: 2,
                  readOnly: isViewOnly ? true : false,
                  decoration: const InputDecoration(labelText: 'Name'),
                  maxLength: 100,
                ),
                TextField(
                  controller: descriptionCtrl,
                  readOnly: isViewOnly ? true : false,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLength: 100,
                ),
                TextField(
                  controller: priceCtrl,
                  readOnly: isViewOnly ? true : false,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    errorText: priceError,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                  ],
                ),
                TextField(
                  controller: taxRateCtrl,
                  readOnly: isViewOnly ? true : false,
                  decoration: InputDecoration(
                    labelText: 'Tax Rate',
                    errorText: taxError,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                  ],
                ),
                TextField(
                  controller: stockCtrl,
                  readOnly: isViewOnly ? true : false,
                  decoration: InputDecoration(
                    labelText: 'Stock',
                    errorText: stockError,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                  ],
                ),
              ],
            ),
          ),
          actions: !isViewOnly ? [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text);
                final stock = int.tryParse(stockCtrl.text);
                final taxRate = int.tryParse(taxRateCtrl.text);

                setState(() {
                  priceError = (price == null || price < 0) ? 'Enter valid non-negative price' : null;
                  stockError = (stock == null || stock < 0) ? 'Enter valid non-negative stock' : null;
                  taxError = (taxRate == null || taxRate > 100 || taxRate < 0) ? 'Enter valid tax rate (0-100)%' : null;
                });

                if (priceError != null || stockError != null || taxError != null) return;

                final updatedProduct = Product(
                  id: product.id,
                  name: nameCtrl.text,
                  description: descriptionCtrl.text,
                  price: price!,
                  stock: stock!,
                  hsncode: hsnCodeCtrl.text,
                  tax_rate: taxRate!
                );

                await dbHelper.updateProduct(updatedProduct);
                await _loadProducts();
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ] :
          [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    await dbHelper.deleteProduct(product.id);
    await _loadProducts();
  }

  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [
      ['Name', 'HSN Code' ,'Description', 'Price','Tax Rate', 'Stock'],
      ...products.map((p) => [p.name, p.hsncode ,p.description, p.price, p.tax_rate, p.stock])
    ];
    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/products.csv');
    await file.writeAsString(csvData);
    await OpenFile.open(file.path);
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Table.fromTextArray(
          context: context,
          data: [
            ['Name', 'HSN Code' ,'Description', 'Price', 'Tax Rate', 'Stock'],
            ...products.map((p) => [p.name,p.hsncode, p.description, p.price, p.tax_rate,p.stock]),
          ],
        ),
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/products.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  void _onSearchChanged(String query) {
    _currentPage = 0;
    searchQuery = query;
    _loadProducts();
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        sortBy = value;
        _currentPage = 0;
      });
      _loadProducts();
    }
  }

  void _nextPage() {
    if ((_currentPage + 1) * _pageSize < _totalProducts) {
      setState(() => _currentPage++);
      _loadProducts();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Add Product Form on the left
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: 300,maxWidth: 300),
              child: Card(
                color: Colors.white,
                elevation: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Add New Product',
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
                        children: [
                          TextField(controller: nameController,
                              decoration: const InputDecoration(labelText: 'Name'),
                              maxLength: 100 ,
                              style: TextStyle(fontSize: 16,color: Colors.black)),
                          TextField(controller: hsnCodeController,
                              decoration: const InputDecoration(labelText: 'HSN Code'),
                              maxLength: 100 ,
                              style: TextStyle(fontSize: 16,color: Colors.black)),
                          TextField(controller: descriptionController,
                              decoration: const InputDecoration(labelText: 'Description'),
                              maxLength: 100 ,
                              style: TextStyle(fontSize: 16,color: Colors.black)),
                          TextField(controller: priceController,
                            decoration: const InputDecoration(labelText: 'Price'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                            ],),
                          TextField(controller: taxRateController,
                            decoration: const InputDecoration(labelText: 'Tax Rate'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                            ],),
                          TextField(controller: stockController,
                            decoration: const InputDecoration(labelText: 'Stock'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                            ],),
                          AppSpacing.hMedium,
                          Center(
                              child: ElevatedButton(
                                  onPressed: _addProduct,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Add Product'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.wMedium,
            // Right side with table and controls
            Expanded(
              child: Card(
                elevation: 2,
                child: Column(
                  children: [
                    // Header row with actions
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
                                  'Products ($_allProdctsCount)',
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
                                ElevatedButton.icon(icon: const Icon(Icons.download), label: const Text('Export CSV'), onPressed: _exportToCSV),
                                AppSpacing.wMedium,
                                ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF'), onPressed: _exportToPDF),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search & Sort
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search products...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          AppSpacing.wMedium,
                          DropdownButton<String>(
                            value: sortBy,
                            items: ['name', 'price', 'stock'].map((f) => DropdownMenuItem(value: f, child: Text('Sort by ${f[0].toUpperCase()}${f.substring(1)}'))).toList(),
                            onChanged: _onSortChanged,
                          ),
                          AppSpacing.wMedium,
                        ],
                      ),
                    ),
                    AppSpacing.hMedium,

                    // Product Table
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                              return Theme.of(context).primaryColor; // Set your desired color here
                            },
                          ),
                          headingTextStyle: TextStyle(color: Colors.white),
                          columns: const [
                            DataColumn(label: Text('Sl. No')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('HSN Code')),
                            DataColumn(label: Text('Description')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Tax Rate')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: List.generate(products.length, (index) {
                            final p = products[index];
                            final serialNumber = (_currentPage * _pageSize) + index + 1; // 👈 For paginated Sl. No
                            return DataRow(
                                color: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                    return (index+1).isEven ? Colors.grey.shade200 : Colors.white;
                                  },
                                ),
                                cells: [
                              DataCell(Text(serialNumber.toString())), // 👈 Serial number
                              DataCell(Text(p.name)),
                              DataCell(Text(p.hsncode)),
                              DataCell(Text(
                                p.description.length > 50
                                  ? '${p.description.substring(0, 50)}...'
                                  : p.description,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1, // Show up to 2 lines, then truncate
                                softWrap: true,)),
                              DataCell(Text('Rs ${p.price.toStringAsFixed(2)}')),
                              DataCell(Text(p.tax_rate.toString())),
                              DataCell(Text(p.stock.toString())),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.visibility,color: Colors.green,), onPressed: () => _showProductDialog(p,true)),
                                  IconButton(icon: const Icon(Icons.edit,color: Colors.blue,), onPressed: () => _showProductDialog(p,false)),
                                  IconButton(icon: const Icon(Icons.delete,color: Colors.red,), onPressed: () => _deleteProduct(p)),
                                ],
                              )),
                            ]);
                          }),
                        ),
                      ),
                    ),

                    // Pagination controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(onPressed: _prevPage, icon: const Icon(Icons.chevron_left)),
                        Text('Page ${_currentPage + 1} of ${(_totalProducts / _pageSize).ceil()}'),
                        IconButton(onPressed: _nextPage, icon: const Icon(Icons.chevron_right)),
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
