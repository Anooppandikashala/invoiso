import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/domain/invoice_totals_calculator.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:uuid/uuid.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/common/constants.dart';

class InvoiceFormGuard {
  Future<bool> Function()? canLeave;
}

class CreateInvoiceScreenV2 extends ConsumerStatefulWidget {
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
  final InvoiceFormGuard? guard;

  const CreateInvoiceScreenV2({
    super.key,
    this.invoiceToEdit,
    this.cloneFrom,
    this.cloneType,
    this.onCreateNewInvoice,
    this.guard,
  });

  @override
  ConsumerState<CreateInvoiceScreenV2> createState() => _CreateInvoiceScreenV2State();
}

class _CreateInvoiceScreenV2State extends ConsumerState<CreateInvoiceScreenV2> {
  final FocusNode _screenFocusNode = FocusNode();
  ProductColumnsConfig _columnsConfig = const ProductColumnsConfig();
  bool _showDescriptionInPdf = false;

  Future<void> _loadColumnsConfig() async {
    final repo = ref.read(settingsRepositoryProvider);
    final config = await repo.getProductColumnsConfig();
    final showDesc = await repo.getSetting(SettingKey.showDescriptionInPdf);
    if (!mounted) return;
    setState(() {
      _columnsConfig = config;
      _showDescriptionInPdf = showDesc == 'true';
    });
  }

  Customer? selectedCustomer;
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  List<Product> products = [];
  List<Product> filteredProducts = [];
  Map<String, ProductMetadata> _productMetadata = {};
  Timer? _productSearchDebounce;
  int _productSearchRequestId = 0;
  static const int _productFetchLimit = 30;
  Timer? _customerSearchDebounce;
  int _customerSearchRequestId = 0;
  static const int _customerFetchLimit = 30;
  List<InvoiceItem> invoiceItems = [];
  final Set<String> _savedAdHocIds =
      {}; // tracks custom item IDs already saved to products
  final List<({TextEditingController label, TextEditingController amount})>
      _additionalCostControllers = [];
  bool _showAdditionalCosts = false;
  bool _invoiceDetailsExpanded = true;
  bool _customerDetailsExpanded = true;
  InvoiceDiscountType _invoiceDiscountType = InvoiceDiscountType.percent;
  final _invoiceDiscountController = TextEditingController();

  final notesController = TextEditingController();
  final customInvoiceNumberController = TextEditingController();
  bool _hideInvoiceNumber = false;
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
  bool _isInterState = false; // India: interstate supply → IGST instead of CGST/SGST
  bool isEditing = false;
  bool isLoading = false;
  // V2: inline product search dropdown (replaces click-to-open popup;
  // the popup dialog is now reserved for the Ctrl+F shortcut only).
  bool _showProductDropdownV2 = false;
  int _highlightedProductIndexV2 = 0;
  final FocusNode _productSearchFocusNodeV2 = FocusNode();
  final ScrollController _productDropdownScrollControllerV2 = ScrollController();

  String invoiceType = 'Invoice';
  String? invoiceTitle;
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
  bool _showPreviousBalance = false;
  bool _showAliasNameInPdf = false;
  bool _allowDuplicateInvoiceItems = false;
  double _previousBalanceDue = 0.0;
  bool _isPreviousBalanceLoading = false;
  bool _isSavingCustomer = false;
  int _previousBalanceRequestSerial = 0;
  BusinessType _businessType = BusinessType.both;
  String _datePattern = 'dd/MM/yyyy';
  String _adHocItemType = 'product'; // type for custom items added inline
  String? _cleanFormSnapshot;
  int _pendingInitialLoads = 2;
  bool _customFieldsEnabled = false;
  List<CustomFieldDef> _customFieldDefs = [];
  Map<String, String> _customFieldValues = {}; // defId -> value, filled via _showCustomFieldsDialogV2

  TaxMode get _taxMode {
    if (!_isTaxEnabled) return TaxMode.none;
    return _isPerItem ? TaxMode.perItem : TaxMode.global;
  }

