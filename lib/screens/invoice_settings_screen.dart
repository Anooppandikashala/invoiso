import 'package:flutter/material.dart';
import 'package:invoiso/common.dart';

import '../constants.dart';
import '../database/settings_service.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final TextEditingController invoicePrefixController = TextEditingController();
  final TextEditingController additionalInfoController = TextEditingController();
  final TextEditingController thankYouController = TextEditingController();
  final TextEditingController quantityLabelController = TextEditingController();

  String _selectedLogoPosition = 'left';
  String _selectedCurrencyCode = 'INR';
  String _selectedLogoSize = 'medium';
  bool _showGstFields = true;
  bool _fractionalQuantity = false;
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
    final currency = await SettingsService.getCurrency();
    final showGst = await SettingsService.getShowGstFields();
    final fractionalQty = await SettingsService.getFractionalQuantity();
    final qtyLabel = await SettingsService.getQuantityLabel();
    final logoSize = await SettingsService.getLogoSize();

    setState(() {
      _selectedLogoPosition = position ?? 'left';
      _selectedCurrencyCode = currency.code;
      _selectedLogoSize = logoSize;
      invoicePrefixController.text = prefix ?? 'INV';
      additionalInfoController.text = info ?? '';
      thankYouController.text = thanks ?? '';
      _showGstFields = showGst;
      _fractionalQuantity = fractionalQty;
      quantityLabelController.text = qtyLabel;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await SettingsService.setSetting(SettingKey.logoSize, _selectedLogoSize);
    await SettingsService.setSetting(SettingKey.logoPosition, _selectedLogoPosition);
    await SettingsService.setSetting(SettingKey.invoicePrefix, invoicePrefixController.text);
    await SettingsService.setSetting(SettingKey.additionalInfo, additionalInfoController.text);
    await SettingsService.setSetting(SettingKey.thankYouNote, thankYouController.text);
    await SettingsService.setCurrency(_selectedCurrencyCode);
    await SettingsService.setSetting(SettingKey.showGstFields, _showGstFields.toString());
    await SettingsService.setSetting(SettingKey.fractionalQuantity, _fractionalQuantity.toString());
    await SettingsService.setSetting(SettingKey.quantityLabel, quantityLabelController.text.trim());

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
              shadowColor: Colors.black.withValues(alpha:0.1),
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

                            // Company Logo Size
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedLogoSize,
                                decoration: InputDecoration(
                                  labelText: 'Company Logo Size',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                                  DropdownMenuItem(value: 'small',  child: Text('Small')),
                                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                  DropdownMenuItem(value: 'large',  child: Text('Large')),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedLogoSize = value!);
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

                            // Quantity Column Label
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: quantityLabelController,
                                maxLength: 30,
                                decoration: InputDecoration(
                                  labelText: 'Quantity Column Label',
                                  hintText: 'e.g. Words, Hours, Units',
                                  helperText: 'Leave blank to use default "Qty"',
                                  prefixIcon: const Icon(Icons.tag),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
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

                            // Invoice numbering info
                            SizedBox(
                              width: fieldWidth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Invoice numbers are auto-generated and cannot be edited manually. '
                                        'Each new invoice number is derived from the last invoice number stored in the database — including soft-deleted invoices. '
                                        'If you created test invoices and deleted them, the counter will continue from where it left off.',
                                        style: TextStyle(fontSize: 12, color: Colors.blue[800], height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Currency
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCurrencyCode,
                                decoration: InputDecoration(
                                  labelText: 'Currency',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                                items: SupportedCurrencies.all.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c.code,
                                    child: Text('${c.symbol}  ${c.name} (${c.code})'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCurrencyCode = value!;
                                  });
                                },
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

                            // GST Fields Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Show GST Fields'),
                                  subtitle: const Text(
                                    'Display GSTIN fields (HSN Code) on invoices, PDFs, and CSV exports',
                                  ),
                                  secondary: Icon(
                                    Icons.receipt_long_rounded,
                                    color: _showGstFields
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _showGstFields,
                                  onChanged: (val) =>
                                      setState(() => _showGstFields = val),
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Fractional Quantity Toggle
                            SizedBox(
                              width: constraints.maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SwitchListTile(
                                  title: const Text('Allow Fractional Quantities'),
                                  subtitle: const Text(
                                    'Enable decimal quantities (e.g. 1.5 hrs, 0.5 kg)',
                                  ),
                                  secondary: Icon(
                                    Icons.pin_outlined,
                                    color: _fractionalQuantity
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  value: _fractionalQuantity,
                                  onChanged: (val) =>
                                      setState(() => _fractionalQuantity = val),
                                  activeColor: Theme.of(context).primaryColor,
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
                          Theme.of(context).primaryColor.withValues(alpha:0.4),
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
