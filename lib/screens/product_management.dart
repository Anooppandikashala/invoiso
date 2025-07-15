import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../models/product.dart';
import '../database/database_helper.dart';

class ProductManagement extends StatefulWidget {
  @override
  _ProductManagementState createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final dbHelper = DatabaseHelper();
  List<Product> products = [];

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 10;
  int _totalProducts = 0;

  // Search and Sort
  String searchQuery = '';
  String sortBy = 'name';

  // Add Product Form Controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final result = await dbHelper.getProductsPaginated(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
      query: searchQuery,
      orderBy: sortBy,
    );
    final count = await dbHelper.getProductCount(searchQuery);
    setState(() {
      products = result;
      _totalProducts = count;
    });
  }

  Future<void> _addProduct() async {
    final newProduct = Product(
      id: const Uuid().v4(),
      name: nameController.text,
      description: descriptionController.text,
      price: double.tryParse(priceController.text) ?? 0.0,
      stock: int.tryParse(stockController.text) ?? 0,
    );
    await dbHelper.insertProduct(newProduct);
    await _loadProducts();
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    stockController.clear();
  }

  void _showProductDialog(Product product) {
    final nameCtrl = TextEditingController(text: product.name);
    final descriptionCtrl = TextEditingController(text: product.description);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: descriptionCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedProduct = Product(
                id: product.id,
                name: nameCtrl.text,
                description: descriptionCtrl.text,
                price: double.tryParse(priceCtrl.text) ?? 0.0,
                stock: int.tryParse(stockCtrl.text) ?? 0,
              );
              await dbHelper.updateProduct(updatedProduct);
              await _loadProducts();
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    await dbHelper.deleteProduct(product.id);
    await _loadProducts();
  }

  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [
      ['Name', 'Description', 'Price', 'Stock'],
      ...products.map((p) => [p.name, p.description, p.price, p.stock])
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
            ['Name', 'Description', 'Price', 'Stock'],
            ...products.map((p) => [p.name, p.description, p.price, p.stock]),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Product Form on the left
          SizedBox(
            width: 400,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                    TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                    TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    Center(child: ElevatedButton(onPressed: _addProduct, child: const Text('Add'))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Right side with table and controls
          Expanded(
            child: Column(
              children: [
                // Header row with actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Product Management',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ElevatedButton.icon(icon: const Icon(Icons.download), label: const Text('Export CSV'), onPressed: _exportToCSV),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF'), onPressed: _exportToPDF),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Search & Sort
                Row(
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
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: sortBy,
                      items: ['name', 'price', 'stock'].map((f) => DropdownMenuItem(value: f, child: Text('Sort by ${f[0].toUpperCase()}${f.substring(1)}'))).toList(),
                      onChanged: _onSortChanged,
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Table
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: products.map((p) {
                        return DataRow(cells: [
                          DataCell(Text(p.name)),
                          DataCell(Text(p.description)),
                          DataCell(Text('\$${p.price.toStringAsFixed(2)}')),
                          DataCell(Text(p.stock.toString())),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showProductDialog(p)),
                              IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteProduct(p)),
                            ],
                          )),
                        ]);
                      }).toList(),
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
        ],
      ),
    );
  }
}
