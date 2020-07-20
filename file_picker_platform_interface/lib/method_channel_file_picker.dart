import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_picker_platform_interface.dart';

const MethodChannel _channel =
    MethodChannel('miguelruivo.flutter.plugins.filepicker');
const EventChannel _eventChannel =
    EventChannel('miguelruivo.flutter.plugins.filepickerevent');

/// An implementation of [FilePickerPlatform] that uses method channels.
class MethodChannelFilePicker extends FilePickerPlatform {
  static const String _tag = 'MethodChannelFilePicker';
  static StreamSubscription _eventSubscription;

  @override
  Future getFiles({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    bool allowMultiple = false,
    bool allowCompression = true,
    Function(FilePickerStatus) onFileLoading,
  }) =>
      _getPath(type, allowMultiple, allowCompression, allowedExtensions,
          onFileLoading);

  @override
  Future<bool> clearTemporaryFiles() async =>
      _channel.invokeMethod<bool>('clear');

  @override
  Future<String> getDirectoryPath() async {
    try {
      return await _channel.invokeMethod('dir');
    } on PlatformException catch (ex) {
      if (ex.code == "unknown_path") {
        print(
            '[$_tag] Could not resolve directory path. Maybe it\'s a protected one or unsupported (such as Downloads folder). If you are on Android, make sure that you are on SDK 21 or above.');
      }
      return null;
    }
  }

  Future<dynamic> _getPath(
    FileType fileType,
    bool allowMultipleSelection,
    bool allowCompression,
    List<String> allowedExtensions,
    Function(FilePickerStatus) onFileLoading,
  ) async {
    final String type = describeEnum(fileType);
    if (type != 'custom' && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
          'If you are using a custom extension filter, please use the FileType.custom instead.');
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

      dynamic result = await _channel.invokeMethod(type, {
        'allowMultipleSelection': allowMultipleSelection,
        'allowedExtensions': allowedExtensions,
        'allowCompression': allowCompression,
      });
      if (result != null && allowMultipleSelection) {
        if (result is String) {
          result = [result];
        }
        return Map<String, String>.fromIterable(result,
            key: (path) => path.split('/').last, value: (path) => path);
      }
      return result;
    } on PlatformException catch (e) {
      print('[$_tag] Platform exception: $e');
      rethrow;
    } catch (e) {
      print(
          '[$_tag] Unsupported operation. Method not found. The exception thrown was: $e');
      rethrow;
    }
  }
}
