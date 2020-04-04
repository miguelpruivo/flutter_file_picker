// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

import 'package:file_picker/file_picker.dart';

abstract class FilePickerInterface {
  FilePickerInterface._();

  /// and the `value` the path.
  ///
  /// A [fileExtension] can be provided to filter the picking results.
  /// If provided, it will be use the `FileType.CUSTOM` for that [fileExtension].
  /// If not, `FileType.ANY` will be used and any combination of files can be multi picked at once.
  static Future<Map<String, String>> getMultiFilePath({FileType type = FileType.any, String fileExtension}) async =>
      throw UnimplementedError('Unsupported Platform for file_picker_cross');

  /// Returns an absolute file path from the calling platform.
  ///
  /// A [type] must be provided to filter the picking results.
  /// Can be used a custom file type with `FileType.CUSTOM`. A [fileExtension] must be provided (e.g. PDF, SVG, etc.)
  /// Defaults to `FileType.ANY` which will display all file types.
  static Future<String> getFilePath({FileType type = FileType.any, String fileExtension}) async =>
      throw UnimplementedError('Unsupported Platform for file_picker_cross');

  /// Returns a `File` object from the selected file path.
  ///
  /// This is an utility method that does the same of `getFilePath()` but saving some boilerplate if
  /// you are planing to create a `File` for the returned path.
  static Future<html.File> getFile({FileType type = FileType.any, String fileExtension}) async =>
      throw UnimplementedError('Unsupported Platform for file_picker_cross');

  /// Returns a `List<File>` object from the selected files paths.
  ///
  /// This is an utility method that does the same of `getMultiFilePath()` but saving some boilerplate if
  /// you are planing to create a list of `File`s for the returned paths.
  static Future<List<html.File>> getMultiFile({FileType type = FileType.any, String fileExtension}) async =>
      throw UnimplementedError('Unsupported Platform for file_picker_cross');

  /// Returns a `List<html.File>` with picked file(s) to be used in a web context.
  /// Allows setting [allowMultiple] for multiple file picking (defaults to `false`).
  ///
  /// **IMPORTANT:** Have in mind that if you specify a type when picking (eg. by not using `var` or `final`),
  /// you should define it as `html.File` by for example importing
  /// ```
  /// import 'dart:html' as html;
  /// ```
  /// otherwise it could be jumbled with Dart IO File object and throw an error.
  static Future<dynamic> handleGetFile(String type, bool allowMultiple) async {
    final Completer<List<html.File>> pickedFiles = Completer<List<html.File>>();
    html.InputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = allowMultiple;
    uploadInput.click();
    uploadInput.onChange.listen((event) => pickedFiles.complete(uploadInput.files));
    return await pickedFiles.future;
  }
}
