import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
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
  final dbHelper = DatabaseHelper();

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
    final info = await dbHelper.getCompanyInfo();
    if (info != null)
    {
      final base64Logo = await dbHelper.getCompanyLogo();
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
      await dbHelper.insertCompanyInfo(newInfo);
    } else {
      await dbHelper.updateCompanyInfo(newInfo);
    }

    if (_base64Logo != null) {
      await dbHelper.setCompanyLogo(_base64Logo!);
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


  Widget _buildCompanyInfoForm()
  {
    final logoWidget = _selectedLogoFile != null
        ? Image.file(_selectedLogoFile!, fit: BoxFit.contain)
        : (_base64Logo != null
        ? Image.memory(base64Decode(_base64Logo!), fit: BoxFit.contain)
        : const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Select Logo', style: TextStyle(color: Colors.grey)),
        ],
      ),
    ));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Info'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            color: Colors.white,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width*0.3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 230,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    AppSpacing.hXlarge,
                    TextField(
                      controller: nameController,
                      style: TextStyle(fontSize: 18),
                      maxLength: 50,
                      decoration: const InputDecoration(labelText: 'Company Name',),
                    ),
                    AppSpacing.hLarge,
                    TextField(
                      controller: addressController,
                      style: TextStyle(fontSize: 18),
                      maxLength: 100,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 3,
                    ),
                    AppSpacing.hLarge,
                    TextField(
                      controller: phoneController,
                      maxLength: 12,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                    ),
                    AppSpacing.hLarge,
                    TextField(
                      controller: emailController,
                      maxLength: 100,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._\-]')),
                      ],
                    ),
                    AppSpacing.hLarge,
                    TextField(
                      controller: websiteController,
                      maxLength: 100,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(labelText: 'Website'),
                      keyboardType: TextInputType.url,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9:/.%-]')),
                      ],
                    ),
                    AppSpacing.hXlarge,
                    TextField(
                      controller: gstinController,
                      style: TextStyle(fontSize: 18),
                      maxLength: 50,
                      decoration: const InputDecoration(labelText: 'GSTIN',),
                    ),
                    AppSpacing.hLarge,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Company Logo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    AppSpacing.hSmall,
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: logoWidget
                        ),
                      ),
                    AppSpacing.hSmall,
                    ElevatedButton(
                      onPressed: _saveCompanyInfo,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save',style: TextStyle(fontSize: 18),),
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

  Widget _buildDummySection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.backup, size: 64, color: Colors.blueGrey),
            AppSpacing.hMedium,
            Text("Options coming soon...", style: TextStyle(fontSize: 18)),
          ],
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
      default:
        return const Center(child: Text("Coming Soon!"));
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
