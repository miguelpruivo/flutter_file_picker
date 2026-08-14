import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:windows_file_picker/windows_file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilePickerWindows', () {
    test('registers instance', () {
      FilePickerWindows.registerWith();
      expect(FilePickerPlatform.instance, isA<FilePickerWindows>());
    });

    test('WindowsPlatformFile parses path correctly', () {
      final file = WindowsPlatformFile.fromPath(r'C:\Users\Test\file.txt');
      expect(file.name, equals('file.txt'));
      expect(file.uri.path, equals('/C:/Users/Test/file.txt'));
    });

    test('FilePickerWindowsOptions contains expected properties', () {
      const options = FilePickerWindowsOptions(
        parentWindowHandle: 12345,
        lockParentWindow: true,
      );
      expect(options.parentWindowHandle, equals(12345));
      expect(options.lockParentWindow, isTrue);
    });
  });
}
