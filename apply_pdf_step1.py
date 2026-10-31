import os

file_path = r'c:\billing\invoiso\lib\screens\settings\pdf_settings_screen_v2.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add required imports
imports_anchor = "import 'package:invoiso/services/pdf/pdf_preview_sample.dart';"
new_imports = """import 'package:invoiso/services/pdf/pdf_preview_sample.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:invoiso/services/thermal_printer_service.dart';
import 'package:invoiso/models/custom_invoice_layout.dart';"""

if imports_anchor in text:
    text = text.replace(imports_anchor, new_imports)
else:
    print('imports_anchor not found!')

# 2. Add custom layouts state variables
state_anchor = "InvoiceTemplate _previewedTemplate = InvoiceTemplate.classic;"
new_state = """InvoiceTemplate _previewedTemplate = InvoiceTemplate.classic;
  List<CustomInvoiceLayout> _customLayouts = [];
  String? _selectedCustomLayoutId;"""

if state_anchor in text:
    text = text.replace(state_anchor, new_state)
else:
    print('state_anchor not found!')

# 3. Load custom layouts in _loadInitial
load_anchor = "final savedShowSoftwareBranding = results[baseIdx + 7] as bool;"
new_load = """final savedShowSoftwareBranding = results[baseIdx + 7] as bool;
    final customLayouts = await ref.read(settingsRepositoryProvider).getCustomInvoiceLayouts();"""

load_setstate_anchor = "setState(() {"
new_load_setstate = """setState(() {
      _customLayouts = customLayouts;"""

if load_anchor in text:
    text = text.replace(load_anchor, new_load, 1)
if load_setstate_anchor in text:
    text = text.replace(load_setstate_anchor, new_load_setstate, 1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Step 1 applied successfully!')

