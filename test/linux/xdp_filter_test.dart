@TestOn('linux')
library;

import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/linux/file_picker_linux.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileTypeToFileFilter()', () {
    test('should return the file filter string for predefined file types', () {
      final filter = Filter(FileType.any, null);

      equals(filter.toDBusArray().children.isEmpty);
    });
  });
}
