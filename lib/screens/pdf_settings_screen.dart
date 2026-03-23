import 'package:flutter/material.dart';
import 'package:invoiso/database/settings_service.dart';

import '../common.dart';
import '../constants.dart';

class PdfSettingsScreen extends StatefulWidget {
  const PdfSettingsScreen({super.key});

  @override
  _PdfSettingsScreenState createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  InvoiceTemplate _savedTemplate = InvoiceTemplate.classic;
  InvoiceTemplate _previewedTemplate = InvoiceTemplate.classic;

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
      "image": "assets/templates/minimal.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final saved = await SettingsService.getInvoiceTemplate();
    setState(() {
      _savedTemplate = saved;
      _previewedTemplate = saved;
    });
  }

  Future<void> _saveTemplate() async {
    await SettingsService.setInvoiceTemplate(_previewedTemplate);
    setState(() {
      _savedTemplate = _previewedTemplate;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Template '${_previewedTemplate.name}' saved"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnsavedChange = _previewedTemplate != _savedTemplate;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Settings"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // ── Left panel ──────────────────────────────────────────────
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    "Templates",
                    style: TextStyle(
                      fontSize: AppFontSize.large,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _templates[index];
                      final template = entry["template"] as InvoiceTemplate;
                      final name = entry["name"] as String;
                      final description = entry["description"] as String;
                      final image = entry["image"] as String;

                      final isPreviewed = _previewedTemplate == template;
                      final isSaved = _savedTemplate == template;

                      return _TemplateListTile(
                        name: name,
                        description: description,
                        image: image,
                        isPreviewed: isPreviewed,
                        isSaved: isSaved,
                        isDefault: index == 0,
                        onTap: () => setState(() => _previewedTemplate = template),
                      );
                    },
                  ),
                ),
                // ── Save button ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasUnsavedChange ? _saveTemplate : null,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.small),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────
          VerticalDivider(width: 1, color: Colors.grey[300]),

          // ── Right preview panel ──────────────────────────────────────
          Expanded(
            child: _PreviewPanel(
              templates: _templates,
              previewedTemplate: _previewedTemplate,
              savedTemplate: _savedTemplate,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left list tile ───────────────────────────────────────────────────────────

class _TemplateListTile extends StatelessWidget {
  final String name;
  final String description;
  final String image;
  final bool isPreviewed;
  final bool isSaved;
  final bool isDefault;
  final VoidCallback onTap;

  const _TemplateListTile({
    required this.name,
    required this.description,
    required this.image,
    required this.isPreviewed,
    required this.isSaved,
    required this.isDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isPreviewed ? primaryColor.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isPreviewed ? primaryColor : Colors.grey[300]!,
            width: isPreviewed ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                image,
                width: 52,
                height: 68,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
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
                            color: isPreviewed ? primaryColor : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSaved)
                        Icon(Icons.check_circle_rounded,
                            color: primaryColor, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
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
                ],
              ),
            ),
          ],
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

  const _PreviewPanel({
    required this.templates,
    required this.previewedTemplate,
    required this.savedTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final entry = templates.firstWhere(
      (t) => t["template"] == previewedTemplate,
    );
    final name = entry["name"] as String;
    final description = entry["description"] as String;
    final image = entry["image"] as String;
    final isSaved = savedTemplate == previewedTemplate;

    return Column(
      children: [
        // Header strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
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
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        // Large preview
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(previewedTemplate),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
