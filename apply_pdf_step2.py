import os

file_path = r'c:\billing\invoiso\lib\screens\settings\pdf_settings_screen_v2.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add custom layout helper methods & print preview method right above _resetToDefaultV2
methods_anchor = "void _resetToDefaultV2() {"
new_methods = """Future<void> _handlePrintPreview() async {
    if (_previewPdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview is still generating, please wait...')),
      );
      return;
    }
    try {
      if (_previewedTemplate == InvoiceTemplate.thermal) {
        final sampleInvoice = PdfPreviewSample.createSampleInvoice(
          company: _basePdfSettings?.company,
        );
        await ThermalPrinterService.printInvoice(context, sampleInvoice);
      } else {
        final pageFmt = PDFService.pageSizeToFormat(_previewedPageSize);
        final isLandscape = _previewedLandscape &&
            _previewedTemplate == InvoiceTemplate.gridClassic;
        final effectiveFormat = isLandscape ? pageFmt.landscape : pageFmt;

        await Printing.layoutPdf(
          format: effectiveFormat,
          name: 'Invoiso_${_previewedTemplate.name}_preview',
          onLayout: (format) async => _previewPdfBytes!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _applyCustomLayout(CustomInvoiceLayout layout) {
    setState(() {
      _selectedCustomLayoutId = layout.id;
      _previewedTemplate = layout.baseTemplate;
      _previewedPageSize = layout.pageSize;
      _previewedLandscape = layout.landscape;
      _previewedThemeColorHex = layout.themeColorHex;
      _themeColorController.text = layout.themeColorHex ?? '';
      _previewedPdfFontSize = layout.fontSize;
      _previewedPdfSectionSizes = Map.of(layout.sectionSizes);
      _previewedShowTotalQuantity = layout.showTotalQuantity;
      _previewedShowSoftwareBranding = layout.showSoftwareBranding;
      _previewedLetterheadEnabled = layout.letterheadEnabled;
      _previewedLetterheadHideCompanyHeader = layout.letterheadHideCompanyHeader;
      _previewedPrintMarginTopMm = layout.printMarginTopMm;
      _marginTopController.text = layout.printMarginTopMm.toStringAsFixed(0);
      _previewedPrintMarginBottomMm = layout.printMarginBottomMm;
      _marginBottomController.text = layout.printMarginBottomMm.toStringAsFixed(0);
      _previewedPrintMarginLeftMm = layout.printMarginLeftMm;
      _marginLeftController.text = layout.printMarginLeftMm.toStringAsFixed(0);
      _previewedPrintMarginRightMm = layout.printMarginRightMm;
      _marginRightController.text = layout.printMarginRightMm.toStringAsFixed(0);
      _previewedPrintContentScale = layout.printContentScale;
      _previewedThermalWidthMargin = layout.thermalWidthMargin;
      _thermalWidthMarginController.text = layout.thermalWidthMargin;
      _previewedThermalItemLayout = layout.thermalItemLayout;
      _previewedThermalCompanyNameSize = layout.thermalCompanyNameSize;
    });
    _schedulePdfPreviewUpdate(immediate: true);
  }

  Future<void> _removeCustomLayout(CustomInvoiceLayout layout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Custom Layout'),
        content: Text('Are you sure you want to remove \\'${layout.name}\\'? Default templates cannot be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _customLayouts.removeWhere((l) => l.id == layout.id);
      if (_selectedCustomLayoutId == layout.id) {
        _selectedCustomLayoutId = null;
        _previewedTemplate = InvoiceTemplate.classic;
      }
    });
    await ref.read(settingsRepositoryProvider).saveCustomInvoiceLayouts(_customLayouts);
    _schedulePdfPreviewUpdate(immediate: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed layout \\'${layout.name}\\'')),
      );
    }
  }

  Future<void> _showAddLayoutDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Custom Layout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Import a custom .json layout file or save current customizations as a new layout.',
                style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.file_upload_outlined, color: Color(0xFF3730A3)),
                ),
                title: const Text('Import from JSON File', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select a .json or .invoiso-layout file from your device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importCustomLayoutFile();
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.bookmark_add_outlined, color: Color(0xFF166534)),
                ),
                title: const Text('Save Current Settings as Layout', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Create a reusable template from currently configured options'),
                onTap: () {
                  Navigator.pop(ctx);
                  _saveCurrentAsCustomLayout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importCustomLayoutFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'invoiso-layout'],
      );
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final layout = CustomInvoiceLayout.fromJson(content);

      setState(() {
        _customLayouts.removeWhere((l) => l.id == layout.id);
        _customLayouts.add(layout);
      });
      await ref.read(settingsRepositoryProvider).saveCustomInvoiceLayouts(_customLayouts);
      _applyCustomLayout(layout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported custom layout \\'${layout.name}\\' successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import layout: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveCurrentAsCustomLayout() async {
    final nameCtrl = TextEditingController(text: 'My Custom Layout');
    final descCtrl = TextEditingController(text: 'Custom template with personal styling');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Custom Layout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Layout Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save Layout')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final newLayout = CustomInvoiceLayout(
      id: 'custom_layout_${DateTime.now().millisecondsSinceEpoch}',
      name: nameCtrl.text.trim().isEmpty ? 'Custom Layout' : nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
      baseTemplate: _previewedTemplate,
      pageSize: _previewedPageSize,
      landscape: _previewedLandscape,
      themeColorHex: _previewedThemeColorHex,
      fontSize: _previewedPdfFontSize,
      sectionSizes: Map.of(_previewedPdfSectionSizes),
      showTotalQuantity: _previewedShowTotalQuantity,
      showSoftwareBranding: _previewedShowSoftwareBranding,
      letterheadEnabled: _previewedLetterheadEnabled,
      letterheadHideCompanyHeader: _previewedLetterheadHideCompanyHeader,
      printMarginTopMm: _previewedPrintMarginTopMm,
      printMarginBottomMm: _previewedPrintMarginBottomMm,
      printMarginLeftMm: _previewedPrintMarginLeftMm,
      printMarginRightMm: _previewedPrintMarginRightMm,
      printContentScale: _previewedPrintContentScale,
      thermalWidthMargin: _previewedThermalWidthMargin,
      thermalItemLayout: _previewedThermalItemLayout,
      thermalCompanyNameSize: _previewedThermalCompanyNameSize,
      createdAt: DateTime.now(),
    );

    setState(() {
      _customLayouts.add(newLayout);
      _selectedCustomLayoutId = newLayout.id;
    });
    await ref.read(settingsRepositoryProvider).saveCustomInvoiceLayouts(_customLayouts);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved custom layout \\'${newLayout.name}\\'!')),
      );
    }
  }

  void _resetToDefaultV2() {"""

