import 'dart:async';

import 'package:flutter/services.dart';

String _kCustomType = '__CUSTOM_';

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

  static Future<dynamic> _getPath(String type, [bool multipleSelection = false]) async {
    try {
      dynamic result = await _channel.invokeMethod(type, multipleSelection);
      if (multipleSelection) {
        if (result is String) {
          result = [result];
        }
        return Map<String, String>.fromIterable(result, key: (path) => path.split('/').last, value: (path) => path);
      }
      return result;
    } on PlatformException catch (e) {
      print("[$_tag] Platform exception: " + e.toString());
    } catch (e) {
      print(e.toString());
      print(
          "[$_tag] Unsupported operation. This probably have happened because [${type.split('_').last}] is an unsupported file type. You may want to try FileType.ALL instead.");
    }
    return null;
  }

  /// Returns an iterable `Map<String,String>` where the `key` is the name of the file
  /// and the `value` the path.
  ///
  /// A [fileExtension] can be provided to filter the picking results.
  /// If provided, it will be use the `FileType.CUSTOM` for that [fileExtension].
  /// If not, `FileType.ANY` will be used and any combination of files can be multi picked at once.
  static Future<Map<String, String>> getMultiFilePath({String fileExtension}) async =>
      await _getPath(fileExtension != null ? (_kCustomType + fileExtension) : 'ANY', true);

  /// Returns an absolute file path from the calling platform
  ///
  /// A [type] must be provided to filter the picking results.
  /// Can be used a custom file type with `FileType.CUSTOM`. A [fileExtension] must be provided (e.g. PDF, SVG, etc.)
  /// Defaults to `FileType.ANY` which will display all file types.
  static Future<String> getFilePath({FileType type = FileType.ANY, String fileExtension}) async {
    var path;
    switch (type) {
      case FileType.IMAGE:
        path = _getPath('IMAGE');
        break;
      case FileType.AUDIO:
        path = _getPath('AUDIO');
        break;
      case FileType.VIDEO:
        path = _getPath('VIDEO');
        break;
      case FileType.ANY:
        path = _getPath('ANY');
        break;
      case FileType.CUSTOM:
        path = _getPath(_kCustomType + (fileExtension ?? ''));
        break;
      default:
        break;
    }
    return await path;
  }
}
