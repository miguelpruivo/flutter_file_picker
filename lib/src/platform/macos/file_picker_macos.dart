import 'dart:io';

import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:file_picker/src/api/platform_file.dart';
import 'package:file_picker/src/api/file_picker_result.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:file_picker/src/file_picker_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class FilePickerMacOS extends FilePickerPlatform {
  static void registerWith() {
    FilePickerPlatform.instance = FilePickerMacOS();
  }

  @visibleForTesting
  final methodChannel = const MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
  );

  @override
  Future<List<String>?> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final fileFilter = fileTypeToFileFilter(type, allowedExtensions);

    final filePaths = await methodChannel.invokeListMethod<String>(
      'pickFileAndDirectoryPaths',
      <String, dynamic>{
        'allowedExtensions': fileFilter,
        'initialDirectory': escapeInitialDirectory(initialDirectory),
        'dialogTitle': dialogTitle == null
            ? null
            : escapeDialogTitle(dialogTitle),
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
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    final fileFilter = fileTypeToFileFilter(type, allowedExtensions);

    final filePaths = await methodChannel
        .invokeListMethod<String>('pickFiles', <String, dynamic>{
          'allowedExtensions': fileFilter,
          'dialogTitle': dialogTitle,
          'initialDirectory': escapeInitialDirectory(initialDirectory),
          'allowMultiple': allowMultiple,
        });
    if (filePaths == null) {
      return null;
    }

    final List<PlatformFile> platformFiles = filePaths
        .where((filePath) => filePath.isNotEmpty)
        .map((filePath) {
          final file = File(filePath);
          return PlatformFile(
            name: basename(filePath),
            path: filePath,
            size: file.existsSync() ? file.lengthSync() : 0,
            bytes: null,
            readStream: withReadStream ? file.openRead() : null,
          );
        })
        .toList();

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
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    String? path,
    Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
  }) async {
    if (bytes == null && path == null) {
      throw ArgumentError('macOS saveFile requires bytes or a path.');
    }

    var effectiveType = type;
    var effectiveExtensions = allowedExtensions;
    var effectiveFileName = fileName;
    if (type == FileType.any &&
        (allowedExtensions == null || allowedExtensions.isEmpty)) {
      final detectedExt = await FilePickerUtils.detectExtension(
        bytes: bytes,
        path: path,
        fileName: fileName,
      );
      if (detectedExt != null) {
        effectiveType = FileType.custom;
        effectiveExtensions = [detectedExt];
        final dotIndex = effectiveFileName.lastIndexOf('.');
        if (dotIndex == -1 || dotIndex == effectiveFileName.length - 1) {
          effectiveFileName = '$effectiveFileName.$detectedExt';
        }
      }
    }

    final fileFilter = fileTypeToFileFilter(effectiveType, effectiveExtensions);

    final String? savedFilePath = await methodChannel
        .invokeMethod<String>('saveFile', <String, dynamic>{
          'dialogTitle': escapeDialogTitle(
            dialogTitle ?? FilePickerUtils.defaultDialogTitle,
          ),
          'fileName': effectiveFileName,
          'initialDirectory': escapeInitialDirectory(initialDirectory),
          'allowedExtensions': fileFilter,
        });

    if (savedFilePath == null) return null;

    if (bytes != null) {
      await FilePickerUtils.saveBytesToFile(bytes, savedFilePath);
    } else if (path != null) {
      await FilePickerUtils.copyFile(path, savedFilePath);
    }

    return savedFilePath;
  }

  @override
  Future<void> skipEntitlementsChecks() async {
    await methodChannel.invokeMethod('skipEntitlementsChecks');
  }

  List<String> fileTypeToFileFilter(
    FileType type,
    List<String>? allowedExtensions,
  ) {
    FilePickerUtils.validateAllowedExtensions(type, allowedExtensions);
    switch (type) {
      case FileType.any:
        return [];
      case FileType.audio:
        return ["aac", "midi", "mp3", "ogg", "wav"];
      case FileType.custom:
        return [...?allowedExtensions];
      case FileType.image:
        return ["bmp", "gif", "jpeg", "jpg", "png", "webp"];
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
          "png",
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
          "wmv",
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
