@TestOn('vm')
library;

// 'dart:typed_data' is exported by flutter services/test bindings, explicit import removed.

import 'package:file_picker/src/platform/file_picker_method_channel.dart';
import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannel channel = MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
    const StandardMethodCodec(),
  );
  final List<MethodCall> log = <MethodCall>[];

  group('MethodChannelFilePicker', () {
    late MethodChannelFilePicker picker;

    setUp(() {
      picker = MethodChannelFilePicker();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'custom') {
              return [
                {
                  'path': '/tmp/test.txt',
                  'name': 'test.txt',
                  'size': 1024,
                  'bytes': null,
                },
              ];
            }
            if (methodCall.method == 'resolvePersistentFile') {
              return {
                'path': null,
                'name': 'persisted.txt',
                'size': 12,
                'identifier': 'content://test/document/1',
                'persistentIdentifier': 'bookmark-or-uri',
              };
            }
            if (methodCall.method == 'readFileBytes') {
              return Uint8List.fromList([1, 2, 3]);
            }
            if (methodCall.method == 'openReadSession') {
              return 'session-1';
            }
            if (methodCall.method == 'readSessionChunk') {
              final args = methodCall.arguments as Map<Object?, Object?>;
              final chunkSize = args['chunkSize'] as int;
              if (log
                      .where((call) => call.method == 'readSessionChunk')
                      .length ==
                  1) {
                return Uint8List.fromList(
                  List<int>.filled(chunkSize > 2 ? 2 : chunkSize, 9),
                );
              }
              return null;
            }
            return null;
          });
      log.clear();
    });

    test('pickFiles calls invokeMethod with correct arguments', () async {
      await picker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

      expect(log, hasLength(1));
      expect(log.first.method, 'custom');
      expect(log.first.arguments, {
        'allowMultipleSelection': false,
        'allowedExtensions': ['pdf'],
        'withData': false,
        'compressionQuality': 0,
        'withPersistentAccess': false,
      });
    });

    test('pickFiles forwards withPersistentAccess when requested', () async {
      await picker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

      expect(log, hasLength(1));
      expect(log.first.arguments, containsPair('withPersistentAccess', true));
    });

    test(
      'pickFiles throws ArgumentError for invalid custom extension usage',
      () async {
        expect(
          () =>
              picker.pickFiles(type: FileType.any, allowedExtensions: ['pdf']),
          throwsArgumentError,
        );
      },
    );
  });
}
