import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// One-line list text the user can copy: selectable (drag / double-click,
/// long-press on touch), plus a copy icon on hover that copies [copyValue]
/// (defaults to [text]) in one click. Used for invoice numbers and
/// customer / product names in the management lists.
class CopyableText extends StatefulWidget {
  final String text;
  final String? copyValue;
  final TextStyle? style;

  const CopyableText(this.text, {super.key, this.copyValue, this.style});

  @override
  State<CopyableText> createState() => _CopyableTextState();
}

class _CopyableTextState extends State<CopyableText> {
  bool _hover = false;

  Future<void> _copy() async {
    final value = widget.copyValue ?? widget.text;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.copiedToClipboardMessage(value)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SelectionArea(
              child: Text(widget.text,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: widget.style),
            ),
          ),
          // Space kept so the text doesn't shift when the icon shows.
          Visibility(
            visible: _hover,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Tooltip(
              message: AppLocalizations.of(context)!.copyToClipboardTooltip,
              child: InkWell(
                onTap: _copy,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