  @override
  void initState() {
    super.initState();
    widget.guard?.canLeave = _confirmLeaveIfDirty;
    // V2: close the inline product dropdown a beat after the field loses
    // focus, so a tap on a dropdown row still registers as a selection
    // before the list disappears.
    _productSearchFocusNodeV2.addListener(() {
      if (!_productSearchFocusNodeV2.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() => _showProductDropdownV2 = false);
          if (!_productSearchFocusNodeV2.hasFocus &&
              (ModalRoute.of(context)?.isCurrent ?? true)) {
            _screenFocusNode.requestFocus();
          }
        });
      }
    });
    taxRateController.text = (taxRate * 100).toStringAsFixed(1);
    _loadCustomersAndProducts(widget.invoiceToEdit != null);
    _loadColumnsConfig();
    _selectedOrderDate = DateTime.now();
    dateController.text = DateFormat(_datePattern).format(_selectedOrderDate);
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
      _isPerItem = _invoice!.taxMode == TaxMode.perItem;
      _isInterState = _invoice!.isInterState;
      invoiceType = _invoice!.type;
      invoiceTitle = _invoice!.invoiceTitle;
      currentInvoiceNumber = _invoice!.invoiceNumber ?? _invoice!.id;
      _selectedOrderDate = _invoice!.date;
      dateController.text = DateFormat(_datePattern).format(_selectedOrderDate);
      if (_invoice!.dueDate != null) {
        _selectedDueDate = _invoice!.dueDate;
        dueDateController.text =
            DateFormat(_datePattern).format(_invoice!.dueDate!);
      }
      _quantityLabel = _invoice!.quantityLabel ?? '';
      _hideInvoiceNumber = _invoice!.hideInvoiceNumber;
      customInvoiceNumberController.text = _invoice!.customInvoiceNumber ?? '';
      for (final c in _invoice!.additionalCosts) {
        _additionalCostControllers.add((
          label: TextEditingController(text: c.label),
          amount: TextEditingController(text: c.amount.toStringAsFixed(2)),
        ));
      }
      if (_additionalCostControllers.isNotEmpty) _showAdditionalCosts = true;
      _customFieldValues = {
        for (final cf in _invoice!.customFields) cf.defId: cf.value,
      };
      _invoiceDiscountType = _invoice!.invoiceDiscountType;
      if (_invoice!.invoiceDiscountValue > 0) {
        _invoiceDiscountController.text =
            _invoice!.invoiceDiscountValue.toStringAsFixed(2);
      }
    } else if (widget.cloneFrom != null) {
      // Clone: pre-populate fields but treat as a brand-new invoice.
      // isEditing stays false → _createInvoice() will be called on save.
      final src = widget.cloneFrom!;
      selectedCustomer = src.customer;
      invoiceItems = src.items
          .map((i) => InvoiceItem(
                product: i.product,
                quantity: i.quantity,
                discount: i.discount,
                unitPrice: i.unitPrice,
                extraCost: i.extraCost,
                unit: i.unit,
                description: i.description,
                discountPerUnit: i.discountPerUnit,
                isProductSaved: i.isProductSaved,
              ))
          .toList();
      nameController.text = src.customer.name;
      emailController.text = src.customer.email;
      phoneController.text = src.customer.phone;
      addressController.text = src.customer.address;
      gstinController.text = src.customer.gstin;
      businessNameController.text = src.customer.businessName;
      taxRate = src.taxRate;
      taxRateController.text = (taxRate * 100).toStringAsFixed(1);
      _isTaxEnabled = src.taxMode != TaxMode.none;
      _isPerItem = src.taxMode == TaxMode.perItem;
      _isInterState = src.isInterState;
      invoiceType = widget.cloneType ?? src.type;
      invoiceTitle = invoiceType == src.type ? src.invoiceTitle : null;
      _quantityLabel = src.quantityLabel ?? '';
      // Custom PDF number is invoice-specific; don't carry it into a clone.
      // Same reasoning for custom fields (Vehicle No, Delivery Note, etc.) —
      // shipment-specific, left blank for the user to fill fresh.
      for (final c in src.additionalCosts) {
        _additionalCostControllers.add((
          label: TextEditingController(text: c.label),
          amount: TextEditingController(text: c.amount.toStringAsFixed(2)),
        ));
      }
      if (_additionalCostControllers.isNotEmpty) _showAdditionalCosts = true;
      _invoiceDiscountType = src.invoiceDiscountType;
      if (src.invoiceDiscountValue > 0) {
        _invoiceDiscountController.text =
            src.invoiceDiscountValue.toStringAsFixed(2);
      }
      // date stays as today; currentInvoiceNumber is generated in _loadCustomersAndProducts
    }
  }

  @override
  void didUpdateWidget(covariant CreateInvoiceScreenV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guard != widget.guard) {
      if (oldWidget.guard?.canLeave == _confirmLeaveIfDirty) {
        oldWidget.guard?.canLeave = null;
      }
      widget.guard?.canLeave = _confirmLeaveIfDirty;
    }
  }

  Future<void> _setAdditionalNote({bool forceDefault = false}) async {
    final String addNote;
    if (!forceDefault && widget.invoiceToEdit != null) {
      addNote = widget.invoiceToEdit!.notes ?? '';
    } else if (!forceDefault && widget.cloneFrom != null) {
      addNote = widget.cloneFrom!.notes ?? '';
    } else {
      if(!mounted) return;
      addNote = await ref.read(settingsRepositoryProvider).getSetting(SettingKey.additionalInfo) ??
          ref.read(appEditionConfigProvider).additionalNote;
    }
    if(!mounted) return;
    final taxRateSetting = await ref.read(settingsRepositoryProvider).getSetting(SettingKey.defaultTaxRate);
    final parsedRate = double.tryParse(taxRateSetting ?? '') ?? 18.0;
    if (widget.invoiceToEdit == null && widget.cloneFrom == null) {
      taxRate = parsedRate / 100.0;
      taxRateController.text = parsedRate.toStringAsFixed(1);
    }
    if(!mounted) return;
    setState(() {
      notesController.text = addNote;
    });
    _completeInitialLoad();
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _productSearchFocusNodeV2.dispose();
    _productDropdownScrollControllerV2.dispose();
    _productSearchDebounce?.cancel();
    _customerSearchDebounce?.cancel();
    if (widget.guard?.canLeave == _confirmLeaveIfDirty) {
      widget.guard?.canLeave = null;
    }
    notesController.dispose();
    customInvoiceNumberController.dispose();
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
    _invoiceDiscountController.dispose();
    super.dispose();
  }

  void _completeInitialLoad() {
    if (_pendingInitialLoads <= 0) return;
    _pendingInitialLoads--;
    if (_pendingInitialLoads == 0) {
      _markFormClean();
    }
  }

  void _markFormClean() {
    _cleanFormSnapshot = _currentFormSnapshot();
  }

  bool get _hasUnsavedChanges {
    if (!isEditing && _invoice != null) return false;
    final clean = _cleanFormSnapshot;
    if (clean == null) return false;
    return _currentFormSnapshot() != clean;
  }

  String _currentFormSnapshot() {
    return jsonEncode({
      'mode': widget.invoiceToEdit != null
          ? 'edit:${widget.invoiceToEdit!.id}'
          : widget.cloneFrom != null
              ? 'clone:${widget.cloneFrom!.id}:$invoiceType'
              : 'create',
      'selectedCustomerId': selectedCustomer?.id ?? '',
      'customer': {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'gstin': gstinController.text.trim(),
        'businessName': businessNameController.text.trim(),
      },
      'items': invoiceItems.map((item) {
        final product = item.product;
        return {
          'productId': product.id,
          'name': product.name,
          'price': product.price,
          'quantity': item.quantity,
          'discount': item.discount,
          'discountPerUnit': item.discountPerUnit,
          'extraCost': item.extraCost ?? 0.0,
          'taxRate': product.tax_rate,
          'hsn': product.hsncode,
          'type': product.type,
          'isProductSaved': item.isProductSaved,
        };
      }).toList(),
      'additionalCosts': _additionalCostControllers
          .map((row) => {
                'label': row.label.text.trim(),
                'amount': row.amount.text.trim(),
              })
          .toList(),
      'showAdditionalCosts': _showAdditionalCosts,
      'notes': notesController.text.trim(),
      'invoiceType': invoiceType,
      'taxEnabled': _isTaxEnabled,
      'perItemTax': _isPerItem,
      'interState': _isInterState,
      'taxRate': taxRate,
      'taxRateText': taxRateController.text.trim(),
      'date': _selectedOrderDate.toIso8601String(),
      'dueDate': _selectedDueDate?.toIso8601String() ?? '',
      'currencyCode': _currencyCode,
      'upiId': _selectedUpi?.id ?? '',
      'bankAccount': _selectedBankAccount?.accountNumber ?? '',
      'quantityLabel': _quantityLabel.trim(),
      'hideInvoiceNumber': _hideInvoiceNumber,
      'customInvoiceNumber': customInvoiceNumberController.text.trim(),
    });
  }

  Future<bool> _confirmLeaveIfDirty() async {
    if (!_hasUnsavedChanges || isLoading) return true;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createInvoiceUnsavedChangesTitle),
        content: Text(
          AppLocalizations.of(context)!.createInvoiceUnsavedChangesMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'keep'),
            child: Text(AppLocalizations.of(context)!.createInvoiceKeepEditingButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: Text(AppLocalizations.of(context)!.actionDiscard),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.actionSave),
          ),
        ],
      ),
    );

    switch (action) {
      case 'discard':
        return true;
      case 'save':
        return widget.invoiceToEdit != null
            ? await _updateInvoice()
            : await _createInvoice();
      default:
        return false;
    }
  }

  Future<void> _loadCustomersAndProducts(bool isEditing) async {
    if(!mounted) return;
    setState(() => isLoading = true);

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final results = await Future.wait([
        ref.read(customerRepositoryProvider).getCustomersPaginated(
            offset: 0, limit: _customerFetchLimit), // 0
        ref.read(productRepositoryProvider).getProductsPaginated(
            offset: 0, limit: _productFetchLimit, type: _businessType.key), // 1
        isEditing
            ? Future.value(widget.invoiceToEdit?.invoiceNumber ?? widget.invoiceToEdit?.id)
            : ref.read(invoiceRepositoryProvider).peekNextInvoiceNumber(invoiceType), // 2
        settingsRepo.getCurrency(), // 3 — discarded below when editing/cloning
        settingsRepo.getUpiIds(), // 4
        settingsRepo.getBankAccounts(), // 5
        settingsRepo.getShowGstFields(), // 6
        settingsRepo.getFractionalQuantity(), // 7
        settingsRepo.getQuantityLabel(), // 8
        settingsRepo.getShowQuantity(), // 9
        settingsRepo.getBusinessType(), // 10
        settingsRepo.getDateFormat(), // 11
        settingsRepo.getShowPreviousBalance(), // 12
        settingsRepo.getShowAliasNameInPdf(), // 13
        settingsRepo.getShowTaxButtonInInvoicePage(), // 14
        settingsRepo.getDefaultInvoiceTitle(), // 15
        settingsRepo.getAllowDuplicateInvoiceItems(), // 16
        settingsRepo.getDefaultTaxMode(), // 17
        settingsRepo.getHideInvoiceNumberByDefault(), // 18
        settingsRepo.getSetting(SettingKey.customFieldsEnabled), // 19
        settingsRepo.getCustomFieldDefs(), // 20
      ]);

      final c = results[0] as List<Customer>;
      final p = results[1] as List<Product>;
      final metadataIds = {
        ...p.map((e) => e.id),
        ...invoiceItems.map((e) => e.product.id),
      }.toList();
      final productMetadata = await ref
          .read(productRepositoryProvider)
          .getProductMetadataForIds(metadataIds);
      final invNumber = results[2] as String?;

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
        final currency = results[3] as CurrencyOption;
        loadedCurrencyCode = currency.code;
        loadedCurrencySymbol = currency.symbol;
      }

      final upiEntries = results[4] as List<UpiEntry>;
      final bankAccounts = results[5] as List<BankAccount>;
      final showGst = results[6] as bool;
      final fractionalQty = results[7] as bool;
      final quantityLabelSetting = results[8] as String;
      final showQuantity = results[9] as bool;
      final businessType = results[10] as BusinessType;
      final dateFormatOpt = results[11] as DateFormatOption;
      final showPrevBalance = results[12] as bool;
      final showAliasNameInPdf = results[13] as bool;
      final showTaxButtonInInvoicePage = results[14] as bool;
      final defaultInvoiceTitle = results[15] as String?;
      final allowDuplicateInvoiceItems = results[16] as bool;
      final defaultTaxMode = results[17] as String;
      final hideInvoiceNumberByDefault = results[18] as bool;
      final customFieldsEnabled = (results[19] as String?) == 'true';
      final customFieldDefs = results[20] as List<CustomFieldDef>;

      // Determine which UPI to pre-select.
      String? existingUpiId;
      if (isEditing && widget.invoiceToEdit != null) {
        existingUpiId = widget.invoiceToEdit!.upiId;
      } else if (widget.cloneFrom != null) {
        existingUpiId = widget.cloneFrom!.upiId;
      }

      UpiEntry? preselectedUpi;
      if (existingUpiId != null && existingUpiId.isNotEmpty) {
        preselectedUpi =
            upiEntries.where((e) => e.id == existingUpiId).firstOrNull;
      }
      preselectedUpi ??= upiEntries.where((e) => e.isDefault).firstOrNull ??
          upiEntries.firstOrNull;

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
      preselectedBank ??= bankAccounts.where((e) => e.isDefault).firstOrNull ??
          bankAccounts.firstOrNull;

      // Pre-mark custom items that were already saved to the product list,
      // using the persisted is_product_saved flag on each InvoiceItem.
      _savedAdHocIds.addAll(
        invoiceItems
            .where((item) =>
                item.product.id.startsWith('custom-') && item.isProductSaved)
            .map((item) => item.product.id),
      );
      if(!mounted) return;
      setState(() {
        customers = c;
        filteredCustomers = List.from(c);
        products = p;
        filteredProducts = List.from(p);
        _productMetadata = productMetadata;
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
        _fractionalQuantity = fractionalQty;
        _showQuantity = showQuantity;
        _showPreviousBalance = showPrevBalance;
        _showAliasNameInPdf = showAliasNameInPdf;
        _allowDuplicateInvoiceItems = allowDuplicateInvoiceItems;
        if (!isEditing && widget.cloneFrom == null) {
          _isTaxEnabled = showTaxButtonInInvoicePage;
          _isPerItem = defaultTaxMode == 'perItem';
          _hideInvoiceNumber = hideInvoiceNumberByDefault;
        }
        _customFieldsEnabled = customFieldsEnabled;
        _customFieldDefs = customFieldDefs;
        _businessType = businessType;
        _adHocItemType =
            businessType == BusinessType.service ? 'service' : 'product';
        // For new invoices, use the global setting. Edit/clone already set _quantityLabel in initState.
        if (!isEditing && widget.cloneFrom == null) {
          _quantityLabel = quantityLabelSetting;
          invoiceTitle = invoiceType == 'Invoice' ? defaultInvoiceTitle : null;
        }
        _datePattern = dateFormatOpt.key;
        dateController.text =
            DateFormat(_datePattern).format(_selectedOrderDate);
        if (_selectedDueDate != null) {
          dueDateController.text =
              DateFormat(_datePattern).format(_selectedDueDate!);
        }
        isLoading = false;
      });
      // Edit/clone may have preloaded selectedCustomer from an invoice
      // snapshot whose id was never actually saved to the customers table
      // (see _resolveInvoiceCustomer). Confirm it still exists so the UI
      // doesn't silently treat an unsaved customer as saved.
      if ((isEditing || widget.cloneFrom != null) && selectedCustomer != null) {
        final stillExists = await ref
            .read(customerRepositoryProvider)
            .getCustomerById(selectedCustomer!.id);
        if (!mounted) return;
        if (stillExists == null) {
          setState(() => selectedCustomer = null);
        }
      }
      if (showPrevBalance && selectedCustomer != null) {
        await _loadPreviousBalanceDue(selectedCustomer);
      }
      _completeInitialLoad();
    } catch (e) {
      if(!mounted) return;
      setState(() => isLoading = false);
      _completeInitialLoad();
      if (mounted) {
        if(kDebugMode) print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.createInvoiceErrorLoadingDataMessage(e.toString())),showCloseIcon: true,),
        );
      }
    }
  }

  void addInvoiceProductPrompt(Product product)
  {
    final quantityController = TextEditingController();
    final discountController = TextEditingController(
        text: product.defaultDiscount > 0
            ? product.defaultDiscount.toString()
            : '0');
    final unitPriceController =
        TextEditingController(text: product.price.toString());
    final extraCostController = TextEditingController();
    final unitController = TextEditingController(text: product.unit);
    // Seed from the product's own description so the user starts from it and
    // can tweak it for this line; what they leave is snapshotted on the item.
    // Only when the field is actually shown, else nothing is silently stored.
    final descriptionController = TextEditingController(
        text: _showDescriptionInPdf ? product.description : '');

    bool discountPerUnit = true;
    String dialogUnit = product.unit;
    int insertAt = invoiceItems.length + 1;

    Future<void> addInvoiceProductImpl() async
    {
      final qty = !_showQuantity
          ? 1.0
          : _fractionalQuantity
          ? (double.tryParse(quantityController.text) ?? 1.0)
          : (int.tryParse(quantityController.text) ?? 1)
          .toDouble();
      final discount =
          double.tryParse(discountController.text) ?? 0.0;
      final parsedUnitPrice =
      double.tryParse(unitPriceController.text);
      final unitPrice = (parsedUnitPrice != null &&
          parsedUnitPrice != product.price)
          ? parsedUnitPrice
          : null;
      final extraCost = double.tryParse(extraCostController.text);

      // Check stock
      if (!product.unlimitedStock &&
          product.stock > 0 &&
          qty > product.stock) {
        // Insufficient stock — ask user if they want to add anyway
        Navigator.pop(context);
        final addAnyway = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.createInvoiceInsufficientStockTitle),
            content: Text(
              AppLocalizations.of(context)!.createInvoiceInsufficientStockMessage(product.stock, qty),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.actionCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange),
                child: Text(AppLocalizations.of(context)!.createInvoiceAddAnywayButton),
              ),
            ],
          ),
        );
        _screenFocusNode.requestFocus();
        if (addAnyway == true) {
          addInvoiceProduct(
              InvoiceItem(
                  product: product,
                  quantity: qty,
                  discount: discount,
                  unitPrice: unitPrice,
                  extraCost: extraCost,
                  unit: dialogUnit.trim(),
                  description: descriptionController.text.trim(),
                  discountPerUnit: discountPerUnit),
              insertAt: insertAt);
        }
      } else if (!product.unlimitedStock && product.stock <= 0) {
        Navigator.pop(context);
        final addAnyway = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.createInvoiceOutOfStockTitle),
            content:
            Text(AppLocalizations.of(context)!.createInvoiceOutOfStockMessage(product.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.actionCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange),
                child: Text(AppLocalizations.of(context)!.createInvoiceAddAnywayButton),
              ),
            ],
          ),
        );
        _screenFocusNode.requestFocus();
        if (addAnyway == true) {
          addInvoiceProduct(
              InvoiceItem(
                  product: product,
                  quantity: qty,
                  discount: discount,
                  unitPrice: unitPrice,
                  extraCost: extraCost,
                  unit: dialogUnit.trim(),
                  description: descriptionController.text.trim(),
                  discountPerUnit: discountPerUnit),
              insertAt: insertAt);
        }
      } else {
        Navigator.pop(context);
        addInvoiceProduct(
            InvoiceItem(
                product: product,
                quantity: qty,
                discount: discount,
                unitPrice: unitPrice,
                extraCost: extraCost,
                unit: dialogUnit.trim(),
                description: descriptionController.text.trim(),
                discountPerUnit: discountPerUnit),
            insertAt: insertAt);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) =>
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_cart,
                    color: Theme.of(context).primaryColor),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.unlimitedStock)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.all_inclusive,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.createInvoiceUnlimitedStockLabel,
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  )
                else if (product.stock <= 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.createInvoiceOutOfStockTitle,
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.createInvoiceAvailableStockLabel(product.stock),
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                Builder(builder: (context) {
                  if (!_columnsConfig.productMetadata) return const SizedBox.shrink();
                  final meta = _productMetadata[product.id];
                  final expiryDate = (_columnsConfig.metaExpiryDate &&
                          (meta?.expiryDate?.isNotEmpty ?? false))
                      ? DateTime.tryParse(meta!.expiryDate!)
                      : null;
                  final isExpired =
                      expiryDate != null && expiryDate.isBefore(DateTime.now());
                  final storageLocation =
                      _columnsConfig.metaStorageLocation ? meta?.storageLocation : null;
                  if ((storageLocation == null || storageLocation.isEmpty) &&
                      expiryDate == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (storageLocation != null && storageLocation.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.place_outlined,
                                size: 14, color: Colors.blueGrey),
                            label: Text(storageLocation,
                                style: const TextStyle(fontSize: AppFontSize.xsmall)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.blueGrey[50],
                          ),
                        if (expiryDate != null)
                          Chip(
                            avatar: Icon(
                                isExpired ? Icons.error_outline : Icons.event_outlined,
                                size: 14,
                                color: isExpired ? Colors.red : Colors.orange[800]),
                            label: Text(
                                '${isExpired ? 'Expired ' : 'Exp '}${DateFormat(_datePattern).format(expiryDate)}',
                                style: TextStyle(
                                    fontSize: AppFontSize.xsmall,
                                    color: isExpired ? Colors.red : null)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: isExpired ? Colors.red[50] : Colors.orange[50],
                          ),
                      ],
                    ),
                  );
                }),
                if (_showQuantity) ...[
                  TextField(
                    controller: quantityController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: _quantityLabel.trim().isNotEmpty
                          ? _quantityLabel.trim()
                          : 'Quantity',
                      hintText: '1',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.numbers),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType: _fractionalQuantity
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onSubmitted: (_) => addInvoiceProductImpl(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_showQuantity && _columnsConfig.unit) ...[
                  _buildUnitPicker(
                    selectedUnit: dialogUnit,
                    customController: unitController,
                    onUnitChanged: (v) => setDialogState(() => dialogUnit = v),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_columnsConfig.defaultDiscount || product.defaultDiscount > 0) ...[
                  TextField(
                    controller: discountController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fieldDiscountLabel,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.discount),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDiscountPerUnitToggle(discountPerUnit,
                      (val) => setDialogState(() => discountPerUnit = val)),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: unitPriceController,
                  autofocus: !_showQuantity,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fieldUnitPriceOverrideLabel,
                    helperText: 'Default: $_currencySymbol${product.price}',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixText: '$_currencySymbol ',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onSubmitted: (_) => addInvoiceProductImpl(),
                ),
                if (_columnsConfig.extraCost) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: extraCostController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fieldExtraCostLabel,
                      hintText: '0.00',
                      helperText: 'Flat fee added on top of the line total',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
                if (_showDescriptionInPdf) ...[
                  const SizedBox(height: 16),
                  _buildItemDescriptionField(descriptionController),
                ],
                if (invoiceItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.format_list_numbered,
                          size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.fieldInsertAtPositionLabel,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: insertAt > 1
                            ? () => setDialogState(() => insertAt--)
                            : null,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text('$insertAt',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: insertAt < invoiceItems.length + 1
                            ? () => setDialogState(() => insertAt++)
                            : null,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => addInvoiceProductImpl(),
              child: Text(AppLocalizations.of(context)!.actionAdd),
            ),
          ],
        ),
      ),
    ).then((_) => _screenFocusNode.requestFocus());
  }

  void addInvoiceProduct(InvoiceItem invoiceItem, {int? insertAt}) {
    final isAdHoc = invoiceItem.product.id.startsWith('custom-');
    final exists = !isAdHoc &&
        !_allowDuplicateInvoiceItems &&
        invoiceItems.any((item) => item.product.id == invoiceItem.product.id);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceProductAlreadyAddedMessage),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
    } else {
      final isAppend = insertAt == null || insertAt >= invoiceItems.length + 1;
      if(!mounted) return;
      setState(() {
        if (!isAppend) {
          invoiceItems.insert(insertAt - 1, invoiceItem);
        } else {
          invoiceItems.add(invoiceItem);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_invoiceItemsScrollController.hasClients && isAppend) {
          _invoiceItemsScrollController.animateTo(
            _invoiceItemsScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// Builds the Customer to attach to the invoice. If the form fields no
  /// longer match `selectedCustomer`'s saved record (edited but not saved
  /// via _saveCustomer), the invoice must NOT keep pointing at that
  /// customer's id — doing so would link invoiceId -> customerId while the
  /// snapshot's name/address/etc silently disagree with that customer's
  /// actual row. Falls back to a fresh, unlinked id in that case.
  bool get _customerFormMatchesSelected {
    final sel = selectedCustomer;
    return sel != null &&
        sel.name == nameController.text &&
        sel.email == emailController.text &&
        sel.phone == phoneController.text &&
        sel.address == addressController.text &&
        sel.gstin == gstinController.text &&
        sel.businessName == businessNameController.text;
  }

  Customer _resolveInvoiceCustomer() {
    final name = nameController.text;
    final email = emailController.text;
    final phone = phoneController.text;
    final address = addressController.text;
    final gstin = gstinController.text;
    final businessName = businessNameController.text;

    final matchesSelected = _customerFormMatchesSelected;
    final sel = selectedCustomer;

    return Customer(
      id: matchesSelected ? sel!.id : const Uuid().v4(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      gstin: gstin,
      businessName: businessName,
    );
  }

  Future<bool> _createInvoice() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceCustomerNameRequiredMessage),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return false;
    }

    if (invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceAtLeastOneItemRequiredMessage),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return false;
    }

    if(!mounted) return false;
    setState(() => isLoading = true);

    try {
      final invoiceId = await InvoicePdfServices.generateNextId();
      final invoiceNumber =
          await InvoicePdfServices.generateNextInvoiceNumber(invoiceType);
      final invoice = Invoice(
        id: invoiceId,
        invoiceNumber: invoiceNumber,
        customer: _resolveInvoiceCustomer(),
        items: List.from(invoiceItems),
        date: _selectedOrderDate,
        dueDate: _selectedDueDate,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: _taxMode == TaxMode.global ? taxRate : 0.0,
        type: invoiceType,
        invoiceTitle: invoiceType == 'Invoice' ? invoiceTitle : null,
        currencyCode: _currencyCode,
        currencySymbol: _currencySymbol,
        taxMode: _taxMode,
        isInterState: _isInterState,
        upiId: _selectedUpi?.id,
        bankAccountId: _selectedBankAccount?.accountNumber,
        quantityLabel:
            _quantityLabel.trim().isEmpty ? null : _quantityLabel.trim(),
        additionalCosts: _buildAdditionalCosts(),
        customFields: _buildCustomFields(),
        invoiceDiscountType: _invoiceDiscountType,
        invoiceDiscountValue: _invoiceDiscountValue,
        hideInvoiceNumber: _hideInvoiceNumber,
        customInvoiceNumber: customInvoiceNumberController.text.trim().isEmpty
            ? null
            : customInvoiceNumberController.text.trim(),
      );

      await ref.read(invoiceRepositoryProvider).insertInvoice(invoice);

      if (!mounted) return true;
      setState(() {
        _invoice = invoice;
        currentInvoiceNumber = invoice.invoiceNumber ?? invoice.id;
        isLoading = false;
      });
      _markFormClean();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceCreatedSuccessMessage(_invoiceTypeLabel(invoiceType))),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => isLoading = false);
      if (kDebugMode)  print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.createInvoiceErrorCreatingMessage(e.toString())),showCloseIcon: true,),
      );
      return false;
    }
  }

  void _editInvoiceItem(int index) {
    final item = invoiceItems[index];
    final quantityController = TextEditingController(
        text: item.quantity == 1.0
            ? ''
            : item.quantity == item.quantity.roundToDouble()
                ? item.quantity.toInt().toString()
                : item.quantity.toString());
    final discountController =
        TextEditingController(text: item.discount.toString());
    final unitPriceController =
        TextEditingController(text: item.effectivePrice.toString());
    final extraCostController = TextEditingController(
        text: item.extraCost != null ? item.extraCost.toString() : '');
    bool discountPerUnit = item.discountPerUnit;
    final unitController = TextEditingController(text: item.effectiveUnit.toString());
    final descriptionController =
        TextEditingController(text: item.effectiveDescription);
    String dialogUnit = item.effectiveUnit.toString();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          // The extra description field can push this past the viewport on
          // short windows; the add-item dialog already scrolls its content.
          scrollable: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit, color: Colors.blue),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceEditItemTitle, style: const TextStyle(fontSize: AppFontSize.xlarge)),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppFontSize.xlarge),
                        ),
                      ),
                      if (_businessType == BusinessType.both &&
                          _columnsConfig.type) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.product.type == 'service'
                                ? Colors.purple.withValues(alpha: 0.15)
                                : Colors.indigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.product.type == 'service'
                                ? 'Service'
                                : 'Product',
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
                Builder(builder: (context) {
                  if (!_columnsConfig.productMetadata) return const SizedBox.shrink();
                  final meta = _productMetadata[item.product.id];
                  final expiryDate = (_columnsConfig.metaExpiryDate &&
                          (meta?.expiryDate?.isNotEmpty ?? false))
                      ? DateTime.tryParse(meta!.expiryDate!)
                      : null;
                  final isExpired =
                      expiryDate != null && expiryDate.isBefore(DateTime.now());
                  final storageLocation =
                      _columnsConfig.metaStorageLocation ? meta?.storageLocation : null;
                  if ((storageLocation == null || storageLocation.isEmpty) &&
                      expiryDate == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (storageLocation != null && storageLocation.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.place_outlined,
                                size: 14, color: Colors.blueGrey),
                            label: Text(storageLocation,
                                style: const TextStyle(fontSize: AppFontSize.xsmall)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.blueGrey[50],
                          ),
                        if (expiryDate != null)
                          Chip(
                            avatar: Icon(
                                isExpired ? Icons.error_outline : Icons.event_outlined,
                                size: 14,
                                color: isExpired ? Colors.red : Colors.orange[800]),
                            label: Text(
                                '${isExpired ? 'Expired ' : 'Exp '}${DateFormat(_datePattern).format(expiryDate)}',
                                style: TextStyle(
                                    fontSize: AppFontSize.xsmall,
                                    color: isExpired ? Colors.red : null)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: isExpired ? Colors.red[50] : Colors.orange[50],
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                if (_showQuantity) ...[
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: _quantityLabel.trim().isNotEmpty
                          ? _quantityLabel.trim()
                          : 'Quantity',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.numbers),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType: _fractionalQuantity
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
                if (_showQuantity && _columnsConfig.unit) ...[
                  const SizedBox(height: 16),
                  _buildUnitPicker(
                    selectedUnit: dialogUnit,
                    customController: unitController,
                    onUnitChanged: (v) => setDialogState(() => dialogUnit = v),
                  ),
                ],
                if (_columnsConfig.defaultDiscount || item.product.defaultDiscount > 0 || item.discount > 0) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: discountController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fieldDiscountLabel,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.discount),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDiscountPerUnitToggle(discountPerUnit,
                      (val) => setDialogState(() => discountPerUnit = val)),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: unitPriceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fieldUnitPriceOverrideLabel,
                    helperText:
                        'Default: $_currencySymbol${item.product.price}',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixText: '$_currencySymbol ',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
                if (_columnsConfig.extraCost) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: extraCostController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fieldExtraCostLabel,
                      hintText: '0.00',
                      helperText: 'Flat fee added on top of the line total',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
                if (_showDescriptionInPdf) ...[
                  const SizedBox(height: 16),
                  _buildItemDescriptionField(descriptionController),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                final parsedUnitPrice = double.tryParse(unitPriceController.text);
                final unitPrice = (parsedUnitPrice != null &&
                        parsedUnitPrice != item.product.price)
                    ? parsedUnitPrice
                    : null;
                final extraCost = double.tryParse(extraCostController.text);
                final updatedItem = InvoiceItem(
                  product: item.product,
                  quantity: !_showQuantity
                      ? 1.0
                      : _fractionalQuantity
                          ? (double.tryParse(quantityController.text) ??
                              item.quantity)
                          : (int.tryParse(quantityController.text) ??
                                  double.tryParse(quantityController.text)
                                      ?.toInt() ??
                                  item.quantity.toInt())
                              .toDouble(),
                  discount:
                      double.tryParse(discountController.text) ?? item.discount,
                  unitPrice: unitPrice,
                  extraCost: extraCost,
                  unit: dialogUnit.trim(),
                  description: descriptionController.text.trim(),
                  discountPerUnit: discountPerUnit,
                );
                if(!mounted) return;
                setState(() {
                  invoiceItems[index] = updatedItem;
                });

                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.actionUpdate),
            ),
          ],
        ),
      ),
    ).then((_) => _screenFocusNode.requestFocus());
  }

  void _addAdHocItemDialog() {
    final nameController = TextEditingController();
    final aliasNameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    final taxRateController = TextEditingController(text: '0');
    final extraCostController = TextEditingController();
    final unitController = TextEditingController();
    final descriptionController = TextEditingController();

    bool discountPerUnit = true;
    bool dialogPriceIncludesTax = false;
    String dialogItemType = _adHocItemType;
    int insertAt = invoiceItems.length + 1;
    String selectedUnit = '';
    String? nameError;
    String? priceError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submitAdHocItem() {
            final name = nameController.text.trim();
            final priceText = priceController.text.trim();
            final price = double.tryParse(priceText) ?? 0.0;
            final newNameError = name.isEmpty ? 'Required' : null;
            final newPriceError = priceText.isEmpty
                ? 'Required'
                : price <= 0
                    ? 'Must be > 0'
                    : null;
            if (newNameError != null || newPriceError != null) {
              setDialogState(() {
                nameError = newNameError;
                priceError = newPriceError;
              });
              return;
            }
            final taxRate = _taxMode == TaxMode.perItem
                ? (int.tryParse(taxRateController.text) ?? 0)
                : 0;

            final adHocProduct = Product(
              id: 'custom-${const Uuid().v4()}',
              name: name,
              description: '',
              price: price,
              stock: 0,
              hsncode: '',
              tax_rate: taxRate,
              unit: selectedUnit.trim(),
              type: dialogItemType,
              aliasName: aliasNameController.text.trim().isEmpty
                  ? null
                  : aliasNameController.text.trim(),
              priceIncludesTax: dialogPriceIncludesTax,
            );
            final extraCost = double.tryParse(extraCostController.text);
            final item = InvoiceItem(
              product: adHocProduct,
              quantity: !_showQuantity
                  ? 1.0
                  : _fractionalQuantity
                      ? (double.tryParse(quantityController.text) ?? 1.0)
                      : (int.tryParse(quantityController.text) ?? 1)
                          .toDouble(),
              discount: double.tryParse(discountController.text) ?? 0.0,
              extraCost: extraCost,
              unit: selectedUnit.trim(),
              description: descriptionController.text.trim(),
              discountPerUnit: discountPerUnit,
            );
            Navigator.pop(context);
            addInvoiceProduct(item, insertAt: insertAt);
          }

          return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_box, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceCustomItemTitle,
                  style: const TextStyle(fontSize: AppFontSize.xlarge)),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_businessType == BusinessType.both &&
                      _columnsConfig.type) ...[
                    SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'product',
                          label: Text(AppLocalizations.of(context)!.labelProduct),
                          icon: const Icon(Icons.inventory_2_outlined, size: 16)),
                      ButtonSegment(
                          value: 'service',
                          label: Text(AppLocalizations.of(context)!.labelService),
                          icon: const Icon(Icons.design_services_outlined, size: 16)),
                    ],
                    selected: {dialogItemType},
                    onSelectionChanged: (val) =>
                        setDialogState(() => dialogItemType = val.first),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fieldItemNameLabel,
                    errorText: nameError,
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixIcon: const Icon(Icons.label),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (_) {
                    if (nameError != null) setDialogState(() => nameError = null);
                  },
                  onSubmitted: (_) => submitAdHocItem(),
                ),
                if (_columnsConfig.aliasName) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: aliasNameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fieldAliasForPdfLabel,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.translate),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: _showQuantity ? AppLocalizations.of(context)!.fieldUnitPriceLabel : AppLocalizations.of(context)!.fieldRateLabel,
                    errorText: priceError,
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixText: '$_currencySymbol ',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) {
                    if (priceError != null) setDialogState(() => priceError = null);
                  },
                  onSubmitted: (_) => submitAdHocItem(),
                ),
                if (_showQuantity) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: _quantityLabel.trim().isNotEmpty
                          ? _quantityLabel.trim()
                          : 'Quantity',
                      hintText: '1',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.numbers),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType: _fractionalQuantity
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
                if (_showQuantity && _columnsConfig.unit) ...[
                  const SizedBox(height: 16),
                  _buildUnitPicker(
                    selectedUnit: selectedUnit,
                    customController: unitController,
                    onUnitChanged: (v) => setDialogState(() => selectedUnit = v),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fieldDiscountLabel,
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                    prefixIcon: const Icon(Icons.discount),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDiscountPerUnitToggle(discountPerUnit,
                    (val) => setDialogState(() => discountPerUnit = val)),
                if (_columnsConfig.extraCost) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: extraCostController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fieldExtraCostLabel,
                      hintText: '0.00',
                      helperText: 'Flat fee added on top of the line total',
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
                if (_taxMode == TaxMode.perItem && _columnsConfig.taxRate) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: taxRateController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fieldTaxRateLabel,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.percent),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(AppLocalizations.of(context)!.fieldPriceIncludesTaxLabel),
                    value: dialogPriceIncludesTax,
                    onChanged: (val) => setDialogState(
                        () => dialogPriceIncludesTax = val ?? false),
                  ),
                ],
                if (_showDescriptionInPdf) ...[
                  const SizedBox(height: 16),
                  _buildItemDescriptionField(descriptionController),
                ],
                if (invoiceItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.format_list_numbered,
                          size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.fieldInsertAtPositionLabel,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: insertAt > 1
                            ? () => setDialogState(() => insertAt--)
                            : null,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text('$insertAt',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: insertAt < invoiceItems.length + 1
                            ? () => setDialogState(() => insertAt++)
                            : null,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: submitAdHocItem,
              child: Text(AppLocalizations.of(context)!.actionAdd, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
        },
      ),
    ).then((_) => _screenFocusNode.requestFocus());
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

  void _filterProducts(String query) {
    if (!mounted) return;
    _productSearchDebounce?.cancel();
    _productSearchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final requestId = ++_productSearchRequestId;
      final repo = ref.read(productRepositoryProvider);
      final results = await repo.getProductsPaginated(
          offset: 0, limit: _productFetchLimit, query: query, type: _businessType.key);
      final metadata =
          await repo.getProductMetadataForIds(results.map((e) => e.id).toList());
      if (requestId != _productSearchRequestId || !mounted) return;
      setState(() {
        filteredProducts = results;
        _productMetadata = {..._productMetadata, ...metadata};
      });
    });
  }

  void _filterCustomers(String query, {VoidCallback? onResults}) {
    if (!mounted) return;
    _customerSearchDebounce?.cancel();
    _customerSearchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final requestId = ++_customerSearchRequestId;
      final results = await ref.read(customerRepositoryProvider).getCustomersPaginated(
          offset: 0, limit: _customerFetchLimit, query: query);
      if (requestId != _customerSearchRequestId || !mounted) return;
      setState(() {
        filteredCustomers = results;
      });
      onResults?.call();
    });
  }

  Future<void> _selectCustomer(Customer? customer) async {
    if(!mounted) return;
    setState(() {
      selectedCustomer = customer;
      nameController.text = customer?.name ?? '';
      emailController.text = customer?.email ?? '';
      phoneController.text = customer?.phone ?? '';
      addressController.text = customer?.address ?? '';
      gstinController.text = customer?.gstin ?? '';
      businessNameController.text = customer?.businessName ?? '';
    });
    await _loadPreviousBalanceDue(customer);
  }

  Future<void> _loadPreviousBalanceDue(Customer? customer) async {
    final requestId = ++_previousBalanceRequestSerial;

    if (!_showPreviousBalance ||
        customer == null ||
        customer.id.trim().isEmpty ||
        invoiceType != 'Invoice')
    {
      if (!mounted) return;
      setState(() {
        _previousBalanceDue = 0.0;
        _isPreviousBalanceLoading = false;
      });
      return;
    }
    if(!mounted) return;
    setState(() => _isPreviousBalanceLoading = true);
    try {
      final balance = await ref.read(invoiceRepositoryProvider).getPreviousBalanceDueForCustomer(
        customerId: customer.id,
        currencyCode: _currencyCode,
        asOfDate: _selectedOrderDate,
        currentInvoiceId: currentInvoiceNumber.isNotEmpty
            ? currentInvoiceNumber
            : _invoice?.id,
      );
      if (!mounted || requestId != _previousBalanceRequestSerial) return;
      setState(() {
        _previousBalanceDue = balance;
        _isPreviousBalanceLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _previousBalanceRequestSerial) return;
      setState(() {
        _previousBalanceDue = 0.0;
        _isPreviousBalanceLoading = false;
      });
    }
  }

  Future<void> resetInvoiceType(String invoiceType_) async {
    if(!mounted) return;
    setState(() {
      invoiceType = invoiceType_;
      if (invoiceType_ != 'Invoice') invoiceTitle = null;
    });
    if (!isEditing) {
      final invNumber =
          await InvoicePdfServices.peekNextInvoiceNumber(invoiceType_);
      if (mounted) setState(() => currentInvoiceNumber = invNumber);
    }
    await _loadPreviousBalanceDue(selectedCustomer);
  }

  Future<void> resetValues(String invoiceType_) async {
    if(!mounted) return;
    final invType = await InvoicePdfServices.peekNextInvoiceNumber(invoiceType_);
    if(!mounted) return;
    setState(() {
      invoiceType = invoiceType_;
      currentInvoiceNumber = invType;
      _invoice = null;
      isEditing = false;
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
      _selectedOrderDate = DateTime.now();
      dateController.text = DateFormat(_datePattern).format(_selectedOrderDate);
      _selectedDueDate = null;
      dueDateController.clear();
      _previousBalanceDue = 0.0;
      _isPreviousBalanceLoading = false;
    });
    await _setAdditionalNote(forceDefault: true);
    _markFormClean();
  }

  Future<void> _showPhoneTakenError(String ownerName) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.createInvoicePhoneAlreadyInUseTitle),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.createInvoicePhoneAlreadyInUseMessage(ownerName),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionOk),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (_isSavingCustomer) return;
    if(!mounted) return;
    setState(() => _isSavingCustomer = true);
    try {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceCustomerNameRequiredBeforeSavingMessage),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final phone = phoneController.text.trim();

    // Editing an already-selected customer whose phone changed: ask whether
    // to overwrite that customer's record or split off a new one, instead
    // of silently matching/creating based on phone alone.
    var forceNew = false;
    final sel = selectedCustomer;
    if (sel != null && sel.id.isNotEmpty && phone != sel.phone) {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.phone_forwarded, color: Colors.orange),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoicePhoneChangedTitle),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.createInvoicePhoneChangedMessage(sel.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'new'),
              child: Text(AppLocalizations.of(context)!.createInvoiceSaveAsNewButton),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, 'update'),
              child: Text(AppLocalizations.of(context)!.createInvoiceUpdateExistingButton,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (choice == null) return;
      if (choice == 'update') {
        final phoneOwner = await ref.read(customerRepositoryProvider).findByPhone(phone);
        if (phoneOwner != null && phoneOwner.id != sel.id) {
          await _showPhoneTakenError(phoneOwner.name);
          return;
        }
        final updated = Customer(
          id: sel.id,
          name: name,
          email: emailController.text.trim(),
          phone: phone,
          address: addressController.text.trim(),
          gstin: gstinController.text.trim(),
          businessName: businessNameController.text.trim(),
        );
        await ref.read(customerRepositoryProvider).updateCustomer(updated);
        final reloaded = await ref.read(customerRepositoryProvider).getAllCustomers();
        if (!mounted) return;
        setState(() {
          selectedCustomer = updated;
          customers = reloaded;
          filteredCustomers = reloaded;
        });
        await _loadPreviousBalanceDue(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.createInvoiceCustomerUpdatedMessage(updated.name)),
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
            ),
          );
        }
        return;
      }
      // choice == 'new': fall through to the phone-lookup flow below,
      // which still guards against colliding with a *different* customer's phone.
      forceNew = true;
    }

    final existing = await ref.read(customerRepositoryProvider).findByPhone(phone);

    if (existing != null && forceNew) {
      // User explicitly chose "Save as New" above, but this phone number
      // is already used by a different customer. Phone numbers must be
      // unique — block instead of creating a duplicate.
      await _showPhoneTakenError(existing.name);
      return;
    }

    if (existing != null) {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_search, color: Colors.orange),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceCustomerAlreadyExistsTitle),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.createInvoiceCustomerAlreadyExistsMessage(existing.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'use'),
              child: Text(AppLocalizations.of(context)!.createInvoiceUseExistingButton),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, 'update'),
              child:
                  Text(AppLocalizations.of(context)!.actionUpdate, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (choice == null) return;

      if (choice == 'use') {
        if (!mounted) return;
        setState(() {
          selectedCustomer = existing;
          nameController.text = existing.name;
          emailController.text = existing.email;
          phoneController.text = existing.phone;
          addressController.text = existing.address;
          gstinController.text = existing.gstin;
          businessNameController.text = existing.businessName;
        });
        await _loadPreviousBalanceDue(existing);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.createInvoiceUsingExistingCustomerMessage(existing.name)),
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
            ),
          );
        }
        return;
      }

      final updated = Customer(
        id: existing.id,
        name: name,
        email: emailController.text.trim(),
        phone: phone,
        address: addressController.text.trim(),
        gstin: gstinController.text.trim(),
        businessName: businessNameController.text.trim(),
      );
      await ref.read(customerRepositoryProvider).updateCustomer(updated);
      final reloaded = await ref.read(customerRepositoryProvider).getAllCustomers();
      if(!mounted) return;
      setState(() {
        selectedCustomer = updated;
        customers = reloaded;
        filteredCustomers = reloaded;
      });
      await _loadPreviousBalanceDue(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.createInvoiceCustomerUpdatedMessage(updated.name)),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
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
      await ref.read(customerRepositoryProvider).insertCustomer(newCustomer);
      final reloaded = await ref.read(customerRepositoryProvider).getAllCustomers();
      if(!mounted) return;
      setState(() {
        selectedCustomer = newCustomer;
        customers = reloaded;
        filteredCustomers = reloaded;
      });
      await _loadPreviousBalanceDue(newCustomer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.createInvoiceCustomerSavedMessage(newCustomer.name)),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
    }
    } finally {
      if (mounted) setState(() => _isSavingCustomer = false);
    }
  }

  /// Re-reads the selected customer's current record and overwrites the
  /// form fields with it. The invoice keeps whatever was last saved on it
  /// (a snapshot) until this is explicitly triggered — editing an invoice
  /// does NOT silently pull in customer changes made elsewhere since.
  Future<void> _refreshCustomerFromRecord() async {
    final current = selectedCustomer;
    if (current == null || current.id.trim().isEmpty) return;
    final latest = await ref.read(customerRepositoryProvider).getCustomerById(current.id);
    if (!mounted) return;
    if (latest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.createInvoiceCustomerRecordGoneMessage),showCloseIcon: true,),
      );
      return;
    }
    if(!mounted) return;
    setState(() {
      selectedCustomer = latest;
      nameController.text = latest.name;
      emailController.text = latest.email;
      phoneController.text = latest.phone;
      addressController.text = latest.address;
      gstinController.text = latest.gstin;
      businessNameController.text = latest.businessName;
    });
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.createInvoiceCustomerRefreshedMessage),
      showCloseIcon: true,),
    );
  }

  void _clearCustomerSelection() {
    if (!mounted) return;
    setState(() {
      selectedCustomer = null;
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      addressController.clear();
      gstinController.clear();
      businessNameController.clear();
      _previousBalanceDue = 0.0;
      _isPreviousBalanceLoading = false;
    });
  }

  double get _invoiceDiscountValue =>
      double.tryParse(_invoiceDiscountController.text) ?? 0.0;

  List<CustomFieldValue> _buildCustomFields() {
    final values = <CustomFieldValue>[];
    for (final def in _customFieldDefs) {
      final value = (_customFieldValues[def.id] ?? '').trim();
      if (value.isNotEmpty) {
        values.add(CustomFieldValue(defId: def.id, label: def.label, value: value));
      }
    }
    return values;
  }

  // Shown at equal width beside the Customer form (see _buildDesktopLayoutV2)
  // so it reads as a peer section, not a narrow sidebar. Not directly
  // editable inline like the Customer form though — these are optional
  // metadata that shouldn't grow the row unpredictably based on how many
  // fields are defined — so it displays whatever's already filled and a
  // button opens _showCustomFieldsDialogV2 to fill/change values.
  Widget _customFieldsSummaryCardV2() {
    if (!_customFieldsEnabled || _customFieldDefs.isEmpty) {
      return const SizedBox.shrink();
    }
    final filled = _customFieldDefs
        .map((d) => (label: d.label, value: (_customFieldValues[d.id] ?? '').trim()))
        .where((e) => e.value.isNotEmpty)
        .toList();

    Widget tile(({String label, String value})? f) => Expanded(
          child: f == null
              ? const SizedBox()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(f.value,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2),
                    ],
                  ),
                ),
        );

    // Fixed height (roughly the Customer Details card's own height) instead
    // of sizing to content — with 1 field or 13 filled, the row this card
    // sits in should still line up with the Customer form, not balloon out
    // or shrink to almost nothing. Overflow scrolls internally.
    return Container(
      height: 165,
      decoration: _flatCardDecorationV2(context),
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CUSTOM FIELDS',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${filled.length}/${_customFieldDefs.length}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showCustomFieldsDialogV2,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(filled.isEmpty ? 'Add' : 'Edit'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filled.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'No custom fields filled yet.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < filled.length; i += 2)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tile(filled[i]),
                              tile(i + 1 < filled.length ? filled[i + 1] : null),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCustomFieldsDialogV2() {
    final controllers = {
      for (final def in _customFieldDefs)
        def.id: TextEditingController(text: _customFieldValues[def.id] ?? ''),
    };
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Custom Fields',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _customFieldDefs.length; i += 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controllers[_customFieldDefs[i].id],
                                    decoration: _flatFieldDecorationV2(
                                        _customFieldDefs[i].label,
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.open_in_full, size: 16),
                                          tooltip: AppLocalizations.of(context)!
                                              .tooltipEditInLargerView,
                                          onPressed: () => _editLongTextDialogV2(
                                            title: _customFieldDefs[i].label,
                                            controller: controllers[_customFieldDefs[i].id]!,
                                          ),
                                        )),
                                  ),
                                ),
                                if (i + 1 < _customFieldDefs.length) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          controllers[_customFieldDefs[i + 1].id],
                                      decoration: _flatFieldDecorationV2(
                                          _customFieldDefs[i + 1].label,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.open_in_full, size: 16),
                                            tooltip: AppLocalizations.of(context)!
                                                .tooltipEditInLargerView,
                                            onPressed: () => _editLongTextDialogV2(
                                              title: _customFieldDefs[i + 1].label,
                                              controller:
                                                  controllers[_customFieldDefs[i + 1].id]!,
                                            ),
                                          )),
                                    ),
                                  ),
                                ] else
                                  const Expanded(child: SizedBox()),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(AppLocalizations.of(context)!.actionCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final updated = {
                          for (final def in _customFieldDefs)
                            def.id: controllers[def.id]!.text,
                        };
                        Navigator.of(dialogContext).pop();
                        if (!mounted) return;
                        setState(() => _customFieldValues = updated);
                      },
                      child: Text(AppLocalizations.of(context)!.actionSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.xsmall)),
            onTap: () {
              if(!mounted) return;
              setState(() => _showAdditionalCosts = !_showAdditionalCosts);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.add_box_outlined,
                      size: 18, color: Colors.teal[700]),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_additionalCostControllers.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _showAdditionalCosts
                        ? Icons.expand_less
                        : Icons.expand_more,
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
                              onChanged: (_) {
                                if(!mounted) return;
                                setState(() {});
                                },
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.fieldLabelLabel,
                                hintText: AppLocalizations.of(context)!.hintLabelExample,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row.amount,
                              onChanged: (_) {
                                if(!mounted) return;
                                setState(() {});
                              },
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.labelAmount,
                                prefixText: '$_currencySymbol ',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red, size: 20),
                            tooltip: AppLocalizations.of(context)!.tooltipRemove,
                            onPressed: () {
                              if(!mounted) return;
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
                        if(!mounted) return;
                        setState(() {
                          _additionalCostControllers.add((
                            label: TextEditingController(),
                            amount: TextEditingController(),
                          ));
                        });
                      },
                      icon: Icon(Icons.add_circle_outline,
                          color: primary, size: 16),
                      label: Text(AppLocalizations.of(context)!.createInvoiceAddRowButton,
                          style: TextStyle(color: primary, fontSize: 13)),
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
            Text(AppLocalizations.of(context)!.fieldDiscountPerUnitLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              value
                  ? AppLocalizations.of(context)!.createInvoiceDiscountPerUnitFormulaOn
                  : AppLocalizations.of(context)!.createInvoiceDiscountPerUnitFormulaOff,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  // Optional per-line description, stored on the invoice item. The
  // add-product dialog seeds it from the product's own description; the
  // ad-hoc dialog starts empty. Whatever is left here is snapshotted on
  // the item and prints under the item name.
  Widget _buildItemDescriptionField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'Extra detail printed under the item name',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        prefixIcon: const Icon(Icons.notes_outlined, size: 18),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      minLines: 1,
      maxLines: 3,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildUnitPicker({
    required String selectedUnit,
    required TextEditingController customController,
    required ValueChanged<String> onUnitChanged,
  }) {
    return _UnitPicker(
      initialUnit: selectedUnit,
      customController: customController,
      onUnitChanged: onUnitChanged,
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            color: isTotal ? Colors.green : Theme.of(context).colorScheme.onSurface,
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
              color: isTotal ? Colors.green : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousBalanceDueRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 190;
        final value = _isPreviousBalanceLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orange[800],
                ),
              )
            : Text(
                '$_currencySymbol${_previousBalanceDue.toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            border: Border.all(color: Colors.orange[200]!, width: 0.8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Colors.orange[800],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  compact ? AppLocalizations.of(context)!.createInvoicePrevBalanceShortLabel : AppLocalizations.of(context)!.createInvoicePreviousBalanceDueLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[900],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: compact ? 2 : 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: value,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalDueRow(double totalDue) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[700],
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  compact ? AppLocalizations.of(context)!.createInvoiceDueShortLabel : AppLocalizations.of(context)!.createInvoiceTotalDueLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: compact ? 2 : 1,
                child: Text(
                  '$_currencySymbol${totalDue.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: onPressed != null ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            iconSize: 28,
            onPressed: onPressed,
            tooltip: tooltip ?? label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<bool> _updateInvoice() async {
    if (_invoice == null) return false;

    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceCustomerNameRequiredMessage),
            ],
          ),
          backgroundColor: Colors.red,
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return false;
    }

    if (invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceAtLeastOneItemRequiredMessage),
            ],
          ),
          backgroundColor: Colors.red,
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return false;
    }
    if(!mounted) return false;
    setState(() => isLoading = true);

    try {
      final updatedInvoice = Invoice(
        id: _invoice!.id,
        invoiceNumber: _invoice!.invoiceNumber,
        customer: _resolveInvoiceCustomer(),
        items: List.from(invoiceItems),
        date: _selectedOrderDate,
        dueDate: _selectedDueDate,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: _taxMode == TaxMode.global ? taxRate : 0.0,
        type: invoiceType,
        invoiceTitle: invoiceType == 'Invoice' ? invoiceTitle : null,
        currencyCode: _currencyCode,
        currencySymbol: _currencySymbol,
        taxMode: _taxMode,
        isInterState: _isInterState,
        upiId: _selectedUpi?.id,
        bankAccountId: _selectedBankAccount?.accountNumber,
        quantityLabel:
            _quantityLabel.trim().isEmpty ? null : _quantityLabel.trim(),
        additionalCosts: _buildAdditionalCosts(),
        customFields: _buildCustomFields(),
        invoiceDiscountType: _invoiceDiscountType,
        invoiceDiscountValue: _invoiceDiscountValue,
        hideInvoiceNumber: _hideInvoiceNumber,
        customInvoiceNumber: customInvoiceNumberController.text.trim().isEmpty
            ? null
            : customInvoiceNumberController.text.trim(),
      );

      await ref.read(invoiceRepositoryProvider).updateInvoice(updatedInvoice);

      final refreshedInvoice =
          await ref.read(invoiceRepositoryProvider).getInvoiceById(updatedInvoice.id);

      if (!mounted) return true;
      setState(() {
        _invoice = refreshedInvoice ?? updatedInvoice;
        isLoading = false;
      });
      _markFormClean();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceUpdatedSuccessMessage(_invoiceTypeLabel(invoiceType))),
            ],
          ),
          backgroundColor: Colors.green,
          showCloseIcon: true,
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.createInvoiceErrorUpdatingMessage(e.toString())),showCloseIcon: true,),
      );
      return false;
    }
  }

  Widget _buildSuccessActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
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
            tooltip: tooltip ?? label,
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
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surface,
                    ]
                  : [
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
                  child: Icon(Icons.check_circle,
                      color: Colors.green.shade700, size: 80),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.createInvoiceCreatedHeadline(_invoiceTypeLabel(invoiceType)),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.createInvoiceIdLabel(_invoiceTypeLabel(invoiceType), '${_invoice?.invoiceNumber}'),
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
                      label: AppLocalizations.of(context)!.createInvoiceViewDetailsLabel,
                      color: Colors.green,
                      onPressed: () => InvoicePdfServices.showInvoiceDetails(
                          context, _invoice!),
                    ),
                    const SizedBox(width: 16),
                    _buildSuccessActionButton(
                      icon: Icons.picture_as_pdf,
                      label: AppLocalizations.of(context)!.createInvoicePreviewPdfLabel,
                      tooltip: AppLocalizations.of(context)!.createInvoicePreviewPdfTooltip,
                      color: Colors.purple,
                      onPressed: () =>
                          InvoicePdfServices.previewPDF(context, _invoice!),
                    ),
                    const SizedBox(width: 16),
                    _buildSuccessActionButton(
                      icon: Icons.download_outlined,
                      label: AppLocalizations.of(context)!.actionDownloadPdf,
                      color: Colors.deepPurple,
                      onPressed: () =>
                          PDFService.downloadPDF(context, _invoice!),
                    ),
                    const SizedBox(width: 16),
                    _buildSuccessActionButton(
                      icon: Icons.print,
                      label: AppLocalizations.of(context)!.createInvoicePrintPdfLabel,
                      tooltip: AppLocalizations.of(context)!.createInvoicePrintPdfTooltip,
                      color: Colors.blue,
                      onPressed: () =>
                          InvoicePdfServices.generatePDF(context, _invoice!),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Offer to save customer only if they weren't already in the list
                if (selectedCustomer == null &&
                    nameController.text.trim().isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1_outlined,
                            color: Colors.amber.shade800, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Save "${nameController.text.trim()}" to your customer list for future use?',
                            style: TextStyle(
                                fontSize: 13, color: Colors.amber.shade900),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber.shade900,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () async {
                            final phone = phoneController.text.trim();
                            final existing = phone.isNotEmpty
                                ? await ref.read(customerRepositoryProvider).findByPhone(phone)
                                : null;
                            final newCustomer = existing ??
                                Customer(
                                  id: const Uuid().v4(),
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phone,
                                  address: addressController.text.trim(),
                                  gstin: gstinController.text.trim(),
                                  businessName:
                                      businessNameController.text.trim(),
                                );
                            if (existing == null) {
                              await ref.read(customerRepositoryProvider).insertCustomer(newCustomer);
                            }
                            final reloaded =
                                await ref.read(customerRepositoryProvider).getAllCustomers();
                            if (mounted) {
                              setState(() {
                                selectedCustomer = newCustomer;
                                customers = reloaded;
                                filteredCustomers = reloaded;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      AppLocalizations.of(context)!.createInvoiceCustomerSavedMessage(newCustomer.name)),
                                  behavior: SnackBarBehavior.floating,
                                  showCloseIcon: true,
                                ),
                              );
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.actionSave,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          onPressed: () {
                            if(!mounted) return;
                            setState(() =>
                            selectedCustomer = Customer(
                              id: '',
                              name: nameController.text.trim(),
                              email: '',
                              phone: '',
                              address: '',
                              gstin: '',
                              businessName: '',
                            ));
                          },
                          child: Text(AppLocalizations.of(context)!.actionDismiss),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        Size(MediaQuery.of(context).size.width * 0.2, 56),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                    elevation: 2,
                  ),
                  onPressed: () => resetValues("Invoice"),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    AppLocalizations.of(context)!.createInvoiceCreateNewInvoiceButton,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _withUnsavedChangesPopScope(Widget child) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeaveIfDirty() && mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && customers.isEmpty) {
      return _withUnsavedChangesPopScope(Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.createInvoiceAppBarTitle(_invoiceTypeLabel(invoiceType))),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.commonLoadingDataMessage),
            ],
          ),
        ),
      ));
    }

    final additionalTotal =
        _buildAdditionalCosts().fold(0.0, (sum, c) => sum + c.amount);
    final totals = InvoiceTotalsCalculator.totals(
      lines: invoiceItems.map((item) => InvoiceTotalsCalculator.line(
            price: item.effectivePrice,
            quantity: item.quantity,
            discount: item.discount,
            discountPerUnit: item.discountPerUnit,
            extraCost: item.extraCost ?? 0.0,
            taxRatePercent: item.product.tax_rate.toDouble(),
            priceIncludesTax: item.product.priceIncludesTax,
            taxMode: _taxMode,
            globalTaxRatePercent: taxRate * 100,
          )),
      taxMode: _taxMode,
      globalTaxRate: taxRate,
      globalTaxRateFormat: TaxRateFormat.fraction,
      additionalCostsTotal: additionalTotal,
      invoiceDiscountType: _invoiceDiscountType,
      invoiceDiscountValue: _invoiceDiscountValue,
    );
    final subtotal = totals.subtotal;
    final grossSubtotal = totals.grossSubtotal;
    final totalDiscount = totals.totalDiscount;
    final tax = totals.tax;
    final invoiceDiscountAmount = totals.invoiceDiscountAmount;
    final total = totals.total;

    final bool showingSuccessScreen = !isEditing && _invoice != null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (showingSuccessScreen) return;
          if (invoiceItems.isNotEmpty && !isLoading) {
            widget.invoiceToEdit != null ? _updateInvoice() : _createInvoice();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.createInvoiceAddItemBeforeCreatingMessage)),
            );
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyQ, control: true): () async {
          if (showingSuccessScreen)
          {
            if(mounted) await resetValues('Invoice');
          }
          else if(isEditing)
          {
            if (await _confirmLeaveIfDirty() && mounted) {
              widget.onCreateNewInvoice?.call();
              await resetValues('Invoice');
            }
          }
          else
          {
            if(kDebugMode) print("already in create invoice page !");
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          if (showingSuccessScreen) return;
          _productSearchFocusNodeV2.requestFocus();
          if (searchController.text.trim().isNotEmpty) {
            setState(() => _showProductDropdownV2 = true);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyM, control: true): () {
          if (showingSuccessScreen) return;
          _addAdHocItemDialog();
        },
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () {
          if (_invoice == null) return;
          InvoicePdfServices.previewPDF(context, _invoice!);
        },
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          if (_invoice == null) return;
          InvoicePdfServices.generatePDF(context, _invoice!);
        },
      },
      child: Focus(
        focusNode: _screenFocusNode,
        autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _screenFocusNode.requestFocus(),
          child: _withUnsavedChangesPopScope(Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, titleConstraints) {
            // The old title Row had three unconstrained children (title +
            // optional button, date, and a 24px-font invoice number +
            // tooltip) with nothing able to shrink — any one of them being
            // a little long (a longer invoice number, "Edit Invoice" plus
            // the button, etc.) pushed the total past the AppBar's
            // available width and overflowed. Now each piece is wrapped in
            // Flexible with ellipsis so it can never force an overflow, the
            // oversized 24px invoice-number font is toned down, and the
            // lowest-priority piece (the date) is dropped entirely on
            // narrow windows instead of fighting for space.
            final compact = titleConstraints.maxWidth < 640;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _invoice != null && !isEditing
                              ? AppLocalizations.of(context)!.createInvoiceCreatedTitleShort(_invoiceTypeLabel(invoiceType))
                              : widget.invoiceToEdit != null
                                  ? AppLocalizations.of(context)!.createInvoiceEditTitle(_invoiceTypeLabel(invoiceType))
                                  : widget.cloneFrom != null
                                      ? AppLocalizations.of(context)!.createInvoiceDuplicateAsTitle(_invoiceTypeLabel(invoiceType))
                                      : AppLocalizations.of(context)!.createInvoiceAppBarTitle(_invoiceTypeLabel(invoiceType)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (await _confirmLeaveIfDirty() && mounted) {
                              widget.onCreateNewInvoice?.call();
                              await resetValues('Invoice');
                            }
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                              compact ? AppLocalizations.of(context)!.createInvoiceNewShortLabel : AppLocalizations.of(context)!.createInvoiceNewInvoiceShortcutLabel,
                              style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceContainer,
                            foregroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact) Text(DateFormat(_datePattern).format(DateTime.now())),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            style: TextStyle(fontSize: compact ? 15 : 18),
                            '$invoiceType Number : #[$currentInvoiceNumber]',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Invoice numbers are auto-generated.\n'
                              'The next number is calculated from the last\n'
                              'invoice in the database (including deleted ones).\n'
                              'Manual editing is not supported.',
                          child: const Icon(Icons.info_outline,
                              size: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: !isEditing && _invoice != null
          ? buildInvoiceSuccessScreen()
          : LayoutBuilder(
              builder: (context, constraints) {
                // V2 owns every width now — no falling back to the old
                // Card-heavy tablet/mobile layouts. Above the threshold we
                // use the two-column desktop composition (items table +
                // sticky right panel, each scrolling independently). Below
                // it, the same flat V2 pieces stack into one scrollable
                // column instead.
                const wideBreakpoint = 980.0;
                final isWide = constraints.maxWidth >= wideBreakpoint;

                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(AppPadding.small),
                  child: Column(
                    children: [
                      Expanded(
                        child: isWide
                            ? _buildDesktopLayoutV2(tax, subtotal, total,
                                grossSubtotal, totalDiscount, invoiceDiscountAmount)
                            : SingleChildScrollView(
                                child: _buildStackedLayoutV2(tax, subtotal, total,
                                    grossSubtotal, totalDiscount, invoiceDiscountAmount),
                              ),
                      ),
                      AppSpacing.hSmall,
                      _actionButtonsV2(),
                    ],
                  ),
                );
              },
            ),
    )),
        ),
      ),
    );
  }

  // ============================================================
  // V2 — flat / minimal desktop layout.
  // Reuses all state, controllers and business-logic methods from
  // the original screen. Only presentation (styling + composition)
  // differs: no elevated Cards, hairline borders instead, and the
  // right panel (invoice details + costs/notes/tax/totals) is laid
  // out as its own scrollable column with the totals pinned to the
  // bottom, instead of being folded into the items card.
  // ============================================================

  BoxDecoration _flatCardDecorationV2(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      );

  Widget _flatCardV2({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: _flatCardDecorationV2(context),
      padding: padding ?? const EdgeInsets.all(AppPadding.medium),
      child: child,
    );
  }

  // `invoiceType` itself ('Invoice'/'Quotation'/'Receipt') is an internal
  // English identifier compared elsewhere in this file's logic — this maps
  // it to a translated display label without touching those comparisons.
  String _invoiceTypeLabel(String type) {
    switch (type) {
      case 'Quotation':
        return AppLocalizations.of(context)!.labelQuotation;
      case 'Receipt':
        return AppLocalizations.of(context)!.labelReceipt;
      default:
        return AppLocalizations.of(context)!.labelInvoice;
    }
  }

  InputDecoration _flatFieldDecorationV2(
    String label, {
    String? hint,
    String? helperText,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? prefixText,
    String? suffixText,
  }) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      labelStyle: TextStyle(fontSize: AppFontSize.small),
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 1.4),
      ),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      suffixText: suffixText
    );
  }

  Widget _sectionLabelV2(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _customerDetailsFormV2() {
    return _flatCardV2(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              const Text(
                'CUSTOMER DETAILS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (selectedCustomer == null || !_customerFormMatchesSelected)
                      TextButton.icon(
                        onPressed: _isSavingCustomer ? null : _saveCustomer,
                        icon: _isSavingCustomer
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.person_add_alt_outlined, size: 16),
                        label: Text(
                            _isSavingCustomer ? AppLocalizations.of(context)!.createInvoiceSavingEllipsisLabel : AppLocalizations.of(context)!.createInvoiceSaveCustomerLabel),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _showCustomerPickerDialogV2,
                      icon: const Icon(Icons.person_search_outlined, size: 16),
                      label: Text(AppLocalizations.of(context)!.createInvoiceSelectExistingCustomerButton),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xsmall)),
                      ),
                    ),
                    if (selectedCustomer != null &&
                        selectedCustomer!.id.trim().isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: AppLocalizations.of(context)!.createInvoiceRefreshCustomerTooltip,
                        visualDensity: VisualDensity.compact,
                        onPressed: _refreshCustomerFromRecord,
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: AppLocalizations.of(context)!.createInvoiceClearCustomerTooltip,
                        visualDensity: VisualDensity.compact,
                        onPressed: _clearCustomerSelection,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _customerDetailsExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: _customerDetailsExpanded
                    ? MaterialLocalizations.of(context).expandedIconTapHint
                    : MaterialLocalizations.of(context).collapsedIconTapHint,
                onPressed: () {
                  if (!mounted) return;
                  setState(() =>
                      _customerDetailsExpanded = !_customerDetailsExpanded);
                },
              ),
            ],
          ),
          if (_customerDetailsExpanded) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldCustomerNameRequiredLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: businessNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldBusinessNameLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  onChanged: (_) => setState(() {}),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldPhoneLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_showGstFields) ...[
                Expanded(
                  child: TextField(
                    controller: gstinController,
                    onChanged: (_) => setState(() {}),
                    decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldGstinVatLabel),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: emailController,
                  onChanged: (_) => setState(() {}),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldEmailLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: addressController,
                  onChanged: (_) => setState(() {}),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldAddressLabel,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.open_in_full, size: 18),
                        tooltip: AppLocalizations.of(context)!.tooltipEditInLargerView,
                        onPressed: () => _editLongTextDialogV2(
                          title: AppLocalizations.of(context)!.fieldAddressLabel,
                          controller: addressController,
                        ),
                      )),
                ),
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }

  void _showCustomerPickerDialogV2() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 420,
          height: 520,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.createInvoiceChooseCustomerTitle,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customerSearchController,
                    autofocus: true,
                    onChanged: (query) {
                      _filterCustomers(query, onResults: () {
                        setDialogState(() {});
                      });
                    },
                    decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoiceSearchCustomerLabel,
                        prefixIcon: const Icon(Icons.search, size: 18)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredCustomers.isEmpty
                        ? Center(
                            child: Text(AppLocalizations.of(context)!.createInvoiceNoCustomersFoundMessage,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)))
                        : ListView.builder(
                            controller: _customerScrollController,
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final isSelected =
                                  selectedCustomer?.id == customer.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: Text(
                                    customer.name.isNotEmpty
                                        ? customer.name[0].toUpperCase()
                                        : '?',
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(customer.name),
                                subtitle: Text(customer.businessName.trim().isNotEmpty
                                    ? '${customer.businessName}  •  ${customer.phone}'
                                    : customer.phone),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: () {
                                  _selectCustomer(customer);
                                  Navigator.of(dialogContext).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _invoiceDetailsFormV2() {
    return _flatCardV2(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (!mounted) return;
              setState(() => _invoiceDetailsExpanded = !_invoiceDetailsExpanded);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.createInvoiceDetailsHeading(_invoiceTypeLabel(invoiceType).toUpperCase()),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6),
                  ),
                ),
                Icon(
                  _invoiceDetailsExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_invoiceDetailsExpanded) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: invoiceType,
            decoration: _flatFieldDecorationV2(
              AppLocalizations.of(context)!.createInvoiceTypeFieldLabel,
              helperText:
                  isEditing ? AppLocalizations.of(context)!.createInvoiceTypeLockedHelperText : null,
            ),
            items: [
              DropdownMenuItem(value: 'Invoice', child: Text(AppLocalizations.of(context)!.labelInvoice)),
              DropdownMenuItem(value: 'Quotation', child: Text(AppLocalizations.of(context)!.labelQuotation)),
              DropdownMenuItem(value: 'Receipt', child: Text(AppLocalizations.of(context)!.labelReceipt)),
            ],
            onChanged: isEditing
                ? null
                : (value) {
                    if (value != null) resetInvoiceType(value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dateController,
            readOnly: true,
            decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoiceOrderDateLabel,
                suffixIcon: const Icon(Icons.calendar_today, size: 16)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedOrderDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                if (!mounted) return;
                setState(() {
                  _selectedOrderDate = picked;
                  dateController.text =
                      DateFormat(_datePattern).format(picked);
                });
                await _loadPreviousBalanceDue(selectedCustomer);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dueDateController,
            readOnly: true,
            decoration: _flatFieldDecorationV2(
              AppLocalizations.of(context)!.createInvoiceDueDateLabel,
              suffixIcon: dueDateController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        if (!mounted) return;
                        setState(() {
                          _selectedDueDate = null;
                          dueDateController.clear();
                        });
                      },
                    )
                  : const Icon(Icons.calendar_today, size: 16),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDueDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                if (!mounted) return;
                setState(() {
                  _selectedDueDate = picked;
                  dueDateController.text =
                      DateFormat(_datePattern).format(picked);
                });
              }
            },
          ),
          if (invoiceType == 'Invoice') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              value: invoiceTitle,
              decoration: _flatFieldDecorationV2(
                  _showGstFields ? AppLocalizations.of(context)!.createInvoiceGstTitleLabel : AppLocalizations.of(context)!.createInvoiceTaxTitleLabel),
              items: [
                DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.labelInvoice)),
                DropdownMenuItem(
                    value: 'Tax Invoice', child: Text(AppLocalizations.of(context)!.gstTitleTaxInvoiceLabel)),
                DropdownMenuItem(
                    value: 'Bill of Supply', child: Text(AppLocalizations.of(context)!.gstTitleBillOfSupplyLabel)),
                DropdownMenuItem(
                    value: 'Invoice-cum-Bill of Supply',
                    child: Text(AppLocalizations.of(context)!.gstTitleInvoiceCumBillLabel)),
                DropdownMenuItem(
                    value: 'Cash Bill', child: Text(AppLocalizations.of(context)!.gstTitleCashBillLabel)),
                DropdownMenuItem(
                    value: 'Credit Note', child: Text(AppLocalizations.of(context)!.gstTitleCreditNoteLabel)),
                DropdownMenuItem(
                    value: 'Debit Note', child: Text(AppLocalizations.of(context)!.gstTitleDebitNoteLabel)),
                DropdownMenuItem(
                    value: 'Revised Invoice', child: Text(AppLocalizations.of(context)!.gstTitleRevisedInvoiceLabel)),
              ],
              onChanged: (value) => setState(() => invoiceTitle = value),
            ),
          ],
          const SizedBox(height: 12),
          _pdfNumberOverrideFieldV2(),
          ],
        ],
      ),
    );
  }

  Widget _productQuickAddBarV2() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          // The ancestor Focus intercepts arrow-key / escape events before
          // they reach the TextField, so you can move through the dropdown
          // results with the keyboard instead of only being able to click.
          child: Focus(
            onKeyEvent: (node, event) {
              if (!_showProductDropdownV2 || filteredProducts.isEmpty) {
                return KeyEventResult.ignored;
              }
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  setState(() {
                    _highlightedProductIndexV2 =
                        (_highlightedProductIndexV2 + 1)
                            .clamp(0, filteredProducts.length - 1);
                  });
                  _ensureHighlightedProductVisibleV2();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  setState(() {
                    _highlightedProductIndexV2 =
                        (_highlightedProductIndexV2 - 1)
                            .clamp(0, filteredProducts.length - 1);
                  });
                  _ensureHighlightedProductVisibleV2();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  setState(() => _showProductDropdownV2 = false);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: searchController,
              focusNode: _productSearchFocusNodeV2,
              onChanged: (value) {
                _filterProducts(value);
                setState(() {
                  _showProductDropdownV2 = value.trim().isNotEmpty;
                  _highlightedProductIndexV2 = 0;
                });
              },
              onSubmitted: (_) {
                if (_showProductDropdownV2 && filteredProducts.isNotEmpty) {
                  final index = _highlightedProductIndexV2.clamp(
                      0, filteredProducts.length - 1);
                  _selectProductFromDropdownV2(filteredProducts[index]);
                }
              },
              decoration: _flatFieldDecorationV2(
                AppLocalizations.of(context)!.createInvoiceSearchProductLabel,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          searchController.clear();
                          setState(() => _showProductDropdownV2 = false);
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _addAdHocItemDialog,
          icon: const Icon(Icons.add, size: 16),
          label: Text(AppLocalizations.of(context)!.createInvoiceCustomItemButton),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
          ),
        ),
      ],
    );
  }

  void _ensureHighlightedProductVisibleV2() {
    if (!_productDropdownScrollControllerV2.hasClients) return;
    const itemExtent = 58.0;
    final targetTop = _highlightedProductIndexV2 * itemExtent;
    final targetBottom = targetTop + itemExtent;
    final viewport = _productDropdownScrollControllerV2.position.viewportDimension;
    final current = _productDropdownScrollControllerV2.offset;
    if (targetTop < current) {
      _productDropdownScrollControllerV2.jumpTo(targetTop);
    } else if (targetBottom > current + viewport) {
      _productDropdownScrollControllerV2.jumpTo(targetBottom - viewport);
    }
  }

  void _selectProductFromDropdownV2(Product product) {
    addInvoiceProductPrompt(product);
    searchController.clear();
    _productSearchFocusNodeV2.unfocus();
    if (!mounted) return;
    setState(() => _showProductDropdownV2 = false);
  }

  Widget _productDropdownListV2() {
    const itemExtent = 58.0;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: filteredProducts.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(AppLocalizations.of(context)!.createInvoiceNoProductsFoundMessage,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )
            : ListView.builder(
                controller: _productDropdownScrollControllerV2,
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemExtent: itemExtent,
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final outOfStock = product.stock <= 0;
                  final isHighlighted = index == _highlightedProductIndexV2;
                  final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

                  // Same metadata source as the Ctrl+F product picker
                  // dialog — pre-loaded in _productMetadata, keyed by
                  // product id, no extra async fetch needed here.
                  final meta =
                      _columnsConfig.productMetadata ? _productMetadata[product.id] : null;
                  final expiryDate = (_columnsConfig.metaExpiryDate &&
                          (meta?.expiryDate?.isNotEmpty ?? false))
                      ? DateTime.tryParse(meta!.expiryDate!)
                      : null;
                  final isExpired =
                      expiryDate != null && expiryDate.isBefore(DateTime.now());
                  final storageLocation =
                      _columnsConfig.metaStorageLocation ? meta?.storageLocation : null;
                  final hasStorage = storageLocation != null && storageLocation.isNotEmpty;

                  return Container(
                    color: isHighlighted
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      dense: true,
                      selected: isHighlighted,
                      title: Text(
                        product.name,
                        overflow: TextOverflow.ellipsis,
                        style: outOfStock
                            ? TextStyle(color: Theme.of(context).colorScheme.error)
                            : null,
                      ),
                      // Everything — price, stock, HSN, storage location,
                      // expiry — on one line. Location and expiry are
                      // bolded/colored to stand out from the plain price/
                      // stock/HSN text; an expired date turns red.
                      subtitle: Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 11, color: mutedColor),
                          children: [
                            TextSpan(
                                text:
                                    '$_currencySymbol${product.price.toStringAsFixed(2)}  ·  Stock: ${product.stock}'
                                    '${product.hsncode.trim().isEmpty ? '' : '  ·  HSN ${product.hsncode}'}'),
                            if (hasStorage) ...[
                              const TextSpan(text: '  ·  '),
                              TextSpan(
                                text: '📍 $storageLocation',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            ],
                            if (expiryDate != null) ...[
                              const TextSpan(text: '  ·  '),
                              TextSpan(
                                text:
                                    '${isExpired ? 'Expired ' : 'Exp '}${DateFormat(_datePattern).format(expiryDate)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExpired ? Colors.red : Colors.orange[800],
                                ),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectProductFromDropdownV2(product),
                    ),
                  );
                },
              ),
      ),
    );
  }
  Future<void> _saveAdHocItemV2(InvoiceItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final existing = await ref
        .read(productRepositoryProvider)
        .findDuplicateByName(item.product.name);
    if (!mounted) return;
    if (existing != null) {
      setState(() => _savedAdHocIds.add(item.product.id));
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.createInvoiceItemAlreadyInProductListMessage(item.product.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final newProduct = Product(
      id: const Uuid().v4(),
      name: item.product.name,
      description: item.effectiveDescription,
      price: item.effectivePrice,
      stock: 0,
      hsncode: item.product.hsncode,
      tax_rate: item.product.tax_rate,
      unit: item.product.unit,
      type: item.product.type,
      aliasName: item.product.aliasName,
      priceIncludesTax: item.product.priceIncludesTax,
    );
    await ref.read(productRepositoryProvider).insertProduct(newProduct);
    item.isProductSaved = true;
    if (isEditing && _invoice != null) {
      await ref
          .read(invoiceItemRepositoryProvider)
          .markProductSaved(_invoice!.id, item.product.id);
    }
    // Was: `await productRepository.getAllProducts()` here — re-fetching
    // every product in the database just to refresh this screen's local
    // list after adding ONE new product. Everywhere else on this screen
    // (initial load, search-as-you-type) is properly paginated (limit
    // _productFetchLimit); this call alone bypassed that and would pull
    // the entire products table into memory on every "Save to product
    // list" tap — fine with a handful of products, but a real slowdown
    // (and needless memory/DB load) once the catalog grows large.
    // We already have the full `newProduct` object from the insert above,
    // so there's nothing to re-fetch — just prepend it locally.
    if (!mounted) return;
    setState(() {
      _savedAdHocIds.add(item.product.id);
      products = [newProduct, ...products];
      filteredProducts = [newProduct, ...filteredProducts];
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.createInvoiceProductSavedMessage(newProduct.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInvoiceItemRowV2(int index) {
    final item = invoiceItems[index];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _showAliasNameInPdf &&
                                (item.product.aliasName
                                        ?.trim()
                                        .isNotEmpty ??
                                    false)
                            ? '${item.product.name} (${item.product.aliasName})'
                            : item.product.name,
                        style: const TextStyle(
                            fontSize: AppFontSize.medium,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_columnsConfig.type &&
                        _businessType == BusinessType.both) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.product.type == 'service'
                              ? 'Service'
                              : 'Product',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_columnsConfig.description &&
                    item.effectiveDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 8),
                    child: Text(
                      item.effectiveDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (item.unitPrice != null)
                        _buildItemDetail('Price',
                            '$_currencySymbol${item.effectivePrice.toStringAsFixed(2)} *',
                            color: Colors.orange[700])
                      else
                        _buildItemDetail('Price',
                            '$_currencySymbol${item.product.price.toStringAsFixed(2)}'),
                      if (_taxMode == TaxMode.perItem)
                        _buildItemDetail(
                            'Tax', '${item.product.tax_rate}%'),
                      if (item.product.priceIncludesTax) ...[
                        _buildItemDetail(
                            _taxMode == TaxMode.perItem ? '' : 'Tax',
                            'Inclusive',
                            color: Colors.teal[700]),
                        _buildItemDetail('Net Price',
                            '$_currencySymbol${InvoiceTotalsCalculator.netPrice(price: item.effectivePrice, taxRatePercent: item.product.tax_rate.toDouble(), priceIncludesTax: true).toStringAsFixed(2)}',
                            color: Colors.teal[700]),
                      ],
                      if (_columnsConfig.hsncode)
                        _buildItemDetail(
                            'HSN/SAC', item.product.hsncode.toString()),
                      if (_showQuantity)
                        _buildItemDetail(
                            _quantityLabel.trim().isNotEmpty
                                ? _quantityLabel.trim()
                                : 'Qty',
                            '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt().toString() : item.quantity.toString()}'
                            '${item.effectiveUnit.trim().isEmpty ? '' : ' ${item.effectiveUnit}'}'),
                      if (_columnsConfig.defaultDiscount || item.discount > 0)
                        _buildItemDetail('Discount',
                            '$_currencySymbol${item.discount.toStringAsFixed(2)}${item.discountPerUnit ? ' ×qty' : ''}'),
                      if (item.discountPerUnit && item.discount > 0)
                        _buildItemDetail('Net',
                            '$_currencySymbol${(item.effectivePrice - item.discount).toStringAsFixed(2)}/item',
                            color: Colors.teal[700]),
                      if (item.extraCost != null && item.extraCost! > 0)
                        _buildItemDetail('Extra',
                            '+$_currencySymbol${item.extraCost!.toStringAsFixed(2)}',
                            color: Colors.teal[700]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$_currencySymbol${item.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (item.product.id.startsWith('custom-') &&
              !_savedAdHocIds.contains(item.product.id)) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              tooltip: AppLocalizations.of(context)!.createInvoiceSaveToProductListTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: () => _saveAdHocItemV2(item),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: AppLocalizations.of(context)!.tooltipEditItem,
            visualDensity: VisualDensity.compact,
            onPressed: () => _editInvoiceItem(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: AppLocalizations.of(context)!.tooltipRemoveItem,
            visualDensity: VisualDensity.compact,
            color: Theme.of(context).colorScheme.error,
            onPressed: () {
              if (!mounted) return;
              setState(() => invoiceItems.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _itemsEmptyStateV2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined,
            size: 48, color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.createInvoiceNoItemsAddedMessage,
            style:
                TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(AppLocalizations.of(context)!.createInvoiceSearchHintMessage,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  // [expand]=true (desktop/wide): the list fills remaining card height and
  // scrolls independently — needs a bounded parent (used inside Expanded).
  // [expand]=false (stacked/narrow): the list sizes to its content and
  // scrolls along with the rest of the page instead.
  Widget _itemsTableSectionV2({bool expand = true}) {
    return _flatCardV2(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'ITEMS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(AppLocalizations.of(context)!.dashboardItemCountLabel(invoiceItems.length),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (expand)
                Expanded(
                  child: invoiceItems.isEmpty
                      ? Center(child: _itemsEmptyStateV2())
                      : Scrollbar(
                          controller: _invoiceItemsScrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _invoiceItemsScrollController,
                            itemCount: invoiceItems.length,
                            itemBuilder: (context, index) =>
                                _buildInvoiceItemRowV2(index),
                          ),
                        ),
                )
              else
                invoiceItems.isEmpty
                    ? SizedBox(
                        height: 160, child: Center(child: _itemsEmptyStateV2()))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: invoiceItems.length,
                        itemBuilder: (context, index) =>
                            _buildInvoiceItemRowV2(index),
                      ),
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                      width: 1.4),
                ),
                child: _productQuickAddBarV2(),
              ),
            ],
          ),
          // Inline search dropdown floats above the items list, anchored
          // just above the search bar at the bottom of the card. The
          // Ctrl+F modal (_showProductPickerDialog) stays available as a
          // separate, keyboard-only shortcut and is no longer opened by
          // clicking or typing into this field.
          if (_showProductDropdownV2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 68,
              child: _productDropdownListV2(),
            ),
        ],
      ),
    );
  }

  // V2: narrow-friendly rebuild of _buildInvoiceDiscountSection(). The
  // original packs icon + label + field + dropdown into a single fixed-
  // width Row, which fits the old ~900px-wide items card but overflows
  // the new 360px right panel. Same state (_invoiceDiscountController,
  // _invoiceDiscountType), just laid out in two rows with the field
  // wrapped in Expanded so it can actually shrink.
  Widget _invoiceDiscountSectionV2() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceDiscountController,
                  onChanged: (_) {
                    if (!mounted) return;
                    setState(() {});
                  },
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoiceDiscountFieldLabel,
                      hint: '',
                      prefixText: _invoiceDiscountType == InvoiceDiscountType.amount
                        ? '$_currencySymbol '
                        : null,
                      suffixText: _invoiceDiscountType == InvoiceDiscountType.percent
                          ? '%'
                          : null,),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InvoiceDiscountType>(
                    value: _invoiceDiscountType,
                    isDense: true,
                    selectedItemBuilder: (context) => [
                      const Center(child: Text('%')),
                      Center(child: Text(AppLocalizations.of(context)!.discountTypeAmountShortLabel)),
                    ],
                    items: [
                      const DropdownMenuItem(
                          value: InvoiceDiscountType.percent, child: Text('%')),
                      DropdownMenuItem(
                          value: InvoiceDiscountType.amount, child: Text(AppLocalizations.of(context)!.labelAmount)),
                    ],
                    onChanged: (v) {
                      if (v == null || !mounted) return;
                      setState(() => _invoiceDiscountType = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notesFieldV2() {
    return TextField(
      controller: notesController,
      maxLength: DefaultValues.additionalNotesLength,
      maxLines: 3,
      decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoiceNotesOptionalLabel,
          hint: AppLocalizations.of(context)!.createInvoiceNotesHint,
          suffixIcon: IconButton(
            icon: const Icon(Icons.open_in_full, size: 18),
            tooltip: AppLocalizations.of(context)!.tooltipEditInLargerView,
            onPressed: _editNotesDialogV2,
          )),
    );
  }

  static const double _notesDialogMinWidth = 320;
  static const double _notesDialogMaxWidth = 800;
  static const double _notesDialogMinHeight = 200;
  static const double _notesDialogMaxHeight = 600;

  Future<void> _editNotesDialogV2() async {
    final controller = TextEditingController(text: notesController.text);
    double dialogWidth = 480;
    double dialogHeight = 320;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.createInvoiceNotesTitle),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TextField(
                    controller: controller,
                    maxLength: DefaultValues.additionalNotesLength,
                    expands: true,
                    maxLines: null,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.createInvoiceNotesHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        setDialogState(() {
                          dialogWidth = (dialogWidth + details.delta.dx)
                              .clamp(_notesDialogMinWidth, _notesDialogMaxWidth);
                          dialogHeight = (dialogHeight + details.delta.dy)
                              .clamp(_notesDialogMinHeight, _notesDialogMaxHeight);
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.south_east, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      notesController.text = result;
    }
  }

  // Generalized version of _editNotesDialogV2 above, for other single-line
  // fields (e.g. customer address) that also want the resizable large-editor
  // "expand" affordance. maxLength is optional since not every field this
  // is used on restricts length.
  Future<void> _editLongTextDialogV2({
    required String title,
    required TextEditingController controller,
    int? maxLength,
  }) async {
    final dialogController = TextEditingController(text: controller.text);
    double dialogWidth = 480;
    double dialogHeight = 320;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TextField(
                    controller: dialogController,
                    maxLength: maxLength,
                    expands: true,
                    maxLines: null,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        setDialogState(() {
                          dialogWidth = (dialogWidth + details.delta.dx)
                              .clamp(_notesDialogMinWidth, _notesDialogMaxWidth);
                          dialogHeight = (dialogHeight + details.delta.dy)
                              .clamp(_notesDialogMinHeight, _notesDialogMaxHeight);
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.south_east, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, dialogController.text),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => controller.text = result);
    }
  }

  Widget _pdfNumberOverrideFieldV2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(AppLocalizations.of(context)!.createInvoiceHideNumberInPdfLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _hideInvoiceNumber,
                onChanged: (value) {
                  if (!mounted) return;
                  setState(() => _hideInvoiceNumber = value);
                },
              ),
            ),
          ],
        ),
        if (_hideInvoiceNumber) ...[
          const SizedBox(height: 10),
          TextField(
            controller: customInvoiceNumberController,
            decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoiceCustomNumberLabel,
                hint: AppLocalizations.of(context)!.createInvoiceCustomNumberHint),
          ),
        ],
      ],
    );
  }

  Widget _taxSettingsSectionV2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(AppLocalizations.of(context)!.createInvoiceEnableTaxLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _isTaxEnabled,
                onChanged: (value) {
                  if (!mounted) return;
                  setState(() => _isTaxEnabled = value);
                },
              ),
            ),
          ],
        ),
        if (_isTaxEnabled) ...[
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.percent, size: 15),
                  tooltip: AppLocalizations.of(context)!.createInvoiceGlobalRateTooltip),
              ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.list_alt, size: 15),
                  tooltip: AppLocalizations.of(context)!.createInvoicePerItemRateTooltip),
            ],
            selected: {_isPerItem},
            onSelectionChanged: (selection) {
              if (!mounted) return;
              setState(() => _isPerItem = selection.first);
            },
          ),
          const SizedBox(height: 10),
          if (!_isPerItem)
            TextField(
              controller: taxRateController,
              decoration:
                  _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoiceDefaultTaxRateLabel).copyWith(suffixText: '%'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (!mounted) return;
                setState(() {
                  taxRate =
                      (double.tryParse(value) ?? (taxRate * 100)) / 100;
                });
              },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(AppLocalizations.of(context)!.createInvoiceTaxRateFromProductMessage,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          if (_showGstFields) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(AppLocalizations.of(context)!.createInvoiceInterStateLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isInterState,
                    onChanged: (value) {
                      if (!mounted) return;
                      setState(() => _isInterState = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
        if (_upiEntries.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<UpiEntry?>(
            isExpanded: true,
            value: _selectedUpi,
            decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoicePaymentUpiAccountLabel),
            items: [
              DropdownMenuItem<UpiEntry?>(
                  value: null, child: Text(AppLocalizations.of(context)!.commonNoneLabel)),
              ..._upiEntries.map((e) => DropdownMenuItem<UpiEntry?>(
                    value: e,
                    child:
                        Text(e.displayLabel, style: const TextStyle(fontSize: 12)),
                  )),
            ],
            onChanged: (val) {
              if (!mounted) return;
              setState(() => _selectedUpi = val);
            },
          ),
        ],
        if (_bankAccounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<BankAccount?>(
            isExpanded: true,
            value: _selectedBankAccount,
            decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.createInvoiceBankAccountLabel),
            items: [
              DropdownMenuItem<BankAccount?>(
                  value: null, child: Text(AppLocalizations.of(context)!.commonNoneLabel)),
              ..._bankAccounts.map((e) => DropdownMenuItem<BankAccount?>(
                    value: e,
                    child:
                        Text(e.displayLabel, style: const TextStyle(fontSize: 12)),
                  )),
            ],
            onChanged: (val) {
              if (!mounted) return;
              setState(() => _selectedBankAccount = val);
            },
          ),
        ],
      ],
    );
  }

  Widget _totalsFooterV2(double tax, double subtotal, double total,
      double grossSubtotal, double totalDiscount, double invoiceDiscountAmount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTotalRow(
              AppLocalizations.of(context)!.fieldSubtotalLabel, totalDiscount > 0 ? grossSubtotal : subtotal, false),
          if (totalDiscount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.createInvoiceDiscountColonLabel,
                    style: TextStyle(fontSize: 14, color: Colors.orange[700])),
                Text('-$_currencySymbol${totalDiscount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700])),
              ],
            ),
          ],
          const SizedBox(height: 6),
          _buildTotalRow(AppLocalizations.of(context)!.fieldTaxLabel, tax, false),
          ..._buildAdditionalCosts().map((c) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildTotalRow(
                    c.label.isEmpty ? AppLocalizations.of(context)!.createInvoiceExtraCostFallbackLabel : c.label, c.amount, false),
              )),
          if (invoiceDiscountAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                      _invoiceDiscountType == InvoiceDiscountType.percent
                          ? AppLocalizations.of(context)!.createInvoiceDiscountPercentLabel(_invoiceDiscountValue.toStringAsFixed(1))
                          : AppLocalizations.of(context)!.createInvoiceInvoiceDiscountColonLabel,
                      style:
                          TextStyle(fontSize: 14, color: Colors.orange[700])),
                ),
                Flexible(
                  child: Text(
                      '-$_currencySymbol${invoiceDiscountAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700])),
                ),
              ],
            ),
          ],
          if (_showPreviousBalance && selectedCustomer != null) ...[
            const SizedBox(height: 8),
            _buildPreviousBalanceDueRow(),
          ],
          const SizedBox(height: 14),
          _buildTotalRow(AppLocalizations.of(context)!.fieldTotalLabel, total, true),
          if (_showPreviousBalance &&
              selectedCustomer != null &&
              !_isPreviousBalanceLoading &&
              _previousBalanceDue > 0) ...[
            const SizedBox(height: 8),
            _buildTotalDueRow(total + _previousBalanceDue),
          ],
          if (isEditing &&
              _invoice != null &&
              _invoice!.type == 'Invoice' &&
              _invoice!.payments.isNotEmpty)
            _buildPaymentSummaryPanel(_invoice!),
        ],
      ),
    );
  }

  Widget _rightPanelV2(double tax, double subtotal, double total,
      double grossSubtotal, double totalDiscount, double invoiceDiscountAmount) {
    return Column(
      children: [
        _invoiceDetailsFormV2(),
        AppSpacing.hSmall,
        Expanded(
          child: Container(
            decoration: _flatCardDecorationV2(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppPadding.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAdditionalCostsSection(),
                        const SizedBox(height: 12),
                        _invoiceDiscountSectionV2(),
                        const SizedBox(height: 18),
                        _sectionLabelV2('Notes'),
                        _notesFieldV2(),
                        const SizedBox(height: 18),
                        _sectionLabelV2('Tax settings'),
                        _taxSettingsSectionV2(),
                      ],
                    ),
                  ),
                ),
                _totalsFooterV2(tax, subtotal, total, grossSubtotal,
                    totalDiscount, invoiceDiscountAmount),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButtonsV2() {
    final isEditMode = widget.invoiceToEdit != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Previously: SizedBox(60) + Expanded(Wrap(...)) + SizedBox(12) +
          // a fixed-size Save/Update button (with a "(Ctrl+S)" hint baked
          // into its label) + SizedBox(60). Only the Wrap could shrink —
          // the two 60px bookends and the button's own intrinsic width set
          // a hard minimum for the row, so a narrow window could come up
          // just short (as little as a few pixels) and overflow. The
          // bookends now shrink away on narrow windows, the button's
          // "(Ctrl+S)" hint drops (it's still in the tooltip), and the
          // button itself is wrapped in Flexible with ellipsis as a
          // last-resort safety net.
          final compact = constraints.maxWidth < 560;
          final bookend = compact ? 0.0 : 60.0;
          return Row(
            children: [
              SizedBox(width: bookend),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildActionButton(
                      icon: Icons.visibility_outlined,
                      label: AppLocalizations.of(context)!.actionView,
                      color: Colors.green,
                      onPressed: _invoice != null
                          ? () => InvoicePdfServices.showInvoiceDetails(
                              context, _invoice!)
                          : null,
                    ),
                    _buildActionButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: AppLocalizations.of(context)!.createInvoicePreviewLabel,
                      tooltip: AppLocalizations.of(context)!.createInvoicePreviewTooltip,
                      color: Colors.purple,
                      onPressed: _invoice != null
                          ? () => InvoicePdfServices.previewPDF(context, _invoice!)
                          : null,
                    ),
                    _buildActionButton(
                      icon: Icons.download_outlined,
                      label: AppLocalizations.of(context)!.createInvoiceDownloadLabel,
                      color: Colors.deepPurple,
                      onPressed: _invoice != null
                          ? () => PDFService.downloadPDF(context, _invoice!)
                          : null,
                    ),
                    _buildActionButton(
                      icon: Icons.print_outlined,
                      label: AppLocalizations.of(context)!.actionPrint,
                      tooltip: AppLocalizations.of(context)!.createInvoicePrintTooltip,
                      color: Colors.blue,
                      onPressed: _invoice != null
                          ? () => InvoicePdfServices.generatePDF(context, _invoice!)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Tooltip(
                  message: 'Shortcut: Ctrl+s',
                  child: ElevatedButton.icon(
                    onPressed: invoiceItems.isNotEmpty && !isLoading
                        ? (isEditMode ? _updateInvoice : _createInvoice)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(isEditMode ? Icons.update : Icons.save_outlined),
                    label: Text(
                      isLoading
                          ? 'Processing...'
                          : (isEditMode
                              ? (compact ? 'Update $invoiceType' : 'Update $invoiceType (Ctrl+S)')
                              : (compact ? 'Create $invoiceType' : 'Create $invoiceType (Ctrl+S)')),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(width: bookend),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayoutV2(double tax, double subtotal, double total,
      double grossSubtotal, double totalDiscount, double invoiceDiscountAmount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              if (_customFieldsEnabled && _customFieldDefs.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _customerDetailsFormV2()),
                    AppSpacing.wSmall,
                    Expanded(flex: 1, child: _customFieldsSummaryCardV2()),
                  ],
                )
              else
                _customerDetailsFormV2(),
              AppSpacing.hSmall,
              Expanded(child: _itemsTableSectionV2()),
            ],
          ),
        ),
        AppSpacing.wSmall,
        SizedBox(
          width: Platform.isAndroid ? 300 : 360,
          child: _rightPanelV2(tax, subtotal, total, grossSubtotal,
              totalDiscount, invoiceDiscountAmount),
        ),
      ],
    );
  }

  // Narrow-width companion to _buildDesktopLayoutV2: the same flat V2
  // pieces (no reused v1 Card widgets), stacked into a single column that
  // scrolls as one page instead of splitting into two independently
  // scrolling panes. Used below the wide-layout breakpoint, including on
  // resize, so the screen never falls back to the old layout.
  Widget _buildStackedLayoutV2(double tax, double subtotal, double total,
      double grossSubtotal, double totalDiscount, double invoiceDiscountAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _customerDetailsFormV2(),
        if (_customFieldsEnabled && _customFieldDefs.isNotEmpty) ...[
          AppSpacing.hSmall,
          _customFieldsSummaryCardV2(),
        ],
        AppSpacing.hSmall,
        _invoiceDetailsFormV2(),
        AppSpacing.hSmall,
        _itemsTableSectionV2(expand: false),
        AppSpacing.hSmall,
        _flatCardV2(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdditionalCostsSection(),
              const SizedBox(height: 12),
              _invoiceDiscountSectionV2(),
              const SizedBox(height: 18),
              _sectionLabelV2('Notes'),
              _notesFieldV2(),
              const SizedBox(height: 18),
              _sectionLabelV2('Tax settings'),
              _taxSettingsSectionV2(),
            ],
          ),
        ),
        AppSpacing.hSmall,
        Container(
          decoration: _flatCardDecorationV2(context),
          clipBehavior: Clip.antiAlias,
          child: _totalsFooterV2(tax, subtotal, total, grossSubtotal,
              totalDiscount, invoiceDiscountAmount),
        ),
      ],
    );
  }
}

