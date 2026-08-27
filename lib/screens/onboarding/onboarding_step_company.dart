import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/app_countries.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/widgets/language_picker.dart';

/// Step 1 of the onboarding wizard: language, theme, and core company
/// details. All values live in [OnboardingScreen]'s state — this widget
/// only reads/reports them via the passed-in controllers/callbacks.
class OnboardingStepCompany extends ConsumerWidget {
  final TextEditingController nameController;
  final String selectedCountry;
  final ValueChanged<String> onCountryChanged;
  final File? logoFile;
  final String? base64Logo;
  final VoidCallback onPickLogo;

  const OnboardingStepCompany({
    super.key,
    required this.nameController,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.logoFile,
    required this.base64Logo,
    required this.onPickLogo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;

    Widget logoPreview;
    if (logoFile != null) {
      logoPreview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(logoFile!, fit: BoxFit.contain),
      );
    } else if (base64Logo != null && base64Logo!.isNotEmpty) {
      logoPreview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(base64Decode(base64Logo!), fit: BoxFit.contain),
      );
    } else {
      logoPreview = Icon(Icons.add_photo_alternate_outlined,
          size: 36, color: primaryColor);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LanguagePicker(),
          const SizedBox(height: 20),
          Text(l10n.commonTheme,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.themeLight)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.themeDark)),
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(l10n.themeSystem)),
            ],
            selected: {ref.watch(themeModeProvider)},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              final mode = selection.first;
              ref.read(themeModeProvider.notifier).state = mode;
              ref
                  .read(settingsRepositoryProvider)
                  .setThemeMode(themeModeToKey(mode));
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: onPickLogo,
              child: Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: logoPreview,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(l10n.onboardingLogoLabel,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.onboardingCompanyNameLabel,
              prefixIcon: const Icon(Icons.business_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _CountryField(
            selectedCountry: selectedCountry,
            onChanged: onCountryChanged,
            label: l10n.onboardingCountryLabel,
          ),
        ],
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  final String selectedCountry;
  final ValueChanged<String> onChanged;
  final String label;

  const _CountryField({
    required this.selectedCountry,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      key: ValueKey(selectedCountry),
      initialValue: TextEditingValue(text: selectedCountry),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return AppCountries.all;
        return AppCountries.all.where(
          (c) => c.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.public_rounded),
            border: const OutlineInputBorder(),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final country = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(country),
                    onTap: () => onSelected(country),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
