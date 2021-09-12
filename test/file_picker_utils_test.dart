@TestOn('linux || mac-os')

import 'package:file_picker/src/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  final imageTestFile = '/tmp/test_utils.jpg';
  final pdfTestFile = '/tmp/test_utils.pdf';
  final yamlTestFile = '/tmp/test_utils.yml';

  setUpAll(
    () => setUpTestFiles(imageTestFile, pdfTestFile, yamlTestFile),
  );

  tearDownAll(
    () => tearDownTestFiles(imageTestFile, pdfTestFile, yamlTestFile),
  );

  group('filePathsToPlatformFiles()', () {
    test('should transform a list of file paths into a list of PlatformFiles',
        () async {
      final filePaths = [imageTestFile, pdfTestFile, yamlTestFile];

      final platformFiles =
          await filePathsToPlatformFiles(filePaths, false, false);

      expect(platformFiles.length, equals(filePaths.length));

      final imageFile = platformFiles.firstWhere(
        (element) => element.name == 'test_utils.jpg',
      );
      expect(imageFile.extension, equals('jpg'));
      expect(imageFile.name, equals('test_utils.jpg'));
      expect(imageFile.path, equals(imageTestFile));
      expect(imageFile.size, equals(4073378));

      final pdfFile = platformFiles.firstWhere(
        (element) => element.name == 'test_utils.pdf',
      );
      expect(pdfFile.extension, equals('pdf'));
      expect(pdfFile.name, equals('test_utils.pdf'));
      expect(pdfFile.path, equals(pdfTestFile));
      expect(pdfFile.size, equals(7478));

      final yamlFile = platformFiles.firstWhere(
        (element) => element.name == 'test_utils.yml',
      );
      expect(yamlFile.extension, equals('yml'));
      expect(yamlFile.name, equals('test_utils.yml'));
      expect(yamlFile.path, equals(yamlTestFile));
      expect(yamlFile.size, equals(213));
    });

    test(
        'should transform an empty list of file paths into an empty list of PlatformFiles',
        () async {
      final filePaths = <String>[];

      final platformFiles = await filePathsToPlatformFiles(
        filePaths,
        false,
        false,
      );

      expect(platformFiles.length, equals(filePaths.length));
    });
  });
}
