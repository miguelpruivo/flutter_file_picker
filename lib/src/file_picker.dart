import 'dart:async';

import 'package:file_picker_android/file_picker_android.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// The primary entry point for picking files and directories across platforms.
abstract final class FilePicker {
  /// Internal helper function to ease the transition and resolve backward compatibility
  /// between deprecated `androidSafOptions` and `androidOptions`.
  static AndroidOptions _resolveAndroidOptions(
    dynamic androidSafOptions,
    AndroidOptions androidOptions,
  ) {
    if (androidSafOptions != null) {
      if (androidSafOptions is AndroidSAFOptions) {
        return FilePickerAndroidOptions(safOptions: androidSafOptions);
      } else if (androidSafOptions is AndroidOptions) {
        return androidSafOptions;
      }
    }
    return androidOptions;
  }

  /// Retrieves the file(s) from the underlying platform
  static Future<List<PlatformFile>?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    @Deprecated(
      'use pickFile for single-file selection; this parameter will be removed in a future release',
    )
    bool allowMultiple = true,
    @Deprecated(
      'Use PlatformFile.readAsBytes(); this parameter will be removed in a future release',
    )
    bool withData = kIsWeb,
    @Deprecated(
      'Use PlatformFile.readAsByteStream(); this parameter will be removed in a future release',
    )
    bool withReadStream = false,
    @Deprecated(
      'Use WindowsOptions.lockParentWindow or LinuxOptions.lockParentWindow instead; this parameter will be removed in a future release.',
    )
    bool lockParentWindow = false,
    @Deprecated(
      'Use PlatformFile.readAsByteStream(); this parameter will be removed in a future release',
    )
    bool readSequential = false,
    @Deprecated(
      'Use WebOptions.cancelUploadOnWindowBlur instead; this parameter will be removed in a future release.',
    )
    bool cancelUploadOnWindowBlur = true,
    @Deprecated('Use androidOptions instead.') dynamic androidSafOptions,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final files = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
      androidOptions: _resolveAndroidOptions(androidSafOptions, androidOptions),
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );

    if (files.isEmpty) return null;
    return files;
  }

  /// Opens a native file explorer and lets the user select a single file.
  static Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    @Deprecated(
      'Use WindowsOptions.lockParentWindow or LinuxOptions.lockParentWindow instead; this parameter will be removed in a future release.',
    )
    bool lockParentWindow = false,
    @Deprecated(
      'Use WebOptions.cancelUploadOnWindowBlur instead; this parameter will be removed in a future release.',
    )
    bool cancelUploadOnWindowBlur = true,
    @Deprecated('Use androidOptions instead.') dynamic androidSafOptions,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    return FilePickerPlatform.instance.pickFile(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
      androidOptions: _resolveAndroidOptions(androidSafOptions, androidOptions),
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );
  }

  /// Displays a dialog that allows the user to select both files and
  /// directories simultaneously, returning their absolute paths.
  ///
  /// **Platform Support:** As of right now, this functionality is only
  /// supported on macOS.
  static Future<List<String>> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final paths = await FilePickerPlatform.instance.pickFileAndDirectoryPaths(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
    );
    return paths.isEmpty ? null : paths;
  }

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  static Future<void> clearTemporaryFiles() async {
    await FilePickerPlatform.instance.clearTemporaryFiles();
    return true;
  }

  /// Selects a directory and returns its absolute path.
  static Future<String?> getDirectoryPath({
    String? dialogTitle,
    @Deprecated(
      'Use WindowsOptions.lockParentWindow or LinuxOptions.lockParentWindow instead; this parameter will be removed in a future release.',
    )
    bool lockParentWindow = false,
    String? initialDirectory,
    @Deprecated('Use androidOptions instead.') dynamic androidSafOptions,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    return FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      androidOptions: _resolveAndroidOptions(androidSafOptions, androidOptions),
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );
  }

  /// Opens a save file dialog to let the user select a location and a file name to
  /// save [bytes] to.
  static Future<Uri?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
    Function(FilePickerStatus)? onFileSaving,
    @Deprecated(
      'Use WindowsOptions.lockParentWindow or LinuxOptions.lockParentWindow instead; this parameter will be removed in a future release.',
    )
    bool lockParentWindow = false,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final uri = await FilePickerPlatform.instance.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      onFileSaving: onFileSaving,
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );

    if (uri == null) return null;
    return uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
  }

  /// Deprecated entitlement check helper for legacy compatibility.
  @Deprecated(
    'Entitlements checks are handled automatically by file_picker_darwin.',
  )
  static Future<void> skipEntitlementsChecks() async {}
}
