import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum FileType {
  any,
  media,
  image,
  video,
  audio,
  custom,
}

class FilePicker {
  FilePicker._();
  static const MethodChannel _channel =
      const MethodChannel('miguelruivo.flutter.plugins.filepicker');
  static const String _tag = 'FilePicker';

  /// Returns an iterable `Map<String,String>` where the `key` is the name of the file
  /// and the `value` the path.
  ///
  /// A `List` with [allowedExtensions] can be provided to filter the allowed files to picked.
  /// If provided, make sure you select `FileType.custom` as type.
  /// Defaults to `FileType.any`, which allows any combination of files to be multi selected at once.
  static Future<Map<String, String>> getMultiFilePath(
          {FileType type = FileType.any,
          List<String> allowedExtensions}) async =>
      await _getPath(describeEnum(type), true, allowedExtensions);

  /// Returns an absolute file path from the calling platform.
  ///
  /// Extension filters are allowed with `FileType.custom`, when used, make sure to provide a `List`
  /// of [allowedExtensions] (e.g. [`pdf`, `svg`, `jpg`].).
  /// Defaults to `FileType.any` which will display all file types.
  static Future<String> getFilePath(
          {FileType type = FileType.any,
          List<String> allowedExtensions}) async =>
      await _getPath(describeEnum(type), false, allowedExtensions);

  /// Returns a `File` object from the selected file path.
  ///
  /// This is an utility method that does the same of `getFilePath()` but saving some boilerplate if
  /// you are planing to create a `File` for the returned path.
  static Future<File> getFile(
      {FileType type = FileType.any, List<String> allowedExtensions}) async {
    final String filePath =
        await _getPath(describeEnum(type), false, allowedExtensions);
    return filePath != null ? File(filePath) : null;
  }

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  ///
  /// This typically relates to cached files that are stored in the cache directory of
  /// each platform and it isn't required to invoke this as the system should take care
  /// of it whenever needed. However, this will force the cleanup if you want to manage those on your own.
  ///
  /// Returns `true` if the files were removed with success, `false` otherwise.
  static Future<bool> clearTemporaryFiles() async {
    return _channel.invokeMethod('clear');
  }

  /// Returns a `List<File>` object from the selected files paths.
  ///
  /// This is an utility method that does the same of `getMultiFilePath()` but saving some boilerplate if
  /// you are planing to create a list of `File`s for the returned paths.
  static Future<List<File>> getMultiFile(
      {FileType type = FileType.any, List<String> allowedExtensions}) async {
    final Map<String, String> paths =
        await _getPath(describeEnum(type), true, allowedExtensions);
    return paths != null && paths.isNotEmpty
        ? paths.values.map((path) => File(path)).toList()
        : null;
  }

  static Future<dynamic> _getPath(String type, bool allowMultipleSelection,
      List<String> allowedExtensions) async {
    if (type != 'custom' && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
          'If you are using a custom extension filter, please use the FileType.custom instead.');
    }
    try {
      dynamic result = await _channel.invokeMethod(type, {
        'allowMultipleSelection': allowMultipleSelection,
        'allowedExtensions': allowedExtensions,
      });
      if (result != null && allowMultipleSelection) {
        if (result is String) {
          result = [result];
        }
        return Map<String, String>.fromIterable(result,
            key: (path) => path.split('/').last, value: (path) => path);
      }
      return result;
    } on PlatformException catch (e) {
      print('[$_tag] Platform exception: $e');
      rethrow;
    } catch (e) {
      print(
          '[$_tag] Unsupported operation. Method not found. The exception thrown was: $e');
      rethrow;
    }
  }
}
