import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  /// Pick a single file using the native file picker.
  ///
  /// The [dialogTitle], if provided, will be used as title for the picker dialog.
  /// The [initialDirectory], if provided, will be used as the path for the initial directory of the file picker.
  /// The [type] parameter specifies the type of file to be picked and defaults to [FileType.any].
  /// The [allowedExtensions] parameter, if provided,
  /// will restrict the file picker to allow only files with the specified extensions,
  /// and defaults to allowing all files.
  /// The [onFileLoading] callback, if provided, will be called when the file picker is loading the selected file.
  /// The [compressionQuality] parameter specifies the compression quality, in percent, to compress the picked file.
  ///
  /// The [androidOptions], [windowsOptions], [linuxOptions],
  /// and [webOptions] parameters allow for platform-specific configurations when configuring the file picker.
  /// See their respective classes for more details on the available options.
  ///
  /// Returns the [PlatformFile] containing the selected file, or `null` if the user cancels the operation.
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    throw UnimplementedError('pickFile() has not been implemented.');
  }

  /// Pick multiple files using the native file picker.
  ///
  /// The [dialogTitle], if provided, will be used as title for the picker dialog.
  /// The [initialDirectory], if provided, will be used as the path for the initial directory of the file picker.
  /// The [type] parameter specifies the type of files to be picked and defaults to [FileType.any].
  /// The [allowedExtensions] parameter, if provided,
  /// will restrict the file picker to allow only files with the specified extensions,
  /// and defaults to allowing all files.
  /// The [onFileLoading] callback, if provided, will be called when the file picker is loading the selected files.
  /// The [compressionQuality] parameter specifies the compression quality, in percent, to compress the picked files.
  ///
  /// The [androidOptions], [windowsOptions], [linuxOptions],
  /// and [webOptions] parameters allow for platform-specific configurations when configuring the file picker.
  /// See their respective classes for more details on the available options.
  ///
  /// Returns the [FilePickerResult] containing the selected files, if any.
  /// The result may contain no files if the user cancels the operation.
  Future<FilePickerResult> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    throw UnimplementedError('pickFiles() has not been implemented.');
  }
}
