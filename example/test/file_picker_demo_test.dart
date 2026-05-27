import 'package:file_picker_example/src/file_picker_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder findSaveFileButton() {
    return find.widgetWithText(FloatingActionButton, 'Save file');
  }

  Finder findMultiPickSwitchTile() {
    return find.widgetWithText(SwitchListTile, 'Pick multiple files');
  }

  testWidgets('enabling multi-pick shows warning and disables save file', (
    tester,
  ) async {
    await tester.pumpWidget(const FilePickerDemo());

    await tester.tap(findMultiPickSwitchTile());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Save file is disabled because it is not compatible with multiple file selection.',
      ),
      findsOneWidget,
    );

    final saveFileButton = tester.widget<FloatingActionButton>(
      findSaveFileButton(),
    );

    expect(saveFileButton.onPressed, isNull);
    expect(saveFileButton.backgroundColor, Colors.grey.shade700);
    expect(saveFileButton.foregroundColor, Colors.white70);
  });

  testWidgets('disabling multi-pick enables save file again', (tester) async {
    await tester.pumpWidget(const FilePickerDemo());

    await tester.tap(findMultiPickSwitchTile());
    await tester.pumpAndSettle();

    await tester.tap(findMultiPickSwitchTile());
    await tester.pumpAndSettle();

    final saveFileButton = tester.widget<FloatingActionButton>(
      findSaveFileButton(),
    );

    expect(saveFileButton.onPressed, isNotNull);
    expect(saveFileButton.backgroundColor, isNull);
    expect(saveFileButton.foregroundColor, isNull);
  });
}
