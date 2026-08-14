import 'package:flutter/material.dart';
import 'package:invoiso/common/constants.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Accessibility'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Keyboard Shortcuts',
                    style: TextStyle(
                        fontSize: AppFontSize.large,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Speed up invoice creation without touching the mouse.',
                  style: TextStyle(
                      fontSize: AppFontSize.small,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: AppShortcuts.all
                          .map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                      ),
                                      child: Text(s.$1,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(s.$2,
                                          style: const TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
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
