@TestOn('vm')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

// Persistent identifier/persistent access tests removed — PlatformFile no longer
// exposes `identifier`/`persistentIdentifier`. The canonical identifier for a
// picked file must be present in `path`.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformFile persistent access', () {
    test('readAsBytes throws when there is no local path or in-memory data',
        () async {
      final file = PlatformFile(
        name: 'movie.mov',
        size: 3,
      );

      expect(file.readAsBytes(), throwsStateError);
    });

    test('readAsByteStream throws when there is no local path or in-memory data',
        () async {
      final file = PlatformFile(
        name: 'movie.mov',
        size: 3,
      );

      expect(() => file.readAsByteStream().toList(), throwsStateError);
    });
  });
}
