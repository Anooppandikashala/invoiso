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
import 'package:invoiso/l10n/app_localizations.dart';
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
    _loadListColumnsV2();
    _loadColumnsBannerDismissed();
  }

  ProductColumnsConfig _columnsConfig = const ProductColumnsConfig();
  bool _showColumnsBanner = false;

  // Which optional columns show in the list table. Independent of the
  // form-field config above; a column still needs its form field on too.
  // 'aliasName' is not a column — it shows "(alias)" under the product name —
  // so it is excluded from the max-columns count.
  static const int _maxVisibleListColumns = 10;
  static const Map<String, bool> _listColumnDefaults = {
    'aliasName': true,
    'description': false,
    'hsncode': true,
    'purchasePrice': true,
    'stock': true,
    'taxRate': true,
    'unit': false,
    'defaultDiscount': false,
    'storageLocation': false,
    'containerNumber': false,
    'batchNumber': false,
    'expiryDate': true,
    'manufactureDate': false,
    'supplierName': false,
    'skuCode': false,
    'notes': false,
  };
  Map<String, bool> _listColumnsV2 = Map.of(_listColumnDefaults);

  Future<void> _loadColumnsConfig() async {
    final config = await ref.read(settingsRepositoryProvider).getProductColumnsConfig();
    if (!mounted) return;
    setState(() {
      _columnsConfig = config;
      if (!config.stock) _unlimitedStock = true;
    });
  }

  Future<void> _loadListColumnsV2() async {
    final saved =
        await ref.read(settingsRepositoryProvider).getProductListColumns();
    if (!mounted) return;
    setState(() => _listColumnsV2 = {..._listColumnDefaults, ...saved});
  }

  // A form field being disabled hides its list column entirely (as before).
  bool _listColumnFieldEnabled(String key) {
    final c = _columnsConfig;
    switch (key) {
      case 'aliasName':
        return c.aliasName;
      case 'description':
        return c.description;
      case 'hsncode':
        return c.hsncode;
      case 'purchasePrice':
        return c.purchasePrice;
      case 'stock':
        return c.stock;
      case 'taxRate':
        return c.taxRate;
      case 'unit':
        return c.unit;
      case 'defaultDiscount':
        return c.defaultDiscount;
      case 'storageLocation':
        return c.productMetadata && c.metaStorageLocation;
      case 'containerNumber':
        return c.productMetadata && c.metaContainerNumber;
      case 'batchNumber':
        return c.productMetadata && c.metaBatchNumber;
      case 'expiryDate':
        return c.productMetadata && c.metaExpiryDate;
      case 'manufactureDate':
        return c.productMetadata && c.metaManufactureDate;
      case 'supplierName':
        return c.productMetadata && c.metaSupplierName;
      case 'skuCode':
        return c.productMetadata && c.metaSkuCode;
      case 'notes':
        return c.productMetadata && c.metaNotes;
      default:
        return false;
    }
  }

  bool _showListCol(String key) =>
      _listColumnFieldEnabled(key) && (_listColumnsV2[key] ?? false);

  // 'aliasName' is a name-cell subtitle, not a table column — excluded here.
  int get _visibleListColumnCount => _listColumnDefaults.keys
      .where((k) => k != 'aliasName' && _showListCol(k))
      .length;

  Future<void> _toggleListColumnV2(String key) async {
    final currentlyOn = _showListCol(key);
    if (key != 'aliasName' &&
        !currentlyOn &&
        _visibleListColumnCount >= _maxVisibleListColumns) {
      return;
    }
    final next = {..._listColumnsV2, key: !(_listColumnsV2[key] ?? false)};
    setState(() => _listColumnsV2 = next);
    await ref.read(settingsRepositoryProvider).setProductListColumns(next);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.productMgmtColumnsBannerTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.productMgmtColumnsBannerSubtitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
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
                    child: Text(AppLocalizations.of(context)!.productMgmtConfigureAction,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: const Color(0xFF93C5FD),
                    onPressed: _dismissColumnsBanner,
                    tooltip: AppLocalizations.of(context)!.actionDismiss,
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
      if (requestId != _loadRequestId || !mounted) return;
      _showSnackBar(AppLocalizations.of(context)!.productMgmtLoadErrorMessage(e.toString()), isError: true);
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
    final l10n = AppLocalizations.of(context)!;
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
      _showSnackBar(l10n.productMgmtAddedMessage);
    } catch (e) {
      _showSnackBar(l10n.productMgmtAddErrorMessage(e.toString()), isError: true);
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
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.productMgmtSellingAtLossTitle),
        content: Text(
          l10n.productMgmtSellingAtLossMessage(
            '$_currencySymbol${purchasePrice.toStringAsFixed(2)}',
            '$_currencySymbol${price.toStringAsFixed(2)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSaveAnyway),
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

    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l10n.productMgmtAdvancedInformationLabel),
        leading: const Icon(Icons.more_horiz),
        childrenPadding: const EdgeInsets.only(top: 8),
        children: [
          if (_columnsConfig.metaStorageLocation)
            field(storageLocationCtrl, l10n.productMgmtStorageLocationLabel, Icons.place_outlined),
          if (_columnsConfig.metaContainerNumber)
            field(containerNumberCtrl, l10n.productMgmtContainerNumberLabel, Icons.inventory_2_outlined),
          if (_columnsConfig.metaBatchNumber)
            field(batchNumberCtrl, l10n.productMgmtBatchNumberLabel, Icons.tag),
          if (_columnsConfig.metaExpiryDate)
            dateField(l10n.productMgmtExpiryDateLabel, expiryDate, onExpiryChanged),
          if (_columnsConfig.metaManufactureDate)
            dateField(l10n.productMgmtManufactureDateLabel, manufactureDate, onManufactureChanged),
          if (_columnsConfig.metaSupplierName)
            field(supplierNameCtrl, l10n.productMgmtSupplierNameLabel, Icons.local_shipping_outlined),
          if (_columnsConfig.metaSkuCode)
            field(skuCodeCtrl, l10n.productMgmtSkuCodeLabel, Icons.qr_code_2),
          if (_columnsConfig.metaNotes)
            field(notesCtrl, l10n.productMgmtNotesLabel, Icons.notes, maxLines: 3),
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
    bool isRequired = false,
    String? prefixText,
    String? helperText,
    VoidCallback? onSubmitted,
  }) {
    final l10n = AppLocalizations.of(context)!;
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
          if (isRequired) return l10n.fieldRequiredMessage(label);
        }
        if (isPrice) {
          final price = double.tryParse(value!);
          if (price == null || price < 0) return l10n.fieldEnterValidPriceMessage;
        }
        if (isStock) {
          final stock = int.tryParse(value!);
          if (stock == null || stock < 0) return l10n.fieldEnterValidStockMessage;
        }
        if (isTaxRate) {
          final tax = int.tryParse(value!);
          if (tax == null || tax < 0 || tax > 100) return l10n.fieldTaxRangeMessage;
        }
        return null;
      },
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.customerMgmtConfirmDeleteTitle),
          ],
        ),
        content: Text(l10n.customerMgmtDeleteConfirmBody(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      await _loadProducts();
      _showSnackBar(l10n.productMgmtDeletedMessage);
    }
  }

  // ── Sample CSV ────────────────────────────────────────────────────────────

  Future<void> _downloadSampleCSV() async {
    const sample =
        '"name","hsn_code","description","price","tax_rate","stock","type","default_discount","purchase_price","alias_name","unit","unlimited_stock","price_includes_tax","storage_location","container_number","batch_number","expiry_date","manufacture_date","supplier_name","sku_code","notes"\n'
        '"Wireless Mouse","84716010","Ergonomic wireless mouse","599.00","18","50","product","5.00","400.00","","pcs","0","0","Rack A1","","","","","","",""\n'
        '"USB Hub","84734000","4-port USB 3.0 hub","299.00","18","100","product","0","180.00","","pcs","0","0","","CNT-1023","","","","","",""\n'
        '"Annual Support","998314","Annual technical support plan","4999.00","18","0","service","10.00","0","","unit","1","1","","","","","","","",""\n';

    final l10n = AppLocalizations.of(context)!;
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: l10n.customerMgmtSaveSampleCsvDialogTitle,
      fileName: 'products_sample.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (savePath == null) return;

    try {
      await File(savePath).writeAsBytes(utf8.encode('\uFEFF$sample'));
      _showSnackBar(l10n.customerMgmtSampleSavedMessage);
    } catch (e) {
      _showSnackBar(l10n.customerMgmtErrorSavingSampleMessage(e.toString()), isError: true);
    }
  }

  // ── CSV Import ────────────────────────────────────────────────────────────

  Future<void> _showImportDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Text(l10n.productMgmtImportProductsCsvTitle),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.customerMgmtCsvFormatInstructionMessage),
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
                      children: [
                        _TableHeader(l10n.customerMgmtCsvColColumnHeader),
                        _TableHeader(l10n.customerMgmtCsvColRequiredHeader),
                        _TableHeader(l10n.customerMgmtCsvColDescriptionHeader),
                      ],
                    ),
                    _csvRuleRow(context, 'name', true, l10n.productMgmtCsvDescName),
                    _csvRuleRow(context, 'price', true, l10n.productMgmtCsvDescPrice),
                    _csvRuleRow(context, 'hsn_code', false, l10n.productMgmtCsvDescHsnCode),
                    _csvRuleRow(context, 'description', false, l10n.productMgmtCsvDescDescription),
                    _csvRuleRow(context, 'tax_rate', false, l10n.productMgmtCsvDescTaxRate),
                    _csvRuleRow(context, 'stock', false, l10n.productMgmtCsvDescStock),
                    _csvRuleRow(context, 'type', false, l10n.productMgmtCsvDescType),
                    _csvRuleRow(context, 'default_discount', false, l10n.productMgmtCsvDescDefaultDiscount),
                    _csvRuleRow(context, 'purchase_price', false, l10n.productMgmtCsvDescPurchasePrice),
                    _csvRuleRow(context, 'alias_name', false, l10n.productMgmtCsvDescAliasName),
                    _csvRuleRow(context, 'unit', false, l10n.productMgmtCsvDescUnit),
                    _csvRuleRow(context, 'unlimited_stock', false, l10n.productMgmtCsvDescUnlimitedStock),
                    _csvRuleRow(context, 'price_includes_tax', false, l10n.productMgmtCsvDescPriceIncludesTax),
                    _csvRuleRow(context, 'storage_location', false, l10n.productMgmtCsvDescStorageLocation),
                    _csvRuleRow(context, 'container_number', false, l10n.productMgmtCsvDescContainerNumber),
                    _csvRuleRow(context, 'batch_number', false, l10n.productMgmtCsvDescBatchNumber),
                    _csvRuleRow(context, 'expiry_date', false, l10n.productMgmtCsvDescExpiryDate),
                    _csvRuleRow(context, 'manufacture_date', false, l10n.productMgmtCsvDescManufactureDate),
                    _csvRuleRow(context, 'supplier_name', false, l10n.productMgmtCsvDescSupplierName),
                    _csvRuleRow(context, 'sku_code', false, l10n.productMgmtCsvDescSkuCode),
                    _csvRuleRow(context, 'notes', false, l10n.productMgmtCsvDescNotes),
                  ],
                ),
                const SizedBox(height: 16),
                _ruleNote(context, Icons.info_outline,
                    l10n.customerMgmtCsvMaxRowsNote(_csvMaxRows)),
                _ruleNote(context, Icons.info_outline,
                    l10n.productMgmtCsvDuplicateNote),
                _ruleNote(context, Icons.info_outline,
                    l10n.productMgmtCsvMissingRequiredNote),
                _ruleNote(context, Icons.info_outline,
                    l10n.customerMgmtCsvEncodingNote),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx, false);
                    await _downloadSampleCSV();
                  },
                  icon: const Icon(Icons.download),
                  label: Text(l10n.customerMgmtDownloadSampleCsvButton),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.customerMgmtChooseFileButton),
          ),
        ],
      ),
    );
    if (proceed == true) await _importFromCSV();
  }

  static TableRow _csvRuleRow(BuildContext context, String col, bool required, String desc) {
    final l10n = AppLocalizations.of(context)!;
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
            required ? l10n.commonYesLabel : l10n.commonNoLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: required ? Colors.red.shade700 : Theme.of(context).colorScheme.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: l10n.productMgmtSelectCsvDialogTitle,
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
        _showSnackBar(l10n.customerMgmtCsvEmptyMessage, isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // Parse and validate headers
      final headers =
          rows.first.map((h) => h.toString().trim().toLowerCase()).toList();

      if (!headers.contains('name')) {
        _showSnackBar(l10n.customerMgmtCsvMissingNameColumnMessage, isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      if (!headers.contains('price')) {
        _showSnackBar(l10n.productMgmtCsvMissingPriceColumnMessage, isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      for (final col in headers) {
        if (!_csvHeaders.contains(col)) {
          _showSnackBar(
              l10n.customerMgmtUnknownColumnMessage(col, _csvHeaders.join(', ')),
              isError: true);
          if(!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
      }

      final dataRows = rows.skip(1).toList();

      if (dataRows.length > _csvMaxRows) {
        _showSnackBar(
            l10n.customerMgmtCsvTooManyRowsMessage(dataRows.length, _csvMaxRows),
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
          title: Text(l10n.productMgmtImportingTitle),
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, done, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.customerMgmtValidatingRowsMessage(dataRows.length)),
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
          errors.add(l10n.customerMgmtRowMissingNameMessage(i + 2));
          continue;
        }
        final price = double.tryParse(priceStr);
        if (price == null || price < 0) {
          errors.add(l10n.productMgmtRowInvalidPriceMessage(i + 2, priceStr));
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
      _showSnackBar(l10n.customerMgmtCsvReadErrorMessage(e.toString()), isError: true);
    }
  }

  Future<void> _showImportPreviewDialog(
    List<Product> newProducts,
    List<Product> duplicates,
    List<String> errors,
    Map<String, ProductMetadata> metadataById,
  ) async {
    final overwriteFlags = List<bool>.filled(duplicates.length, false);
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total =
              newProducts.length + overwriteFlags.where((f) => f).length;

          return AlertDialog(
            title: Text(l10n.customerMgmtImportPreviewTitle),
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
                          label: Text(l10n.customerMgmtNewCountChip(newProducts.length)),
                          backgroundColor: Colors.green.shade100,
                          avatar: const Icon(Icons.add_box_outlined, size: 16),
                        ),
                        Chip(
                          label: Text(l10n.customerMgmtDuplicatesCountChip(duplicates.length)),
                          backgroundColor: Colors.orange.shade100,
                          avatar: const Icon(Icons.warning_amber, size: 16),
                        ),
                        if (errors.isNotEmpty)
                          Chip(
                            label: Text(l10n.customerMgmtErrorsCountChip(errors.length)),
                            backgroundColor: Colors.red.shade100,
                            avatar: const Icon(Icons.error_outline, size: 16),
                          ),
                      ],
                    ),
                    if (duplicates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(l10n.productMgmtDuplicatesMatchedByNameLabel,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) {
                                overwriteFlags[i] = true;
                              }
                            }),
                            child: Text(l10n.customerMgmtOverwriteAllButton),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) {
                                overwriteFlags[i] = false;
                              }
                            }),
                            child: Text(l10n.customerMgmtSkipAllButton),
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
                                Text(l10n.actionSkip,
                                    style: const TextStyle(fontSize: 12)),
                                Switch(
                                  value: overwriteFlags[i],
                                  onChanged: (v) => setDialogState(
                                      () => overwriteFlags[i] = v),
                                ),
                                Text(l10n.customerMgmtOverwriteLabel,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(l10n.customerMgmtSkippedRowsLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      ...errors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(l10n.customerMgmtErrorBulletLabel(e),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          )),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      l10n.productMgmtWillImportMessage(total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.actionCancel),
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
                label: Text(l10n.customerMgmtImportCountButton(total)),
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
    final l10n = AppLocalizations.of(context)!;
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
      _showSnackBar(l10n.productMgmtImportedMessage(imported));
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(l10n.customerMgmtImportErrorMessage(e.toString()), isError: true);
    }
  }

  // ── Delete All ────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context)!;
    if (_allProductsCount == 0) {
      _showSnackBar(l10n.productMgmtNoProductsToDeleteMessage);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.productMgmtDeleteAllTitle),
        content: Text(l10n.productMgmtDeleteAllBody(_allProductsCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.customerMgmtDeleteAllButton),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(productRepositoryProvider).deleteAllProducts();
      await _loadProducts();
      _showSnackBar(l10n.productMgmtAllDeletedMessage);
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(l10n.productMgmtDeleteAllErrorMessage(e.toString()), isError: true);
    }
  }

  Future<void> _exportToCSV() async {
    final l10n = AppLocalizations.of(context)!;
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
        dialogTitle: l10n.productMgmtSaveProductsCsvDialogTitle,
        fileName: 'products.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(utf8.encode('\uFEFF$csvData'));
      _showSnackBar(l10n.customerMgmtCsvExportedMessage);
    } catch (e) {
      _showSnackBar(l10n.customerMgmtCsvExportErrorMessage(e.toString()), isError: true);
    }
  }

  Future<void> _exportToPDF() async {
    final l10n = AppLocalizations.of(context)!;
    // Ask user: current page or all products
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.productMgmtExportToPdfTitle),
        content: Text(
          l10n.productMgmtExportPdfChoiceMessage(_pageSize, _allProductsCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'page'),
            child: Text(l10n.productMgmtCurrentPageLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: Text(l10n.productMgmtAllProductsLabel),
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
        dialogTitle: l10n.productMgmtSaveProductsPdfDialogTitle,
        fileName: 'products.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(await pdf.save());
      _showSnackBar(l10n.customerMgmtPdfExportedMessage);
    } catch (e) {
      _showSnackBar(l10n.customerMgmtPdfExportErrorMessage(e.toString()), isError: true);
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
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context)!.productMgmtLoadErrorMessage(e.toString()), isError: true);
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

  String _listColLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'aliasName':
        return l10n.productColumnsAliasNameLabel;
      case 'description':
        return l10n.productColumnsDescriptionLabel;
      case 'hsncode':
        return l10n.productColumnsHsnSacLabel;
      case 'purchasePrice':
        return l10n.productColumnsPurchasePriceLabel;
      case 'stock':
        return l10n.productColumnsStockLabel;
      case 'taxRate':
        return l10n.productColumnsTaxRateLabel;
      case 'unit':
        return l10n.productColumnsUnitLabel;
      case 'defaultDiscount':
        return l10n.productColumnsDefaultDiscountLabel;
      case 'storageLocation':
        return l10n.productColumnsMetaStorageLocationLabel;
      case 'containerNumber':
        return l10n.productColumnsMetaContainerNumberLabel;
      case 'batchNumber':
        return l10n.productColumnsMetaBatchNumberLabel;
      case 'expiryDate':
        return l10n.productColumnsMetaExpiryDateLabel;
      case 'manufactureDate':
        return l10n.productColumnsMetaManufactureDateLabel;
      case 'supplierName':
        return l10n.productColumnsMetaSupplierNameLabel;
      case 'skuCode':
        return l10n.productColumnsMetaSkuCodeLabel;
      case 'notes':
        return l10n.productColumnsMetaNotesLabel;
      default:
        return key;
    }
  }

  int _listColFlex(String key) {
    switch (key) {
      case 'stock':
      case 'taxRate':
      case 'unit':
      case 'defaultDiscount':
        return 1;
      case 'description':
      case 'notes':
        return 3;
      default:
        return 2;
    }
  }

  String _fmtMetaDateV2(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : DateFormat(_datePattern).format(d);
  }

  // Header cells for the optional list columns, in _listColumnDefaults order.
  List<Widget> _optionalHeaderCellsV2(TextStyle style) {
    final l10n = AppLocalizations.of(context)!;
    final cells = <Widget>[];
    for (final key in _listColumnDefaults.keys) {
      if (key == 'aliasName' || !_showListCol(key)) continue;
      cells.add(Expanded(
        flex: _listColFlex(key),
        child: Text(_listColLabel(l10n, key).toUpperCase(), style: style),
      ));
    }
    return cells;
  }

  // Row cells matching _optionalHeaderCellsV2, same order/flex.
  List<Widget> _optionalRowCellsV2(Product p) {
    final meta = _productMetadataV2[p.id];
    final muted =
        TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    Widget text(String v) => Text(v.isEmpty ? '—' : v,
        maxLines: 1, overflow: TextOverflow.ellipsis, style: muted);

    final cells = <Widget>[];
    for (final key in _listColumnDefaults.keys) {
      if (key == 'aliasName' || !_showListCol(key)) continue;
      Widget child;
      switch (key) {
        case 'description':
          child = text(p.description);
          break;
        case 'hsncode':
          child = text(p.hsncode);
          break;
        case 'purchasePrice':
          child = text(p.purchasePrice > 0
              ? '$_currencySymbol${p.purchasePrice.toStringAsFixed(2)}'
              : '');
          break;
        case 'stock':
          child = _stockCellV2(p);
          break;
        case 'taxRate':
          child = Text('${p.tax_rate}%');
          break;
        case 'unit':
          child = text(p.unit);
          break;
        case 'defaultDiscount':
          child = text(p.defaultDiscount > 0
              ? p.defaultDiscount.toStringAsFixed(2)
              : '');
          break;
        case 'storageLocation':
          child = text(meta?.storageLocation ?? '');
          break;
        case 'containerNumber':
          child = text(meta?.containerNumber ?? '');
          break;
        case 'batchNumber':
          child = text(meta?.batchNumber ?? '');
          break;
        case 'expiryDate':
          child = _expiryCellV2(p);
          break;
        case 'manufactureDate':
          child = text(_fmtMetaDateV2(meta?.manufactureDate));
          break;
        case 'supplierName':
          child = text(meta?.supplierName ?? '');
          break;
        case 'skuCode':
          child = text(meta?.skuCode ?? '');
          break;
        case 'notes':
          child = text(meta?.notes ?? '');
          break;
        default:
          continue;
      }
      cells.add(Expanded(flex: _listColFlex(key), child: child));
    }
    return cells;
  }

  Widget _expiryCellV2(Product p) {
    final expiryDate = _expiryDateOfV2(p);
    if (expiryDate == null) {
      return Text('—',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    final isExpired = expiryDate.isBefore(DateTime.now());
    return Row(
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
    );
  }

  PopupMenuItem<String> _listColMenuItemV2(String key, String label) {
    final visible = _showListCol(key);
    final canToggle = key == 'aliasName' ||
        visible ||
        _visibleListColumnCount < _maxVisibleListColumns;
    return PopupMenuItem<String>(
      value: key,
      enabled: canToggle,
      child: Row(
        children: [
          Icon(visible ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: canToggle
                  ? null
                  : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label),
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
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _statCardV2(
        label: l10n.productMgmtAllProductsLabel,
        value: '$_allCountV2',
        subtitle: l10n.productMgmtTotalItemsSubtitle,
        icon: Icons.inventory_2_outlined,
        accent: Theme.of(context).primaryColor,
      ),
      _statCardV2(
        label: l10n.navProducts,
        value: '$_productsCountV2',
        subtitle: l10n.productMgmtTangibleProductsSubtitle,
        icon: Icons.widgets_outlined,
        accent: Colors.green,
      ),
      _statCardV2(
        label: l10n.productMgmtServicesTabLabel,
        value: '$_servicesCountV2',
        subtitle: l10n.productMgmtNonTangibleServicesSubtitle,
        icon: Icons.design_services_outlined,
        accent: Colors.orange,
      ),
      _statCardV2(
        label: l10n.productMgmtLowStockTabLabel,
        value: '$_lowStockCountV2',
        subtitle: l10n.productMgmtNeedAttentionSubtitle,
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
              Text(AppLocalizations.of(context)!.productMgmtTitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(AppLocalizations.of(context)!.productMgmtSubtitle,
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
              label: Text(AppLocalizations.of(context)!.actionImport),
            ),
            OutlinedButton.icon(
              onPressed: _exportToCSV,
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: Text(AppLocalizations.of(context)!.actionExport),
            ),
            if (widget.user.isAdmin())
              PopupMenuButton<String>(
                tooltip: AppLocalizations.of(context)!.invoiceMgmtMoreActionsTooltip,
                onSelected: (value) async {
                  if (value == 'export_pdf') await _exportToPDF();
                  if (value == 'delete_all') {
                    await _confirmDeleteAll();
                    await _loadStatsV2();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'export_pdf',
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.customerMgmtExportPdfMenuLabel),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.productMgmtDeleteAllTitle,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: _menuButtonLookV2(
                    Icons.more_horiz, AppLocalizations.of(context)!.commonMoreLabel),
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
              tooltip: AppLocalizations.of(context)!.actionRefresh,
            ),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _showAddPanelV2 = true;
                  _addPanelTabV2 = 0;
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context)!.productMgmtNewProductButton),
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
    final l10n = AppLocalizations.of(context)!;
    final sortOptions = [
      {'label': l10n.customerMgmtSortNameAZ, 'field': 'name', 'asc': true},
      {'label': l10n.customerMgmtSortNameZA, 'field': 'name', 'asc': false},
      {'label': l10n.productMgmtSortPriceLowHigh, 'field': 'price', 'asc': true},
      {'label': l10n.productMgmtSortPriceHighLow, 'field': 'price', 'asc': false},
      {'label': l10n.productMgmtSortStockLowHigh, 'field': 'stock', 'asc': true},
      {'label': l10n.productMgmtSortStockHighLow, 'field': 'stock', 'asc': false},
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
              hintText: l10n.productMgmtSearchHint,
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
                tooltip: l10n.productMgmtFilterByStockStatusTooltip,
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
                  PopupMenuItem(value: 'all', child: Text(l10n.productMgmtAllStockLevelsLabel)),
                  PopupMenuItem(value: 'low', child: Text(l10n.productMgmtLowStockLabel)),
                  PopupMenuItem(value: 'out', child: Text(l10n.productMgmtOutOfStockLabel)),
                  if (_columnsConfig.productMetadata && _columnsConfig.metaExpiryDate)
                    PopupMenuItem(value: 'expired', child: Text(l10n.productMgmtExpiredLabel)),
                ],
                child: _menuButtonLookV2(Icons.filter_list, l10n.invoiceMgmtFilterLabel),
              ),
              PopupMenuButton<Map<String, Object>>(
                tooltip: l10n.invoiceMgmtSortLabel,
                onSelected: (opt) =>
                    _onSortSelectionV2(opt['field'] as String, opt['asc'] as bool),
                itemBuilder: (ctx) => sortOptions
                    .map((o) => PopupMenuItem(value: o, child: Text(o['label'] as String)))
                    .toList(),
                child: _menuButtonLookV2(
                    Icons.swap_vert, l10n.customerMgmtSortWithLabel(currentLabel)),
              ),
              OutlinedButton.icon(
                onPressed: _openColumnsSettingsV2,
                icon: const Icon(Icons.tune, size: 16),
                label: Text(l10n.productMgmtCustomizeColumnsLabel),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.productMgmtShowColumnsLabel,
                onSelected: _toggleListColumnV2,
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                        l10n.productMgmtShowColumnsMaxHint(
                            _maxVisibleListColumns),
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ),
                  for (final key in _listColumnDefaults.keys)
                    if (_listColumnFieldEnabled(key))
                      _listColMenuItemV2(key, _listColLabel(l10n, key)),
                ],
                child: _menuButtonLookV2(
                    Icons.view_column_outlined, l10n.productMgmtShowColumnsLabel),
              ),
              IconButton(
                tooltip: _showStatsCardsV2
                    ? l10n.customerMgmtHideStatCardsTooltip
                    : l10n.customerMgmtShowStatCardsTooltip,
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
        child: Text(AppLocalizations.of(context)!.customerMgmtTabChipLabel(label, count)),
      ),
    );
  }

  Widget _tabsRowV2() {
    final l10n = AppLocalizations.of(context)!;
    final showExpiredTab = _columnsConfig.productMetadata && _columnsConfig.metaExpiryDate;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChipV2(l10n.invoiceMgmtStatusAllLabel, _allCountV2, 0),
          _tabChipV2(l10n.navProducts, _productsCountV2, 1),
          _tabChipV2(l10n.productMgmtServicesTabLabel, _servicesCountV2, 2),
          _tabChipV2(l10n.productMgmtLowStockTabLabel, _lowStockCountV2, 3),
          _tabChipV2(l10n.productMgmtOutOfStockTabLabel, _outOfStockCountV2, 4),
          if (showExpiredTab) _tabChipV2(l10n.productMgmtExpiredLabel, _expiredCountV2, 5),
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
        isService ? AppLocalizations.of(context)!.labelService : AppLocalizations.of(context)!.labelProduct,
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
                if (_businessType == BusinessType.both && _columnsConfig.type)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _typeTagV2(p.type),
                  ),
                if (_showListCol('aliasName') && (p.aliasName ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('(${p.aliasName})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('$_currencySymbol${p.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          ..._optionalRowCellsV2(p),
          SizedBox(
            width: 116,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _viewProductV2(p),
                  tooltip: AppLocalizations.of(context)!.actionView,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editProductV2(p),
                  tooltip: AppLocalizations.of(context)!.actionEdit,
                ),
                if (widget.user.isAdmin())
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _deleteProductV2(p),
                    tooltip: AppLocalizations.of(context)!.actionDelete,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderRowV2() {
    final l10n = AppLocalizations.of(context)!;
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
          SizedBox(width: 56, child: Text(l10n.productMgmtColSlNo, style: style)),
          Expanded(flex: 3, child: Text(l10n.productMgmtColNameAlias, style: style)),
          Expanded(flex: 2, child: Text(l10n.productMgmtColPrice, style: style)),
          ..._optionalHeaderCellsV2(style),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.productMgmtShowingRangeLabel(
                _totalProducts == 0 ? 0 : _currentPage * _pageSize + 1,
                (_currentPage * _pageSize + _pageSize).clamp(0, _totalProducts),
                _totalProducts),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.customerMgmtRowsPerPageLabel,
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
              Text(l10n.customerMgmtOfTotalPagesLabel(totalPages),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabelV2(l10n.productMgmtSectionGeneral),
        _buildFormField(_nameController, l10n.fieldNameLabel, Icons.inventory_2,
            maxLength: 100, onSubmitted: _addProductV2),
        if (_columnsConfig.aliasName) ...[
          const SizedBox(height: 16),
          _buildFormField(_aliasNameController,
              l10n.productMgmtAliasNameLabel, Icons.translate,
              maxLength: 100,
              required: false,
              helperText: l10n.productMgmtAliasHelperText),
        ],
        if (_columnsConfig.description) ...[
          const SizedBox(height: 16),
          _buildFormField(
              _descriptionController, l10n.productMgmtDescriptionLabel, Icons.description,
              maxLines: 3, maxLength: 500, required: false),
        ],
        if (_columnsConfig.hsncode) ...[
          const SizedBox(height: 16),
          _buildFormField(_hsnCodeController, l10n.productMgmtHsnSacLabel, Icons.qr_code,
              maxLength: 100, required: false),
        ],
        const SizedBox(height: 20),
        _sectionLabelV2(l10n.productMgmtSectionPricing),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFormField(_priceController, l10n.productMgmtSalePriceLabel, Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isPrice: true,
                  prefixText: '$_currencySymbol ',
                  onSubmitted: _addProductV2),
            ),
            if (_columnsConfig.purchasePrice) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                    _purchasePriceController, l10n.productMgmtPurchasePriceLabel, Icons.shopping_cart_outlined,
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
              _defaultDiscountController, l10n.productMgmtDefaultDiscountLabel, Icons.discount,
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
                child: _buildFormField(_taxRateController, l10n.productMgmtTaxPercentLabel, Icons.percent,
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
                      child: Text(l10n.fieldPriceIncludesTaxLabel,
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
            child: Text(l10n.productMgmtPerItemTaxModeOnlyLabel,
                style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
        if (_columnsConfig.stock || _columnsConfig.unit) ...[
          const SizedBox(height: 12),
          _sectionLabelV2(l10n.productMgmtSectionInventory),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_columnsConfig.stock)
                Expanded(
                  child: _buildFormField(_stockController, l10n.labelStock, Icons.inventory,
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
              title: Text(l10n.productMgmtUnlimitedStockLabel),
              subtitle: Text(l10n.productMgmtTrackInfiniteStockSubtitle),
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
                child: Text(l10n.productMgmtTipEnableCustomFieldsMessage,
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
    final l10n = AppLocalizations.of(context)!;
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
                      Text(
                          l10n.productMgmtAddNewItemTitle(_newItemType == 'service'
                              ? l10n.labelService
                              : l10n.labelProduct),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(l10n.productMgmtEnterProductDetailsSubtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (showTypeToggle) ...[
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'product',
                          label: Text(l10n.labelProduct),
                          icon: const Icon(Icons.inventory_2_outlined, size: 14)),
                      ButtonSegment(
                          value: 'service',
                          label: Text(l10n.labelService),
                          icon: const Icon(Icons.design_services_outlined, size: 14)),
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
                    Expanded(child: Text(l10n.customerMgmtAddAnotherLabel)),
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
                        child: Text(l10n.actionCancel),
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
                        label: Text(l10n.productMgmtSaveProductButton),
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
    final l10n = AppLocalizations.of(context)!;

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
            bool isRequired = false,
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
              isRequired: isRequired,
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
              _showSnackBar(l10n.productMgmtUpdatedMessage);
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
                              Text(isEdit ? l10n.productMgmtEditProductTitle : l10n.productMgmtViewProductTitle,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(isEdit
                                      ? l10n.productMgmtUpdateProductDetailsSubtitle
                                      : l10n.productMgmtProductDetailsSubtitle,
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
                              segments: [
                                ButtonSegment(
                                    value: 'product',
                                    label: Text(l10n.labelProduct),
                                    icon: const Icon(Icons.inventory_2_outlined, size: 14)),
                                ButtonSegment(
                                    value: 'service',
                                    label: Text(l10n.labelService),
                                    icon:
                                        const Icon(Icons.design_services_outlined, size: 14)),
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
                              label: Text(itemType == 'service' ? l10n.labelService : l10n.labelProduct),
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
                            sectionLabel(l10n.productMgmtSectionGeneral),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: field(nameCtrl, l10n.productMgmtProductNameLabel,
                                      Icons.inventory_2, maxLength: 100, isRequired: true),
                                ),
                                if (_columnsConfig.aliasName) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: field(aliasCtrl,
                                        l10n.productMgmtAliasNameLabel, Icons.translate,
                                        maxLength: 100),
                                  ),
                                ],
                              ],
                            ),
                            if (_columnsConfig.description) ...[
                              const SizedBox(height: 16),
                              field(descCtrl, l10n.productMgmtDescriptionLabel, Icons.description,
                                  maxLines: 3, maxLength: 500),
                            ],
                            if (_columnsConfig.hsncode) ...[
                              const SizedBox(height: 16),
                              field(hsnCtrl, l10n.productMgmtColHsnSac, Icons.qr_code, maxLength: 100),
                            ],
                            const SizedBox(height: 20),
                            sectionLabel(l10n.productMgmtSectionPricing),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: field(priceCtrl, l10n.productMgmtPriceLabel, Icons.attach_money,
                                      keyboardType: const TextInputType.numberWithOptions(
                                          decimal: true),
                                      isPrice: true,
                                      isRequired: true,
                                      prefixText: '$_currencySymbol '),
                                ),
                                if (_columnsConfig.purchasePrice) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: field(purchaseCtrl, l10n.productMgmtPurchasePriceLabel,
                                        Icons.shopping_cart_outlined,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true),
                                        isPrice: true,
                                        isRequired: true,
                                        prefixText: '$_currencySymbol '),
                                  ),
                                ],
                              ],
                            ),
                            if (_columnsConfig.defaultDiscount) ...[
                              const SizedBox(height: 16),
                              field(discountCtrl, l10n.productMgmtDefaultDiscountLabel, Icons.discount,
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
                                        taxCtrl, l10n.fieldTaxRateLabel, Icons.percent,
                                        keyboardType: TextInputType.number,
                                        isTaxRate: true,
                                        isRequired: true),
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
                                          child: Text(l10n.fieldPriceIncludesTaxLabel,
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
                                child: Text(l10n.productMgmtPerItemTaxModeOnlyLabel,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color:
                                            Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
                              ),
                            ],
                            if (_columnsConfig.stock || _columnsConfig.unit) ...[
                              const SizedBox(height: 12),
                              sectionLabel(l10n.productMgmtSectionInventory),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_columnsConfig.stock)
                                    Expanded(
                                      child: field(stockCtrl, l10n.labelStock, Icons.inventory,
                                          keyboardType: TextInputType.number,
                                          isStock: !unlimitedStock,
                                          isRequired: !unlimitedStock),
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
                                  title: Text(l10n.productMgmtUnlimitedStockLabel),
                                  subtitle:
                                      Text(l10n.productMgmtTrackInfiniteStockSubtitle),
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
                                          l10n.productMgmtTipEnableCustomFieldsMessage,
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
                            label: Text(l10n.productMgmtDeleteProductButton,
                                style: const TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        const Spacer(),
                        if (isEdit) ...[
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(l10n.actionCancel),
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
                            label: Text(l10n.productMgmtSaveChangesButton),
                          ),
                        ] else ...[
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(l10n.actionClose),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => setDialogState(() => isEdit = true),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(l10n.actionEdit),
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
    final l10n = AppLocalizations.of(context)!;
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
          return l10n.fieldRequiredMessage(label);
        }
        if (isPrice) {
          final price = double.tryParse(value);
          if (price == null || price < 0) return l10n.fieldEnterValidPriceMessage;
        }
        if (isStock) {
          final stock = int.tryParse(value);
          if (stock == null || stock < 0) return l10n.fieldEnterValidStockMessage;
        }
        if (isTaxRate) {
          final tax = int.tryParse(value);
          if (tax == null || tax < 0 || tax > 100) {
            return l10n.fieldTaxRangeMessage;
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
            AppLocalizations.of(context)!.createInvoiceNoProductsFoundMessage,
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? AppLocalizations.of(context)!.productMgmtAddFirstProductSubtitle
                : AppLocalizations.of(context)!.customerMgmtTryAdjustingSearchSubtitle,
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _isCustom ? 'custom' : _presetValue,
          decoration: InputDecoration(
            labelText: l10n.fieldUnitLabel,
            prefixIcon: const Icon(Icons.straighten),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            filled: widget.readOnly,
            fillColor: widget.readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(l10n.commonNoneLabel)),
            for (final u in ProductUnits.presets)
              DropdownMenuItem(value: u, child: Text(u.toUpperCase())),
            DropdownMenuItem(value: 'custom', child: Text(l10n.commonCustomEllipsisLabel)),
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
              labelText: l10n.fieldCustomUnitLabel,
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
