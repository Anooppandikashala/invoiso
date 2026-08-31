import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/utils/formatters.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/supported_currencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/company_info.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/widgets/apply_customer_payment_dialog.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class CustomerManagementScreenV2 extends ConsumerStatefulWidget {
  final User user;
  final void Function(Customer customer)? onViewCustomerStatement;
  const CustomerManagementScreenV2({super.key, required this.user, this.onViewCustomerStatement});

  @override
  ConsumerState<CustomerManagementScreenV2> createState() =>
      _CustomerManagementScreenV2State();
}

class _CustomerManagementScreenV2State extends ConsumerState<CustomerManagementScreenV2> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _isAscending = true;
  int _pageSize = 10;
  int _currentPage = 0;
  bool _isLoading = false;
  String? _companyCountry;
  String get _taxWord => isIndiaCountry(_companyCountry)
      ? AppLocalizations.of(context)!.taxWordGst
      : AppLocalizations.of(context)!.taxWordTax;
  Map<String, double> _outstandingByCustomer = {};
  String _outstandingCurrencySymbol = '';
  List<String> _outstandingCurrencies = [];
  String? _selectedOutstandingCurrency;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _horizontalScrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── V2 state ──────────────────────────────────────────────────────────
  int _activeTabV2 = 0; // 0 all, 1 businesses, 2 individuals, 3 gst reg, 4 without gst
  bool _showAddPanelV2 = false;
  bool _addAnotherAfterSavingV2 = false;
  bool _showStatsCardsV2 = true;
  final Map<String, bool> _visibleColumnsV2 = {
    'phone': true,
    'email': true,
    'gstin': true,
    'address': true,
    'outstanding': true,
  };

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadStatsCardsVisibilityV2();
  }

  Future<void> _loadStatsCardsVisibilityV2() async {
    final v = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.showCustomerStatsCards);
    if (!mounted) return;
    setState(() => _showStatsCardsV2 = v != 'false');
  }

  Future<void> _toggleStatsCardsV2() async {
    final next = !_showStatsCardsV2;
    setState(() => _showStatsCardsV2 = next);
    await ref
        .read(settingsRepositoryProvider)
        .setSetting(SettingKey.showCustomerStatsCards, next.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _businessNameController.dispose();
    _searchFocusNode.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    if(!mounted) return;
    setState(() => _isLoading = true);
    try {
      if(!mounted) return;
      final customerRepo = ref.read(customerRepositoryProvider);
      final companyRepo = ref.read(companyInfoRepositoryProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final reportRepo = ref.read(reportRepositoryProvider);
      final results = await Future.wait([
        customerRepo.getAllCustomers(),
        companyRepo.getCompanyInfo(),
        settingsRepo.getCurrency(),
        reportRepo.getInvoiceCurrencies(),
      ]);
      final data = results[0] as List<Customer>;
      final company = results[1] as CompanyInfo?;
      final defaultCurrency = results[2] as CurrencyOption;
      final currencies = results[3] as List<String>;

      // Keep the user's chosen currency across a refresh; otherwise default
      // to the shop's currency if it has invoices, else the first one that does.
      final prevSelected = _selectedOutstandingCurrency;
      final String selected = prevSelected != null && currencies.contains(prevSelected)
          ? prevSelected
          : (currencies.contains(defaultCurrency.code)
              ? defaultCurrency.code
              : (currencies.isNotEmpty ? currencies.first : defaultCurrency.code));
      final outstanding = await reportRepo.getOutstandingByCustomer(currencyCode: selected);

      if(!mounted) return;
      setState(() {
        _customers = data;
        _companyCountry = company?.country;
        _outstandingCurrencies = currencies;
        _selectedOutstandingCurrency = selected;
        _outstandingByCustomer = outstanding;
        _outstandingCurrencySymbol = SupportedCurrencies.fromCode(selected).symbol;
        _filterAndSort();
      });
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.customerMgmtLoadErrorMessage(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onOutstandingCurrencyChangedV2(String code) async {
    if (!mounted || code == _selectedOutstandingCurrency) return;
    setState(() => _selectedOutstandingCurrency = code);
    final outstanding =
        await ref.read(reportRepositoryProvider).getOutstandingByCustomer(currencyCode: code);
    if (!mounted) return;
    setState(() {
      _outstandingByCustomer = outstanding;
      _outstandingCurrencySymbol = SupportedCurrencies.fromCode(code).symbol;
      _applyFilterV2();
    });
  }

  void _filterAndSort() {
    _filteredCustomers = _customers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.businessName.toLowerCase().contains(query) ||
          c.address.toLowerCase().contains(query) ||
          c.gstin.toLowerCase().contains(query);
    }).toList();

    _filteredCustomers.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'id':
          result = a.id.compareTo(b.id);
          break;
        case 'outstanding':
          result = (_outstandingByCustomer[a.id] ?? 0)
              .compareTo(_outstandingByCustomer[b.id] ?? 0);
          break;
        default:
          result = 0;
      }
      return _isAscending ? result : -result;
    });

    // Reset to first page when filtering
    _currentPage = 0;
  }

  void _changePage(int page) {
    if(!mounted) return;
    setState(() => _currentPage = page);
  }

  Future<void> _handleAddOrUpdateCustomer([Customer? customer]) async {
    if (!_formKey.currentState!.validate() || !mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      final newCustomer = Customer(
        id: customer?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gstin: _gstinController.text.trim(),
        businessName: _businessNameController.text.trim(),
      );

      if (customer == null) {
        await ref.read(customerRepositoryProvider).insertCustomer(newCustomer);
        _showSnackBar(l10n.customerMgmtAddedMessage);
      } else {
        await ref.read(customerRepositoryProvider).updateCustomer(newCustomer);
        _showSnackBar(l10n.customerMgmtUpdatedMessage);
      }

      _clearForm();
      await _loadCustomers();
    } catch (e) {
      _showSnackBar(l10n.customerMgmtSaveErrorMessage(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _gstinController.clear();
    _businessNameController.clear();
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showCustomerDialog(Customer customer, bool isEdit) async {
    //final isEdit = customer != null;
    final nameCtrl = TextEditingController(text: customer.name);
    final emailCtrl = TextEditingController(text: customer.email);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final addressCtrl = TextEditingController(text: customer.address);
    final gstinCtrl = TextEditingController(text: customer.gstin);
    final businessNameCtrl = TextEditingController(text: customer.businessName);
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit : Icons.visibility,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(isEdit
                ? AppLocalizations.of(context)!.customerMgmtEditCustomerTitle
                : AppLocalizations.of(context)!.customerMgmtViewCustomerTitle),
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
                  _buildDialogTextField(nameCtrl, AppLocalizations.of(context)!.fieldNameLabel, Icons.person,
                      readOnly: !isEdit),
                  const SizedBox(height: 16),
                  _buildDialogTextField(businessNameCtrl, AppLocalizations.of(context)!.fieldBusinessNameLabel, Icons.business_center,
                      readOnly: !isEdit, maxLength: 100),
                  const SizedBox(height: 16),
                  _buildDialogTextField(emailCtrl, AppLocalizations.of(context)!.fieldEmailLabel, Icons.email,
                      readOnly: !isEdit, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildDialogTextField(phoneCtrl, AppLocalizations.of(context)!.fieldPhoneLabel, Icons.phone,
                      readOnly: !isEdit,
                      keyboardType: TextInputType.phone,
                      maxLength: 12),
                  const SizedBox(height: 16),
                  _buildDialogTextField(gstinCtrl, AppLocalizations.of(context)!.fieldTaxVatNumberLabel(_taxWord), Icons.receipt_long,
                      readOnly: !isEdit, maxLength: 50),
                  const SizedBox(height: 16),
                  _buildDialogTextField(addressCtrl, AppLocalizations.of(context)!.fieldAddressLabel, Icons.location_on,
                      readOnly: !isEdit, maxLines: 3, maxLength: 100),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.actionClose),
          ),
          if (isEdit)
            FilledButton.icon(
              onPressed: isSaving ? null : () async {
                if (!dialogFormKey.currentState!.validate()) return;
                final l10n = AppLocalizations.of(context)!;
                setDialogState(() => isSaving = true);
                try {
                  final updatedCustomer = Customer(
                    id: customer.id,
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    gstin: gstinCtrl.text.trim(),
                    businessName: businessNameCtrl.text.trim(),
                  );

                  await ref.read(customerRepositoryProvider).updateCustomer(updatedCustomer);
                  await _loadCustomers();
                  if (context.mounted) Navigator.pop(context);
                  _showSnackBar(l10n.customerMgmtUpdatedMessage);
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              icon: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(isSaving
                  ? AppLocalizations.of(context)!.createInvoiceSavingEllipsisLabel
                  : AppLocalizations.of(context)!.actionUpdate),
            ),
        ],
        );
        });
      },
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
      }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        filled: readOnly,
        fillColor: readOnly ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
      ),
      validator: (value) {
        if (label == AppLocalizations.of(context)!.fieldNameLabel &&
            (value == null || value.trim().isEmpty)) {
          return AppLocalizations.of(context)!.fieldRequiredMessage(label);
        }
        return null;
      },
    );
  }

  Future<void> _confirmDelete(Customer customer) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.customerMgmtConfirmDeleteTitle),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.customerMgmtDeleteConfirmBody(customer.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.actionDelete),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
      await _loadCustomers();
      _showSnackBar(l10n.customerMgmtDeletedMessage);
    }
  }

  Future<void> _downloadSampleCSV() async {
    const sample = '"name","email","phone","address","business_name","tax_number"\n'
        '"John Smith","john@example.com","+27821234567","123 Main St, Cape Town","Acme (Pty) Ltd","ZA123456789"\n'
        '"Jane Doe","jane@example.com","+27831234567","456 Oak Ave, Johannesburg","",""\n';
    final l10n = AppLocalizations.of(context)!;

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: l10n.customerMgmtSaveSampleCsvDialogTitle,
      fileName: 'customers_sample.csv',
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

  static const _csvMaxRows = 200;
  static const _csvHeaders = ['name', 'email', 'phone', 'address', 'business_name', 'tax_number'];

  Future<void> _showImportDialog() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.customerMgmtImportCsvDialogTitle),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.customerMgmtCsvFormatInstructionMessage,
                ),
                const SizedBox(height: 12),
                // Columns table
                Table(
                  border: TableBorder.all(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(6)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.4),
                    1: FlexColumnWidth(0.7),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      children: [
                        _TableHeader(AppLocalizations.of(context)!.customerMgmtCsvColColumnHeader),
                        _TableHeader(AppLocalizations.of(context)!.customerMgmtCsvColRequiredHeader),
                        _TableHeader(AppLocalizations.of(context)!.customerMgmtCsvColDescriptionHeader),
                      ],
                    ),
                    _csvRuleRow(context, 'name',          AppLocalizations.of(context)!.commonYesLabel, AppLocalizations.of(context)!.customerMgmtCsvDescName, required: true),
                    _csvRuleRow(context, 'email',         AppLocalizations.of(context)!.commonNoLabel,  AppLocalizations.of(context)!.customerMgmtCsvDescEmail),
                    _csvRuleRow(context, 'phone',         AppLocalizations.of(context)!.commonNoLabel,  AppLocalizations.of(context)!.customerMgmtCsvDescPhone),
                    _csvRuleRow(context, 'address',       AppLocalizations.of(context)!.commonNoLabel,  AppLocalizations.of(context)!.customerMgmtCsvDescAddress),
                    _csvRuleRow(context, 'business_name', AppLocalizations.of(context)!.commonNoLabel,  AppLocalizations.of(context)!.customerMgmtCsvDescBusinessName),
                    _csvRuleRow(context, 'tax_number',    AppLocalizations.of(context)!.commonNoLabel,  AppLocalizations.of(context)!.customerMgmtCsvDescTaxNumber),
                  ],
                ),
                const SizedBox(height: 16),
                // Notes
                _ruleNote(context, Icons.info_outline, AppLocalizations.of(context)!.customerMgmtCsvMaxRowsNote(_csvMaxRows)),
                _ruleNote(context, Icons.info_outline, AppLocalizations.of(context)!.customerMgmtCsvDuplicatesNote),
                _ruleNote(context, Icons.info_outline, AppLocalizations.of(context)!.customerMgmtCsvMissingNameNote),
                _ruleNote(context, Icons.info_outline, AppLocalizations.of(context)!.customerMgmtCsvEncodingNote),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx, false);
                    await _downloadSampleCSV();
                  },
                  icon: const Icon(Icons.download),
                  label: Text(AppLocalizations.of(context)!.customerMgmtDownloadSampleCsvButton),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.folder_open),
            label: Text(AppLocalizations.of(context)!.customerMgmtChooseFileButton),
          ),
        ],
      ),
    );
    if (proceed == true) await _importFromCSV();
  }

  static TableRow _csvRuleRow(BuildContext context, String col, String req, String desc, {bool required = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(col, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            req,
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
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface))),
        ],
      ),
    );
  }

  Future<void> _importFromCSV() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: l10n.customerMgmtSelectCsvDialogTitle,
    );
    if (result == null || result.files.single.path == null || !mounted) return;

    setState(() => _isLoading = true);

    var progressDialogShown = false;
    try {
      final bytes = await File(result.files.single.path!).readAsBytes();
      // Strip UTF-8 BOM if present
      final content = utf8.decode(
        bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF
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
      final headers = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
      if (!headers.contains('name')) {
        _showSnackBar(l10n.customerMgmtCsvMissingNameColumnMessage, isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      for (final col in headers) {
        if (!_csvHeaders.contains(col)) {
          _showSnackBar(l10n.customerMgmtUnknownColumnMessage(col, _csvHeaders.join(', ')), isError: true);
          if(!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
      }

      final dataRows = rows.skip(1).toList();

      // Hard limit
      if (dataRows.length > _csvMaxRows) {
        _showSnackBar(l10n.customerMgmtCsvTooManyRowsMessage(dataRows.length, _csvMaxRows), isError: true);
        if(!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      String getField(List<dynamic> row, String col) {
        final i = headers.indexOf(col);
        return i < 0 || i >= row.length ? '' : row[i].toString().trim();
      }

      // Categorise rows
      final List<Customer> valid = [];
      final List<Customer> duplicates = [];
      final List<String> errors = [];

      final progress = ValueNotifier<int>(0);
      if (!mounted) return;
      progressDialogShown = true;
      unawaited(showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.customerMgmtImportingTitle),
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
        if (name.isEmpty) {
          errors.add(l10n.customerMgmtRowMissingNameMessage(i + 2));
          continue;
        }
        final email = getField(row, 'email');
        final phone = getField(row, 'phone');
        final existing = await ref.read(customerRepositoryProvider).findDuplicate(email, phone);
        final customer = Customer(
          id: existing?.id ?? const Uuid().v4(),
          name: name,
          email: email,
          phone: phone,
          address: getField(row, 'address'),
          gstin: getField(row, 'tax_number'),
          businessName: getField(row, 'business_name'),
        );
        if (existing != null) {
          duplicates.add(customer);
        } else {
          valid.add(customer);
        }
      }
      if (progressDialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if(!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      await _showImportPreviewDialog(valid, duplicates, errors);
    } catch (e) {
      if (progressDialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(l10n.customerMgmtCsvReadErrorMessage(e.toString()), isError: true);
    }
  }

  Future<void> _showImportPreviewDialog(
    List<Customer> newCustomers,
    List<Customer> duplicates,
    List<String> errors,
  ) async {
    // Per-row overwrite flags: true = overwrite, false = skip
    final overwriteFlags = List<bool>.filled(duplicates.length, false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = newCustomers.length + overwriteFlags.where((f) => f).length;

          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.customerMgmtImportPreviewTitle),
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
                          label: Text(AppLocalizations.of(context)!.customerMgmtNewCountChip(newCustomers.length)),
                          backgroundColor: Colors.green.shade100,
                          avatar: const Icon(Icons.person_add, size: 16),
                        ),
                        Chip(
                          label: Text(AppLocalizations.of(context)!.customerMgmtDuplicatesCountChip(duplicates.length)),
                          backgroundColor: Colors.orange.shade100,
                          avatar: const Icon(Icons.warning_amber, size: 16),
                        ),
                        if (errors.isNotEmpty)
                          Chip(
                            label: Text(AppLocalizations.of(context)!.customerMgmtErrorsCountChip(errors.length)),
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
                            child: Text(AppLocalizations.of(context)!.customerMgmtDuplicatesMatchedLabel,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) { overwriteFlags[i] = true; }
                            }),
                            child: Text(AppLocalizations.of(context)!.customerMgmtOverwriteAllButton),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              for (int i = 0; i < overwriteFlags.length; i++) { overwriteFlags[i] = false; }
                            }),
                            child: Text(AppLocalizations.of(context)!.customerMgmtSkipAllButton),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(duplicates.length, (i) {
                        final c = duplicates[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text('${c.name}${c.businessName.isNotEmpty ? ' — ${c.businessName}' : ''}'),
                            subtitle: Text('${c.email} · ${c.phone}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(AppLocalizations.of(context)!.actionSkip, style: const TextStyle(fontSize: 12)),
                                Switch(
                                  value: overwriteFlags[i],
                                  onChanged: (v) => setDialogState(() => overwriteFlags[i] = v),
                                ),
                                Text(AppLocalizations.of(context)!.customerMgmtOverwriteLabel, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.customerMgmtSkippedRowsLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      ...errors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(AppLocalizations.of(context)!.customerMgmtErrorBulletLabel(e),
                                style: const TextStyle(fontSize: 12, color: Colors.red)),
                          )),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.customerMgmtWillImportMessage(total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.actionCancel),
              ),
              FilledButton.icon(
                onPressed: total == 0
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _executeImport(newCustomers, duplicates, overwriteFlags);
                      },
                icon: const Icon(Icons.upload),
                label: Text(AppLocalizations.of(context)!.customerMgmtImportCountButton(total)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _executeImport(
    List<Customer> newCustomers,
    List<Customer> duplicates,
    List<bool> overwriteFlags,
  ) async {
    if(!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      if (newCustomers.isNotEmpty) {
        await ref.read(customerRepositoryProvider).insertBatch(newCustomers);
      }
      for (int i = 0; i < duplicates.length; i++) {
        if (overwriteFlags[i]) {
          await ref.read(customerRepositoryProvider).updateCustomer(duplicates[i]);
        }
      }
      await _loadCustomers();
      final imported = newCustomers.length + overwriteFlags.where((f) => f).length;
      _showSnackBar(l10n.customerMgmtImportedMessage(imported));
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(l10n.customerMgmtImportErrorMessage(e.toString()), isError: true);
    }
  }

  // ── Delete All ────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context)!;
    if (_customers.isEmpty) {
      _showSnackBar(l10n.customerMgmtNoCustomersToDeleteMessage);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.customerMgmtDeleteAllTitle),
        content: Text(
          l10n.customerMgmtDeleteAllBody(_customers.length),
        ),
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
      await ref.read(customerRepositoryProvider).deleteAllCustomers();
      await _loadCustomers();
      _showSnackBar(l10n.customerMgmtAllDeletedMessage);
    } catch (e) {
      if(!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(l10n.customerMgmtDeleteAllErrorMessage(e.toString()), isError: true);
    }
  }

  Future<void> _exportToCSV() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      List<List<String>> csvData = [
        ['name', 'email', 'phone', 'address', 'business_name', 'tax_number'],
        ..._filteredCustomers.map((c) => [
          c.name,
          c.email,
          c.phone,
          c.address,
          c.businessName,
          c.gstin,
        ]),
      ];

      final csv = buildQuotedCsv(csvData);
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.customerMgmtSaveCsvDialogTitle,
        fileName: 'customers.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (savePath == null) return;
      await File(savePath).writeAsBytes(utf8.encode('\uFEFF$csv'));
      _showSnackBar(l10n.customerMgmtCsvExportedMessage);
    } catch (e) {
      _showSnackBar(l10n.customerMgmtCsvExportErrorMessage(e.toString()), isError: true);
    }
  }

  Future<void> _exportToPDF() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final totalCount = _filteredCustomers.length;
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Customer Export - $totalCount customer${totalCount == 1 ? '' : 's'}',
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
                ['#', 'Name', 'Business Name', 'Email', 'Phone', 'Tax/VAT No', 'Address'],
                ..._filteredCustomers.indexed.map(((int, dynamic) e) => [
                      e.$1 + 1,
                      e.$2.name,
                      e.$2.businessName,
                      e.$2.email,
                      e.$2.phone,
                      e.$2.gstin,
                      e.$2.address,
                    ]),
              ],
            ),
          ],
        ),
      );

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.customerMgmtSavePdfDialogTitle,
        fileName: 'customers.pdf',
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
  // validation, and repository calls (_customers, _filterAndSort,
  // _handleAddOrUpdateCustomer, _showCustomerDialog, _confirmDelete,
  // import/export methods are all untouched). New pieces: tab-based
  // filtering layered on top of _filterAndSort, stat cards, a
  // slide-out "New Customer" panel, and a flat table.
  // ============================================================

  int get _businessesCountV2 =>
      _customers.where((c) => c.businessName.trim().isNotEmpty).length;
  int get _individualsCountV2 =>
      _customers.where((c) => c.businessName.trim().isEmpty).length;
  int get _gstRegisteredCountV2 =>
      _customers.where((c) => c.gstin.trim().isNotEmpty).length;
  int get _withoutGstCountV2 => _customers.length - _gstRegisteredCountV2;
  int get _withOutstandingCountV2 =>
      _customers.where((c) => (_outstandingByCustomer[c.id] ?? 0) > 0.005).length;

  // Runs the existing search+sort (_filterAndSort) then layers the active
  // tab's business/individual/GST filter on top of its result.
  void _applyFilterV2() {
    _filterAndSort();
    Iterable<Customer> list = _filteredCustomers;
    switch (_activeTabV2) {
      case 1:
        list = list.where((c) => c.businessName.trim().isNotEmpty);
        break;
      case 2:
        list = list.where((c) => c.businessName.trim().isEmpty);
        break;
      case 3:
        list = list.where((c) => c.gstin.trim().isNotEmpty);
        break;
      case 4:
        list = list.where((c) => c.gstin.trim().isEmpty);
        break;
      case 5:
        list = list.where((c) => (_outstandingByCustomer[c.id] ?? 0) > 0.005);
        break;
    }
    _filteredCustomers = list.toList();
  }

  void _onSearchChangedV2(String value) {
    if (!mounted) return;
    setState(() {
      _searchQuery = value;
      _applyFilterV2();
    });
  }

  void _onSortSelectionV2(String field, bool ascending) {
    if (!mounted) return;
    setState(() {
      _sortBy = field;
      _isAscending = ascending;
      _applyFilterV2();
    });
  }

  void _selectTabV2(int index) {
    if (!mounted) return;
    setState(() {
      _activeTabV2 = index;
      _currentPage = 0;
      _applyFilterV2();
    });
  }

  Future<void> _addCustomerV2() async {
    final nameBefore = _nameController.text;
    await _handleAddOrUpdateCustomer();
    final succeeded = _nameController.text.isEmpty && nameBefore.trim().isNotEmpty;
    if (succeeded) {
      if (!mounted) return;
      setState(() {
        _applyFilterV2();
        if (!_addAnotherAfterSavingV2) _showAddPanelV2 = false;
      });
    }
  }

  Future<void> _viewCustomerV2(Customer c) async {
    await _showCustomerDialog(c, false);
  }

  Future<void> _editCustomerV2(Customer c) async {
    await _showCustomerDialog(c, true);
    // _showCustomerDialog already reloads _customers + runs the plain
    // _filterAndSort internally on save; re-apply the active tab filter
    // on top so it doesn't get lost after an edit.
    if (!mounted) return;
    setState(_applyFilterV2);
  }

  Future<void> _deleteCustomerV2(Customer c) async {
    await _confirmDelete(c);
    if (!mounted) return;
    setState(_applyFilterV2);
  }

  Future<void> _receivePayment(Customer c) async {
    await showDialog(
      context: context,
      builder: (_) => ApplyCustomerPaymentDialog(
        customer: c,
        onPaymentApplied: _loadCustomers,
      ),
    );
  }

  BoxDecoration _flatCardDecorationV2(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );

  // A PopupMenuButton's `child` should stay non-interactive (PopupMenuButton
  // itself provides the tap-to-open handling) — a real OutlinedButton with
  // onPressed: null there would render as visually disabled/greyed out.
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
    required String subtitle,
    required IconData icon,
    required Color accent,
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
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
        label: AppLocalizations.of(context)!.customerMgmtTotalCustomersLabel,
        value: '${_customers.length}',
        subtitle: AppLocalizations.of(context)!.customerMgmtAllCustomersSubtitle,
        icon: Icons.groups_outlined,
        accent: Theme.of(context).primaryColor,
      ),
      _statCardV2(
        label: AppLocalizations.of(context)!.customerMgmtBusinessesLabel,
        value: '$_businessesCountV2',
        subtitle: AppLocalizations.of(context)!.customerMgmtRegisteredBusinessesSubtitle,
        icon: Icons.apartment_outlined,
        accent: Colors.green,
      ),
      _statCardV2(
        label: AppLocalizations.of(context)!.customerMgmtIndividualsLabel,
        value: '$_individualsCountV2',
        subtitle: AppLocalizations.of(context)!.customerMgmtIndividualCustomersSubtitle,
        icon: Icons.person_outline,
        accent: Colors.deepPurple,
      ),
      _statCardV2(
        label: AppLocalizations.of(context)!.customerMgmtTaxRegisteredLabel(_taxWord),
        value: '$_gstRegisteredCountV2',
        subtitle: AppLocalizations.of(context)!.customerMgmtWithTaxNumberSubtitle(_taxWord),
        icon: Icons.receipt_long_outlined,
        accent: Colors.orange,
      ),
    ];

    // Responsive: fit as many equal-width cards per row as the available
    // width allows (min ~170px each), wrapping to additional rows instead
    // of squeezing/overflowing on narrow screens.
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
              Text(AppLocalizations.of(context)!.customerMgmtTitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(AppLocalizations.of(context)!.customerMgmtSubtitle,
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
              onPressed: _showImportDialog,
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
                onSelected: (value) {
                  if (value == 'export_pdf') _exportToPDF();
                  if (value == 'delete_all') _confirmDeleteAll();
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
                        Text(AppLocalizations.of(context)!.customerMgmtDeleteAllTitle,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: _menuButtonLookV2(Icons.more_horiz, AppLocalizations.of(context)!.commonMoreLabel),
              ),
            IconButton(
              onPressed: _isLoading ? null : _loadCustomers,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              tooltip: AppLocalizations.of(context)!.actionRefresh,
            ),
            FilledButton.icon(
              onPressed: () => setState(() => _showAddPanelV2 = true),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context)!.customerMgmtNewCustomerButton),
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
      {'label': l10n.customerMgmtSortIdOldest, 'field': 'id', 'asc': true},
      {'label': l10n.customerMgmtSortIdNewest, 'field': 'id', 'asc': false},
      {'label': l10n.customerMgmtSortOutstandingHighLow, 'field': 'outstanding', 'asc': false},
      {'label': l10n.customerMgmtSortOutstandingLowHigh, 'field': 'outstanding', 'asc': true},
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
              hintText: l10n.customerMgmtSearchHint(_taxWord),
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
                tooltip: l10n.invoiceMgmtFilterLabel,
                onSelected: (value) {
                  if (!mounted) return;
                  setState(() {
                    _currentPage = 0;
                    _activeTabV2 = switch (value) {
                      'gst' => 3,
                      'no_gst' => 4,
                      _ => _activeTabV2 >= 3 ? 0 : _activeTabV2,
                    };
                    _applyFilterV2();
                  });
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'all', child: Text(l10n.customerMgmtAllTaxStatusesLabel(_taxWord))),
                  PopupMenuItem(value: 'gst', child: Text(l10n.customerMgmtTaxRegisteredLowerLabel(_taxWord))),
                  PopupMenuItem(value: 'no_gst', child: Text(l10n.customerMgmtWithoutTaxLabel(_taxWord))),
                ],
                child: _menuButtonLookV2(Icons.filter_list, l10n.invoiceMgmtFilterLabel),
              ),
              if (_outstandingCurrencies.length > 1)
                PopupMenuButton<String>(
                  tooltip: 'Outstanding currency',
                  onSelected: _onOutstandingCurrencyChangedV2,
                  itemBuilder: (ctx) => _outstandingCurrencies
                      .map((code) => PopupMenuItem(value: code, child: Text(code)))
                      .toList(),
                  child: _menuButtonLookV2(Icons.currency_exchange,
                      'Currency: ${_selectedOutstandingCurrency ?? ''}'),
                ),
              PopupMenuButton<Map<String, Object>>(
                tooltip: l10n.invoiceMgmtSortLabel,
                onSelected: (opt) =>
                    _onSortSelectionV2(opt['field'] as String, opt['asc'] as bool),
                itemBuilder: (ctx) => sortOptions
                    .map((o) => PopupMenuItem(value: o, child: Text(o['label'] as String)))
                    .toList(),
                child: _menuButtonLookV2(Icons.swap_vert, l10n.customerMgmtSortWithLabel(currentLabel)),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.customerMgmtColumnsLabel,
                onSelected: (key) {
                  if (!mounted) return;
                  setState(() =>
                      _visibleColumnsV2[key] = !(_visibleColumnsV2[key] ?? true));
                },
                itemBuilder: (ctx) => [
                  _columnMenuItemV2('phone', l10n.fieldPhoneLabel),
                  _columnMenuItemV2('email', l10n.fieldEmailLabel),
                  _columnMenuItemV2('gstin', l10n.customerMgmtTaxVatNoColumnLabel(_taxWord)),
                  _columnMenuItemV2('address', l10n.fieldAddressLabel),
                  _columnMenuItemV2('outstanding', l10n.invoiceMgmtColOutstanding),
                ],
                child: _menuButtonLookV2(Icons.view_column_outlined, l10n.customerMgmtColumnsLabel),
              ),
              IconButton(
                tooltip: _showStatsCardsV2 ? l10n.customerMgmtHideStatCardsTooltip : l10n.customerMgmtShowStatCardsTooltip,
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

  PopupMenuItem<String> _columnMenuItemV2(String key, String label) {
    final visible = _visibleColumnsV2[key] ?? true;
    return PopupMenuItem<String>(
      value: key,
      child: Row(
        children: [
          Icon(visible ? Icons.check_box : Icons.check_box_outline_blank, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
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
          foregroundColor:
              selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChipV2(AppLocalizations.of(context)!.invoiceMgmtStatusAllLabel, _customers.length, 0),
          _tabChipV2(AppLocalizations.of(context)!.customerMgmtBusinessesLabel, _businessesCountV2, 1),
          _tabChipV2(AppLocalizations.of(context)!.customerMgmtIndividualsLabel, _individualsCountV2, 2),
          _tabChipV2(AppLocalizations.of(context)!.customerMgmtTaxRegisteredLabel(_taxWord), _gstRegisteredCountV2, 3),
          _tabChipV2(AppLocalizations.of(context)!.customerMgmtWithOutstandingLabel, _withOutstandingCountV2, 5),
          _tabChipV2(AppLocalizations.of(context)!.customerMgmtWithoutTaxLabel(_taxWord), _withoutGstCountV2, 4),
        ],
      ),
    );
  }

  static const List<MaterialColor> _avatarColorsV2 = [
    Colors.blue,
    Colors.green,
    Colors.deepPurple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  Widget _avatarV2(Customer c) {
    final initials = c.name.trim().isEmpty
        ? '?'
        : c.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((s) => s.isNotEmpty ? s[0] : '')
            .join()
            .toUpperCase();
    final color = _avatarColorsV2[c.name.hashCode.abs() % _avatarColorsV2.length];
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(initials,
          style: TextStyle(color: color.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _tableRowV2(Customer c, int index) {
    final serial = _currentPage * _pageSize + index + 1;
    final outstanding = _outstandingByCustomer[c.id] ?? 0;
    final hasOutstanding = outstanding > 0.005;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
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
            child: Row(
              children: [
                _avatarV2(c),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (c.businessName.trim().isNotEmpty)
                        Text(c.businessName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_visibleColumnsV2['phone'] ?? true)
            Expanded(
              flex: 2,
              child: Text(c.phone.isEmpty ? '—' : c.phone),
            ),
          if (_visibleColumnsV2['email'] ?? true)
            Expanded(
              flex: 3,
              child: Text(c.email.isEmpty ? '—' : c.email,
                  overflow: TextOverflow.ellipsis),
            ),
          if (_visibleColumnsV2['gstin'] ?? true)
            Expanded(
              flex: 2,
              child: Text(c.gstin.isEmpty ? '—' : c.gstin,
                  overflow: TextOverflow.ellipsis),
            ),
          if (_visibleColumnsV2['address'] ?? true)
            Expanded(
              flex: 3,
              child: Text(c.address.isEmpty ? '—' : c.address,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          if (_visibleColumnsV2['outstanding'] ?? true)
            Expanded(
              flex: 2,
              child: Text(
                hasOutstanding
                    ? '$_outstandingCurrencySymbol ${outstanding.toStringAsFixed(2)}'
                    : '—',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: hasOutstanding ? FontWeight.w600 : FontWeight.normal,
                    color: hasOutstanding
                        ? Colors.orange.shade800
                        : Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _viewCustomerV2(c),
                  tooltip: AppLocalizations.of(context)!.actionView,
                ),
                if (widget.onViewCustomerStatement != null)
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.onViewCustomerStatement!(c),
                    tooltip: AppLocalizations.of(context)!.customerMgmtViewStatementTooltip,
                  ),
                IconButton(
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _receivePayment(c),
                  tooltip: 'Receive Payment',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editCustomerV2(c),
                  tooltip: AppLocalizations.of(context)!.actionEdit,
                ),
                if (widget.user.isAdmin())
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _deleteCustomerV2(c),
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
          SizedBox(
              width: 56,
              child: Text(AppLocalizations.of(context)!.customerMgmtColSlNo,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          Expanded(flex: 3, child: Text(AppLocalizations.of(context)!.customerMgmtColNameBusiness, style: style)),
          if (_visibleColumnsV2['phone'] ?? true)
            Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.customerMgmtColPhone, style: style)),
          if (_visibleColumnsV2['email'] ?? true)
            Expanded(flex: 3, child: Text(AppLocalizations.of(context)!.customerMgmtColEmail, style: style)),
          if (_visibleColumnsV2['gstin'] ?? true)
            Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.customerMgmtColTaxVatNo(_taxWord.toUpperCase()), style: style)),
          if (_visibleColumnsV2['address'] ?? true)
            Expanded(flex: 3, child: Text(AppLocalizations.of(context)!.customerMgmtColAddress, style: style)),
          if (_visibleColumnsV2['outstanding'] ?? true)
            Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.invoiceMgmtColOutstanding.toUpperCase(), style: style)),
          SizedBox(width: 200, child: Text(AppLocalizations.of(context)!.customerMgmtColActions, style: style)),
        ],
      ),
    );
  }

  Widget _paginationV2(List<Customer> pageItems, int totalPages) {
    final total = _filteredCustomers.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      // A plain Row with no Expanded/Wrap will overflow horizontally on a
      // narrow table. A horizontally-scrolling Row keeps this bar's height
      // constant and never overflows regardless of how narrow it gets.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Text(
            AppLocalizations.of(context)!.customerMgmtShowingRangeLabel(
                total == 0 ? 0 : _currentPage * _pageSize + 1,
                (_currentPage * _pageSize + _pageSize).clamp(0, total),
                total),
            style: TextStyle(
                fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              Text(AppLocalizations.of(context)!.customerMgmtRowsPerPageLabel,
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
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
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
              Text(AppLocalizations.of(context)!.customerMgmtOfTotalPagesLabel(totalPages),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              IconButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => _changePage(_currentPage + 1)
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

  // This widget sizes itself naturally instead of relying on `Expanded` to
  // fill whatever space a bounded ancestor gives it — the page itself is a
  // CustomScrollView (see _buildV2), so the list here is shrink-wrapped
  // (its own scrolling disabled) and the page just scrolls further if the
  // natural content (header + rows + pagination) doesn't fit the viewport.
  Widget _tableSectionV2() {
    final totalPages =
        _filteredCustomers.isEmpty ? 1 : (_filteredCustomers.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredCustomers.length);
    final pageItems = start < end ? _filteredCustomers.sublist(start, end) : <Customer>[];

    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tableHeaderRowV2(),
          _isLoading && _customers.isEmpty
              ? const SizedBox(
                  height: 240, child: Center(child: CircularProgressIndicator()))
              : pageItems.isEmpty
                  ? SizedBox(height: 240, child: _buildEmptyState())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) => _tableRowV2(pageItems[index], index),
                    ),
          _paginationV2(pageItems, totalPages),
        ],
      ),
    );
  }

  // ── Slide-out "New Customer" panel ──────────────────────────────────
  // The customer model only has these six fields — there's no secondary
  // "advanced" data set the way products have metadata/discount/tax, so
  // this is a single section rather than a tabbed panel.

  Widget _addPanelV2() {
    // Width is now controlled by the Positioned wrapper in _buildV2 (scales
    // with the window, capped between 520–680px, full width on narrow
    // screens), so this no longer hardcodes its own width.
    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.customerMgmtNewCustomerButton,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(_nameController, AppLocalizations.of(context)!.fieldNameLabel, Icons.person, true,
                          maxLength: 50),
                      const SizedBox(height: 16),
                      _buildFormField(_businessNameController, AppLocalizations.of(context)!.fieldBusinessNameLabel,
                          Icons.business_center, false,
                          maxLength: 100),
                      const SizedBox(height: 16),
                      _buildFormField(_phoneController, AppLocalizations.of(context)!.fieldPhoneLabel, Icons.phone, true,
                          keyboardType: TextInputType.phone, maxLength: 12),
                      const SizedBox(height: 16),
                      _buildFormField(_emailController, AppLocalizations.of(context)!.fieldEmailLabel, Icons.email, false,
                          maxLength: 100, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildFormField(_gstinController, AppLocalizations.of(context)!.fieldTaxVatNumberLabel(_taxWord),
                          Icons.receipt_long, false,
                          maxLength: 50),
                      const SizedBox(height: 16),
                      _buildFormField(_addressController, AppLocalizations.of(context)!.fieldAddressLabel, Icons.location_on,
                          false,
                          maxLines: 3, maxLength: 500),
                    ],
                  ),
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
                      onChanged: (v) =>
                          setState(() => _addAnotherAfterSavingV2 = v ?? false),
                    ),
                    Expanded(child: Text(AppLocalizations.of(context)!.customerMgmtAddAnotherLabel)),
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
                        child: Text(AppLocalizations.of(context)!.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _addCustomerV2,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(AppLocalizations.of(context)!.customerMgmtSaveCustomerButton),
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

  Widget _buildV2(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Add/Edit panel width: was a flat 400px, squeezed into a Row
            // next to the main content (which could force the main
            // content's Expanded to near-zero on narrow windows). Now the
            // panel floats as an overlay instead, so it never steals width
            // from the table, and its own width scales a bit with the
            // window on large screens (capped so it doesn't get unwieldy)
            // while dropping to full width (minus margins) on narrow ones.
            final panelWidth = constraints.maxWidth < 750
                ? constraints.maxWidth - 32
                : (constraints.maxWidth * 0.42).clamp(520.0, 680.0);

            return Stack(
              children: [
                // The table section no longer relies on `Expanded` to fill
                // leftover space — it sizes itself naturally (header row +
                // actual row heights + pagination row), and sits in a plain
                // SliverToBoxAdapter below the rest of the page's content,
                // inside this CustomScrollView. Nothing here is forced into
                // a box smaller than it needs, so there's nothing to
                // overflow: if the natural content is taller than the
                // visible viewport, the page scrolls further to show it,
                // and if it fits (only a couple of customers), it fits with
                // no extra scrolling.
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                    width: panelWidth,
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

  Widget _buildFormField(
      TextEditingController controller,
      String label,
      IconData icon,
      bool required, {
        int maxLines = 1,
        int? maxLength,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        counterText: '',
      ),
      validator: required
          ? (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context)!.fieldRequiredMessage(label);
        }
        return null;
      }
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.createInvoiceNoCustomersFoundMessage,
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? AppLocalizations.of(context)!.customerMgmtAddFirstCustomerSubtitle
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
