import 'dart:isolate';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:windows_file_picker/src/open_save_file_args.dart';
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

  group('resolveDefaultExtension', () {
    final picker = FilePickerWindows();
    final port = ReceivePort();
    tearDownAll(port.close);

    OpenSaveFileArgs args({
      List<String>? allowedExtensions,
      String? defaultFileName,
    }) {
      return OpenSaveFileArgs(
        port: port.sendPort,
        allowedExtensions: allowedExtensions,
        defaultFileName: defaultFileName,
      );
    }

    test('prefers the first allowed extension', () {
      expect(
        picker.resolveDefaultExtension(
          args(allowedExtensions: ['pdf', 'docx'], defaultFileName: 'a.txt'),
        ),
        equals('pdf'),
      );
    });

    test('falls back to the extension of the default file name', () {
      expect(
        picker.resolveDefaultExtension(args(defaultFileName: 'calendar.pdf')),
        equals('pdf'),
      );
    });

    test('returns null when the default file name has no extension', () {
      expect(
        picker.resolveDefaultExtension(args(defaultFileName: 'calendar')),
        isNull,
      );
    });

    test('returns null when there is no extension source at all', () {
      expect(picker.resolveDefaultExtension(args()), isNull);
    });
  });

  group('fileTypeFilterSpecs', () {
    test('any type matches every file', () {
      final specs = FilePickerWindows.fileTypeFilterSpecs(FileType.any, null);
      expect(specs, [(name: 'All Files (*.*)', pattern: '*.*')]);
    });

    test('custom type builds a single spec from allowed extensions', () {
      final specs = FilePickerWindows.fileTypeFilterSpecs(FileType.custom, [
        'pdf',
        'docx',
      ]);
      expect(specs, [(name: 'Files (*.pdf,*.docx)', pattern: '*.pdf;*.docx')]);
    });

    test('custom type without allowed extensions throws', () {
      expect(
        () => FilePickerWindows.fileTypeFilterSpecs(FileType.custom, null),
        throwsArgumentError,
      );
      expect(
        () => FilePickerWindows.fileTypeFilterSpecs(FileType.custom, []),
        throwsArgumentError,
      );
    });

    test('media type produces separate video and image specs', () {
      final specs = FilePickerWindows.fileTypeFilterSpecs(FileType.media, null);
      expect(specs, hasLength(2));
      expect(specs[0].name, contains('Videos'));
      expect(specs[1].name, contains('Images'));
    });
  });
}
