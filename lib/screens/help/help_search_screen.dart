import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:invoiso/common/app_config.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/services/help_search/help_search_service.dart';
import 'package:invoiso/services/help_search/highlight_util.dart';
import 'package:invoiso/services/help_search/searchable_item.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Help & Settings search as a centered popup dialog.
Future<void> showHelpSearchDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _HelpSearchDialog(),
  );
}

void _contactSupport() {
  launchUrl(Uri.parse(AppConfig.supportForm), mode: LaunchMode.externalApplication);
}

class _HelpSearchDialog extends StatelessWidget {
  const _HelpSearchDialog();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 700;
    final width = isCompact ? size.width - 24 : math.min(1400.0, size.width * 0.92);
    final height = isCompact ? size.height - 64 : math.min(900.0, size.height * 0.88);
    return Dialog(
      insetPadding:
          EdgeInsets.symmetric(horizontal: isCompact ? 12 : 40, vertical: isCompact ? 32 : 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.large)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: width, height: height, child: const HelpSearchScreen()),
    );
  }
}

class HelpSearchScreen extends StatefulWidget {
  const HelpSearchScreen({super.key});

  @override
  State<HelpSearchScreen> createState() => _HelpSearchScreenState();
}

class _HelpSearchScreenState extends State<HelpSearchScreen> {
  static const _wideBreakpoint = 900.0;
  static const _categoryOrder = [
    'FAQ',
    'Settings',
    'Invoices',
    'Dashboard',
    'Reports',
    'Products',
    'Customers',
  ];

  final _controller = TextEditingController();
  List<SearchableItem> _index = [];
  List<String> _categories = [];
  String? _selectedCategory; // null = All
  List<ScoredSearchResult> _results = [];
  bool _loading = true;

