@TestOn('vm')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFilePickerPlatform extends FilePickerPlatform {
  Uint8List bytes = Uint8List.fromList([4, 5, 6]);
  final List<Map<String, Object?>> readCalls = <Map<String, Object?>>[];
  final List<Map<String, Object?>> streamCalls = <Map<String, Object?>>[];

  @override
  Future<Uint8List> readFileAsBytes({
    String? identifier,
    String? persistentIdentifier,
  }) async {
    readCalls.add({
      'identifier': identifier,
      'persistentIdentifier': persistentIdentifier,
    });
    return bytes;
  }

  @override
  Stream<Uint8List> readFileAsStream({
    String? identifier,
    String? persistentIdentifier,
    int chunkSize = 64 * 1024,
  }) {
    streamCalls.add({
      'identifier': identifier,
      'persistentIdentifier': persistentIdentifier,
      'chunkSize': chunkSize,
    });
    return Stream<Uint8List>.value(bytes);
  }

  @override
  Future<PlatformFile> resolvePersistentFile({
    required String persistentIdentifier,
    bool withData = false,
  }) async {
    return PlatformFile(
      name: 'restored.txt',
      size: bytes.length,
      identifier: 'content://restored',
      persistentIdentifier: persistentIdentifier,
      bytes: withData ? bytes : null,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformFile persistent access', () {
    late FilePickerPlatform originalInstance;
    late _FakeFilePickerPlatform fakePlatform;

    setUp(() {
      originalInstance = FilePickerPlatform.instance;
      fakePlatform = _FakeFilePickerPlatform();
      FilePickerPlatform.instance = fakePlatform;
    });

    tearDown(() {
      FilePickerPlatform.instance = originalInstance;
    });

    test(
      'readAsBytes falls back to platform access when there is no local path',
      () async {
        final file = PlatformFile(
          name: 'movie.mov',
          size: 3,
          identifier: 'content://media/external/video/1',
          persistentIdentifier: 'content://media/external/video/1',
        );

        final bytes = await file.readAsBytes();

        expect(bytes, Uint8List.fromList([4, 5, 6]));
        expect(fakePlatform.readCalls.single, {
          'identifier': 'content://media/external/video/1',
          'persistentIdentifier': 'content://media/external/video/1',
        });
      },
    );

    test(
      'readAsByteStream falls back to platform streaming when there is no local path',
      () async {
        final file = PlatformFile(
          name: 'movie.mov',
          size: 3,
          identifier: 'content://media/external/video/1',
          persistentIdentifier: 'content://media/external/video/1',
        );

        final chunks = await file.readAsByteStream().toList();

        expect(chunks, [
          Uint8List.fromList([4, 5, 6]),
        ]);
        expect(fakePlatform.streamCalls.single, {
          'identifier': 'content://media/external/video/1',
          'persistentIdentifier': 'content://media/external/video/1',
          'chunkSize': 64 * 1024,
        });
      },
    );

    test(
      'restorePersistentFile delegates to platform implementation',
      () async {
        final file = await FilePicker.restorePersistentFile(
          'content://media/external/video/1',
          withData: true,
        );

        expect(file.name, 'restored.txt');
        expect(file.persistentIdentifier, 'content://media/external/video/1');
        expect(file.bytes, Uint8List.fromList([4, 5, 6]));
      },
    );
  });
}
