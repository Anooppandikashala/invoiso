import 'package:flutter/material.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// Shared invoice-template catalog (template + thumbnail asset per
/// InvoiceTemplate), used by both the PDF Settings screen and the
/// onboarding wizard so they don't maintain two separate copies of this
/// list. Display name/description are localized separately via
/// [templateName]/[templateDescription] (need a BuildContext, so can't
/// live in this static data).
final templateCatalog = [
  {
    "template": InvoiceTemplate.classic,
    "image": "assets/templates/classic.png",
  },
  {
    "template": InvoiceTemplate.modern,
    "image": "assets/templates/modern.png",
  },
  {
    "template": InvoiceTemplate.minimal,
  },
  {
    "template": InvoiceTemplate.executive,
  },
  {
    "template": InvoiceTemplate.compact,
  },
  {
    "template": InvoiceTemplate.thermal,
  },
  {
    "template": InvoiceTemplate.gridClassic,
  },
];

String templateName(BuildContext context, InvoiceTemplate template) {
  final l10n = AppLocalizations.of(context)!;
  return switch (template) {
    InvoiceTemplate.classic => l10n.pdfTemplateClassicName,
    InvoiceTemplate.modern => l10n.pdfTemplateModernName,
    InvoiceTemplate.minimal => l10n.pdfTemplateMinimalName,
    InvoiceTemplate.executive => l10n.pdfTemplateExecutiveName,
    InvoiceTemplate.compact => l10n.pdfTemplateCompactName,
    InvoiceTemplate.thermal => l10n.pdfTemplateThermalName,
    InvoiceTemplate.gridClassic => l10n.pdfTemplateGridClassicName,
  };
}

String templateDescription(BuildContext context, InvoiceTemplate template) {
  final l10n = AppLocalizations.of(context)!;
  return switch (template) {
    InvoiceTemplate.classic => l10n.pdfTemplateClassicDescription,
    InvoiceTemplate.modern => l10n.pdfTemplateModernDescription,
    InvoiceTemplate.minimal => l10n.pdfTemplateMinimalDescription,
    InvoiceTemplate.executive => l10n.pdfTemplateExecutiveDescription,
    InvoiceTemplate.compact => l10n.pdfTemplateCompactDescription,
    InvoiceTemplate.thermal => l10n.pdfTemplateThermalDescription,
    InvoiceTemplate.gridClassic => l10n.pdfTemplateGridClassicDescription,
  };
}

// ── Left list tile ───────────────────────────────────────────────────────────

class TemplateListTile extends StatelessWidget {
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
  final bool thermalDetailedTemplate;