  SearchableItem? _selected; // wide layout: which result is shown in the detail pane
  String? _expandedId; // narrow layout: which result is expanded inline

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final index = await HelpSearchService.buildIndex();
    if (!mounted) return;
    final groups = index.map((i) => i.path.isNotEmpty ? i.path.first : 'Other').toSet();
    final categories = [
      ..._categoryOrder.where(groups.contains),
      ...groups.where((g) => !_categoryOrder.contains(g)).toList()..sort(),
    ];
    setState(() {
      _index = index;
      _categories = categories;
      _loading = false;
    });
  }

  Set<String> get _queryWords => _controller.text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 2)
      .toSet();

  List<SearchableItem> get _scopedIndex {
    if (_selectedCategory == null) return _index;
    return _index.where((i) => i.path.isNotEmpty && i.path.first == _selectedCategory).toList();
  }

  void _onQueryChanged(String query) => _refreshResults();

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    _refreshResults();
  }

  void _refreshResults() {
    final scoped = _scopedIndex;
    final query = _controller.text;
    List<ScoredSearchResult> results;
    if (query.trim().isEmpty) {
      // Browsing a category with no query yet: list everything in it alphabetically.
      results = _selectedCategory == null
          ? const []
          : ((scoped.toList()..sort((a, b) => a.question.compareTo(b.question)))
              .map((item) => ScoredSearchResult(item, 100))
              .toList());
    } else {
      results = HelpSearchService.search(scoped, query);
    }
    setState(() {
      _results = results;
      _expandedId = null;
      _selected = results.isEmpty ? null : results.first.item;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Search Help & Settings',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: _contactSupport,
                  icon: const Icon(Icons.support_agent_outlined, size: 18),
                  label: const Text('Contact Support'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          if (!_loading && _categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _CategoryChips(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: _onCategorySelected,
              ),
            ),
          if ((_controller.text.trim().isNotEmpty || _selectedCategory != null) && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                _results.isEmpty
                    ? 'No matching results'
                    : '${_results.length} result${_results.length == 1 ? '' : 's'}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= _wideBreakpoint;
                if (_loading) return const Center(child: CircularProgressIndicator());
                if (_results.isNotEmpty) {
                  return isWide ? _buildMasterDetail(colors) : _buildAccordionList(colors);
                }
                return _controller.text.trim().isEmpty && _selectedCategory == null
                    ? _EmptyState(
                        icon: Icons.search,
                        text: 'Type to search, or pick a category to browse',
                        colors: colors,
                      )
                    : _EmptyState(
                        icon: Icons.search_off,
                        text: "Can't find what you're looking for?",
                        colors: colors,
                        actionLabel: 'Contact Support',
                        onAction: _contactSupport,
                      );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _SearchField(controller: _controller, onChanged: _onQueryChanged),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterDetail(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: _results.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final item = _results[i].item;
                    final isSelected = item.id == _selected?.id;
                    return _ResultRow(
                      item: item,
                      selected: isSelected,
                      queryWords: _queryWords,
                      onTap: () => setState(() => _selected = item),
                    );
                  },
                ),
        ),
        VerticalDivider(width: 1, color: colors.outlineVariant),
        Expanded(
          child: _selected == null
              ? _EmptyState(
                  icon: Icons.chat_bubble_outline,
                  text: 'Select a question to see the answer',
                  colors: colors,
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  child: SingleChildScrollView(
                    child: _AnswerContent(item: _selected!, queryWords: _queryWords),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAccordionList(ColorScheme colors) {
    if (_results.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final item = _results[i].item;
        final expanded = item.id == _expandedId;
        return _ExpandableResultCard(
          item: item,
          expanded: expanded,
          queryWords: _queryWords,
          onTap: () => setState(() => _expandedId = expanded ? null : item.id),
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, label: 'All', value: null),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _chip(context, label: category, value: category),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required String? value}) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Ask a question, e.g. "forgot password"',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  final SearchableItem item;
  final bool selected;
  final Set<String> queryWords;
  final VoidCallback onTap;

  const _ResultRow({
    required this.item,
    required this.selected,
    required this.queryWords,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isFaq = item.type == SearchableItemType.faq;
    final highlightColor = colors.primary.withValues(alpha: 0.28);
    final questionStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: selected ? colors.onPrimaryContainer : null,
        );
    final pathStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: selected
              ? colors.onPrimaryContainer.withValues(alpha: 0.7)
              : colors.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isFaq ? Icons.help_outline : Icons.settings_outlined,
                  size: 18,
                  color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        highlightedTextSpan(item.question, queryWords,
                            baseStyle: questionStyle, highlightColor: highlightColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        highlightedTextSpan(item.pathLabel, queryWords,
                            baseStyle: pathStyle, highlightColor: highlightColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableResultCard extends StatelessWidget {
  final SearchableItem item;
  final bool expanded;
  final Set<String> queryWords;
  final VoidCallback onTap;

  const _ExpandableResultCard({
    required this.item,
    required this.expanded,
    required this.queryWords,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isFaq = item.type == SearchableItemType.faq;
    final highlightColor = colors.primary.withValues(alpha: 0.28);
    final questionStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    final pathStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.medium)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isFaq ? colors.primaryContainer : colors.secondaryContainer,
                    child: Icon(
                      isFaq ? Icons.help_outline : Icons.settings_outlined,
                      size: 18,
                      color: isFaq ? colors.onPrimaryContainer : colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          highlightedTextSpan(item.question, queryWords,
                              baseStyle: questionStyle, highlightColor: highlightColor),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          highlightedTextSpan(item.pathLabel, queryWords,
                              baseStyle: pathStyle, highlightColor: highlightColor),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        parseEmphasisSpans(
                          item.answer,
                          baseStyle: Theme.of(context).textTheme.bodyMedium,
                          emphasisStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _AnswerContent extends StatelessWidget {
  final SearchableItem item;
  final Set<String> queryWords;

  const _AnswerContent({required this.item, required this.queryWords});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          highlightedTextSpan(
            item.question,
            queryWords,
            baseStyle: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
            highlightColor: colors.primary.withValues(alpha: 0.28),
          ),
        ),
        const SizedBox(height: 10),
        _Breadcrumb(path: item.path, queryWords: queryWords),
        const SizedBox(height: 20),
        Divider(color: colors.outlineVariant),
        const SizedBox(height: 20),
        Text.rich(
          parseEmphasisSpans(
            item.answer,
            baseStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            emphasisStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final List<String> path;
  final Set<String> queryWords;

  const _Breadcrumb({required this.path, required this.queryWords});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlightColor = colors.primary.withValues(alpha: 0.28);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < path.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.chevron_right, size: 16, color: colors.onSurfaceVariant),
            ),
          Text.rich(
            highlightedTextSpan(
              path[i],
              queryWords,
              baseStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: i == path.length - 1 ? colors.onSurface : colors.onSurfaceVariant,
                    fontWeight: i == path.length - 1 ? FontWeight.w600 : FontWeight.w400,
                  ),
              highlightColor: highlightColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colors;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.text,
    required this.colors,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: colors.onSurfaceVariant)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.support_agent_outlined, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
