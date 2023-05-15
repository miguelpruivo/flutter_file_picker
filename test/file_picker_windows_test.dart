@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_picker/src/exceptions.dart';
import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/windows/file_picker_windows.dart';
import 'package:file_picker/src/windows/file_picker_windows_ffi_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileTypeToFileFilter()', () {
    test('should return the file filter', () {
      final picker = FilePickerWindows();

      expect(
        picker.fileTypeToFileFilter(FileType.any, null),
        equals('All Files (*.*)\x00*.*\x00\x00'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.audio, null),
        equals(
            'Audios (*.aac,*.midi,*.mp3,*.ogg,*.wav)\x00*.aac;*.midi;*.mp3;*.ogg;*.wav\x00\x00'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.image, null),
        equals(
          'Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png\x00\x00',
        ),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.media, null),
        equals(
          'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png\x00\x00',
        ),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.video, null),
        equals(
          'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00\x00',
        ),
      );
    });

    test(
        'should return the file filter when given a list of custom file extensions',
        () {
      final picker = FilePickerWindows();

      expect(
        picker.fileTypeToFileFilter(FileType.custom, ['dart']),
        equals('Files (*.dart)\x00*.dart\x00\x00'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.custom, ['dart', 'html']),
        equals('Files (*.dart,*.html)\x00*.dart;*.html\x00\x00'),
      );
    });
  });

  group('validateFileName()', () {
    test('should throw an exception if the file name contains a < (less than)',
        () {
      expect(() => FilePickerWindows().validateFileName('file with < .txt'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test(
        'should throw an exception if the file name contains a > (greater than)',
        () {
      expect(() => FilePickerWindows().validateFileName('file>.csv'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test('should throw an exception if the file name contains a : (colon)', () {
      expect(() => FilePickerWindows().validateFileName('fi:le.csv'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test(
        'should throw an exception if the file name contains a " (double quote)',
        () {
      expect(() => FilePickerWindows().validateFileName('"output.csv'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test(
        'should throw an exception if the file name contains a / (forward slash)',
        () {
      expect(() => FilePickerWindows().validateFileName('my-output/-file.csv'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test('should throw an exception if the file name contains a \\ (backslash)',
        () {
      expect(
          () =>
              FilePickerWindows().validateFileName('invalid-\\-file-name.csv'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test('should throw an exception if the file name contains a | (pipe)', () {
      expect(() => FilePickerWindows().validateFileName('download|.pdf'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test(
        'should throw an exception if the file name contains a ? (question mark)',
        () {
      expect(() => FilePickerWindows().validateFileName('bill?-2021-12-18.pdf'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test('should throw an exception if the file name contains a * (asterisk)',
        () {
      expect(() => FilePickerWindows().validateFileName('*.txt'),
          throwsA(TypeMatcher<IllegalCharacterInFileNameException>()));
    });
    test('should return normally given a valid file name', () {
      expect(
          () => FilePickerWindows()
              .validateFileName('0123456789,;.-_+#\'äöüß!§\$%&(){}[]=`´.txt'),
          returnsNormally);
    });
  });

  group('extractSelectedFilesFromOpenFileNameW', () {
    test('should parse the result of picking a single file', () {
      final Pointer<OPENFILENAMEW> openFileNameW = calloc<OPENFILENAMEW>();
      openFileNameW.ref.lpstrFile =
          "C:\\Program Files\\Sublime Text 3\\changelog.txt\x00\x00"
              .toNativeUtf16();

      final filePaths = FilePickerWindows()
          .extractSelectedFilesFromOpenFileNameW(openFileNameW.ref);

      expect(filePaths, hasLength(1));
      expect(filePaths[0],
          equals("C:\\Program Files\\Sublime Text 3\\changelog.txt"));
    });

    test('should parse the result of picking multiple files', () {
      final Pointer<OPENFILENAMEW> openFileNameW = calloc<OPENFILENAMEW>();
      openFileNameW.ref.lpstrFile =
          "C:\\Users\\Jane\x00file1.jpg\x00file2.pdf\x00file3.docx\x00\x00"
              .toNativeUtf16();

      final filePaths = FilePickerWindows()
          .extractSelectedFilesFromOpenFileNameW(openFileNameW.ref);

      expect(filePaths, hasLength(3));
      expect(filePaths[0], equals("C:\\Users\\Jane\\file1.jpg"));
      expect(filePaths[1], equals("C:\\Users\\Jane\\file2.pdf"));
      expect(filePaths[2], equals("C:\\Users\\Jane\\file3.docx"));
    });
  });

  /** See https://github.com/miguelpruivo/flutter_file_picker/issues/1257 for reconstructing this special case. */
  test(
      'should parse the result of the save-file dialog when the dialog was instantiated with a long '
      'default file name that is contained - in parts - in the result separated by only one null character',
      () {
    final Pointer<OPENFILENAMEW> x = calloc<OPENFILENAMEW>();
    x.ref.lpstrFile =
        "C:\\Users\\John\\Desktop\\test.txt\x00qrstuvwxyz0123456789.png\x00\x00"
            .toNativeUtf16();

    final filePaths = FilePickerWindows().extractSelectedFilesFromOpenFileNameW(
      x.ref,
      isResultFromSaveFileDialog: true,
    );

    expect(filePaths, hasLength(1));
    expect(filePaths[0], equals("C:\\Users\\John\\Desktop\\test.txt"));
  });
}
