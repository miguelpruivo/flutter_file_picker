import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/api/android_options.dart';
import 'src/api/file_picker_result.dart';
import 'src/api/file_picker_types.dart';
import 'src/api/linux_options.dart';
import 'src/api/web_options.dart';
import 'src/api/windows_options.dart';
import 'src/method_channel/file_picker_method_channel.dart';

export 'src/api/android_options.dart';
export 'src/api/android_saf_handle.dart';
export 'src/api/exceptions.dart';
export 'src/api/file_picker_result.dart';
export 'src/api/file_picker_types.dart';
export 'src/api/linux_options.dart';
export 'src/api/platform_file.dart';
export 'src/api/web_options.dart';
export 'src/api/windows_options.dart';
export 'src/method_channel/file_picker_method_channel.dart';
export 'src/utils/file_picker_utils.dart';

/// The interface that implementations of file_picker must implement.
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
    bool cancelUploadOnWindowBlur = true,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    throw UnimplementedError('pickFiles() has not been implemented.');
  }

  /// Displays a dialog that allows the user to select both files and
  /// directories simultaneously, returning their absolute paths.
  Future<List<String>?> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    throw UnimplementedError(
      'pickFileAndDirectoryPaths() has not been implemented.',
    );
  }

  /// Releases the given SAF grant.
  Future<void> releaseSAFGrant(String uri) async {
    throw UnimplementedError('releaseSAFGrant() has not been implemented.');
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
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    throw UnimplementedError('getDirectoryPath() has not been implemented.');
  }

  /// Opens a save file dialog which lets the user select a file path and a file
  /// name to save a file.
  Future<String?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    required Uint8List bytes,
    Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    throw UnimplementedError('saveFile() has not been implemented.');
  }

  Future<void> skipEntitlementsChecks() async {
    // By default, do nothing.
    // This is only relevant for macOS, and the method is overridden there.
  }
}
