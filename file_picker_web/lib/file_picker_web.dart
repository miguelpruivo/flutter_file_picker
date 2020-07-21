import 'dart:async';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:html' as html;

/// File Object wrapper
///
/// [file]  `html.File` object that contains picked file
class File {
  final html.File file;

  File({this.file});

  String get name => file.name;
  String get type => file.type;
  int get size => file.size;
  String toString() => file.toString();

  /// Serialize `html.File` object
  ///
  /// Returns a `<List<int>>`
  Future<List<int>> fileAsBytes() async {
    final Completer<List<int>> bytesFile = Completer<List<int>>();
    final html.FileReader reader = html.FileReader();
    reader.onLoad.listen((event) => bytesFile.complete(reader.result));
    reader.readAsArrayBuffer(file);
    return await bytesFile.future;
  }
}

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
  /// Returns a `List<File>`
  static Future<List<File>> getMultiFile(
      {FileType type = FileType.any, List<String> allowedExtensions}) async {
    return await _instance.getFiles(
        type: type, allowMultiple: true, allowedExtensions: allowedExtensions);
  }

  /// Opens browser file picker window to select a single file.
  /// [type] defaults to `FileType.any` which allows all file types to be picked. Optionally,
  /// [allowedExtensions] can be used (eg. `[.jpg, .pdf]`) to restrict picking types
  ///
  /// Returns a `File`
  static Future<File> getFile(
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
    final Completer<List<File>> pickedFiles = Completer<List<File>>();
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = allowMultiple;
    uploadInput.accept = _fileType(type, allowedExtensions);
    uploadInput.onChange.listen((event) {
      List<File> _files = [];
      uploadInput.files.forEach((file) => _files.add(File(file: file)));
      pickedFiles.complete(_files);
    });
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
        return allowedExtensions.reduce((value, element) => '$value,$element');
        break;
    }
    return '';
  }
}
