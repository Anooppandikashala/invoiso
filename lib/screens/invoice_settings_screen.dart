import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/common.dart';

import '../constants.dart';
import '../database/settings_service.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final TextEditingController invoicePrefixController = TextEditingController();
  final TextEditingController additionalInfoController = TextEditingController();
  final TextEditingController thankYouController = TextEditingController();

  String _selectedLogoPosition = 'left';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final position = await SettingsService.getSetting(SettingKey.logoPosition);
    final prefix = await SettingsService.getSetting(SettingKey.invoicePrefix);
    final info = await SettingsService.getSetting(SettingKey.additionalInfo);
    final thanks = await SettingsService.getSetting(SettingKey.thankYouNote);

    setState(() {
      _selectedLogoPosition = position ?? 'left';
      invoicePrefixController.text = prefix ?? 'INV';
      additionalInfoController.text = info ?? '';
      thankYouController.text = thanks ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await SettingsService.setSetting(SettingKey.logoPosition, _selectedLogoPosition);
    await SettingsService.setSetting(SettingKey.invoicePrefix, invoicePrefixController.text);
    await SettingsService.setSetting(SettingKey.additionalInfo, additionalInfoController.text);
    await SettingsService.setSetting(SettingKey.thankYouNote, thankYouController.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice settings saved successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Invoice Settings'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invoice Settings'),
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
              elevation: 4,
              color: Colors.white,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
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
                          'Invoice Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldWidth = constraints.maxWidth / 2 - 12;
                        return Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            // Company Logo Position
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedLogoPosition,
                                decoration: InputDecoration(
                                  labelText: 'Company Logo Position',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'left', child: Text('Left')),
                                  DropdownMenuItem(
                                      value: 'right', child: Text('Right')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLogoPosition = value!;
                                  });
                                },
                              ),
                            ),

                            // Invoice Prefix
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: invoicePrefixController,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  labelText: 'Invoice Prefix',
                                  prefixIcon:
                                  const Icon(Icons.confirmation_number),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
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

                            // Additional Info
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextField(
                                controller: additionalInfoController,
                                maxLength: 300,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Additional Information',
                                  prefixIcon: const Icon(Icons.info_outline),
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
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

                            // Thank You Note
                            SizedBox(
                              width: constraints.maxWidth,
                              child: TextField(
                                controller: thankYouController,
                                maxLength: 300,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Thank You Note',
                                  prefixIcon:
                                  const Icon(Icons.favorite_outline),
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
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
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor:
                          Theme.of(context).primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Invoice Settings',
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
}
