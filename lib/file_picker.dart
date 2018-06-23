import 'dart:async';

import 'package:flutter/services.dart';

class FilePicker {
  static const MethodChannel _channel = const MethodChannel('file_picker');

  static Future<String> get getFilePath async => await _channel.invokeMethod('pickPDF');
}
