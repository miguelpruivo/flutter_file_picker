import 'dart:async';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:html' as html;

class FilePicker extends FilePickerPlatform {
  FilePicker._();
  static final FilePicker _instance = FilePicker._();

  static void registerWith(Registrar registrar) {
    FilePickerPlatform.instance = _instance;
  }

  /// Opens browser file picker window to select multiple files.
  /// [type] defaults to `FileType.any` which allows all file types to be picked. Optionally,
  /// [allowedExtensions] can be used (eg. `[.jpg, .pdf]`) to restrict picking types
  ///
  /// Returns a `List<html.File>`
  static Future<List<html.File>> getMultiFile(
      {FileType type = FileType.any, List<String> allowedExtensions}) async {
    return await _instance.getFiles(
        type: type, allowMultiple: true, allowedExtensions: allowedExtensions);
  }

  /// Opens browser file picker window to select a single file.
  /// [type] defaults to `FileType.any` which allows all file types to be picked. Optionally,
  /// [allowedExtensions] can be used (eg. `[.jpg, .pdf]`) to restrict picking types
  ///
  /// Returns a `html.File`
  static Future<html.File> getFile(
      {FileType type = FileType.any, List<String> allowedExtensions}) async {
    return (await _instance.getFiles(
            type: type, allowedExtensions: allowedExtensions))
        .first;
  }

  @override
  Future<dynamic> getFiles({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    bool allowMultiple = false,
  }) async {
    final Completer<List<html.File>> pickedFiles = Completer<List<html.File>>();
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = allowMultiple;
    uploadInput.accept = _fileType(type, allowedExtensions);
    uploadInput.click();
    uploadInput.onChange
        .listen((event) => pickedFiles.complete(uploadInput.files));
    return await pickedFiles.future;
  }

  static String _fileType(FileType type, List<String> allowedExtensions) {
    switch (type) {
      case FileType.any:
        return '';

      case FileType.audio:
        return 'audio/*';

      case FileType.image:
        return 'image/*';

      case FileType.video:
        return 'video/*';

      case FileType.media:
        return 'video/*|image/*';

      case FileType.custom:
        return allowedExtensions.reduce((value, element) => '$value,$element');
        break;
    }
    return '';
  }
}
