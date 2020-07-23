import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_file_picker.dart';

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
/// [FilePickerPlatform] methods.
abstract class FilePickerPlatform extends PlatformInterface {
  /// Constructs a UrlLauncherPlatform.
  FilePickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FilePickerPlatform _instance = MethodChannelFilePicker();

  static FilePickerPlatform get instance => _instance;

  static set instance(FilePickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Retrieves the file(s) from the underlying platform
  ///
  /// Default [type] set to `FileType.any` with [allowMultiple] set to `false`
  /// Optionally, [allowedExtensions] might be provided (e.g. [`pdf`, `svg`, `jpg`].).
  ///
  /// If you want to track picking status, for example, because some files may take some time to be
  /// cached (particularly those picked from cloud providers), you may want to set [onFileLoading] handler
  /// that will give you the current status of picking.
  ///
  /// Allows `dynamic` return as files may be resolved to different types, based
  /// on each platform implementation. For example, when using _dart:html_ with Flutter Web
  /// or _dart:io_ with Flutter, different `File` instances could be used.
  Future<dynamic> getFiles({
    FileType type = FileType.any,
    List<String> allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus) onFileLoading,
  }) async =>
      throw UnimplementedError('getFiles() has not been implemented.');

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  ///
  /// This typically relates to cached files that are stored in the cache directory of
  /// each platform and it isn't required to invoke this as the system should take care
  /// of it whenever needed. However, this will force the cleanup if you want to manage those on your own.
  ///
  /// Returns `true` if the files were removed with success, `false` otherwise.
  Future<bool> clearTemporaryFiles() async => throw UnimplementedError(
      'clearTemporaryFiles() has not been implemented.');

  /// Selects a directory and returns its absolute path.
  ///
  /// On Android, this requires to be running on SDK 21 or above, else won't work.
  /// Returns `null` if folder path couldn't be resolved.
  Future<String> getDirectoryPath() async =>
      throw UnimplementedError('getDirectoryPath() has not been implemented.');
}
