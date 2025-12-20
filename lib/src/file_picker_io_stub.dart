import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// An implementation of [FilePicker] that throws UnimplementedError
/// for platforms that do not support dart:io (like Web).
class FilePickerIO extends FilePicker {
  static void registerWith() {
    FilePicker.platform = FilePickerIO();
  }

  @override
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileLoading,
    bool? allowCompression = false,
    bool allowMultiple = false,
    bool? withData = false,
    int compressionQuality = 0,
    bool? withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) =>
      throw UnimplementedError('pickFiles() has not been implemented.');

  @override
  Future<bool?> clearTemporaryFiles() async => throw UnimplementedError(
      'clearTemporaryFiles() has not been implemented.');

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      throw UnimplementedError('getDirectoryPath() has not been implemented.');

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async =>
      throw UnimplementedError('saveFile() has not been implemented.');
}
