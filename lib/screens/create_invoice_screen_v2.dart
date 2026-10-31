import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/domain/invoice_calculator.dart';
import 'package:invoiso/domain/invoice_totals_calculator.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:uuid/uuid.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_list_filter.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/models/invoice_item.dart';
import 'package:invoiso/models/product.dart';
import 'package:invoiso/models/refund.dart';
import 'package:invoiso/models/additional_cost.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer_field_settings.dart';
import 'package:invoiso/widgets/customer_extra_fields.dart';
import 'package:invoiso/services/invoice_pdf_services.dart';
import 'package:invoiso/services/pdf_service.dart';
import 'package:invoiso/widgets/apply_payment_dialog.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/widgets/return_l10n.dart';
import 'package:invoiso/widgets/product_form.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/services/refund_receipt_service.dart';

/// Stamped on a credit note that puts at least one line back into stock.
const salesReturnTitle = 'Credit Note (Sales Return)';

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

  /// Document type to preselect for a brand-new form ('Invoice' | 'Quotation'
  /// | 'Receipt'). Ignored when editing or cloning.
  final String? initialType;

  /// Set when this form is a quotation→invoice conversion: the id of the source
  /// quotation. On save the quotation is stamped 'converted' and linked, and
  /// the new invoice records it as its source. Implies cloneFrom is that
  /// quotation and cloneType == 'Invoice'.
  final String? convertFromQuotationId;

  /// Called when the user taps "New Invoice" while in edit mode.
  /// The parent (DashboardScreen) resets invoiceToEdit to null.
  final VoidCallback? onCreateNewInvoice;
  final InvoiceFormGuard? guard;

  /// Logged-in user — admin-only rules of the "New product" form. Null →
  /// non-admin rules.
  final User? user;

  const CreateInvoiceScreenV2({
    super.key,
    this.invoiceToEdit,
    this.cloneFrom,
    this.cloneType,
    this.initialType,
    this.convertFromQuotationId,
    this.onCreateNewInvoice,
    this.guard,
    this.user,
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

  // Freeze a detached copy of the product's current metadata onto a new line so
  // it can print on the PDF and never shift if the catalogue product is edited.
  ProductMetadata? _snapshotMetadata(String productId) {
    final m = _productMetadata[productId];
    return (m == null || m.isEmpty) ? null : m.copy();
  }

  Timer? _productSearchDebounce;
  int _productSearchRequestId = 0;
  static const int _productFetchLimit = 30;
  Timer? _customerSearchDebounce;
  int _customerSearchRequestId = 0;
  static const int _customerFetchLimit = 30;

  /// Puts [c] into the local customer list (replaced by id, else prepended)
  /// instead of re-fetching every customer after one add/edit — the list is
  /// only ever the first [_customerFetchLimit] anyway (Issues.md #43).
  void _upsertLocalCustomer(Customer c) {
    customers = customers.any((x) => x.id == c.id)
        ? [for (final x in customers) x.id == c.id ? c : x]
        : [c, ...customers];
    filteredCustomers = List.from(customers);
  }
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
  // Payment taken while creating an invoice. Unpaid (default) records no
  // payment, so saving behaves exactly as before.
  PaymentStatus _payStatus = PaymentStatus.unpaid;
  String _payMethod = 'Cash';
  final _payAmountController = TextEditingController();

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
  final _customerExtraFields = CustomerExtraFieldsController();
  final _customerExtraFormKey = GlobalKey<FormState>();
  final _customerCardScrollController = ScrollController();
  CustomerFieldSettings _customerFieldSettings = const CustomerFieldSettings();
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
  bool _finalizing = false;
  // V2: inline product search dropdown (replaces click-to-open popup;
  // the popup dialog is now reserved for the Ctrl+F shortcut only).
  bool _showProductDropdownV2 = false;
  int _highlightedProductIndexV2 = 0;
  final FocusNode _productSearchFocusNodeV2 = FocusNode();
  final ScrollController _productDropdownScrollControllerV2 = ScrollController();

  String invoiceType = 'Invoice';
  String? invoiceTitle;

  // Standalone Credit / Debit Note fields (only used when _isReturnDoc).
  // Invoice the note is linked to — set from the Invoices row action (locked)
  // or picked from the customer's invoices. Null = standalone note.
  Invoice? _againstInvoice;
  String _returnReason = '';
  CreditSettlement _creditSettlement = CreditSettlement.customerCredit;
  String _refundMethod = 'Cash';
  // Credit note against an invoice: qty already returned per product, for the
  // Left cap. Loaded with the invoice's lines by _prefillCreditNoteFrom.
  Map<String, double> _returnedByProduct = const {};
  // Editing an invoice that has credit notes: customer and everything that
  // moves the total is locked (InvoiceService.updateInvoice enforces it too).
  bool _lockedByCreditNotes = false;
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
  bool _showTimeInPdf = false; // order-time field shown only when PDFs print the time
  String _pdfTimeFormat = '24'; // '12' | '24'
  bool _showAliasNameInPdf = false;
  bool _allowDuplicateInvoiceItems = false;
  double _previousBalanceDue = 0.0;
  bool _isPreviousBalanceLoading = false;
  double _customerCreditAvailable = 0.0;
  bool _applyCustomerCredit = false;
  bool _isSavingCustomer = false;
  bool _customerFieldsUnlocked = false;
  bool get _customerFieldsLocked =>
      selectedCustomer != null && !_customerFieldsUnlocked;
  int _previousBalanceRequestSerial = 0;
  BusinessType _businessType = BusinessType.both;
  String _datePattern = 'dd/MM/yyyy';
  String _adHocItemType = 'product'; // type for custom items added inline
  String? _cleanFormSnapshot;
  int _pendingInitialLoads = 2;
  bool _customFieldsEnabled = false;
  List<CustomFieldDef> _customFieldDefs = [];
  Map<String, String> _customFieldValues = {}; // defId -> value, filled via _showCustomFieldsDialogV2
  bool _customFieldsCollapsed = false;

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
    // Resolve the document type before the first load so the previewed number
    // uses the right series — Invoice and Quotation have separate sequences,
    // and _loadCustomersAndProducts peeks the next number using invoiceType.
    if (widget.invoiceToEdit == null) {
      if (widget.cloneFrom != null) {
        invoiceType = widget.cloneType ?? widget.cloneFrom!.type;
      } else if (widget.initialType != null) {
        invoiceType = widget.initialType!;
      }
    }
    _loadCustomersAndProducts(widget.invoiceToEdit != null);
    _loadColumnsConfig();
    _selectedOrderDate = DateTime.now();
    dateController.text = DateFormat(_datePattern).format(_selectedOrderDate);
    _setAdditionalNote();
    if (widget.invoiceToEdit != null) {
      _invoice = widget.invoiceToEdit;
      isEditing = true;
      if (_invoice!.type == 'Invoice' || _invoice!.type == 'Receipt') {
        ref
            .read(returnRepositoryProvider)
            .getNotesForInvoice(_invoice!.id)
            .then((notes) {
          if (mounted &&
              notes.any((n) => n.type == 'Credit Note' && !n.isDraft)) {
            setState(() => _lockedByCreditNotes = true);
          }
        });
      }
      // A draft credit / debit note reopened: note fields + linked invoice
      // (with what's already returned, for the Left cap).
      if (_invoice!.type == 'Credit Note' || _invoice!.type == 'Debit Note') {
        _returnReason = _invoice!.returnReason ?? '';
        _creditSettlement =
            _invoice!.creditSettlement ?? CreditSettlement.customerCredit;
        final originalId = _invoice!.originalInvoiceId;
        if (originalId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final original = await ref
                .read(invoiceRepositoryProvider)
                .getInvoiceById(originalId);
            final returned = await ref
                .read(returnRepositoryProvider)
                .getReturnedQtyByLine(originalId);
            if (!mounted || original == null) return;
            setState(() {
              _againstInvoice = original;
              _returnedByProduct = returned;
            });
          });
        }
      }
      selectedCustomer = _invoice!.customer;
      invoiceItems = List.from(_invoice!.items);
      nameController.text = _invoice!.customer.name;
      emailController.text = _invoice!.customer.email;
      phoneController.text = _invoice!.customer.phone;
      addressController.text = _invoice!.customer.address;
      gstinController.text = _invoice!.customer.gstin;
      businessNameController.text = _invoice!.customer.businessName;
      _customerExtraFields.load(_invoice!.customer);
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
      // "Create Debit Note" from an invoice row: a new note linked to it —
      // items are the extra charge, not a copy of the invoice.
      final debitNoteFor = widget.cloneType == 'Debit Note' && src.type == 'Invoice';
      if (debitNoteFor) {
        _againstInvoice = src;
      }
      // Credit note from an invoice row: lines / extra costs / discount are
      // filled async from what's still returnable (_prefillCreditNoteFrom).
      final creditNoteFor = widget.cloneType == 'Credit Note' &&
          (src.type == 'Invoice' || src.type == 'Receipt');
      if (creditNoteFor) {
        _pendingInitialLoads++;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _prefillCreditNoteFrom(src);
          _completeInitialLoad();
        });
      }
      invoiceItems = (debitNoteFor || creditNoteFor) ? [] : src.items
          .map((i) => InvoiceItem(
                product: i.product,
                quantity: i.quantity,
                discount: i.discount,
                unitPrice: i.unitPrice,
                extraCost: i.extraCost,
                unit: i.unit,
                description: i.description,
                metadata: i.metadata,
                discountPerUnit: i.discountPerUnit,
                discountIsPercent: i.discountIsPercent,
                isProductSaved: i.isProductSaved,
              ))
          .toList();
      nameController.text = src.customer.name;
      emailController.text = src.customer.email;
      phoneController.text = src.customer.phone;
      addressController.text = src.customer.address;
      gstinController.text = src.customer.gstin;
      businessNameController.text = src.customer.businessName;
      _customerExtraFields.load(src.customer);
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
      for (final c in (debitNoteFor || creditNoteFor)
          ? const <AdditionalCost>[]
          : src.additionalCosts) {
        _additionalCostControllers.add((
          label: TextEditingController(text: c.label),
          amount: TextEditingController(text: c.amount.toStringAsFixed(2)),
        ));
      }
      if (_additionalCostControllers.isNotEmpty) _showAdditionalCosts = true;
      _invoiceDiscountType = src.invoiceDiscountType;
      if (src.invoiceDiscountValue > 0 && !debitNoteFor && !creditNoteFor) {
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
    _customerExtraFields.dispose();
    _customerCardScrollController.dispose();
    for (final row in _additionalCostControllers) {
      row.label.dispose();
      row.amount.dispose();
    }
    _invoiceDiscountController.dispose();
    _payAmountController.dispose();
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
      'customerExtra': _customerExtraFields
          .applyTo(
              Customer(id: '', name: '', email: '', phone: '', address: '', gstin: ''),
              _customerFieldSettings)
          .toMap(),
      'items': invoiceItems.map((item) {
        final product = item.product;
        return {
          'productId': product.id,
          'name': product.name,
          'price': product.price,
          'quantity': item.quantity,
          'discount': item.discount,
          'discountPerUnit': item.discountPerUnit,
          'discountIsPercent': item.discountIsPercent,
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
      'payStatus': _payStatus.name,
      'payMethod': _payMethod,
      'payAmount': _payAmountController.text.trim(),
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
        // A draft has no number yet — preview the next one, like a new invoice.
        isEditing && !(widget.invoiceToEdit?.isDraft ?? false)
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
        settingsRepo.getShowTimeInPdf(), // 21
        settingsRepo.getPdfTimeFormat(), // 22
        CustomerFieldSettings.load(settingsRepo), // 23
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
      final showTimeInPdf = results[21] as bool;
      final pdfTimeFormat = results[22] as String;
      final customerFieldSettings = results[23] as CustomerFieldSettings;

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
        _customerFieldSettings = customerFieldSettings;
        _businessType = businessType;
        _adHocItemType =
            businessType == BusinessType.service ? 'service' : 'product';
        // For new invoices, use the global setting. Edit/clone already set _quantityLabel in initState.
        if (!isEditing && widget.cloneFrom == null) {
          _quantityLabel = quantityLabelSetting;
          invoiceTitle = invoiceType == 'Invoice' ? defaultInvoiceTitle : null;
        }
        _datePattern = dateFormatOpt.key;
        _showTimeInPdf = showTimeInPdf;
        _pdfTimeFormat = pdfTimeFormat;
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

  // [newProduct]: just created in the New product dialog, where its stock
  // was in view — skip the add-time stock prompts (the save check still runs).
  void addInvoiceProductPrompt(Product product, {bool newProduct = false})
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
    bool discountIsPercent = false;
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
      final discount = _clampLineDiscount(
          double.tryParse(discountController.text) ?? 0.0, discountIsPercent);
      final parsedUnitPrice =
      double.tryParse(unitPriceController.text);
      final unitPrice = (parsedUnitPrice != null &&
          parsedUnitPrice != product.price)
          ? parsedUnitPrice
          : null;
      final extraCost = double.tryParse(extraCostController.text);

      // Check stock
      if (!newProduct &&
          !product.unlimitedStock &&
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
                  metadata: _snapshotMetadata(product.id),
                  discountPerUnit: discountPerUnit,
                  discountIsPercent: discountIsPercent),
              insertAt: insertAt);
        }
      } else if (!newProduct && !product.unlimitedStock && product.stock <= 0) {
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
                  metadata: _snapshotMetadata(product.id),
                  discountPerUnit: discountPerUnit,
                  discountIsPercent: discountIsPercent),
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
                metadata: _snapshotMetadata(product.id),
                discountPerUnit: discountPerUnit,
                discountIsPercent: discountIsPercent),
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
                      suffixIcon: _buildDiscountTypeSelector(discountIsPercent,
                          (val) => setDialogState(() => discountIsPercent = val)),
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
                  if (!discountIsPercent) ...[
                    const SizedBox(height: 8),
                    _buildDiscountPerUnitToggle(discountPerUnit,
                        (val) => setDialogState(() => discountPerUnit = val)),
                  ],
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
  /// Address is excluded (edited often, not identity-bearing) and the rest
  /// compare case-insensitively so minor casing/whitespace edits don't
  /// fragment the same customer into a new id.
  bool get _customerFormMatchesSelected {
    final sel = selectedCustomer;
    if (sel == null) return false;
    bool eq(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();
    return eq(sel.name, nameController.text) &&
        eq(sel.email, emailController.text) &&
        eq(sel.phone, phoneController.text) &&
        eq(sel.gstin, gstinController.text) &&
        eq(sel.businessName, businessNameController.text);
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

    return _customerExtraFields.applyTo(Customer(
      id: matchesSelected ? sel!.id : const Uuid().v4(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      gstin: gstin,
      businessName: businessName,
    ), _customerFieldSettings);
  }

  // Reopened draft note saved / finalized before its linked invoice finished
  // loading — load it now so the link and Left cap aren't lost.
  Future<void> _ensureDraftLinkLoaded() async {
    final draftLinkId = _invoice?.isDraft == true && _isReturnDoc
        ? _invoice!.originalInvoiceId
        : null;
    if (draftLinkId != null && _againstInvoice == null) {
      final original =
          await ref.read(invoiceRepositoryProvider).getInvoiceById(draftLinkId);
      final returned = await ref
          .read(returnRepositoryProvider)
          .getReturnedQtyByLine(draftLinkId);
      if (!mounted) return;
      _againstInvoice = original;
      _returnedByProduct = returned;
    }
  }

  Future<bool> _createInvoice() async {
    await _ensureDraftLinkLoaded();
    if (!mounted) return false;
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

    // Ship To address required when not same-as-billing; age range. Null
    // when the customer card is collapsed — render falls back to one block.
    if (!(_customerExtraFormKey.currentState?.validate() ?? true)) return false;

    // Linked credit note: per product, no more than is still returnable.
    if (invoiceType == 'Credit Note' && _againstInvoice != null) {
      final qty = <String, double>{};
      for (final i in invoiceItems) {
        qty[i.product.id] = (qty[i.product.id] ?? 0) + i.quantity;
      }
      for (final i in invoiceItems) {
        final left = math.max(0.0, _creditNoteLeft(i.product.id));
        if (qty[i.product.id]! > left + InvoiceCalculator.moneyEpsilon) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .returnValidationMaxQty(i.product.name, _fmtQty(left))),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ));
          return false;
        }
      }
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

    if (!await _confirmStockForSave()) return false;

    if(!mounted) return false;
    setState(() => isLoading = true);

    try {
      // Finalizing a saved draft note keeps its id; the draft row is swapped
      // for the final note when it's created below.
      final draftNoteId =
          _isReturnDoc && (_invoice?.isDraft ?? false) ? _invoice!.id : null;
      final invoiceId =
          draftNoteId ?? await InvoicePdfServices.generateNextId();
      final invoiceNumber =
          await InvoicePdfServices.generateNextInvoiceNumber(invoiceType);
      final invoice = Invoice(
        id: invoiceId,
        invoiceNumber: invoiceNumber,
        customer: _isReturnDoc && _againstInvoice != null
            ? _againstInvoice!.customer
            : _resolveInvoiceCustomer(),
        items: List.from(invoiceItems),
        date: _selectedOrderDate,
        dueDate: _selectedDueDate,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: _taxMode == TaxMode.global ? taxRate : 0.0,
        type: invoiceType,
        invoiceTitle: invoiceType == 'Invoice'
            ? invoiceTitle
            : invoiceType == 'Credit Note' &&
                    invoiceItems.any((i) => i.restocked && _canRestock(i))
                ? salesReturnTitle
                : null,
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
        originalInvoiceId: _isReturnDoc ? _againstInvoice?.id : null,
        originalInvoiceNumber: _isReturnDoc && _againstInvoice != null
            ? (_againstInvoice!.invoiceNumber ?? _againstInvoice!.id)
            : null,
        originalInvoiceDate: _isReturnDoc ? _againstInvoice?.date : null,
        returnReason:
            _isReturnDoc && _returnReason.trim().isNotEmpty ? _returnReason : null,
        creditSettlement:
            invoiceType == 'Credit Note' ? _creditSettlement : null,
        convertedFromInvoiceId: widget.convertFromQuotationId,
      );

      final payAmount = _paymentChoiceAmount(invoice.total);
      if (payAmount == null) return false;

      SnackBarAction? voucherAction;
      if (invoiceType == 'Credit Note') {
        final returnRepo = ref.read(returnRepositoryProvider);
        await returnRepo.createCreditNote(
              creditNote: invoice,
              originalInvoice: _againstInvoice,
              replaceDraft: draftNoteId != null,
              immediateRefund: _creditSettlement == CreditSettlement.refund
                  ? (
                      amount: invoice.total,
                      method: _refundMethod,
                      date: invoice.date,
                      notes: null,
                    )
                  : null,
            );
        final refunds = _creditSettlement == CreditSettlement.refund
            ? await returnRepo.getRefundsForCreditNote(invoice.id)
            : const <Refund>[];
        if (refunds.isNotEmpty && mounted) {
          final remaining = await returnRepo.getRemainingCustomerCredit(
            customerId: invoice.customer.id,
            customerName: invoice.customer.name,
            currencyCode: invoice.currencyCode,
          );
          if (!mounted) return true;
          voucherAction = SnackBarAction(
            label: AppLocalizations.of(context)!.returnPrintVoucher,
            textColor: Colors.white,
            onPressed: () => RefundReceiptService.preview(
                context, invoice, refunds.last,
                remainingCredit: remaining),
          );
        }
      } else if (invoiceType == 'Debit Note') {
        await ref.read(returnRepositoryProvider).createDebitNote(
            debitNote: invoice, replaceDraft: draftNoteId != null);
      } else {
        await ref.read(invoiceRepositoryProvider).insertInvoice(invoice);
      }

      final (:payError, :creditToApply) =
          await _applyPaymentChoice(invoice, payAmount);

      if (!mounted) return true;
      setState(() {
        _invoice = invoice;
        currentInvoiceNumber = invoice.invoiceNumber ?? invoice.id;
        isLoading = false;
        // A finalized note is never edited — show the success screen.
        if (draftNoteId != null) isEditing = false;
        if (creditToApply > 0) {
          _customerCreditAvailable -= creditToApply;
          _applyCustomerCredit = false;
        }
      });
      _markFormClean();

      final l10n = AppLocalizations.of(context)!;
      final convertedFromId = widget.convertFromQuotationId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(convertedFromId != null
                    ? l10n.createInvoiceConvertedSuccessMessage(
                        invoice.invoiceNumber ?? invoice.id)
                    : l10n.createInvoiceCreatedSuccessMessage(
                        _invoiceTypeLabel(invoiceType))),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          duration: convertedFromId != null
              ? const Duration(seconds: 8)
              : const Duration(seconds: 4),
          action: convertedFromId == null
              ? voucherAction
              : SnackBarAction(
                  label: l10n.createInvoiceTrashQuotationAction,
                  textColor: Colors.white,
                  onPressed: () async {
                    await ref
                        .read(invoiceRepositoryProvider)
                        .softDeleteInvoice(convertedFromId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l10n.createInvoiceQuotationTrashedMessage),
                      behavior: SnackBarBehavior.floating,
                      showCloseIcon: true,
                    ));
                  },
                ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        ),
      );
      if (payError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .createInvoicePaymentNotRecordedMessage(payError)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
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

  /// Payment section: amount to record on save, or null (error shown) when
  /// the partial amount is invalid.
  double? _paymentChoiceAmount(double total) {
    final payAmount = invoiceType != 'Invoice'
        ? 0.0
        : _payStatus == PaymentStatus.paid
            ? total
            : _payStatus == PaymentStatus.partial
                ? (double.tryParse(_payAmountController.text.trim()) ?? 0.0)
                : 0.0;
    if (invoiceType == 'Invoice' &&
        _payStatus == PaymentStatus.partial &&
        (payAmount <= 0 || payAmount > total)) {
      if (!mounted) return null;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payAmount <= 0
              ? AppLocalizations.of(context)!.paymentDialogInvalidAmountError
              : AppLocalizations.of(context)!.paymentDialogExceedsOutstandingError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
      return null;
    }
    return payAmount;
  }

  /// Records the Payment section's choice on a just-saved [invoice].
  /// Separate transactions from the invoice save: if one fails the invoice
  /// is kept and the user adds the payment from the Invoices list.
  Future<({String? payError, double creditToApply})> _applyPaymentChoice(
      Invoice invoice, double payAmount) async {
    String? payError;
    if (payAmount > 0) {
      try {
        invoice.payments = [
          await ref.read(paymentRepositoryProvider).addPayment(
                invoice: invoice,
                amountPaid: payAmount,
                datePaid: DateTime.now(),
                paymentMethod: _payMethod,
              )
        ];
      } catch (e) {
        payError = e.toString();
      }
    }

    // "Apply credit to this invoice" ticked — capped at what's still owed.
    final unpaid = invoice.total - payAmount;
    final creditToApply = _applyCustomerCredit && invoiceType == 'Invoice'
        ? (_customerCreditAvailable < unpaid ? _customerCreditAvailable : unpaid)
        : 0.0;
    if (creditToApply > 0) {
      try {
        await ref.read(returnRepositoryProvider).applyCustomerCreditToInvoice(
            invoice: invoice, amount: creditToApply);
      } catch (e) {
        payError ??= e.toString();
      }
    }
    return (payError: payError, creditToApply: creditToApply);
  }

  /// Draft → final. Notes finalize through the create path (settle +
  /// restock), invoices through _updateInvoice. One run at a time (a
  /// double-click would start two), and a back-dated draft first asks
  /// whether to take today's date.
  Future<void> _finalizeDraft() async {
    if (_finalizing) return;
    _finalizing = true;
    try {
      if (!await _confirmFinalizeDate()) return;
      _isReturnDoc ? await _createInvoice() : await _updateInvoice(finalize: true);
    } finally {
      _finalizing = false;
    }
  }

  // Numbers follow date order, so a draft dated before today offers today's
  // date (due date moves with it). False when the dialog is dismissed.
  Future<bool> _confirmFinalizeDate() async {
    final now = DateTime.now();
    final old = _selectedOrderDate;
    final days = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(old.year, old.month, old.day))
        .inDays;
    if (days <= 0) return true;
    final l10n = AppLocalizations.of(context)!;
    final shown = DateFormat(_datePattern).format(old);
    final useToday = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createInvoiceFinalizeDateTitle),
        content: Text(l10n.createInvoiceFinalizeDateMessage(shown)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionCancel)),
          OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.createInvoiceFinalizeKeepDateButton(shown))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.createInvoiceFinalizeUseTodayButton)),
        ],
      ),
    );
    if (useToday == null || !mounted) return false;
    if (useToday) {
      setState(() {
        _selectedOrderDate = DateTime(now.year, now.month, now.day, old.hour,
            old.minute, old.second);
        dateController.text = DateFormat(_datePattern).format(_selectedOrderDate);
        final due = _selectedDueDate;
        if (due != null) {
          _selectedDueDate = DateTime(due.year, due.month, due.day + days,
              due.hour, due.minute, due.second);
          dueDateController.text =
              DateFormat(_datePattern).format(_selectedDueDate!);
        }
      });
    }
    return true;
  }

  /// Draft is a scratchpad: customer name still required, items are not, and
  /// it never touches the numbered sequence (invoiceNumber stays null until
  /// _updateInvoice(finalize: true) assigns one). Handles both the first
  /// save (insert) and re-saving an already-existing draft (update).
  Future<bool> _saveDraft() async {
    await _ensureDraftLinkLoaded();
    if (!mounted) return false;
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

    if (!mounted) return false;
    setState(() => isLoading = true);

    try {
      final bool isNewRow = _invoice == null;
      final invoice = Invoice(
        id: isNewRow ? await InvoicePdfServices.generateNextId() : _invoice!.id,
        invoiceNumber: null,
        customer: _isReturnDoc && _againstInvoice != null
            ? _againstInvoice!.customer
            : _resolveInvoiceCustomer(),
        items: List.from(invoiceItems),
        date: _selectedOrderDate,
        dueDate: _selectedDueDate,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        taxRate: _taxMode == TaxMode.global ? taxRate : 0.0,
        type: invoiceType,
        invoiceTitle: invoiceType == 'Invoice'
            ? invoiceTitle
            : invoiceType == 'Credit Note' &&
                    invoiceItems.any((i) => i.restocked && _canRestock(i))
                ? salesReturnTitle
                : null,
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
        originalInvoiceId: _isReturnDoc ? _againstInvoice?.id : null,
        originalInvoiceNumber: _isReturnDoc && _againstInvoice != null
            ? (_againstInvoice!.invoiceNumber ?? _againstInvoice!.id)
            : null,
        originalInvoiceDate: _isReturnDoc ? _againstInvoice?.date : null,
        returnReason:
            _isReturnDoc && _returnReason.trim().isNotEmpty ? _returnReason : null,
        creditSettlement:
            invoiceType == 'Credit Note' ? _creditSettlement : null,
        isDraft: true,
      );

      if (isNewRow) {
        await ref.read(invoiceRepositoryProvider).insertInvoice(invoice);
      } else {
        await ref.read(invoiceRepositoryProvider).updateInvoice(invoice);
      }

      final nextNumber = await ref
          .read(invoiceRepositoryProvider)
          .peekNextInvoiceNumber(invoiceType);
      if (!mounted) return true;
      setState(() {
        _invoice = invoice;
        // Keep the edit form on screen instead of falling through to the
        // "invoice created" success screen (`!isEditing && _invoice != null`
        // in build()) — a draft isn't done yet, the user likely wants to
        // keep adding to it.
        isEditing = true;
        currentInvoiceNumber = nextNumber;
        isLoading = false;
      });
      _markFormClean();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.createInvoiceDraftSavedMessage),
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
      if (kDebugMode) print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.createInvoiceErrorCreatingMessage(e.toString())), showCloseIcon: true),
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
    bool discountIsPercent = item.discountIsPercent;
    final unitController = TextEditingController(text: item.effectiveUnit.toString());
    final descriptionController =
        TextEditingController(text: item.effectiveDescription);
    String dialogUnit = item.effectiveUnit.toString();
    // Ad-hoc items have no catalog entry to fix a typo in, so their name is
    // editable here. Catalog products keep their catalog name.
    final isAdHoc = item.product.id.startsWith('custom-');
    final nameController = TextEditingController(text: item.product.name);
    final hsnController = TextEditingController(text: item.product.hsncode);
    String? nameError;
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
                if (isAdHoc) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
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
                  ),
                  if (_columnsConfig.hsncode) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: hsnController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.productMgmtHsnSacLabel,
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xsmall)),
                        prefixIcon: const Icon(Icons.qr_code_2),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
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
                      suffixIcon: _buildDiscountTypeSelector(discountIsPercent,
                          (val) => setDialogState(() => discountIsPercent = val)),
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
                  if (!discountIsPercent) ...[
                    const SizedBox(height: 8),
                    _buildDiscountPerUnitToggle(discountPerUnit,
                        (val) => setDialogState(() => discountPerUnit = val)),
                  ],
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
                final newName = nameController.text.trim();
                final newHsn = hsnController.text.trim();
                if (isAdHoc && newName.isEmpty) {
                  setDialogState(() => nameError = 'Required');
                  return;
                }
                final parsedUnitPrice = double.tryParse(unitPriceController.text);
                final unitPrice = (parsedUnitPrice != null &&
                        parsedUnitPrice != item.product.price)
                    ? parsedUnitPrice
                    : null;
                final extraCost = double.tryParse(extraCostController.text);
                final updatedItem = InvoiceItem(
                  // Copy rather than mutate: the original Product may be
                  // shared with the unsaved source invoice (edit/clone).
                  product: isAdHoc &&
                          (newName != item.product.name ||
                              newHsn != item.product.hsncode)
                      ? Product.fromMap({
                          ...item.product.toMap(),
                          'name': newName,
                          'hsncode': newHsn,
                        })
                      : item.product,
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
                  discount: _clampLineDiscount(
                      double.tryParse(discountController.text) ?? item.discount,
                      discountIsPercent),
                  unitPrice: unitPrice,
                  extraCost: extraCost,
                  unit: dialogUnit.trim(),
                  description: descriptionController.text.trim(),
                  metadata: item.metadata,
                  discountPerUnit: discountPerUnit,
                  discountIsPercent: discountIsPercent,
                  restocked: item.restocked,
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
    final hsnController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    final taxRateController = TextEditingController(text: '0');
    final extraCostController = TextEditingController();
    final unitController = TextEditingController();
    final descriptionController = TextEditingController();

    bool discountPerUnit = true;
    bool discountIsPercent = false;
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
              hsncode: hsnController.text.trim(),
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
              discount: _clampLineDiscount(
                  double.tryParse(discountController.text) ?? 0.0,
                  discountIsPercent),
              extraCost: extraCost,
              unit: selectedUnit.trim(),
              description: descriptionController.text.trim(),
              discountPerUnit: discountPerUnit,
              discountIsPercent: discountIsPercent,
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
                if (_columnsConfig.hsncode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: hsnController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.productMgmtHsnSacLabel,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.xsmall)),
                      prefixIcon: const Icon(Icons.qr_code_2),
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
                    suffixIcon: _buildDiscountTypeSelector(discountIsPercent,
                        (val) => setDialogState(() => discountIsPercent = val)),
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
                if (!discountIsPercent) ...[
                  const SizedBox(height: 8),
                  _buildDiscountPerUnitToggle(discountPerUnit,
                      (val) => setDialogState(() => discountPerUnit = val)),
                ],
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
      _customerExtraFields.load(customer);
      _customerFieldsUnlocked = false;
    });
    await _loadPreviousBalanceDue(customer);
  }

  Future<void> _loadPreviousBalanceDue(Customer? customer) async {
    final requestId = ++_previousBalanceRequestSerial;

    if (customer == null ||
        customer.id.trim().isEmpty ||
        invoiceType != 'Invoice')
    {
      if (!mounted) return;
      setState(() {
        _previousBalanceDue = 0.0;
        _customerCreditAvailable = 0.0;
        _isPreviousBalanceLoading = false;
      });
      return;
    }
    if(!mounted) return;
    setState(() => _isPreviousBalanceLoading = true);
    try {
      // Credit below loads even with Previous Balance off (Apply credit uses it).
      final balance = !_showPreviousBalance
          ? 0.0
          : await ref.read(invoiceRepositoryProvider).getPreviousBalanceDueForCustomer(
        customerId: customer.id,
        currencyCode: _currencyCode,
        asOfDate: _selectedOrderDate,
        currentInvoiceId: currentInvoiceNumber.isNotEmpty
            ? currentInvoiceNumber
            : _invoice?.id,
      );
      final credit = invoiceType == 'Invoice'
          ? await ref.read(returnRepositoryProvider).getRemainingCustomerCredit(
                customerId: customer.id,
                customerName: customer.name,
                currencyCode: _currencyCode,
              )
          : 0.0;
      if (!mounted || requestId != _previousBalanceRequestSerial) return;
      setState(() {
        _previousBalanceDue = balance;
        _customerCreditAvailable = credit;
        _isPreviousBalanceLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _previousBalanceRequestSerial) return;
      setState(() {
        _previousBalanceDue = 0.0;
        _customerCreditAvailable = 0.0;
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
      _customerExtraFields.load(null);
      taxRate = Tax.defaultTaxRate;
      _selectedOrderDate = DateTime.now();
      dateController.text = DateFormat(_datePattern).format(_selectedOrderDate);
      _selectedDueDate = null;
      dueDateController.clear();
      _previousBalanceDue = 0.0;
      _isPreviousBalanceLoading = false;
      _customerCreditAvailable = 0.0;
      _applyCustomerCredit = false;
      _payStatus = PaymentStatus.unpaid;
      _payAmountController.clear();
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
    if (!(_customerExtraFormKey.currentState?.validate() ?? true)) return;

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
        final updated = _customerExtraFields.applyTo(Customer(
          id: sel.id,
          name: name,
          email: emailController.text.trim(),
          phone: phone,
          address: addressController.text.trim(),
          gstin: gstinController.text.trim(),
          businessName: businessNameController.text.trim(),
        ), _customerFieldSettings);
        await ref.read(customerRepositoryProvider).updateCustomer(updated);
        if (!mounted) return;
        setState(() {
          selectedCustomer = updated;
          _upsertLocalCustomer(updated);
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
          _customerExtraFields.load(existing);
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

      // keepFrom: the form wasn't loaded from `existing`, so switched-off
      // fields must come from its stored row, not the form.
      final updated = _customerExtraFields.applyTo(Customer(
        id: existing.id,
        name: name,
        email: emailController.text.trim(),
        phone: phone,
        address: addressController.text.trim(),
        gstin: gstinController.text.trim(),
        businessName: businessNameController.text.trim(),
      ), _customerFieldSettings, keepFrom: existing);
      await ref.read(customerRepositoryProvider).updateCustomer(updated);
      if(!mounted) return;
      setState(() {
        selectedCustomer = updated;
        _upsertLocalCustomer(updated);
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
      final newCustomer = _customerExtraFields.applyTo(Customer(
        id: const Uuid().v4(),
        name: name,
        email: emailController.text.trim(),
        phone: phone,
        address: addressController.text.trim(),
        gstin: gstinController.text.trim(),
        businessName: businessNameController.text.trim(),
      ), _customerFieldSettings);
      await ref.read(customerRepositoryProvider).insertCustomer(newCustomer);
      if(!mounted) return;
      setState(() {
        selectedCustomer = newCustomer;
        _upsertLocalCustomer(newCustomer);
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
      _customerExtraFields.load(latest);
      _customerFieldsUnlocked = false;
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
      _customerExtraFields.load(null);
      _previousBalanceDue = 0.0;
      _isPreviousBalanceLoading = false;
      _customerFieldsUnlocked = false;
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
      height: _customFieldsCollapsed ? null : (_topCardHeightV2 ?? 165),
      decoration: _flatCardDecorationV2(context),
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            _customFieldsCollapsed ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Builder(builder: (context) {
            final title = InkWell(
              onTap: () {
                if (!mounted) return;
                setState(
                    () => _customFieldsCollapsed = !_customFieldsCollapsed);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      _customFieldsCollapsed
                          ? Icons.chevron_right
                          : Icons.expand_more,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Icon(Icons.dashboard_customize_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'CUSTOM FIELDS',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
            final controls = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filled.length}/${_customFieldDefs.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showCustomFieldsDialogV2,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(filled.isEmpty ? 'Add' : 'Edit'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.xsmall)),
                  ),
                ),
              ],
            );
            // Original single-row header; falls back to title-above-controls
            // once the column gets too narrow for both to fit side by side
            // (e.g. the Custom Fields card in a 3-column desktop layout).
            return LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 260) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 6), controls],
                );
              }
              return Row(
                children: [Expanded(child: title), const SizedBox(width: 8), controls],
              );
            });
          }),
          if (!_customFieldsCollapsed) ...[
            const SizedBox(height: 12),
            Expanded(
              child: filled.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'No custom fields filled yet.',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
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
                                tile(i + 1 < filled.length
                                    ? filled[i + 1]
                                    : null),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
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
      if (label.isNotEmpty && amount != 0) {
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
                    'Charges & Adjustments',
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Use a minus sign for deductions (e.g. freight paid by buyer).',
                        style: TextStyle(fontSize: 11, color: Colors.teal[700]),
                      ),
                    ),
                  ),
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
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  tooltip: '',
                                  onSelected: (v) {
                                    if (!mounted) return;
                                    setState(() => row.label.text = v);
                                  },
                                  itemBuilder: (_) => AdjustmentLabels.presets
                                      .map((l) => PopupMenuItem(
                                          value: l, child: Text(l)))
                                      .toList(),
                                ),
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
                                      decimal: true, signed: true),
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

  // A % line discount above 100 would make the line total negative.
  double _clampLineDiscount(double discount, bool isPercent) =>
      isPercent ? discount.clamp(0.0, 100.0) : discount;

  // % / Amount dropdown shown inside the line discount field — same control
  // as the invoice-level discount type.
  Widget _buildDiscountTypeSelector(bool isPercent, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: isPercent,
          isDense: true,
          // Button is only as wide as "%"/symbol; without this the menu
          // matches that width and wraps "Amount".
          menuWidth: 120,
          selectedItemBuilder: (context) => [
            const Center(child: Text('%')),
            Center(child: Text(_currencySymbol)),
          ],
          items: [
            const DropdownMenuItem(value: true, child: Text('%')),
            DropdownMenuItem(value: false, child: Text(AppLocalizations.of(context)!.labelAmount)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
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
            '$_currencySymbol${AmountFormat.money(amount)}',
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
                '$_currencySymbol${AmountFormat.money(_previousBalanceDue)}',
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
                  '$_currencySymbol${AmountFormat.money(totalDue)}',
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
              '$_currencySymbol${AmountFormat.money(amountPaid)}',
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
                '$_currencySymbol${AmountFormat.money(outstanding)}',
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

  /// finalize: true is how a draft leaves draft state — assigns the real
  /// invoiceNumber (via generateNextInvoiceNumber, same as _createInvoice)
  /// and flips isDraft off. Otherwise this just re-saves whatever
  /// invoiceNumber/isDraft _invoice already had (plain edit, or "update
  /// draft" which must stay unnumbered).
  Future<bool> _updateInvoice({bool finalize = false}) async {
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

    // Ship To address required when not same-as-billing; age range. Null
    // when the customer card is collapsed — render falls back to one block.
    if (!(_customerExtraFormKey.currentState?.validate() ?? true)) return false;

    // A draft being re-saved as a draft (not finalized) doesn't need items
    // yet — only finalizing (or editing an already-final invoice) does.
    if (invoiceItems.isEmpty && (finalize || !_invoice!.isDraft)) {
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
    // Re-saving a draft as a draft takes no stock, so nothing to check.
    if ((finalize || !_invoice!.isDraft) && !await _confirmStockForSave()) {
      return false;
    }

    if(!mounted) return false;
    setState(() => isLoading = true);

    try {
      final invoiceNumber = finalize
          ? await InvoicePdfServices.generateNextInvoiceNumber(invoiceType)
          : _invoice!.invoiceNumber;
      final updatedInvoice = Invoice(
        id: _invoice!.id,
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
        isDraft: finalize ? false : _invoice!.isDraft,
      );

      // Block edits that drop the total below what's already been paid.
      final paid = await ref
          .read(paymentRepositoryProvider)
          .getTotalPaidForInvoice(updatedInvoice.id);
      if (paid - updatedInvoice.total > InvoiceCalculator.moneyEpsilon) {
        if (!mounted) return false;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .createInvoiceTotalBelowPaidMessage(
                  '$_currencySymbol ${AmountFormat.money(paid)}')),
          backgroundColor: Colors.red,
          showCloseIcon: true,
          behavior: SnackBarBehavior.floating,
        ));
        return false;
      }

      // Finalizing a draft records the Payment section's choice, like create.
      final payNow = finalize && _invoice!.isDraft;
      final payAmount = payNow ? _paymentChoiceAmount(updatedInvoice.total) : 0.0;
      if (payAmount == null) return false;

      await ref.read(invoiceRepositoryProvider).updateInvoice(updatedInvoice);

      final (:payError, :creditToApply) = payNow
          ? await _applyPaymentChoice(updatedInvoice, payAmount)
          : (payError: null, creditToApply: 0.0);

      final refreshedInvoice =
          await ref.read(invoiceRepositoryProvider).getInvoiceById(updatedInvoice.id);
      final stillDraft = (refreshedInvoice ?? updatedInvoice).isDraft;
      final nextNumber = stillDraft
          ? await ref
              .read(invoiceRepositoryProvider)
              .peekNextInvoiceNumber(invoiceType)
          : null;

      if (!mounted) return true;
      setState(() {
        _invoice = refreshedInvoice ?? updatedInvoice;
        currentInvoiceNumber = nextNumber ??
            (_invoice!.invoiceNumber ?? _invoice!.id);
        isLoading = false;
        if (creditToApply > 0) {
          _customerCreditAvailable -= creditToApply;
          _applyCustomerCredit = false;
        }
      });
      _markFormClean();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(finalize
                  ? AppLocalizations.of(context)!.createInvoiceFinalizedMessage(
                      _invoiceTypeLabel(invoiceType), updatedInvoice.invoiceNumber ?? '')
                  : AppLocalizations.of(context)!.createInvoiceUpdatedSuccessMessage(_invoiceTypeLabel(invoiceType))),
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
      if (payError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .createInvoicePaymentNotRecordedMessage(payError)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
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
                                _customerExtraFields.applyTo(Customer(
                                  id: const Uuid().v4(),
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phone,
                                  address: addressController.text.trim(),
                                  gstin: gstinController.text.trim(),
                                  businessName:
                                      businessNameController.text.trim(),
                                ), _customerFieldSettings);
                            if (existing == null) {
                              await ref.read(customerRepositoryProvider).insertCustomer(newCustomer);
                            }
                            if (mounted) {
                              setState(() {
                                selectedCustomer = newCustomer;
                                _upsertLocalCustomer(newCustomer);
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
            discountIsPercent: item.discountIsPercent,
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
            if (_invoice == null) {
              _createInvoice();
            } else if (_invoice!.isDraft) {
              _finalizeDraft();
            } else {
              _updateInvoice();
            }
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
        // Drafts can't be previewed / printed — same rule as the buttons.
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () {
          if (_invoice == null || _invoice!.isDraft) return;
          InvoicePdfServices.previewPDF(context, _invoice!);
        },
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          if (_invoice == null || _invoice!.isDraft) return;
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
                                  : widget.convertFromQuotationId != null
                                      ? AppLocalizations.of(context)!.createInvoiceConvertTitle
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
      case 'Credit Note':
        return AppLocalizations.of(context)!.docTypeCreditNote;
      case 'Debit Note':
        return AppLocalizations.of(context)!.docTypeDebitNote;
      default:
        return AppLocalizations.of(context)!.labelInvoice;
    }
  }

  bool get _isReturnDoc =>
      invoiceType == 'Credit Note' || invoiceType == 'Debit Note';
  // Order time, next to the order date. Uses the PDF's 12/24-hour setting.
  Widget _orderTimeFieldV2() {
    final text = DateFormat(_pdfTimeFormat == '12' ? 'h:mm a' : 'HH:mm', 'en_US')
        .format(_selectedOrderDate);
    return TextFormField(
      key: ValueKey('order-time-$text'), // rebuild when the time changes
      initialValue: text,
      readOnly: true,
      decoration: _flatFieldDecorationV2(
          AppLocalizations.of(context)!.createInvoiceOrderTimeLabel,
          suffixIcon: const Icon(Icons.access_time, size: 16)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedOrderDate),
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx)
                .copyWith(alwaysUse24HourFormat: _pdfTimeFormat != '12'),
            child: child!,
          ),
        );
        if (picked == null || !mounted) return;
        setState(() => _selectedOrderDate = DateTime(
            _selectedOrderDate.year,
            _selectedOrderDate.month,
            _selectedOrderDate.day,
            picked.hour,
            picked.minute));
      },
    );
  }

  String _againstInvoiceText(Invoice inv) =>
      '#${inv.invoiceNumber ?? inv.id}  ·  ${AppFormatters.formatShortDate(inv.date)}'
      '  ·  ${inv.currencySymbol}${AmountFormat.money(inv.total)}';

  // "Against invoice" picker for credit / debit notes: the selected
  // customer's invoices, searchable. Optional (empty = standalone note);
  // locked when the note was started from an invoice row. GST + registered
  // customer + nothing picked → soft warning (Rule 53 wants the reference).
  Widget _againstInvoiceFieldV2() {
    final l10n = AppLocalizations.of(context)!;
    final inv = _againstInvoice;
    final locked =
        widget.cloneFrom != null && inv?.id == widget.cloneFrom!.id;
    final gstWarning =
        inv == null && _showGstFields && gstinController.text.trim().isNotEmpty;
    return InkWell(
      onTap: locked ? null : _pickAgainstInvoice,
      child: InputDecorator(
        isEmpty: inv == null,
        decoration: _flatFieldDecorationV2(
          inv?.type == 'Receipt'
              ? l10n.returnAgainstReceiptLabel
              : l10n.returnAgainstInvoiceLabel,
          helperText: gstWarning ? l10n.returnGstAgainstInvoiceWarning : null,
          suffixIcon: inv != null && !locked
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() {
                    _againstInvoice = null;
                    _returnedByProduct = const {};
                    if (_creditSettlement == CreditSettlement.reduceInvoice) {
                      _creditSettlement = CreditSettlement.customerCredit;
                    }
                  }),
                )
              : const Icon(Icons.arrow_drop_down),
        ).copyWith(
          enabled: !locked,
          helperMaxLines: 2,
          helperStyle: TextStyle(color: Colors.orange[800]),
        ),
        child: inv == null ? null : Text(_againstInvoiceText(inv)),
      ),
    );
  }

  Future<void> _pickAgainstInvoice() async {
    final l10n = AppLocalizations.of(context)!;
    final customerId = selectedCustomer?.id ?? '';
    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.returnSelectCustomerFirst)));
      return;
    }
    // DB search (newest 50 matches) so every invoice is reachable.
    // Drafts have no number and no committed sale yet — nothing to return.
    Future<List<Invoice>> search(String q) async => (await ref
            .read(invoiceRepositoryProvider)
            .getInvoicesPaginated(
              searchQuery: q.trim(),
              filterType: 'Invoice',
              customerId: customerId,
              filter: const InvoiceListFilter(hideDeclined: true),
            ))
        .where((i) => !i.isDraft)
        .toList();
    var shown = await search('');
    if (!mounted) return;
    var query = '';
    Timer? debounce;
    final picked = await showDialog<Invoice>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text(l10n.returnPickInvoiceTitle),
          content: SizedBox(
            width: 440,
            height: 420,
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  decoration: _flatFieldDecorationV2(
                      l10n.returnPickInvoiceSearchHint,
                      prefixIcon: const Icon(Icons.search)),
                  onChanged: (v) {
                    query = v;
                    debounce?.cancel();
                    debounce = Timer(const Duration(milliseconds: 300), () async {
                      final result = await search(v);
                      if (ctx.mounted && v == query) {
                        setLocal(() => shown = result);
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: shown.isEmpty
                      ? Center(child: Text(l10n.returnPickInvoiceEmpty))
                      : ListView.builder(
                          itemCount: shown.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            title: Text(_againstInvoiceText(shown[i])),
                            onTap: () => Navigator.pop(ctx, shown[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.actionCancel),
            ),
          ],
        );
      }),
    );
    debounce?.cancel();
    if (picked == null || !mounted) return;
    if (invoiceType == 'Credit Note') {
      final full =
          await ref.read(invoiceRepositoryProvider).getInvoiceById(picked.id);
      if (full == null || !mounted) return;
      await _prefillCreditNoteFrom(full);
      return;
    }
    setState(() => _againstInvoice = picked);
  }

  /// Credit note against [inv]: link it and fill its lines at the qty still
  /// returnable (Left), with the invoice's discounts and extra costs. A flat
  /// line discount / extra cost and a flat invoice discount scale with the
  /// returned share; % discounts carry over as-is.
  Future<void> _prefillCreditNoteFrom(Invoice inv) async {
    final returned =
        await ref.read(returnRepositoryProvider).getReturnedQtyByLine(inv.id);
    // Drafts skip the Left cap but still hold the extra costs.
    final hasEarlierNote = (await ref
            .read(returnRepositoryProvider)
            .getNotesForInvoice(inv.id))
        .any((n) => n.type == 'Credit Note' && n.id != _invoice?.id);
    if (!mounted) return;
    final left = <String, double>{};
    for (final i in inv.items) {
      left[i.product.id] = (left[i.product.id] ?? 0) + i.quantity;
    }
    returned.forEach((pid, q) => left[pid] = (left[pid] ?? 0) - q);
    final lines = <InvoiceItem>[];
    for (final i in inv.items) {
      final qty = math.min(i.quantity, left[i.product.id] ?? 0.0);
      if (qty <= InvoiceCalculator.moneyEpsilon) continue;
      left[i.product.id] = left[i.product.id]! - qty;
      final ratio = qty / i.quantity;
      lines.add(InvoiceItem(
        product: i.product,
        quantity: qty,
        discount: i.discountPerUnit || i.discountIsPercent
            ? i.discount
            : i.discount * ratio,
        unitPrice: i.unitPrice,
        extraCost: i.extraCost == null ? null : i.extraCost! * ratio,
        unit: i.unit,
        description: i.description,
        metadata: i.metadata,
        discountPerUnit: i.discountPerUnit,
        discountIsPercent: i.discountIsPercent,
        isProductSaved: i.isProductSaved,
      ));
    }
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!
            .returnNothingLeft(inv.invoiceNumber ?? inv.id)),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ));
      return;
    }
    final soldValue = inv.items.fold<double>(0, (s, i) => s + i.total);
    final returnValue = lines.fold<double>(0, (s, i) => s + i.total);
    final discountValue =
        inv.invoiceDiscountType == InvoiceDiscountType.percent ||
                soldValue <= InvoiceCalculator.moneyEpsilon
            ? inv.invoiceDiscountValue
            : inv.invoiceDiscountValue * returnValue / soldValue;
    setState(() {
      _againstInvoice = inv;
      _returnedByProduct = returned;
      invoiceItems = lines;
      _currencyCode = inv.currencyCode;
      _currencySymbol = inv.currencySymbol;
      taxRate = inv.taxRate;
      taxRateController.text = (taxRate * 100).toStringAsFixed(1);
      _isTaxEnabled = inv.taxMode != TaxMode.none;
      _isPerItem = inv.taxMode == TaxMode.perItem;
      _isInterState = inv.isInterState;
      for (final row in _additionalCostControllers) {
        row.label.dispose();
        row.amount.dispose();
      }
      _additionalCostControllers.clear();
      // Extra costs (shipping…) go back once — only on the first return.
      for (final c in hasEarlierNote ? const <AdditionalCost>[] : inv.additionalCosts) {
        _additionalCostControllers.add((
          label: TextEditingController(text: c.label),
          amount: TextEditingController(text: c.amount.toStringAsFixed(2)),
        ));
      }
      _showAdditionalCosts = _additionalCostControllers.isNotEmpty;
      _invoiceDiscountType = inv.invoiceDiscountType;
      _invoiceDiscountController.text =
          discountValue > 0 ? discountValue.toStringAsFixed(2) : '';
      _returnReason = 'Goods returned';
      _creditSettlement = _canReduceInvoice
          ? CreditSettlement.reduceInvoice
          : CreditSettlement.refund;
    });
  }

  /// Linked credit note: qty of [productId] still returnable on top of what
  /// earlier credit notes took back.
  double _creditNoteLeft(String productId) {
    final sold = _againstInvoice!.items
        .where((i) => i.product.id == productId)
        .fold<double>(0, (s, i) => s + i.quantity);
    return sold - (_returnedByProduct[productId] ?? 0);
  }

  // Greys out and disables a section while _lockedByCreditNotes.
  Widget _lockedV2(Widget child, {bool? locked}) =>
      (locked ?? _lockedByCreditNotes)
          ? AbsorbPointer(child: Opacity(opacity: 0.55, child: child))
          : child;

  // A note linked to an invoice belongs to that invoice's customer — the card
  // is read-only until the link is cleared.
  bool get _customerLocked =>
      _lockedByCreditNotes || (_isReturnDoc && _againstInvoice != null);

  // "Reduce invoice balance" only makes sense while the linked invoice is owed.
  // Receipts are paid on the spot, so they never have a balance to reduce.
  bool get _canReduceInvoice =>
      _againstInvoice != null &&
      _againstInvoice!.type == 'Invoice' &&
      _againstInvoice!.outstandingBalance > InvoiceCalculator.moneyEpsilon;

  // Only catalogue goods with tracked stock can go back on the shelf.
  bool _canRestock(InvoiceItem i) =>
      i.product.type != 'service' &&
      !i.product.unlimitedStock &&
      !i.product.id.startsWith('custom-');

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  /// Save-time stock check for Create / Update / Finalize. "Add anyway" only
  /// ran when a line was added; a draft finalized later, another sale in the
  /// meantime, or a raised qty on edit can still take stock below zero. Same
  /// warn-but-allow rule: lists the short products, user saves anyway or not.
  Future<bool> _confirmStockForSave() async {
    // Only sales take stock (quotations, notes and drafts don't).
    if (invoiceType != 'Invoice' && invoiceType != 'Receipt') return true;
    final l10n = AppLocalizations.of(context)!;
    final need = <String, double>{};
    for (final i in invoiceItems) {
      need[i.product.id] = (need[i.product.id] ?? 0) + i.quantity;
    }
    // An already-final invoice gets its own saved qty back before re-deducting.
    final saved = _invoice != null && !_invoice!.isDraft
        ? _invoice!.items
        : const <InvoiceItem>[];
    final shortLines = <String>[];
    for (final e in need.entries) {
      if (e.key.startsWith('custom-')) continue;
      final product =
          await ref.read(productRepositoryProvider).getProductById(e.key);
      if (product == null || product.unlimitedStock) continue;
      final available = product.stock +
          saved
              .where((i) => i.product.id == e.key)
              .fold<double>(0, (s, i) => s + i.quantity);
      if (e.value > available + InvoiceCalculator.moneyEpsilon) {
        final unit = product.unit.trim().isEmpty ? '' : ' ${product.unit.trim()}';
        shortLines.add(l10n.createInvoiceStockShortLine(
            product.name,
            '${_fmtQty(available)}$unit',
            '${_fmtQty(e.value)}$unit',
            '${_fmtQty(e.value - available)}$unit'));
      }
    }
    if (shortLines.isEmpty || !mounted) return mounted;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createInvoiceStockShortTitle),
        content: Text('${l10n.createInvoiceStockShortMessage}\n'
            '${shortLines.map((l) => '• $l').join('\n')}\n\n'
            '${l10n.createInvoiceStockShortFooter}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.createInvoiceGoBackButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: Text(l10n.createInvoiceSaveAnywayButton),
          ),
        ],
      ),
    );
    return go == true;
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

  // Desktop, when any extra customer field is on: Customer Details and Custom
  // Fields cards sit side by side at the same fixed height; overflow scrolls
  // inside each card under its header. All extras off: null = exactly the
  // pre-feature layout (customer card natural height, custom fields 165).
  double? get _topCardHeightV2 => _customerFieldSettings.any ? 215 : null;

  // [height] set (desktop): fixed-height card, fields scroll under the fixed
  // header with an always-visible scrollbar so users can tell there's more.
  // Null (stacked layout): natural height, the whole page scrolls.
  Widget _customerDetailsFormV2({double? height}) {
    final scroll = height != null && _customerDetailsExpanded;
    // Same shape as _flatCardV2, plus the optional fixed height (same pattern
    // as _customFieldsSummaryCardV2).
    return Container(
      height: scroll ? height : null,
      decoration: _flatCardDecorationV2(context),
      padding: const EdgeInsets.all(AppPadding.medium),
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
                child: _lockedV2(locked: _customerLocked, Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (nameController.text.trim().isNotEmpty &&
                        (selectedCustomer == null || !_customerFormMatchesSelected))
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
                      if (!_customerFieldsUnlocked)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit customer details',
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(() => _customerFieldsUnlocked = true),
                        ),
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
                )),
              ),
              if (_customerFieldSettings.any)
                IconButton(
                  icon: const Icon(Icons.open_in_full, size: 18),
                  tooltip:
                      AppLocalizations.of(context)!.tooltipEditInLargerView,
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      _customerLocked ? null : _showCustomerDetailsDialogV2,
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
          if (_customerDetailsExpanded)
            _customerCardBodyV2(scroll, [
          const SizedBox(height: 2),
          if (selectedCustomer == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'New or walk-in customer — enter their details below.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  readOnly: _customerFieldsLocked,
                  onChanged: (_) => setState(() {}),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldCustomerNameRequiredLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: businessNameController,
                  readOnly: _customerFieldsLocked,
                  onChanged: (_) => setState(() {}),
                  decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldBusinessNameLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  readOnly: _customerFieldsLocked,
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
                    readOnly: _customerFieldsLocked,
                    onChanged: (_) => setState(() {}),
                    decoration: _flatFieldDecorationV2(AppLocalizations.of(context)!.fieldGstinVatLabel),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: emailController,
                  readOnly: _customerFieldsLocked,
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
          // Per-invoice values, never locked (like address): editing them
          // changes only this invoice's snapshot, not the customer record.
          Form(
            key: _customerExtraFormKey,
            child: CustomerExtraFields(
              controller: _customerExtraFields,
              settings: _customerFieldSettings,
              inline: true,
              decoration: (label) => _flatFieldDecorationV2(label),
              billingName: nameController,
              billingPhone: phoneController,
              billingAddress: addressController,
              datePattern: _datePattern,
            ),
          ),
          ]),
        ],
      ),
    );
  }

  // Larger view of the whole customer card (base + extra fields) for easier
  // filling. Edits the same controllers live, so the card reflects every
  // change; Cancel restores what was there when the dialog opened. Same
  // locking as the card: base fields read-only for a selected customer
  // until unlocked; address and extra fields always editable.
  Future<void> _showCustomerDetailsDialogV2() async {
    final l10n = AppLocalizations.of(context)!;
    final base = [
      nameController,
      businessNameController,
      phoneController,
      emailController,
      gstinController,
      addressController,
    ];
    final baseBefore = [for (final c in base) c.text];
    final extraBefore = _customerExtraFields.applyTo(
        Customer(id: '', name: '', email: '', phone: '', address: '', gstin: ''),
        _customerFieldSettings);
    final formKey = GlobalKey<FormState>();
    final locked = _customerFieldsLocked;

    Widget field(TextEditingController c, String label,
            {bool readOnly = false, int maxLines = 1}) =>
        TextField(
          controller: c,
          readOnly: readOnly,
          minLines: 1,
          maxLines: maxLines,
          decoration: _flatFieldDecorationV2(label),
        );
    Widget row(List<Widget> fields) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: fields[i]),
            ],
          ],
        );

    final applied = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createInvoiceCustomerDetailsDialogTitle),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  row([
                    field(nameController, l10n.fieldCustomerNameRequiredLabel,
                        readOnly: locked),
                    field(businessNameController, l10n.fieldBusinessNameLabel,
                        readOnly: locked),
                    field(phoneController, l10n.fieldPhoneLabel,
                        readOnly: locked),
                  ]),
                  const SizedBox(height: 12),
                  row([
                    field(emailController, l10n.fieldEmailLabel,
                        readOnly: locked),
                    if (_showGstFields)
                      field(gstinController, l10n.fieldGstinVatLabel,
                          readOnly: locked),
                  ]),
                  const SizedBox(height: 12),
                  field(addressController, l10n.fieldAddressLabel, maxLines: 3),
                  CustomerExtraFields(
                    controller: _customerExtraFields,
                    settings: _customerFieldSettings,
                    inline: true,
                    decoration: (label) => _flatFieldDecorationV2(label),
                    billingName: nameController,
                    billingPhone: phoneController,
                    billingAddress: addressController,
                    datePattern: _datePattern,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(l10n.actionApply),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (applied != true) {
      for (var i = 0; i < base.length; i++) {
        base[i].text = baseBefore[i];
      }
      _customerExtraFields.load(extraBefore);
    }
    setState(() {});
  }

  Widget _customerCardBodyV2(bool scroll, List<Widget> children) {
    // Lock sits inside the scroll view so a locked card still scrolls.
    final body = _lockedV2(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        locked: _customerLocked);
    if (!scroll) return body;
    return Expanded(
      child: Scrollbar(
        controller: _customerCardScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _customerCardScrollController,
          // Top room for the first row's floating labels, which sit above
          // the field and would be clipped by the scroll viewport.
          padding: const EdgeInsets.only(top: 8, right: 12),
          child: body,
        ),
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
          if (_isReturnDoc)
            TextField(
              enabled: false,
              controller:
                  TextEditingController(text: _invoiceTypeLabel(invoiceType)),
              decoration: _flatFieldDecorationV2(
                  AppLocalizations.of(context)!.createInvoiceTypeFieldLabel),
            )
          else
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: invoiceType,
              decoration: _flatFieldDecorationV2(
                AppLocalizations.of(context)!.createInvoiceTypeFieldLabel,
                helperText: (isEditing || widget.convertFromQuotationId != null)
                    ? AppLocalizations.of(context)!.createInvoiceTypeLockedHelperText
                    : null,
              ),
              items: [
                DropdownMenuItem(value: 'Invoice', child: Text(AppLocalizations.of(context)!.labelInvoice)),
                DropdownMenuItem(value: 'Quotation', child: Text(AppLocalizations.of(context)!.labelQuotation)),
                DropdownMenuItem(value: 'Receipt', child: Text(AppLocalizations.of(context)!.labelReceipt)),
              ],
              onChanged: (isEditing || widget.convertFromQuotationId != null)
                  ? null
                  : (value) {
                      if (value != null) resetInvoiceType(value);
                    },
            ),
          if (_isReturnDoc) ...[
            const SizedBox(height: 12),
            _againstInvoiceFieldV2(),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _returnReason.isEmpty ? 'Other' : _returnReason,
              decoration: _flatFieldDecorationV2(
                  AppLocalizations.of(context)!.returnReasonLabel),
              items: [
                for (final r in const [
                  'Price revision',
                  'Goods returned',
                  'Billing correction',
                  'Goodwill / discount',
                  'Other'
                ])
                  DropdownMenuItem(
                      value: r,
                      child: Text(returnReasonLabel(
                          AppLocalizations.of(context)!, r))),
              ],
              onChanged: (v) => setState(() => _returnReason = v ?? 'Other'),
            ),
            if (invoiceType == 'Credit Note') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<CreditSettlement>(
                isExpanded: true,
                value: _creditSettlement == CreditSettlement.reduceInvoice &&
                        !_canReduceInvoice
                    ? CreditSettlement.customerCredit
                    : _creditSettlement,
                decoration: _flatFieldDecorationV2(
                    AppLocalizations.of(context)!.returnSettlementLabel),
                items: [
                  if (_canReduceInvoice)
                    DropdownMenuItem(
                        value: CreditSettlement.reduceInvoice,
                        child: Text(AppLocalizations.of(context)!
                            .returnSettlementReduceInvoice(
                                '$_currencySymbol${AmountFormat.money(_againstInvoice!.outstandingBalance)}'))),
                  DropdownMenuItem(
                      value: CreditSettlement.customerCredit,
                      child: Text(AppLocalizations.of(context)!
                          .returnSettlementKeepCredit)),
                  DropdownMenuItem(
                      value: CreditSettlement.refund,
                      child: Text(AppLocalizations.of(context)!
                          .returnSettlementRefundNow)),
                ],
                onChanged: (v) => setState(() =>
                    _creditSettlement = v ?? CreditSettlement.customerCredit),
              ),
              if (_creditSettlement == CreditSettlement.refund) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _refundMethod,
                  decoration: _flatFieldDecorationV2(
                      AppLocalizations.of(context)!.returnRefundMethodLabel),
                  items: [
                    for (final m in const [
                      'Cash',
                      'Bank Transfer',
                      'Check',
                      'Online',
                      'Other'
                    ])
                      DropdownMenuItem(
                          value: m,
                          child: Text(refundMethodLabel(
                              AppLocalizations.of(context)!, m))),
                  ],
                  onChanged: (v) => setState(() => _refundMethod = v ?? 'Cash'),
                ),
              ],
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
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
                        // Keep the invoice's existing time — the picker returns midnight.
                        _selectedOrderDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            _selectedOrderDate.hour,
                            _selectedOrderDate.minute,
                            _selectedOrderDate.second);
                        dateController.text =
                            DateFormat(_datePattern).format(picked);
                      });
                      await _loadPreviousBalanceDue(selectedCustomer);
                    }
                  },
                ),
              ),
              if (_showTimeInPdf) ...[
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _orderTimeFieldV2()),
              ],
            ],
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
                // Real Credit / Debit Notes are their own types now; kept only
                // so invoices saved with these titles still show them.
                if (invoiceTitle == 'Credit Note')
                  DropdownMenuItem(
                      value: 'Credit Note', child: Text(AppLocalizations.of(context)!.gstTitleCreditNoteLabel)),
                if (invoiceTitle == 'Debit Note')
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
        // Notes return / charge what was sold — no new catalogue products.
        if (!_isReturnDoc) ...[
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _addNewProductV2,
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: Text(AppLocalizations.of(context)!.productFormNewProductButton),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
          ),
        ),
        ],
      ],
    );
  }

  // Saves a real catalogue product (same form and rules as Product
  // Management), then adds it as a line like any picked product.
  Future<void> _addNewProductV2() async {
    final product = await showNewProductDialog(context,
        user: widget.user, initialName: searchController.text);
    if (product == null || !mounted) return;
    // Its custom fields (batch, expiry…) snapshot onto the line like search.
    final metadata = await ref
        .read(productRepositoryProvider)
        .getProductMetadataForIds([product.id]);
    if (!mounted) return;
    searchController.clear();
    setState(() {
      products = [...products, product];
      filteredProducts = [...filteredProducts, product];
      _productMetadata = {..._productMetadata, ...metadata};
      _showProductDropdownV2 = false;
    });
    addInvoiceProductPrompt(product, newProduct: true);
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
                                    '$_currencySymbol${AmountFormat.money(product.price)}  ·  Stock: ${product.stock}'
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
                            '$_currencySymbol${AmountFormat.money(item.effectivePrice)} *',
                            color: Colors.orange[700])
                      else
                        _buildItemDetail('Price',
                            '$_currencySymbol${AmountFormat.money(item.product.price)}'),
                      if (_taxMode == TaxMode.perItem)
                        _buildItemDetail(
                            'Tax', '${item.product.tax_rate}%'),
                      if (item.product.priceIncludesTax) ...[
                        _buildItemDetail(
                            _taxMode == TaxMode.perItem ? '' : 'Tax',
                            'Inclusive',
                            color: Colors.teal[700]),
                        _buildItemDetail('Net Price',
                            '$_currencySymbol${AmountFormat.money(InvoiceTotalsCalculator.netPrice(price: item.effectivePrice, taxRatePercent: item.product.tax_rate.toDouble(), priceIncludesTax: true))}',
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
                            item.discountIsPercent
                                ? '${item.discount.toStringAsFixed(2)}%'
                                : '$_currencySymbol${AmountFormat.money(item.discount)}${item.discountPerUnit ? ' ×qty' : ''}'),
                      if (!item.discountIsPercent && item.discountPerUnit && item.discount > 0)
                        _buildItemDetail('Net',
                            '$_currencySymbol${AmountFormat.money(item.effectivePrice - item.discount)}/item',
                            color: Colors.teal[700]),
                      if (item.extraCost != null && item.extraCost! > 0)
                        _buildItemDetail('Extra',
                            '+$_currencySymbol${AmountFormat.money(item.extraCost!)}',
                            color: Colors.teal[700]),
                      // Credit note: qty still returnable (linked invoice)
                      // and whether this line goes back into stock.
                      if (invoiceType == 'Credit Note' && _againstInvoice != null)
                        _buildItemDetail(
                            AppLocalizations.of(context)!.returnColLeft,
                            _fmtQty(math.max(
                                0.0, _creditNoteLeft(item.product.id))),
                            color: Colors.orange[800]),
                      if (invoiceType == 'Credit Note' && _canRestock(item))
                        InkWell(
                          onTap: () =>
                              setState(() => item.restocked = !item.restocked),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: Checkbox(
                                  value: item.restocked,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (v) => setState(
                                      () => item.restocked = v ?? true),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(AppLocalizations.of(context)!.returnColToStock,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$_currencySymbol${AmountFormat.money(item.total)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (!_lockedByCreditNotes) ...[
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
              if (_lockedByCreditNotes)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    AppLocalizations.of(context)!.createInvoiceLockedByCreditNotes,
                    style: TextStyle(
                        fontSize: AppFontSize.small, color: Colors.orange[800]),
                  ),
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
                child: _lockedV2(_productQuickAddBarV2()),
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
              // Counts as "inside" the search field, so a mouse-down on a
              // row doesn't unfocus it and hide the list before the click lands.
              child: TextFieldTapRegion(child: _productDropdownListV2()),
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

  Widget _paymentSectionV2(double total) {
    final l10n = AppLocalizations.of(context)!;
    final paid = _payStatus == PaymentStatus.paid
        ? total
        : _payStatus == PaymentStatus.partial
            ? (double.tryParse(_payAmountController.text.trim()) ?? 0.0)
            : 0.0;
    final balanceDue = total -
        paid -
        (_applyCustomerCredit
            ? _customerCreditAvailable
            : 0.0);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PaymentStatus>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: PaymentStatus.unpaid,
                  label: Text(l10n.paymentStatusUnpaid)),
              ButtonSegment(
                  value: PaymentStatus.partial,
                  label: Text(l10n.paymentStatusPartial)),
              ButtonSegment(
                  value: PaymentStatus.paid,
                  label: Text(l10n.paymentStatusPaid)),
            ],
            selected: {_payStatus},
            onSelectionChanged: (v) => setState(() => _payStatus = v.first),
          ),
          if (_payStatus != PaymentStatus.unpaid) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _payMethod,
                    decoration: _flatFieldDecorationV2(
                        l10n.paymentDialogMethodFieldLabel),
                    items: paymentMethods
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(paymentMethodLabel(l10n, m))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _payMethod = v);
                    },
                  ),
                ),
                if (_payStatus == PaymentStatus.partial) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _payAmountController,
                      onChanged: (_) => setState(() {}),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _flatFieldDecorationV2(
                          l10n.paymentDialogAmountPaidLabel,
                          prefixText: '$_currencySymbol '),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _buildTotalRow(l10n.paymentDialogAmountPaidLabel, paid, false),
            const SizedBox(height: 4),
            _buildTotalRow(l10n.createInvoiceBalanceDueLabel,
                balanceDue < 0 ? 0 : balanceDue, false),
          ],
          if (_customerCreditAvailable > 0)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _applyCustomerCredit,
              onChanged: (v) =>
                  setState(() => _applyCustomerCredit = v ?? false),
              title: Text(l10n.returnApplyCreditToInvoiceLabel),
              subtitle: Text(l10n.returnCreditAvailableLabel(
                  '$_currencySymbol${AmountFormat.money(_customerCreditAvailable)}')),
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
                Text('-$_currencySymbol${AmountFormat.money(totalDiscount)}',
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
                      '-$_currencySymbol${AmountFormat.money(invoiceDiscountAmount)}',
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
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          // Tall details (a credit note's link / reason / settlement / refund
          // method) scroll here instead of squeezing out the totals footer.
          ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: constraints.maxHeight * 0.45),
            child: SingleChildScrollView(child: _invoiceDetailsFormV2()),
          ),
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
                          _lockedV2(_buildAdditionalCostsSection()),
                          const SizedBox(height: 12),
                          _lockedV2(_invoiceDiscountSectionV2()),
                          if ((!isEditing || (_invoice?.isDraft ?? false)) &&
                              invoiceType == 'Invoice') ...[
                            const SizedBox(height: 18),
                            _sectionLabelV2(AppLocalizations.of(context)!
                                .createInvoicePaymentSectionLabel),
                            _paymentSectionV2(total),
                          ],
                          const SizedBox(height: 18),
                          _sectionLabelV2('Notes'),
                          _notesFieldV2(),
                          const SizedBox(height: 18),
                          _sectionLabelV2('Tax settings'),
                          _lockedV2(_taxSettingsSectionV2()),
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
      ),
    );
  }

  Widget _actionButtonsV2() {
    // NOT widget.invoiceToEdit != null — Save Draft can create a saved row
    // (_invoice != null) within this same session without the widget ever
    // being reconstructed in edit mode, so routing must key off _invoice.
    final hasSavedRow = _invoice != null;
    final isDraftRow = _invoice?.isDraft ?? false;
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
                      tooltip: isDraftRow
                          ? AppLocalizations.of(context)!.createInvoiceDraftPreviewTooltip
                          : AppLocalizations.of(context)!.createInvoicePreviewTooltip,
                      color: Colors.purple,
                      onPressed: hasSavedRow && !isDraftRow
                          ? () => InvoicePdfServices.previewPDF(context, _invoice!)
                          : null,
                    ),
                    _buildActionButton(
                      icon: Icons.download_outlined,
                      label: AppLocalizations.of(context)!.createInvoiceDownloadLabel,
                      color: Colors.deepPurple,
                      onPressed: hasSavedRow && !isDraftRow
                          ? () => PDFService.downloadPDF(context, _invoice!)
                          : null,
                    ),
                    _buildActionButton(
                      icon: Icons.print_outlined,
                      label: AppLocalizations.of(context)!.actionPrint,
                      tooltip: isDraftRow
                          ? AppLocalizations.of(context)!.createInvoiceDraftPrintTooltip
                          : AppLocalizations.of(context)!.createInvoicePrintTooltip,
                      color: Colors.blue,
                      onPressed: hasSavedRow && !isDraftRow
                          ? () => InvoicePdfServices.generatePDF(context, _invoice!)
                          : null,
                    ),
                  ],
                ),
              ),
              // A quotation conversion links on create, so it can't be a
              // draft. Draft notes stay inert until finalized (_createInvoice).
              if ((!hasSavedRow || isDraftRow) &&
                  widget.convertFromQuotationId == null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: !isLoading ? _saveDraft : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                    ),
                    icon: const Icon(Icons.drafts_outlined),
                    label: Text(
                      AppLocalizations.of(context)!.createInvoiceSaveDraftButton,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Flexible(
                child: Tooltip(
                  message: 'Shortcut: Ctrl+s',
                  child: ElevatedButton.icon(
                    onPressed: invoiceItems.isNotEmpty && !isLoading
                        ? (!hasSavedRow
                            ? _createInvoice
                            : isDraftRow
                                ? _finalizeDraft
                                : _updateInvoice)
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
                        : Icon(!hasSavedRow
                            ? Icons.save_outlined
                            : isDraftRow
                                ? Icons.task_alt
                                : Icons.update),
                    label: Text(
                      isLoading
                          ? 'Processing...'
                          : (!hasSavedRow
                              ? (compact ? 'Create $invoiceType' : 'Create $invoiceType (Ctrl+S)')
                              : isDraftRow
                                  ? (compact
                                      ? AppLocalizations.of(context)!.createInvoiceFinalizeButton(_invoiceTypeLabel(invoiceType))
                                      : '${AppLocalizations.of(context)!.createInvoiceFinalizeButton(_invoiceTypeLabel(invoiceType))} (Ctrl+S)')
                                  : (compact ? 'Update $invoiceType' : 'Update $invoiceType (Ctrl+S)')),
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
                    Expanded(
                        flex: 2,
                        child: _customerDetailsFormV2(height: _topCardHeightV2)),
                    AppSpacing.wSmall,
                    Expanded(flex: 1, child: _customFieldsSummaryCardV2()),
                  ],
                )
              else
                _customerDetailsFormV2(height: _topCardHeightV2),
              AppSpacing.hSmall,
              Expanded(child: _itemsTableSectionV2()),
            ],
          ),
        ),
        AppSpacing.wSmall,
        SizedBox(
          width: Platform.isAndroid ? 300 : 420,
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
              _lockedV2(_buildAdditionalCostsSection()),
              const SizedBox(height: 12),
              _lockedV2(_invoiceDiscountSectionV2()),
              if ((!isEditing || (_invoice?.isDraft ?? false)) &&
                  invoiceType == 'Invoice') ...[
                const SizedBox(height: 18),
                _sectionLabelV2(AppLocalizations.of(context)!
                    .createInvoicePaymentSectionLabel),
                _paymentSectionV2(total),
              ],
              const SizedBox(height: 18),
              _sectionLabelV2('Notes'),
              _notesFieldV2(),
              const SizedBox(height: 18),
              _sectionLabelV2('Tax settings'),
              _lockedV2(_taxSettingsSectionV2()),
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
