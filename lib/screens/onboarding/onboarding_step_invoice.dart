import 'package:flutter/material.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/common/supported_currencies.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// Step 2 of the onboarding wizard: currency, date format and invoice
/// numbering. All values live in [OnboardingScreen]'s state.
class OnboardingStepInvoice extends StatelessWidget {
  final String selectedCurrencyCode;
  final ValueChanged<String> onCurrencyChanged;
  final DateFormatOption selectedDateFormat;
  final ValueChanged<DateFormatOption> onDateFormatChanged;
  final TextEditingController startingNumberController;
  final bool leadingZeros;
  final ValueChanged<bool> onLeadingZerosChanged;
  final TextEditingController taxRateController;

  const OnboardingStepInvoice({
    super.key,
    required this.selectedCurrencyCode,
    required this.onCurrencyChanged,
    required this.selectedDateFormat,
    required this.onDateFormatChanged,
    required this.startingNumberController,
    required this.leadingZeros,
    required this.onLeadingZerosChanged,
    required this.taxRateController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CurrencyField(
            selectedCode: selectedCurrencyCode,
            onChanged: onCurrencyChanged,
            label: l10n.onboardingCurrencyLabel,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DateFormatOption>(
            isExpanded: true,
            value: selectedDateFormat,
            decoration: InputDecoration(
              labelText: l10n.onboardingDateFormatLabel,
              prefixIcon: const Icon(Icons.calendar_today),
              border: const OutlineInputBorder(),
            ),
            items: DateFormatOption.values
                .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(dateFormatOptionLabel(context, opt),
                        maxLines: 1, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) {
              if (value != null) onDateFormatChanged(value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: startingNumberController,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: l10n.onboardingInvoiceStartingNumberLabel,
              prefixIcon: const Icon(Icons.looks_one_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.onboardingLeadingZerosLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(l10n.onboardingLeadingZerosSubtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
                Switch(value: leadingZeros, onChanged: onLeadingZerosChanged),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: taxRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.onboardingDefaultTaxRateLabel,
              prefixIcon: const Icon(Icons.percent_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  final String selectedCode;
  final ValueChanged<String> onChanged;
  final String label;

  const _CurrencyField({
    required this.selectedCode,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final current = SupportedCurrencies.fromCode(selectedCode);
    return Autocomplete<CurrencyOption>(
      key: ValueKey(selectedCode),
      initialValue: TextEditingValue(
          text: '${current.symbol}  ${current.name} (${current.code})'),
      displayStringForOption: (c) => '${c.symbol}  ${c.name} (${c.code})',
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return SupportedCurrencies.all;
        final query = value.text.toLowerCase();
        return SupportedCurrencies.all.where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.code.toLowerCase().contains(query) ||
            c.symbol.toLowerCase().contains(query));
      },
      onSelected: (c) => onChanged(c.code),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.attach_money),
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
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final c = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text('${c.symbol}  ${c.name}'),
                    trailing: Text(c.code),
                    onTap: () => onSelected(c),
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
