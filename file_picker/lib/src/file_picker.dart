import 'dart:typed_data';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

/// Public facade that mirrors the old API and delegates to the federated
/// platform implementations via `FilePickerPlatform.instance`.
class FilePicker {
  static Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileLoading,
    bool allowMultiple = false,
    bool? withData,
    int compressionQuality = 0,
    bool? withReadStream,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    AndroidSAFOptions? androidSafOptions,
  }) {
    return FilePickerPlatform.instance.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      onFileLoading: onFileLoading,
      allowMultiple: allowMultiple,
      withData: withData ?? false,
      compressionQuality: compressionQuality,
      withReadStream: withReadStream ?? false,
      lockParentWindow: lockParentWindow,
      readSequential: readSequential,
      cancelUploadOnWindowBlur: cancelUploadOnWindowBlur,
      androidSafOptions: androidSafOptions,
    );
  }

  static Future<PlatformFile?> pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileLoading,
    bool? withData,
    int compressionQuality = 0,
    bool? withReadStream,
    bool lockParentWindow = false,
    AndroidSAFOptions? androidSafOptions,
  }) async {
    final res = await pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      onFileLoading: onFileLoading,
      allowMultiple: false,
      withData: withData,
      compressionQuality: compressionQuality,
      withReadStream: withReadStream,
      lockParentWindow: lockParentWindow,
      androidSafOptions: androidSafOptions,
    );
    return res?.files.first;
  }

  static Future<List<String>?> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) {
    return FilePickerPlatform.instance.pickFileAndDirectoryPaths(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
    );
  }

  static Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
    AndroidSAFOptions? androidSafOptions,
  }) {
    return FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: dialogTitle,
      lockParentWindow: lockParentWindow,
      initialDirectory: initialDirectory,
      androidSafOptions: androidSafOptions,
    );
  }

  static Future<bool?> clearTemporaryFiles() =>
      FilePickerPlatform.instance.clearTemporaryFiles();

  static Future<String?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    required Uint8List bytes,
    Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
  }) {
    return FilePickerPlatform.instance.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
      onFileLoading: onFileLoading,
      lockParentWindow: lockParentWindow,
    );
  }
}
