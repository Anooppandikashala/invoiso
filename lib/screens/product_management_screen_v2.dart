import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/constants.dart';
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

class ProductManagementScreenV2 extends ConsumerStatefulWidget {
  final User user;
  const ProductManagementScreenV2({super.key, required this.user});

  @override
  ConsumerState<ProductManagementScreenV2> createState() =>
      _ProductManagementScreenV2State();
}

class _ProductManagementScreenV2State extends ConsumerState<ProductManagementScreenV2> {
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

  // ── V2 state ──────────────────────────────────────────────────────────
  // V2 loads the full product list once (for the stat cards / tab counts)
  // and does all filtering, search, sort, and pagination against that
  // in-memory list, rather than round-tripping to the paginated server
  // query for every interaction. _products/_totalProducts/_currentPage/
  // _pageSize are the same fields v1 uses — just populated differently.
  List<Product> _allProductsV2 = [];
  Map<String, ProductMetadata> _productMetadataV2 = {};
  bool _statsLoadingV2 = false;
  int _activeTabV2 = 0; // 0 all, 1 products, 2 services, 3 low stock, 4 out of stock
  bool _showAddPanelV2 = false;
  int _addPanelTabV2 = 0; // 0 Basic Information, 1 Advanced
  bool _addAnotherAfterSavingV2 = false;
  bool _showStatsCardsV2 = true;

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
    _loadStatsV2();
    _loadStatsCardsVisibilityV2();
  }

  Future<void> _loadStatsCardsVisibilityV2() async {
    final v = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.showProductStatsCards);
    if (!mounted) return;
    setState(() => _showStatsCardsV2 = v != 'false');
  }

  Future<void> _toggleStatsCardsV2() async {
    final next = !_showStatsCardsV2;
    setState(() => _showStatsCardsV2 = next);
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.showProductStatsCards, next.toString());
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
        title: const Text('Advanced Information'),
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

    var progressDialogShown = false;
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

      final progress = ValueNotifier<int>(0);
      if (!mounted) return;
      progressDialogShown = true;
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Importing Products'),
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, done, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Checking for duplicates and validating ${dataRows.length} row${dataRows.length == 1 ? '' : 's'}...'),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: dataRows.isEmpty ? null : done / dataRows.length,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  '$done / ${dataRows.length}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ));

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        progress.value = i + 1;
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
      if (progressDialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if(!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      await _showImportPreviewDialog(valid, duplicates, errors, metadataById);
    } catch (e) {
      if (progressDialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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

  @override
  Widget build(BuildContext context) => _buildV2(context);

  // ============================================================
  // V2 — flat / modern layout. Reuses all v1 state, controllers,
  // validation, and repository calls. New pieces:
  //  - stats loaded once as a full list, filtering/search/sort/paging
  //    done in-memory against it (see _applyClientFilterV2)
  //  - a slide-out "Add New Product" panel (Basic/Advanced tabs)
  //    instead of the always-visible left sidebar form
  //  - flat table/cards instead of Card/DataTable chrome
  // ============================================================

  Future<void> _loadStatsV2() async {
    if (!mounted) return;
    setState(() => _statsLoadingV2 = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final all = await repo.getAllProducts();
      final metadata = await repo.getAllProductMetadata();
      if (!mounted) return;
      setState(() {
        _allProductsV2 = all;
        _productMetadataV2 = metadata;
      });
      _applyClientFilterV2();
    } catch (e) {
      _showSnackBar('Error loading products: $e', isError: true);
    } finally {
      if (mounted) setState(() => _statsLoadingV2 = false);
    }
  }

  DateTime? _expiryDateOfV2(Product p) {
    final raw = _productMetadataV2[p.id]?.expiryDate;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _isExpiredV2(Product p) {
    final d = _expiryDateOfV2(p);
    return d != null && d.isBefore(DateTime.now());
  }

  int get _allCountV2 => _allProductsV2.length;
  int get _productsCountV2 =>
      _allProductsV2.where((p) => p.type == 'product').length;
  int get _servicesCountV2 =>
      _allProductsV2.where((p) => p.type == 'service').length;
  int get _lowStockCountV2 => _allProductsV2
      .where((p) => !p.unlimitedStock && p.stock > 0 && p.stock <= 10)
      .length;
  int get _outOfStockCountV2 =>
      _allProductsV2.where((p) => !p.unlimitedStock && p.stock <= 0).length;
  int get _expiredCountV2 => _allProductsV2.where(_isExpiredV2).length;

  // Applies the active tab (type + stock-status), search text, and sort
  // to the full in-memory list, then slices out the current page.
  void _applyClientFilterV2() {
    Iterable<Product> list = _allProductsV2;
    if (_activeTabV2 == 1) list = list.where((p) => p.type == 'product');
    if (_activeTabV2 == 2) list = list.where((p) => p.type == 'service');
    if (_activeTabV2 == 3) {
      list = list.where((p) => !p.unlimitedStock && p.stock > 0 && p.stock <= 10);
    }
    if (_activeTabV2 == 4) {
      list = list.where((p) => !p.unlimitedStock && p.stock <= 0);
    }
    if (_activeTabV2 == 5) {
      list = list.where(_isExpiredV2);
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.aliasName ?? '').toLowerCase().contains(q) ||
          p.hsncode.toLowerCase().contains(q));
    }
    final sorted = list.toList()
      ..sort((a, b) {
        int cmp;
        switch (_sortBy) {
          case 'price':
            cmp = a.price.compareTo(b.price);
            break;
          case 'stock':
            cmp = a.stock.compareTo(b.stock);
            break;
          default:
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return _isAscending ? cmp : -cmp;
      });
    final total = sorted.length;
    final maxPage = total == 0 ? 0 : ((total - 1) / _pageSize).floor();
    if (_currentPage > maxPage) _currentPage = maxPage;
    final start = (_currentPage * _pageSize).clamp(0, total);
    final end = (start + _pageSize).clamp(0, total);
    if (!mounted) return;
    setState(() {
      _totalProducts = total;
      _products = sorted.sublist(start, end);
    });
  }

  void _selectTabV2(int index) {
    if (!mounted) return;
    setState(() {
      _activeTabV2 = index;
      _currentPage = 0;
    });
    _applyClientFilterV2();
  }

  void _onSearchChangedV2(String query) {
    if (!mounted) return;
    setState(() {
      _searchQuery = query;
      _currentPage = 0;
    });
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 300), _applyClientFilterV2);
  }

  // Combines v1's separate sort-field + sort-direction controls into the
  // single "Sort: Name A-Z" style dropdown shown in the mockup.
  void _onSortSelectionV2(String field, bool ascending) {
    if (!mounted) return;
    setState(() {
      _sortBy = field;
      _isAscending = ascending;
      _currentPage = 0;
    });
    _applyClientFilterV2();
  }

  void _changePageV2(int page) {
    if (!mounted) return;
    setState(() => _currentPage = page);
    _applyClientFilterV2();
  }

  Future<void> _addProductV2() async {
    final nameBefore = _nameController.text;
    await _addProduct();
    final succeeded = _nameController.text.isEmpty && nameBefore.trim().isNotEmpty;
    if (succeeded) {
      await _loadStatsV2();
      if (!mounted) return;
      if (!_addAnotherAfterSavingV2) {
        setState(() => _showAddPanelV2 = false);
      }
    }
  }

  Future<void> _editProductV2(Product product) async {
    await _showDetailDialogV2(product, startInEdit: true);
  }

  Future<void> _viewProductV2(Product product) async {
    await _showDetailDialogV2(product, startInEdit: false);
  }

  Future<void> _deleteProductV2(Product product) async {
    await _confirmDelete(product);
    await _loadStatsV2();
  }

  Future<void> _openColumnsSettingsV2() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProductColumnsSettingsScreen()));
    await _loadColumnsConfig();
    await _loadStatsV2();
  }

  BoxDecoration _flatCardDecorationV2(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );

  Widget _sectionLabelV2(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // A PopupMenuButton's `child` should stay non-interactive (PopupMenuButton
  // itself provides the tap-to-open handling) — using a real OutlinedButton
  // with onPressed: null there would render as visually disabled/greyed.
  Widget _menuButtonLookV2(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _statCardV2({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    String? subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.all(16),
      decoration: _flatCardDecorationV2(context),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle ?? '',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
          ],
        ),
    );
  }

  Widget _statCardsRowV2() {
    final cards = [
      _statCardV2(
        label: 'All Products',
        value: '$_allCountV2',
        subtitle: 'Total items',
        icon: Icons.inventory_2_outlined,
        accent: Theme.of(context).primaryColor,
      ),
      _statCardV2(
        label: 'Products',
        value: '$_productsCountV2',
        subtitle: 'Tangible products',
        icon: Icons.widgets_outlined,
        accent: Colors.green,
      ),
      _statCardV2(
        label: 'Services',
        value: '$_servicesCountV2',
        subtitle: 'Non-tangible services',
        icon: Icons.design_services_outlined,
        accent: Colors.orange,
      ),
      _statCardV2(
        label: 'Low Stock',
        value: '$_lowStockCountV2',
        subtitle: 'Need attention',
        icon: Icons.warning_amber_rounded,
        accent: Colors.red,
      ),
    ];

    // Responsive: fit as many equal-width cards per row as the available
    // width allows (min ~170px each, see _statCardV2), wrapping to
    // additional rows instead of squeezing/overflowing on narrow screens.
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minCardWidth = 170.0;
        final perRow = (constraints.maxWidth + spacing) ~/ (minCardWidth + spacing);
        final columns = perRow.clamp(1, cards.length);
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
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
              Text('Product Management',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text('Manage your products and services',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await _showImportDialog();
                await _loadStatsV2();
              },
              icon: const Icon(Icons.upload_file_outlined, size: 16),
              label: const Text('Import'),
            ),
            OutlinedButton.icon(
              onPressed: _exportToCSV,
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export'),
            ),
            if (widget.user.isAdmin())
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) async {
                  if (value == 'export_pdf') await _exportToPDF();
                  if (value == 'delete_all') {
                    await _confirmDeleteAll();
                    await _loadStatsV2();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem<String>(
                    value: 'export_pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Export PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete All Products',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: _menuButtonLookV2(Icons.more_horiz, 'More'),
              ),
            IconButton(
              onPressed: _statsLoadingV2
                  ? null
                  : () async {
                      await _loadStatsV2();
                    },
              icon: _statsLoadingV2
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _showAddPanelV2 = true;
                  _addPanelTabV2 = 0;
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Product'),
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
    const sortOptions = [
      {'label': 'Name A-Z', 'field': 'name', 'asc': true},
      {'label': 'Name Z-A', 'field': 'name', 'asc': false},
      {'label': 'Price Low-High', 'field': 'price', 'asc': true},
      {'label': 'Price High-Low', 'field': 'price', 'asc': false},
      {'label': 'Stock Low-High', 'field': 'stock', 'asc': true},
      {'label': 'Stock High-Low', 'field': 'stock', 'asc': false},
    ];
    final currentLabel = sortOptions.firstWhere(
      (o) => o['field'] == _sortBy && o['asc'] == _isAscending,
      orElse: () => sortOptions.first,
    )['label'] as String;

    return Row(
      children: [
        Expanded(
          child: TextField(
            focusNode: _searchFocusNode,
            onChanged: _onSearchChangedV2,
            decoration: InputDecoration(
              hintText: 'Search products by name, alias, HSN/SAC, SKU…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Filter by stock status',
                onSelected: (value) {
                  if (!mounted) return;
                  setState(() {
                    _currentPage = 0;
                    _activeTabV2 = switch (value) {
                      'low' => 3,
                      'out' => 4,
                      'expired' => 5,
                      _ => (_activeTabV2 >= 3 && _activeTabV2 <= 5) ? 0 : _activeTabV2,
                    };
                  });
                  _applyClientFilterV2();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'all', child: Text('All stock levels')),
                  const PopupMenuItem(value: 'low', child: Text('Low stock')),
                  const PopupMenuItem(value: 'out', child: Text('Out of stock')),
                  if (_columnsConfig.productMetadata && _columnsConfig.metaExpiryDate)
                    const PopupMenuItem(value: 'expired', child: Text('Expired')),
                ],
                child: _menuButtonLookV2(Icons.filter_list, 'Filter'),
              ),
              PopupMenuButton<Map<String, Object>>(
                tooltip: 'Sort',
                onSelected: (opt) =>
                    _onSortSelectionV2(opt['field'] as String, opt['asc'] as bool),
                itemBuilder: (ctx) => sortOptions
                    .map((o) => PopupMenuItem(value: o, child: Text(o['label'] as String)))
                    .toList(),
                child: _menuButtonLookV2(Icons.swap_vert, 'Sort: $currentLabel'),
              ),
              OutlinedButton.icon(
                onPressed: _openColumnsSettingsV2,
                icon: const Icon(Icons.view_column_outlined, size: 16),
                label: const Text('Columns'),
              ),
              IconButton(
                tooltip: _showStatsCardsV2 ? 'Hide stat cards' : 'Show stat cards',
                onPressed: _toggleStatsCardsV2,
                icon: Icon(
                  _showStatsCardsV2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabChipV2(String label, int count, int index) {
    final selected = _activeTabV2 == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: () => _selectTabV2(index),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Theme.of(context).primaryColor : null,
          foregroundColor: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
              color: selected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
        child: Text('$label ($count)'),
      ),
    );
  }

  Widget _tabsRowV2() {
    final showExpiredTab = _columnsConfig.productMetadata && _columnsConfig.metaExpiryDate;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChipV2('All', _allCountV2, 0),
          _tabChipV2('Products', _productsCountV2, 1),
          _tabChipV2('Services', _servicesCountV2, 2),
          _tabChipV2('Low Stock', _lowStockCountV2, 3),
          _tabChipV2('Out of Stock', _outOfStockCountV2, 4),
          if (showExpiredTab) _tabChipV2('Expired', _expiredCountV2, 5),
        ],
      ),
    );
  }

  Widget _typeTagV2(String type) {
    final isService = type == 'service';
    final color = isService ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isService ? 'Service' : 'Product',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color.shade700),
      ),
    );
  }

  Widget _stockCellV2(Product p) {
    if (p.unlimitedStock) {
      return const Text('∞');
    }
    final color = p.stock > 10
        ? null
        : p.stock > 0
            ? Colors.orange[700]
            : Colors.red[700];
    return Text('${p.stock}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600));
  }

  Widget _tableRowV2(Product p, int index) {
    final serial = _currentPage * _pageSize + index + 1;
    final showExpiry = _columnsConfig.productMetadata && _columnsConfig.metaExpiryDate;
    final expiryDate = showExpiry ? _expiryDateOfV2(p) : null;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text('$serial',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if ((p.aliasName ?? '').isNotEmpty || _columnsConfig.type)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        if (_businessType == BusinessType.both && _columnsConfig.type)
                          _typeTagV2(p.type),
                        if ((p.aliasName ?? '').isNotEmpty) ...[
                          if (_businessType == BusinessType.both && _columnsConfig.type)
                            const SizedBox(width: 6),
                          Flexible(
                            child: Text(p.aliasName!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_columnsConfig.hsncode)
            Expanded(
              flex: 2,
              child: Text(p.hsncode.isEmpty ? '—' : p.hsncode,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          Expanded(
            flex: 2,
            child: Text('$_currencySymbol${p.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (_columnsConfig.purchasePrice)
            Expanded(
              flex: 2,
              child: Text(
                  p.purchasePrice > 0
                      ? '$_currencySymbol${p.purchasePrice.toStringAsFixed(2)}'
                      : '—',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          if (_columnsConfig.stock)
            Expanded(flex: 1, child: _stockCellV2(p)),
          if (_columnsConfig.taxRate)
            Expanded(flex: 1, child: Text('${p.tax_rate}%')),
          if (showExpiry)
            Expanded(
              flex: 2,
              child: expiryDate == null
                  ? Text('—',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExpired)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.error_outline, size: 14, color: Colors.red),
                          ),
                        Text(DateFormat(_datePattern).format(expiryDate),
                            style: TextStyle(
                                fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                color: isExpired
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
            ),
          SizedBox(
            width: 116,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _viewProductV2(p),
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editProductV2(p),
                  tooltip: 'Edit',
                ),
                if (widget.user.isAdmin())
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _deleteProductV2(p),
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderRowV2() {
    TextStyle style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text('SL. NO.', style: style)),
          Expanded(flex: 3, child: Text('NAME / ALIAS', style: style)),
          if (_columnsConfig.hsncode) Expanded(flex: 2, child: Text('HSN / SAC', style: style)),
          Expanded(flex: 2, child: Text('PRICE', style: style)),
          if (_columnsConfig.purchasePrice)
            Expanded(flex: 2, child: Text('PURCHASE', style: style)),
          if (_columnsConfig.stock) Expanded(flex: 1, child: Text('STOCK', style: style)),
          if (_columnsConfig.taxRate) Expanded(flex: 1, child: Text('TAX %', style: style)),
          if (_columnsConfig.productMetadata && _columnsConfig.metaExpiryDate)
            Expanded(flex: 2, child: Text('EXPIRY DATE', style: style)),
          SizedBox(width: 116, child: Text('', style: style)),
        ],
      ),
    );
  }

  // This widget now sizes itself naturally instead of relying on `Expanded`
  // to fill whatever space a bounded ancestor gives it. The list is
  // shrink-wrapped (its own scrolling disabled) because the *page* is
  // already inside a CustomScrollView — so instead of this Column being
  // squeezed into a fixed box and overflowing when its fixed rows (header +
  // pagination) don't fit, it just reports its true height and the page
  // scrolls further if needed. A naturally-sized widget can't overflow.
  Widget _tableSectionV2() {
    final totalPages = _totalProducts == 0 ? 1 : ((_totalProducts - 1) ~/ _pageSize) + 1;
    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tableHeaderRowV2(),
          _statsLoadingV2 && _allProductsV2.isEmpty
              ? const SizedBox(
                  height: 240, child: Center(child: CircularProgressIndicator()))
              : _products.isEmpty
                  ? SizedBox(height: 240, child: _buildEmptyState())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _products.length,
                      itemBuilder: (context, index) =>
                          _tableRowV2(_products[index], index),
                    ),
          _paginationV2(totalPages),
        ],
      ),
    );
  }

  Widget _paginationV2(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      // Was a Wrap(alignment: spaceBetween, ...): when the row got narrow it
      // would silently wrap onto a second line, growing this widget's
      // height and stealing space the table's Expanded(ListView) needed —
      // the direct cause of the reported "RenderFlex overflowed by 55
      // pixels" error. A horizontally-scrolling Row keeps this bar's
      // height constant no matter how narrow the table gets.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Text(
            'Showing ${_totalProducts == 0 ? 0 : _currentPage * _pageSize + 1} to '
            '${(_currentPage * _pageSize + _pageSize).clamp(0, _totalProducts)} of $_totalProducts products',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rows per page',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox(),
                itemHeight: 48,
                items: [10, 25, 50, 100]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (n) {
                  if (n == null || !mounted) return;
                  setState(() {
                    _pageSize = n;
                    _currentPage = 0;
                  });
                  _applyClientFilterV2();
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed:
                    _currentPage > 0 ? () => _changePageV2(_currentPage - 1) : null,
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
                onPressed: _currentPage < totalPages - 1
                    ? () => _changePageV2(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  // ── Slide-out "Add New Product" panel ──────────────────────────────────

  // Sectioned form used by the Add panel — same section grouping/order as
  // the View/Edit dialog (General / Pricing / Inventory / Advanced
  // Information) instead of the old Basic Information / Advanced tabs.
  Widget _addPanelFormV2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabelV2('General'),
        _buildFormField(_nameController, 'Name', Icons.inventory_2,
            maxLength: 100, onSubmitted: _addProductV2),
        if (_columnsConfig.aliasName) ...[
          const SizedBox(height: 16),
          _buildFormField(_aliasNameController,
              'Alias Name (for invoice PDF)', Icons.translate,
              maxLength: 100,
              required: false,
              helperText:
                  'Optional local-language display name used only on PDF invoices.'),
        ],
        if (_columnsConfig.description) ...[
          const SizedBox(height: 16),
          _buildFormField(
              _descriptionController, 'Description', Icons.description,
              maxLines: 3, maxLength: 500, required: false),
        ],
        if (_columnsConfig.hsncode) ...[
          const SizedBox(height: 16),
          _buildFormField(_hsnCodeController, 'HSN/SAC', Icons.qr_code,
              maxLength: 100, required: false),
        ],
        const SizedBox(height: 20),
        _sectionLabelV2('Pricing'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(_priceController, 'Sale Price', Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isPrice: true,
                  prefixText: '$_currencySymbol ',
                  onSubmitted: _addProductV2),
            ),
            if (_columnsConfig.purchasePrice) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                    _purchasePriceController, 'Purchase Price', Icons.shopping_cart_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isPrice: true,
                    required: _newItemType != 'service',
                    prefixText: '$_currencySymbol '),
              ),
            ],
          ],
        ),
        if (_columnsConfig.defaultDiscount) ...[
          const SizedBox(height: 16),
          _buildFormField(
              _defaultDiscountController, 'Default Discount', Icons.discount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              isPrice: true,
              required: false,
              prefixText: '$_currencySymbol '),
        ],
        if (_columnsConfig.taxRate) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildFormField(_taxRateController, 'Tax (%)', Icons.percent,
                    keyboardType: TextInputType.number, isTaxRate: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _priceIncludesTax,
                      onChanged: (v) {
                        if (!mounted) return;
                        setState(() => _priceIncludesTax = v ?? false);
                      },
                    ),
                    Flexible(
                      child: Text('Price includes tax',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('Per-item tax mode only',
                style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
        if (_columnsConfig.stock || _columnsConfig.unit) ...[
          const SizedBox(height: 12),
          _sectionLabelV2('Inventory'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_columnsConfig.stock)
                Expanded(
                  child: _buildFormField(_stockController, 'Stock', Icons.inventory,
                      keyboardType: TextInputType.number,
                      isStock: true,
                      required: !_unlimitedStock,
                      enabled: !_unlimitedStock),
                ),
              if (_columnsConfig.stock && _columnsConfig.unit) const SizedBox(width: 12),
              if (_columnsConfig.unit)
                Expanded(
                  child: _buildUnitField(
                    selectedUnit: _selectedUnit,
                    customController: _customUnitController,
                    onUnitChanged: (v) {
                      if (!mounted) return;
                      setState(() => _selectedUnit = v);
                    },
                  ),
                ),
            ],
          ),
          if (_columnsConfig.stock)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              value: _unlimitedStock,
              onChanged: (v) {
                if (!mounted) return;
                setState(() => _unlimitedStock = v ?? false);
              },
              title: const Text('Unlimited stock'),
              subtitle: const Text('Track infinite stock for this product'),
            ),
        ],
        if (_columnsConfig.productMetadata) ...[
          const SizedBox(height: 8),
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
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Tip: Enable custom fields from Columns to add more details.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addPanelV2() {
    // Width is now controlled by the Positioned wrapper in _buildV2 (fixed
    // 400 on wide screens, screen-width-minus-margins on narrow ones), so
    // this no longer hardcodes its own width.
    final showTypeToggle = _businessType == BusinessType.both && _columnsConfig.type;
    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New ${_newItemType == 'service' ? 'Service' : 'Product'}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Enter product details',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (showTypeToggle) ...[
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'product',
                          label: Text('Product'),
                          icon: Icon(Icons.inventory_2_outlined, size: 14)),
                      ButtonSegment(
                          value: 'service',
                          label: Text('Service'),
                          icon: Icon(Icons.design_services_outlined, size: 14)),
                    ],
                    selected: {_newItemType},
                    onSelectionChanged: (val) {
                      if (!mounted) return;
                      setState(() {
                        _newItemType = val.first;
                        _unlimitedStock = _newItemType == 'service' || !_columnsConfig.stock;
                      });
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _showAddPanelV2 = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: FocusTraversalGroup(
                child: Form(
                  key: _formKey,
                  child: _addPanelFormV2(),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _addAnotherAfterSavingV2,
                      onChanged: (v) => setState(
                          () => _addAnotherAfterSavingV2 = v ?? false),
                    ),
                    const Expanded(child: Text('Add another after saving')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
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
                        onPressed: _isLoading ? null : _addProductV2,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save Product'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── View/Edit dialog ─────────────────────────────────────────────────
  // Same content/layout as the old right-side panel (sectioned General/
  // Pricing/Inventory groups, Product/Service toggle, Advanced Info,
  // tip banner) but shown as a proper Dialog instead. Each open creates
  // fresh local controllers scoped to this call (same pattern as the
  // original _showProductDialog) so there's no shared-controller state
  // to accidentally double-dispose between opens — that was the bug
  // that made the panel stop reopening after being closed.

  Future<void> _showDetailDialogV2(Product product, {required bool startInEdit}) async {
    final metadata =
        await ref.read(productRepositoryProvider).getProductMetadata(product.id);
    if (!mounted) return;

    final nameCtrl = TextEditingController(text: product.name);
    final aliasCtrl = TextEditingController(text: product.aliasName ?? '');
    final descCtrl = TextEditingController(text: product.description);
    final hsnCtrl = TextEditingController(text: product.hsncode);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final purchaseCtrl = TextEditingController(
        text: product.purchasePrice > 0 ? product.purchasePrice.toString() : '0.0');
    final discountCtrl = TextEditingController(
        text: product.defaultDiscount > 0 ? product.defaultDiscount.toString() : '0.0');
    final taxCtrl = TextEditingController(text: product.tax_rate.toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final customUnitCtrl = TextEditingController(
        text: ProductUnits.presets.contains(product.unit) ? '' : product.unit);
    final storageCtrl = TextEditingController(text: metadata?.storageLocation ?? '');
    final containerCtrl = TextEditingController(text: metadata?.containerNumber ?? '');
    final batchCtrl = TextEditingController(text: metadata?.batchNumber ?? '');
    final supplierCtrl = TextEditingController(text: metadata?.supplierName ?? '');
    final skuCtrl = TextEditingController(text: metadata?.skuCode ?? '');
    final notesCtrl = TextEditingController(text: metadata?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    String itemType = product.type;
    String unit = product.unit;
    bool priceIncludesTax = product.priceIncludesTax;
    bool unlimitedStock = !_columnsConfig.stock ? true : product.unlimitedStock;
    DateTime? expiryDate = _parseIsoDate(metadata?.expiryDate);
    DateTime? manufactureDate = _parseIsoDate(metadata?.manufactureDate);
    bool isEdit = startInEdit;
    bool isSaving = false;

    void disposeAll() {
      nameCtrl.dispose();
      aliasCtrl.dispose();
      descCtrl.dispose();
      hsnCtrl.dispose();
      priceCtrl.dispose();
      purchaseCtrl.dispose();
      discountCtrl.dispose();
      taxCtrl.dispose();
      stockCtrl.dispose();
      customUnitCtrl.dispose();
      storageCtrl.dispose();
      containerCtrl.dispose();
      batchCtrl.dispose();
      supplierCtrl.dispose();
      skuCtrl.dispose();
      notesCtrl.dispose();
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setDialogState) {
          Widget field(
            TextEditingController controller,
            String label,
            IconData icon, {
            int maxLines = 1,
            int? maxLength,
            TextInputType? keyboardType,
            bool isPrice = false,
            bool isStock = false,
            bool isTaxRate = false,
            String? prefixText,
          }) {
            return _buildDialogTextField(
              controller,
              label,
              icon,
              readOnly: !isEdit,
              maxLines: maxLines,
              maxLength: maxLength,
              keyboardType: keyboardType,
              isPrice: isPrice,
              isStock: isStock,
              isTaxRate: isTaxRate,
              prefixText: prefixText,
            );
          }

          Widget sectionLabel(String text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                text.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          Future<void> save() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            final price = double.parse(priceCtrl.text.trim());
            final purchasePrice = double.tryParse(purchaseCtrl.text.trim()) ?? 0.0;
            if (!await _confirmIfSellingAtLoss(price, purchasePrice)) return;
            setDialogState(() => isSaving = true);
            try {
              final updated = Product(
                id: product.id,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                price: price,
                stock: unlimitedStock ? 0 : int.parse(stockCtrl.text.trim()),
                hsncode: hsnCtrl.text.trim(),
                tax_rate: int.parse(taxCtrl.text.trim()),
                type: itemType,
                defaultDiscount: double.tryParse(discountCtrl.text.trim()) ?? 0.0,
                purchasePrice: purchasePrice,
                aliasName: aliasCtrl.text.trim().isEmpty ? null : aliasCtrl.text.trim(),
                unit: unit.trim(),
                unlimitedStock: unlimitedStock,
                priceIncludesTax: priceIncludesTax,
              );
              await ref.read(productRepositoryProvider).updateProduct(updated);
              await ref.read(productRepositoryProvider).upsertProductMetadata(
                    ProductMetadata(
                      productId: updated.id,
                      storageLocation: storageCtrl.text.trim(),
                      containerNumber: containerCtrl.text.trim(),
                      batchNumber: batchCtrl.text.trim(),
                      expiryDate: _isoDate(expiryDate),
                      manufactureDate: _isoDate(manufactureDate),
                      supplierName: supplierCtrl.text.trim(),
                      skuCode: skuCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    ),
                  );
              await _loadStatsV2();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _showSnackBar('Product/Service updated successfully!');
            } finally {
              setDialogState(() => isSaving = false);
            }
          }

          final showTypeToggle = _businessType == BusinessType.both && _columnsConfig.type;
          final screenSize = MediaQuery.of(dialogContext).size;
          final dialogWidth = (screenSize.width * 0.55).clamp(560.0, 760.0);
          final dialogMaxHeight = (screenSize.height * 0.88).clamp(500.0, 880.0);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              child: SizedBox(
                width: dialogWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEdit ? 'Edit Product' : 'View Product',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(isEdit ? 'Update product details' : 'Product details',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        if (showTypeToggle) ...[
                          const SizedBox(width: 8),
                          if (isEdit)
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                    value: 'product',
                                    label: Text('Product'),
                                    icon: Icon(Icons.inventory_2_outlined, size: 14)),
                                ButtonSegment(
                                    value: 'service',
                                    label: Text('Service'),
                                    icon:
                                        Icon(Icons.design_services_outlined, size: 14)),
                              ],
                              selected: {itemType},
                              onSelectionChanged: (val) =>
                                  setDialogState(() => itemType = val.first),
                            )
                          else
                            Chip(
                              avatar: Icon(
                                  itemType == 'service'
                                      ? Icons.design_services_outlined
                                      : Icons.inventory_2_outlined,
                                  size: 14),
                              label: Text(itemType == 'service' ? 'Service' : 'Product'),
                            ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionLabel('General'),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: field(nameCtrl, 'Product Name',
                                      Icons.inventory_2, maxLength: 100),
                                ),
                                if (_columnsConfig.aliasName) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: field(aliasCtrl,
                                        'Alias Name (for invoice PDF)', Icons.translate,
                                        maxLength: 100),
                                  ),
                                ],
                              ],
                            ),
                            if (_columnsConfig.description) ...[
                              const SizedBox(height: 16),
                              field(descCtrl, 'Description', Icons.description,
                                  maxLines: 3, maxLength: 500),
                            ],
                            if (_columnsConfig.hsncode) ...[
                              const SizedBox(height: 16),
                              field(hsnCtrl, 'HSN / SAC', Icons.qr_code, maxLength: 100),
                            ],
                            const SizedBox(height: 20),
                            sectionLabel('Pricing'),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: field(priceCtrl, 'Price', Icons.attach_money,
                                      keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true),
                                      isPrice: true,
                                      prefixText: '$_currencySymbol '),
                                ),
                                if (_columnsConfig.purchasePrice) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: field(purchaseCtrl, 'Purchase Price',
                                        Icons.shopping_cart_outlined,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true),
                                        isPrice: true,
                                        prefixText: '$_currencySymbol '),
                                  ),
                                ],
                              ],
                            ),
                            if (_columnsConfig.defaultDiscount) ...[
                              const SizedBox(height: 16),
                              field(discountCtrl, 'Default Discount', Icons.discount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  isPrice: true,
                                  prefixText: '$_currencySymbol '),
                            ],
                            if (_columnsConfig.taxRate) ...[
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: field(
                                        taxCtrl, 'Tax Rate (%)', Icons.percent,
                                        keyboardType: TextInputType.number,
                                        isTaxRate: true),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: priceIncludesTax,
                                          onChanged: !isEdit
                                              ? null
                                              : (v) => setDialogState(
                                                  () => priceIncludesTax = v ?? false),
                                        ),
                                        Flexible(
                                          child: Text('Price includes tax',
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(dialogContext)
                                                  .textTheme
                                                  .bodyMedium),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 4, top: 2),
                                child: Text('Per-item tax mode only',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color:
                                            Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                              ),
                            ],
                            if (_columnsConfig.stock || _columnsConfig.unit) ...[
                              const SizedBox(height: 12),
                              sectionLabel('Inventory'),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_columnsConfig.stock)
                                    Expanded(
                                      child: field(stockCtrl, 'Stock', Icons.inventory,
                                          keyboardType: TextInputType.number,
                                          isStock: !unlimitedStock),
                                    ),
                                  if (_columnsConfig.stock && _columnsConfig.unit)
                                    const SizedBox(width: 12),
                                  if (_columnsConfig.unit)
                                    Expanded(
                                      child: _buildUnitField(
                                        selectedUnit: unit,
                                        customController: customUnitCtrl,
                                        onUnitChanged: (v) =>
                                            setDialogState(() => unit = v),
                                        readOnly: !isEdit,
                                      ),
                                    ),
                                ],
                              ),
                              if (_columnsConfig.stock)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  value: unlimitedStock,
                                  onChanged: !isEdit
                                      ? null
                                      : (v) => setDialogState(
                                          () => unlimitedStock = v ?? false),
                                  title: const Text('Unlimited stock'),
                                  subtitle:
                                      const Text('Track infinite stock for this product'),
                                ),
                            ],
                            if (_columnsConfig.productMetadata) ...[
                              const SizedBox(height: 8),
                              _buildMetadataSection(
                                storageLocationCtrl: storageCtrl,
                                containerNumberCtrl: containerCtrl,
                                batchNumberCtrl: batchCtrl,
                                supplierNameCtrl: supplierCtrl,
                                skuCodeCtrl: skuCtrl,
                                notesCtrl: notesCtrl,
                                expiryDate: expiryDate,
                                manufactureDate: manufactureDate,
                                datePattern: _datePattern,
                                readOnly: !isEdit,
                                onExpiryChanged: (d) =>
                                    setDialogState(() => expiryDate = d),
                                onManufactureChanged: (d) =>
                                    setDialogState(() => manufactureDate = d),
                              ),
                            ],
                            if (isEdit) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.xsmall),
                                  border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline,
                                        size: 16, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                          'Tip: Enable custom fields from Columns to add more details.',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(dialogContext)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Theme.of(dialogContext).colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (widget.user.isAdmin())
                          OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await _deleteProductV2(product);
                            },
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            label: const Text('Delete Product',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        const Spacer(),
                        if (isEdit) ...[
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: isSaving ? null : save,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Save Changes'),
                          ),
                        ] else ...[
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => setDialogState(() => isEdit = true),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          );
        });
      },
    );
    // showDialog's future completes on Navigator.pop, before the dialog's
    // close (exit) animation finishes rebuilding the still-mounted subtree.
    // Delay disposal past that or the fields get used-after-dispose.
    Future.delayed(const Duration(milliseconds: 300), disposeAll);
  }


  Widget _buildV2(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The table section (`_tableSectionV2`) no longer relies on
            // `Expanded` to fill leftover space — it sizes itself naturally
            // (header row + actual row heights + pagination row), and sits
            // in a plain SliverToBoxAdapter below the rest of the page's
            // content, inside this CustomScrollView. Since nothing here
            // is forced into a box smaller than it needs, there is nothing
            // to overflow: if the natural content is taller than the
            // visible viewport, the page simply scrolls further to show it,
            // and if it fits (e.g. only a couple of products), it fits with
            // no extra scrolling — no guessed heights involved anywhere.
            final isNarrow = constraints.maxWidth < 700;

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
                            _buildColumnsDiscoveryBanner(),
                            _headerBarV2(),
                            const SizedBox(height: 12),
                            if (_showStatsCardsV2) ...[
                              _statCardsRowV2(),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: _flatCardDecorationV2(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _searchFilterRowV2(),
                                  const SizedBox(height: 10),
                                  _tabsRowV2(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: _tableSectionV2(),
                      ),
                    ),
                  ],
                ),
                // The Add/Edit panel now floats as an overlay on top of the
                // page instead of living in a Row next to the main content.
                // Previously it was a fixed-width (400px) sibling in a Row,
                // which forced the main content's Expanded down to almost
                // nothing (and could itself overflow) on narrower windows.
                // As an overlay it never steals width from the table.
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
                    width: isNarrow
                        ? constraints.maxWidth - 32
                        : 550,
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
