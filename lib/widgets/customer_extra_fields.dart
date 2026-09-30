import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/models/custom_field_value.dart';
import 'package:invoiso/models/customer.dart';
import 'package:invoiso/models/customer_field_settings.dart';
import 'package:invoiso/utils/app_date.dart';

/// Form state for [CustomerExtraFields]. [load] a customer (null = new), then
/// [applyTo] the Customer built from the base form fields. Fields whose
/// setting is off are carried through unchanged (from what was loaded, or
/// from `keepFrom`), so switching a setting off never wipes stored data.
class CustomerExtraFieldsController {
  bool shippingSameAsBilling = true;
  final shippingName = TextEditingController();
  final shippingPhone = TextEditingController();
  final shippingAddress = TextEditingController();
  String dob = '';
  final age = TextEditingController();
  String gender = '';
  List<CustomFieldValue> _customValues = const [];
  final Map<String, TextEditingController> _custom = {};

  void load(Customer? c) {
    shippingSameAsBilling = c?.shippingSameAsBilling ?? true;
    shippingName.text = c?.shippingName ?? '';
    shippingPhone.text = c?.shippingPhone ?? '';
    shippingAddress.text = c?.shippingAddress ?? '';
    dob = c?.dob ?? '';
    age.text = c?.age?.toString() ?? '';
    gender = c?.gender ?? '';
    _customValues = c?.customFields ?? const [];
    for (final e in _custom.entries) {
      e.value.text = _valueOf(e.key);
    }
  }

  String _valueOf(String defId) =>
      _customValues.where((v) => v.defId == defId).firstOrNull?.value ?? '';

  TextEditingController customFor(String defId) => _custom.putIfAbsent(
      defId, () => TextEditingController(text: _valueOf(defId)));

  /// [keepFrom]: the stored customer being overwritten, when it isn't the one
  /// that was [load]ed (e.g. "update the existing customer with this phone"
  /// from a blank invoice form) — switched-off fields are then kept from it.
  Customer applyTo(Customer c, CustomerFieldSettings s, {Customer? keepFrom}) {
    final k = keepFrom;
    if (s.shipping || k == null) {
      c.shippingSameAsBilling = shippingSameAsBilling;
      c.shippingName = shippingName.text.trim();
      c.shippingPhone = shippingPhone.text.trim();
      c.shippingAddress = shippingAddress.text.trim();
    } else {
      c.shippingSameAsBilling = k.shippingSameAsBilling;
      c.shippingName = k.shippingName;
      c.shippingPhone = k.shippingPhone;
      c.shippingAddress = k.shippingAddress;
    }
    c.dob = s.dob || k == null ? dob : k.dob;
    c.age = s.age || k == null ? int.tryParse(age.text.trim()) : k.age;
    c.gender = s.gender || k == null ? gender : k.gender;
    c.customFields = s.customFields
        ? [
            for (final def in s.customFieldDefs)
              if (customFor(def.id).text.trim().isNotEmpty)
                CustomFieldValue(
                    defId: def.id,
                    label: def.label,
                    value: customFor(def.id).text.trim()),
          ]
        : k?.customFields ?? _customValues;
    return c;
  }

  void dispose() {
    shippingName.dispose();
    shippingPhone.dispose();
    shippingAddress.dispose();
    age.dispose();
    for (final c in _custom.values) {
      c.dispose();
    }
  }
}

/// Optional customer fields (Ship To, DOB, Age, Gender, custom fields), each
/// shown only when switched on in [settings]. Place inside the parent Form so
/// its validators run with the base fields. Renders nothing when all are off.
class CustomerExtraFields extends StatefulWidget {
  final CustomerExtraFieldsController controller;
  final CustomerFieldSettings settings;
  final bool readOnly;
  // Billing fields for "Copy from billing"; button hidden when null.
  final TextEditingController? billingName;
  final TextEditingController? billingPhone;
  final TextEditingController? billingAddress;
  // Host screen's field style; default is the outlined customer-form style.
  final InputDecoration Function(String label)? decoration;
  // Several fields per row (create-invoice layout) instead of one per row.
  final bool inline;
  // App date-format setting, for showing the DOB.
  final String datePattern;

  const CustomerExtraFields({
    super.key,
    required this.controller,
    required this.settings,
    this.readOnly = false,
    this.billingName,
    this.billingPhone,
    this.billingAddress,
    this.decoration,
    this.inline = false,
    this.datePattern = 'dd/MM/yyyy',
  });

  @override
  State<CustomerExtraFields> createState() => _CustomerExtraFieldsState();
}

class _CustomerExtraFieldsState extends State<CustomerExtraFields> {
  static const _genders = ['male', 'female', 'other'];

