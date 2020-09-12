import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'file_picker_result.dart';
import 'platform_file.dart';

class FilePickerWeb extends FilePicker {
  html.Element _target;
  final String _kFilePickerInputsDomId = '__file_picker_web-file-input';

  static final FilePickerWeb platform = FilePickerWeb._();

  FilePickerWeb._() {
    _target = _ensureInitialized(_kFilePickerInputsDomId);
  }

  static void registerWith(Registrar registrar) {
    FilePicker.platform = platform;
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

  @override
  Future<FilePickerResult> pickFiles({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus) onFileLoading,
    bool allowCompression,
    bool withData = true,
  }) async {
    final Completer<List<PlatformFile>> filesCompleter =
        Completer<List<PlatformFile>>();

    String accept = _fileType(type, allowedExtensions);
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.draggable = true;
    uploadInput.multiple = allowMultiple;
    uploadInput.accept = accept;

    bool changeEventTriggered = false;
    void changeEventListener (e) {
      if (changeEventTriggered) {
        return;
      }
      changeEventTriggered = true;

      final files = uploadInput.files;

      List<PlatformFile> pickedFiles = [];

      files.forEach((element) {
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          Uint8List bytes;
          if (withData) {
            bytes = reader.result;
          }

          pickedFiles.add(
            PlatformFile(
              name: uploadInput.value.split('\\').last,
              path: uploadInput.value,
              size: bytes.length,
              bytes: withData ? bytes : null,
            ),
          );

          if (pickedFiles.length >= files.length) {
            filesCompleter.complete(pickedFiles);
          }
        });

        reader.readAsArrayBuffer(element);
      });
    }

    uploadInput.onChange.listen(changeEventListener);
    uploadInput.addEventListener('change', changeEventListener);

    //Add input element to the page body
    _target.children.clear();
    _target.children.add(uploadInput);
    uploadInput.click();

    return FilePickerResult(await filesCompleter.future);
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
