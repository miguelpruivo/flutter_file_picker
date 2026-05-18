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

      // Cancel the event subscription before the (potentially slow) isolate
      // reads below so that no stale "done" event from the native side can
      // prematurely hide the loading indicator.
      await _eventSubscription?.cancel();
      _eventSubscription = null;

      // Build PlatformFile list.  When withData is true we read the bytes from
      // the cached file using async I/O (File.readAsBytes) instead of receiving
      // them via the method channel.  Transferring large byte arrays through
      // StandardMethodCodec serialises them on the platform thread, blocking
      // the UI for the full duration of the copy (e.g. ~2 s for a 20 MB file).
      // Dart's async file I/O is non-blocking and does not stall the rasterizer.
      // Files are processed sequentially to avoid saturating memory/IO when
      // multiple large files are selected at once.
      final List<PlatformFile> platformFiles = [];
      for (final Map platformFileMap in result) {
        final String? path = platformFileMap['path'] as String?;

        // Bytes that arrive over the channel (legacy / non-Android paths).
        Uint8List? bytes = platformFileMap['bytes'] as Uint8List?;

        // If the native side omitted bytes but we need them and have a path,
        // read them in a worker isolate via FilePickerUtils.readBytesFromFile.
        // Using compute() (which powers readBytesFromFile) sends only the
        // primitive String path across the isolate boundary — no closures,
        // no widget-tree references — and keeps the main isolate's heap free
        // from a large allocation that would stall the rasterizer.
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
    String? fileName,
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
        // Listen only for intermediate "picking" state updates from the native
        // side.  We handle the final "done" ourselves after the invoke returns,
        // so we filter out the false (done) events to avoid a premature hide of
        // the loading indicator while the native side is still writing bytes.
        _eventSubscription = eventChannel.receiveBroadcastStream().listen((
          data,
        ) {
          if (data is! bool) return;
          if (data) {
            onFileLoading(FilePickerStatus.picking);
          }
          // Intentionally ignore the native "done" (false) event here – we
          // call onFileLoading(done) below once the full operation has finished.
        }, onError: (error) => throw Exception(error));
      }

      // On Android & iOS the native side writes the bytes via the platform's
      // content resolver / document picker (which handles SAF URIs correctly).
      // We therefore send the bytes to the native layer so it can write them,
      // and we must NOT call saveBytesToFile here – the path returned by the
      // native side is a SAF/document URI path, not a real filesystem path.
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
