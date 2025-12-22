@TestOn('linux')
library;

import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:file_picker/src/platform/linux/filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileTypeToFileFilter()', () {
    test('any should be empty', () {
      final filter = Filter(FileType.any, null);

      expect(filter.toDBusArray().children.isEmpty, equals(true));
    });
    test('audio test', () {
      final filter = Filter(FileType.audio, null);

      expect(
          filter.info["Audio"],
          equals([
            (0, "*.aac"),
            (0, "*.midi"),
            (0, "*.mp3"),
            (0, "*.ogg"),
            (0, "*.wav")
          ]));
    });
    test('media test', () {
      final filter = Filter(FileType.media, null);

      expect(
          filter.info["Media"],
          equals([
            (0, "*.avi"),
            (0, "*.flv"),
            (0, "*.m4v"),
            (0, "*.mkv"),
            (0, "*.mov"),
            (0, "*.mp4"),
            (0, "*.mpeg"),
            (0, "*.webm"),
            (0, "*.wmv"),
            (0, "*.bmp"),
            (0, "*.gif"),
            (0, "*.jpeg"),
            (0, "*.jpg"),
            (0, "*.png")
          ]));
    });
    test('video test', () {
      final filter = Filter(FileType.video, null);

      expect(
          filter.info["Video"],
          equals([
            (0, "*.avi"),
            (0, "*.flv"),
            (0, "*.mkv"),
            (0, "*.mov"),
            (0, "*.mp4"),
            (0, "*.m4v"),
            (0, "*.mpeg"),
            (0, "*.webm"),
            (0, "*.wmv")
          ]));
    });
    test('custom test', () {
      final filter = Filter(FileType.custom, ["txt", "utau"]);

      expect(
          filter.info["Custom"],
          equals([
            (0, "*.txt"),
            (0, "*.utau"),
          ]));
    });
  });
}