  const TemplateListTile({
    super.key,
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
    required this.thermalDetailedTemplate
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
                : Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(
              color: isPreviewed
                  ? primaryColor
                  : Theme.of(context).colorScheme.outlineVariant,
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
                child: TemplatePreviewSketch(
                  template: template,
                  themeColor: themeColor,
                  width: 64,
                  height: 74,
                  thermalDetailedTemplate: thermalDetailedTemplate,
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
                              color: isPreviewed
                                  ? primaryColor
                                  : Theme.of(context).colorScheme.onSurface,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.dashboardLayoutDefaultTitle,
                          style: TextStyle(
                            fontSize: AppFontSize.xsmall,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          disabledLabel ?? AppLocalizations.of(context)!.commonUnavailableLabel,
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

class TemplatePreviewSketch extends StatelessWidget {
  final InvoiceTemplate template;
  final Color themeColor;
  final double width;
  final double height;
  final bool showDetails;
  final bool thermalDetailedTemplate;

  const TemplatePreviewSketch({
    super.key,
    required this.template,
    required this.themeColor,
    required this.width,
    required this.height,
    this.showDetails = false,
    required this.thermalDetailedTemplate,
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
        InvoiceTemplate.thermal => _thermal(detailed: thermalDetailedTemplate),
        InvoiceTemplate.gridClassic => _gridClassic(),
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

  Widget _gridClassic() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF334155), width: showDetails ? 1.2 : 1),
      ),
      padding: EdgeInsets.all(showDetails ? 10 : 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered header block
          _fixedLine(showDetails ? 110 : 26, height: showDetails ? 8 : 3, color: themeColor),
          SizedBox(height: showDetails ? 5 : 2),
          _fixedLine(showDetails ? 80 : 20, height: showDetails ? 5 : 2),
          SizedBox(height: showDetails ? 10 : 3),
          Container(height: 1, color: const Color(0xFF334155)),
          SizedBox(height: showDetails ? 10 : 3),
          // Customer (left) / invoice meta (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(.8, height: showDetails ? 6 : 2),
                    SizedBox(height: showDetails ? 4 : 1),
                    _line(.55, height: showDetails ? 6 : 2),
                  ],
                ),
              ),
              SizedBox(width: showDetails ? 10 : 3),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _line(.9, height: showDetails ? 6 : 2),
                    SizedBox(height: showDetails ? 4 : 1),
                    _line(.7, height: showDetails ? 6 : 2),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: showDetails ? 10 : 3),
          // Full-bordered item grid, with column dividers
          Container(
            height: showDetails ? 74 : 20,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1), width: 0.6),
            ),
            child: Column(
              children: [
                Container(height: showDetails ? 16 : 4, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          flex: i == 1 ? 3 : 1,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: i < 3
                                    ? const BorderSide(
                                        color: Color(0xFFCBD5E1), width: 0.6)
                                    : BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: showDetails ? 10 : 3),
          // Plain totals rows + bold net amount line
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _fixedLine(showDetails ? 88 : 22, height: showDetails ? 5 : 2),
                SizedBox(height: showDetails ? 3 : 1),
                _fixedLine(showDetails ? 88 : 22, height: showDetails ? 5 : 2),
                SizedBox(height: showDetails ? 5 : 1),
                _fixedLine(showDetails ? 70 : 18,
                    height: showDetails ? 7 : 3, color: themeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedLine() {
    return Row(
      children: List.generate(showDetails ? 24 : 12, (i) {
        return Expanded(
          child: Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: showDetails ? 1 : 0.5),
            color: i.isEven ? const Color(0xFF94A3B8) : Colors.transparent,
          ),
        );
      }),
    );
  }

  Widget _thermal({bool detailed = false}) {
    final rows = showDetails ? 20  : 5;
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered header — narrow roll-paper look
            _dashedLine(),
            SizedBox(height: showDetails ? 8 : 2),
            _fixedLine(showDetails ? 90 : 22, height: showDetails ? 7 : 3, color: themeColor),
            SizedBox(height: showDetails ? 4 : 1),
            _fixedLine(showDetails ? 70 : 16, height: showDetails ? 4 : 2),
            SizedBox(height: showDetails ? 2 : 1),
            _fixedLine(showDetails ? 60 : 14, height: showDetails ? 4 : 2),
            SizedBox(height: showDetails ? 8 : 2),
            _dashedLine(),
            SizedBox(height: showDetails ? 6 : 2),
            // Item lines — name left, price right, no grid borders
            ...List.generate(rows, (i) => Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: showDetails ? 4 : 1),
                  child: Row(
                    children: [
                      Expanded(child: _line(.6, height: showDetails ? 5 : 2)),
                      SizedBox(width: showDetails ? 6 : 2),
                      if(!detailed)
                      _fixedLine(showDetails ? 20 : 6, height: showDetails ? 5 : 2),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: showDetails ? 4 : 1),
                  child: Row(
                    children: [
                      if(detailed)
                      Expanded(child: _line(0.3, height: showDetails ? 5 : 2)),
                      SizedBox(width: showDetails ? 6 : 2),
                      if(detailed)
                      _fixedLine(showDetails ? 20 : 6, height: showDetails ? 5 : 2),
                    ],
                  ),
                )

              ],
            )
            ),
            SizedBox(height: showDetails ? 2 : 1),
            _dashedLine(),
            SizedBox(height: showDetails ? 6 : 2),
            // Bold total line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _fixedLine(showDetails ? 40 : 10, height: showDetails ? 7 : 3, color: themeColor),
                _fixedLine(showDetails ? 40 : 10, height: showDetails ? 7 : 3, color: themeColor),
              ],
            ),
            SizedBox(height: showDetails ? 8 : 2),
            _dashedLine(),
            SizedBox(height: showDetails ? 6 : 2),
            _fixedLine(showDetails ? 60 : 14, height: showDetails ? 4 : 2),
          ],
        ),
      ),
    );
  }
}
