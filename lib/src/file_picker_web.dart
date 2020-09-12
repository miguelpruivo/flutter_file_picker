import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'file_picker_result.dart';
import 'platform_file.dart';

class FilePickerWeb extends FilePicker {
  FilePickerWeb._();
  static final FilePickerWeb platform = FilePickerWeb._();

  static void registerWith(Registrar registrar) {
    FilePicker.platform = platform;
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
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      List<PlatformFile> pickedFiles = [];

      files.forEach((element) {
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          final Uint8List bytes =
              Base64Decoder().convert(reader.result.toString().split(",").last);

          pickedFiles.add(
            PlatformFile(
              name: uploadInput.value.replaceAll('\\', '/'),
              path: uploadInput.value,
              size: bytes.length ~/ 1024,
              bytes: withData ? bytes : null,
            ),
          );

          if (pickedFiles.length >= files.length) {
            filesCompleter.complete(pickedFiles);
          }
        });

        reader.readAsDataUrl(element);
      });
    });
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
