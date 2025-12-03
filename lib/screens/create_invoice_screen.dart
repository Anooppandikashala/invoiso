import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:uuid/uuid.dart';
import '../database/invoice_service.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../services/invoice_pdf_services.dart';
import 'package:invoiso/constants.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;
  const CreateInvoiceScreen({super.key, this.invoiceToEdit});
  @override
  _CreateInvoiceScreenState createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
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
  final dateController = TextEditingController();

  final _customerScrollController = ScrollController();
  final _productScrollController = ScrollController();
  final _invoiceItemsScrollController = ScrollController();

  bool isTaxEnabled = true;
  bool isEditing = false;
  bool isLoading = false;

  String invoiceType = 'Invoice';
  double taxRate = Tax.defaultTaxRate;
  Invoice? _invoice;
  String currentInvoiceNumber = "";

  @override
  void initState() {
    super.initState();
    taxRateController.text = (taxRate * 100).toStringAsFixed(1);
    _loadCustomersAndProducts(widget.invoiceToEdit != null);
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _setAdditionalNote();
    if (widget.invoiceToEdit != null) {
      _invoice = widget.invoiceToEdit;
      isEditing = true;
      selectedCustomer = _invoice!.customer;
      invoiceItems = List.from(_invoice!.items);
      nameController.text = _invoice!.customer.name;
      emailController.text = _invoice!.customer.email;
      phoneController.text = _invoice!.customer.phone;
      addressController.text = _invoice!.customer.address;
      gstinController.text = _invoice!.customer.gstin;
      taxRate = _invoice!.taxRate;
      taxRateController.text = (taxRate * 100).toStringAsFixed(1);
      invoiceType = _invoice!.type;
      currentInvoiceNumber = _invoice!.id;
      dateController.text = DateFormat('dd/MM/yyyy').format(_invoice!.date);
    }
  }

  Future<void> _setAdditionalNote() async
  {
    final addNote = widget.invoiceToEdit != null ?
        ( widget.invoiceToEdit!.notes != null ? widget.invoiceToEdit!.notes! : "") :
        await SettingsService.getSetting(SettingKey.additionalInfo) ?? DefaultValues.additionalNote;
    setState(() {
      notesController.text = addNote;
    });
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

  Future<void> _loadCustomersAndProducts(bool isEditing) async {
    setState(() => isLoading = true);

    try {
      final c = await CustomerService.getAllCustomers();
      final p = await ProductService.getAllProducts();
      final String? invNumber;
      if (!isEditing) {
        invNumber = await InvoicePdfServices.generateNextInvoiceNumber();
      } else {
        invNumber = widget.invoiceToEdit?.id;
      }

      setState(() {
        customers = c;
        filteredCustomers = List.from(c);
        products = p;
        filteredProducts = List.from(p);
        if (invNumber != null) {
          currentInvoiceNumber = invNumber;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void addInvoiceProductPrompt(Product product) {
    final quantityController = TextEditingController(text: '1');
    final discountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_cart, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${product.name} (Rs: ${product.price})',
                style: const TextStyle(fontSize: AppFontSize.xlarge),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountController,
                decoration: InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.discount),
                  filled: true,
                  fillColor: Colors.grey[50],
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
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('This product has already been added'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
    } else {
      setState(() {
        invoiceItems.insert(0, invoiceItem);
      });
    }
  }

  Future<void> _createInvoice() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Please provide customer name'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return;
    }

    if (invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Please add at least one item'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final invoiceId = await InvoicePdfServices.generateNextInvoiceNumber();
      final invoice = Invoice(
        id: invoiceId,
        customer: selectedCustomer ??
            Customer(
              id: const Uuid().v4(),
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              address: addressController.text,
              gstin: gstinController.text,
            ),
        items: List.from(invoiceItems),
        date: DateTime.now(),
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: taxRate,
        type: invoiceType,
      );

      await InvoiceService.insertInvoice(invoice);

      setState(() {
        _invoice = invoice;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('$invoiceType created successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating invoice: $e')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 12),
            Text('Edit Item', style: TextStyle(fontSize: AppFontSize.xlarge)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppFontSize.xlarge),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountController,
                decoration: InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.discount),
                  filled: true,
                  fillColor: Colors.grey[50],
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
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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

  // void _filterProducts(String query) {
  //   setState(() {
  //     if (query.isEmpty) {
  //       filteredProducts = List.from(products);
  //     } else {
  //       filteredProducts = products
  //           .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
  //           .toList();
  //     }
  //   });
  // }

  void _filterProducts(String query) async {
    final results = await ProductService.searchProducts(query);
    setState(() {
      filteredProducts = results;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = List.from(customers);
      } else {
        filteredCustomers = customers.where((customer) {
          final nameMatch = customer.name.toLowerCase().contains(query.toLowerCase());
          final mobileMatch = customer.phone.toLowerCase().contains(query.toLowerCase());
          return nameMatch || mobileMatch;
        }).toList();
      }
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Customers',
                      style: TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customerSearchController,
                  onChanged: _filterCustomers,
                  decoration: InputDecoration(
                    labelText: 'Search Customer',
                    labelStyle: TextStyle(fontSize: AppFontSize.small),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppPadding.small, vertical: AppPadding.xsmall),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.15,
            child: filteredCustomers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No customers found', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : Scrollbar(
              controller: _customerScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: filteredCustomers.length > 2 ? 2 : filteredCustomers.length,
                controller: _customerScrollController,
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  final isSelected = selectedCustomer?.id == customer.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: AppFontSize.xlarge,
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: AppFontSize.medium,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                          customer.phone),
                      trailing: IconButton(
                        icon: Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSelected ? Colors.green : Theme.of(context).primaryColor,
                        ),
                        onPressed: () => _selectCustomer(customer),
                        tooltip: 'Select Customer',
                      ),
                      onTap: () => _selectCustomer(customer),
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

  Widget _productSearchView() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Products',
                      style: TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  onChanged: _filterProducts,
                  decoration: InputDecoration(
                    labelText: 'Search Product',
                    labelStyle: TextStyle(fontSize: AppFontSize.small),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppPadding.small, vertical: AppPadding.xsmall),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No products found', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : Scrollbar(
              thumbVisibility: true,
              controller: _productScrollController,
              child: ListView.builder(
                itemCount: filteredProducts.length > 8 ? 8 : filteredProducts.length,
                controller: _productScrollController,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory_2, color: Colors.grey,size: AppFontSize.xlarge,),
                      ),
                      title: Text(
                        product.name,
                        maxLines: 5,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          fontSize: AppFontSize.medium
                        ),
                      ),
                      subtitle: Column(
                        //mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HSN: ${product.hsncode.toUpperCase()}',
                            maxLines: 2,
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w400,fontSize: AppFontSize.small),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   'Stock : ${product.stock}',
                              //   overflow: TextOverflow.ellipsis,
                              //   style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                              // ),
                              Text(
                                '₹${product.price.toStringAsFixed(2)}  (Stock : ${product.stock})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold,fontSize: AppFontSize.medium),
                              )
                            ],
                          )
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => addInvoiceProductPrompt(product),
                        tooltip: 'Add to Invoice',
                      ),
                      onTap: () => addInvoiceProductPrompt(product),
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

  Widget _invoiceDetailsForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '$invoiceType Details',
                  style: const TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Expanded(
                //   child: TextField(
                //     controller: TextEditingController(text: currentInvoiceNumber),
                //     readOnly: true,
                //     enabled: false,
                //     maxLines: 1,
                //     decoration: InputDecoration(
                //       labelText: '$invoiceType Number',
                //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                //       filled: true,
                //       fillColor: Colors.grey[100],
                //     ),
                //   ),
                // ),
                // const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: dateController,
                    readOnly: true,
                    enabled: false,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Date',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: invoiceType,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'Invoice', child: Text('Invoice',style: TextStyle(fontSize: AppFontSize.medium),)),
                DropdownMenuItem(value: 'Quotation', child: Text('Quotation',style: TextStyle(fontSize: AppFontSize.medium),)),
              ],
              onChanged: (value) {
                if (value != null) {
                  resetInvoiceType(value);
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> resetInvoiceType(String invoiceType_) async {
    setState(() {
      invoiceType = invoiceType_;
    });
  }

  Future<void> resetValues(String invoiceType_) async {
    final invType = await InvoicePdfServices.generateNextInvoiceNumber();
    setState(() {
      invoiceType = invoiceType_;
      currentInvoiceNumber = invType;
      _invoice = null;
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
  }

  Widget _customerDetailsForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Customer Details',
                  style: TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Customer Name *',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: gstinController,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'GSTIN',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: addressController,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Address',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
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

  Widget _buildItemDetail(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green : Colors.grey[700],
          ),
        ),
        const SizedBox(width: 24),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _invoiceItems(double tax, double subtotal, double total) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '$invoiceType Items',
                  style: const TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${invoiceItems.length} items',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: invoiceItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No items added yet',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products from the right panel',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : Scrollbar(
              controller: _invoiceItemsScrollController,
              child: ListView.builder(
                controller: _invoiceItemsScrollController,
                itemCount: invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = invoiceItems[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppMargin.small, vertical: AppMargin.xxxsmall),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppPadding.medium, vertical: AppPadding.xxxsmall),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                        ),
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      title: Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: AppFontSize.medium,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            _buildItemDetail('Price', item.product.price.toString()),
                            _buildItemDetail('HSN', item.product.hsncode.toString()),
                            _buildItemDetail('Qty', item.quantity.toString()),
                            _buildItemDetail('Discount', '₹${item.discount.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.blue,
                            onPressed: () => _editInvoiceItem(index),
                            tooltip: 'Edit Item',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
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
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                    ),
                    AppSpacing.wSmall,
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Enable Tax',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Switch(
                                value: isTaxEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    isTaxEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: taxRateController,
                            style: TextStyle(fontSize: AppFontSize.medium),
                            decoration: InputDecoration(
                              labelText: 'Tax Rate',
                              labelStyle: TextStyle(fontSize: AppFontSize.medium),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                              suffixText: '%',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                taxRate = (double.tryParse(value) ?? (taxRate * 100)) / 100;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.wSmall,
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(AppPadding.medium),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildTotalRow('Subtotal', subtotal, false),
                            const SizedBox(height: 8),
                            _buildTotalRow('Tax', tax, false),
                            const SizedBox(height: 20),
                            _buildTotalRow('Total', total, true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: onPressed != null ? color.withValues(alpha: 0.1) : Colors.grey[200],
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: onPressed != null ? color : Colors.grey,
            iconSize: 28,
            onPressed: onPressed,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null ? color : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    final isEditMode = widget.invoiceToEdit != null;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.medium)),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: invoiceItems.isNotEmpty && !isLoading
                  ? (isEditMode ? _updateInvoice : _createInvoice)
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(MediaQuery.of(context).size.width * 0.25, 56),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                elevation: 2,
              ),
              icon: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Icon(isEditMode ? Icons.update : Icons.save),
              label: Text(
                isLoading
                    ? 'Processing...'
                    : (isEditMode ? 'Update $invoiceType' : 'Create $invoiceType'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: Icons.visibility,
              label: 'View',
              color: Colors.green,
              onPressed: _invoice != null
                  ? () => InvoicePdfServices.showInvoiceDetails(context, _invoice!)
                  : null,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.picture_as_pdf,
              label: 'Preview',
              color: Colors.purple,
              onPressed: _invoice != null
                  ? () => InvoicePdfServices.previewPDF(context, _invoice!)
                  : null,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.print,
              label: 'Print',
              color: Colors.blue,
              onPressed: _invoice != null
                  ? () => InvoicePdfServices.generatePDF(context, _invoice!)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateInvoice() async {
    if (_invoice == null) return;

    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Please provide customer name'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final updatedInvoice = Invoice(
        id: _invoice!.id,
        customer: selectedCustomer ??
            Customer(
              id: const Uuid().v4(),
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              address: addressController.text,
              gstin: gstinController.text,
            ),
        items: List.from(invoiceItems),
        date: _invoice!.date,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: taxRate,
        type: invoiceType,
      );

      await InvoiceService.updateInvoice(updatedInvoice);

      setState(() {
        _invoice = updatedInvoice;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('$invoiceType updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating invoice: $e')),
      );
    }
  }

  Widget _buildSuccessActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: color,
            iconSize: 32,
            onPressed: onPressed,
            tooltip: label,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget buildInvoiceSuccessScreen() {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.all(32),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 80),
                ),
                const SizedBox(height: 24),
                Text(
                  '$invoiceType Created Successfully!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$invoiceType ID: ${_invoice?.id}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSuccessActionButton(
                      icon: Icons.visibility,
                      label: 'View Details',
                      color: Colors.green,
                      onPressed: () => InvoicePdfServices.showInvoiceDetails(context, _invoice!),
                    ),
                    const SizedBox(width: 16),
                    _buildSuccessActionButton(
                      icon: Icons.picture_as_pdf,
                      label: 'Preview PDF',
                      color: Colors.purple,
                      onPressed: () => InvoicePdfServices.previewPDF(context, _invoice!),
                    ),
                    const SizedBox(width: 16),
                    _buildSuccessActionButton(
                      icon: Icons.print,
                      label: 'Print PDF',
                      color: Colors.blue,
                      onPressed: () => InvoicePdfServices.generatePDF(context, _invoice!),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(MediaQuery.of(context).size.width * 0.2, 56),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                    elevation: 2,
                  ),
                  onPressed: () => resetValues("Invoice"),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Create New Invoice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
    if (isLoading && customers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Create New $invoiceType'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...'),
            ],
          ),
        ),
      );
    }

    double subtotal = invoiceItems.fold(0.0, (sum, item) => sum + item.total);
    double tax = isTaxEnabled ? subtotal * taxRate : 0.0;
    double total = subtotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _invoice != null && !isEditing
                  ? '$invoiceType Created'
                  : (widget.invoiceToEdit != null ? 'Edit $invoiceType' : 'Create New $invoiceType'),
            ),
            Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                style: TextStyle(fontSize: 24),
                '$invoiceType Number : #[$currentInvoiceNumber]',
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: !isEditing && _invoice != null
          ? buildInvoiceSuccessScreen()
          : LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 1200;
          bool isTablet = constraints.maxWidth > 800 && constraints.maxWidth <= 1200;

          return Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppPadding.xsmall),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(double tax, double subtotal, double total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox(
        //   width: MediaQuery.of(context).size.width * 0.20,
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       _customerSearchView(),
        //       const SizedBox(height: 16),
        //       _productSearchView(),
        //     ],
        //   ),
        // ),
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
        AppSpacing.wSmall,
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _invoiceDetailsForm()),
                  AppSpacing.wSmall,
                  Expanded(flex: 3, child: _customerDetailsForm()),
                ],
              ),
              AppSpacing.hSmall,
              _invoiceItems(tax, subtotal, total),
              AppSpacing.hSmall,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _customerSearchView(),
                  const SizedBox(height: 16),
                  _productSearchView(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _invoiceDetailsForm()),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: _customerDetailsForm()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _invoiceItems(tax, subtotal, total),
                  const SizedBox(height: 16),
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
        _customerSearchView(),
        const SizedBox(height: 16),
        _productSearchView(),
        const SizedBox(height: 16),
        _invoiceDetailsForm(),
        const SizedBox(height: 16),
        _customerDetailsForm(),
        const SizedBox(height: 16),
        _invoiceItems(tax, subtotal, total),
        const SizedBox(height: 16),
        _actionButtons(),
      ],
    );
  }
}