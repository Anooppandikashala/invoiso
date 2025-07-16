import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../services/invoice_services.dart';

class InvoiceManagement extends StatefulWidget {
  @override
  _InvoiceManagementState createState() => _InvoiceManagementState();
}

class _InvoiceManagementState extends State<InvoiceManagement> {
  final dbHelper = DatabaseHelper();
  Customer? selectedCustomer;
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<InvoiceItem> invoiceItems = [];
  final notesController = TextEditingController();
  final searchController = TextEditingController();
  final customerSearchController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final taxRateController = TextEditingController();
  double taxRate = 0.1;
  Invoice? _invoice;

  @override
  void initState() {
    super.initState();
    taxRateController.text = (taxRate * 100).toStringAsFixed(1);
    _loadCustomersAndProducts();
  }

  Future<void> _loadCustomersAndProducts() async {
    final c = await dbHelper.getAllCustomers();
    final p = await dbHelper.getAllProducts();
    setState(() {
      customers = c;
      filteredCustomers = List.from(c);
      products = p;
      filteredProducts = List.from(p);
    });
  }

  void addInvoiceProductPrompt(Product product) {
    final quantityController = TextEditingController(text: '1');
    final discountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(labelText: 'Discount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              addInvoiceProduct(
                InvoiceItem(
                  product: product,
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  discount: double.tryParse(discountController.text) ?? 0.0,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void addInvoiceProduct(InvoiceItem invoiceItem) {
    final exists = invoiceItems.any((item) => item.product.id == invoiceItem.product.id);
    setState(() {
      invoiceItems.insert(0, invoiceItem);
    });
    return;
    if (exists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate Product'),
          content: const Text('This product has already been added to the invoice.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        invoiceItems.insert(0, invoiceItem);
      });
    }
  }

  Future<void> _createInvoice() async {
    if (invoiceItems.isNotEmpty) {
      final invoiceId = const Uuid().v4();
      final invoice = Invoice(
        id: invoiceId,
        customer: selectedCustomer ?? Customer(
          id: const Uuid().v4(),
          name: nameController.text,
          email: emailController.text,
          phone: phoneController.text,
          address: addressController.text,
        ),
        items: List.from(invoiceItems),
        date: DateTime.now(),
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: taxRate,
      );

      await dbHelper.insertInvoice(invoice);

      setState(() {
        _invoice = null;
        selectedCustomer = null;
        invoiceItems.clear();
        notesController.clear();
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        addressController.clear();
        taxRate = 0.1;
        taxRateController.text = (taxRate * 100).toStringAsFixed(1);
        _invoice = invoice;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created successfully!')),
      );
    }
  }

  void _editInvoiceItem(int index) {
    final item = invoiceItems[index];
    final quantityController = TextEditingController(text: item.quantity.toString());
    final discountController = TextEditingController(text: item.discount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: discountController,
                decoration: const InputDecoration(labelText: 'Discount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final updatedItem = InvoiceItem(
                product: item.product,
                quantity: int.tryParse(quantityController.text) ?? item.quantity,
                discount: double.tryParse(discountController.text) ?? item.discount,
              );

              setState(() {
                invoiceItems[index] = updatedItem;
              });

              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = products
          .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      filteredCustomers = customers
          .where((customer) => customer.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _selectCustomer(Customer? customer) {
    setState(() {
      selectedCustomer = customer;
      nameController.text = customer?.name ?? '';
      emailController.text = customer?.email ?? '';
      phoneController.text = customer?.phone ?? '';
      addressController.text = customer?.address ?? '';
    });
  }

  Widget _customerSearchView()
  {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: customerSearchController,
              onChanged: _filterCustomers,
              decoration: const InputDecoration(
                labelText: 'Search Customer',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: filteredCustomers.length > 5 ? 5 : filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = filteredCustomers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text(customer.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _selectCustomer(customer),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productSearchView()
  {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              onChanged: _filterProducts,
              decoration: const InputDecoration(
                labelText: 'Search Product',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 500,
            child: ListView.builder(
              itemCount: filteredProducts.length > 6 ? 6 : filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('Price: ${product.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => addInvoiceProductPrompt(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerDetailsForm()
  {
    return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
        );
  }

  Widget _invoiceItems(
      double tax,
      double subtotal,
      double total)
  {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
                    Text('Tax: ${tax.toStringAsFixed(2)}'),
                    Text('Total: ${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = invoiceItems[index];
                  return ListTile(
                    title: Text(item.product.name),
                    subtitle: Text('Qty: ${item.quantity}, Discount: ${item.discount.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.total.toStringAsFixed(2)),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editInvoiceItem(index),
                          tooltip: 'Edit Item',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              invoiceItems.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = invoiceItems.fold(0.0, (sum, item) => sum + item.total);
    double tax = subtotal * taxRate;
    double total = subtotal + tax;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight-20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Column(
                        children: [
                          Flexible(
                                flex: 1,
                                child: _customerSearchView(),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                              flex: 2,
                              child: _productSearchView()
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Create New Invoice', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _customerDetailsForm(),
                          const SizedBox(height: 8),
                          TextField(
                            controller: notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: taxRateController,
                            decoration: const InputDecoration(
                              labelText: 'Tax Rate (%)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                taxRate = double.tryParse(value) ?? 10;
                                taxRate = taxRate / 100;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _invoiceItems(tax,subtotal,total),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Flexible(
                                  flex:3,
                                  child: ElevatedButton(
                                    onPressed: invoiceItems.isNotEmpty ? _createInvoice : null,
                                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity,50)),
                                    child: const Text('Create Invoice'),
                                  ),
                                ),
                                Flexible(
                                  flex: 1,
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(icon: const Icon(Icons.visibility),
                                            onPressed: _invoice != null
                                                ? () => InvoiceServices.showInvoiceDetails(context, _invoice!) : null,
                                            tooltip: 'View Details'),
                                        SizedBox(width: 30,),
                                        IconButton(icon: const Icon(Icons.picture_as_pdf),
                                            onPressed: _invoice != null ? () => InvoiceServices.previewPDF(context,_invoice!) : null,
                                            tooltip: 'Preview PDF'),
                                        SizedBox(width: 30,),
                                        IconButton(icon: const Icon(Icons.print),
                                            onPressed: _invoice != null ? () => InvoiceServices.generatePDF(context,_invoice!) : null,
                                            tooltip: 'Print PDF'),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
