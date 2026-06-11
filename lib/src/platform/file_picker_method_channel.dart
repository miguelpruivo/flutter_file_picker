import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/src/api/file_picker_result.dart';
import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:file_picker/src/api/platform_file.dart';
import 'package:file_picker/src/file_picker_utils.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:file_picker/src/utils/file_picker_utils.dart';

/// An implementation of [FilePickerPlatform] that uses method channels.
class MethodChannelFilePicker extends FilePickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
    const StandardMethodCodec(),
  );

  /// The event channel used to receive real-time updates from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel(
    'miguelruivo.flutter.plugins.filepickerevent',
  );

  /// Registers this class as the default instance of [FilePickerPlatform].
  static void registerWith() {
    FilePickerPlatform.instance = MethodChannelFilePicker();
  }

  static const String _tag = 'MethodChannelFilePicker';
  static StreamSubscription? _eventSubscription;

  @override
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileLoading,
    bool allowMultiple = false,
    bool? withData = false,
    int compressionQuality = 0,
    bool? withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) => _getPath(
    type,
    allowMultiple,
    allowedExtensions,
    onFileLoading,
    withData,
    withReadStream,
    compressionQuality,
  );

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    try {
      return await methodChannel.invokeMethod('dir', {});
    } on PlatformException catch (ex) {
      if (ex.code == "unknown_path") {
        print(
          '[$_tag] Could not resolve directory path. Maybe it\'s a protected one or unsupported (such as Downloads folder). If you are on Android, make sure that you are on SDK 21 or above.',
        );
      }
    }
    return null;
  }

  Future<FilePickerResult?> _getPath(
    FileType fileType,
    bool allowMultipleSelection,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool? withData,
    bool? withReadStream,
    int? compressionQuality,
  ) async {
    final String type = fileType.name;
    FilePickerUtils.validateAllowedExtensions(fileType, allowedExtensions);
    try {
      if (onFileLoading != null) {
        _eventSubscription = eventChannel.receiveBroadcastStream().listen((
          data,
        ) {
          if (data is! bool) return;
          onFileLoading(
            data ? FilePickerStatus.picking : FilePickerStatus.done,
          );
        }, onError: (error) => throw Exception(error));
      }

      final List<Map>? result = await methodChannel.invokeListMethod(type, {
        'allowMultipleSelection': allowMultipleSelection,
        'allowedExtensions': allowedExtensions,
        'withData': withData,
        'compressionQuality': compressionQuality,
      });

      if (result == null) {
        return null;
      }

      final List<PlatformFile> platformFiles = <PlatformFile>[];

      for (final Map platformFileMap in result) {
        platformFiles.add(
          PlatformFile.fromMap(
            platformFileMap,
            readStream: withReadStream! && platformFileMap['path'] is String
                ? File(platformFileMap['path'] as String).openRead()
                : null,
          ),
        );
      }

      return FilePickerResult(platformFiles);
    } catch (e) {
      rethrow;
    } finally {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
    }
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
    // Ensure at least one source is provided: bytes OR a native reference
    if (bytes == null && path == null) {
      throw ArgumentError('Either bytes or a path must be provided.');
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

    try {
      if (onFileLoading != null) {
        onFileLoading(FilePickerStatus.picking);
        _eventSubscription = eventChannel.receiveBroadcastStream().listen((
          data,
        ) {
          if (data is! bool) return;
          onFileLoading(
            data ? FilePickerStatus.picking : FilePickerStatus.done,
          );
        }, onError: (error) => throw Exception(error));
      }

      final String? savedPath = await methodChannel
          .invokeMethod<String>("save", {
            "fileName": effectiveFileName,
            "fileType": effectiveType.name,
            "initialDirectory": initialDirectory,
            "allowedExtensions": effectiveExtensions,
            if (bytes != null) "bytes": bytes,
            if (path != null) "path": path,
          });

      if (onFileLoading != null) {
        onFileLoading(FilePickerStatus.done);
      }

      return savedPath;
    } catch (e) {
      rethrow;
    } finally {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
    }
  }
}
