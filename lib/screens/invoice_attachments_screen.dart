import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:invoiso/database/invoice_attachment_service.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/invoice.dart';
import 'package:invoiso/models/invoice_attachment.dart';
import 'package:invoiso/utils/error_handler.dart';
import 'package:invoiso/services/backend_services.dart';

/// Customer / Private photo tabs for one invoice. Edits a copy of the drafts
/// it is given and returns them on Done (null on back / discard) — the caller
/// decides when they hit disk (`InvoiceAttachmentService.sync`).
class InvoiceAttachmentsScreen extends StatefulWidget {
  final String document; // shown in the title, e.g. the invoice number
  final List<AttachmentDraft> initial;

  const InvoiceAttachmentsScreen(
      {super.key, required this.document, required this.initial});

  static Future<List<AttachmentDraft>?> open(BuildContext context,
          {required String document, required List<AttachmentDraft> initial}) =>
      showDialog<List<AttachmentDraft>>(
          context: context,
          barrierDismissible: false, // Esc / ✕ go through the discard check
          builder: (_) =>
              InvoiceAttachmentsScreen(document: document, initial: initial));

  /// For an already-saved invoice (invoice list, details dialog): edits and
  /// saves straight away. True when something was saved.
  static Future<bool> editSaved(BuildContext context, Invoice invoice) async {
    final drafts = await BackendServices.attachments.draftsFor(invoice.id);
    if (!context.mounted) return false;
    final result = await open(context,
        document: '${invoice.type} #${invoice.invoiceNumber ?? invoice.id}',
        initial: drafts);
    if (result == null) return false;
    try {
      await BackendServices.attachments.sync(invoice.id, result);
      return true;
    } catch (e) {
      if (context.mounted) {
        AppError.show(context,
            AppLocalizations.of(context)!.attachmentsSaveFailedMessage('$e'));
      }
      return false;
    }
  }

  @override
  State<InvoiceAttachmentsScreen> createState() =>
      _InvoiceAttachmentsScreenState();
}

String _signature(List<AttachmentDraft> drafts) => jsonEncode([
      for (final d in drafts)
        [d.id, d.path, d.isPublic, (d.caption ?? '').trim()],
    ]);

