import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/common.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/screens/backup_management_screen.dart';
import 'package:invoiso/screens/invoice_settings_screen.dart';
import 'package:invoiso/screens/pdf_settings_screen.dart';
import 'package:invoiso/screens/user_management_screen.dart';
import '../invoisoColors.dart';
import '../models/company_info.dart';
import '../models/user.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

class SettingsScreen extends StatefulWidget {
  final User currentUser;
  const SettingsScreen({super.key, required this.currentUser});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();
  final gstinController = TextEditingController();
  String _selectedCountry = 'India';
  int _companyInfoLoadCount = 0; // incremented once when DB data arrives; forces Autocomplete reinit
  final List<({TextEditingController label, TextEditingController id})>
      _upiControllers = [];
  int? _defaultUpiIndex;

  final List<({
    TextEditingController label,
    TextEditingController bankName,
    TextEditingController accountNumber,
    TextEditingController ifscCode,
  })> _bankControllers = [];
  int? _defaultBankIndex;

  CompanyInfo? _companyInfo;
  bool _showUpiQr = false;
  bool _showBankDetails = false;
  BusinessType _businessType = BusinessType.both;

  // Update check state
  UpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;
  bool _updateCheckFailed = false;

  File? _selectedLogoFile;
  String? _base64Logo;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
    _loadCachedUpdateInfo();
  }

  Future<void> _loadCachedUpdateInfo() async {
    final cached = await SettingsService.getSetting(SettingKey.lastKnownLatestVersion);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _updateInfo = UpdateInfo(latestVersion: cached, currentVersion: AppConfig.version);
      });
    }
  }

  Future<void> _checkForUpdatesNow() async {
    if (_isCheckingUpdate) return;
    setState(() {
      _isCheckingUpdate = true;
      _updateCheckFailed = false;
    });
    final info = await UpdateService.checkForUpdate(force: true);
    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = false;
      if (info != null) {
        _updateInfo = info;
        _updateCheckFailed = false;
      } else {
        _updateCheckFailed = true;
      }
    });
  }

  Future<void> _loadCompanyInfo() async {
    final info = await CompanyInfoService.getCompanyInfo();
    final base64Logo = await SettingsService.getCompanyLogo();
    final upiEntries = await SettingsService.getUpiIds();
    final bankEntries = await SettingsService.getBankAccounts();
    final showQrStr = await SettingsService.getSetting(SettingKey.showUpiQr);
    final showBankDetails = await SettingsService.getShowBankDetails();
    final businessType = await SettingsService.getBusinessType();
    if (info != null) {
      setState(() {
        _companyInfo = info;
        nameController.text = info.name;
        addressController.text = info.address;
        phoneController.text = info.phone;
        emailController.text = info.email;
        websiteController.text = info.website;
        gstinController.text = info.gstin;
        _selectedCountry = info.country.isEmpty ? 'India' : info.country;
        _companyInfoLoadCount++;
        _showUpiQr = showQrStr == 'true';
        _showBankDetails = showBankDetails;
        _businessType = businessType;
        if (base64Logo != null && base64Logo.isNotEmpty) {
          _base64Logo = base64Logo;
        }
        for (final row in _upiControllers) {
          row.label.dispose();
          row.id.dispose();
        }
        _upiControllers.clear();
        _defaultUpiIndex = null;
        for (int i = 0; i < upiEntries.length; i++) {
          final entry = upiEntries[i];
          _upiControllers.add((
            label: TextEditingController(text: entry.label),
            id: TextEditingController(text: entry.id),
          ));
          if (entry.isDefault) _defaultUpiIndex = i;
        }

        for (final row in _bankControllers) {
          row.label.dispose();
          row.bankName.dispose();
          row.accountNumber.dispose();
          row.ifscCode.dispose();
        }
        _bankControllers.clear();
        _defaultBankIndex = null;
        for (int i = 0; i < bankEntries.length; i++) {
          final e = bankEntries[i];
          _bankControllers.add((
            label: TextEditingController(text: e.label),
            bankName: TextEditingController(text: e.bankName),
            accountNumber: TextEditingController(text: e.accountNumber),
            ifscCode: TextEditingController(text: e.ifscCode),
          ));
          if (e.isDefault) _defaultBankIndex = i;
        }
      });
    }
  }

  Future<void> _saveCompanyInfo() async {
    final newInfo = CompanyInfo(
        id: _companyInfo?.id,
        name: nameController.text,
        address: addressController.text,
        phone: phoneController.text,
        email: emailController.text,
        website: websiteController.text,
        gstin: gstinController.text,
        country: _selectedCountry);

    if (_companyInfo == null) {
      await CompanyInfoService.insertCompanyInfo(newInfo);
    } else {
      await CompanyInfoService.updateCompanyInfo(newInfo);
    }

    if (_base64Logo != null) {
      await SettingsService.setCompanyLogo(_base64Logo!);
    }

    final upiEntries = <UpiEntry>[];
    for (int i = 0; i < _upiControllers.length; i++) {
      final id = _upiControllers[i].id.text.trim();
      if (id.isEmpty) continue;
      upiEntries.add(UpiEntry(
        label: _upiControllers[i].label.text.trim(),
        id: id,
        isDefault: i == _defaultUpiIndex,
      ));
    }
    await SettingsService.setUpiIds(upiEntries);
    await SettingsService.setSetting(
        SettingKey.showUpiQr, _showUpiQr.toString());

    final bankAccounts = <BankAccount>[];
    for (int i = 0; i < _bankControllers.length; i++) {
      final accountNum = _bankControllers[i].accountNumber.text.trim();
      if (accountNum.isEmpty) continue;
      bankAccounts.add(BankAccount(
        label: _bankControllers[i].label.text.trim(),
        bankName: _bankControllers[i].bankName.text.trim(),
        accountNumber: accountNum,
        ifscCode: _bankControllers[i].ifscCode.text.trim(),
        isDefault: i == _defaultBankIndex,
      ));
    }
    await SettingsService.setBankAccounts(bankAccounts);
    await SettingsService.setShowBankDetails(_showBankDetails);

    await SettingsService.setBusinessType(_businessType);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company info saved successfully')),
    );

    setState(() {
      _companyInfo = newInfo;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    gstinController.dispose();
    for (final row in _upiControllers) {
      row.label.dispose();
      row.id.dispose();
    }
    for (final row in _bankControllers) {
      row.label.dispose();
      row.bankName.dispose();
      row.accountNumber.dispose();
      row.ifscCode.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    // Validate file size (2MB limit)
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image file must be less than 2 MB.')),
        );
      }
      return;
    }

    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image file.')),
      );
      return;
    }

    // Validate dimensions
    if (decodedImage.width > 512 || decodedImage.height > 512) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be max 512x512 pixels.')),
      );
      return;
    }

    setState(() {
      _selectedLogoFile = file;
      _base64Logo = base64Encode(bytes);
    });
  }

  Widget _buildCompanyInfoForm() {
    final primaryColor = Theme.of(context).primaryColor;

    final logoContent = _selectedLogoFile != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            child: Image.file(_selectedLogoFile!, fit: BoxFit.contain),
          )
        : (_base64Logo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                child: Image.memory(base64Decode(_base64Logo!),
                    fit: BoxFit.contain),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined,
                        size: 36, color: primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Text('Upload Logo',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: AppFontSize.small,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Click to browse',
                      style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: AppFontSize.xsmall)),
                ],
              ));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Company Information'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left panel ──────────────────────────────────────────────
          SizedBox(
            width: 240,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _sectionLabel('COMPANY LOGO'),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickLogo,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  border: Border.all(
                                      color: Colors.grey[300]!, width: 2),
                                  borderRadius: BorderRadius.circular(
                                      AppBorderRadius.xsmall),
                                ),
                                child: logoContent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Live company name preview
                          ValueListenableBuilder(
                            valueListenable: nameController,
                            builder: (_, value, __) {
                              final name = value.text.trim();
                              if (name.isEmpty) return const SizedBox.shrink();
                              return Text(
                                name,
                                style: const TextStyle(
                                  fontSize: AppFontSize.large,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Max 512×512 px · 2 MB\nPNG or JPG only',
                            style: TextStyle(
                              fontSize: AppFontSize.xsmall,
                              color: CompanyInfoScreenColors.sectionHeadingColor,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Save button pinned at bottom
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveCompanyInfo,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.small),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          VerticalDivider(width: 1, color: Colors.grey[200]),

          // ── Right: scrollable form ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  _sectionLabel('COMPANY DETAILS'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: nameController,
                          label: 'Company Name',
                          icon: Icons.business_rounded,
                          maxLength: 50,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: gstinController,
                          label: _selectedCountry == 'India' || _selectedCountry.isEmpty
                              ? 'GSTIN'
                              : 'Tax/VAT No',
                          icon: Icons.receipt_long_rounded,
                          maxLength: 50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildCountryField()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: phoneController,
                          label: 'Phone',
                          icon: Icons.phone_rounded,
                          maxLength: 60,
                          keyboardType: TextInputType.phone,
                          hint: '+91 9876543210',
                          helper: 'Multiple numbers: separate with comma',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\s\-()\,]')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.email_rounded,
                          maxLength: 100,
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9@._\-]')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: websiteController,
                    label: 'Website',
                    icon: Icons.language_rounded,
                    maxLength: 100,
                    keyboardType: TextInputType.url,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9:/.%-]')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: addressController,
                    label: 'Address',
                    icon: Icons.location_on_rounded,
                    maxLength: 100,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  _sectionLabel('BUSINESS TYPE'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category_outlined, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 12),
                            const Text('Business Type', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Controls item type options in the product list and invoices',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<BusinessType>(
                          segments: const [
                            ButtonSegment(
                              value: BusinessType.product,
                              label: Text('Product'),
                              icon: Icon(Icons.inventory_2_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: BusinessType.service,
                              label: Text('Service'),
                              icon: Icon(Icons.design_services_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: BusinessType.both,
                              label: Text('Both'),
                              icon: Icon(Icons.all_inclusive, size: 16),
                            ),
                          ],
                          selected: {_businessType},
                          onSelectionChanged: (val) =>
                              setState(() => _businessType = val.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _sectionLabel('PAYMENT SETTINGS'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.xsmall),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: SwitchListTile(
                      title: const Text('Show QR Code on Invoices'),
                      subtitle: const Text(
                        'Adds scannable UPI payment QR codes to generated PDFs',
                        style: TextStyle(fontSize: AppFontSize.small),
                      ),
                      value: _showUpiQr,
                      onChanged: (val) => setState(() => _showUpiQr = val),
                      activeColor: primaryColor,
                      secondary: Icon(
                        Icons.payment_rounded,
                        color: _showUpiQr ? primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('UPI ACCOUNTS'),
                  const SizedBox(height: 10),
                  ..._upiControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final isDefault = index == _defaultUpiIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          // Default star
                          Tooltip(
                            message: isDefault ? 'Default' : 'Set as Default',
                            child: IconButton(
                              icon: Icon(
                                isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isDefault ? Colors.amber[700] : Colors.grey[400],
                              ),
                              onPressed: () => setState(() => _defaultUpiIndex = index),
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: _buildField(
                              controller: row.label,
                              label: 'Label',
                              icon: Icons.label_outline_rounded,
                              hint: 'e.g. HDFC Bank',
                              maxLength: 40,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: row.id,
                              label: 'UPI ID',
                              icon: Icons.qr_code_rounded,
                              hint: 'yourname@bankname',
                              maxLength: 100,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _upiControllers[index].label.dispose();
                                _upiControllers[index].id.dispose();
                                _upiControllers.removeAt(index);
                                if (_defaultUpiIndex == index) {
                                  _defaultUpiIndex = null;
                                } else if (_defaultUpiIndex != null &&
                                    _defaultUpiIndex! > index) {
                                  _defaultUpiIndex = _defaultUpiIndex! - 1;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _upiControllers.add((
                            label: TextEditingController(),
                            id: TextEditingController(),
                          ));
                        });
                      },
                      icon: Icon(Icons.add_circle_outline,
                          color: primaryColor, size: 18),
                      label: Text('Add UPI Account',
                          style: TextStyle(color: primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Bank Details ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: SwitchListTile(
                      title: const Text('Show Bank Details on Invoices'),
                      subtitle: const Text(
                        'Prints bank account details on generated PDFs',
                        style: TextStyle(fontSize: AppFontSize.small),
                      ),
                      value: _showBankDetails,
                      onChanged: (val) => setState(() => _showBankDetails = val),
                      activeColor: primaryColor,
                      secondary: Icon(
                        Icons.account_balance_outlined,
                        color: _showBankDetails ? primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('BANK ACCOUNTS'),
                  const SizedBox(height: 10),
                  ..._bankControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final isDefault = index == _defaultBankIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Default star
                          Tooltip(
                            message: isDefault ? 'Default' : 'Set as Default',
                            child: IconButton(
                              icon: Icon(
                                isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isDefault ? Colors.amber[700] : Colors.grey[400],
                              ),
                              onPressed: () => setState(() => _defaultBankIndex = index),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: _buildField(
                              controller: row.label,
                              label: 'Label',
                              icon: Icons.label_outline_rounded,
                              hint: 'e.g. Main Account',
                              maxLength: 40,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 140,
                            child: _buildField(
                              controller: row.bankName,
                              label: 'Bank Name',
                              icon: Icons.account_balance_outlined,
                              hint: 'e.g. HDFC Bank',
                              maxLength: 60,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              controller: row.accountNumber,
                              label: 'Account Number',
                              icon: Icons.numbers_outlined,
                              hint: '123456789012',
                              maxLength: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 130,
                            child: _buildField(
                              controller: row.ifscCode,
                              label: 'IFSC Code',
                              icon: Icons.code_outlined,
                              hint: 'HDFC0001234',
                              maxLength: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _bankControllers[index].label.dispose();
                                _bankControllers[index].bankName.dispose();
                                _bankControllers[index].accountNumber.dispose();
                                _bankControllers[index].ifscCode.dispose();
                                _bankControllers.removeAt(index);
                                if (_defaultBankIndex == index) {
                                  _defaultBankIndex = null;
                                } else if (_defaultBankIndex != null &&
                                    _defaultBankIndex! > index) {
                                  _defaultBankIndex = _defaultBankIndex! - 1;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _bankControllers.add((
                            label: TextEditingController(),
                            bankName: TextEditingController(),
                            accountNumber: TextEditingController(),
                            ifscCode: TextEditingController(),
                          ));
                        });
                      },
                      icon: Icon(Icons.add_circle_outline,
                          color: primaryColor, size: 18),
                      label: Text('Add Bank Account',
                          style: TextStyle(color: primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoScreen() {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Software Information'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero card ────────────────────────────────────────────
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 130,
                          height: 52,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConfig.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: AppFontSize.xxlarge,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppConfig.description,
                                style: TextStyle(
                                  fontSize: AppFontSize.small,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            AppConfig.version,
                            style: TextStyle(
                              fontSize: AppFontSize.medium,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Two info cards ───────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _infoCard('APP DETAILS', [
                        _infoRow(Icons.apps_rounded, 'App Name',
                            AppConfig.name.toUpperCase()),
                        _infoRow(Icons.tag_rounded, 'Version',
                            AppConfig.version),
                        _infoRow(Icons.gavel_rounded, 'License',
                            AppConfig.license.toUpperCase()),
                      ]),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _infoCard('DEVELOPER', [
                        _infoRow(Icons.person_rounded, 'Developer',
                            AppConfig.developer.toUpperCase()),
                        _infoRow(Icons.email_rounded, 'Support Email',
                            AppConfig.supportEmail),
                        _infoRow(Icons.language_rounded, 'Website',
                            AppConfig.website),
                      ]),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Update card ──────────────────────────────────────────
                _buildUpdateCard(),

                const SizedBox(height: 32),

                // ── Footer ───────────────────────────────────────────────
                Text(
                  '© ${DateTime.now().year} ${AppConfig.developer}  |  Released under the ${AppConfig.license} License',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard() {
    final primaryColor = Theme.of(context).primaryColor;
    final info = _updateInfo;
    final hasUpdate = info != null && info.hasUpdate;
    final isUpToDate = info != null && !info.hasUpdate;

    Widget statusBadge;
    if (_isCheckingUpdate) {
      statusBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
          ),
          const SizedBox(width: 8),
          Text('Checking...', style: TextStyle(fontSize: AppFontSize.xsmall, color: primaryColor)),
        ],
      );
    } else if (hasUpdate) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Text(
          'Update Available',
          style: TextStyle(fontSize: AppFontSize.xsmall, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
        ),
      );
    } else if (isUpToDate) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Text(
          'Up to date',
          style: TextStyle(fontSize: AppFontSize.xsmall, color: Colors.green.shade700, fontWeight: FontWeight.w600),
        ),
      );
    } else if (_updateCheckFailed) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Check failed',
          style: TextStyle(fontSize: AppFontSize.xsmall, color: Colors.red.shade600, fontWeight: FontWeight.w600),
        ),
      );
    } else {
      statusBadge = const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'UPDATES',
                  style: TextStyle(
                    fontSize: AppFontSize.xsmall,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                statusBadge,
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.tag_rounded, size: 18, color: Colors.grey[400]),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Version',
                              style: TextStyle(fontSize: AppFontSize.xsmall, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          const SizedBox(height: 3),
                          Text(AppConfig.version,
                              style: const TextStyle(fontSize: AppFontSize.medium, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (info != null) ...[
                        const SizedBox(width: 32),
                        Icon(Icons.new_releases_outlined, size: 18, color: hasUpdate ? Colors.orange.shade400 : Colors.grey[400]),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Latest Version',
                                style: TextStyle(fontSize: AppFontSize.xsmall, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(
                              info.latestVersion,
                              style: TextStyle(
                                fontSize: AppFontSize.medium,
                                fontWeight: FontWeight.w600,
                                color: hasUpdate ? Colors.orange.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isCheckingUpdate ? null : _checkForUpdatesNow,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Check Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                      ),
                    ),
                    if (hasUpdate) ...[
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: primaryColor),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download'),
                        onPressed: () => launchUrl(
                          Uri.parse('https://invoiso.co.in/download.html'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: AppFontSize.xsmall,
                fontWeight: FontWeight.w700,
                color: Colors.grey[400],
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            ...rows.expand((row) => [
                  row,
                  Divider(height: 1, color: Colors.grey[100]),
                ]).toList()
              ..removeLast(),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSize.xsmall,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: AppFontSize.medium,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppFontSize.xsmall,
        fontWeight: FontWeight.w600,
        color: CompanyInfoScreenColors.sectionHeadingColor,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCountryField() {
    final primaryColor = Theme.of(context).primaryColor;
    return Autocomplete<String>(
      key: ValueKey(_companyInfoLoadCount),
      initialValue: TextEditingValue(text: _selectedCountry),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return AppCountries.all;
        return AppCountries.all.where(
          (c) => c.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: (String country) {
        setState(() => _selectedCountry = country);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: AppFontSize.medium),
          decoration: InputDecoration(
            labelText: 'Country',
            prefixIcon: const Icon(Icons.public_rounded, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final country = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(country, style: const TextStyle(fontSize: AppFontSize.medium)),
                    onTap: () => onSelected(country),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLength = 100,
    int maxLines = 1,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(fontSize: AppFontSize.medium),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, size: 20),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
      ),
    );
  }

  Widget _buildDummySection(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_circle_outline, size: 64, color: Colors.blueGrey),
              AppSpacing.hMedium,
              Text("Options coming soon...", style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildCompanyInfoForm();
      case 1:
        return BackupManagementScreen();
      case 2:
        return UserManagementScreen(
          currentUser: widget.currentUser,
        );
      case 3:
        return PdfSettingsScreen();
      case 4:
        return InvoiceSettingsScreen();
      case 5:
        return _buildAppInfoScreen();
      default:
        return _buildDummySection("Invoice Settings");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin()) {
      return _buildAppInfoScreen();
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('Company Info'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.backup),
                label: Text('Backup'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('PDF Settings'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.file_present),
                label: Text('Invoice Settings'),
              ),
              NavigationRailDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.info_outline),
                    if (_updateInfo?.hasUpdate == true)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: const Text('Software Info'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
