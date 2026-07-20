import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:file_picker/src/api/file_picker_result.dart';
import 'package:file_picker/src/api/platform_file.dart';
import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:file_picker/src/api/android_saf_options.dart';
import 'package:file_picker/src/api/windows_options.dart';
import 'package:file_picker/src/api/linux_options.dart';
import 'package:file_picker/src/api/web_options.dart';

abstract final class FilePicker {
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
  /// If [lockParentWindow] is set, the child window (file picker window) will
  /// stay in front of the Flutter window until it is closed (like a modal
  /// window). This parameter is deprecated; use [WindowsOptions.lockParentWindow] or
  /// [LinuxOptions.lockParentWindow] instead.
  ///
  /// [dialogTitle] can be optionally set on desktop platforms to set the modal window title.
  /// Not supported on macOS. It will be ignored on other platforms.
  ///
  /// [initialDirectory] can be optionally set to an absolute path to specify
  /// where the dialog should open. Only supported on Linux, macOS, and Windows.
  /// On macOS the home directory shortcut (~/) is not necessary and passing it will be ignored.
  /// On macOS if the [initialDirectory] is invalid, the user directory or previously valid directory
  /// will be used.
  ///
  /// [readSequential] can be optionally set on web to keep the import file order during import.
  /// Not supported on macOS.
  ///
  /// [cancelUploadOnWindowBlur] prevents upload cancellation when window focus is lost.
  /// This parameter is deprecated; use [WebOptions.cancelUploadOnWindowBlur] instead.
  ///
  /// [windowsOptions] can be optionally set to configure Windows-specific options.
  ///
  /// [linuxOptions] can be optionally set to configure Linux-specific options.
  ///
  /// [webOptions] can be optionally set to configure Web-specific options.
  ///
  /// The result is wrapped in a [FilePickerResult] which contains helper getters
  /// with useful information regarding the picked [List<PlatformFile>].
  ///
  /// For more information, check the [API documentation](https://github.com/miguelpruivo/flutter_file_picker/wiki/api).
  ///
  /// Note: This requires the User Selected File Read entitlement on macOS.
  ///
  /// Returns `null` if aborted.
  /// selection; `pickFiles` now implies multiple selection by default.
  /// NOTE: `withData`, `withReadStream` and `readSequential` are deprecated.
  /// Call `PlatformFile.readAsBytes()` or `PlatformFile.readAsByteStream()` on
  /// the returned `PlatformFile` to load data on demand. These parameters
  /// will be removed in a future release.
  static Future<FilePickerResult?> pickFiles({
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
    AndroidSAFOptions? androidSafOptions,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    return FilePickerPlatform.instance.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
      allowMultiple: allowMultiple,
      withData: withData,
      withReadStream: withReadStream,
      lockParentWindow: lockParentWindow,
      readSequential: readSequential,
      cancelUploadOnWindowBlur: cancelUploadOnWindowBlur,
      androidSafOptions: androidSafOptions,
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );
  }

