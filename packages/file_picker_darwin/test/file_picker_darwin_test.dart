import 'package:file_picker_darwin/file_picker_darwin.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/services.dart';
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

    test(
      'pickFileAndDirectoryPaths calls the native combined picker and '
      'returns its paths',
      () async {
        final picker = FilePickerDarwin();

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(picker.methodChannel, (call) async {
              expect(call.method, 'pickFileAndDirectoryPaths');
              expect((call.arguments as Map)['allowedExtensions'], [
                'pdf',
              ]);
              return ['/tmp/some_file.pdf', '/tmp/some_directory'];
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(picker.methodChannel, null);
        });

        final result = await picker.pickFileAndDirectoryPaths(
          allowedExtensions: ['pdf'],
        );

        expect(result, ['/tmp/some_file.pdf', '/tmp/some_directory']);
      },
    );

    test(
      'pickFileAndDirectoryPaths returns an empty list on PlatformException',
      () async {
        final picker = FilePickerDarwin();

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(picker.methodChannel, (call) async {
              throw PlatformException(code: 'error');
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(picker.methodChannel, null);
        });

        final result = await picker.pickFileAndDirectoryPaths();

        expect(result, isEmpty);
      },
    );
  });
}
