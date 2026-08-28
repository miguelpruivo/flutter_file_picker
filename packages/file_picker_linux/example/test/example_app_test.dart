import 'package:file_picker_linux_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app resolves the parent window through an injected callback so tests do
/// not have to spawn `xdotool`.
ExampleApp appWith(String? xid) =>
    ExampleApp(resolveParentWindow: () async => xid);

void main() {
  testWidgets('renders the options the example demonstrates', (tester) async {
    await tester.pumpWidget(appWith('25165834'));
    await tester.pumpAndSettle();

    expect(find.text('lockParentWindow'), findsOneWidget);
    expect(find.text('Send parentWindow'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Choose'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Pick a file'), findsOneWidget);
    expect(find.text('Nothing picked yet.'), findsOneWidget);
  });

  testWidgets('both switches start on and can be toggled off', (tester) async {
    await tester.pumpWidget(appWith('25165834'));
    await tester.pumpAndSettle();

    final switches = find.byType(SwitchListTile);
    expect(switches, findsNWidgets(2));
    expect(
      tester.widgetList<SwitchListTile>(switches).every((s) => s.value),
      isTrue,
    );

    await tester.tap(switches.first);
    await tester.pump();

    expect(tester.widgetList<SwitchListTile>(switches).first.value, isFalse);
  });

  testWidgets('reports the XID when the process has an X window', (
    tester,
  ) async {
    await tester.pumpWidget(appWith('25165834'));
    await tester.pumpAndSettle();

    expect(find.textContaining('25165834'), findsOneWidget);
    expect(find.textContaining('can be parented'), findsOneWidget);
  });

  testWidgets('explains the Wayland case when there is no X window', (
    tester,
  ) async {
    await tester.pumpWidget(appWith(null));
    await tester.pumpAndSettle();

    expect(find.textContaining('no X window'), findsOneWidget);
    expect(find.textContaining('GDK_BACKEND=x11'), findsOneWidget);
  });
}
