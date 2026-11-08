import re

file_path = r'c:\billing\invoiso\lib\screens\settings\pdf_settings_screen_v2.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Fix letterhead header row
old_lh = '''          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Print invoices on physical company paper with pre-printed header and footer.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _previewedLetterheadEnabled,
                onChanged: (v) {
                  setState(() => _previewedLetterheadEnabled = v);
                  _schedulePdfPreviewUpdate(immediate: true);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),'''

new_lh = '''          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Print invoices on physical company paper with pre-printed header and footer.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _previewedLetterheadEnabled,
                onChanged: (v) {
                  setState(() => _previewedLetterheadEnabled = v);
                  _schedulePdfPreviewUpdate(immediate: true);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),'''

assert old_lh in text, 'old_lh not found'
text = text.replace(old_lh, new_lh)

# 2. Fix margins presets row
old_margins_preset = '''            Row(
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
            ),'''

new_margins_preset = '''            Column(
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
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    InkWell(
                      onTap: () => _applyMarginPreset(40, 25, 10, 10),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
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
            ),'''

assert old_margins_preset in text, 'old_margins_preset not found'
text = text.replace(old_margins_preset, new_margins_preset)

# 3. Fix _marginInputField label text
old_input = "labelText: '$label (mm)',"
new_input = "labelText: label,"
assert old_input in text, 'old_input not found'
text = text.replace(old_input, new_input)

# 4. Fix _PreviewPanel header strip
old_panel_header = '''        Container(
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
                                color: Colors.teal, size: 16),
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
        ),'''

new_panel_header = '''        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 460;
              final infoBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: AppFontSize.large,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSaved)
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
                      if (letterheadMode)
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
              );

              final toggleBlock = SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.picture_as_pdf_outlined, size: 14),
                    label: Text('Print Preview', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.brush_outlined, size: 14),
                    label: Text('Sketch', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {useLivePdf},
                onSelectionChanged: (_) => onToggleLivePdf(),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    infoBlock,
                    const SizedBox(height: 8),
                    toggleBlock,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: infoBlock),
                  const SizedBox(width: 12),
                  toggleBlock,
                ],
              );
            },
          ),
        ),'''

assert old_panel_header in text, 'old_panel_header not found'
text = text.replace(old_panel_header, new_panel_header)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print('All 4 layout overflow issues fixed successfully!')

