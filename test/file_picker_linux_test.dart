@TestOn('linux')

import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/file_picker_linux.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final imageTestFile = '/tmp/test_linux.jpg';
  final pdfTestFile = '/tmp/test_linux.pdf';
  final yamlTestFile = '/tmp/test_linux.yml';

  group('fileTypeToFileFilter()', () {
    test('should return the file filter', () {
      final picker = FilePickerLinux();

      expect(
        picker.fileTypeToFileFilter(FileType.any, null),
        equals(''),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.audio, null),
        equals('*.mp3 *.wav *.midi *.ogg *.aac'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.image, null),
        equals('*.bmp *.gif *.jpg *.jpeg *.png'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.media, null),
        equals(
          '*.webm *.mpeg *.mkv *.mp4 *.avi *.mov *.flv *.jpg *.jpeg *.bmp *.gif *.png',
        ),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.video, null),
        equals('*.webm *.mpeg *.mkv *.mp4 *.avi *.mov *.flv'),
      );
    });

    test(
        'should return the file filter when given a list of custom file extensions',
        () {
      final picker = FilePickerLinux();

      expect(
        picker.fileTypeToFileFilter(FileType.custom, ['dart']),
        equals('*.dart'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.custom, ['dart', 'html']),
        equals('*.dart *.html'),
      );
    });
  });

  group('resultStringToFilePaths()', () {
    test('should interpret the result of picking a single file', () async {
      final picker = FilePickerLinux();

      final filePaths = picker.resultStringToFilePaths(imageTestFile);

      expect(filePaths.length, equals(1));
      expect(filePaths[0], imageTestFile);
    });

    test('should return an empty list if the file picker result was empty',
        () async {
      final picker = FilePickerLinux();

      final filePaths = picker.resultStringToFilePaths('');

      expect(filePaths.length, equals(0));
    });

    test('should interpret the result of picking multiple files', () async {
      final picker = FilePickerLinux();

      final filePaths = picker.resultStringToFilePaths(
        '$imageTestFile|$pdfTestFile|$yamlTestFile',
      );

      expect(filePaths.length, equals(3));
      expect(filePaths[0], equals(imageTestFile));
      expect(filePaths[1], equals(pdfTestFile));
      expect(filePaths[2], equals(yamlTestFile));
    });

    test('should interpret the result of picking a directory', () async {
      final picker = FilePickerLinux();

      final filePaths = picker.resultStringToFilePaths(
        '/home/john/studies',
      );

      expect(filePaths.length, equals(1));
      expect(filePaths[0], equals('/home/john/studies'));
    });
  });

  group('generateCommandLineArguments()', () {
    test('should generate the arguments for picking a single file', () {
      final picker = FilePickerLinux();

      final cliArguments = picker.generateCommandLineArguments(
        'Select a file:',
        multipleFiles: false,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals("""--file-selection --title Select a file:"""),
      );
    });

    test('should generate the arguments for the save-file dialog', () {
      final picker = FilePickerLinux();

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
            """--file-selection --title Select output file: --save --filename=test.out"""),
      );
    });

    test('should generate the arguments for picking multiple files', () {
      final picker = FilePickerLinux();

      final cliArguments = picker.generateCommandLineArguments(
        'Select files:',
        multipleFiles: true,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals("""--file-selection --title Select files: --multiple"""),
      );
    });

    test(
        'should generate the arguments for picking a single file with a custom file filter',
        () {
      final picker = FilePickerLinux();

      final cliArguments = picker.generateCommandLineArguments(
        'Select a file:',
        fileFilter: '*.dart *.yml',
        multipleFiles: false,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals(
          """--file-selection --title Select a file: --file-filter=*.dart *.yml""",
        ),
      );
    });

    test(
        'should generate the arguments for picking multiple files with a custom file filter',
        () {
      final picker = FilePickerLinux();

      final cliArguments = picker.generateCommandLineArguments(
        'Select HTML files:',
        fileFilter: '*.html',
        multipleFiles: true,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals(
            """--file-selection --title Select HTML files: --file-filter=*.html --multiple"""),
      );
    });

    test('should generate the arguments for picking a directory', () {
      final picker = FilePickerLinux();

      final cliArguments = picker.generateCommandLineArguments(
        'Select a directory:',
        pickDirectory: true,
      );

      expect(
        cliArguments.join(' '),
        equals("""--file-selection --title Select a directory: --directory"""),
      );
    });
  });
}
