import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/company_info_service.dart';
import 'package:invoiso/database/settings_service.dart';
import 'package:invoiso/screens/backup_management_screen.dart';
import 'package:invoiso/screens/pdf_settings_screen.dart';
import 'package:invoiso/screens/user_management_screen.dart';
import '../database/database_helper.dart';
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

  CompanyInfo? _companyInfo;

  File? _selectedLogoFile;
  String? _base64Logo;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    final info = await CompanyInfoService.getCompanyInfo();
    if (info != null)
    {
      final base64Logo = await SettingsService.getCompanyLogo();
      setState(() {
        _companyInfo = info;
        nameController.text = info.name;
        addressController.text = info.address;
        phoneController.text = info.phone;
        emailController.text = info.email;
        websiteController.text = info.website;
        gstinController.text = info.gstin;
        if (base64Logo != null && base64Logo.isNotEmpty) {
          setState(() {
            _base64Logo = base64Logo;
          });
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
      gstin: gstinController.text
    );

    if (_companyInfo == null) {
      await CompanyInfoService.insertCompanyInfo(newInfo);
    } else {
      await CompanyInfoService.updateCompanyInfo(newInfo);
    }

    if (_base64Logo != null) {
      await SettingsService.setCompanyLogo(_base64Logo!);
    }

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
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image file.')),
      );
      return;
    }

    // Validate dimensions
    if (decodedImage.width > 512 || decodedImage.height > 512) {
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
    final logoWidget = _selectedLogoFile != null
        ? ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(_selectedLogoFile!, fit: BoxFit.contain),
    )
        : (_base64Logo != null
        ? ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(base64Decode(_base64Logo!), fit: BoxFit.contain),
    )
        : Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Upload Logo',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Click to browse',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    ));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Company Information'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo Section
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Company Logo',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
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
                                    color: Colors.grey[300]!,
                                    width: 2,
                                    strokeAlign: BorderSide.strokeAlignInside,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: logoWidget,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Company Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Two Column Form
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldWidth = constraints.maxWidth / 2 - 12;
                        return Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: nameController,
                                style: const TextStyle(fontSize: 16),
                                maxLength: 50,
                                decoration: InputDecoration(
                                  labelText: 'Company Name',
                                  prefixIcon: const Icon(Icons.business, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: gstinController,
                                style: const TextStyle(fontSize: 16),
                                maxLength: 50,
                                decoration: InputDecoration(
                                  labelText: 'GSTIN',
                                  prefixIcon: const Icon(Icons.receipt_long, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: phoneController,
                                maxLength: 12,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Phone',
                                  prefixIcon: const Icon(Icons.phone, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(12),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: emailController,
                                maxLength: 100,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9@._\-]')),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: websiteController,
                                maxLength: 100,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Website',
                                  prefixIcon: const Icon(Icons.language, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                                keyboardType: TextInputType.url,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9:/.%-]')),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextField(
                                controller: addressController,
                                style: const TextStyle(fontSize: 16),
                                maxLength: 100,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(bottom: 48),
                                    child: Icon(Icons.location_on, size: 20),
                                  ),
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveCompanyInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Company Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Application Information'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                          //const SizedBox(height: 8),
                          Text(
                            'Version & License Information',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Application Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Three Column Info Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldWidth = (constraints.maxWidth - 48) / 3;
                        return Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            _infoTile(
                              'App Name',
                              AppConfig.name.toUpperCase(),
                              fieldWidth,
                              Icons.apps,
                            ),
                            _infoTile(
                              'Version',
                              AppConfig.version,
                              fieldWidth,
                              Icons.numbers,
                            ),
                            _infoTile(
                              'Developer',
                              AppConfig.developer.toUpperCase(),
                              fieldWidth,
                              Icons.code,
                            ),
                            _infoTile(
                              'Contact Email',
                              AppConfig.supportEmail,
                              fieldWidth,
                              Icons.email_outlined,
                            ),
                            _infoTile(
                              'Website',
                              AppConfig.website,
                              fieldWidth,
                              Icons.language,
                            ),
                            _infoTile(
                              'License',
                              AppConfig.license.toUpperCase(),
                              fieldWidth,
                              Icons.gavel,
                            ),
                            _infoTile(
                              'Description',
                              AppConfig.description,
                              constraints.maxWidth,
                              Icons.description_outlined,
                              maxLines: 3,
                              isFullWidth: true,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Footer Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This information is read-only and configured in the application settings.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(
      String label,
      String value,
      double width,
      IconData icon, {
        int maxLines = 1,
        bool isFullWidth = false,
      }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SelectableText(
                value,
                style: TextStyle(
                  fontSize: isFullWidth ? 15 : 16,
                  color: Colors.grey[800],
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: maxLines,
              ),
            ),
          ],
        ),
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
        return UserManagementScreen(currentUser: widget.currentUser,);
      case 3:
        return PdfSettingsScreen();
      case 4:
        return _buildDummySection("Invoice Settings");
      case 5:
        return _buildAppInfoScreen() ;
      default:
        return _buildDummySection("Invoice Settings");
    }
  }

  @override
  Widget build(BuildContext context) {
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
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('Company Info'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.backup),
                label: Text('Backup'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('PDF Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.file_present),
                label: Text('Invoice Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info_outline),
                label: Text('Software Info'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent()
            // Scaffold(
            //   appBar: AppBar(title: const Text("Settings")),
            //   body: _buildContent(),
            //),
          ),
        ],
      ),
    );
  }
}