class _InvoiceAttachmentsScreenState extends State<InvoiceAttachmentsScreen>
    with SingleTickerProviderStateMixin {
  static const _limit = InvoiceAttachmentService.publicLimit;

  late final List<AttachmentDraft> _drafts = [
    for (final d in widget.initial)
      AttachmentDraft(
          id: d.id, path: d.path, isPublic: d.isPublic, caption: d.caption),
  ];
  late final String _initialSignature;
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));
  final _captions = <AttachmentDraft, TextEditingController>{};

  int get _publicCount => _drafts.where((d) => d.isPublic).length;

  TextEditingController _caption(AttachmentDraft d) =>
      _captions.putIfAbsent(d, () {
        final c = TextEditingController(text: d.caption ?? '');
        c.addListener(() => d.caption = c.text);
        return c;
      });

  @override
  void initState() {
    super.initState();
    _initialSignature = _signature(_drafts); // before any edit
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _captions.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (_signature(_drafts) == _initialSignature) return true;
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.attachmentsDiscardTitle),
            content: Text(l10n.attachmentsDiscardBody),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.actionCancel)),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.actionDiscard)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _addPhotos() async {
    final l10n = AppLocalizations.of(context)!;
    final full = _publicCount >= _limit;
    var asPublic = _tabs.index == 0 && !full;
    Widget picker(BuildContext ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(l10n.attachmentsAddTitle,
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(l10n.attachmentsAddAsLabel,
                    style: Theme.of(ctx).textTheme.labelMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(l10n.attachmentsAddAsCustomer),
                        enabled: !full),
                    ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.lock_outline),
                        label: Text(l10n.attachmentsAddAsPrivate)),
                  ],
                  selected: {asPublic},
                  onSelectionChanged: (s) =>
                      setSheetState(() => asPublic = s.first),
                ),
              ),
              if (full)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Text(l10n.attachmentsCustomerFullHint(_limit),
                      style: Theme.of(ctx).textTheme.bodySmall),
                ),
              const Divider(height: 24),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.attachmentsTakePhoto),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
              ListTile(
                leading: Icon(Platform.isAndroid
                    ? Icons.photo_library_outlined
                    : Icons.folder_open_outlined),
                title: Text(Platform.isAndroid
                    ? l10n.attachmentsChooseGallery
                    : l10n.attachmentsChooseFiles),
                onTap: () => Navigator.pop(ctx, 'pick'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    final source = await (Platform.isAndroid
        ? showModalBottomSheet<String>(
            context: context, showDragHandle: true, builder: picker)
        : showDialog<String>(
            context: context,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: picker(ctx)),
              ),
            ),
          ));
    if (source == null) return;

    List<String> paths;
    if (source == 'camera') {
      final x = await ImagePicker().pickImage(source: ImageSource.camera);
      paths = x == null ? [] : [x.path];
    } else if (Platform.isAndroid) {
      paths = (await ImagePicker().pickMultiImage()).map((x) => x.path).toList();
    } else {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: true);
      paths = r?.paths.whereType<String>().toList() ?? [];
    }
    if (paths.isEmpty || !mounted) return;

    if (asPublic) {
      final room = _limit - _publicCount;
      if (paths.length > room) {
        AppError.show(context,
            l10n.attachmentsLimitReachedMessage(_limit, paths.length - room));
        paths = paths.take(room).toList();
      }
    }
    setState(() {
      _drafts.addAll(
          paths.map((p) => AttachmentDraft(path: p, isPublic: asPublic)));
    });
    _tabs.animateTo(asPublic ? 0 : 1);
  }

  void _swap(List<AttachmentDraft> items, int i, int j) {
    final a = _drafts.indexOf(items[i]);
    final b = _drafts.indexOf(items[j]);
    setState(() {
      _drafts[a] = items[j];
      _drafts[b] = items[i];
    });
  }

  Future<void> _delete(AttachmentDraft d) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.attachmentsDeleteTitle),
        content: SizedBox(height: 160, child: _Thumb(d.path)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionDelete)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _drafts.remove(d));
    _captions.remove(d)?.dispose();
  }

  void _openViewer(List<AttachmentDraft> items, int index) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _AttachmentViewer(
          items: items, initialIndex: index, captionFor: _caption),
    );
  }

  Widget _card(List<AttachmentDraft> items, int i) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final d = items[i];
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed 4:3 photo area so photos line up whatever the caption length.
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Whole photo (letterboxed), as it will print on the PDF.
                InkWell(
                    onTap: () => _openViewer(items, i),
                    child: ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: _Thumb(d.path, fit: BoxFit.contain))),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    child: PopupMenuButton<String>(
                      tooltip: '',
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (action) {
                        switch (action) {
                          case 'move':
                            setState(() => d.isPublic = !d.isPublic);
                          case 'left':
                            _swap(items, i, i - 1);
                          case 'right':
                            _swap(items, i, i + 1);
                          case 'delete':
                            _delete(d);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'move',
                          // Customer tab full → can't move another one in.
                          enabled: d.isPublic || _publicCount < _limit,
                          child: _MenuRow(
                              d.isPublic
                                  ? Icons.lock_outline
                                  : Icons.visibility_outlined,
                              d.isPublic
                                  ? l10n.attachmentsMoveToPrivate
                                  : l10n.attachmentsMoveToCustomer),
                        ),
                        PopupMenuItem(
                            value: 'left',
                            enabled: i > 0,
                            child: _MenuRow(
                                Icons.arrow_back, l10n.attachmentsMoveLeft)),
                        PopupMenuItem(
                            value: 'right',
                            enabled: i < items.length - 1,
                            child: _MenuRow(Icons.arrow_forward,
                                l10n.attachmentsMoveRight)),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                            value: 'delete',
                            child: _MenuRow(Icons.delete_outline,
                                l10n.actionDelete, Colors.red)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: scheme.surfaceContainerLow,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _caption(d),
                maxLength: 120,
                minLines: 1,
                maxLines: 3, // scrolls past 3 lines; full text in the viewer
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  hintText: l10n.attachmentsCaptionHint,
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(bool public) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final items = _drafts.where((d) => d.isPublic == public).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                public
                    ? l10n.attachmentsCustomerSubtitle
                    : l10n.attachmentsPrivateSubtitle,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 56, color: scheme.outline),
                      const SizedBox(height: 10),
                      Text(l10n.attachmentsEmptyHint,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78, // 4:3 photo + room for a 3-line caption
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _card(items, i),
                ),
        ),
      ],
    );
  }

  Future<void> _close() async {
    if (await _confirmDiscard() && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final radius = narrow ? Radius.zero : const Radius.circular(16);

    final content = Column(
      children: [
        // Header — same look as the payment dialog.
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: BoxDecoration(
            color: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
            borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.attachmentsTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(widget.document,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: l10n.actionClose,
                  onPressed: _close,
                ),
              ],
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          labelColor: theme.primaryColor,
          indicatorColor: theme.primaryColor,
          tabs: [
            Tab(
              height: 46,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.visibility_outlined, size: 18),
                const SizedBox(width: 8),
                Text(l10n.attachmentsTabCustomer(_publicCount, _limit)),
              ]),
            ),
            Tab(
              height: 46,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: 8),
                Text(l10n.attachmentsTabPrivate(_drafts.length - _publicCount)),
              ]),
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                  controller: _tabs, children: [_tab(true), _tab(false)]),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _addPhotos,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.attachmentsAddTitle),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _close, child: Text(l10n.actionCancel)),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, _drafts),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l10n.attachmentsDone),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: narrow
          ? Dialog.fullscreen(child: Material(child: content))
          : Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880, maxHeight: 680),
                child: SizedBox(width: 880, height: 680, child: content),
              ),
            ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow(this.icon, this.label, [this.color]);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ]);
}