if methods_anchor in text:
    text = text.replace(methods_anchor, new_methods, 1)
else:
    print('methods_anchor not found!')

# 2. Update _templatesColumnV2 to show Add Layout button & user inserted templates
old_templates_col_header = "_sectionLabel(l10n.pdfSettingsTemplatesLabel),"
new_templates_col_header = """Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel(l10n.pdfSettingsTemplatesLabel),
              TextButton.icon(
                onPressed: _showAddLayoutDialog,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Add Layout', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),"""

if old_templates_col_header in text:
    text = text.replace(old_templates_col_header, new_templates_col_header, 1)
else:
    print('old_templates_col_header not found!')

# 3. Update the templates listing builder to include custom layouts
old_builder = """              final visibleTemplates = templateCatalog
                  .where((e) => (e["template"] as InvoiceTemplate)
                      .supportsPageSize(_previewedPageSize))
                  .toList();
              if (visibleTemplates.isEmpty) {
                return Center(
                  child: Text(
                      l10n.pdfSettingsNoTemplatesForPageSizeMessage(
                          pageSizeLabel(context, _previewedPageSize)),
                      style: TextStyle(
                          fontSize: 12.5,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: visibleTemplates.asMap().entries.map((e) {
                    final index = e.key;
                    final entry = e.value;
                    final template = entry["template"] as InvoiceTemplate;
                    final name = templateName(context, template);
                    final description = templateDescription(context, template);
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: index < visibleTemplates.length - 1 ? 8 : 0),
                      child: TemplateListTile(
                          template: template,
                          name: name,
                          description: description,
                          themeColor: _activePreviewColor,
                          isPreviewed: _previewedTemplate == template,
                          isSaved: _savedTemplate == template,
                          thermalDetailedTemplate:
                              _previewedThermalItemLayout != "table",
                          isDefault: template == InvoiceTemplate.classic,
                          onTap: () => _setPreviewedTemplate(template),
                          isDisabled: false,
                          disabledLabel: null),
                    );
                  }).toList(),
                ),
              );"""

new_builder = """              final visibleTemplates = templateCatalog
                  .where((e) => (e["template"] as InvoiceTemplate)
                      .supportsPageSize(_previewedPageSize))
                  .toList();
              final matchingCustomLayouts = _customLayouts
                  .where((l) => l.pageSize == _previewedPageSize)
                  .toList();

              if (visibleTemplates.isEmpty && matchingCustomLayouts.isEmpty) {
                return Center(
                  child: Text(
                      l10n.pdfSettingsNoTemplatesForPageSizeMessage(
                          pageSizeLabel(context, _previewedPageSize)),
                      style: TextStyle(
                          fontSize: 12.5,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (matchingCustomLayouts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'YOUR INSERTED LAYOUTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      for (final customLayout in matchingCustomLayouts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TemplateListTile(
                            template: customLayout.baseTemplate,
                            name: customLayout.name,
                            description: customLayout.description,
                            themeColor: customLayout.themeColorHex != null
                                ? (_colorFromHex(customLayout.themeColorHex!) ?? _activePreviewColor)
                                : _activePreviewColor,
                            isPreviewed: _selectedCustomLayoutId == customLayout.id,
                            isSaved: false,
                            isDefault: false,
                            isInserted: true,
                            thermalDetailedTemplate: customLayout.thermalItemLayout != "table",
                            onTap: () => _applyCustomLayout(customLayout),
                            onDelete: () => _removeCustomLayout(customLayout),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'DEFAULT TEMPLATES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    for (final entry in visibleTemplates)
                      Builder(builder: (context) {
                        final template = entry["template"] as InvoiceTemplate;
                        final name = templateName(context, template);
                        final description = templateDescription(context, template);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TemplateListTile(
                            template: template,
                            name: name,
                            description: description,
                            themeColor: _activePreviewColor,
                            isPreviewed: _selectedCustomLayoutId == null && _previewedTemplate == template,
                            isSaved: _savedTemplate == template,
                            thermalDetailedTemplate:
                                _previewedThermalItemLayout != "table",
                            isDefault: template == InvoiceTemplate.classic,
                            isInserted: false,
                            onDelete: null,
                            onTap: () {
                              setState(() => _selectedCustomLayoutId = null);
                              _setPreviewedTemplate(template);
                            },
                            isDisabled: false,
                            disabledLabel: null,
                          ),
                        );
                      }),
                  ],
                ),
              );"""

if old_builder in text:
    text = text.replace(old_builder, new_builder, 1)
else:
    print('old_builder not found!')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Step 2 applied successfully!')

