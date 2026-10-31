import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/utils/formatters.dart';

/// The "add product" form, shared by Product Management (side panel) and the
/// "New product" dialog on the Create Invoice / Purchase Bill pages, so every
/// rule lives in one place: field visibility from Product Columns, admin-only
/// purchase price / stock, product vs service, validators, duplicate-name and
/// selling-at-a-loss confirmations, custom fields (product metadata).
///
/// The Product / Service toggle stays in the caller's header — read
/// [ProductFormState.itemType] / [ProductFormState.showTypeToggle] and call
/// [ProductFormState.setItemType]; [onChanged] fires when those change.
class ProductForm extends ConsumerStatefulWidget {
  /// Null → non-admin rules (purchase price / stock may be locked).
  final User? user;
  final String? initialName;

  /// Extra hint on the stock field (e.g. a purchase bill adds its qty on top).
  final String? stockHelperText;

  /// Always a stock-tracked product, no Product / Service toggle (purchase
  /// bills only list products).
  final bool productOnly;

  /// Enter pressed in the name / sale price field.
  final VoidCallback? onSubmitted;

  /// Config loaded, item type or saving state changed — rebuild the header.
  final VoidCallback? onChanged;

  const ProductForm({
    super.key,
    this.user,
    this.initialName,
    this.stockHelperText,
    this.productOnly = false,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  ConsumerState<ProductForm> createState() => ProductFormState();
}

class ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aliasNameController = TextEditingController();
  final _defaultDiscountController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _lowStockLimitController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _taxRateController = TextEditingController(text: '18');
  final _customUnitController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _containerNumberController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _manufactureNameController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _skuCodeController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedUnit = '';
  DateTime? _expiryDate;
  DateTime? _manufactureDate;
  String _datePattern = 'dd/MM/yyyy';
  String _currencySymbol = '₹';
  BusinessType _businessType = BusinessType.both;
  String _newItemType = 'product';
  bool _unlimitedStock = false;
  bool _priceIncludesTax = false;
  ProductColumnsConfig _columnsConfig = const ProductColumnsConfig();
  // Purchase price restricted to admins and this user isn't one.
  bool _hidePurchasePrice = false;
  // Stock editing admin-only: non-admins can't set stock.
  bool _stockLocked = false;
  bool _saving = false;
  bool _submitting = false;

  String get itemType => _newItemType;
  bool get showTypeToggle =>
      !widget.productOnly &&
      _businessType == BusinessType.both &&
      _columnsConfig.type;
  bool get saving => _saving;

  void setItemType(String type) {
    setState(() {
      _newItemType = type;
      _unlimitedStock = type == 'service' || !_columnsConfig.stock;
    });
    widget.onChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName?.trim() ?? '';
    reloadConfig();
  }

  /// Re-reads settings — call after Product Columns settings change.
  Future<void> reloadConfig() async {
    final repo = ref.read(settingsRepositoryProvider);
    final config = await repo.getProductColumnsConfig();
    final bt = await repo.getBusinessType();
    final currency = await repo.getCurrency();
    final fmt = await repo.getDateFormat();
    if (!mounted) return;
    final isAdmin = widget.user?.isAdmin() ?? false;
    final hide = config.purchasePriceAdminOnly && !isAdmin;
    setState(() {
      _hidePurchasePrice = hide;
      _stockLocked = config.stockEditAdminOnly && !isAdmin;
      _columnsConfig = hide ? config.copyWith(purchasePrice: false) : config;
      if (!config.stock) _unlimitedStock = true;
      _businessType = bt;
      _newItemType = bt == BusinessType.service && !widget.productOnly
          ? 'service'
          : 'product';
      _currencySymbol = currency.symbol;
      _datePattern = fmt.key;
    });
    widget.onChanged?.call();
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _aliasNameController,
      _defaultDiscountController,
      _descriptionController,
      _priceController,
      _purchasePriceController,
      _stockController,
      _lowStockLimitController,
      _hsnCodeController,
      _taxRateController,
      _customUnitController,
      _storageLocationController,
      _containerNumberController,
      _batchNumberController,
      _manufactureNameController,
      _supplierNameController,
      _skuCodeController,
      _notesController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Validates, confirms (duplicate name, selling at a loss), saves the
  /// product + its custom fields and returns it. Null = not saved.
  /// One run at a time: a second Enter / click during the duplicate lookup
  /// or a confirm dialog would otherwise save twice.
  Future<Product?> submit() async {
    if (_submitting) return null;
    _submitting = true;
    try {
      return await _submit();
    } finally {
      _submitting = false;
    }
  }

  Future<Product?> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return null;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final productRepo = ref.read(productRepositoryProvider);

    final duplicate = await productRepo.findDuplicateByName(name);
    if (!mounted) return null;
    if (duplicate != null && !await _confirmDuplicate(name)) return null;

    final price = double.parse(_priceController.text.trim());
    final purchasePrice =
        double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    if (!mounted) return null;
    if (!_hidePurchasePrice &&
        !await confirmSellingAtLoss(context,
            price: price,
            purchasePrice: purchasePrice,
            currencySymbol: _currencySymbol)) {
      return null;
    }
    if (!mounted) return null;

    setState(() => _saving = true);
    widget.onChanged?.call();
    try {
      final product = Product(
        id: const Uuid().v4(),
        name: name,
        description: _descriptionController.text.trim(),
        price: price,
        stock: _unlimitedStock || _stockLocked
            ? 0
            : int.parse(_stockController.text.trim()),
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
        lowStockLimit: _unlimitedStock || _stockLocked
            ? null
            : int.tryParse(_lowStockLimitController.text.trim()),
      );
      await productRepo.insertProduct(product);
      await productRepo.upsertProductMetadata(
        ProductMetadata(
          productId: product.id,
          storageLocation: _storageLocationController.text.trim(),
          containerNumber: _containerNumberController.text.trim(),
          batchNumber: _batchNumberController.text.trim(),
          expiryDate: _isoDate(_expiryDate),
          manufactureDate: _isoDate(_manufactureDate),
          manufactureName: _manufactureNameController.text.trim(),
          supplierName: _supplierNameController.text.trim(),
          skuCode: _skuCodeController.text.trim(),
          notes: _notesController.text.trim(),
        ),
      );
      return product;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.productMgmtAddErrorMessage(e.toString())),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
      widget.onChanged?.call();
    }
  }

