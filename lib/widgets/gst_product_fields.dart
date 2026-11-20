import 'package:flutter/material.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/l10n/app_localizations.dart';

InputDecoration _decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
    );

/// GST unit code (UQC) for GSTR-1. '' = Auto: the export derives it from
/// the free-text [unit] (shown in the label when recognised).
class UqcDropdown extends StatelessWidget {
  final String value;
  final String unit;
  final bool isService;
  final ValueChanged<String> onChanged;

  const UqcDropdown({
    super.key,
    required this.value,
    required this.unit,
    required this.isService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auto = GstUtils.suggestUqc(unit, isService: isService);
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: GstUtils.uqcCodes.containsKey(value) ? value : '',
      decoration: _decoration(l10n.productUqcLabel, Icons.straighten),
      items: [
        DropdownMenuItem(
            value: '',
            child: Text(auto == null
                ? l10n.productUqcAutoUnknown
                : l10n.productUqcAuto(GstUtils.uqcLabel(auto)))),
        for (final code in GstUtils.uqcCodes.keys)
          DropdownMenuItem(value: code, child: Text(GstUtils.uqcLabel(code))),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }
}

/// GST type of a 0 % item for GSTR-1 Table 8: '' nil-rated | 'exempt' | 'non_gst'.
class GstCategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const GstCategoryDropdown(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: const ['', 'exempt', 'non_gst'].contains(value) ? value : '',
      decoration: _decoration(l10n.productGstTypeLabel, Icons.category_outlined),
      items: [
        DropdownMenuItem(value: '', child: Text(l10n.productGstTypeNil)),
        DropdownMenuItem(value: 'exempt', child: Text(l10n.productGstTypeExempt)),
        DropdownMenuItem(value: 'non_gst', child: Text(l10n.productGstTypeNonGst)),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }
}
