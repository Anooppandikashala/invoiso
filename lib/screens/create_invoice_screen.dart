import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../services/invoice_services.dart';
import 'package:invoiso/constants.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
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
  final gstinController = TextEditingController();
  final taxRateController = TextEditingController();

  final _customerScrollController = ScrollController();
  final _productScrollController = ScrollController();
  final _invoiceItemsScrollController = ScrollController();

  bool isTaxEnabled = true;

  String invoiceType = 'Invoice'; // default value
  double taxRate = Tax.defaultTaxRate;
  Invoice? _invoice;

  String currentInvoiceNumber = "";

  @override
  void initState() {
    super.initState();
    taxRateController.text = (taxRate * 100).toStringAsFixed(1);
    _loadCustomersAndProducts();
  }

  @override
  void dispose() {
    notesController.dispose();
    searchController.dispose();
    customerSearchController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    taxRateController.dispose();
    _customerScrollController.dispose();
    _productScrollController.dispose();
    _invoiceItemsScrollController.dispose();
    gstinController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomersAndProducts() async {
    final c = await dbHelper.getAllCustomers();
    final p = await dbHelper.getAllProducts();
    final String invNumber = await InvoiceServices.generateNextInvoiceNumber();
    setState(() {
      customers = c;
      filteredCustomers = List.from(c);
      products = p;
      filteredProducts = List.from(p);
      currentInvoiceNumber = invNumber;
    });
  }

  void addInvoiceProductPrompt(Product product) {
    final quantityController = TextEditingController(text: '1');
    final discountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${product.name}'),
        content: SizedBox(
          width : MediaQuery.sizeOf(context).width *0.2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              AppSpacing.hMedium,
              TextField(
                controller: discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
    final exists =
        invoiceItems.any((item) => item.product.id == invoiceItem.product.id);

    if (exists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplicate Product'),
          content:
              const Text('This product has already been added to the invoice.'),
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
    if(nameController.text.isEmpty)
    {
      //nameController.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give customer name')),
      );
      return;
    }
    if (invoiceItems.isNotEmpty) {
      final invoiceId = await InvoiceServices.generateNextInvoiceNumber();
      final invoice = Invoice(
        id: invoiceId,
        customer: selectedCustomer ??
            Customer(
              id: const Uuid().v4(),
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              address: addressController.text,
              gstin: gstinController.text
            ),
        items: List.from(invoiceItems),
        date: DateTime.now(),
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: taxRate,
        type: invoiceType
      );

      await dbHelper.insertInvoice(invoice);

      setState(() {
        _invoice = invoice;
        selectedCustomer = null;
        invoiceItems.clear();
        notesController.clear();
        nameController.clear();
        emailController.clear();
        phoneController.clear();
        addressController.clear();
        gstinController.clear();
        taxRate = Tax.defaultTaxRate;
        taxRateController.text = (taxRate * 100).toStringAsFixed(1);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created successfully!')),
      );
    }
  }

  void _editInvoiceItem(int index) {
    final item = invoiceItems[index];
    final quantityController =
        TextEditingController(text: item.quantity.toString());
    final discountController =
        TextEditingController(text: item.discount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item',style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width*0.2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              AppSpacing.hMedium,
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              AppSpacing.hMedium,
              TextField(
                controller: discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedItem = InvoiceItem(
                product: item.product,
                quantity:
                    int.tryParse(quantityController.text) ?? item.quantity,
                discount:
                    double.tryParse(discountController.text) ?? item.discount,
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
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      filteredCustomers = customers
          .where((customer) =>
              customer.name.toLowerCase().contains(query.toLowerCase()))
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
      gstinController.text = customer?.gstin ?? '';
    });
  }

  Widget _customerSearchView() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: customerSearchController,
                  onChanged: _filterCustomers,
                  decoration: const InputDecoration(
                    labelText: 'Search Customer',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.sizeOf(context).height*0.25,
            child: Scrollbar(
              controller: _customerScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: ListView.builder(
                itemCount:
                    filteredCustomers.length > 5 ? 5 : filteredCustomers.length,
                controller: _customerScrollController,
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  return ListTile(
                    title: Text(customer.name),
                    subtitle: Text(customer.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle),
                      onPressed: () => _selectCustomer(customer),
                      tooltip: 'Select Customer',
                    ),
                    onTap: () => _selectCustomer(customer),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productSearchView() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: searchController,
                  onChanged: _filterProducts,
                  decoration: const InputDecoration(
                    labelText: 'Search Product',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.sizeOf(context).height*0.35,
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              controller: _productScrollController,
              child: ListView.builder(
                itemCount:
                    filteredProducts.length > 8 ? 8 : filteredProducts.length,
                controller: _productScrollController,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle:
                        Text('Price: ${product.price.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () => addInvoiceProductPrompt(product),
                      tooltip: 'Add to Invoice',
                    ),
                    onTap: () => addInvoiceProductPrompt(product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceDetailsForm() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$invoiceType Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.hMedium,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: currentInvoiceNumber),
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: '$invoiceType Number',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                AppSpacing.wMedium,
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: DateTime.now().toString().substring(0, 10)),
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date',
                      border: OutlineInputBorder(),
                    ),
                  ),
                )
              ],
            ),
            AppSpacing.hMedium,
            DropdownButtonFormField<String>(
              value: invoiceType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
                DropdownMenuItem(value: 'Quotation', child: Text('Quotation')),
              ],
              onChanged: (value) {
                if (value != null)
                {
                  resetValues(value);
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> resetValues(String invoiceType_) async
  {
    final invType = await InvoiceServices.generateNextInvoiceNumber();
    setState(() {
      invoiceType = invoiceType_;
      currentInvoiceNumber = invType;
      _invoice = null;
    });
  }

  Widget _customerDetailsForm() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.hMedium,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                AppSpacing.wMedium,
                Expanded(
                  child: TextField(
                    controller: gstinController,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                AppSpacing.wMedium,
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.hMedium,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                AppSpacing.wMedium,
                Expanded(
                  child: TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _invoiceItems(double tax, double subtotal, double total) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${invoiceType} Items',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.sizeOf(context).height*0.35,
            child: invoiceItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _invoiceItemsScrollController,
                    child: ListView.builder(
                      controller: _invoiceItemsScrollController,
                      itemCount: invoiceItems.length,
                      itemBuilder: (context, index) {
                        final item = invoiceItems[index];
                        return ListTile(
                          leading: Text("${index+1}", style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          )),
                          title: Text(item.product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'HSN: ${item.product.hsncode}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                textAlign: TextAlign.start,
                              ),
                              AppSpacing.wLarge,
                              Text(
                                'Qty: ${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  )
                              ),
                              AppSpacing.wLarge,
                              Text(
                                  'Discount: Rs ${item.discount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  )
                              ),
                              AppSpacing.wLarge,
                              Text(
                                'Price : ${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSpacing.wLarge,
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.blue,
                                onPressed: () => _editInvoiceItem(index),
                                tooltip: 'Edit Item',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    invoiceItems.removeAt(index);
                                  });
                                },
                                tooltip: 'Remove Item',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                AppSpacing.wLarge,
                Row(
                  children: [
                    const Text(
                      'Enable Tax',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: isTaxEnabled,
                      onChanged: (value) {
                        setState(() {
                          isTaxEnabled = value;
                        });
                      },
                    ),
                    AppSpacing.wMedium,
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: taxRateController,
                        decoration: const InputDecoration(
                          labelText: 'Tax Rate (%)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            taxRate =
                                (double.tryParse(value) ?? (taxRate * 100)) / 100;
                          });
                        },
                      ),
                    )
                  ],
                ),
                AppSpacing.wMedium,
                SizedBox(
                  width: MediaQuery.sizeOf(context).width*0.15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Subtotal: Rs ${subtotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text('Tax: Rs ${tax.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),),
                      AppSpacing.hSmall,
                      Text(
                        'Total: Rs ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: invoiceItems.isNotEmpty ? _createInvoice : null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(MediaQuery.sizeOf(context).width*0.3, 50),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Create ${invoiceType.toString()}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInvoiceSuccessScreen()
  {
     return Scaffold(
       body: Center(
         child: Card(
           elevation: 4,
           margin: const EdgeInsets.all(32),
           child: Padding(
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                 AppSpacing.hXlarge,
                 const Text(
                   'Invoice Created Successfully!',
                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                 ),
                 AppSpacing.hSmall,
                 Text('Invoice ID: ${_invoice?.id}'),
                 AppSpacing.hXlarge,
                 Row(
                   mainAxisSize: MainAxisSize.min,
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     IconButton(
                       icon: _invoice != null ? const Icon(Icons.visibility,color: Colors.green,) : const Icon(Icons.visibility),
                       onPressed: _invoice != null
                           ? () => InvoiceServices.showInvoiceDetails(
                           context, _invoice!)
                           : null,
                       tooltip: 'View Details',
                       iconSize: 28,
                     ),
                     AppSpacing.wXlarge,
                     IconButton(
                       icon: _invoice != null ? const Icon(Icons.picture_as_pdf,color: Colors.purple,) :  const Icon(Icons.picture_as_pdf),
                       onPressed: _invoice != null
                           ? () => InvoiceServices.previewPDF(context, _invoice!)
                           : null,
                       tooltip: 'Preview PDF',
                       iconSize: 28,
                     ),
                     AppSpacing.wXlarge,
                     IconButton(
                       icon: _invoice != null ? const Icon(Icons.print,color: Colors.black,) : const Icon(Icons.print),
                       onPressed: _invoice != null
                           ? () => InvoiceServices.generatePDF(context, _invoice!)
                           : null,
                       tooltip: 'Print PDF',
                       iconSize: 28,
                     ),
                   ],
                 ),
                 AppSpacing.hXlarge,
                 ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     minimumSize:  Size(MediaQuery.sizeOf(context).width*0.15 , 50),
                     backgroundColor: Theme.of(context).primaryColor,
                     foregroundColor: Colors.white,
                   ),
                   onPressed: () {
                     // or navigate to home
                     resetValues("Invoice");
                   },
                   child: const Text('Create New Invoice'),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = invoiceItems.fold(0.0, (sum, item) => sum + item.total);
    double tax = isTaxEnabled ? subtotal * taxRate : 0.0;
    double total = subtotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New ${invoiceType}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _invoice != null ? buildInvoiceSuccessScreen() :
      LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoints
          bool isDesktop = constraints.maxWidth > 1200;
          bool isTablet =
              constraints.maxWidth > 800 && constraints.maxWidth <= 1200;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isDesktop)
                  _buildDesktopLayout(tax, subtotal, total)
                else if (isTablet)
                  _buildTabletLayout(tax, subtotal, total)
                else
                  _buildMobileLayout(tax, subtotal, total),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(double tax, double subtotal, double total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar
        SizedBox(
          width: MediaQuery.sizeOf(context).width*0.2,
          child: Column(
            children: [
              _customerSearchView(),
              AppSpacing.hMedium,
              _productSearchView(),
            ],
          ),
        ),
        AppSpacing.wMedium,
        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal split for Invoice and Customer Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _invoiceDetailsForm(),
                  ),
                  AppSpacing.wMedium,
                  Expanded(
                    flex: 3,
                    child: _customerDetailsForm(),
                  ),
                ],
              ),
              AppSpacing.hMedium,
              _invoiceItems(tax, subtotal, total),
              AppSpacing.hMedium,
              _actionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(double tax, double subtotal, double total) {
    return Column(
      children: [
        AppSpacing.hLarge,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _customerSearchView(),
                  AppSpacing.hMedium,
                  _productSearchView(),
                ],
              ),
            ),
            AppSpacing.hMedium,
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Horizontal split for Invoice and Customer Details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _invoiceDetailsForm(),
                      ),
                      AppSpacing.wMedium,
                      Expanded(
                        flex: 3,
                        child: _customerDetailsForm(),
                      ),
                    ],
                  ),
                  AppSpacing.hMedium,
                  _invoiceItems(tax, subtotal, total),
                  AppSpacing.hMedium,
                  _actionButtons(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double tax, double subtotal, double total) {
    return Column(
      children: [
        AppSpacing.hMedium,
        _customerSearchView(),
        AppSpacing.hMedium,
        _productSearchView(),
        AppSpacing.hMedium,
        // For mobile, keep vertical stack due to space constraints
        _invoiceDetailsForm(),
        AppSpacing.hMedium,
        _customerDetailsForm(),
        AppSpacing.hMedium,
        _invoiceItems(tax, subtotal, total),
        AppSpacing.hMedium,
        _actionButtons(),
      ],
    );
  }
}
