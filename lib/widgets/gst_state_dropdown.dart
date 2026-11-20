import 'package:flutter/material.dart';
import 'package:invoiso/common/gst_utils.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';

/// India GST state picker ('' = not set). [onChanged] null = read-only,
/// e.g. while a valid GSTIN fixes the state.
class GstStateDropdown extends StatelessWidget {
  final String value;
  final String label;
  final ValueChanged<String>? onChanged;

  const GstStateDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: GstUtils.states.containsKey(value) ? value : '',
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.map_outlined),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
      ),
      items: [
        DropdownMenuItem(
            value: '',
            child: Text(AppLocalizations.of(context)!.gstStateNotSetLabel)),
        for (final code in GstUtils.states.keys)
          DropdownMenuItem(
              value: code, child: Text(GstUtils.stateLabel(code))),
      ],
      onChanged: onChanged == null ? null : (v) => onChanged!(v ?? ''),
    );
  }
}
