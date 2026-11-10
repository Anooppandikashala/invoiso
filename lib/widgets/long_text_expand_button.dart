import 'package:flutter/material.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// ⤢ suffix button that opens [controller]'s text in a large, resizable
/// editor — same dialog as the Notes "expand" button on the invoice form.
/// Save writes back to [controller]; Cancel discards. [readOnly] shows the
/// text without a Save button.
class LongTextExpandButton extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final int? maxLength;
  final bool readOnly;

  const LongTextExpandButton(
      {super.key,
      required this.title,
      required this.controller,
      this.maxLength,
      this.readOnly = false});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final dialogController = TextEditingController(text: controller.text);
    double width = 480;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    double height = (maxHeight * 0.8).clamp(200, 640);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TextField(
                    controller: dialogController,
                    readOnly: readOnly,
                    maxLength: maxLength,
                    expands: true,
                    maxLines: null,
                    autofocus: !readOnly,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  // Sit inside the box corner, above the 0/N counter row.
                  bottom: maxLength == null ? 4 : 28,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        setDialogState(() {
                          width = (width + details.delta.dx).clamp(320, 800);
                          height = (height + details.delta.dy).clamp(200, maxHeight);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.south_east,
                            size: 20,
                            color: Theme.of(ctx).colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(readOnly ? l10n.actionClose : l10n.actionCancel),
            ),
            if (!readOnly)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, dialogController.text),
                child: Text(l10n.actionSave),
              ),
          ],
        ),
      ),
    );
    if (result != null) controller.text = result;
  }

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.open_in_full, size: 18),
        tooltip: AppLocalizations.of(context)!.tooltipEditInLargerView,
        onPressed: () => _open(context),
      );
}
