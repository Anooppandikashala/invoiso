// Attachments screen: tabs split customer / private, captions, move between
// tabs, delete, Done returns the edits, back with changes asks to discard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/invoice_attachment.dart';
import 'package:invoiso/screens/invoice_attachments_screen.dart';

void main() {
  List<AttachmentDraft>? result;
  var closed = false;

  Future<void> openScreen(WidgetTester tester, List<AttachmentDraft> initial) async {
    result = null;
    closed = false;
    await tester.binding.setSurfaceSize(const Size(900, 900));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await InvoiceAttachmentsScreen.open(context,
                document: 'INV-7', initial: initial);
            closed = true;
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // Paths needn't exist — the screen only edits drafts.
  List<AttachmentDraft> sample() => [
        AttachmentDraft(id: 'a', path: '/nope/a.jpg', isPublic: true, caption: 'Before'),
        AttachmentDraft(id: 'b', path: '/nope/b.jpg', isPublic: true),
        AttachmentDraft(id: 'c', path: '/nope/c.jpg', isPublic: false, caption: 'Receipt'),
      ];

  testWidgets('tabs show counts and split customer / private', (tester) async {
    await openScreen(tester, sample());
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('INV-7'), findsOneWidget);
    expect(find.text('Customer (2/10)'), findsOneWidget);
    expect(find.text('Private (1)'), findsOneWidget);
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('Receipt'), findsNothing); // on the other tab

    await tester.tap(find.text('Private (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt'), findsOneWidget);
  });

  testWidgets('edit caption, move to private, delete, then Done', (tester) async {
    final initial = sample();
    await openScreen(tester, initial);

    await tester.enterText(find.byType(TextField).at(1), 'After');
    // Move the first photo to Private.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Private'));
    await tester.pumpAndSettle();
    expect(find.text('Customer (1/10)'), findsOneWidget);
    expect(find.text('Private (2)'), findsOneWidget);

    // Delete the last photo on the Private tab ('c').
    await tester.tap(find.text('Private (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result!.map((d) => [d.id, d.isPublic, d.caption]), [
      ['a', false, 'Before'],
      ['b', true, 'After'],
    ]);
    // The caller's list is untouched until it applies the result.
    expect(initial.first.isPublic, isTrue);
    expect(initial.length, 3);
  });

  testWidgets('close with changes asks; Discard returns null', (tester) async {
    await openScreen(tester, sample());
    await tester.enterText(find.byType(TextField).first, 'Changed');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Discard attachment changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('close without changes closes straight away', (tester) async {
    await openScreen(tester, sample());
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Discard attachment changes?'), findsNothing);
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('Move to Customer is disabled when the customer tab is full',
      (tester) async {
    await openScreen(tester, [
      for (var i = 0; i < 10; i++)
        AttachmentDraft(id: 'p$i', path: '/nope/$i.jpg', isPublic: true),
      AttachmentDraft(id: 'x', path: '/nope/x.jpg', isPublic: false),
    ]);
    await tester.tap(find.text('Private (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    final item = tester.widget<PopupMenuItem<String>>(
        find.widgetWithText(PopupMenuItem<String>, 'Move to Customer'));
    expect(item.enabled, isFalse);
  });

  testWidgets('viewer opens as a dialog; its close keeps the screen open',
      (tester) async {
    await openScreen(tester, sample());
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNWidgets(2)); // screen + viewer

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsNothing);
    expect(find.text('Customer (2/10)'), findsOneWidget);
    expect(closed, isFalse);
  });
}
