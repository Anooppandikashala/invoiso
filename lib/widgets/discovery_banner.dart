import 'package:flutter/material.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// Dismissible "New: ..." feature-discovery banner. Shared shape for all
/// discovery banners on the dashboard (layout, theme, shortcuts, support) —
/// only colors/copy/action differ between them.
class DiscoveryBanner extends StatelessWidget {
  final bool visible;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Widget title;
  final Widget subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Color actionColor;
  final Color? actionBackgroundColor;
  final VoidCallback onDismiss;
  final Color dismissIconColor;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsetsGeometry margin;
  final double iconSize;

  const DiscoveryBanner({
    super.key,
    required this.visible,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.actionColor,
    this.actionBackgroundColor,
    required this.onDismiss,
    required this.dismissIconColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.margin = const EdgeInsets.only(bottom: 20),
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: visible
          ? Container(
              margin: margin,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  Icon(icon, color: iconColor, size: iconSize),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 2),
                        subtitle,
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: actionColor,
                      backgroundColor: actionBackgroundColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: dismissIconColor,
                    onPressed: onDismiss,
                    tooltip: AppLocalizations.of(context)!.actionDismiss,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
