import os

file_path = r'c:\billing\invoiso\lib\screens\settings\pdf_settings_screen_v2.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix Pre-printed Letterhead Mode row overflow (add Expanded & ellipsis)
old_lh_title = """                    Row(
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 16,
                          color: _previewedLetterheadEnabled
                              ? primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pre-printed Letterhead Mode',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: FontWeight.w600,
                            color: _previewedLetterheadEnabled
                                ? primaryColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),"""

new_lh_title = """                    Row(
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 16,
                          color: _previewedLetterheadEnabled
                              ? primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pre-printed Letterhead Mode',
                            style: TextStyle(
                              fontSize: AppFontSize.small,
                              fontWeight: FontWeight.w600,
                              color: _previewedLetterheadEnabled
                                  ? primaryColor
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),"""

if old_lh_title in text:
    text = text.replace(old_lh_title, new_lh_title, 1)
    print('lh_title fixed!')
else:
    print('old_lh_title not found!')

# 2. Fix Omit digital company header & logo live preview update
old_omit = """                    onChanged: (v) => setState(
                        () => _previewedLetterheadHideCompanyHeader = v ?? true),"""

new_omit = """                    onChanged: (v) {
                      setState(() => _previewedLetterheadHideCompanyHeader = v ?? true);
                      _schedulePdfPreviewUpdate(immediate: true);
                    },"""

if old_omit in text:
    text = text.replace(old_omit, new_omit, 1)
    print('omit header preview fixed!')
else:
    print('old_omit not found!')

# 3. Fix Margins presets row overflow
old_margins_row = """            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PRINT MARGINS (MM)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    InkWell(
                      onTap: () => _applyMarginPreset(40, 25, 10, 10),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Standard (40/25)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _applyMarginPreset(25, 20, 8, 8),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Compact (25/20)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),"""

new_margins_row = """            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRINT MARGINS (MM)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    InkWell(
                      onTap: () => _applyMarginPreset(40, 25, 10, 10),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Standard (40/25)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _applyMarginPreset(25, 20, 8, 8),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Compact (25/20)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),"""

if old_margins_row in text:
    text = text.replace(old_margins_row, new_margins_row, 1)
    print('margins row fixed!')
else:
    print('old_margins_row not found!')

# 4. Pass onPrint in _previewColumnV2
old_preview_call = """      onToggleLivePdf: () =>
          setState(() => _useLivePdfPreview = !_useLivePdfPreview),
      previewVersion: _previewVersion,
    );"""

new_preview_call = """      onToggleLivePdf: () =>
          setState(() => _useLivePdfPreview = !_useLivePdfPreview),
      previewVersion: _previewVersion,
      onPrint: _handlePrintPreview,
    );"""

if old_preview_call in text:
    text = text.replace(old_preview_call, new_preview_call, 1)
    print('preview onPrint passed!')
else:
    print('old_preview_call not found!')

# 5. Add onPrint to _PreviewPanel and replace header with zero-overflow responsive layout + Print button
old_panel_def = """  final bool useLivePdf;
  final VoidCallback onToggleLivePdf;
  final int previewVersion;

  const _PreviewPanel({
    required this.previewedTemplate,
    required this.savedTemplate,
    required this.themeColor,
    required this.thermalDetailedTemplate,
    this.landscape = false,
    this.letterheadMode = false,
    this.marginTop = 40.0,
    this.marginBottom = 25.0,
    this.contentScale = 100.0,
    this.pdfBytes,
    this.isLoading = false,
    this.useLivePdf = true,
    required this.onToggleLivePdf,
    this.previewVersion = 0,
  });"""

new_panel_def = """  final bool useLivePdf;
  final VoidCallback onToggleLivePdf;
  final int previewVersion;
  final VoidCallback? onPrint;

  const _PreviewPanel({
    required this.previewedTemplate,
    required this.savedTemplate,
    required this.themeColor,
    required this.thermalDetailedTemplate,
    this.landscape = false,
    this.letterheadMode = false,
    this.marginTop = 40.0,
    this.marginBottom = 25.0,
    this.contentScale = 100.0,
    this.pdfBytes,
    this.isLoading = false,
    this.useLivePdf = true,
    required this.onToggleLivePdf,
    this.previewVersion = 0,
    this.onPrint,
  });"""

if old_panel_def in text:
    text = text.replace(old_panel_def, new_panel_def, 1)
    print('panel def updated!')
else:
    print('old_panel_def not found!')

# 6. Replace _PreviewPanel header strip with LayoutBuilder responsive header + Print button
old_header_strip = """        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: AppFontSize.large,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isSaved) ...[
                          const SizedBox(width: 8),
                          Chip(
                            avatar: Icon(Icons.check_circle_rounded,
                                color: Theme.of(context).primaryColor, size: 14),
                            label: Text(
                              l10n.commonActiveLabel,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ],
                        if (letterheadMode) ...[
                          const SizedBox(width: 8),
                          Chip(
                            avatar: const Icon(Icons.layers_outlined,
                                color: Colors.teal, size: 14),
                            label: Text(
                              'Letterhead (${contentScale.round()}%)',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.picture_as_pdf_outlined, size: 14),
                    label: Text('Print Preview', style: TextStyle(fontSize: 11.5)),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.brush_outlined, size: 14),
                    label: Text('Sketch', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
                selected: {useLivePdf},
                onSelectionChanged: (_) => onToggleLivePdf(),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),"""

new_header_strip = """        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 420;
              final infoBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: AppFontSize.medium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSaved)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Theme.of(context).primaryColor, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                l10n.commonActiveLabel,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (letterheadMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.layers_outlined, color: Colors.teal, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                'Letterhead (${contentScale.round()}%)',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pdfBytes != null && onPrint != null) ...[
                    FilledButton.tonalIcon(
                      onPressed: onPrint,
                      icon: const Icon(Icons.print_outlined, size: 15),
                      label: const Text('Print', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.picture_as_pdf_outlined, size: 13),
                        label: Text('PDF', style: TextStyle(fontSize: 11)),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.brush_outlined, size: 13),
                        label: Text('Mock', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    selected: {useLivePdf},
                    onSelectionChanged: (_) => onToggleLivePdf(),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    infoBlock,
                    const SizedBox(height: 8),
                    actionButtons,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: infoBlock),
                  const SizedBox(width: 8),
                  actionButtons,
                ],
              );
            },
          ),
        ),"""

if old_header_strip in text:
    text = text.replace(old_header_strip, new_header_strip, 1)
    print('header strip updated!')
else:
    print('old_header_strip not found!')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Step 3 completed!')

