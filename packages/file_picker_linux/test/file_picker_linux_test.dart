import 'package:file_picker_linux/file_picker_linux.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilePickerLinux', () {
    test('registers instance', () {
      FilePickerLinux.registerWith();
      expect(FilePickerPlatform.instance, isA<FilePickerLinux>());
    });

    test('LinuxPlatformFile parses path correctly', () {
      final file = LinuxPlatformFile.fromPath('/tmp/test.png');
      expect(file.name, equals('test.png'));
      expect(file.uri.path, equals('/tmp/test.png'));
    });

    test('Filter constructs filters correctly', () {
      final filter = Filter(FileType.custom, ['png', 'jpg']);
      expect(filter.info.containsKey('Custom'), isTrue);
    });
  });
}
