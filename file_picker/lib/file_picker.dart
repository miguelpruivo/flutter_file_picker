import 'dart:async';
import 'dart:io';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:file_picker_platform_interface/method_channel_file_picker.dart';

export 'package:file_picker_platform_interface/file_picker_platform_interface.dart'
    show FileType;

final MethodChannelFilePicker _filePickerPlatform = FilePickerPlatform.instance;

class FilePicker {
  FilePicker._();

  /// Returns an absolute file path from the calling platform.
  ///
  /// Extension filters are allowed with [FileType.custom], when used, make sure to provide a [List]
  /// of `allowedExtensions` (e.g. [`pdf`, `svg`, `jpg`].).
  ///
  /// If you want to track picking status, for example, because some files may take some time to be
  /// cached (particularly those picked from cloud providers), you may want to set [onFileLoading] handler
  /// that will give you the current status of picking.
  ///
  /// If you plan on picking images/videos and don't want them to be compressed automatically by OS,
  /// you should set `allowCompression` to [false]. Calling this on Android won't have any effect, as
  /// it already provides you the original file (or integral copy).
  ///
  /// Defaults to [FileType.any] which will display all file types.
  static Future<String> getFilePath({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    Function(FilePickerStatus) onFileLoading,
    bool allowCompression,
  }) async =>
      await _filePickerPlatform.getFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        onFileLoading: onFileLoading,
        allowCompression: allowCompression,
      );

  /// Returns an iterable [Map<String,String>] where the `key` is the name of the file
  /// and the `value` the path.
  ///
  /// A [List] with `allowedExtensions` can be provided to filter the allowed files to picked.
  /// If provided, make sure you select [FileType.custom] as type.
  ///
  /// If you want to track picking status, for example, because some files may take some time to be
  /// cached (particularly those picked from cloud providers), you may want to set `onFileLoading` handler
  /// that will give you the current status of picking.
  ///
  /// If you plan on picking images/videos and don't want them to be compressed automatically by OS,
  /// you should set `allowCompression` to [false]. Calling this on Android won't have any effect, as
  /// it already provides you the original file (or integral copy).
  ///
  /// Defaults to `FileType.any`, which allows any combination of files to be multi selected at once.
  static Future<Map<String, String>> getMultiFilePath({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    Function(FilePickerStatus) onFileLoading,
    bool allowCompression,
  }) async =>
      await _filePickerPlatform.getFiles(
        type: type,
        allowMultiple: true,
        allowedExtensions: allowedExtensions,
        onFileLoading: onFileLoading,
        allowCompression: allowCompression,
      );

  /// Returns a [File] object from the selected file path.
  ///
  /// This is an utility method that does the same of [getFilePath] but saving some boilerplate if
  /// you are planing to create a [File] for the returned path.
  static Future<File> getFile({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    Function(FilePickerStatus) onFileLoading,
    bool allowCompression,
  }) async {
    final String filePath = await _filePickerPlatform.getFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      allowCompression: allowCompression,
    );
    return filePath != null ? File(filePath) : null;
  }

  /// Returns a [List<File>] object from the selected files paths.
  ///
  /// This is an utility method that does the same of [getMultiFilePath] but saving some boilerplate if
  /// you are planing to create a list of [File]`s for the returned paths.
  static Future<List<File>> getMultiFile({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    Function(FilePickerStatus) onFileLoading,
    bool allowCompression,
  }) async {
    final Map<String, String> paths = await _filePickerPlatform.getFiles(
      type: type,
      allowMultiple: true,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      allowCompression: allowCompression,
    );

    return paths != null && paths.isNotEmpty
        ? paths.values.map((path) => File(path)).toList()
        : null;
  }

  /// Selects a directory and returns its absolute path.
  ///
  /// On Android, this requires to be running on SDK 21 or above, else won't work.
  /// Returns [null] if folder path couldn't be resolved.
  static Future<String> getDirectoryPath() async {
    return _filePickerPlatform.getDirectoryPath();
  }

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  ///
  /// This typically relates to cached files that are stored in the cache directory of
  /// each platform and it isn't required to invoke this as the system should take care
  /// of it whenever needed. However, this will force the cleanup if you want to manage those on your own.
  ///
  /// Returns [true] if the files were removed with success, [false] otherwise.
  static Future<bool> clearTemporaryFiles() async {
    return _filePickerPlatform.clearTemporaryFiles();
  }
}