  InputDecoration _decoration(String label, IconData icon,
      {String? helperText, Widget? suffixIcon}) {
    final custom = widget.decoration;
    if (custom != null) {
      return custom(label).copyWith(
          helperText: helperText, suffixIcon: suffixIcon, counterText: '');
    }
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
      counterText: '',
      filled: widget.readOnly,
      fillColor: widget.readOnly
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: AppDate.parse(widget.controller.dob) ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => widget.controller.dob = AppDate.dateKey(picked));
  }

  void _copyFromBilling() {
    final c = widget.controller;
    setState(() {
      c.shippingName.text = widget.billingName!.text;
      c.shippingPhone.text = widget.billingPhone?.text ?? '';
      c.shippingAddress.text = widget.billingAddress?.text ?? '';
    });
  }

  // Stacked: each field on its own line. Inline: [perRow] fields per row.
  List<Widget> _layout(List<Widget> fields, int perRow) {
    final gap = SizedBox(height: widget.inline ? 12 : 16);
    if (!widget.inline) return [for (final f in fields) ...[gap, f]];
    return [
      for (var i = 0; i < fields.length; i += perRow) ...[
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = i; j < i + perRow; j++) ...[
              if (j > i) const SizedBox(width: 12),
              Expanded(
                  child: j < fields.length ? fields[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      ],
    ];
  }

  // Small-caps group label + hairline, matching the create-invoice card's
  // own section labels; [trailing] sits at the right end of the line.
  Widget _subheader(String text, {List<Widget> trailing = const []}) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.only(top: widget.inline ? 16 : 24),
      child: Row(
        children: [
          Text(text.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: muted)),
          const SizedBox(width: 8),
          // Controls take the rest of the line, right-aligned, wrapping
          // instead of overflowing in narrow forms / long translations. No
          // LayoutBuilder: the customer dialog is an AlertDialog, which
          // measures intrinsic width.
          Expanded(
            child: trailing.isEmpty
                ? const Divider(height: 1)
                : Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: trailing,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    if (!s.any) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final c = widget.controller;
    final ro = widget.readOnly;
    final dobDate = AppDate.parse(c.dob);

    final personal = <Widget>[
      if (s.dob)
        TextFormField(
          key: ValueKey('dob-${c.dob}'),
          initialValue: dobDate == null
              ? ''
              // en_US like PDF dates: 'bo' has no intl locale data.
              : DateFormat(widget.datePattern, 'en_US').format(dobDate),
          readOnly: true,
          onTap: ro ? null : _pickDob,
          decoration: _decoration(l10n.customerFieldDobLabel, Icons.cake_outlined,
              suffixIcon: ro
                  ? null
                  : c.dob.isEmpty
                      ? const Icon(Icons.calendar_today_outlined, size: 18)
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: l10n.customerFieldClearDobTooltip,
                          onPressed: () => setState(() => c.dob = ''),
                        )),
        ),
      // DOB wins: whenever a DOB is stored (even with the DOB setting off),
      // age is computed from it — same rule as Customer.ageOn used for the
      // invoice snapshot. The manual age is kept but unused.
      if (s.age && dobDate != null)
        TextFormField(
          key: ValueKey('age-${c.dob}'),
          initialValue: '${Customer.ageFromDob(c.dob, DateTime.now())}',
          readOnly: true,
          decoration: _decoration(l10n.customerFieldAgeLabel, Icons.numbers_outlined,
              suffixIcon: Tooltip(
                message: l10n.customerFieldAgeFromDobHelper,
                child: const Icon(Icons.info_outline, size: 18),
              )),
        )
      else if (s.age)
        TextFormField(
          controller: c.age,
          readOnly: ro,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3,
          decoration: _decoration(l10n.customerFieldAgeLabel, Icons.numbers_outlined),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return null;
            final n = int.tryParse(t);
            return n == null || n > 150 ? l10n.customerFieldAgeInvalidMessage : null;
          },
        ),
      if (s.gender)
        DropdownButtonFormField<String>(
          value: _genders.contains(c.gender) ? c.gender : null,
          isExpanded: true,
          isDense: true,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: _decoration(l10n.customerFieldGenderLabel, Icons.wc_outlined),
          items: [
            DropdownMenuItem(value: '', child: Text(l10n.customerFieldGenderNotSpecified)),
            DropdownMenuItem(value: 'male', child: Text(l10n.customerFieldGenderMale)),
            DropdownMenuItem(value: 'female', child: Text(l10n.customerFieldGenderFemale)),
            DropdownMenuItem(value: 'other', child: Text(l10n.customerFieldGenderOther)),
          ],
          onChanged: ro ? null : (v) => setState(() => c.gender = v ?? ''),
        ),
    ];

    final custom = <Widget>[
      if (s.customFields)
        for (final def in s.customFieldDefs)
          TextFormField(
            controller: c.customFor(def.id),
            readOnly: ro,
            maxLength: 200,
            decoration: _decoration(def.label, Icons.label_outline),
          ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (personal.isNotEmpty) ...[
          _subheader(l10n.customerFieldPersonalDetailsHeader),
          ..._layout(personal, 3),
        ],
        if (custom.isNotEmpty) ...[
          _subheader(l10n.customerFieldAdditionalDetailsHeader),
          ..._layout(custom, 3),
        ],
        if (s.shipping) ...[
          _subheader(l10n.customerFieldShipToHeader, trailing: [
            if (!ro && !c.shippingSameAsBilling && widget.billingName != null)
              TextButton.icon(
                onPressed: _copyFromBilling,
                icon: const Icon(Icons.content_copy, size: 14),
                label: Text(l10n.customerFieldCopyFromBillingButton,
                    style: const TextStyle(fontSize: 12.5)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: ro
                  ? null
                  : () => setState(() =>
                      c.shippingSameAsBilling = !c.shippingSameAsBilling),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: c.shippingSameAsBilling,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: ro
                        ? null
                        : (v) => setState(
                            () => c.shippingSameAsBilling = v ?? true),
                  ),
                  Flexible(
                    child: Text(l10n.customerFieldShippingSameAsBillingLabel,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ]),
          if (!c.shippingSameAsBilling) ...[
            ..._layout([
              TextFormField(
                controller: c.shippingName,
                readOnly: ro,
                maxLength: 100,
                decoration: _decoration(
                    l10n.customerFieldRecipientNameLabel, Icons.person_outline),
              ),
              TextFormField(
                controller: c.shippingPhone,
                readOnly: ro,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 12,
                decoration: _decoration(
                    l10n.customerFieldRecipientPhoneLabel, Icons.phone_outlined),
              ),
            ], 2),
            ..._layout([
              TextFormField(
                controller: c.shippingAddress,
                readOnly: ro,
                maxLines: widget.inline ? 2 : 3,
                maxLength: 500,
                decoration: _decoration(
                    l10n.customerFieldShippingAddressLabel, Icons.local_shipping_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.customerFieldShippingAddressRequiredMessage
                    : null,
              ),
            ], 1),
          ],
        ],
      ],
    );
  }
}

/// CSV header prefix for customer custom fields: `custom:<field label>`.
const customerCsvCustomPrefix = 'custom:';

// Optional columns (shipping_*, dob, age, gender, custom:<label>). A column
// missing from the CSV keeps the existing customer's value, so importing an
// old-format CSV over duplicates doesn't wipe these fields. Invalid
// dob/age/gender values import as blank instead of failing the row.
// custom:<label> headers match current definitions by label (case-
// insensitive); unknown labels are ignored, not auto-created.
void applyCustomerCsvExtraFields(Customer c, List<String> headers,
    String Function(String col) field, Customer? existing,
    List<CustomFieldDef> defs) {
  String pick(String col, String old) => headers.contains(col) ? field(col) : old;
  c.shippingName = pick('shipping_name', existing?.shippingName ?? '');
  c.shippingPhone = pick('shipping_phone', existing?.shippingPhone ?? '');
  c.shippingAddress = pick('shipping_address', existing?.shippingAddress ?? '');
  c.shippingSameAsBilling = headers.contains('shipping_address')
      ? c.shippingAddress.isEmpty
      : existing?.shippingSameAsBilling ?? true;
  if (headers.contains('dob')) {
    final d = DateTime.tryParse(field('dob'));
    c.dob = d == null || d.isAfter(DateTime.now()) ? '' : AppDate.dateKey(d);
  } else {
    c.dob = existing?.dob ?? '';
  }
  if (headers.contains('age')) {
    final a = int.tryParse(field('age'));
    c.age = a == null || a < 0 || a > 150 ? null : a;
  } else {
    c.age = existing?.age;
  }
  final g = field('gender').toLowerCase();
  c.gender = headers.contains('gender')
      ? (const ['male', 'female', 'other'].contains(g) ? g : '')
      : existing?.gender ?? '';
  final values = {for (final v in existing?.customFields ?? const <CustomFieldValue>[]) v.defId: v};
  for (final def in defs) {
    final col = '$customerCsvCustomPrefix${def.label.trim().toLowerCase()}';
    if (!headers.contains(col)) continue;
    final v = field(col);
    if (v.isEmpty) {
      values.remove(def.id);
    } else {
      values[def.id] = CustomFieldValue(defId: def.id, label: def.label, value: v);
    }
  }
  c.customFields = values.values.toList();
}
