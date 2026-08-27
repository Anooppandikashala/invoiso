import 'package:flutter/material.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// Step 3 of the onboarding wizard: opt-in toggle for the Purchase Bills /
/// Suppliers dashboard tabs. Off by default; can be changed later in
/// Settings > Suppliers.
class OnboardingStepPurchaseBills extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const OnboardingStepPurchaseBills({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.local_shipping_outlined,
                color: enabled
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.onboardingEnablePurchaseBillsSuppliersLabel,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(l10n.onboardingEnablePurchaseBillsSuppliersSubtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
