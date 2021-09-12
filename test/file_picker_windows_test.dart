@TestOn('windows')

import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/windows/file_picker_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileTypeToFileFilter()', () {
    test('should return the file filter', () {
      final picker = FilePickerWindows();

      expect(
        picker.fileTypeToFileFilter(FileType.any, null),
        equals('*.*\x00\x00'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.audio, null),
        equals('Audios (*.mp3)\x00*.mp3\x00All Files (*.*)\x00*.*\x00\x00'),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.image, null),
        equals(
          'Images (*.jpeg,*.png,*.gif)\x00*.jpg;*.jpeg;*.png;*.gif\x00All Files (*.*)\x00*.*\x00\x00',
        ),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.media, null),
        equals(
          'Videos (*.webm,*.wmv,*.mpeg,*.mkv,*.mp4,*.avi,*.mov,*.flv)\x00*.webm;*.wmv;*.mpeg;*.mkv;*mp4;*.avi;*.mov;*.flv\x00Images (*.jpeg,*.png,*.gif)\x00*.jpg;*.jpeg;*.png;*.gif\x00All Files (*.*)\x00*.*\x00\x00',
        ),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.video, null),
        equals(
          'Videos (*.webm,*.wmv,*.mpeg,*.mkv,*.mp4,*.avi,*.mov,*.flv)\x00*.webm;*.wmv;*.mpeg;*.mkv;*mp4;*.avi;*.mov;*.flv\x00All Files (*.*)\x00*.*\x00\x00',
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
}
