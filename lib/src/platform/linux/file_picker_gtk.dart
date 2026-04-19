import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/file_picker_utils.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/services.dart';

class FilePickerGTK extends FilePickerPlatform {
  static void registerWith() {
    FilePickerPlatform.instance = FilePickerGTK();
  }

  final methodChannel = const MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
  );

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = true,
    bool readSequential = false,
    int compressionQuality = 0,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    final List<String>? pickedFilePaths = await methodChannel
        .invokeListMethod<String>('pickFiles', <String, dynamic>{
      'dialogTitle': dialogTitle,
      'initialDirectory': initialDirectory,
      'type': type.name,
      'allowedExtensions': allowedExtensions?.join(',') ?? '',
      'allowMultiple': allowMultiple,
      'fileOnly': true,
    });
    if (pickedFilePaths == null) {
      return null;
    }
    final platformFiles = pickedFilePaths
        .map((path) => PlatformFile(
              path: path,
              name: path.split('/').last,
              size: File(path).lengthSync(),
            ))
        .toList();

    return FilePickerResult(platformFiles);
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = true,
    String? initialDirectory,
  }) async {
    final List<String>? directoryPaths = await pickDirectoryPaths(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      allowMultiple: false,
    );
    return directoryPaths?.firstOrNull;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = true,
  }) async {
    final String? savedFilePath = await methodChannel.invokeMethod<String>(
      'saveFile',
      <String, dynamic>{
        'dialogTitle': dialogTitle,
        'initialDirectory': initialDirectory,
        'fileName': fileName,
      },
    );
    await FilePickerUtils.saveBytesToFile(bytes, savedFilePath);
    return savedFilePath;
  }

  @override
  Future<List<String>?> pickDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    bool allowMultiple = false,
  }) async {
    final List<String>? directoryPaths =
        await methodChannel.invokeListMethod<String>(
      'pickDirectoryPaths',
      <String, dynamic>{
        'dialogTitle': dialogTitle,
        'initialDirectory': initialDirectory,
        'allowMultiple': allowMultiple,
      },
    );

    return directoryPaths;
  }
}
