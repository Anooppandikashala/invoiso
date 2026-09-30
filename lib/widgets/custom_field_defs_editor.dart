import 'package:flutter/material.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/custom_field_def.dart';

/// Add / rename / reorder / delete list of [CustomFieldDef]s. Shared by the
/// invoice custom fields and customer custom fields settings. Every change
/// hands a new list to [onChanged]; the parent owns the list and persists it.
/// TextFormField keeps its own text/cursor state via the ValueKey on each row,
/// so a parent rebuild on rename doesn't reset it.
class CustomFieldDefsEditor extends StatefulWidget {
  final List<CustomFieldDef> defs;
  final ValueChanged<List<CustomFieldDef>> onChanged;
  final String idPrefix; // 'cf' for invoice fields, 'ccf' for customer fields
  final String newFieldHint;
  final InputDecoration Function(String label, String? hint) decoration;
  // Per-row "print on PDF" toggle (customer custom fields).
  final bool showPdfToggle;

  const CustomFieldDefsEditor({
    super.key,
    required this.defs,
    required this.onChanged,
    required this.idPrefix,
    required this.newFieldHint,
    required this.decoration,
    this.showPdfToggle = false,
  });

  @override
  State<CustomFieldDefsEditor> createState() => _CustomFieldDefsEditorState();
}

class _CustomFieldDefsEditorState extends State<CustomFieldDefsEditor> {
  final _newFieldController = TextEditingController();

  @override
  void dispose() {
    _newFieldController.dispose();
    super.dispose();
  }

  List<CustomFieldDef> _renumbered(List<CustomFieldDef> defs) => [
        for (var i = 0; i < defs.length; i++) defs[i].copyWith(sortOrder: i),
      ];

  void _add() {
    final label = _newFieldController.text.trim();
    if (label.isEmpty) return;
    widget.onChanged([
      ...widget.defs,
      CustomFieldDef(
        id: '${widget.idPrefix}-${DateTime.now().microsecondsSinceEpoch}',
        label: label,
        sortOrder: widget.defs.length,
      ),
    ]);
    _newFieldController.clear();
  }

  void _remove(int index) {
    widget.onChanged([...widget.defs]..removeAt(index));
  }

  void _rename(int index, String label) {
    widget.onChanged(
        [...widget.defs]..[index] = widget.defs[index].copyWith(label: label));
  }

  void _togglePdf(int index) {
    final def = widget.defs[index];
    widget.onChanged([...widget.defs]..[index] =
        def.copyWith(showInPdf: !def.showInPdf));
  }

  void _move(int oldIndex, int newIndex) {
    final defs = [...widget.defs];
    defs.insert(newIndex, defs.removeAt(oldIndex));
    widget.onChanged(_renumbered(defs));
  }

  @override
  Widget build(BuildContext context) {
    final defs = widget.defs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < defs.length; index++) ...[
          Row(
            key: ValueKey(defs[index].id),
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Move up',
                onPressed: index == 0 ? null : () => _move(index, index - 1),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Move down',
                onPressed: index == defs.length - 1
                    ? null
                    : () => _move(index, index + 1),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  initialValue: defs[index].label,
                  decoration: widget.decoration('Field label', null),
                  onChanged: (val) => _rename(index, val),
                ),
              ),
              if (widget.showPdfToggle)
                IconButton(
                  icon: Icon(defs[index].showInPdf
                      ? Icons.print_outlined
                      : Icons.print_disabled_outlined),
                  color: defs[index].showInPdf
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  tooltip: defs[index].showInPdf
                      ? AppLocalizations.of(context)!.customFieldPrintedOnPdfTooltip
                      : AppLocalizations.of(context)!.customFieldNotPrintedOnPdfTooltip,
                  onPressed: () => _togglePdf(index),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete field',
                onPressed: () => _remove(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _newFieldController,
                decoration:
                    widget.decoration('New field label', widget.newFieldHint),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}
