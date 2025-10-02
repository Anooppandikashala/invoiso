import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/screens/backup_management_screen.dart';
import 'package:invoiso/screens/user_management_screen.dart';
import '../database/database_helper.dart';
import '../models/company_info.dart';
import '../models/user.dart';

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

  CompanyInfo? _companyInfo;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    final info = await dbHelper.getCompanyInfo();
    if (info != null) {
      setState(() {
        _companyInfo = info;
        nameController.text = info.name;
        addressController.text = info.address;
        phoneController.text = info.phone;
        emailController.text = info.email;
        websiteController.text = info.website;
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
    );

    if (_companyInfo == null) {
      await dbHelper.insertCompanyInfo(newInfo);
    } else {
      await dbHelper.updateCompanyInfo(newInfo);
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
    super.dispose();
  }

  Widget _buildCompanyInfoForm() {
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
                    AppSpacing.hLarge,
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
      default:
        return const Center(child: Text("Unknown tab"));
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
