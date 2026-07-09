import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/database/settings_service.dart';

import '../common.dart';
import '../constants.dart';

class PdfSettingsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCustomization;

  const PdfSettingsScreen({super.key, this.onNavigateToCustomization});

  @override
  State<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  InvoiceTemplate _savedTemplate = InvoiceTemplate.classic;
  InvoiceTemplate _previewedTemplate = InvoiceTemplate.classic;
  String? _savedThemeColorHex;
  String? _previewedThemeColorHex;
  final _themeColorController = TextEditingController();
  bool _themeColorInputValid = true;
  PageSize _savedPageSize = PageSize.a4;
  PageSize _previewedPageSize = PageSize.a4;
  bool _savedShowTotalQuantity = false;
  bool _previewedShowTotalQuantity = false;
  final _thermalWidthMarginController = TextEditingController();
  String _savedThermalWidthMargin = '1';
  String _previewedThermalWidthMargin = '1';
  bool _isSaving = false;

  static const _presetThemeColors = [
    Color(0xFF002E78),
    Color(0xFF2563EB),
    Color(0xFF047857),
    Color(0xFF7C2D12),
    Color(0xFF6D28D9),
  ];

  final _templates = [
    {
      "template": InvoiceTemplate.classic,
      "name": "Classic",
      "description": "Traditional layout with clean structure",
      "image": "assets/templates/classic.png",
    },
    {
      "template": InvoiceTemplate.modern,
      "name": "Modern",
      "description": "Bold header with contemporary styling",
      "image": "assets/templates/modern.png",
    },
    {
      "template": InvoiceTemplate.minimal,
      "name": "Minimal",
      "description": "Simple and distraction-free",
    },
    {
      "template": InvoiceTemplate.executive,
      "name": "Executive",
      "description": "Premium business layout with structured billing blocks",
    },
    {
      "template": InvoiceTemplate.compact,
      "name": "Compact",
      "description": "Space-efficient receipt layout, ideal for A6 printing",
    },
    {
      "template": InvoiceTemplate.thermal,
      "name": "Thermal",
      "description": "Narrow receipt layout for 80mm and 58mm thermal printers",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final results = await Future.wait([
      SettingsService.getInvoiceTemplate(),
      SettingsService.getPdfThemeColor(),
      SettingsService.getPageSize(),
      SettingsService.getShowTotalQuantity(),
      SettingsService.getSetting(SettingKey.thermalWidthMargin),
    ]);
    final saved = results[0] as InvoiceTemplate;
    final savedThemeColor = results[1] as String?;
    final savedPageSize = results[2] as PageSize;
    final savedShowTotalQty = results[3] as bool;
    final savedThermalWidthMargin = results[4] as String?;
    final previewedTemplate =
        effectiveInvoiceTemplateForPageSize(saved, savedPageSize);
    setState(() {
      _savedTemplate = saved;
      _previewedTemplate = previewedTemplate;
      _savedThemeColorHex = savedThemeColor;
      _previewedThemeColorHex = savedThemeColor;
      _themeColorController.text = savedThemeColor ?? '';
      _savedPageSize = savedPageSize;
      _previewedPageSize = savedPageSize;
      _savedShowTotalQuantity = savedShowTotalQty;
      _previewedShowTotalQuantity = savedShowTotalQty;
      _savedThermalWidthMargin = savedThermalWidthMargin ?? '1';
      _previewedThermalWidthMargin = _savedThermalWidthMargin;
      _thermalWidthMarginController.text = _savedThermalWidthMargin;
    });
  }

  Future<void> _saveTemplate() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
    await Future.wait([
      SettingsService.setInvoiceTemplate(_previewedTemplate),
      if (_previewedThemeColorHex == null)
        SettingsService.clearPdfThemeColor()
      else
        SettingsService.setPdfThemeColor(_previewedThemeColorHex!),
      SettingsService.setPageSize(_previewedPageSize),
      SettingsService.setShowTotalQuantity(_previewedShowTotalQuantity),
      SettingsService.setSetting(SettingKey.thermalWidthMargin,
          (int.tryParse(_previewedThermalWidthMargin.trim()) ?? 1)
              .clamp(-10, 10)
              .toString()),
    ]);
    setState(() {
      _savedTemplate = _previewedTemplate;
      _savedThemeColorHex = _previewedThemeColorHex;
      _savedPageSize = _previewedPageSize;
      _savedShowTotalQuantity = _previewedShowTotalQuantity;
      _savedThermalWidthMargin = _previewedThermalWidthMargin;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("PDF settings saved"),
        behavior: SnackBarBehavior.floating,
      ),
    );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _themeColorController.dispose();
    _thermalWidthMarginController.dispose();
    super.dispose();
  }

  void _setPreviewedThemeColor(String? hexColor) {
    setState(() {
      _previewedThemeColorHex = hexColor;
      _themeColorController.text = hexColor ?? '';
      _themeColorInputValid = true;
    });
  }

  void _setPreviewedTemplate(InvoiceTemplate template) {
    if (!template.supportsPageSize(_previewedPageSize)) return;
    setState(() => _previewedTemplate = template);
  }

  void _setPreviewedPageSize(PageSize pageSize) {
    setState(() {
      _previewedPageSize = pageSize;
      _previewedTemplate = effectiveInvoiceTemplateForPageSize(
        _previewedTemplate,
        pageSize,
      );
    });
  }

  void _handleCustomThemeColor(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _previewedThemeColorHex = null;
        _themeColorInputValid = true;
      });
      return;
    }
    try {
      final normalized = SettingsService.normalizePdfThemeColor(value);
      setState(() {
        _previewedThemeColorHex = normalized;
        _themeColorInputValid = true;
      });
    } catch (_) {
      setState(() => _themeColorInputValid = false);
    }
  }

  Future<void> _openColorPicker() async {
    Color picked = _activePreviewColor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Pick theme color'),
          content: SizedBox(
            width: 300,
            child: ColorPicker(
              color: picked,
              onColorChanged: (c) => setDialogState(() => picked = c),
              pickersEnabled: const {
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
                ColorPickerType.wheel: true,
              },
              showColorCode: true,
              colorCodeHasColor: true,
              enableShadesSelection: false,
              wheelDiameter: 220,
              wheelWidth: 24,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      _setPreviewedThemeColor(_colorToHex(picked));
    }
  }

  Color get _activePreviewColor =>
      _colorFromHex(_previewedThemeColorHex) ??
      _defaultThemeColor(_previewedTemplate);

  @override
  Widget build(BuildContext context) {
    final hasUnsavedChange = _themeColorInputValid &&
        (_previewedTemplate != _savedTemplate ||
            _previewedThemeColorHex != _savedThemeColorHex ||
            _previewedPageSize != _savedPageSize ||
            _previewedShowTotalQuantity != _savedShowTotalQuantity ||
            _previewedThermalWidthMargin != _savedThermalWidthMargin);

    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Settings"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      backgroundColor: Colors.grey[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;
          final panelWidth =
              (constraints.maxWidth * 0.34).clamp(240.0, 300.0).toDouble();
          final previewPanel = _PreviewPanel(
            templates: _templates,
            previewedTemplate: _previewedTemplate,
            savedTemplate: _savedTemplate,
            themeColor: _activePreviewColor,
          );

          if (isNarrow) {
            return Column(
              children: [
                SizedBox(
                  height: (constraints.maxHeight * 0.56)
                      .clamp(340.0, 520.0)
                      .toDouble(),
                  child: _buildSettingsPanel(hasUnsavedChange),
                ),
                Divider(height: 1, color: Colors.grey[300]),
                Expanded(child: previewPanel),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: panelWidth,
                child: _buildSettingsPanel(hasUnsavedChange),
              ),
              VerticalDivider(width: 1, color: Colors.grey[300]),
              Expanded(child: previewPanel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsPanel(bool hasUnsavedChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel("Settings"),
                const SizedBox(height: 8),
                _buildPageSizeSection(),
                if (_previewedTemplate == InvoiceTemplate.compact ||
                    _previewedTemplate == InvoiceTemplate.thermal) ...[
                  const SizedBox(height: 6),
                  if (_previewedTemplate == InvoiceTemplate.compact)
                    _buildTotalQuantityToggle(),
                  if (_previewedTemplate == InvoiceTemplate.thermal)
                    _buildThermalWidthMarginField(),
                ],
                const SizedBox(height: 14),
                _sectionLabel("Templates"),
                const SizedBox(height: 8),
                ..._templates.asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  final template = entry["template"] as InvoiceTemplate;
                  final name = entry["name"] as String;
                  final description = entry["description"] as String;
                  final isDisabled =
                      !template.supportsPageSize(_previewedPageSize);
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index < _templates.length - 1 ? 6 : 0),
                    child: _TemplateListTile(
                      template: template,
                      name: name,
                      description: description,
                      themeColor: _activePreviewColor,
                      isPreviewed: _previewedTemplate == template,
                      isSaved: _savedTemplate == template,
                      isDefault: index == 0,
                      isDisabled: isDisabled,
                      disabledLabel: template == InvoiceTemplate.compact
                          ? "A6 only"
                          : template == InvoiceTemplate.thermal
                              ? "Thermal only"
                              : "Not for thermal/A6",
                      onTap: () => _setPreviewedTemplate(template),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                _ThemeColorCard(
                  controller: _themeColorController,
                  presetColors: _presetThemeColors,
                  selectedHex: _previewedThemeColorHex,
                  isValid: _themeColorInputValid,
                  onPresetSelected: (color) =>
                      _setPreviewedThemeColor(_colorToHex(color)),
                  onCustomChanged: _handleCustomThemeColor,
                  onUseTemplateDefault: () => _setPreviewedThemeColor(null),
                  onPickColor: _openColorPicker,
                ),
                const SizedBox(height: 6),
                _buildCustomTemplatePromo(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (hasUnsavedChange && !_isSaving) ? _saveTemplate : null,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: AppFontSize.xsmall,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _buildPageSizeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Page size',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PageSize>(
            value: _previewedPageSize,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            items: PageSize.values
                .map((s) => DropdownMenuItem<PageSize>(
                      value: s,
                      child: Text(s.label,
                          style:
                              const TextStyle(fontSize: AppFontSize.small)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) _setPreviewedPageSize(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalQuantityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Show total quantity row',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Switch(
            value: _previewedShowTotalQuantity,
            onChanged: (v) => setState(() => _previewedShowTotalQuantity = v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildThermalWidthMarginField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thermal print width margin',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Characters trimmed from each line to avoid edge clipping. '
                  'Increase if text runs off the paper edge on your printer.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _thermalWidthMarginController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return RegExp(r'^-?\d*$').hasMatch(newValue.text)
                      ? newValue
                      : oldValue;
                }),
              ],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _previewedThermalWidthMargin = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTemplatePromo() {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 14, color: primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Want a custom template?',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Get a design that matches your brand — colors, fonts, and layout.',
            style: TextStyle(
              fontSize: AppFontSize.xsmall,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onNavigateToCustomization,
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text(
                'Customization Options',
                style: TextStyle(
                  fontSize: AppFontSize.xsmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color? _colorFromHex(String? hexColor) {
  if (hexColor == null || hexColor.trim().isEmpty) return null;
  try {
    final normalized = SettingsService.normalizePdfThemeColor(hexColor);
    return Color(int.parse('FF${normalized.substring(1)}', radix: 16));
  } catch (_) {
    return null;
  }
}

Color _defaultThemeColor(InvoiceTemplate template) {
  return switch (template) {
    InvoiceTemplate.classic => const Color(0xFF1A237E),
    InvoiceTemplate.modern => const Color(0xFF1E88E5),
    InvoiceTemplate.minimal => const Color(0xFF616161),
    InvoiceTemplate.executive => const Color(0xFF37474F),
    InvoiceTemplate.compact => const Color(0xFF000000),
    InvoiceTemplate.thermal => const Color(0xFF000000),
  };
}

// ── Left list tile ───────────────────────────────────────────────────────────

class _TemplateListTile extends StatelessWidget {
  final InvoiceTemplate template;
  final String name;
  final String description;
  final Color themeColor;
  final bool isPreviewed;
  final bool isSaved;
  final bool isDefault;
  final bool isDisabled;
  final String? disabledLabel;
  final VoidCallback onTap;

  const _TemplateListTile({
    required this.template,
    required this.name,
    required this.description,
    required this.themeColor,
    required this.isPreviewed,
    required this.isSaved,
    required this.isDefault,
    required this.onTap,
    this.isDisabled = false,
    this.disabledLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isPreviewed
                ? primaryColor.withValues(alpha: 0.08)
                : Colors.white,
            border: Border.all(
              color: isPreviewed ? primaryColor : Colors.grey[300]!,
              width: isPreviewed ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.small),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: _TemplatePreviewSketch(
                  template: template,
                  themeColor: themeColor,
                  width: 64,
                  height: 74,
                ),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: AppFontSize.medium,
                              fontWeight: FontWeight.w600,
                              color:
                                  isPreviewed ? primaryColor : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSaved)
                          Icon(Icons.check_circle_rounded,
                              color: primaryColor, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: AppFontSize.xsmall,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isDefault) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          "Default",
                          style: TextStyle(
                            fontSize: AppFontSize.xsmall,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (isDisabled) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          border:
                              Border.all(color: Colors.amber[300]!, width: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          disabledLabel ?? "Unavailable",
                          style: TextStyle(
                            fontSize: AppFontSize.xsmall,
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Right preview panel ──────────────────────────────────────────────────────

class _PreviewPanel extends StatelessWidget {
  final List<Map<String, dynamic>> templates;
  final InvoiceTemplate previewedTemplate;
  final InvoiceTemplate savedTemplate;
  final Color themeColor;

  const _PreviewPanel({
    required this.templates,
    required this.previewedTemplate,
    required this.savedTemplate,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final entry = templates.firstWhere(
      (t) => t["template"] == previewedTemplate,
    );
    final name = entry["name"] as String;
    final description = entry["description"] as String;
    final isSaved = savedTemplate == previewedTemplate;

    return Column(
      children: [
        // Header strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160, maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: AppFontSize.xxlarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: AppFontSize.medium,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSaved)
                Chip(
                  avatar: Icon(Icons.check_circle_rounded,
                      color: Theme.of(context).primaryColor, size: 16),
                  label: Text(
                    "Active",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.small,
                    ),
                  ),
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        // Large preview
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 520 ? 16.0 : 32.0;
              final verticalPadding = constraints.maxHeight < 620 ? 16.0 : 32.0;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: FittedBox(
                    key: ValueKey(
                        '${previewedTemplate.name}-${_colorToHex(themeColor)}'),
                    fit: BoxFit.contain,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _TemplatePreviewSketch(
                        template: previewedTemplate,
                        themeColor: themeColor,
                        width: 390,
                        height: 520,
                        showDetails: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThemeColorCard extends StatelessWidget {
  final TextEditingController controller;
  final List<Color> presetColors;
  final String? selectedHex;
  final bool isValid;
  final ValueChanged<Color> onPresetSelected;
  final ValueChanged<String> onCustomChanged;
  final VoidCallback onUseTemplateDefault;
  final VoidCallback onPickColor;

  const _ThemeColorCard({
    required this.controller,
    required this.presetColors,
    required this.selectedHex,
    required this.isValid,
    required this.onPresetSelected,
    required this.onCustomChanged,
    required this.onUseTemplateDefault,
    required this.onPickColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme color',
            style: TextStyle(
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...presetColors.map((color) {
                final hex = _colorToHex(color);
                final selected = selectedHex == hex;
                return Tooltip(
                  message: hex,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onPresetSelected(color),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black87 : Colors.white,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              TextButton(
                onPressed: onUseTemplateDefault,
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(fontSize: AppFontSize.xsmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLength: 7,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
            ],
            decoration: InputDecoration(
              hintText: '#002E78',
              errorText: isValid ? null : 'Use #RRGGBB',
              counterText: '',
              isDense: true,
              prefixIcon: GestureDetector(
                onTap: onPickColor,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _colorFromHex(selectedHex) ?? Colors.grey[300]!,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              suffixIcon: Tooltip(
                message: 'Open color picker',
                child: IconButton(
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  onPressed: onPickColor,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
            onChanged: onCustomChanged,
          ),
        ],
      ),
    );
  }
}

class _TemplatePreviewSketch extends StatelessWidget {
  final InvoiceTemplate template;
  final Color themeColor;
  final double width;
  final double height;
  final bool showDetails;

  const _TemplatePreviewSketch({
    required this.template,
    required this.themeColor,
    required this.width,
    required this.height,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.white,
      padding: EdgeInsets.all(showDetails ? 24 : 4),
      child: switch (template) {
        InvoiceTemplate.classic => _classic(),
        InvoiceTemplate.modern => _modern(),
        InvoiceTemplate.minimal => _minimal(),
        InvoiceTemplate.executive => _executive(),
        InvoiceTemplate.compact => _compact(),
        InvoiceTemplate.thermal => _compact(),
      },
    );
  }

  Widget _line(double widthFactor, {double? height, Color? color}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height ?? (showDetails ? 6 : 3),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _fixedLine(double width, {double? height, Color? color}) {
    return Container(
      width: width,
      height: height ?? (showDetails ? 6 : 3),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _table({bool filledHeader = true}) {
    final rowCount = showDetails ? 5 : 3;
    return Column(
      children: [
        Container(
            height: showDetails ? 22 : 5,
            color: filledHeader ? themeColor : const Color(0xFFE5E7EB)),
        ...List.generate(rowCount, (index) {
          return Container(
            height: showDetails ? 26 : 4,
            margin: EdgeInsets.only(top: showDetails ? 2 : 1),
            color: index.isEven ? const Color(0xFFF8FAFC) : Colors.white,
          );
        }),
      ],
    );
  }

  Widget _totals() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: showDetails ? 130 : 34,
        height: showDetails ? 58 : 10,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(height: showDetails ? 18 : 3, color: themeColor),
        ),
      ),
    );
  }

  Widget _classic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: showDetails ? 54 : 14,
                height: showDetails ? 42 : 12,
                color: const Color(0xFFE5E7EB)),
            const Spacer(),
            SizedBox(
                width: showDetails ? 170 : 38,
                child: Column(children: [
                  _line(1, height: showDetails ? 9 : 3),
                  const SizedBox(height: 4),
                  _line(.72, height: showDetails ? 7 : 3)
                ])),
          ],
        ),
        SizedBox(height: showDetails ? 16 : 4),
        Container(height: showDetails ? 3 : 1.5, color: themeColor),
        SizedBox(height: showDetails ? 22 : 5),
        _line(.28, color: const Color(0xFFE5E7EB)),
        SizedBox(height: showDetails ? 18 : 4),
        _table(),
        const Spacer(),
        _totals(),
      ],
    );
  }

  Widget _modern() {
    return Column(
      children: [
        Container(
          height: showDetails ? 96 : 22,
          width: double.infinity,
          color: themeColor,
          padding: EdgeInsets.all(showDetails ? 16 : 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(.45, height: showDetails ? 10 : 3, color: Colors.white),
              SizedBox(height: showDetails ? 8 : 3),
              _line(.7, height: showDetails ? 7 : 2.5, color: Colors.white70),
            ],
          ),
        ),
        Flexible(child: SizedBox(height: showDetails ? 24 : 3)),
        _table(),
        const Spacer(),
        _totals(),
        Flexible(child: SizedBox(height: showDetails ? 18 : 2)),
        Container(height: showDetails ? 34 : 7, color: themeColor),
      ],
    );
  }

  Widget _minimal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: showDetails ? 160 : 36,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(.7),
                  SizedBox(height: showDetails ? 5 : 3),
                  _line(.5)
                ],
              ),
            ),
            const Spacer(),
            Container(
                width: showDetails ? 48 : 14,
                height: showDetails ? 38 : 12,
                color: const Color(0xFFE5E7EB)),
          ],
        ),
        SizedBox(height: showDetails ? 22 : 5),
        Container(height: 1, color: const Color(0xFFCBD5E1)),
        SizedBox(height: showDetails ? 28 : 6),
        _table(filledHeader: false),
        const Spacer(),
        _totals(),
        SizedBox(height: showDetails ? 16 : 3),
        Container(height: showDetails ? 2 : 1, color: themeColor),
      ],
    );
  }

  Widget _executive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: showDetails ? 8 : 3,
                height: showDetails ? 72 : 14,
                color: themeColor),
            SizedBox(width: showDetails ? 14 : 4),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _line(.55, height: showDetails ? 11 : 3),
                  SizedBox(height: showDetails ? 6 : 3),
                  _line(.8, height: showDetails ? 7 : 2.5)
                ])),
            SizedBox(width: showDetails ? 18 : 4),
            _fixedLine(showDetails ? 72 : 16,
                height: showDetails ? 18 : 5, color: themeColor),
          ],
        ),
        Flexible(child: SizedBox(height: showDetails ? 24 : 2)),
        Row(
          children: [
            Expanded(
                child: Container(
                    height: showDetails ? 72 : 12,
                    color: const Color(0xFFF8FAFC))),
            SizedBox(width: showDetails ? 16 : 4),
            Expanded(
                child: Container(
                    height: showDetails ? 72 : 12,
                    color: const Color(0xFFF8FAFC))),
          ],
        ),
        Flexible(child: SizedBox(height: showDetails ? 24 : 2)),
        _table(),
        const Spacer(),
        _totals(),
        Flexible(child: SizedBox(height: showDetails ? 18 : 1)),
        Container(height: showDetails ? 3 : 1.5, color: themeColor),
      ],
    );
  }

  Widget _compact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: showDetails ? 40 : 10,
                height: showDetails ? 32 : 9,
                color: const Color(0xFFE5E7EB)),
            SizedBox(width: showDetails ? 8 : 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(.8, height: showDetails ? 9 : 3),
                  SizedBox(height: showDetails ? 4 : 2),
                  _line(.6, height: showDetails ? 6 : 2),
                ],
              ),
            ),
            SizedBox(width: showDetails ? 8 : 2),
            _fixedLine(showDetails ? 52 : 14,
                height: showDetails ? 11 : 3, color: themeColor),
          ],
        ),
        SizedBox(height: showDetails ? 8 : 2),
        Container(
          height: showDetails ? 36 : 8,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
          ),
        ),
        SizedBox(height: showDetails ? 6 : 2),
        _table(),
        SizedBox(height: showDetails ? 4 : 1),
        Container(
          height: showDetails ? 14 : 3,
          color: const Color(0xFFF1F5F9),
        ),
        const Spacer(),
        _totals(),
      ],
    );
  }
}
