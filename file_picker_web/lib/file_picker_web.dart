import 'dart:async';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:html' as html;

class FilePicker extends FilePickerPlatform {
  static final FilePicker _instance = FilePicker._();

  html.Element _target;
  final String _kImagePickerInputsDomId = '__file_picker_web-file-input';

  FilePicker._() {
    _target = _ensureInitialized(_kImagePickerInputsDomId);
  }

  static void registerWith(Registrar registrar) {
    FilePickerPlatform.instance = _instance;
  }

  /// Initializes a DOM container where we can host input elements.
  html.Element _ensureInitialized(String id) {
    var target = html.querySelector('#${id}');
    if (target == null) {
      final html.Element targetElement =
      html.Element.tag('flt-file-picker-inputs')..id = id;

      html.querySelector('body').children.add(targetElement);
      target = targetElement;
    }
    return target;
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
    Function(FilePickerStatus) onFileLoading,
  }) async {
    final Completer<List<html.File>> pickedFiles = Completer<List<html.File>>();
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = allowMultiple;
    uploadInput.accept = _fileType(type, allowedExtensions);
    uploadInput.onChange.listen((event) {
      if (pickedFiles.isCompleted) {
        return;
      }
      pickedFiles.complete(uploadInput.files);
    });
    uploadInput.addEventListener('change', (event) {
      if (pickedFiles.isCompleted) {
        return;
      }
      pickedFiles.complete(uploadInput.files);
    });

    _target.children.clear();
    _target.children.add(uploadInput);
    uploadInput.click();
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
        return allowedExtensions.fold(
            '', (prev, next) => '${prev.isEmpty ? '' : '$prev,'} .$next');
        break;
    }
    return '';
  }
}
