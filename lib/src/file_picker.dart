import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'file_picker_io.dart';
import 'file_picker_result.dart';

enum FileType {
  any,
  media,
  image,
  video,
  audio,
  custom,
}

enum FilePickerStatus {
  picking,
  done,
}

/// The interface that implementations of file_picker must implement.
///
/// Platform implementations should extend this class rather than implement it as `file_picker`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [FilePicker] methods.
abstract class FilePicker extends PlatformInterface {
  FilePicker() : super(token: _token);

  static final Object _token = Object();

  static FilePicker _instance = FilePickerIO();

  static FilePicker get platform => _instance;

  static set platform(FilePicker instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Retrieves the file(s) from the underlying platform
  ///
  /// Default [type] set to [FileType.any] with [allowMultiple] set to [false]
  /// Optionally, [allowedExtensions] might be provided (e.g. `[pdf, svg, jpg]`.).
  ///
  /// If [withData] is set, picked files will have its byte data immediately available on memory as [Uint8List]
  /// which can be useful if you are picking it for server upload or similar.
  ///
  /// If [withReadStream] is set, picked files will have its byte data available as a [Stream<List<int>>]
  /// which can be useful for uploading and processing large files.
  ///
  /// If you want to track picking status, for example, because some files may take some time to be
  /// cached (particularly those picked from cloud providers), you may want to set [onFileLoading] handler
  /// that will give you the current status of picking.
  ///
  /// The result is wrapped in a [FilePickerResult] which contains helper getters
  /// with useful information regarding the picked [List<PlatformFile>].
  ///
  /// Returns [null] if aborted.
  Future<FilePickerResult> pickFiles({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    Function(FilePickerStatus) onFileLoading,
    bool allowCompression,
    bool allowMultiple = false,
    bool withData,
    bool withReadStream,
  }) async =>
      throw UnimplementedError('pickFiles() has not been implemented.');

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  ///
  /// This typically relates to cached files that are stored in the cache directory of
  /// each platform and it isn't required to invoke this as the system should take care
  /// of it whenever needed. However, this will force the cleanup if you want to manage those on your own.
  ///
  /// Returns [true] if the files were removed with success, [false] otherwise.
  Future<bool> clearTemporaryFiles() async => throw UnimplementedError(
      'clearTemporaryFiles() has not been implemented.');

  /// Selects a directory and returns its absolute path.
  ///
  /// On Android, this requires to be running on SDK 21 or above, else won't work.
  /// Returns [null] if folder path couldn't be resolved.
  Future<String> getDirectoryPath() async =>
      throw UnimplementedError('getDirectoryPath() has not been implemented.');
}
