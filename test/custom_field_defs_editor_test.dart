import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/custom_field_def.dart';
import 'package:invoiso/widgets/custom_field_defs_editor.dart';

void main() {
  late List<CustomFieldDef> defs;

  Future<void> pump(WidgetTester tester, {bool showPdfToggle = false}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: CustomFieldDefsEditor(
              defs: defs,
              onChanged: (d) => setState(() => defs = d),
              idPrefix: 'ccf',
              newFieldHint: 'e.g. Patient ID',
              decoration: (label, hint) =>
                  InputDecoration(labelText: label, hintText: hint),
              showPdfToggle: showPdfToggle,
            ),
          ),
        ),
      ),
    ));
  }

  setUp(() => defs = const [
        CustomFieldDef(id: 'a', label: 'A', sortOrder: 0),
        CustomFieldDef(id: 'b', label: 'B', sortOrder: 1),
      ]);

  testWidgets('add appends with prefixed id and next sortOrder, clears input',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).last, '  Patient ID ');
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(defs.map((d) => d.label), ['A', 'B', 'Patient ID']);
    expect(defs.last.id, startsWith('ccf-'));
    expect(defs.last.sortOrder, 2);
    expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty);
  });

  testWidgets('blank label is not added', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).last, '   ');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(defs, hasLength(2));
  });

  testWidgets('rename keeps id and sortOrder', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Blood Group');
    await tester.pump();
    expect(defs.first.id, 'a');
    expect(defs.first.label, 'Blood Group');
    expect(defs.first.sortOrder, 0);
  });

  testWidgets('move down reorders and renumbers sortOrder', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Move down').first);
    await tester.pump();
    expect(defs.map((d) => d.id), ['b', 'a']);
    expect(defs.map((d) => d.sortOrder), [0, 1]);
  });

  testWidgets('delete removes the row', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Delete field').first);
    await tester.pump();
    expect(defs.map((d) => d.id), ['b']);
  });

  testWidgets('print toggle hidden by default (invoice fields)', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.print_outlined), findsNothing);
  });

  testWidgets('print toggle flips showInPdf and survives rename', (tester) async {
    await pump(tester, showPdfToggle: true);
    await tester.tap(find.byTooltip('Printed on PDF — click to hide').first);
    await tester.pump();
    expect(defs.first.showInPdf, isFalse);
    await tester.enterText(find.byType(TextFormField).first, 'Renamed');
    await tester.pump();
    expect(defs.first.label, 'Renamed');
    expect(defs.first.showInPdf, isFalse);
    expect(defs.last.showInPdf, isTrue);
  });

  test('CustomFieldDef JSON without showInPdf (older data) defaults to true', () {
    expect(CustomFieldDef.fromJson({'id': 'x', 'label': 'L', 'sortOrder': 0}).showInPdf,
        isTrue);
    final d = CustomFieldDef.fromJson(
        const CustomFieldDef(id: 'x', label: 'L', sortOrder: 0, showInPdf: false)
            .toJson());
    expect(d.showInPdf, isFalse);
  });
}