/// Unit dropdown + "Custom…" text field. Whether the custom field is shown
/// is tracked as sticky local state (set the moment "Custom…" is picked) —
/// NOT re-derived from the current unit string each rebuild, since that
/// string is still empty right after picking "Custom…" and would otherwise
/// make the field disappear before the user can type anything into it.
class _UnitPicker extends StatefulWidget {
  final String initialUnit;
  final TextEditingController customController;
  final ValueChanged<String> onUnitChanged;

  const _UnitPicker({
    required this.initialUnit,
    required this.customController,
    required this.onUnitChanged,
  });

  @override
  State<_UnitPicker> createState() => _UnitPickerState();
}

class _UnitPickerState extends State<_UnitPicker> {
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
            labelText: AppLocalizations.of(context)!.fieldUnitOverrideLabel,
            prefixIcon: const Icon(Icons.straighten),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(AppLocalizations.of(context)!.commonNoneLabel)),
            for (final u in ProductUnits.presets)
              DropdownMenuItem(value: u, child: Text(u.toUpperCase())),
            DropdownMenuItem(value: 'custom', child: Text(AppLocalizations.of(context)!.commonCustomEllipsisLabel)),
          ],
          onChanged: (val) {
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
          TextField(
            controller: widget.customController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.fieldCustomUnitLabel,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: widget.onUnitChanged,
          ),
        ],
      ],
    );
  }
}