/// Thumbnail with a placeholder when the file is gone (e.g. a JSON restore
/// brings rows back without images).
class _Thumb extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final int? cacheWidth;
  const _Thumb(this.path, {this.fit = BoxFit.cover, this.cacheWidth = 440});

  @override
  Widget build(BuildContext context) => Image.file(
        File(path),
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined),
              Text(AppLocalizations.of(context)!.attachmentsMissingFile,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

/// Photo preview as a dialog (not a full-window page), so closing it can't
/// be confused with closing the app window.
class _AttachmentViewer extends StatefulWidget {
  final List<AttachmentDraft> items;
  final int initialIndex;
  final TextEditingController Function(AttachmentDraft) captionFor;
  const _AttachmentViewer(
      {required this.items, required this.initialIndex, required this.captionFor});

  @override
  State<_AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<_AttachmentViewer> {
  late int _index = widget.initialIndex;
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) => _pages.animateToPage(_index + delta,
      duration: const Duration(milliseconds: 200), curve: Curves.easeOut);

  Widget _arrow(IconData icon, VoidCallback? onPressed) => IconButton.filled(
        style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white),
        icon: Icon(icon),
        onPressed: onPressed,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = widget.items.length;
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Text('${_index + 1} / $count',
                      style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: l10n.actionClose,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pages,
                    itemCount: count,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => InteractiveViewer(
                      maxScale: 5,
                      child: Center(
                          child: _Thumb(widget.items[i].path,
                              fit: BoxFit.contain, cacheWidth: null)),
                    ),
                  ),
                  if (count > 1) ...[
                    Positioned(
                        left: 12,
                        child: _arrow(Icons.chevron_left,
                            _index > 0 ? () => _go(-1) : null)),
                    Positioned(
                        right: 12,
                        child: _arrow(Icons.chevron_right,
                            _index < count - 1 ? () => _go(1) : null)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextField(
                key: ValueKey(widget.items[_index]),
                controller: widget.captionFor(widget.items[_index]),
                maxLength: 120,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(Icons.short_text, color: Colors.white54),
                  hintText: l10n.attachmentsCaptionHint,
                  hintStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