  /// Opens a native file explorer and lets the user select a single file.
  ///
  /// This is a convenience wrapper around [pickFiles] for when you only need to
  /// pick one file. It returns a [PlatformFile] directly, or `null` if the
  /// user canceled the operation.
  ///
  /// For documentation on the parameters, see [pickFiles].
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
    AndroidSAFOptions? androidSafOptions,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final result = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
      allowMultiple: false,
      withData: false,
      withReadStream: false,
      lockParentWindow: lockParentWindow,
      readSequential: false,
      cancelUploadOnWindowBlur: cancelUploadOnWindowBlur,
      androidSafOptions: androidSafOptions,
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );

    return result?.files.firstOrNull;
  }

  /// Displays a dialog that allows the user to select both files and
  /// directories simultaneously, returning their absolute paths.
  ///
  /// **Platform Support:** As of right now, this functionality is only
  /// supported on macOS.
  ///
  /// [initialDirectory] can be optionally set to an absolute path to specify
  /// where the dialog should open. On macOS the home directory shortcut (~/) is
  /// not necessary and passing it will be ignored. On macOS if the
  /// [initialDirectory] is invalid the user directory or previously valid
  /// directory will be used.
  ///
  /// The file type filter [type] defaults to [FileType.any]. Optionally,
  /// [allowedExtensions] might be provided (e.g. `["pdf", "svg", "jpg"]`).
  ///
  /// Returns a [Future<List<String>?>] that resolves to a list of absolute
  /// paths for the selected files and directories. If the user cancels the
  /// dialog or if the paths cannot be resolved, the method returns `null`.
  static Future<List<String>?> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) {
    return FilePickerPlatform.instance.pickFileAndDirectoryPaths(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
    );
  }

  /// Asks the underlying platform to remove any temporary files created by this plugin.
  ///
  /// This typically relates to cached files that are stored in the cache directory of
  /// each platform and it isn't required to invoke this as the system should take care
  /// of it whenever needed. However, this will force the cleanup if you want to manage those on your own.
  ///
  /// This method is only available on mobile platforms (Android & iOS).
  ///
  /// Returns `true` if the files were removed with success, `false` otherwise.
  static Future<bool?> clearTemporaryFiles() {
    return FilePickerPlatform.instance.clearTemporaryFiles();
  }

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
  /// window). This parameter is deprecated; use [WindowsOptions.lockParentWindow] or
  /// [LinuxOptions.lockParentWindow] instead.
  ///
  /// [initialDirectory] can be optionally set to an absolute path to specify
  /// where the dialog should open. Only supported on Linux, macOS, and Windows.
  /// On macOS the home directory shortcut (~/) is not necessary and passing it will be ignored.
  /// On macOS if the [initialDirectory] is invalid, the user directory or previously valid directory
  /// will be used.
  ///
  /// [windowsOptions] can be optionally set to configure Windows-specific options.
  ///
  /// [linuxOptions] can be optionally set to configure Linux-specific options.
  ///
  /// [webOptions] can be optionally set to configure Web-specific options.
  ///
  /// Returns a [Future<String?>] which resolves to the absolute path of the selected directory,
  /// if the user selected a directory. Returns `null` if the user aborted the dialog or if the
  /// folder path couldn't be resolved.
  ///
  /// Note: on Windows, throws a `WindowsException` with a detailed error message, if the dialog
  /// could not be instantiated or the dialog result could not be interpreted.
  /// Note: Some Android paths are protected, hence can't be accessed and will return `/` instead.
  /// Note: The User Selected File Read entitlement is required on macOS.
  /// Note: On Android, if [androidSafOptions] is provided, the returned string will be a
  /// `content://` document tree URI instead of an absolute path.
  static Future<String?> getDirectoryPath({
    String? dialogTitle,
    @Deprecated(
      'Use WindowsOptions.lockParentWindow or LinuxOptions.lockParentWindow instead; this parameter will be removed in a future release.',
    )
    bool lockParentWindow = false,
    String? initialDirectory,
    AndroidSAFOptions? androidSafOptions,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    return FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: dialogTitle,
      lockParentWindow: lockParentWindow,
      initialDirectory: initialDirectory,
      androidSafOptions: androidSafOptions,
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );
  }

  /// Opens a save file dialog to let the user select a location and a file name to
  /// save [bytes] to.
  ///
  /// Returns a [Future<String?>] which resolves to the absolute path of the
  /// saved file, or `null` if the user canceled the operation.
  ///
  /// On the web, this starts a download and always returns `null`.
  ///
  /// The User Selected File Read/Write entitlement is required on macOS.
  ///
  /// [dialogTitle] can be set to display a custom title on desktop platforms.
  /// Not supported on macOS.
  ///
  /// [fileName] should be set to provide a default file name.
  /// Throws an `IllegalCharacterInFileNameException` under Windows if the
  /// given [fileName] contains forbidden characters.
  ///
  /// [initialDirectory] can be optionally set to an absolute path to specify
  /// where the dialog should open. Only supported on Linux, macOS, and Windows.
  /// On macOS the home directory shortcut (~/) is not necessary and passing it will be ignored.
  /// On macOS if the [initialDirectory] is invalid, the user directory or previously valid directory
  /// will be used.
  ///
  /// The file type filter [type] defaults to [FileType.any]. Optionally,
  /// [allowedExtensions] might be provided (e.g. `[pdf, svg, jpg]`). Both
  /// parameters are just a proposal to the user as the save file dialog does
  /// not enforce these restrictions.
  ///
  /// If [lockParentWindow] is set, the child window (file picker window) will
  /// stay in front of the Flutter window until it is closed (like a modal
  /// window). This parameter is deprecated; use [WindowsOptions.lockParentWindow] or
  /// [LinuxOptions.lockParentWindow] instead.
  ///
  /// [windowsOptions] can be optionally set to configure Windows-specific options.
  ///
  /// [linuxOptions] can be optionally set to configure Linux-specific options.
  ///
  /// [webOptions] can be optionally set to configure Web-specific options.
  ///
  /// Returns `null` if aborted.
  static Future<String?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    required Uint8List bytes,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated(
      'Use WindowsOptions.lockParentWindow or LinuxOptions.lockParentWindow instead; this parameter will be removed in a future release.',
    )
    bool lockParentWindow = false,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    return FilePickerPlatform.instance.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
      onFileLoading: onFileLoading,
      lockParentWindow: lockParentWindow,
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions,
    );
  }

  /// Skips the entitlements checks on macOS, allowing the plugin to be used without Sandbox enabled.
  ///
  /// This is only relevant for macOS. On other platforms, this method does nothing.
  /// Call this method before any other file picking method to ensure that the entitlements checks are skipped.
  ///
  /// Note: Skipping entitlements checks may lead to unexpected behavior or security issues. Use with caution.
  static Future<void> skipEntitlementsChecks() {
    return FilePickerPlatform.instance.skipEntitlementsChecks();
  }
}
