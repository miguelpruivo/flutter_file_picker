@TestOn('linux')

import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/linux/kdialog_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final imageTestFile = '/tmp/test_linux.jpg';
  final pdfTestFile = '/tmp/test_linux.pdf';
  final yamlTestFile = '/tmp/test_linux.yml';

  group('fileTypeToFileFilter()', () {
    test('should return the file filter string for predefined file types', () {
      final dialogHandler = KDialogHandler();

      expect(
        dialogHandler.fileTypeToFileFilter(FileType.any, null),
        equals(''),
      );

      expect(
        dialogHandler.fileTypeToFileFilter(FileType.audio, null),
        equals('Audio File (*.aac *.midi *.mp3 *.ogg *.wav)'),
      );

      expect(
        dialogHandler.fileTypeToFileFilter(FileType.image, null),
        equals('Image File (*.bmp *.gif *.jpeg *.jpg *.png)'),
      );

      expect(
        dialogHandler.fileTypeToFileFilter(FileType.media, null),
        equals(
          'Media File (*.avi *.flv *.mkv *.mov *.mp4 *.mpeg *.webm *.wmv *.bmp *.gif *.jpeg *.jpg *.png)',
        ),
      );

      expect(
        dialogHandler.fileTypeToFileFilter(FileType.video, null),
        equals(
            'Video File (*.avi *.flv *.mkv *.mov *.mp4 *.mpeg *.webm *.wmv)'),
      );
    });

    test('should return the file filter string for custom file extensions', () {
      final dialogHandler = KDialogHandler();

      expect(
        dialogHandler.fileTypeToFileFilter(FileType.custom, ['dart']),
        equals('DART File (*.dart)'),
      );

      expect(
        dialogHandler.fileTypeToFileFilter(FileType.custom, ['dart', 'html']),
        equals('DART File, HTML File (*.dart *.html)'),
      );
    });
  });

  group('resultStringToFilePaths()', () {
    test('should interpret the result of picking a single file', () {
      final filePaths = KDialogHandler().resultStringToFilePaths(
        imageTestFile,
      );

      expect(filePaths.length, equals(1));
      expect(filePaths[0], imageTestFile);
    });

    test('should return an empty list if the file picker result was empty', () {
      final filePaths = KDialogHandler().resultStringToFilePaths('');

      expect(filePaths.length, equals(0));
    });

    test('should interpret the result of picking multiple files', () {
      final filePaths = KDialogHandler().resultStringToFilePaths(
        '$imageTestFile $pdfTestFile $yamlTestFile',
      );

      expect(filePaths.length, equals(3));
      expect(filePaths[0], equals(imageTestFile));
      expect(filePaths[1], equals(pdfTestFile));
      expect(filePaths[2], equals(yamlTestFile));
    });

    test(
        'should interpret the result of file names that contain vertical pipes',
        () {
      final filePaths = KDialogHandler().resultStringToFilePaths(
        '$imageTestFile /home/user/file-with- -in-name.txt /tmp/image.png',
      );

      expect(filePaths.length, equals(3));
      expect(filePaths[0], equals(imageTestFile));
      expect(filePaths[1], equals('/home/user/file-with- -in-name.txt'));
      expect(filePaths[2], equals('/tmp/image.png'));
    });

    test('should interpret the result of picking a directory', () {
      final filePaths = KDialogHandler().resultStringToFilePaths(
        '/home/john/studies',
      );

      expect(filePaths.length, equals(1));
      expect(filePaths[0], equals('/home/john/studies'));
    });
  });

  group('generateCommandLineArguments()', () {
    test('should generate the arguments for picking a single file', () {
      final cliArguments = KDialogHandler().generateCommandLineArguments(
        'Select a file:',
        multipleFiles: false,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals("""--title Select a file: --getopenfilename"""),
      );
    });

    test('should generate the arguments for the save-file dialog', () {
      final cliArguments = KDialogHandler().generateCommandLineArguments(
        'Select output file:',
        multipleFiles: false,
        pickDirectory: false,
        saveFile: true,
        fileName: 'test.out',
      );

      expect(
        cliArguments.join(' '),
        equals("""--title Select output file: --getsavefilename test.out"""),
      );
    });

    test('should generate the arguments for picking multiple files', () {
      final cliArguments = KDialogHandler().generateCommandLineArguments(
        'Select files:',
        multipleFiles: true,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals("""--title Select files: --getopenfilename --multiple"""),
      );
    });

    test(
        'should generate the arguments for picking a single file with a custom file filter',
        () {
      final cliArguments = KDialogHandler().generateCommandLineArguments(
        'Select a file:',
        fileFilter: 'DART File, YML File (*.dart *.yml)',
        multipleFiles: false,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals(
          """--title Select a file: --getopenfilename . DART File, YML File (*.dart *.yml)""",
        ),
      );
    });

    test(
        'should generate the arguments for picking multiple files with a custom file filter',
        () {
      final cliArguments = KDialogHandler().generateCommandLineArguments(
        'Select HTML files:',
        fileFilter: 'HTML File (*.html)',
        multipleFiles: true,
        pickDirectory: false,
      );

      expect(
        cliArguments.join(' '),
        equals(
            """--title Select HTML files: --getopenfilename . HTML File (*.html) --multiple"""),
      );
    });

    test('should generate the arguments for picking a directory', () {
      final cliArguments = KDialogHandler().generateCommandLineArguments(
        'Select a directory:',
        pickDirectory: true,
      );

      expect(
        cliArguments.join(' '),
        equals("""--title Select a directory: --getexistingdirectory"""),
      );
    });
  });
}
