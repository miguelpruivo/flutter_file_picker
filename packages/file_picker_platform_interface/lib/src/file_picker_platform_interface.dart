import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'enums/file_picker_status.dart';
import 'enums/file_type.dart';
import 'file_picker_options/android_options.dart';
import 'file_picker_options/linux_options.dart';
import 'file_picker_options/web_options.dart';
import 'file_picker_options/windows_options.dart';
import 'platform_file.dart';

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
  /// Returns a list of [PlatformFile] containing the selected files, if any.
  /// The list may be empty if the user cancels the operation.
  Future<List<PlatformFile>> pickFiles({
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

  /// Pick files and directories using the native file picker.
  ///
  /// The [dialogTitle], if provided, will be used as title for the picker dialog.
  /// The [initialDirectory], if provided, will be used as the path for the initial directory of the file picker.
  /// The [type] parameter specifies the type of files to be picked and defaults to [FileType.any].
  /// The [allowedExtensions] parameter, if provided,
  /// will restrict the file picker to allow only files with the specified extensions,
  /// and defaults to allowing all files.
  ///
  /// Returns a list of absolute paths for the selected files and directories, if any.
  /// The resulting list will be empty if the user cancels the operation.
  Future<List<String>> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    throw UnimplementedError('pickFileAndDirectoryPaths() has not been implemented.');
  }

  /// Pick a single directory using the native file picker.
  ///
  /// The [dialogTitle], if provided, will be used as title for the picker dialog.
  /// The [initialDirectory], if provided, will be used as the path for the initial directory of the directory picker.
  ///
  /// The [androidOptions], [windowsOptions], [linuxOptions],
  /// and [webOptions] parameters allow for platform-specific configurations when configuring the directory picker.
  /// See their respective classes for more details on the available options.
  ///
  /// Returns the absolute path of the selected directory, or `null` if the user cancels the operation.
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    throw UnimplementedError('getDirectoryPath() has not been implemented.');
  }

  /// Clear the temporary files created by the underlying file picker.
  Future<void> clearTemporaryFiles() async {
    throw UnimplementedError('clearTemporaryFiles() has not been implemented.');
  }

  /// Save the given [bytes] to a file with the given [fileName], using the native save file dialog.
  ///
  /// The [fileName] should include the file extension, e.g. `myFile.txt`.
  /// The [mimeType] should be a valid MIME type for the file, e.g. `text/plain`.
  /// The [dialogTitle], if provided, will be used as title for the save file dialog.
  /// The [initialDirectory], if provided, will be used as the path for the initial directory of the save file dialog.
  /// The [onFileSaving] callback, if provided, will be called when the save file dialog is saving the file.
  ///
  /// The [windowsOptions], [linuxOptions], and [webOptions] parameters
  /// allow for platform-specific configurations when configuring the save file dialog.
  /// See their respective classes for more details on the available options.
  ///
  /// Returns the [Uri] of the saved file, or null if the user cancels the operation.
  /// Depending on the platform, the [Uri.scheme] may be `file`, `content`, `http(s)`, `data` or `blob`.
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    throw UnimplementedError('saveFile() has not been implemented.');
  }
}
