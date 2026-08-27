import 'package:flutter/material.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/widgets/template_list_tile.dart';

/// Step 3 of the onboarding wizard: page size + invoice template, reusing
/// the same catalog/tile widget and page-size/template compatibility rules
/// as the full PDF Settings screen (lib/screens/settings/pdf_settings_screen_v2.dart).
class OnboardingStepAppearance extends StatelessWidget {
  final PageSize pageSize;
  final InvoiceTemplate template;
  final ValueChanged<PageSize> onPageSizeChanged;
  final ValueChanged<InvoiceTemplate> onTemplateChanged;

  const OnboardingStepAppearance({
    super.key,
    required this.pageSize,
    required this.template,
    required this.onPageSizeChanged,
    required this.onTemplateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleTemplates = templateCatalog
        .where((e) =>
            (e["template"] as InvoiceTemplate).supportsPageSize(pageSize))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<PageSize>(
            isExpanded: true,
            value: pageSize,
            decoration: InputDecoration(
              labelText: l10n.onboardingPageSizeLabel,
              border: const OutlineInputBorder(),
            ),
            items: PageSize.values
                .map((s) => DropdownMenuItem(
                    value: s, child: Text(pageSizeLabel(context, s))))
                .toList(),
            onChanged: (val) {
              if (val != null) onPageSizeChanged(val);
            },
          ),
          const SizedBox(height: 16),
          Text(l10n.onboardingTemplateLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final entry in visibleTemplates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TemplateListTile(
                template: entry["template"] as InvoiceTemplate,
                name:
                    templateName(context, entry["template"] as InvoiceTemplate),
                description: templateDescription(
                    context, entry["template"] as InvoiceTemplate),
                themeColor: Theme.of(context).primaryColor,
                isPreviewed: template == entry["template"],
                isSaved: false,
                isDefault: entry["template"] == InvoiceTemplate.classic,
                thermalDetailedTemplate: false,
                onTap: () =>
                    onTemplateChanged(entry["template"] as InvoiceTemplate),
              ),
            ),
        ],
      ),
    );
  }
}
