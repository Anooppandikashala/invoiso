// CopyableText: text is selectable; the hover copy icon copies the copy
// value (not the display text) and confirms with a snackbar.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/widgets/copyable_text.dart';

void main() {
  testWidgets('selectable, hover icon copies the value', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
          body: Center(child: CopyableText('#INV-0001', copyValue: 'INV-0001'))),
    ));

    expect(find.text('#INV-0001'), findsOneWidget);
    expect(find.ancestor(of: find.text('#INV-0001'), matching: find.byType(SelectionArea)),
        findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded).hitTestable(), findsNothing); // hidden

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('#INV-0001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump();

    expect(copied, 'INV-0001');
    expect(find.text('Copied: INV-0001'), findsOneWidget);
  });
}
