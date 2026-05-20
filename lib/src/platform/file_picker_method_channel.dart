import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/src/api/file_picker_result.dart';
import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:file_picker/src/api/platform_file.dart';
import 'package:file_picker/src/api/android_saf_options.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:file_picker/src/file_picker_utils.dart';

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
    AndroidSAFOptions? androidSafOptions,
  }) => _getPath(
    type,
    allowMultiple,
    allowedExtensions,
    onFileLoading,
    withData,
    withReadStream,
    compressionQuality,
    androidSafOptions,
  );

  @override
  Future<void> releaseSAFGrant(String uri) async {
    await methodChannel.invokeMethod('releaseSafGrant', {'uri': uri});
  }

  @override
  Future<bool?> clearTemporaryFiles() async =>
      methodChannel.invokeMethod<bool>('clear');

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
    AndroidSAFOptions? androidSafOptions,
  }) async {
    try {
      return await methodChannel.invokeMethod('dir', {
        if (androidSafOptions != null)
          'androidSafOptions': androidSafOptions.toMap(),
      });
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
    AndroidSAFOptions? androidSafOptions,
  ) async {
    final String type = fileType.name;
    if (type != 'custom' && (allowedExtensions?.isNotEmpty ?? false)) {
      throw ArgumentError.value(
        allowedExtensions,
        'allowedExtensions',
        'Custom extension filters are only allowed with FileType.custom. '
            'Remove the extension filter or change the FileType to FileType.custom.',
      );
    }
    try {
      if (onFileLoading != null) {
        _eventSubscription = eventChannel.receiveBroadcastStream().listen((
          data,
        ) {
          if (data is! bool) return;
          if (data) {
            onFileLoading(FilePickerStatus.picking);
          }
        }, onError: (error) => throw Exception(error));
      }

      final List<Map>? result = await methodChannel.invokeListMethod(type, {
        'allowMultipleSelection': allowMultipleSelection,
        'allowedExtensions': allowedExtensions,
        'withData': withData,
        'compressionQuality': compressionQuality,
        if (androidSafOptions != null)
          'androidSafOptions': androidSafOptions.toMap(),
      });

      if (result == null) {
        onFileLoading?.call(FilePickerStatus.done);
        return null;
      }

      await _eventSubscription?.cancel();
      _eventSubscription = null;

      final List<PlatformFile> platformFiles = [];
      for (final Map platformFileMap in result) {
        final String? path = platformFileMap['path'] as String?;

        Uint8List? bytes = platformFileMap['bytes'] as Uint8List?;

        if ((withData ?? false) && bytes == null && path != null) {
          bytes = await FilePickerUtils.readBytesFromFile(path);
        }

        platformFiles.add(
          PlatformFile.fromMap({
            ...platformFileMap,
            'bytes': bytes,
          }, readStream: withReadStream! ? File(path!).openRead() : null),
        );
      }

      onFileLoading?.call(FilePickerStatus.done);

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
    Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
  }) async {
    if (bytes == null) {
      throw ArgumentError(
        'The "bytes" parameter is required on Android & iOS when calling "saveFile".',
      );
    }

    try {
      if (onFileLoading != null) {
        onFileLoading(FilePickerStatus.picking);
        _eventSubscription = eventChannel.receiveBroadcastStream().listen((
          data,
        ) {
          if (data is! bool) return;
          if (data) {
            onFileLoading(FilePickerStatus.picking);
          }
        }, onError: (error) => throw Exception(error));
      }

      final String? savedPath = await methodChannel
          .invokeMethod<String>("save", {
            "fileName": fileName,
            "fileType": type.name,
            "initialDirectory": initialDirectory,
            "allowedExtensions": allowedExtensions,
            "bytes": bytes,
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
