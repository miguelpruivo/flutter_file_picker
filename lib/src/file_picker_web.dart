import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'file_picker_result.dart';
import 'platform_file.dart';

class FilePickerWeb extends FilePicker {
  Element _target;
  final String _kFilePickerInputsDomId = '__file_picker_web-file-input';

  static final FilePickerWeb platform = FilePickerWeb._();

  FilePickerWeb._() {
    _target = _ensureInitialized(_kFilePickerInputsDomId);
  }

  static void registerWith(Registrar registrar) {
    FilePicker.platform = platform;
  }

  /// Initializes a DOM container where we can host input elements.
  Element _ensureInitialized(String id) {
    Element target = querySelector('#$id');
    if (target == null) {
      final Element targetElement = Element.tag('flt-file-picker-inputs')
        ..id = id;

      querySelector('body').children.add(targetElement);
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
    InputElement uploadInput = FileUploadInputElement();
    uploadInput.draggable = true;
    uploadInput.multiple = allowMultiple;
    uploadInput.accept = accept;

    bool changeEventTriggered = false;
    void changeEventListener(e) {
      if (changeEventTriggered) {
        return;
      }
      changeEventTriggered = true;

      final List<File> files = uploadInput.files;
      final List<PlatformFile> pickedFiles = [];

      void addPickedFile(File file, Uint8List bytes, String path) {
        pickedFiles.add(PlatformFile(
          name: file.name,
          path: path,
          size: bytes != null ? bytes.length ~/ 1024 : -1,
          bytes: bytes,
        ));

        if (pickedFiles.length >= files.length) {
          filesCompleter.complete(pickedFiles);
        }
      }

      files.forEach((File file) {
        if (!withData) {
          final FileReader reader = FileReader();
          reader.onLoadEnd.listen((e) {
            addPickedFile(file, null, reader.result);
          });
          reader.readAsDataUrl(file);
          return;
        }

        final FileReader reader = FileReader();
        reader.onLoadEnd.listen((e) {
          addPickedFile(file, reader.result, null);
        });
        reader.readAsArrayBuffer(file);
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
