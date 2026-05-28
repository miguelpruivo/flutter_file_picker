@TestOn('linux || mac-os')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/src/api/platform_file.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  final appTestFilePath = '/tmp/test_platform_file.app';
  final imageTestFile = '/tmp/test_platform_file.jpg';
  final pdfTestFile = '/tmp/test_platform_file.pdf';
  final yamlTestFile = '/tmp/test_platform_file.yml';

  setUpAll(
    () => setUpTestFiles(
      appTestFilePath,
      imageTestFile,
      pdfTestFile,
      yamlTestFile,
    ),
  );

  tearDownAll(
    () => tearDownTestFiles(
      appTestFilePath,
      imageTestFile,
      pdfTestFile,
      yamlTestFile,
    ),
  );

  group('PlatformFile.readAsBytes()', () {
    test('returns the in-memory bytes when already available', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final platformFile = PlatformFile(
        name: 'memory.bin',
        size: bytes.length,
        bytes: bytes,
      );

      final result = await platformFile.readAsBytes();

      expect(identical(result, bytes), isTrue);
      expect(result, orderedEquals(bytes));
    });

    test('reads bytes from disk using the reported file size', () async {
      final sourceBytes = File(yamlTestFile).readAsBytesSync();
      final platformFile = PlatformFile(
        path: yamlTestFile,
        name: 'test_platform_file.yml',
        size: sourceBytes.length,
      );

      final result = await platformFile.readAsBytes();

      expect(result, orderedEquals(sourceBytes));
    });

    test(
      'still returns all bytes when the stored size is smaller than the file',
      () async {
        final sourceBytes = File(pdfTestFile).readAsBytesSync();
        final platformFile = PlatformFile(
          path: pdfTestFile,
          name: 'test_platform_file.pdf',
          size: 1,
        );

        final result = await platformFile.readAsBytes();

        expect(result, orderedEquals(sourceBytes));
      },
    );
  });
}
