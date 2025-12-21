import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/src/api/file_picker_result.dart';
import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:file_picker/src/platform/file_picker_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of file_picker must implement.
///
/// Platform implementations should extend this class rather than implement it as `file_picker`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [FilePickerPlatform] methods.
abstract class FilePickerPlatform extends PlatformInterface {
  FilePickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FilePickerPlatform _instance = MethodChannelFilePicker();

  static FilePickerPlatform get instance => _instance;

  static set instance(FilePickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Retrieves the file(s) from the underlying platform
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    throw UnimplementedError('pickFiles() has not been implemented.');
  }

  /// Displays a dialog that allows the user to select both files and
  /// directories simultaneously, returning their absolute paths.
  Future<List<String>?> pickFileAndDirectoryPaths({
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    throw UnimplementedError(
        'pickFileAndDirectoryPaths() has not been implemented.');
  }

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  Future<bool?> clearTemporaryFiles() async {
    throw UnimplementedError('clearTemporaryFiles() has not been implemented.');
  }

  /// Selects a directory and returns its absolute path.
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    throw UnimplementedError('getDirectoryPath() has not been implemented.');
  }

  /// Opens a save file dialog which lets the user select a file path and a file
  /// name to save a file.
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    throw UnimplementedError('saveFile() has not been implemented.');
  }
}
