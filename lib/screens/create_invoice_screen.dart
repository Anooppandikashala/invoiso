import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/database/customer_service.dart';
import 'package:invoiso/database/product_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:uuid/uuid.dart';
import '../database/invoice_item_service.dart';
import '../database/invoice_service.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../models/additional_cost.dart';
import '../services/invoice_pdf_services.dart';
import '../services/pdf_service.dart';
import 'package:invoiso/constants.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;
  /// When set, the form is pre-populated from this invoice and saved as a NEW
  /// invoice (cloneFrom != null implies invoiceToEdit == null).
  final Invoice? cloneFrom;
  /// The invoice type to use for the clone ('Invoice' or 'Quotation').
  /// Defaults to the source invoice type when null.
  final String? cloneType;
  /// Called when the user taps "New Invoice" while in edit mode.
  /// The parent (DashboardScreen) resets invoiceToEdit to null.
  final VoidCallback? onCreateNewInvoice;

  const CreateInvoiceScreen({
    super.key,
    this.invoiceToEdit,
    this.cloneFrom,
    this.cloneType,
    this.onCreateNewInvoice,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  Customer? selectedCustomer;
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<InvoiceItem> invoiceItems = [];
  final Set<String> _savedAdHocIds = {}; // tracks custom item IDs already saved to products
  final List<({TextEditingController label, TextEditingController amount})>
      _additionalCostControllers = [];
  bool _showAdditionalCosts = false;

  final notesController = TextEditingController();
  final searchController = TextEditingController();
  final customerSearchController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final gstinController = TextEditingController();
  final businessNameController = TextEditingController();
  final taxRateController = TextEditingController();
  final dateController = TextEditingController();
  final dueDateController = TextEditingController();
  DateTime _selectedOrderDate = DateTime.now();
  DateTime? _selectedDueDate;

  final _customerScrollController = ScrollController();
  final _productScrollController = ScrollController();
  final _invoiceItemsScrollController = ScrollController();

  bool _isTaxEnabled = true;
  bool _isPerItem = false;
  bool isEditing = false;
  bool isLoading = false;

  String invoiceType = 'Invoice';
  double taxRate = Tax.defaultTaxRate;
  Invoice? _invoice;
  String currentInvoiceNumber = "";
  String _currencyCode = 'INR';
  String _currencySymbol = '₹';
  List<UpiEntry> _upiEntries = [];
  UpiEntry? _selectedUpi;
  List<BankAccount> _bankAccounts = [];
  BankAccount? _selectedBankAccount;
  bool _showGstFields = true;
  bool _fractionalQuantity = false;
  String _quantityLabel = '';
  bool _showQuantity = true;
  BusinessType _businessType = BusinessType.both;
  String _adHocItemType = 'product'; // type for custom items added inline

  TaxMode get _taxMode {
    if (!_isTaxEnabled) return TaxMode.none;
    return _isPerItem ? TaxMode.perItem : TaxMode.global;
  }

  @override
  void initState() {
    super.initState();
    taxRateController.text = (taxRate * 100).toStringAsFixed(1);
    _loadCustomersAndProducts(widget.invoiceToEdit != null);
    _selectedOrderDate = DateTime.now();
    dateController.text = DateFormat('dd/MM/yyyy').format(_selectedOrderDate);
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
      businessNameController.text = _invoice!.customer.businessName;
      taxRate = _invoice!.taxRate;
      taxRateController.text = (taxRate * 100).toStringAsFixed(1);
      _isTaxEnabled = _invoice!.taxMode != TaxMode.none;
      _isPerItem    = _invoice!.taxMode == TaxMode.perItem;
      invoiceType = _invoice!.type;
      currentInvoiceNumber = _invoice!.id;
      _selectedOrderDate = _invoice!.date;
      dateController.text = DateFormat('dd/MM/yyyy').format(_selectedOrderDate);
      if (_invoice!.dueDate != null) {
        _selectedDueDate = _invoice!.dueDate;
        dueDateController.text = DateFormat('dd/MM/yyyy').format(_invoice!.dueDate!);
      }
      _quantityLabel = _invoice!.quantityLabel ?? '';
      for (final c in _invoice!.additionalCosts) {
        _additionalCostControllers.add((
          label: TextEditingController(text: c.label),
          amount: TextEditingController(text: c.amount.toStringAsFixed(2)),
        ));
      }
      if (_additionalCostControllers.isNotEmpty) _showAdditionalCosts = true;
    } else if (widget.cloneFrom != null) {
      // Clone: pre-populate fields but treat as a brand-new invoice.
      // isEditing stays false → _createInvoice() will be called on save.
      final src = widget.cloneFrom!;
      selectedCustomer = src.customer;
      invoiceItems = List.from(src.items);
      nameController.text = src.customer.name;
      emailController.text = src.customer.email;
      phoneController.text = src.customer.phone;
      addressController.text = src.customer.address;
      gstinController.text = src.customer.gstin;
      businessNameController.text = src.customer.businessName;
      taxRate = src.taxRate;
      taxRateController.text = (taxRate * 100).toStringAsFixed(1);
      _isTaxEnabled = src.taxMode != TaxMode.none;
      _isPerItem    = src.taxMode == TaxMode.perItem;
      invoiceType = widget.cloneType ?? src.type;
      _quantityLabel = src.quantityLabel ?? '';
      for (final c in src.additionalCosts) {
        _additionalCostControllers.add((
          label: TextEditingController(text: c.label),
          amount: TextEditingController(text: c.amount.toStringAsFixed(2)),
        ));
      }
      if (_additionalCostControllers.isNotEmpty) _showAdditionalCosts = true;
      // date stays as today; currentInvoiceNumber is generated in _loadCustomersAndProducts
    }
  }

  Future<void> _setAdditionalNote() async {
    final String addNote;
    if (widget.invoiceToEdit != null) {
      addNote = widget.invoiceToEdit!.notes ?? '';
    } else if (widget.cloneFrom != null) {
      addNote = widget.cloneFrom!.notes ?? '';
    } else {
      addNote = await SettingsService.getSetting(SettingKey.additionalInfo) ??
          DefaultValues.additionalNote;
    }
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
    dateController.dispose();
    dueDateController.dispose();
    _customerScrollController.dispose();
    _productScrollController.dispose();
    _invoiceItemsScrollController.dispose();
    gstinController.dispose();
    businessNameController.dispose();
    for (final row in _additionalCostControllers) {
      row.label.dispose();
      row.amount.dispose();
    }
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

      // Use the existing invoice's currency when editing or cloning,
      // otherwise fall back to the current app-wide currency setting.
      final String loadedCurrencyCode;
      final String loadedCurrencySymbol;
      if (isEditing && widget.invoiceToEdit != null) {
        loadedCurrencyCode = widget.invoiceToEdit!.currencyCode;
        loadedCurrencySymbol = widget.invoiceToEdit!.currencySymbol;
      } else if (widget.cloneFrom != null) {
        loadedCurrencyCode = widget.cloneFrom!.currencyCode;
        loadedCurrencySymbol = widget.cloneFrom!.currencySymbol;
      } else {
        final currency = await SettingsService.getCurrency();
        loadedCurrencyCode = currency.code;
        loadedCurrencySymbol = currency.symbol;
      }

      final upiEntries = await SettingsService.getUpiIds();
      final bankAccounts = await SettingsService.getBankAccounts();
      final showGst = await SettingsService.getShowGstFields();
      final fractionalQty = await SettingsService.getFractionalQuantity();
      final quantityLabelSetting = await SettingsService.getQuantityLabel();
      final showQuantity = await SettingsService.getShowQuantity();
      final businessType = await SettingsService.getBusinessType();

      // Determine which UPI to pre-select.
      String? existingUpiId;
      if (isEditing && widget.invoiceToEdit != null) {
        existingUpiId = widget.invoiceToEdit!.upiId;
      } else if (widget.cloneFrom != null) {
        existingUpiId = widget.cloneFrom!.upiId;
      }

      UpiEntry? preselectedUpi;
      if (existingUpiId != null && existingUpiId.isNotEmpty) {
        preselectedUpi = upiEntries.where((e) => e.id == existingUpiId).firstOrNull;
      }
      preselectedUpi ??= upiEntries.where((e) => e.isDefault).firstOrNull
          ?? upiEntries.firstOrNull;

      // Determine which bank account to pre-select.
      String? existingBankId;
      if (isEditing && widget.invoiceToEdit != null) {
        existingBankId = widget.invoiceToEdit!.bankAccountId;
      } else if (widget.cloneFrom != null) {
        existingBankId = widget.cloneFrom!.bankAccountId;
      }
      BankAccount? preselectedBank;
      if (existingBankId != null && existingBankId.isNotEmpty) {
        preselectedBank = bankAccounts
            .where((e) => e.accountNumber == existingBankId)
            .firstOrNull;
      }
      preselectedBank ??= bankAccounts.where((e) => e.isDefault).firstOrNull
          ?? bankAccounts.firstOrNull;

      // Pre-mark custom items that were already saved to the product list,
      // using the persisted is_product_saved flag on each InvoiceItem.
      _savedAdHocIds.addAll(
        invoiceItems
            .where((item) => item.product.id.startsWith('custom-') && item.isProductSaved)
            .map((item) => item.product.id),
      );

      setState(() {
        customers = c;
        filteredCustomers = List.from(c);
        products = p;
        filteredProducts = List.from(p);
        if (invNumber != null) {
          currentInvoiceNumber = invNumber;
        }
        _currencyCode = loadedCurrencyCode;
        _currencySymbol = loadedCurrencySymbol;
        _upiEntries = upiEntries;
        _selectedUpi = preselectedUpi;
        _bankAccounts = bankAccounts;
        _selectedBankAccount = preselectedBank;
        _showGstFields = showGst;
        if (!showGst) _isTaxEnabled = false;
        _fractionalQuantity = fractionalQty;
        _showQuantity = showQuantity;
        _businessType = businessType;
        _adHocItemType = businessType == BusinessType.service ? 'service' : 'product';
        // For new invoices, use the global setting. Edit/clone already set _quantityLabel in initState.
        if (!isEditing && widget.cloneFrom == null) {
          _quantityLabel = quantityLabelSetting;
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
    final quantityController = TextEditingController();
    final discountController = TextEditingController(
        text: product.defaultDiscount > 0
            ? product.defaultDiscount.toString()
            : '0');
    final unitPriceController = TextEditingController(text: product.price.toString());
    final extraCostController = TextEditingController();

    bool discountPerUnit = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                '${product.name} ($_currencySymbol ${product.price})',
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
              if (product.stock <= 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      const Text('Out of Stock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('Available Stock: ${product.stock}', style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              if (_showQuantity) ...[
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: _quantityLabel.trim().isNotEmpty ? _quantityLabel.trim() : 'Quantity',
                  hintText: '1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: _fractionalQuantity
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
              ),
              const SizedBox(height: 16),
              ],
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
              const SizedBox(height: 8),
              _buildDiscountPerUnitToggle(discountPerUnit, (val) => setDialogState(() => discountPerUnit = val)),
              const SizedBox(height: 16),
              TextField(
                controller: unitPriceController,
                decoration: InputDecoration(
                  labelText: 'Unit Price (override)',
                  helperText: 'Default: $_currencySymbol${product.price}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixText: '$_currencySymbol ',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: extraCostController,
                decoration: InputDecoration(
                  labelText: 'Extra Cost (optional)',
                  hintText: '0.00',
                  helperText: 'Flat fee added on top of the line total',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            onPressed: () async {
              final qty = !_showQuantity
                  ? 1.0
                  : _fractionalQuantity
                      ? (double.tryParse(quantityController.text) ?? 1.0)
                      : (int.tryParse(quantityController.text) ?? 1).toDouble();
              final discount = double.tryParse(discountController.text) ?? 0.0;
              final parsedUnitPrice = double.tryParse(unitPriceController.text);
              final unitPrice = (parsedUnitPrice != null && parsedUnitPrice != product.price) ? parsedUnitPrice : null;
              final extraCost = double.tryParse(extraCostController.text);

              // Check stock
              if (product.stock > 0 && qty > product.stock) {
                // Insufficient stock — ask user if they want to add anyway
                Navigator.pop(context);
                final addAnyway = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Insufficient Stock'),
                    content: Text(
                      'Only ${product.stock} unit(s) available. Add $qty anyway?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Add Anyway'),
                      ),
                    ],
                  ),
                );
                if (addAnyway == true) {
                  addInvoiceProduct(InvoiceItem(product: product, quantity: qty, discount: discount, unitPrice: unitPrice, extraCost: extraCost, discountPerUnit: discountPerUnit));
                }
              } else if (product.stock <= 0) {
                Navigator.pop(context);
                final addAnyway = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Out of Stock'),
                    content: Text('${product.name} is out of stock. Add anyway?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Add Anyway'),
                      ),
                    ],
                  ),
                );
                if (addAnyway == true) {
                  addInvoiceProduct(InvoiceItem(product: product, quantity: qty, discount: discount, unitPrice: unitPrice, extraCost: extraCost, discountPerUnit: discountPerUnit));
                }
              } else {
                Navigator.pop(context);
                addInvoiceProduct(InvoiceItem(product: product, quantity: qty, discount: discount, unitPrice: unitPrice, extraCost: extraCost, discountPerUnit: discountPerUnit));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
      ),
    );
  }

  void addInvoiceProduct(InvoiceItem invoiceItem) {
    final isAdHoc = invoiceItem.product.id.startsWith('custom-');
    final exists = !isAdHoc && invoiceItems.any((item) => item.product.id == invoiceItem.product.id);

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
        customer: Customer(
              id: selectedCustomer?.id ?? const Uuid().v4(),
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              address: addressController.text,
              gstin: gstinController.text,
              businessName: businessNameController.text,
            ),
        items: List.from(invoiceItems),
        date: _selectedOrderDate,
        dueDate: _selectedDueDate,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: _taxMode == TaxMode.global ? taxRate : 0.0,
        type: invoiceType,
        currencyCode: _currencyCode,
        currencySymbol: _currencySymbol,
        taxMode: _taxMode,
        upiId: _selectedUpi?.id,
        bankAccountId: _selectedBankAccount?.accountNumber,
        quantityLabel: _quantityLabel.trim().isEmpty ? null : _quantityLabel.trim(),
        additionalCosts: _buildAdditionalCosts(),
      );

      await InvoiceService.insertInvoice(invoice);

      setState(() {
        _invoice = invoice;
        isLoading = false;
      });

      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating invoice: $e')),
      );
    }
  }

  void _editInvoiceItem(int index) {
    final item = invoiceItems[index];
    final quantityController = TextEditingController(text: item.quantity == 1.0 ? '' : item.quantity.toString());
    final discountController = TextEditingController(text: item.discount.toString());
    final unitPriceController = TextEditingController(text: item.effectivePrice.toString());
    final extraCostController = TextEditingController(text: item.extraCost != null ? item.extraCost.toString() : '');
    bool discountPerUnit = item.discountPerUnit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    Icon(
                      item.product.type == 'service'
                          ? Icons.design_services_outlined
                          : Icons.inventory_2,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppFontSize.xlarge),
                      ),
                    ),
                    if (_businessType == BusinessType.both) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.product.type == 'service'
                              ? Colors.purple.withValues(alpha: 0.15)
                              : Colors.indigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.product.type == 'service' ? 'Service' : 'Product',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.product.type == 'service'
                                ? Colors.purple[700]
                                : Colors.indigo[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_showQuantity) ...[
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: _quantityLabel.trim().isNotEmpty ? _quantityLabel.trim() : 'Quantity',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: _fractionalQuantity
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
              ),
              ],
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
              const SizedBox(height: 8),
              _buildDiscountPerUnitToggle(discountPerUnit, (val) => setDialogState(() => discountPerUnit = val)),
              const SizedBox(height: 16),
              TextField(
                controller: unitPriceController,
                decoration: InputDecoration(
                  labelText: 'Unit Price (override)',
                  helperText: 'Default: $_currencySymbol${item.product.price}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixText: '$_currencySymbol ',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: extraCostController,
                decoration: InputDecoration(
                  labelText: 'Extra Cost (optional)',
                  hintText: '0.00',
                  helperText: 'Flat fee added on top of the line total',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final parsedUnitPrice = double.tryParse(unitPriceController.text);
              final unitPrice = (parsedUnitPrice != null && parsedUnitPrice != item.product.price) ? parsedUnitPrice : null;
              final extraCost = double.tryParse(extraCostController.text);
              final updatedItem = InvoiceItem(
                product: item.product,
                quantity: !_showQuantity
                    ? 1.0
                    : _fractionalQuantity
                        ? (double.tryParse(quantityController.text) ?? item.quantity)
                        : (int.tryParse(quantityController.text) ?? item.quantity.toInt()).toDouble(),
                discount: double.tryParse(discountController.text) ?? item.discount,
                unitPrice: unitPrice,
                extraCost: extraCost,
                discountPerUnit: discountPerUnit,
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
      ),
    );
  }

  void _addAdHocItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    final taxRateController = TextEditingController(text: '0');
    final extraCostController = TextEditingController();

    bool discountPerUnit = false;
    String dialogItemType = _adHocItemType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_box, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text('Custom Item', style: TextStyle(fontSize: AppFontSize.xlarge)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_businessType == BusinessType.both) ...[
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'product', label: Text('Product'), icon: Icon(Icons.inventory_2_outlined, size: 16)),
                    ButtonSegment(value: 'service', label: Text('Service'), icon: Icon(Icons.design_services_outlined, size: 16)),
                  ],
                  selected: {dialogItemType},
                  onSelectionChanged: (val) => setDialogState(() => dialogItemType = val.first),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.label),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: _showQuantity ? 'Unit Price' : 'Rate',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixText: '$_currencySymbol ',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              if (_showQuantity) ...[
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: _quantityLabel.trim().isNotEmpty ? _quantityLabel.trim() : 'Quantity',
                  hintText: '1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: _fractionalQuantity
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
              ),
              ],
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
              const SizedBox(height: 8),
              _buildDiscountPerUnitToggle(discountPerUnit, (val) => setDialogState(() => discountPerUnit = val)),
              const SizedBox(height: 16),
              TextField(
                controller: extraCostController,
                decoration: InputDecoration(
                  labelText: 'Extra Cost (optional)',
                  hintText: '0.00',
                  helperText: 'Flat fee added on top of the line total',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              if (_taxMode == TaxMode.perItem) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: taxRateController,
                  decoration: InputDecoration(
                    labelText: 'Tax Rate (%)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixIcon: const Icon(Icons.percent),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
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
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              final taxRate = _taxMode == TaxMode.perItem
                  ? (int.tryParse(taxRateController.text) ?? 0)
                  : 0;
              if (name.isEmpty) return;

              final adHocProduct = Product(
                id: 'custom-${const Uuid().v4()}',
                name: name,
                description: '',
                price: price,
                stock: 0,
                hsncode: '',
                tax_rate: taxRate,
                type: dialogItemType,
              );
              final extraCost = double.tryParse(extraCostController.text);
              final item = InvoiceItem(
                product: adHocProduct,
                quantity: !_showQuantity
                    ? 1.0
                    : _fractionalQuantity
                        ? (double.tryParse(quantityController.text) ?? 1.0)
                        : (int.tryParse(quantityController.text) ?? 1).toDouble(),
                discount: double.tryParse(discountController.text) ?? 0.0,
                extraCost: extraCost,
                discountPerUnit: discountPerUnit,
              );
              Navigator.pop(context);
              addInvoiceProduct(item);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
    final results = await ProductService.searchProducts(query, type: _businessType.key);
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
      businessNameController.text = customer?.businessName ?? '';
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
                    const Flexible(
                      child: Text(
                        'Products/Services',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 8),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'Out of stock items are shown in red',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: AppFontSize.xsmall, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addAdHocItemDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Custom Item', style: TextStyle(fontSize: AppFontSize.small)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
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
                          color: product.stock <= 0
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2,
                          color: product.stock <= 0 ? Colors.red : Colors.grey,
                          size: AppFontSize.xlarge,
                        ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HSN: ${product.hsncode.toUpperCase()}',
                            maxLines: 2,
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w400, fontSize: AppFontSize.small),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '$_currencySymbol${product.price.toStringAsFixed(2)}  ·  Stock: ${product.stock}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: AppFontSize.small),
                                ),
                              ),
                              if (product.defaultDiscount > 0) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      border: Border.all(color: Colors.orange),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-$_currencySymbol${product.defaultDiscount.toStringAsFixed(0)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                Flexible(
                  child: Text(
                    '$invoiceType Details',
                    style: const TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Order Date',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedOrderDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedOrderDate = picked;
                          dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: dueDateController,
                    readOnly: true,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      labelStyle: TextStyle(fontSize: AppFontSize.medium),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: dueDateController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _selectedDueDate = null;
                                  dueDateController.clear();
                                });
                              },
                            )
                          : const Icon(Icons.calendar_today, size: 18),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDueDate = picked;
                          dueDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: invoiceType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Invoice', child: Text('Invoice', style: TextStyle(fontSize: AppFontSize.medium))),
                      DropdownMenuItem(value: 'Quotation', child: Text('Quotation', style: TextStyle(fontSize: AppFontSize.medium))),
                    ],
                    onChanged: (value) {
                      if (value != null) resetInvoiceType(value);
                    },
                  ),
                ),
                if (_quantityLabel.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: 'Qty column label — change in Invoice Settings',
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Qty Label',
                          prefixIcon: const Icon(Icons.tag, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        child: Text(
                          _quantityLabel.trim(),
                          style: TextStyle(fontSize: AppFontSize.medium, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
      for (final row in _additionalCostControllers) {
        row.label.dispose();
        row.amount.dispose();
      }
      _additionalCostControllers.clear();
      _showAdditionalCosts = false;
      notesController.clear();
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      addressController.clear();
      gstinController.clear();
      businessNameController.clear();
      taxRate = Tax.defaultTaxRate;
      taxRateController.text = (taxRate * 100).toStringAsFixed(1);
    });
    await _setAdditionalNote();
  }

  Future<void> _saveCustomer() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter a customer name before saving'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final phone = phoneController.text.trim();
    final existing = await CustomerService.findByPhone(phone);

    if (existing != null) {
      if (!mounted) return;
      final update = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_search, color: Colors.orange),
              SizedBox(width: 12),
              Text('Customer Already Exists'),
            ],
          ),
          content: Text(
            '"${existing.name}" is already saved with this phone number.\n\nUpdate their details with the current information?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Existing'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (update != true) return;

      final updated = Customer(
        id: existing.id,
        name: name,
        email: emailController.text.trim(),
        phone: phone,
        address: addressController.text.trim(),
        gstin: gstinController.text.trim(),
        businessName: businessNameController.text.trim(),
      );
      await CustomerService.updateCustomer(updated);
      final reloaded = await CustomerService.getAllCustomers();
      setState(() {
        selectedCustomer = updated;
        customers = reloaded;
        filteredCustomers = reloaded;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updated.name} updated in customer list'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final newCustomer = Customer(
        id: const Uuid().v4(),
        name: name,
        email: emailController.text.trim(),
        phone: phone,
        address: addressController.text.trim(),
        gstin: gstinController.text.trim(),
        businessName: businessNameController.text.trim(),
      );
      await CustomerService.insertCustomer(newCustomer);
      final reloaded = await CustomerService.getAllCustomers();
      setState(() {
        selectedCustomer = newCustomer;
        customers = reloaded;
        filteredCustomers = reloaded;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newCustomer.name} saved to customer list'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                const Spacer(),
                Tooltip(
                  message: selectedCustomer != null
                      ? 'Customer already saved — deselect to save a new one'
                      : 'Save customer to customer list',
                  child: OutlinedButton.icon(
                    onPressed: selectedCustomer != null ? null : _saveCustomer,
                    icon: Icon(
                      Icons.person_add_outlined,
                      size: 16,
                      color: selectedCustomer != null ? Colors.grey : Theme.of(context).primaryColor,
                    ),
                    label: Text(
                      selectedCustomer != null ? 'Saved' : 'Save Customer',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: selectedCustomer != null ? Colors.grey : Theme.of(context).primaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      side: BorderSide(
                        color: selectedCustomer != null ? Colors.grey[300]! : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 1: Customer Name | Business Name | Phone
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
                    controller: businessNameController,
                    style: TextStyle(fontSize: AppFontSize.medium),
                    decoration: InputDecoration(
                      labelText: 'Business Name',
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
            // Row 2: Email | Address | GSTIN (conditional)
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
                if (_showGstFields) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: gstinController,
                      style: TextStyle(fontSize: AppFontSize.medium),
                      decoration: InputDecoration(
                        labelText: 'Tax/VAT Number (GSTIN)',
                        labelStyle: TextStyle(fontSize: AppFontSize.medium),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<AdditionalCost> _buildAdditionalCosts() {
    final costs = <AdditionalCost>[];
    for (final row in _additionalCostControllers) {
      final label = row.label.text.trim();
      final amount = double.tryParse(row.amount.text) ?? 0.0;
      if (label.isNotEmpty && amount > 0) {
        costs.add(AdditionalCost(label: label, amount: amount));
      }
    }
    return costs;
  }

  Widget _buildAdditionalCostsSection() {
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Header row — always visible, toggles collapse
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xsmall)),
            onTap: () => setState(() => _showAdditionalCosts = !_showAdditionalCosts),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.add_box_outlined, size: 18, color: Colors.teal[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Additional Costs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal[800],
                    ),
                  ),
                  if (_additionalCostControllers.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_additionalCostControllers.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _showAdditionalCosts ? Icons.expand_less : Icons.expand_more,
                    color: Colors.teal[700],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible body
          if (_showAdditionalCosts) ...[
            const Divider(height: 1, color: Colors.teal),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ..._additionalCostControllers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: row.label,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Label',
                                hintText: 'e.g. Shipping',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row.amount,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '$_currencySymbol ',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            tooltip: 'Remove',
                            onPressed: () {
                              setState(() {
                                _additionalCostControllers[i].label.dispose();
                                _additionalCostControllers[i].amount.dispose();
                                _additionalCostControllers.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _additionalCostControllers.add((
                            label: TextEditingController(),
                            amount: TextEditingController(),
                          ));
                        });
                      },
                      icon: Icon(Icons.add_circle_outline, color: primary, size: 16),
                      label: Text('Add Row', style: TextStyle(color: primary, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountPerUnitToggle(bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Discount per unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              value
                  ? '(price − discount) × qty'
                  : '(price × qty) − discount',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildItemDetail(String label, String value, {Color? color}) {
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$_currencySymbol${amount.toStringAsFixed(2)}',
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryPanel(Invoice invoice) {
    final amountPaid = invoice.amountPaid;
    final outstanding = invoice.outstandingBalance;
    final isPaid = outstanding <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Amount Paid:',
                style: TextStyle(fontSize: 14, color: Colors.green[700]),
              ),
            ),
            Text(
              '$_currencySymbol${amountPaid.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (isPaid)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PAID IN FULL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Amount Due:',
                  style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                ),
              ),
              Text(
                '$_currencySymbol${outstanding.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
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
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products from the right panel',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                            if (_businessType == BusinessType.both)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.product.type == 'service'
                                      ? Colors.purple.withValues(alpha: 0.1)
                                      : Colors.indigo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: item.product.type == 'service'
                                        ? Colors.purple.withValues(alpha: 0.4)
                                        : Colors.indigo.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  item.product.type == 'service' ? 'Service' : 'Product',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: item.product.type == 'service'
                                        ? Colors.purple[700]
                                        : Colors.indigo[700],
                                  ),
                                ),
                              ),
                            if (item.unitPrice != null)
                              _buildItemDetail('Price', '$_currencySymbol${item.effectivePrice.toStringAsFixed(2)} *', color: Colors.orange[700])
                            else
                              _buildItemDetail('Price', '$_currencySymbol${item.product.price.toStringAsFixed(2)}'),
                            _buildItemDetail('HSN', item.product.hsncode.toString()),
                            if (_showQuantity)
                              _buildItemDetail(_quantityLabel.trim().isNotEmpty ? _quantityLabel.trim() : 'Qty', item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toString()),
                            _buildItemDetail('Discount', '$_currencySymbol${item.discount.toStringAsFixed(2)}${item.discountPerUnit ? ' ×qty' : ''}'),
                            if (item.extraCost != null && item.extraCost! > 0)
                              _buildItemDetail('Extra', '+$_currencySymbol${item.extraCost!.toStringAsFixed(2)}', color: Colors.teal[700]),
                            if (_taxMode == TaxMode.perItem)
                              _buildItemDetail('Tax', '${item.product.tax_rate}%'),
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
                              '$_currencySymbol${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          if (item.product.id.startsWith('custom-') &&
                              !_savedAdHocIds.contains(item.product.id)) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Save to product list',
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: Colors.deepPurple, width: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                                label: const Text('Save', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  // Guard against duplicates: if a product with
                                  // the same name already exists, skip insert.
                                  final existing = await ProductService.findDuplicateByName(item.product.name);
                                  if (!mounted) return;
                                  if (existing != null) {
                                    setState(() => _savedAdHocIds.add(item.product.id));
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('"${item.product.name}" already exists in product list'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  final newProduct = Product(
                                    id: const Uuid().v4(),
                                    name: item.product.name,
                                    description: '',
                                    price: item.effectivePrice,
                                    stock: 0,
                                    hsncode: item.product.hsncode,
                                    tax_rate: item.product.tax_rate,
                                    type: item.product.type,
                                  );
                                  await ProductService.insertProduct(newProduct);
                                  item.isProductSaved = true;
                                  // Persist immediately so the flag survives
                                  // even if the user closes without saving the invoice.
                                  if (isEditing && _invoice != null) {
                                    await InvoiceItemService.markProductSaved(
                                        _invoice!.id, item.product.id);
                                  }
                                  final reloaded = await ProductService.getAllProducts();
                                  if (!mounted) return;
                                  setState(() {
                                    _savedAdHocIds.add(item.product.id);
                                    products = reloaded;
                                    filteredProducts = reloaded;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('${newProduct.name} saved to product list'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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
                _buildAdditionalCostsSection(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: _upiEntries.isNotEmpty ? 3 : 4,
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
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_upiEntries.isNotEmpty) ...[
                              AppSpacing.wSmall,
                              DropdownButtonFormField<UpiEntry?>(
                                isExpanded: true,
                                value: _selectedUpi,
                                decoration: InputDecoration(
                                  labelText: 'Payment UPI Account',
                                  prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                items: [
                                  const DropdownMenuItem<UpiEntry?>(
                                    value: null,
                                    child: Text('None', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ..._upiEntries.map((e) => DropdownMenuItem<UpiEntry?>(
                                    value: e,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (e.isDefault) ...[
                                          Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(e.displayLabel),
                                      ],
                                    ),
                                  )),
                                ],
                                onChanged: (val) => setState(() => _selectedUpi = val),
                              ),
                            ],
                            AppSpacing.hMedium,
                            if (_bankAccounts.isNotEmpty) ...[
                              AppSpacing.wSmall,
                              DropdownButtonFormField<BankAccount?>(
                                isExpanded: true,
                                value: _selectedBankAccount,
                                decoration: InputDecoration(
                                  labelText: 'Bank Account',
                                  prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                items: [
                                  const DropdownMenuItem<BankAccount?>(
                                    value: null,
                                    child: Text('None', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ..._bankAccounts.map((e) => DropdownMenuItem<BankAccount?>(
                                    value: e,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (e.isDefault) ...[
                                          Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(e.displayLabel),
                                      ],
                                    ),
                                  )),
                                ],
                                onChanged: (val) => setState(() => _selectedBankAccount = val),
                              ),
                            ],
                          ],
                    )),
                    AppSpacing.wSmall,
                    Expanded(
                      flex: (_upiEntries.isNotEmpty || _bankAccounts.isNotEmpty) ? 2 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enable Tax toggle (only when GST fields are enabled)
                          if (_showGstFields) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Enable Tax',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Switch(
                                  value: _isTaxEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _isTaxEnabled = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                          if (_isTaxEnabled) ...[
                            const SizedBox(height: 8),
                            // Global / Per Item selector
                            SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment<bool>(
                                    value: false,
                                    icon: Icon(Icons.percent, size: 16),
                                    tooltip: 'Global Rate',
                                  ),
                                  ButtonSegment<bool>(
                                    value: true,
                                    icon: Icon(Icons.list_alt, size: 16),
                                    tooltip: 'Per Item Rate',
                                  ),
                                ],
                                selected: {_isPerItem},
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    _isPerItem = selection.first;
                                  });
                                },
                              ),
                            const SizedBox(height: 8),
                            // Global rate input (only when global selected)
                            if (!_isPerItem)
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
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Tax rate from each product',
                                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
                            ..._buildAdditionalCosts().map((c) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _buildTotalRow(
                                c.label.isEmpty ? 'Extra Cost' : c.label,
                                c.amount,
                                false,
                              ),
                            )),
                            const SizedBox(height: 20),
                            _buildTotalRow('Total', total, true),
                            if (isEditing &&
                                _invoice != null &&
                                _invoice!.type == 'Invoice' &&
                                _invoice!.payments.isNotEmpty)
                              _buildPaymentSummaryPanel(_invoice!),
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
              icon: Icons.download_outlined,
              label: 'Download',
              color: Colors.deepPurple,
              onPressed: _invoice != null
                  ? () => PDFService.downloadPDF(context, _invoice!)
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
        customer: Customer(
              id: selectedCustomer?.id ?? const Uuid().v4(),
              name: nameController.text,
              email: emailController.text,
              phone: phoneController.text,
              address: addressController.text,
              gstin: gstinController.text,
              businessName: businessNameController.text,
            ),
        items: List.from(invoiceItems),
        date: _selectedOrderDate,
        dueDate: _selectedDueDate,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: _taxMode == TaxMode.global ? taxRate : 0.0,
        type: invoiceType,
        currencyCode: _currencyCode,
        currencySymbol: _currencySymbol,
        taxMode: _taxMode,
        upiId: _selectedUpi?.id,
        bankAccountId: _selectedBankAccount?.accountNumber,
        quantityLabel: _quantityLabel.trim().isEmpty ? null : _quantityLabel.trim(),
        additionalCosts: _buildAdditionalCosts(),
      );

      await InvoiceService.updateInvoice(updatedInvoice);

      final refreshedInvoice = await InvoiceService.getInvoiceById(updatedInvoice.id);
      setState(() {
        _invoice = refreshedInvoice ?? updatedInvoice;
        isLoading = false;
      });

      if (!mounted) return;
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
      if (!mounted) return;
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
                      icon: Icons.download_outlined,
                      label: 'Download PDF',
                      color: Colors.deepPurple,
                      onPressed: () => PDFService.downloadPDF(context, _invoice!),
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
                const SizedBox(height: 24),
                // Offer to save customer only if they weren't already in the list
                if (selectedCustomer == null && nameController.text.trim().isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1_outlined, color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Save "${nameController.text.trim()}" to your customer list for future use?',
                            style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber.shade900,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () async {
                            final phone = phoneController.text.trim();
                            final existing = phone.isNotEmpty
                                ? await CustomerService.findByPhone(phone)
                                : null;
                            final newCustomer = existing ?? Customer(
                              id: const Uuid().v4(),
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phone,
                              address: addressController.text.trim(),
                              gstin: gstinController.text.trim(),
                              businessName: businessNameController.text.trim(),
                            );
                            if (existing == null) {
                              await CustomerService.insertCustomer(newCustomer);
                            }
                            final reloaded = await CustomerService.getAllCustomers();
                            if (mounted) {
                              setState(() {
                                selectedCustomer = newCustomer;
                                customers = reloaded;
                                filteredCustomers = reloaded;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${newCustomer.name} saved to customer list'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onPressed: () => setState(() => selectedCustomer = Customer(
                            id: '', name: nameController.text.trim(),
                            email: '', phone: '', address: '', gstin: '', businessName: '',
                          )),
                          child: const Text('Dismiss'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
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
    double tax;
    switch (_taxMode) {
      case TaxMode.global:
        tax = subtotal * taxRate;
        break;
      case TaxMode.perItem:
        tax = invoiceItems.fold(0.0, (sum, item) => sum + item.taxAmount);
        break;
      case TaxMode.none:
        tax = 0.0;
        break;
    }
    final additionalTotal = _buildAdditionalCosts()
        .fold(0.0, (sum, c) => sum + c.amount);
    double total = subtotal + tax + additionalTotal;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _invoice != null && !isEditing
                      ? '$invoiceType Created'
                      : widget.invoiceToEdit != null
                          ? 'Edit $invoiceType'
                          : widget.cloneFrom != null
                              ? 'Duplicate as $invoiceType'
                              : 'Create New $invoiceType',
                ),
                if (isEditing) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => widget.onCreateNewInvoice?.call(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Invoice', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    style: TextStyle(fontSize: 24),
                    '$invoiceType Number : #[$currentInvoiceNumber]',
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Invoice numbers are auto-generated.\n'
                        'The next number is calculated from the last\n'
                        'invoice in the database (including deleted ones).\n'
                        'Manual editing is not supported.',
                    child: const Icon(Icons.info_outline, size: 16, color: Colors.white70),
                  ),
                ],
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppLayout.maxWidthWide),
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
                  Expanded(flex: 2, child: _invoiceDetailsForm()),
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
                      Expanded(flex: 2, child: _invoiceDetailsForm()),
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