  /// Back to an empty form (after "add another").
  void reset() {
    _formKey.currentState?.reset();
    for (final c in [
      _nameController,
      _aliasNameController,
      _descriptionController,
      _priceController,
      _purchasePriceController,
      _lowStockLimitController,
      _hsnCodeController,
      _customUnitController,
      _storageLocationController,
      _containerNumberController,
      _batchNumberController,
      _manufactureNameController,
      _supplierNameController,
      _skuCodeController,
      _notesController,
    ]) {
      c.clear();
    }
    _defaultDiscountController.text = '0';
    _stockController.text = '0';
    _taxRateController.text = '18';
    setState(() {
      _selectedUnit = '';
      _unlimitedStock = !_columnsConfig.stock;
      _priceIncludesTax = false;
      _expiryDate = null;
      _manufactureDate = null;
    });
  }

  Future<bool> _confirmDuplicate(String name) async {
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.productFormDuplicateTitle),
        content: Text(l10n.productFormDuplicateMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.productFormCreateAnywayButton),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  static String _isoDate(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(l10n.productMgmtSectionGeneral),
          _buildFormField(_nameController, l10n.fieldNameLabel, Icons.inventory_2,
              maxLength: 100, onSubmitted: widget.onSubmitted),
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
          _sectionLabel(l10n.productMgmtSectionPricing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormField(_priceController, l10n.productMgmtSalePriceLabel, Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isPrice: true,
                    prefixText: '$_currencySymbol ',
                    onSubmitted: widget.onSubmitted),
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
            _sectionLabel(l10n.productMgmtSectionInventory),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_columnsConfig.stock)
                  Expanded(
                    child: _buildFormField(_stockController, l10n.labelStock, Icons.inventory,
                        keyboardType: TextInputType.number,
                        isStock: true,
                        required: !_unlimitedStock && !_stockLocked,
                        enabled: !_unlimitedStock && !_stockLocked,
                        helperText: widget.stockHelperText),
                  ),
                if (_columnsConfig.stock && _columnsConfig.unit) const SizedBox(width: 12),
                if (_columnsConfig.unit)
                  Expanded(
                    child: ProductUnitField(
                      initialUnit: _selectedUnit,
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
                onChanged: _stockLocked
                    ? null
                    : (v) {
                        if (!mounted) return;
                        setState(() => _unlimitedStock = v ?? false);
                      },
                title: Text(l10n.productMgmtUnlimitedStockLabel),
                subtitle: Text(l10n.productMgmtTrackInfiniteStockSubtitle),
              ),
            if (_columnsConfig.stock && !_unlimitedStock)
              _buildFormField(_lowStockLimitController,
                  l10n.productMgmtLowStockLimitLabel, Icons.notification_important_outlined,
                  keyboardType: TextInputType.number,
                  isStock: true,
                  required: false,
                  enabled: !_stockLocked,
                  helperText: l10n.productMgmtLowStockLimitHelper),
          ],
          if (_columnsConfig.productMetadata) ...[
            const SizedBox(height: 8),
            ProductMetadataSection(
              config: _columnsConfig,
              storageLocationCtrl: _storageLocationController,
              containerNumberCtrl: _containerNumberController,
              batchNumberCtrl: _batchNumberController,
              manufactureNameCtrl: _manufactureNameController,
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
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
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
        helperText: helperText,
        helperMaxLines: 3,
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
}

/// "New product" dialog for pages outside Product Management. Returns the
/// saved product, or null when cancelled.
Future<Product?> showNewProductDialog(
  BuildContext context, {
  User? user,
  String? initialName,
  String? stockHelperText,
  bool productOnly = false,
}) {
  final formKey = GlobalKey<ProductFormState>();
  return showDialog<Product>(
    context: context,
    // A stray outside tap would drop everything typed.
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
      final l10n = AppLocalizations.of(ctx)!;
      final form = formKey.currentState;
      Future<void> save() async {
        final product = await formKey.currentState?.submit();
        if (product != null && ctx.mounted) Navigator.pop(ctx, product);
      }

      return AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.productMgmtAddNewItemTitle(form?.itemType == 'service'
                    ? l10n.labelService
                    : l10n.labelProduct),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (form?.showTypeToggle ?? false)
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
                selected: {form!.itemType},
                onSelectionChanged: (v) => form.setItemType(v.first),
              ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ProductForm(
                key: formKey,
                user: user,
                initialName: initialName,
                stockHelperText: stockHelperText,
                productOnly: productOnly,
                onSubmitted: save,
                onChanged: () {
                  if (ctx.mounted) setLocal(() {});
                },
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.actionCancel),
          ),
          FilledButton.icon(
            onPressed: (form?.saving ?? false) ? null : save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(l10n.productMgmtSaveProductButton),
          ),
        ],
      );
    }),
  );
}

