import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/company_info.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
      id: _companyInfo?.id, // Update if already exists
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Company Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 500,
            child: ListView(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveCompanyInfo,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
