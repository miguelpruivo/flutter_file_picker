import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Supported file types, [ANY] should be used if the file you need isn't listed
enum FileType {
  ANY,
  IMAGE,
  VIDEO,
  CAMERA,
  CUSTOM,
}

class FilePicker {
  static const MethodChannel _channel = const MethodChannel('file_picker');
  static const String _tag = 'FilePicker';

  static Future<String> _getPath(String type) async {
    try {
      return await _channel.invokeMethod(type);
    } on PlatformException catch (e) {
      print("[$_tag] Platform exception: " + e.toString());
    } catch (e) {
      print(
          "[$_tag] Unsupported operation. This probably have happened because [${type.split('_').last}] is an unsupported file type. You may want to try FileType.ALL instead.");
    }
    return null;
  }

  static Future<String> _getImage(ImageSource type) async {
    try {
      var image = await ImagePicker.pickImage(source: type);
      return image?.path;
    } on PlatformException catch (e) {
      print("[$_tag] Platform exception: " + e.toString());
    }
    return null;
  }

  /// Returns an absolute file path from the calling platform
  ///
  /// A [type] must be provided to filter the picking results.
  /// Can be used a custom file type with `FileType.CUSTOM`. A [fileExtension] must be provided (e.g. PDF, SVG, etc.)
  /// Defaults to `FileType.ANY` which will display all file types.
  static Future<String> getFilePath({FileType type = FileType.ANY, String fileExtension}) async {
    switch (type) {
      case FileType.IMAGE:
        return _getImage(ImageSource.gallery);
      case FileType.CAMERA:
        return _getImage(ImageSource.camera);
      case FileType.VIDEO:
        return _getPath('VIDEO');
      case FileType.ANY:
        return _getPath('ANY');
      case FileType.CUSTOM:
        return _getPath('__CUSTOM_' + (fileExtension ?? ''));
      default:
        return _getPath('ANY');
    }
  }
}
