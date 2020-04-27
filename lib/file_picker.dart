import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html';

import 'file_picker_stub.dart' if (dart.library.io) 'file_picker_mobile.dart' if (dart.library.html) 'file_picker_web.dart';

enum FileType {
  any,
  image,
  video,
  audio,
  custom,
}

abstract class FilePicker {
  FilePicker._();
  static const String tag = 'FilePicker';

  /// Returns an iterable `Map<String,String>` where the `key` is the name of the file
  /// and the `value` the path.
  ///
  /// A [fileExtension] can be provided to filter the picking results.
  /// If provided, it will be use the `FileType.CUSTOM` for that [fileExtension].
  /// If not, `FileType.ANY` will be used and any co mbination of files can be multi picked at once.
  static Future<Map<String, String>> getMultiFilePath({FileType type = FileType.any, String fileExtension}) async =>
      await FilePickerInterface.getMultiFilePath(type: type, fileExtension: fileExtension);

  /// Returns an absolute file path from the calling platform.
  ///
  /// A [type] must be provided to filter the picking results.
  /// Can be used a custom file type with `FileType.CUSTOM`. A [fileExtension] must be provided (e.g. PDF, SVG, etc.)
  /// Defaults to `FileType.ANY` which will display all file types.
  static Future<String> getFilePath({FileType type = FileType.any, String fileExtension}) async =>
      await FilePickerInterface.getFilePath(type: type, fileExtension: fileExtension);

  /// Returns a `File` object from the selected file path.
  ///
  /// This is an utility method that does the same of `getFilePath()` but saving some boilerplate if
  /// you are planing to create a `File` for the returned path.
  static Future<File> getFile({FileType type = FileType.any, String fileExtension}) async =>
      await FilePickerInterface.getFile(type: type, fileExtension: fileExtension);

  /// Returns a `List<File>` object from the selected files paths.
  ///
  /// This is an utility method that does the same of `getMultiFilePath()` but saving some boilerplate if
  /// you are planing to create a list of `File`s for the returned paths.
  static Future<List<File>> getMultiFile({FileType type = FileType.any, String fileExtension}) async =>
      await FilePickerInterface.getMultiFile(type: type, fileExtension: fileExtension);
}
