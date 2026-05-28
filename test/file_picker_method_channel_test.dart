@TestOn('vm')
library;

import 'dart:typed_data';
import 'package:file_picker/src/api/platform_file.dart';
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
      });
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

    test(
      'saveFile sends the provided bytes through the save method',
      () async {
        final bytes = Uint8List.fromList([1, 2, 3]);

        await picker.saveFile(
          fileName: 'saved.txt',
          type: FileType.custom,
          allowedExtensions: ['txt'],
          bytes: bytes,
        );

        expect(log, hasLength(1));
        expect(log.first.method, 'save');
        expect(log.first.arguments, {
          'fileName': 'saved.txt',
          'fileType': 'custom',
          'initialDirectory': null,
          'allowedExtensions': ['txt'],
          'bytes': bytes,
        });
      },
    );

    test(
      'saveFile rejects deferred byte tokens on mobile platforms',
      () async {
        final bytes = await PlatformFile(
          path: '/tmp/source.txt',
          identifier: 'content://source.txt',
          name: 'source.txt',
          size: 1024 * 1024 * 1024,
        ).readAsBytes();

        expect(bytes, isA<Uint8List>());
        expect(bytes, isEmpty);

        await expectLater(
          () => picker.saveFile(
            fileName: 'saved.txt',
            type: FileType.custom,
            allowedExtensions: ['txt'],
            bytes: bytes,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('requires actual byte content'),
            ),
          ),
        );
        expect(log, isEmpty);
      },
    );
  });
}
