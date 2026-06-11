import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<List<PlatformFile>> filePathsToPlatformFiles(
  List<String> filePaths, {
  bool withReadStream = false,
  bool withData = false,
}) => throw UnsupportedError(
  'filePathsToPlatformFiles is only supported on native platforms',
);

Future<PlatformFile> createPlatformFile(
  Object file,
  Uint8List? bytes,
  Stream<List<int>>? readStream,
) => throw UnsupportedError(
  'createPlatformFile is only supported on native platforms',
);

Future<String?> runExecutableWithArguments(
  String executable,
  List<String> arguments,
) => throw UnsupportedError(
  'runExecutableWithArguments is only supported on native platforms',
);

Future<String> isExecutableOnPath(String executable) => throw UnsupportedError(
  'isExecutableOnPath is only supported on native platforms',
);

Future<void> saveBytesToFile(Uint8List? bytes, String? path) =>
    throw UnsupportedError(
      'saveBytesToFile is only supported on native platforms',
    );
