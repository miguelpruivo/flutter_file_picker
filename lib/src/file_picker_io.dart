import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  static void registerWith() {
    FilePicker.platform = FilePickerIO();
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
    @Deprecated(
        'allowCompression is deprecated and has no effect. Use compressionQuality instead.')
    bool? allowCompression = false,
    bool allowMultiple = false,
    bool? withData = false,
    int compressionQuality = 0,
    bool? withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) =>
      _getPath(
        type,
        allowMultiple,
        allowCompression,
        allowedExtensions,
        onFileLoading,
        withData,
        withReadStream,
        compressionQuality,
      );

  @override
  Future<bool?> clearTemporaryFiles() async =>
      _channel.invokeMethod<bool>('clear');

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
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
      _eventSubscription?.cancel();
      if (onFileLoading != null) {
        _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
              (data) => onFileLoading((data is bool)
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
  Future<String?> saveFile(
      {String? dialogTitle,
      String? fileName,
      String? initialDirectory,
      FileType type = FileType.any,
      List<String>? allowedExtensions,
      Uint8List? bytes,
      bool lockParentWindow = false}) {
    if (Platform.isIOS || Platform.isAndroid) {
      if (bytes == null) {
        throw ArgumentError(
            'Bytes are required on Android & iOS when saving a file.');
      }

      return _channel.invokeMethod("save", {
        "fileName": fileName,
        "fileType": type.name,
        "initialDirectory": initialDirectory,
        "allowedExtensions": allowedExtensions,
        "bytes": bytes,
      });
    }
    return super.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
      lockParentWindow: lockParentWindow,
    );
  }
}
