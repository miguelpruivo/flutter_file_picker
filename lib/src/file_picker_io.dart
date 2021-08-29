import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final MethodChannel _channel = MethodChannel(
  'miguelruivo.flutter.plugins.filepicker',
  Platform.isLinux || Platform.isWindows || Platform.isMacOS
      ? const JSONMethodCodec()
      : const StandardMethodCodec(),
);

const EventChannel _eventChannel =
    EventChannel('miguelruivo.flutter.plugins.filepickerevent');

/// An implementation of [FilePicker] that uses method channels.
class FilePickerIO extends FilePicker {
  static const String _tag = 'MethodChannelFilePicker';
  static StreamSubscription? _eventSubscription;

  @override
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    String? dialogTitle,
    Function(FilePickerStatus)? onFileLoading,
    bool? allowCompression = true,
    bool allowMultiple = false,
    bool? withData = false,
    bool? withReadStream = false,
  }) =>
      _getPath(
        type,
        allowMultiple,
        allowCompression,
        allowedExtensions,
        onFileLoading,
        withData,
        withReadStream,
      );

  @override
  Future<bool?> clearTemporaryFiles() async =>
      _channel.invokeMethod<bool>('clear');

  @override
  Future<String?> getDirectoryPath({String? dialogTitle}) async {
    try {
      return await _channel.invokeMethod('dir', {});
    } on PlatformException catch (ex) {
      if (ex.code == "unknown_path") {
        print(
            '[$_tag] Could not resolve directory path. Maybe it\'s a protected one or unsupported (such as Downloads folder). If you are on Android, make sure that you are on SDK 21 or above.');
      }
    }
    return null;
  }

  Future<FilePickerResult?> _getPath(
    FileType fileType,
    bool allowMultipleSelection,
    bool? allowCompression,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool? withData,
    bool? withReadStream,
  ) async {
    final String type = describeEnum(fileType);
    if (type != 'custom' && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
          'You are setting a type [$fileType]. Custom extension filters are only allowed with FileType.custom, please change it or remove filters.');
    }
    try {
      _eventSubscription?.cancel();
      if (onFileLoading != null) {
        _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
              (data) => onFileLoading((data as bool)
                  ? FilePickerStatus.picking
                  : FilePickerStatus.done),
              onError: (error) => throw Exception(error),
            );
      }

      final List<Map>? result = await _channel.invokeListMethod(type, {
        'allowMultipleSelection': allowMultipleSelection,
        'allowedExtensions': allowedExtensions,
        'allowCompression': allowCompression,
        'withData': withData,
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
  Future<LostData> retrieveLostData() async {
    try {
      final Map<String, dynamic>? result =
          await _channel.invokeMapMethod<String, dynamic>('retrieve');

      if (result == null) {
        return LostData.empty();
      }

      assert(result.containsKey('filePickerResult') ^
          result.containsKey('errorCode'));

      PlatformException? exception;
      if (result.containsKey('errorCode')) {
        exception = PlatformException(
          code: result['errorCode'],
          message: result['errorMessage'],
        );
      }

      FilePickerResult? filePickerResult;
      if (result.containsKey('filePickerResult')) {
        final list = result['filePickerResult'];
        filePickerResult = FilePickerResult(
          list
              ?.map(
                  (file) => PlatformFile.fromMap(file.cast<String, dynamic>()))
              ?.toList()
              ?.cast<PlatformFile>(),
        );
      }
      return LostData(
        result: filePickerResult,
        exception: exception,
      );
    } on PlatformException catch (e) {
      print('[$_tag] Platform exception: $e');
      rethrow;
    } catch (e) {
      print('[$_tag] Unsupported operation. The exception thrown was: $e');
      rethrow;
    }
  }
}
