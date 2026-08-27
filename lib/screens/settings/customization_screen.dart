import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';

class CustomizationScreen extends StatefulWidget {
  final int? highlightIndex;
  const CustomizationScreen({super.key, this.highlightIndex});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  int? _highlightIndex;

  @override
  void initState() {
    super.initState();
    _highlightIndex = widget.highlightIndex;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    const formUrl = 'https://forms.gle/LyX6Z2kBNR2BpwVu7';

    final options = [
      _CustomOption(
        icon: Icons.picture_as_pdf_rounded,
        title: l10n.customizationPdfTemplateTitle,
        description: l10n.customizationPdfTemplateDescription,
        price: '\$30 – \$50',
        delivery: l10n.customizationPdfTemplateDelivery,
      ),
      _CustomOption(
        icon: Icons.tune_rounded,
        title: l10n.customizationCustomFieldsTitle,
        description: l10n.customizationCustomFieldsDescription,
        price: '\$25 – \$100',
        delivery: l10n.customizationCustomFieldsDelivery,
      ),
      _CustomOption(
        icon: Icons.branding_watermark_rounded,
        title: l10n.customizationWhiteLabelTitle,
        description: l10n.customizationWhiteLabelDescription,
        price: '\$100 – \$150',
        delivery: l10n.customizationWhiteLabelDelivery,
      ),
      _CustomOption(
        icon: Icons.category_rounded,
        title: l10n.customizationIndustryBuildTitle,
        description: l10n.customizationIndustryBuildDescription,
        price: '\$175 – \$200',
        delivery: l10n.customizationIndustryBuildDelivery,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.customizationEyebrowLabel,
              style: TextStyle(
                fontSize: AppFontSize.xsmall,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.customizationHeadline,
              style: TextStyle(
                fontSize: AppFontSize.xlarge,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.customizationSubtitle,
              style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 380,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.35,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                final isHighlighted = _highlightIndex == index;
                return Card(
                  elevation: isHighlighted ? 4 : 0,
                  shadowColor: isHighlighted
                      ? primaryColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                  color: isHighlighted
                      ? primaryColor.withValues(alpha: 0.04)
                      : Theme.of(context).colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    side: BorderSide(
                      color: isHighlighted
                          ? primaryColor
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: isHighlighted ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(
                                    alpha: isHighlighted ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(
                                    AppBorderRadius.small),
                              ),
                              child:
                                  Icon(opt.icon, size: 20, color: primaryColor),
                            ),
                            if (isHighlighted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.customizationRecommendedBadge,
                                  style: const TextStyle(
                                    fontSize: AppFontSize.xsmall,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                opt.price,
                                style: TextStyle(
                                  fontSize: AppFontSize.xsmall,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          opt.title,
                          style: TextStyle(
                            fontSize: AppFontSize.medium,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            opt.description,
                            style: TextStyle(
                              fontSize: AppFontSize.xsmall,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l10n.customizationDeliveryLabel(opt.delivery),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: AppFontSize.xsmall,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                if (_highlightIndex != null) {
                                  setState(() => _highlightIndex = null);
                                }
                                final uri = Uri.parse(formUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(l10n
                                              .customizationFormOpenErrorMessage)),
                                    );
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  l10n.customizationRequestButton,
                                  style: const TextStyle(
                                      fontSize: AppFontSize.xsmall,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.customizationDisclaimerMessage,
                      style: TextStyle(
                          fontSize: AppFontSize.xsmall,
                          color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomOption {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  final String delivery;

  const _CustomOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.delivery,
  });
}
