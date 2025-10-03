import 'package:flutter/material.dart';

import '../common.dart';
import '../database/database_helper.dart';

class PdfSettingsScreen extends StatefulWidget {
  const PdfSettingsScreen({super.key});

  @override
  _PdfSettingsScreenState createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen>
{
  InvoiceTemplate _selectedTemplate = InvoiceTemplate.classic;
  final dbHelper = DatabaseHelper();

  final templates = [
    {"template": InvoiceTemplate.classic, "name": "Classic", "image": "assets/templates/classic.png"},
    {"template": InvoiceTemplate.modern, "name": "Modern", "image": "assets/templates/modern.png"},
    {"template": InvoiceTemplate.minimal, "name": "Minimal", "image": "assets/templates/minimal.png"},
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final savedTemplate = await dbHelper.getInvoiceTemplate();
    setState(() {
      _selectedTemplate = savedTemplate;
    });
  }

  Future<void> _selectTemplate(InvoiceTemplate template) async {
    setState(() {
      _selectedTemplate = template;
    });
    await dbHelper.setInvoiceTemplate(template);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Template '${template.name}' selected")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Settings"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: templates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // four templates per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final template = templates[index]["template"] as InvoiceTemplate;
            var templateName = templates[index]["name"] as String;
            final templateImage = templates[index]["image"] as String;
            if(index == 0)
            {
              templateName = "$templateName (Default)";
            }

            return GestureDetector(
              onTap: () async {
                // Update state + save template
                await _selectTemplate(template);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedTemplate == template
                        ? Colors.blue
                        : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.asset(
                          templateImage,
                          fit: BoxFit.fill,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      templateName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTemplate == template
                            ? Colors.blue
                            : Colors.black,
                      ),
                    ),
                    if (_selectedTemplate == template)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle, color: Colors.blue),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
