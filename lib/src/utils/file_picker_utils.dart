import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '_file_utils_web.dart'
    if (dart.library.io) '_file_utils_io.dart'
    as impl;

/// Utility class for [FilePicker] that provides common helper methods
/// used across different platform implementations.
class FilePickerUtils {
  /// The default title for the file picker dialog.
  static const String defaultDialogTitle = 'File Picker';

  /// Converts a list of file paths into a list of [PlatformFile]s.
  ///
  /// The [filePaths] is the list of absolute paths to the selected files.
  /// If [withReadStream] is true, the [PlatformFile] will contain a readable [Stream] of the file contents.
  /// If [withData] is true, the [PlatformFile] will contain the file bytes.
  /// This option should be used with caution, due to potentially loading large files in one [Uint8List].
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
  ///
  /// The [file] is the source file.
  /// This is typed as [Object] to satisfy restrictions around conditional imports.
  /// The [bytes] are the file bytes.
  /// The [readStream] is a [Stream] of the file content.
  @visibleForTesting
  static Future<PlatformFile> createPlatformFile(
    Object file,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
  ) => impl.createPlatformFile(file, bytes, readStream);

  /// Runs an executable with the given arguments and returns the output.
  ///
  /// Returns the trimmed stdout as a [String], or null if the process fails
  /// or produces no output.
  static Future<String?> runExecutableWithArguments(
    String executable,
    List<String> arguments,
  ) => impl.runExecutableWithArguments(executable, arguments);

  /// Checks if an executable exists on the system path using `which`.
  ///
  /// Returns the absolute path to the executable if found.
  /// Throws an [Exception] if the executable is not found.
  static Future<String> isExecutableOnPath(String executable) =>
      impl.isExecutableOnPath(executable);

  /// Saves the given [bytes] to a file at [path].
  ///
  /// Does nothing if [path] or [bytes] is null or empty.
  static Future<void> saveBytesToFile(Uint8List? bytes, String? path) =>
      impl.saveBytesToFile(bytes, path);

  /// Checks if the start of the string [x] is an alphabetical character (a-z or A-Z).
  ///
  /// Returns true if the first character of [x] is a letter.
  static bool isAlpha(String x) {
    if (x.isEmpty) return false;
    final int codeUnit = x.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122); // a-z
  }

  /// Validates the [allowedExtensions] parameter against the provided [type].
  ///
  /// Throws an [ArgumentError] if extension filters are provided while the
  /// [type] is not [FileType.custom].
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
