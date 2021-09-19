@TestOn('mac-os')

import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/file_picker_macos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileTypeToFileFilter()', () {
    test('should return the file filter', () {
      final picker = FilePickerMacOS();

      expect(
        picker.fileTypeToFileFilter(FileType.any, null),
        equals(''),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.audio, null),
        equals('"", "mp3", "wav", "midi", "ogg", "aac"'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.image, null),
        equals('"", "jpg", "jpeg", "bmp", "gif", "png"'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.media, null),
        equals(
          '"", "webm", "mpeg", "mkv", "mp4", "avi", "mov", "flv", "jpg", "jpeg", "bmp", "gif", "png"',
        ),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.video, null),
        equals('"", "webm", "mpeg", "mkv", "mp4", "avi", "mov", "flv"'),
      );
    });

    test(
        'should return the file filter when given a list of custom file extensions',
        () {
      final picker = FilePickerMacOS();

      expect(
        picker.fileTypeToFileFilter(FileType.custom, ['dart']),
        equals('"", "dart"'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.custom, ['dart', 'html']),
        equals('"", "dart", "html"'),
      );
    });
  });

  group('escapeDialogTitle()', () {
    test('should escape backslashes in the title of the dialog', () {
      final picker = FilePickerMacOS();

      final escapedTitle = picker.escapeDialogTitle(
        'Please select files that contain a \\:',
      );

      expect(
        escapedTitle,
        equals(
          'Please select files that contain a \\\\:',
        ),
      );
    });

    test('should escape line breaks in the title of the dialog', () {
      final picker = FilePickerMacOS();

      final escapedTitle = picker.escapeDialogTitle(
        'Please continue reading\nafter the line break:',
      );

      expect(
        escapedTitle,
        equals(
          'Please continue reading\\\nafter the line break:',
        ),
      );
    });

    test('should escape double quotes in the title of the dialog', () {
      final picker = FilePickerMacOS();

      final escapedTitle = picker.escapeDialogTitle(
        'Please select a "quoted" file:',
      );

      expect(escapedTitle, equals('Please select a \\"quoted\\" file:'));
    });
  });

  group('resultStringToFilePaths()', () {
    test('should interpret the result of picking no files', () {
      final picker = FilePickerMacOS();

      final filePaths = picker.resultStringToFilePaths('  ');
      expect(filePaths.length, equals(0));
      expect(filePaths.length, equals(0));
    });

    test('should interpret the result of picking a single file', () {
      final picker = FilePickerMacOS();

      final filePaths = picker.resultStringToFilePaths(
        'alias macOS:Users:john:Downloads:config.yml',
      );

      expect(filePaths.length, equals(1));
      expect(filePaths[0],
          equals('/Volumes/macOS/Users/john/Downloads/config.yml'));
    });

    test('should interpret the result of picking two files', () {
      final picker = FilePickerMacOS();

      final filePaths = picker.resultStringToFilePaths(
        'alias macOS:System:usr:lib:lib.dylib, alias macOS:System:usr:lib:libA.dylib',
      );

      expect(filePaths.length, equals(2));
      expect(filePaths[0], equals('/Volumes/macOS/System/usr/lib/lib.dylib'));
      expect(filePaths[1], equals('/Volumes/macOS/System/usr/lib/libA.dylib'));
    });

    test('should interpret the result of picking a directory', () {
      final picker = FilePickerMacOS();

      final filePaths = picker.resultStringToFilePaths(
        'alias macOS:System:iOSSupport:usr:lib:swift:',
      );

      expect(filePaths.length, equals(1));
      expect(filePaths[0],
          equals('/Volumes/macOS/System/iOSSupport/usr/lib/swift'));
    });

    test(
        'should interpret the result of picking a file from an external hard drive',
        () {
      final picker = FilePickerMacOS();

      final filePaths = picker.resultStringToFilePaths(
        'alias Western Digital Backup:backups:2021:photos:july:image1.jpg',
      );

      expect(filePaths.length, equals(1));
      expect(
        filePaths[0],
        equals(
          '/Volumes/Western Digital Backup/backups/2021/photos/july/image1.jpg',
        ),
      );
    });
    test(
        'should interpret the result of picking multiple files from an external hard drive',
        () {
      final picker = FilePickerMacOS();

      final filePaths = picker.resultStringToFilePaths(
        'alias WD Backup:photos:my screenshot.jpg, alias WD Backup:photos:christmas.png, alias WD Backup:photos:image33.png',
      );

      expect(filePaths.length, equals(3));
      expect(
          filePaths[0], equals('/Volumes/WD Backup/photos/my screenshot.jpg'));
      expect(filePaths[1], equals('/Volumes/WD Backup/photos/christmas.png'));
      expect(filePaths[2], equals('/Volumes/WD Backup/photos/image33.png'));
    });

    test(
        'should interpret the result of picking a directory from an external hard drive',
        () {
      final picker = FilePickerMacOS();

      final filePaths = picker.resultStringToFilePaths(
        'alias TAILS 4.20 - 202:EFI:debian:grub:x86_64-efi:',
      );

      expect(filePaths.length, equals(1));
      expect(
        filePaths[0],
        equals('/Volumes/TAILS 4.20 - 202/EFI/debian/grub/x86_64-efi'),
      );
    });
  });

  group('generateCommandLineArguments()', () {
    test('should generate the arguments for picking a single file', () {
      final picker = FilePickerMacOS();

      final cliArguments = picker.generateCommandLineArguments(
        'Select a file:',
        multipleFiles: false,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals('-e choose file of type {} with prompt "Select a file:"'),
      );
    });

    test('should generate the arguments for the save-file dialog', () {
      final picker = FilePickerMacOS();

      final cliArguments = picker.generateCommandLineArguments(
        'Select output file:',
        multipleFiles: false,
        pickDirectory: false,
        saveFile: true,
        fileName: 'test.out',
      );

      expect(
        cliArguments.join(' '),
        equals(
            '-e choose file name default name "test.out" with prompt "Select output file:"'),
      );
    });

    test('should generate the arguments for picking multiple files', () {
      final picker = FilePickerMacOS();

      final cliArguments = picker.generateCommandLineArguments(
        'Select files:',
        multipleFiles: true,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals(
          '-e choose file of type {} with multiple selections allowed with prompt "Select files:"',
        ),
      );
    });

    test(
        'should generate the arguments for picking a single file with a custom file filter',
        () {
      final picker = FilePickerMacOS();

      final cliArguments = picker.generateCommandLineArguments(
        'Select a file:',
        fileFilter: '"dart", "yml"',
        multipleFiles: false,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals(
            '-e choose file of type {"dart", "yml"} with prompt "Select a file:"'),
      );
    });

    test(
        'should generate the arguments for picking multiple files with a custom file filter',
        () {
      final picker = FilePickerMacOS();

      final cliArguments = picker.generateCommandLineArguments(
        'Select HTML files:',
        fileFilter: '"html"',
        multipleFiles: true,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals(
          '-e choose file of type {"html"} with multiple selections allowed with prompt "Select HTML files:"',
        ),
      );
    });

    test('should generate the arguments for picking a directory', () {
      final picker = FilePickerMacOS();

      final cliArguments = picker.generateCommandLineArguments(
        'Select a directory:',
        pickDirectory: true,
      );

      expect(
        cliArguments.join(' '),
        equals('-e choose folder with prompt "Select a directory:"'),
      );
    });
  });
}
