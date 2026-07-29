import 'package:file_picker_darwin/file_picker_darwin.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
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
  });
}
