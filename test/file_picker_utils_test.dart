@TestOn('linux || mac-os')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/src/file_picker_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  final appTestFilePath = '/tmp/test_utils.app';
  final imageTestFile = '/tmp/test_utils.jpg';
  final pdfTestFile = '/tmp/test_utils.pdf';
  final yamlTestFile = '/tmp/test_utils.yml';

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

  group('createPlatformFile()', () {
    test('should return an instance of PlatformFile', () async {
      final imageFile = File(imageTestFile);
      final bytes = imageFile.readAsBytesSync();
      final readStream = imageFile.openRead();

      final platformFile = await FilePickerUtils.createPlatformFile(
        imageFile,
        bytes,
        readStream,
      );

      expect(platformFile.bytes, equals(bytes));
      expect(platformFile.name, equals('test_utils.jpg'));
      expect(platformFile.readStream, equals(readStream));
      expect(platformFile.size, equals(bytes.length));
      expect(platformFile.toString(), contains('bytesLength: ${bytes.length}'));
      expect(platformFile.toString(), isNot(contains('Uint8List')));
    });

    test(
      'should not throw an exception when picking .app files on macOS (.app files on macOS are actually directories but they are treated as files, similar to .exe files on Windows)',
      () async {
        final appFile = File(appTestFilePath);

        final platformFile = await FilePickerUtils.createPlatformFile(
          appFile,
          null,
          null,
        );

        expect(platformFile.bytes, equals(null));
        expect(platformFile.name, equals('test_utils.app'));
        expect(platformFile.readStream, equals(null));
        expect(
          platformFile.size,
          equals(0),
          reason: 'Expect size to be 0 because .app files are directories.',
        );
      },
    );
  });

  group('filePathsToPlatformFiles()', () {
    test(
      'should transform a list of file paths into a list of PlatformFiles',
      () async {
        final filePaths = [imageTestFile, pdfTestFile, yamlTestFile];

        final platformFiles = await FilePickerUtils.filePathsToPlatformFiles(
          filePaths,
          false,
          false,
        );

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
      },
    );

    test(
      'should transform an empty list of file paths into an empty list of PlatformFiles',
      () async {
        final filePaths = <String>[];

        final platformFiles = await FilePickerUtils.filePathsToPlatformFiles(
          filePaths,
          false,
          false,
        );

        expect(platformFiles.length, equals(filePaths.length));
      },
    );

    test(
      'should transform a list of file paths containing a path into a list of PlatformFiles',
      () async {
        final filePaths = <String>['test'];

        final platformFiles = await FilePickerUtils.filePathsToPlatformFiles(
          filePaths,
          true,
          false,
        );

        expect(platformFiles.length, equals(filePaths.length));
      },
    );

    test(
      'should transform a list of file paths containing a valid path into a list of PlatformFiles',
      () async {
        final filePaths = <String>['test/test_files/test.pdf'];

        final platformFiles = await FilePickerUtils.filePathsToPlatformFiles(
          filePaths,
          false,
          true,
        );

        expect(platformFiles.length, equals(filePaths.length));
      },
    );
  });

  group('runExecutableWithArguments()', () {
    test('should catch an exception when sending an empty filepath', () async {
      final filepath = '';

      expect(
        () async => await FilePickerUtils.isExecutableOnPath(filepath),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('resolveSaveFileName()', () {
    test('keeps existing extension when already present', () async {
      final fileName = await FilePickerUtils.resolveSaveFileName(
        fileName: 'document.pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
      );

      expect(fileName, 'document.pdf');
    });

    test('infers png extension from signature', () async {
      final fileName = await FilePickerUtils.resolveSaveFileName(
        fileName: 'image',
        bytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
      );

      expect(fileName, 'image.png');
    });

    test('infers mp4 family extension from ftyp brand', () async {
      final fileName = await FilePickerUtils.resolveSaveFileName(
        fileName: 'video',
        bytes: Uint8List.fromList([
          0x00,
          0x00,
          0x00,
          0x18,
          0x66,
          0x74,
          0x79,
          0x70,
          0x6D,
          0x70,
          0x34,
          0x32,
        ]),
      );

      expect(fileName, 'video.mp4');
    });

    test('falls back to original safe name when type is unknown', () async {
      final fileName = await FilePickerUtils.resolveSaveFileName(
        fileName: 'archive',
        bytes: Uint8List.fromList([0x00, 0x11, 0x22, 0x33]),
      );

      expect(fileName, 'archive');
    });
  });

  group('isAlpha()', () {
    test('should identify alpha chars', () async {
      expect(FilePickerUtils.isAlpha('a'), equals(true));
      expect(FilePickerUtils.isAlpha('A'), equals(true));
      expect(FilePickerUtils.isAlpha('z'), equals(true));
      expect(FilePickerUtils.isAlpha('Z'), equals(true));
      expect(FilePickerUtils.isAlpha('.'), equals(false));
      expect(FilePickerUtils.isAlpha('*'), equals(false));
      expect(FilePickerUtils.isAlpha(' '), equals(false));
    });
  });
}
