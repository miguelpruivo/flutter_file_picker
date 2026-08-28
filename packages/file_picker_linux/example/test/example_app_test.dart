import 'package:file_picker_linux_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the options the example demonstrates', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('lockParentWindow'), findsOneWidget);
    expect(find.text('Resolve parentWindow'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Choose'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Pick a file'), findsOneWidget);
  });

  testWidgets('both switches start on and can be toggled off', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    final switches = find.byType(SwitchListTile);
    expect(switches, findsNWidgets(2));
    expect(
      tester.widgetList<SwitchListTile>(switches).every((s) => s.value == true),
      isTrue,
    );

    await tester.tap(switches.first);
    await tester.pump();

    expect(tester.widgetList<SwitchListTile>(switches).first.value, isFalse);
  });

  testWidgets('reports that nothing has been picked yet', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Nothing picked yet.'), findsOneWidget);
  });
}