/// Asks before saving a product whose purchase price is above its sale
/// price. True = fine to save.
Future<bool> confirmSellingAtLoss(
  BuildContext context, {
  required double price,
  required double purchasePrice,
  required String currencySymbol,
}) async {
  if (purchasePrice <= 0 || purchasePrice <= price) return true;
  final l10n = AppLocalizations.of(context)!;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.productMgmtSellingAtLossTitle),
      content: Text(
        l10n.productMgmtSellingAtLossMessage(
          '$currencySymbol${AmountFormat.money(purchasePrice)}',
          '$currencySymbol${AmountFormat.money(price)}',
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

/// Custom fields (product metadata) — "Advanced information" expander.
class ProductMetadataSection extends StatelessWidget {
  final ProductColumnsConfig config;
  final TextEditingController storageLocationCtrl;
  final TextEditingController containerNumberCtrl;
  final TextEditingController batchNumberCtrl;
  final TextEditingController manufactureNameCtrl;
  final TextEditingController supplierNameCtrl;
  final TextEditingController skuCodeCtrl;
  final TextEditingController notesCtrl;
  final DateTime? expiryDate;
  final DateTime? manufactureDate;
  final String datePattern;
  final ValueChanged<DateTime?> onExpiryChanged;
  final ValueChanged<DateTime?> onManufactureChanged;
  final bool readOnly;

  const ProductMetadataSection({
    super.key,
    required this.config,
    required this.storageLocationCtrl,
    required this.containerNumberCtrl,
    required this.batchNumberCtrl,
    required this.manufactureNameCtrl,
    required this.supplierNameCtrl,
    required this.skuCodeCtrl,
    required this.notesCtrl,
    required this.expiryDate,
    required this.manufactureDate,
    required this.datePattern,
    required this.onExpiryChanged,
    required this.onManufactureChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
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
          if (config.metaStorageLocation)
            field(storageLocationCtrl, l10n.productMgmtStorageLocationLabel, Icons.place_outlined),
          if (config.metaContainerNumber)
            field(containerNumberCtrl, l10n.productMgmtContainerNumberLabel, Icons.inventory_2_outlined),
          if (config.metaBatchNumber)
            field(batchNumberCtrl, l10n.productMgmtBatchNumberLabel, Icons.tag),
          if (config.metaExpiryDate)
            dateField(l10n.productMgmtExpiryDateLabel, expiryDate, onExpiryChanged),
          if (config.metaManufactureDate)
            dateField(l10n.productMgmtManufactureDateLabel, manufactureDate, onManufactureChanged),
          if (config.metaManufactureName)
            field(manufactureNameCtrl, l10n.productMgmtManufactureNameLabel, Icons.factory_outlined),
          if (config.metaSupplierName)
            field(supplierNameCtrl, l10n.productMgmtSupplierNameLabel, Icons.local_shipping_outlined),
          if (config.metaSkuCode)
            field(skuCodeCtrl, l10n.productMgmtSkuCodeLabel, Icons.qr_code_2),
          if (config.metaNotes)
            field(notesCtrl, l10n.productMgmtNotesLabel, Icons.notes, maxLines: 3),
        ],
      ),
    );
  }
}

/// Unit picker: preset units, or "Custom…" with a free-text unit.
class ProductUnitField extends StatefulWidget {
  final String initialUnit;
  final TextEditingController customController;
  final ValueChanged<String> onUnitChanged;
  final bool readOnly;

  const ProductUnitField({
    super.key,
    required this.initialUnit,
    required this.customController,
    required this.onUnitChanged,
    this.readOnly = false,
  });

  @override
  State<ProductUnitField> createState() => _ProductUnitFieldState();
}

class _ProductUnitFieldState extends State<ProductUnitField> {
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
