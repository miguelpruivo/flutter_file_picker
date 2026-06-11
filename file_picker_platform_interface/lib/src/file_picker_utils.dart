import 'package:flutter/foundation.dart';

import 'api/file_picker_types.dart';
import 'api/platform_file.dart';
import 'utils/_file_utils_web.dart'
    if (dart.library.io) 'utils/_file_utils_io.dart'
    as impl;

class FilePickerUtils {
  FilePickerUtils._();

  static const String defaultDialogTitle = 'File Picker';

  static Future<List<PlatformFile>> filePathsToPlatformFiles(
    List<String> filePaths, {
    bool withReadStream = false,
    bool withData = false,
  }) => impl.filePathsToPlatformFiles(
    filePaths,
    withReadStream: withReadStream,
    withData: withData,
  );

  @visibleForTesting
  static Future<PlatformFile> createPlatformFile(
    Object file,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
  ) => impl.createPlatformFile(file, bytes, readStream);

  static Future<String?> runExecutableWithArguments(
    String executable,
    List<String> arguments,
  ) => impl.runExecutableWithArguments(executable, arguments);

  static Future<String> isExecutableOnPath(String executable) =>
      impl.isExecutableOnPath(executable);

  static Future<void> saveBytesToFile(Uint8List? bytes, String? path) =>
      impl.saveBytesToFile(bytes, path);

  static bool isAlpha(String x) {
    if (x.isEmpty) return false;
    final int codeUnit = x.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }

  static void validateAllowedExtensions(
    FileType type,
    List<String>? allowedExtensions,
  ) {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw ArgumentError.value(
        allowedExtensions,
        'allowedExtensions',
        'Custom extension filters are only allowed with FileType.custom. '
            'Remove the extension filter or change the FileType to FileType.custom.',
      );
    }

    if (type == FileType.custom &&
        (allowedExtensions == null || allowedExtensions.isEmpty)) {
      throw ArgumentError.value(
        allowedExtensions,
        'allowedExtensions',
        'When using FileType.custom you must provide a non-empty list of allowedExtensions.',
      );
    }
  }
}
