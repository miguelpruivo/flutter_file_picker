import 'dart:io';

import 'package:file_picker_darwin/file_picker_darwin.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilePickerDarwin', () {
    test('registers instance', () {
      FilePickerDarwin.registerWith();
      expect(FilePickerPlatform.instance, isA<FilePickerDarwin>());
    });

    test('DarwinPlatformFile parses map correctly', () {
      final file = DarwinPlatformFile.fromMap({
        'name': 'test.png',
        'path': '/tmp/test.png',
        'size': 1024,
      });
      expect(file.name, equals('test.png'));
      expect(file.uri.path, equals('/tmp/test.png'));
    });

    test('saveFile writes bytes to disk on macOS', () async {
      final picker = FilePickerDarwin();
      final tempDir = await Directory.systemTemp.createTemp(
        'file_picker_darwin_test',
      );
      final targetFile = File('${tempDir.path}/output.txt');
      addTearDown(() => tempDir.delete(recursive: true));

      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(picker.methodChannel, (call) async {
            expect(call.method, 'save');
            expect(
              (call.arguments as Map).containsKey('bytes'),
              isFalse,
              reason:
                  'macOS writes bytes itself; the native side only '
                  'needs to return the destination path.',
            );
            return targetFile.path;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(picker.methodChannel, null);
      });

      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await picker.saveFile(
        fileName: 'output.txt',
        bytes: bytes,
        mimeType: 'text/plain',
      );

      expect(result, isNotNull);
      expect(await targetFile.readAsBytes(), equals(bytes));
    });
  });
}
