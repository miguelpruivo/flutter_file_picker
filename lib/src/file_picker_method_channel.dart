import 'dart:async';
import 'dart:io';

import 'package:file_picker/src/file_picker_result.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_picker.dart';
import 'file_picker_platform_interface.dart';

/// An implementation of [FilePickerPlatform] that uses method channels.
class MethodChannelFilePicker extends FilePickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
    JSONMethodCodec(),
  );

  /// The event channel used to receive real-time updates from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel(
    'miguelruivo.flutter.plugins.filepickerevent',
  );

  static const String _tag = 'MethodChannelFilePicker';
  static StreamSubscription? _eventSubscription;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) {
    return _getPath(
      type,
      allowMultiple,
      allowCompression,
      allowedExtensions,
      onFileLoading,
      withData,
      withReadStream,
      compressionQuality,
    );
  }

  @override
  Future<bool?> clearTemporaryFiles() async =>
      methodChannel.invokeMethod<bool>('clear');

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
            '[$_tag] Could not resolve directory path. Maybe it\'s a protected one or unsupported (such as Downloads folder). If you are on Android, make sure that you are on SDK 21 or above.');
      }
    }
    return null;
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
  }) {
    if (Platform.isIOS || Platform.isAndroid) {
      if (bytes == null) {
        throw ArgumentError(
            'Bytes are required on Android & iOS when saving a file.');
      }

      return methodChannel.invokeMethod("save", {
        "fileName": fileName,
        "fileType": type.name,
        "initialDirectory": initialDirectory,
        "allowedExtensions": allowedExtensions,
        "bytes": bytes,
      });
    }
    // For desktop platforms or others where saveFile might be handled differently or not fully supported via this specific method channel if it was separated,
    // but based on IO implementation it seems they share some logic or fallback.
    // However, FilePickerIO called `super.saveFile` (which threw Unimplemented) for non-mobile if not handled?
    // Actually FilePickerIO handled calling the channel for mobile, and super for others?
    // Let's look at FilePickerIO again. It checked Platform.isIOS || Platform.isAndroid.
    // Ideally MethodChannelFilePicker should try to invoke the method on the channel for ALL platforms that support this channel.
    // If the native side implements 'saveFile', it should work.

    // Fallback or full implementation depending on native support:
    return methodChannel.invokeMethod("saveFile", {
      "dialogTitle": dialogTitle,
      "fileName": fileName,
      "initialDirectory": initialDirectory,
      "allowedExtensions": allowedExtensions,
      "bytes": bytes,
      "lockParentWindow": lockParentWindow,
      "type": type.name,
    });
  }

  Future<FilePickerResult?> _getPath(
    FileType fileType,
    bool allowMultipleSelection,
    bool? allowCompression,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool? withData,
    bool? withReadStream,
    int? compressionQuality,
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
      await _eventSubscription?.cancel();
      if (onFileLoading != null) {
        _eventSubscription = eventChannel.receiveBroadcastStream().listen(
          (data) {
            if (data is! bool) return;
            onFileLoading(
                data ? FilePickerStatus.picking : FilePickerStatus.done);
          },
          onError: (error) => throw Exception(error),
        );
      }

      final List<Map>? result = await methodChannel.invokeListMethod(type, {
        'allowMultipleSelection': allowMultipleSelection,
        'allowedExtensions': allowedExtensions,
        'allowCompression': allowCompression,
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
            readStream: withReadStream!
                ? File(platformFileMap['path']).openRead()
                : null,
          ),
        );
      }

      return FilePickerResult(platformFiles);
    } on PlatformException catch (e) {
      print('[$_tag] Platform exception: $e');
      rethrow;
    } catch (e) {
      print(
          '[$_tag] Unsupported operation. Method not found. The exception thrown was: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>?> pickFileAndDirectoryPaths({
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    // Attempting to match MacOS implementation or generic method channel
    try {
      return await methodChannel
          .invokeListMethod<String>('pickFileAndDirectoryPaths', {
        'initialDirectory': initialDirectory,
        'allowedExtensions': allowedExtensions,
        'type': type.name,
      });
    } on MissingPluginException {
      // Fallback or return null if not supported
      return null;
    }
  }
}
