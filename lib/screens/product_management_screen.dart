import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/common/invoiso_colors.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/screens/settings/product_columns_settings_screen.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  final User user;
  const ProductManagementScreen({super.key, required this.user});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  List<Product> _products = [];

  // Pagination
  int _currentPage = 0;
  int _pageSize = 10;
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
  int _loadRequestId = 0;

  // Form controllers
  final _nameController = TextEditingController();
  final _aliasNameController = TextEditingController();
  final _defaultDiscountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _hsnCodeController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _customUnitController = TextEditingController();
  String _selectedUnit = '';
  final _formKey = GlobalKey<FormState>();

  // Metadata form controllers (add form)
  final _storageLocationController = TextEditingController();
  final _containerNumberController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _skuCodeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _expiryDate;
  DateTime? _manufactureDate;
  String _datePattern = 'dd/MM/yyyy';

  String _currencySymbol = '₹';
  BusinessType _businessType = BusinessType.both;
  String _typeFilter = 'both'; // 'both' | 'product' | 'service'
  String _newItemType = 'product'; // type for the add-product form
  bool _unlimitedStock = false;
  bool _priceIncludesTax = false;

  static const _csvMaxRows = 500;
  static const _csvHeaders = [
    'name',
    'hsn_code',
    'description',
    'price',
    'tax_rate',
    'stock',
    'type',
    'default_discount',
    'purchase_price',
    'alias_name',
    'unit',
    'unlimited_stock',
    'price_includes_tax',
    'storage_location',
    'container_number',
    'batch_number',
    'expiry_date',
    'manufacture_date',
    'supplier_name',
    'sku_code',
    'notes',
  ];

  @override
  void initState() {
    super.initState();
    _taxRateController.text = "18";
    _defaultDiscountController.text = "0";
    _loadBusinessType();
    _loadProducts();
    _loadCurrency();
    _loadDateFormat();
  }

  Future<void> _loadDateFormat() async {
    if (!mounted) return;
    final fmt = await ref.read(settingsRepositoryProvider).getDateFormat();
    if (!mounted) return;
    setState(() => _datePattern = fmt.key);
    _loadColumnsConfig();
    _loadColumnsBannerDismissed();
  }

  ProductColumnsConfig _columnsConfig = const ProductColumnsConfig();
  bool _showColumnsBanner = false;

  Future<void> _loadColumnsConfig() async {
    final config = await ref.read(settingsRepositoryProvider).getProductColumnsConfig();
    if (!mounted) return;
    setState(() {
      _columnsConfig = config;
      if (!config.stock) _unlimitedStock = true;
    });
  }

  Future<void> _loadColumnsBannerDismissed() async {
    final dismissed = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.productColumnsBannerDismissed);
    if (!mounted) return;
    setState(() => _showColumnsBanner = dismissed != '1');
  }

  Future<void> _dismissColumnsBanner() async {
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.productColumnsBannerDismissed, '1');
    if (mounted) setState(() => _showColumnsBanner = false);
  }

  Widget _buildColumnsDiscoveryBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _showColumnsBanner
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New: Customize product fields',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose which fields show for a simpler catalog. Settings > Customize Product Details.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ProductColumnsSettingsScreen()));
                      _loadColumnsConfig();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Configure',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: const Color(0xFF93C5FD),
                    onPressed: _dismissColumnsBanner,
                    tooltip: 'Dismiss',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _loadBusinessType() async {
    if(!mounted) return;
    final bt = await ref.read(settingsRepositoryProvider).getBusinessType();
    setState(() {
      _businessType = bt;
      _typeFilter = bt == BusinessType.both ? 'both' : bt.key;
      _newItemType = bt == BusinessType.service ? 'service' : 'product';
    });
  }

  Future<void> _loadCurrency() async {
    if(!mounted) return;
    final currency = await ref.read(settingsRepositoryProvider).getCurrency();
    setState(() {
      _currencySymbol = currency.symbol;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _defaultDiscountController.dispose();
    _stockController.dispose();
    _taxRateController.dispose();
    _hsnCodeController.dispose();
    _customUnitController.dispose();
    _storageLocationController.dispose();
    _containerNumberController.dispose();
    _batchNumberController.dispose();
    _supplierNameController.dispose();
    _skuCodeController.dispose();
    _notesController.dispose();
    _searchFocusNode.dispose();
    _horizontalScrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final requestId = ++_loadRequestId;
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      final productRepo = ref.read(productRepositoryProvider);
      final results = await Future.wait([
        productRepo.getProductsPaginated(
            offset: _currentPage * _pageSize,
            limit: _pageSize,
            query: _searchQuery,
            orderBy: _sortBy,
            orderASC: _isAscending,
            type: _typeFilter),
        productRepo.getTotalProductCount(),
      ]);
      final result = results[0] as List<Product>;
      final allCount = results[1] as int;

      if (requestId != _loadRequestId || !mounted) return;
      setState(() {
        _products = result;
        _totalProducts = allCount;
        _allProductsCount = allCount;
      });
    } catch (e) {
      if (requestId != _loadRequestId) return;
      _showSnackBar('Error loading products: $e', isError: true);
    } finally {
      
      if (requestId == _loadRequestId && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.parse(_priceController.text.trim());
    final purchasePrice =
        double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    if (!await _confirmIfSellingAtLoss(price, purchasePrice)) return;
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      final newProduct = Product(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stock: _unlimitedStock ? 0 : int.parse(_stockController.text.trim()),
        hsncode: _hsnCodeController.text.trim(),
        tax_rate: int.parse(_taxRateController.text.trim()),
        type: _newItemType,
        defaultDiscount:
            double.tryParse(_defaultDiscountController.text.trim()) ?? 0.0,
        purchasePrice: purchasePrice,
        aliasName: _aliasNameController.text.trim().isEmpty
            ? null
            : _aliasNameController.text.trim(),
        unit: _selectedUnit.trim(),
        unlimitedStock: _unlimitedStock,
        priceIncludesTax: _priceIncludesTax,
      );

      await ref.read(productRepositoryProvider).insertProduct(newProduct);
      await ref.read(productRepositoryProvider).upsertProductMetadata(
            ProductMetadata(
              productId: newProduct.id,
              storageLocation: _storageLocationController.text.trim(),
              containerNumber: _containerNumberController.text.trim(),
              batchNumber: _batchNumberController.text.trim(),
              expiryDate: _isoDate(_expiryDate),
              manufactureDate: _isoDate(_manufactureDate),
              supplierName: _supplierNameController.text.trim(),
              skuCode: _skuCodeController.text.trim(),
              notes: _notesController.text.trim(),
            ),
          );
      _clearForm();
      await _loadProducts();
      _showSnackBar('Product added successfully!');
    } catch (e) {
      _showSnackBar('Error adding product: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _aliasNameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _purchasePriceController.clear();
    _defaultDiscountController.clear();
    _stockController.clear();
    _hsnCodeController.clear();
    _taxRateController.clear();
    _taxRateController.text = "18";
    _customUnitController.clear();
    _storageLocationController.clear();
    _containerNumberController.clear();
    _batchNumberController.clear();
    _supplierNameController.clear();
    _skuCodeController.clear();
    _notesController.clear();
    if (mounted) {
      setState(() {
      _selectedUnit = '';
      _unlimitedStock = !_columnsConfig.stock;
      _priceIncludesTax = false;
      _expiryDate = null;
      _manufactureDate = null;
    });
    }
  }

  static String _isoDate(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  static DateTime? _parseIsoDate(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

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

  /// Returns true if it's fine to proceed with saving. Warns (with a
  /// cancel option) when purchase price exceeds sale price, since that
  /// means selling at a loss.
  Future<bool> _confirmIfSellingAtLoss(double price, double purchasePrice) async {
    if (purchasePrice <= 0 || purchasePrice <= price) return true;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selling at a loss'),
        content: Text(
          'Purchase price ($_currencySymbol${purchasePrice.toStringAsFixed(2)}) '
          'is higher than sale price ($_currencySymbol${price.toStringAsFixed(2)}). '
          'Save anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _showProductDialog(Product product, bool isEdit) async {
    final existingMetadata =
        await ref.read(productRepositoryProvider).getProductMetadata(product.id);
    final storageLocationCtrl =
        TextEditingController(text: existingMetadata?.storageLocation ?? '');
    final containerNumberCtrl =
        TextEditingController(text: existingMetadata?.containerNumber ?? '');
    final batchNumberCtrl =
        TextEditingController(text: existingMetadata?.batchNumber ?? '');
    DateTime? dialogExpiryDate = _parseIsoDate(existingMetadata?.expiryDate);
    DateTime? dialogManufactureDate =
        _parseIsoDate(existingMetadata?.manufactureDate);
    final supplierNameCtrl =
        TextEditingController(text: existingMetadata?.supplierName ?? '');
    final skuCodeCtrl = TextEditingController(text: existingMetadata?.skuCode ?? '');
    final notesCtrl = TextEditingController(text: existingMetadata?.notes ?? '');
    if (!mounted) return;
    //final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product.name);
    final aliasNameCtrl = TextEditingController(text: product.aliasName ?? '');
    final descriptionCtrl = TextEditingController(text: product.description);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final purchasePriceCtrl = TextEditingController(
        text: product.purchasePrice > 0
            ? product.purchasePrice.toString()
            : '0.0');
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final hsnCodeCtrl = TextEditingController(text: product.hsncode);
    final taxRateCtrl =
        TextEditingController(text: product.tax_rate.toString());
    final defaultDiscountCtrl = TextEditingController(
        text: product.defaultDiscount > 0
            ? product.defaultDiscount.toString()
            : '0.0');
    final customUnitCtrl = TextEditingController(
        text: ProductUnits.presets.contains(product.unit) ? '' : product.unit);
    final dialogFormKey = GlobalKey<FormState>();
    String dialogItemType = product.type;
    String dialogUnit = product.unit;
    bool dialogPriceIncludesTax = product.priceIncludesTax;
    bool dialogUnlimitedStock =
        !_columnsConfig.stock ? true : product.unlimitedStock;

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submitEdit() async {
            if (isSaving) return;
            if (!dialogFormKey.currentState!.validate()) return;
            final dialogPrice = double.parse(priceCtrl.text.trim());
            final dialogPurchasePrice =
                double.tryParse(purchasePriceCtrl.text.trim()) ?? 0.0;
            if (!await _confirmIfSellingAtLoss(
                dialogPrice, dialogPurchasePrice)) {
              return;
            }
            setDialogState(() => isSaving = true);
            try {
              final updatedProduct = Product(
                  id: product.id,
                  name: nameCtrl.text.trim(),
                  description: descriptionCtrl.text.trim(),
                  price: dialogPrice,
                  stock: dialogUnlimitedStock ? 0 : int.parse(stockCtrl.text.trim()),
                  hsncode: hsnCodeCtrl.text.trim(),
                  tax_rate: int.parse(taxRateCtrl.text.trim()),
                  type: dialogItemType,
                  defaultDiscount:
                  double.tryParse(defaultDiscountCtrl.text.trim()) ?? 0.0,
                  purchasePrice: dialogPurchasePrice,
                  aliasName: aliasNameCtrl.text.trim().isEmpty
                      ? null
                      : aliasNameCtrl.text.trim(),
                  unit: dialogUnit.trim(),
                  unlimitedStock: dialogUnlimitedStock,
                  priceIncludesTax: dialogPriceIncludesTax,
              );

              await ref.read(productRepositoryProvider).updateProduct(updatedProduct);
              await ref.read(productRepositoryProvider).upsertProductMetadata(
                ProductMetadata(
                  productId: product.id,
                  storageLocation: storageLocationCtrl.text.trim(),
                  containerNumber: containerNumberCtrl.text.trim(),
                  batchNumber: batchNumberCtrl.text.trim(),
                  expiryDate: _isoDate(dialogExpiryDate),
                  manufactureDate: _isoDate(dialogManufactureDate),
                  supplierName: supplierNameCtrl.text.trim(),
                  skuCode: skuCodeCtrl.text.trim(),
                  notes: notesCtrl.text.trim(),
                ),
              );
              await _loadProducts();
              if (context.mounted) Navigator.pop(context);
              _showSnackBar('Product/Service updated successfully!');
            } finally {
              setDialogState(() => isSaving = false);
            }
          }

          return AlertDialog(
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
                    if (_businessType == BusinessType.both &&
                        _columnsConfig.type &&
                        isEdit) ...[
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
                    ] else if (_businessType == BusinessType.both &&
                        _columnsConfig.type) ...[
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
                    _buildDialogTextField(nameCtrl, 'Name (In English)', Icons.inventory_2,
                        readOnly: !isEdit, maxLength: 100,
                        onSubmitted: isEdit ? submitEdit : null),
                    const SizedBox(height: 16),
                    if (_columnsConfig.aliasName) ...[
                      _buildDialogTextField(aliasNameCtrl,
                          'Alias Name (for invoice PDF)', Icons.translate,
                          readOnly: !isEdit, maxLength: 100,
                          helperText : "Alias Name is an optional local-language display name used only on PDF invoices.(You can enable this in InvoiceSettings Page)"
                              "\n You can enter the alias in any supported language, \n"
                              "such as Malayalam, Tamil, Kannada, Hindi, Telugu, Marathi, or others, to generate customer-friendly invoices."
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.hsncode) ...[
                      _buildDialogTextField(
                          hsnCodeCtrl, 'HSN/SAC', Icons.qr_code,
                          readOnly: !isEdit, maxLength: 100),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.description) ...[
                      _buildDialogTextField(
                          descriptionCtrl, 'Description', Icons.description,
                          readOnly: !isEdit, maxLines: 3, maxLength: 100),
                      const SizedBox(height: 16),
                    ],
                    _buildDialogTextField(
                        priceCtrl, 'Price', Icons.attach_money,
                        readOnly: !isEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        isPrice: true,
                        prefixText: '$_currencySymbol ',
                        onSubmitted: isEdit ? submitEdit : null),
                    const SizedBox(height: 16),
                    if (_columnsConfig.purchasePrice) ...[
                      _buildDialogTextField(
                          purchasePriceCtrl, 'Purchase Price', Icons.shopping_cart_outlined,
                          readOnly: !isEdit,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          isPrice: true,
                          prefixText: '$_currencySymbol '),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.defaultDiscount) ...[
                      _buildDialogTextField(
                          defaultDiscountCtrl, 'Default Discount', Icons.discount,
                          readOnly: !isEdit,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          isPrice: true,
                          prefixText: '$_currencySymbol '),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.taxRate) ...[
                      _buildDialogTextField(
                          taxRateCtrl, 'Tax Rate (%)', Icons.percent,
                          readOnly: !isEdit,
                          keyboardType: TextInputType.number,
                          isTaxRate: true),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: dialogPriceIncludesTax,
                        onChanged: !isEdit
                            ? null
                            : (v) => setDialogState(
                                () => dialogPriceIncludesTax = v ?? false),
                        title: const Text('Price Includes Tax'),
                        subtitle: const Text(
                            'Product price already includes tax (per-item tax mode only)'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.stock) ...[
                      _buildDialogTextField(stockCtrl, 'Stock', Icons.inventory,
                          readOnly: !isEdit || dialogUnlimitedStock,
                          keyboardType: TextInputType.number,
                          isStock: !dialogUnlimitedStock),
                      if (isEdit)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: dialogUnlimitedStock,
                          onChanged: (v) => setDialogState(
                              () => dialogUnlimitedStock = v ?? false),
                          title: const Text('Unlimited stock'),
                        ),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.unit)
                    _buildUnitField(
                      selectedUnit: dialogUnit,
                      customController: customUnitCtrl,
                      onUnitChanged: (v) =>
                          setDialogState(() => dialogUnit = v),
                      readOnly: !isEdit,
                    ),
                    const SizedBox(height: 16),
                    if (_columnsConfig.productMetadata)
                    _buildMetadataSection(
                      storageLocationCtrl: storageLocationCtrl,
                      containerNumberCtrl: containerNumberCtrl,
                      batchNumberCtrl: batchNumberCtrl,
                      supplierNameCtrl: supplierNameCtrl,
                      skuCodeCtrl: skuCodeCtrl,
                      notesCtrl: notesCtrl,
                      expiryDate: dialogExpiryDate,
                      manufactureDate: dialogManufactureDate,
                      datePattern: _datePattern,
                      readOnly: !isEdit,
                      onExpiryChanged: (d) =>
                          setDialogState(() => dialogExpiryDate = d),
                      onManufactureChanged: (d) =>
                          setDialogState(() => dialogManufactureDate = d),
                    ),
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
                onPressed: isSaving ? null : submitEdit,
                icon: isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(isSaving ? 'Saving...' : 'Update'),
              ),
          ],
        );
        },
        );
      },
    );
  }

  Widget _buildMetadataSection({
    required TextEditingController storageLocationCtrl,
    required TextEditingController containerNumberCtrl,
    required TextEditingController batchNumberCtrl,
    required TextEditingController supplierNameCtrl,
    required TextEditingController skuCodeCtrl,
    required TextEditingController notesCtrl,
    required DateTime? expiryDate,
    required DateTime? manufactureDate,
    required String datePattern,
    required ValueChanged<DateTime?> onExpiryChanged,
    required ValueChanged<DateTime?> onManufactureChanged,
    bool readOnly = false,
  }) {
    Widget field(TextEditingController ctrl, String label, IconData icon,
        {int maxLines = 1}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            filled: readOnly,
            fillColor:
                readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
          ),
        ),
      );
    }

    Widget dateField(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
      final display = value == null ? '' : DateFormat(datePattern).format(value);
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(text: display),
          onTap: readOnly
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) onChanged(picked);
                },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            suffixIcon: (!readOnly && value != null)
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => onChanged(null),
                  )
                : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            filled: readOnly,
            fillColor:
                readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Additional Info (optional)'),
        leading: const Icon(Icons.more_horiz),
        childrenPadding: const EdgeInsets.only(top: 8),
        children: [
          if (_columnsConfig.metaStorageLocation)
            field(storageLocationCtrl, 'Storage Location', Icons.place_outlined),
          if (_columnsConfig.metaContainerNumber)
            field(containerNumberCtrl, 'Container Number', Icons.inventory_2_outlined),
          if (_columnsConfig.metaBatchNumber)
            field(batchNumberCtrl, 'Batch Number', Icons.tag),
          if (_columnsConfig.metaExpiryDate)
            dateField('Expiry Date', expiryDate, onExpiryChanged),
          if (_columnsConfig.metaManufactureDate)
            dateField('Manufacture Date', manufactureDate, onManufactureChanged),
          if (_columnsConfig.metaSupplierName)
            field(supplierNameCtrl, 'Supplier Name', Icons.local_shipping_outlined),
          if (_columnsConfig.metaSkuCode)
            field(skuCodeCtrl, 'SKU Code', Icons.qr_code_2),
          if (_columnsConfig.metaNotes)
            field(notesCtrl, 'Notes', Icons.notes, maxLines: 3),
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
    String? prefixText,
    String? helperText,
    VoidCallback? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
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
        fillColor: readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
        counterText: '',
          helper: helperText != null ? Tooltip(
            message: helperText,
            textStyle: TextStyle(fontSize: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade900, // Background color
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: InkWell(
              onTap: null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(Icons.info_outline, size: 18, color: Colors.indigo[400]),
              ),
            ),
          ) : null
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
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      await _loadProducts();
      _showSnackBar('Product deleted successfully!');
    }
  }

  // ── Sample CSV ────────────────────────────────────────────────────────────

  Future<void> _downloadSampleCSV() async {
    const sample =
        '"name","hsn_code","description","price","tax_rate","stock","type","default_discount","purchase_price","alias_name","unit","unlimited_stock","price_includes_tax","storage_location","container_number","batch_number","expiry_date","manufacture_date","supplier_name","sku_code","notes"\n'
        '"Wireless Mouse","84716010","Ergonomic wireless mouse","599.00","18","50","product","5.00","400.00","","pcs","0","0","Rack A1","","","","","","",""\n'
        '"USB Hub","84734000","4-port USB 3.0 hub","299.00","18","100","product","0","180.00","","pcs","0","0","","CNT-1023","","","","","",""\n'
        '"Annual Support","998314","Annual technical support plan","4999.00","18","0","service","10.00","0","","unit","1","1","","","","","","","",""\n';

    final sampleBytes = utf8.encode('\uFEFF$sample');
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Sample CSV',
      fileName: 'products_sample.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: Platform.isAndroid ? sampleBytes : null,
    );
    if (savePath == null) return;

    try {
      if (!Platform.isAndroid) {
        await File(savePath).writeAsBytes(sampleBytes);
      }
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
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(6)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.4),
                    1: FlexColumnWidth(0.7),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      children: const [
                        _TableHeader('Column'),
                        _TableHeader('Required'),
                        _TableHeader('Description'),
                      ],
                    ),
                    _csvRuleRow(context, 'name', 'Yes', 'Product name'),
                    _csvRuleRow(context, 'price', 'Yes', 'Unit price (numeric)'),
                    _csvRuleRow(context, 'hsn_code', 'No', 'HSN / SAC code'),
                    _csvRuleRow(context, 'description', 'No', 'Short description'),
                    _csvRuleRow(context, 'tax_rate', 'No', 'Tax % (0–100), default 0'),
                    _csvRuleRow(context, 'stock', 'No', 'Stock quantity, default 0'),
                    _csvRuleRow(context, 'type', 'No', '"product" or "service", default product'),
                    _csvRuleRow(context, 'default_discount', 'No', 'Flat discount amount (currency), default 0'),
                    _csvRuleRow(context, 'purchase_price', 'No', 'Cost price (numeric), default 0'),
                    _csvRuleRow(context, 'alias_name', 'No', 'Local-language display name for PDFs'),
                    _csvRuleRow(context, 'unit', 'No', 'Unit of measure (e.g. kg, bag, pcs), default pcs'),
                    _csvRuleRow(context, 'unlimited_stock', 'No', '1/true for unlimited stock, default 0'),
                    _csvRuleRow(context, 'price_includes_tax', 'No', '1/true if price already includes tax, default 0'),
                    _csvRuleRow(context, 'storage_location', 'No', 'Warehouse/shelf location'),
                    _csvRuleRow(context, 'container_number', 'No', 'Container/box number'),
                    _csvRuleRow(context, 'batch_number', 'No', 'Batch/lot number'),
                    _csvRuleRow(context, 'expiry_date', 'No', 'Expiry date'),
                    _csvRuleRow(context, 'manufacture_date', 'No', 'Manufacture date'),
                    _csvRuleRow(context, 'supplier_name', 'No', 'Supplier name'),
                    _csvRuleRow(context, 'sku_code', 'No', 'SKU code'),
                    _csvRuleRow(context, 'notes', 'No', 'Free-text notes'),
                  ],
                ),
                const SizedBox(height: 16),
                _ruleNote(context, Icons.info_outline,
                    'Maximum $_csvMaxRows rows per import.'),
                _ruleNote(context, Icons.info_outline,
                    'Duplicates are detected by product name (case-insensitive). You will be asked to overwrite or skip each one.'),
                _ruleNote(context, Icons.info_outline,
                    'Rows missing name or price are skipped and reported.'),
                _ruleNote(context, Icons.info_outline,
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

  static TableRow _csvRuleRow(BuildContext context, String col, String req, String desc) {
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
              color: req == 'Yes' ? Colors.red.shade700 : Theme.of(context).colorScheme.onSurfaceVariant,
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

  static Widget _ruleNote(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface))),
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
    if (result == null || result.files.single.path == null || !mounted) return;
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
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // Parse and validate headers
      final headers =
          rows.first.map((h) => h.toString().trim().toLowerCase()).toList();

      if (!headers.contains('name')) {
        _showSnackBar('CSV missing required column: "name"', isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      if (!headers.contains('price')) {
        _showSnackBar('CSV missing required column: "price"', isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      for (final col in headers) {
        if (!_csvHeaders.contains(col)) {
          _showSnackBar(
              'Unknown column "$col". Expected: ${_csvHeaders.join(', ')}',
              isError: true);
          if(!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
      }

      final dataRows = rows.skip(1).toList();

      if (dataRows.length > _csvMaxRows) {
        _showSnackBar(
            'CSV has ${dataRows.length} rows. Maximum is $_csvMaxRows. Please split the file.',
            isError: true);
        if(!mounted) return;
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
      final Map<String, ProductMetadata> metadataById = {};

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
        final typeStr = getField(row, 'type');
        final discountStr = getField(row, 'default_discount');
        final purchasePriceStr = getField(row, 'purchase_price');
        final aliasNameStr = getField(row, 'alias_name');
        final unitStr = getField(row, 'unit');
        final unlimitedStockStr = getField(row, 'unlimited_stock');
        final priceIncludesTaxStr = getField(row, 'price_includes_tax');
        final taxRate = taxStr.isEmpty ? 0 : (int.tryParse(taxStr) ?? 0);
        final stock = stockStr.isEmpty ? 0 : (int.tryParse(stockStr) ?? 0);
        final unlimitedStock = unlimitedStockStr == '1' || unlimitedStockStr.toLowerCase() == 'true';
        final priceIncludesTax = priceIncludesTaxStr == '1' || priceIncludesTaxStr.toLowerCase() == 'true';
        final discount = discountStr.isEmpty ? 0.0 : (double.tryParse(discountStr) ?? 0.0);
        final purchasePrice = purchasePriceStr.isEmpty ? 0.0 : (double.tryParse(purchasePriceStr) ?? 0.0);
        final type = (typeStr == 'service') ? 'service' : 'product';

        final existing = await ref.read(productRepositoryProvider).findDuplicateByName(name);
        final product = Product(
          id: existing?.id ?? const Uuid().v4(),
          name: name,
          hsncode: getField(row, 'hsn_code'),
          description: getField(row, 'description'),
          price: price,
          tax_rate: taxRate.clamp(0, 100),
          stock: stock < 0 ? 0 : stock,
          type: type,
          defaultDiscount: discount < 0 ? 0.0 : discount,
          purchasePrice: purchasePrice < 0 ? 0.0 : purchasePrice,
          aliasName: aliasNameStr.isEmpty ? null : aliasNameStr,
          unit: unitStr,
          unlimitedStock: unlimitedStock,
          priceIncludesTax: priceIncludesTax,
        );

        metadataById[product.id] = ProductMetadata(
          productId: product.id,
          storageLocation: getField(row, 'storage_location'),
          containerNumber: getField(row, 'container_number'),
          batchNumber: getField(row, 'batch_number'),
          expiryDate: getField(row, 'expiry_date'),
          manufactureDate: getField(row, 'manufacture_date'),
          supplierName: getField(row, 'supplier_name'),
          skuCode: getField(row, 'sku_code'),
          notes: getField(row, 'notes'),
        );

        if (existing != null) {
          duplicates.add(product);
        } else {
          valid.add(product);
        }
      }
      if(!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      await _showImportPreviewDialog(valid, duplicates, errors, metadataById);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error reading CSV: $e', isError: true);
    }
  }

  Future<void> _showImportPreviewDialog(
    List<Product> newProducts,
    List<Product> duplicates,
    List<String> errors,
    Map<String, ProductMetadata> metadataById,
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
                                '$_currencySymbol${p.price.toStringAsFixed(2)} · HSN/SAC: ${p.hsncode.isEmpty ? '—' : p.hsncode}'),
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
                            newProducts, duplicates, overwriteFlags, metadataById);
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
    Map<String, ProductMetadata> metadataById,
  ) async {
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      if (newProducts.isNotEmpty) {
        await repo.insertBatch(newProducts);
        for (final p in newProducts) {
          final meta = metadataById[p.id];
          if (meta != null) await repo.upsertProductMetadata(meta);
        }
      }
      for (int i = 0; i < duplicates.length; i++) {
        if (overwriteFlags[i]) {
          await repo.updateProduct(duplicates[i]);
          final meta = metadataById[duplicates[i].id];
          if (meta != null) await repo.upsertProductMetadata(meta);
        }
      }
      await _loadProducts();
      final imported =
          newProducts.length + overwriteFlags.where((f) => f).length;
      _showSnackBar(
          'Imported $imported product${imported == 1 ? '' : 's'} successfully!');
    } catch (e) {
      if(!mounted) return;
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
    if (confirm != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(productRepositoryProvider).deleteAllProducts();
      await _loadProducts();
      _showSnackBar('All products deleted.');
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error deleting products: $e', isError: true);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final repo = ref.read(productRepositoryProvider);
      final allProducts = await repo.getAllProducts();
      final allMetadata = await repo.getAllProductMetadata();
      final List<List<dynamic>> rows = [
        ['name', 'hsn_code', 'description', 'price', 'tax_rate', 'stock', 'type', 'default_discount', 'purchase_price', 'alias_name', 'unit', 'unlimited_stock', 'price_includes_tax', 'storage_location', 'container_number', 'batch_number', 'expiry_date', 'manufacture_date', 'supplier_name', 'sku_code', 'notes'],
        ...allProducts.map((p) {
          final meta = allMetadata[p.id];
          return [
              p.name,
              p.hsncode,
              p.description,
              p.price,
              p.tax_rate,
              p.stock,
              p.type,
              p.defaultDiscount,
              p.purchasePrice,
              p.aliasName ?? '',
              p.unit,
              p.unlimitedStock ? 1 : 0,
              p.priceIncludesTax ? 1 : 0,
              meta?.storageLocation ?? '',
              meta?.containerNumber ?? '',
              meta?.batchNumber ?? '',
              meta?.expiryDate ?? '',
              meta?.manufactureDate ?? '',
              meta?.supplierName ?? '',
              meta?.skuCode ?? '',
              meta?.notes ?? '',
            ];
        }),
      ];
      final csvData = buildQuotedCsv(rows);
      final csvBytes = utf8.encode('\uFEFF$csvData');
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Products CSV',
        fileName: 'products.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Platform.isAndroid ? csvBytes : null,
      );
      if (savePath == null) return;
      if (!Platform.isAndroid) {
        await File(savePath).writeAsBytes(csvBytes);
      }
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
          choice == 'all' ? await ref.read(productRepositoryProvider).getAllProducts() : _products;

      final pdf = pw.Document();
      final totalCount = productsToExport.length;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Product Export - $totalCount product${totalCount == 1 ? '' : 's'}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated by Invoiso',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['#', 'Name', 'HSN/SAC', 'Description', 'Price', 'Tax Rate', 'Stock', 'Type', 'Discount', 'Unit'],
                ...productsToExport.indexed.map(((int, dynamic) e) => [
                      e.$1 + 1,
                      e.$2.name,
                      e.$2.hsncode,
                      e.$2.description,
                      e.$2.price.toStringAsFixed(2),
                      '${e.$2.tax_rate}%',
                      e.$2.unlimitedStock ? 'Unlimited' : e.$2.stock,
                      e.$2.type,
                      e.$2.defaultDiscount > 0 ? e.$2.defaultDiscount.toStringAsFixed(2) : '-',
                      e.$2.unit,
                    ]),
              ],
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Products PDF',
        fileName: 'products.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: Platform.isAndroid ? pdfBytes : null,
      );
      if (savePath == null) return;
      if (!Platform.isAndroid) {
        await File(savePath).writeAsBytes(pdfBytes);
      }
      _showSnackBar('PDF exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting PDF: $e', isError: true);
    }
  }

  void _onSearchChanged(String query) {
    if(!mounted) return;
    setState(() {
      _currentPage = 0;
      _searchQuery = query;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadProducts);
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      if(!mounted) return;
      setState(() {
        _sortBy = value;
        _currentPage = 0;
      });
      _loadProducts();
    }
  }

  void _toggleSortOrder() {
    if(!mounted) return;
    setState(() => _isAscending = !_isAscending);
    _loadProducts();
  }

  void _changePage(int page) {
    if(!mounted) return;
    setState(() => _currentPage = page);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_totalProducts / _pageSize).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product/Service Management'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildColumnsDiscoveryBanner(),
            Expanded(
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
            child: Row(
              children: [
                Icon(Icons.add_box, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add new $_newItemType',
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
            child: FocusTraversalGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_businessType == BusinessType.both && _columnsConfig.type) ...[
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
                        onSelectionChanged: (val) {
                          if(!mounted) return;
                          setState(()
                          {
                            _newItemType = val.first;
                            if(_newItemType == 'service' || !_columnsConfig.stock)
                            {
                              _unlimitedStock = true;
                            }
                            else
                            {
                              _unlimitedStock = false;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildFormField(_nameController, 'Name (In English)', Icons.inventory_2,
                        maxLength: 100, onSubmitted: _addProduct),
                    const SizedBox(height: 16),
                    if (_columnsConfig.aliasName) ...[
                      _buildFormField(_aliasNameController,
                          'Alias Name (for invoice PDF)', Icons.translate,
                          maxLength: 100,
                          required: false,
                          helperText : "Alias Name is an optional local-language display name used only on PDF invoices.(You can enable this in InvoiceSettings Page)"
                              "\n You can enter the alias in any supported language, \n"
                              "such as Malayalam, Tamil, Kannada, Hindi, Telugu, Marathi, or others, to generate customer-friendly invoices."),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.hsncode) ...[
                      _buildFormField(_hsnCodeController, 'HSN/SAC', Icons.qr_code,
                          maxLength: 100, required: false),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.description) ...[
                      _buildFormField(
                          _descriptionController, 'Description', Icons.description,
                          maxLines: 3, maxLength: 100, required: false),
                      const SizedBox(height: 16),
                    ],
                    _buildFormField(_priceController, 'Price', Icons.attach_money,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        isPrice: true,
                        prefixText: '$_currencySymbol ',
                        onSubmitted: _addProduct),
                    const SizedBox(height: 16),
                    if (_columnsConfig.purchasePrice) ...[
                      _buildFormField(_purchasePriceController,
                          'Purchase Price', Icons.shopping_cart_outlined,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          isPrice: true,
                          required: _newItemType == 'service' ? false : true,
                          prefixText: '$_currencySymbol '),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.defaultDiscount) ...[
                      _buildFormField(
                          _defaultDiscountController,
                          'Default Discount', Icons.discount,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          isPrice: true,
                          required: false,
                          prefixText: '$_currencySymbol '),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.taxRate) ...[
                      _buildFormField(
                          _taxRateController, 'Tax Rate (%)', Icons.percent,
                          keyboardType: TextInputType.number, isTaxRate: true),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _priceIncludesTax,
                        onChanged: (v) {
                          if (!mounted) return;
                          setState(() => _priceIncludesTax = v ?? false);
                        },
                        title: const Text('Price Includes Tax'),
                        subtitle: const Text(
                            'Product price already includes tax (per-item tax mode only)'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.stock) ...[
                      _buildFormField(_stockController, 'Stock', Icons.inventory,
                          keyboardType: TextInputType.number,
                          isStock: true,
                          required: !_unlimitedStock,
                          enabled: !_unlimitedStock),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _unlimitedStock,
                        onChanged: (v) {
                          if (!mounted) return;
                          setState(() => _unlimitedStock = v ?? false);
                        },
                        title: const Text('Unlimited stock'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.unit) ...[
                      _buildUnitField(
                        selectedUnit: _selectedUnit,
                        customController: _customUnitController,
                        onUnitChanged: (v) {
                          if (!mounted) return;
                          setState(() => _selectedUnit = v);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_columnsConfig.productMetadata)
                      _buildMetadataSection(
                        storageLocationCtrl: _storageLocationController,
                        containerNumberCtrl: _containerNumberController,
                        batchNumberCtrl: _batchNumberController,
                        supplierNameCtrl: _supplierNameController,
                        skuCodeCtrl: _skuCodeController,
                        notesCtrl: _notesController,
                        expiryDate: _expiryDate,
                        manufactureDate: _manufactureDate,
                        datePattern: _datePattern,
                        onExpiryChanged: (d) {
                          if (!mounted) return;
                          setState(() => _expiryDate = d);
                        },
                        onManufactureChanged: (d) {
                          if (!mounted) return;
                          setState(() => _manufactureDate = d);
                        },
                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildUnitField({
    required String selectedUnit,
    required TextEditingController customController,
    required ValueChanged<String> onUnitChanged,
    bool readOnly = false,
  }) {
    return _UnitField(
      initialUnit: selectedUnit,
      customController: customController,
      onUnitChanged: onUnitChanged,
      readOnly: readOnly,
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
    String? helperText,
    bool enabled = true,
    VoidCallback? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onFieldSubmitted: (value) {
        if (onSubmitted != null) {
          onSubmitted();
        } else {
          FocusScope.of(context).nextFocus();
        }
      },
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
        helper: helperText != null ? Tooltip(
          message: helperText,
          textStyle: TextStyle(fontSize: 15),
          decoration: BoxDecoration(
            color: Colors.grey.shade900, // Background color
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: InkWell(
            onTap: null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.info_outline, size: 18, color: Colors.indigo[400]),
            ),
          ),
        ) : null
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
                  if(!mounted) return;
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 12,
                    radius: const Radius.circular(6),
                    interactive: true,
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
        ? 'Products/Services($_allProductsCount)'
        : (_typeFilter == "product")
            ? 'Products($_totalProducts)'
            : 'Services($_totalProducts)');
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
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              size: 80, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first product to get started'
                : 'Try adjusting your search',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        if (_columnsConfig.aliasName)
          const DataColumn(
              label:
                  Text('Alias', style: TextStyle(fontWeight: FontWeight.bold))),
        if (_businessType == BusinessType.both && _columnsConfig.type)
          const DataColumn(
              label:Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
        if (_columnsConfig.hsncode)
          const DataColumn(
              label: Text('HSN/SAC',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        if (_columnsConfig.description)
          const DataColumn(
              label: Text('Description',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label:
                Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
        if (_columnsConfig.purchasePrice)
          const DataColumn(
              label: Text('Purchase Price',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        if (_columnsConfig.defaultDiscount)
          const DataColumn(
              label:
              Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
        if (_columnsConfig.taxRate)
          const DataColumn(
              label: Text('Tax Rate',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        if (_columnsConfig.stock)
          const DataColumn(
              label:
                  Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
        if (_columnsConfig.unit)
          const DataColumn(
              label:
                  Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(
            label:
                Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: List.generate(_products.length, (index) {
        final p = _products[index];
        final serialNumber = (_currentPage * _pageSize) + index + 1;
        return DataRow(
          color: WidgetStateProperty.all(
            index.isEven ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          cells: [
            DataCell(Text(serialNumber.toString())),
            DataCell(Text(
                p.name.length > 30 ? '${p.name.substring(0, 30)}...' : p.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500))),
            if (_columnsConfig.aliasName) DataCell(Text(p.aliasName ?? '—')),
            if (_businessType == BusinessType.both && _columnsConfig.type)
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
            if (_columnsConfig.hsncode) DataCell(Text(p.hsncode)),
            if (_columnsConfig.description)
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
            if (_columnsConfig.purchasePrice)
            DataCell(
              p.purchasePrice > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.purchasePrice > p.price
                            ? Colors.red.shade50
                            : Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_currencySymbol${p.purchasePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.purchasePrice > p.price
                              ? Colors.red.shade700
                              : Colors.blueGrey.shade700,
                        ),
                      ),
                    )
                  : Text('—', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            if (_columnsConfig.defaultDiscount)
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
            if (_columnsConfig.taxRate)
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
            if (_columnsConfig.stock)
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.unlimitedStock
                      ? Colors.blue.shade50
                      : p.stock > 10
                          ? Colors.green.shade50
                          : p.stock > 0
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.unlimitedStock ? '∞' : p.stock.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: p.unlimitedStock
                        ? Colors.blue.shade700
                        : p.stock > 10
                            ? Colors.green.shade700
                            : p.stock > 0
                                ? Colors.orange.shade700
                                : Colors.red.shade700,
                  ),
                ),
              ),
            ),
            if (_columnsConfig.unit)
              DataCell(Text(p.unit.isEmpty ? '—' : p.unit.toUpperCase())),
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
                  if (n == null || !mounted) return;
                  setState(() {
                    _pageSize = n;
                    _currentPage = 0;
                  });
                  _loadProducts();
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Showing ${_currentPage * _pageSize + 1} - ${(_currentPage * _pageSize + _pageSize).clamp(0, _totalProducts)} of $_totalProducts',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
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

/// Unit dropdown + "Custom…" text field. Whether the custom field is shown
/// is tracked as sticky local state (set the moment "Custom…" is picked) —
/// NOT re-derived from the current unit string each rebuild, since that
/// string is still empty right after picking "Custom…" and would otherwise
/// make the field disappear before the user can type anything into it.
class _UnitField extends StatefulWidget {
  final String initialUnit;
  final TextEditingController customController;
  final ValueChanged<String> onUnitChanged;
  final bool readOnly;

  const _UnitField({
    required this.initialUnit,
    required this.customController,
    required this.onUnitChanged,
    this.readOnly = false,
  });

  @override
  State<_UnitField> createState() => _UnitFieldState();
}

class _UnitFieldState extends State<_UnitField> {
  late bool _isCustom;
  late String _presetValue;

  @override
  void initState() {
    super.initState();
    _isCustom = widget.initialUnit.isNotEmpty &&
        !ProductUnits.presets.contains(widget.initialUnit);
    _presetValue = _isCustom ? '' : widget.initialUnit;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _isCustom ? 'custom' : _presetValue,
          decoration: InputDecoration(
            labelText: 'Unit',
            prefixIcon: const Icon(Icons.straighten),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            filled: widget.readOnly,
            fillColor: widget.readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('None')),
            for (final u in ProductUnits.presets)
              DropdownMenuItem(value: u, child: Text(u.toUpperCase())),
            const DropdownMenuItem(value: 'custom', child: Text('Custom…')),
          ],
          onChanged: widget.readOnly
              ? null
              : (val) {
                  if (val == null) return;
                  setState(() {
                    _isCustom = val == 'custom';
                    _presetValue = _isCustom ? '' : val;
                  });
                  widget.onUnitChanged(
                      _isCustom ? widget.customController.text.trim() : val);
                },
        ),
        if (_isCustom) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.customController,
            readOnly: widget.readOnly,
            decoration: InputDecoration(
              labelText: 'Custom unit',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
              filled: widget.readOnly,
              fillColor: widget.readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
            ),
            onChanged: widget.onUnitChanged,
          ),
        ],
      ],
    );
  }
}
