import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/common/common.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/widgets/template_list_tile.dart';

void main() {
  testWidgets('custom layout tile fits in the 260px templates column', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 236,
              child: TemplateListTile(
                template: InvoiceTemplate.gridClassic,
                name: 'My Custom Layout',
                description: 'Custom template with personal styling',
                themeColor: Colors.blue,
                isPreviewed: true,
                isSaved: false,
                isDefault: false,
                isInserted: true,
                thermalDetailedTemplate: false,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
