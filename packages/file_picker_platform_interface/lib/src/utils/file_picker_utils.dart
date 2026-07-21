import 'package:flutter/foundation.dart';

import 'package:file_picker_platform_interface/src/api/file_picker_types.dart';
import 'package:file_picker_platform_interface/src/api/platform_file.dart';
import '_file_utils_web.dart'
    if (dart.library.io) '_file_utils_io.dart'
    as impl;

/// Utility class for file picker that provides common helper methods
/// used across different platform implementations.
class FilePickerUtils {
  /// The default title for the file picker dialog.
  static const String defaultDialogTitle = 'File Picker';

  /// Converts a list of file paths into a list of [PlatformFile]s.
  static Future<List<PlatformFile>> filePathsToPlatformFiles(
    List<String> filePaths, {
    bool withReadStream = false,
    bool withData = false,
  }) => impl.filePathsToPlatformFiles(
    filePaths,
    withReadStream: withReadStream,
    withData: withData,
  );

  /// Creates a [PlatformFile] instance from a [File] object.
  @visibleForTesting
  static Future<PlatformFile> createPlatformFile(
    Object file,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
  ) => impl.createPlatformFile(file, bytes, readStream);

  /// Runs an executable with the given arguments and returns the output.
  static Future<String?> runExecutableWithArguments(
    String executable,
    List<String> arguments,
  ) => impl.runExecutableWithArguments(executable, arguments);

  /// Checks if an executable exists on the system path using `which`.
  static Future<String> isExecutableOnPath(String executable) =>
      impl.isExecutableOnPath(executable);

  /// Saves the given [bytes] to a file at [path].
  static Future<void> saveBytesToFile(Uint8List? bytes, String? path) =>
      impl.saveBytesToFile(bytes, path);

  /// Checks if the start of the string [x] is an alphabetical character (a-z or A-Z).
  static bool isAlpha(String x) {
    if (x.isEmpty) return false;
    final int codeUnit = x.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122); // a-z
  }

  /// Validates the [allowedExtensions] parameter against the provided [type].
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
