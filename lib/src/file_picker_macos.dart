import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FilePickerMacOS extends FilePicker {
  static void registerWith() {
    FilePicker.platform = FilePickerMacOS();
  }

  @visibleForTesting
  final methodChannel =
      const MethodChannel('miguelruivo.flutter.plugins.filepicker');

  @override
  Future<List<String>?> pickFileAndDirectoryPaths({
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );

    final filePaths = await methodChannel.invokeListMethod<String>(
      'pickFileAndDirectoryPaths',
      <String, dynamic>{
        'allowedExtensions': fileFilter,
        'initialDirectory': escapeInitialDirectory(initialDirectory),
      },
    );

    return filePaths;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated(
        'allowCompression is deprecated and has no effect. Use compressionQuality instead.')
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );

    final filePaths = await methodChannel.invokeListMethod<String>(
      'pickFiles',
      <String, dynamic>{
        'allowedExtensions': fileFilter,
        'initialDirectory': escapeInitialDirectory(initialDirectory),
        'allowMultiple': allowMultiple,
      },
    );
    if (filePaths == null) {
      return null;
    }

    final List<PlatformFile> platformFiles = await filePathsToPlatformFiles(
      filePaths,
      withReadStream,
      withData,
    );

    return FilePickerResult(platformFiles);
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    final String? directoryPath = await methodChannel.invokeMethod<String>(
      'getDirectoryPath',
      <String, dynamic>{
        'initialDirectory': escapeInitialDirectory(initialDirectory),
      },
    );

    return directoryPath;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    final fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );

    final String? savedFilePath = await methodChannel.invokeMethod<String>(
      'saveFile',
      <String, dynamic>{
        'dialogTitle': escapeDialogTitle(dialogTitle ?? defaultDialogTitle),
        'fileName': fileName,
        'initialDirectory': escapeInitialDirectory(initialDirectory),
        'allowedExtensions': fileFilter,
      },
    );

    await saveBytesToFile(bytes, savedFilePath);
    return savedFilePath;
  }

  List<String> fileTypeToFileFilter(
      FileType type, List<String>? allowedExtensions) {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw ArgumentError.value(
        allowedExtensions,
        'allowedExtensions',
        'Custom extension filters are only allowed with FileType.custom. '
            'Remove the extension filter or change the FileType to FileType.custom.',
      );
    }
    switch (type) {
      case FileType.any:
        return [];
      case FileType.audio:
        return ["aac", "midi", "mp3", "ogg", "wav"];
      case FileType.custom:
        return [...?allowedExtensions];
      case FileType.image:
        return ["bmp", "gif", "jpeg", "jpg", "png"];
      case FileType.media:
        return [
          "avi",
          "flv",
          "m4v",
          "mkv",
          "mov",
          "mp4",
          "mpeg",
          "webm",
          "wmv",
          "bmp",
          "gif",
          "jpeg",
          "jpg",
          "png"
        ];
      case FileType.video:
        return [
          "avi",
          "flv",
          "mkv",
          "mov",
          "mp4",
          "m4v",
          "mpeg",
          "webm",
          "wmv"
        ];
    }
  }

  String? escapeInitialDirectory(String? initialDirectory) {
    if (initialDirectory == null) {
      return null;
    }
    // if starts with ~/ or ~ then remove it
    if (initialDirectory.startsWith('~/')) {
      return initialDirectory.substring(2);
    }
    if (initialDirectory.startsWith('~')) {
      return initialDirectory.substring(1);
    }
    return initialDirectory;
  }

  String escapeDialogTitle(String dialogTitle) => dialogTitle
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\\n');
}
