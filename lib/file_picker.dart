import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

enum FileType {
  ANY,
  IMAGE,
  VIDEO,
  AUDIO,
  CUSTOM,
}

class FilePicker {
  static const MethodChannel _channel = const MethodChannel('file_picker');
  static const String _tag = 'FilePicker';

  FilePicker._();

  /// Returns an iterable `Map<String,String>` where the `key` is the name of the file
  /// and the `value` the path.
  ///
  /// A [fileExtension] can be provided to filter the picking results.
  /// If provided, it will be use the `FileType.CUSTOM` for that [fileExtension].
  /// If not, `FileType.ANY` will be used and any combination of files can be multi picked at once.
  static Future<Map<String, String>> getMultiFilePath(
          {FileType type = FileType.ANY, String fileExtension}) async =>
      await _getPath(_handleType(type, fileExtension), true);

  /// Returns an absolute file path from the calling platform.
  ///
  /// A [type] must be provided to filter the picking results.
  /// Can be used a custom file type with `FileType.CUSTOM`. A [fileExtension] must be provided (e.g. PDF, SVG, etc.)
  /// Defaults to `FileType.ANY` which will display all file types.
  static Future<String> getFilePath(
          {FileType type = FileType.ANY, String fileExtension}) async =>
      await _getPath(_handleType(type, fileExtension), false);

  /// Returns a `File` object from the selected file path.
  ///
  /// This is an utility method that does the same of `getFilePath()` but saving some boilerplate if
  /// you are planing to create a `File` for the returned path.
  static Future<File> getFile(
      {FileType type = FileType.ANY, String fileExtension}) async {
    final String filePath =
        await _getPath(_handleType(type, fileExtension), false);
    return filePath != null ? File(filePath) : null;
  }

  static Future<dynamic> _getPath(String type, bool multipleSelection) async {
    try {
      dynamic result = await _channel.invokeMethod(type, multipleSelection);
      if (result != null && multipleSelection) {
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

  static String _handleType(FileType type, String fileExtension) {
    switch (type) {
      case FileType.IMAGE:
        return 'IMAGE';
      case FileType.AUDIO:
        return 'AUDIO';
      case FileType.VIDEO:
        return 'VIDEO';
      case FileType.ANY:
        return 'ANY';
      case FileType.CUSTOM:
        return '__CUSTOM_' + (fileExtension ?? '');
      default:
        return 'ANY';
    }
  }
}
