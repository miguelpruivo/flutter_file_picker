import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/src/file_picker_result.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const String defaultDialogTitle = '';

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

  static late FilePicker _instance;

  static FilePicker get platform => _instance;

  static set platform(FilePicker instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Retrieves the file(s) from the underlying platform
  ///
  /// Default [type] set to [FileType.any] with [allowMultiple] set to `false`.
  /// Optionally, [allowedExtensions] might be provided (e.g. `[pdf, svg, jpg]`.).
  ///
  /// If [withData] is set, picked files will have its byte data immediately available on memory as `Uint8List`
  /// which can be useful if you are picking it for server upload or similar. However, have in mind that
  /// enabling this on IO (iOS & Android) may result in out of memory issues if you allow multiple picks or
  /// pick huge files. Use [withReadStream] instead. Defaults to `true` on web, `false` otherwise.
  /// Not supported on macOS.
  ///
  /// If [withReadStream] is set, picked files will have its byte data available as a [Stream<List<int>>]
  /// which can be useful for uploading and processing large files. Defaults to `false`.
  /// Not supported on macOS.
  ///
  /// If you want to track picking status, for example, because some files may take some time to be
  /// cached (particularly those picked from cloud providers), you may want to set [onFileLoading] handler
  /// that will give you the current status of picking.
  /// Not supported on macOS.
  ///
  /// If [allowCompression] is set, it will allow media to apply the default OS compression.
  /// Defaults to `false`.
  /// **Deprecated:** This option has no effect. Use [compressionQuality] instead.
  ///
  /// If [lockParentWindow] is set, the child window (file picker window) will
  /// stay in front of the Flutter window until it is closed (like a modal
  /// window). This parameter works only on Windows desktop.
  /// On macOS the parent window will be locked and this parameter is ignored.
  ///
  /// [dialogTitle] can be optionally set on desktop platforms to set the modal window title.
  /// Not supported on macOS. It will be ignored on other platforms.
  ///
  /// [initialDirectory] can be optionally set to an absolute path to specify
  /// where the dialog should open. Only supported on Linux, macOS, and Windows.
  /// On macOS the home directory shortcut (~/) is not necessary and passing it will be ignored.
  /// On macOS if the [initialDirectory] is invalid the user directory or previously valid directory
  /// will be used.
  ///
  /// [readSequential] can be optionally set on web to keep the import file order during import.
  /// Not supported on macOS.
  ///
  /// The result is wrapped in a [FilePickerResult] which contains helper getters
  /// with useful information regarding the picked [List<PlatformFile>].
  ///
  /// For more information, check the [API documentation](https://github.com/miguelpruivo/flutter_file_picker/wiki/api).
  ///
  /// Note: This requires the User Selected File Read entitlement on macOS.
  ///
  /// Returns `null` if aborted.
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated(
        'allowCompression is deprecated and has no effect. Use compressionQuality instead.')
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      throw UnimplementedError('pickFiles() has not been implemented.');

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  ///
  /// This typically relates to cached files that are stored in the cache directory of
  /// each platform and it isn't required to invoke this as the system should take care
  /// of it whenever needed. However, this will force the cleanup if you want to manage those on your own.
  ///
  /// This method is only available on mobile platforms (Android & iOS).
  ///
  /// Returns `true` if the files were removed with success, `false` otherwise.
  Future<bool?> clearTemporaryFiles() async => throw UnimplementedError(
      'clearTemporaryFiles() has not been implemented.');

  /// Selects a directory and returns its absolute path.
  ///
  /// On Android, this requires to be running on SDK 21 or above, else won't work.
  /// Note: Some Android paths are protected, hence can't be accessed and will return `/` instead.
  ///
  /// [dialogTitle] can be set to display a custom title on desktop platforms.
  /// Not supported on macOS. It will be ignored on other platforms.
  ///
  /// If [lockParentWindow] is set, the child window (file picker window) will
  /// stay in front of the Flutter window until it is closed (like a modal
  /// window). This parameter works only on Windows desktop.
  /// On macOS the parent window will be locked and this parameter is ignored.
  ///
  /// [initialDirectory] can be optionally set to an absolute path to specify
  /// where the dialog should open. Only supported on Linux, macOS, and Windows.
  /// On macOS the home directory shortcut (~/) is not necessary and passing it will be ignored.
  /// On macOS if the [initialDirectory] is invalid the user directory or previously valid directory
  /// will be used.
  ///
  /// Returns a [Future<String?>] which resolves to  the absolute path of the selected directory,
  /// if the user selected a directory. Returns `null` if the user aborted the dialog or if the
  /// folder path couldn't be resolved.
  ///
  /// Note: on Windows, throws a `WindowsException` with a detailed error message, if the dialog
  /// could not be instantiated or the dialog result could not be interpreted.
  /// Note: Some Android paths are protected, hence can't be accessed and will return `/` instead.
  /// Note: The User Selected File Read entitlement is required on macOS.
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      throw UnimplementedError('getDirectoryPath() has not been implemented.');

  /// Opens a save file dialog which lets the user select a file path and a file
  /// name to save a file.
  ///
  /// For mobile, this function will save a file with the given [fileName] and [bytes] and return the path where the file was saved.
  ///
  /// For desktop platforms, this function opens a dialog to let the user choose a location for the file and returns the selected path.
  /// If the bytes are provided, then the bytes are written to a file at the chosen path.
  ///
  /// On the web, this function will start a download for the file with [bytes] and [fileName].
  /// If the [bytes] or [fileName] are omitted, this will throw an [ArgumentError].
  /// The returned path for the downloaded file will always be `null`, as the browser handles the download.
  ///
  /// The User Selected File Read/Write entitlement is required on macOS.
  ///
  /// [dialogTitle] can be set to display a custom title on desktop platforms.
  /// Not supported on macOS.
  ///
  /// [fileName] can be set to a non-empty string to provide a default file
  /// name. Throws an `IllegalCharacterInFileNameException` under Windows if the
  /// given [fileName] contains forbidden characters.
  ///
  /// [initialDirectory] can be optionally set to an absolute path to specify
  /// where the dialog should open. Only supported on Linux, macOS, and Windows.
  /// On macOS the home directory shortcut (~/) is not necessary and passing it will be ignored.
  /// On macOS if the [initialDirectory] is invalid the user directory or previously valid directory
  /// will be used.
  ///
  /// The file type filter [type] defaults to [FileType.any]. Optionally,
  /// [allowedExtensions] might be provided (e.g. `[pdf, svg, jpg]`). Both
  /// parameters are just a proposal to the user as the save file dialog does
  /// not enforce these restrictions.
  ///
  /// If [lockParentWindow] is set, the child window (file picker window) will
  /// stay in front of the Flutter window until it is closed (like a modal
  /// window). This parameter works only on Windows desktop.
  ///
  /// Returns `null` if aborted. Returns a [Future<String?>] which resolves to
  /// the absolute path of the selected file, if the user selected a file.
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async =>
      throw UnimplementedError('saveFile() has not been implemented.');
}
