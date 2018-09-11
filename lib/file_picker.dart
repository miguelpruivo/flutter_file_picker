import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

class FilePicker {
  static const MethodChannel _channel = const MethodChannel('file_picker');

  static Future<String> get _getPDF async => await _channel.invokeMethod('pickPDF');

  static Future<String> _getImage(ImageSource type) async {
    var image = await ImagePicker.pickImage(source: type);

    return image?.path;
  }

  static Future<String> getFilePath({@required FileType type}) async {
    switch (type) {
      case FileType.PDF:
        return _getPDF;
      case FileType.IMAGE:
        return _getImage(ImageSource.gallery);
      case FileType.CAPTURE:
        return _getImage(ImageSource.camera);
    }
    return '';
  }
}

enum FileType {
  PDF,
  IMAGE,
  CAPTURE,
}
