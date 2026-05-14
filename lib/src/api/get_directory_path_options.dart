import 'package:file_picker/src/api/android_saf_options.dart';

/// Cross-platform wrapper for platform-specific options used by
/// `FilePicker.getDirectoryPath`.
///
/// This model follows the same pattern as other method-specific options models
/// in the package (for example, `PickFilesOptions` for
/// `FilePicker.pickFiles`).
///
/// Keeping a dedicated options object per API method helps avoid frequent
/// breaking changes when new platform settings are introduced.
///
/// Most platform option models are intentionally empty for now and act as
/// extension points for future settings.
class GetDirectoryPathOptions {
  /// Create a new [GetDirectoryPathOptions] instance.
  ///
  /// All parameters default to empty platform option objects.
  ///
  /// Example:
  /// ```dart
  /// final options = GetDirectoryPathOptions(
  ///   androidOptions: GetDirectoryPathAndroidOptions(
  ///     safOptions: AndroidSAFOptions(
  ///       grant: AndroidSAFGrant.lifetime,
  ///       accessMode: AndroidSAFAccessMode.readWrite,
  ///     ),
  ///   ),
  /// );
  /// ```
  const GetDirectoryPathOptions({
    this.androidOptions = const GetDirectoryPathAndroidOptions(),
    this.webOptions = const GetDirectoryPathWebOptions(),
    this.iosOptions = const GetDirectoryPathIosOptions(),
    this.windowsOptions = const GetDirectoryPathWindowsOptions(),
    this.macosOptions = const GetDirectoryPathMacosOptions(),
    this.linuxOptions = const GetDirectoryPathLinuxOptions(),
  });

  /// Android-specific options for `FilePicker.getDirectoryPath`.
  ///
  /// This is currently where Storage Access Framework (SAF) behavior is
  /// configured.
  final GetDirectoryPathAndroidOptions androidOptions;

  /// Web-specific options for `FilePicker.getDirectoryPath`.
  ///
  /// Reserved for future options.
  final GetDirectoryPathWebOptions webOptions;

  /// iOS-specific options for `FilePicker.getDirectoryPath`.
  ///
  /// Reserved for future options.
  final GetDirectoryPathIosOptions iosOptions;

  /// Windows-specific options for `FilePicker.getDirectoryPath`.
  ///
  /// Reserved for future options.
  final GetDirectoryPathWindowsOptions windowsOptions;

  /// macOS-specific options for `FilePicker.getDirectoryPath`.
  ///
  /// Reserved for future options.
  final GetDirectoryPathMacosOptions macosOptions;

  /// Linux-specific options for `FilePicker.getDirectoryPath`.
  ///
  /// Reserved for future options.
  final GetDirectoryPathLinuxOptions linuxOptions;
}

/// Android-specific options for `FilePicker.getDirectoryPath`.
///
/// These options are only applied when running on Android. Other platforms
/// ignore them.
class GetDirectoryPathAndroidOptions {
  const GetDirectoryPathAndroidOptions({this.safOptions});

  /// Storage Access Framework (SAF) options used when requesting a directory.
  ///
  /// When set, Android can return a `content://` document tree URI instead of
  /// an absolute filesystem path, depending on the selected location and SAF
  /// mode.
  final AndroidSAFOptions? safOptions;
}

/// Web-specific options for `FilePicker.getDirectoryPath`.
///
/// Reserved for future options.
class GetDirectoryPathWebOptions {
  const GetDirectoryPathWebOptions();
}

/// iOS-specific options for `FilePicker.getDirectoryPath`.
///
/// Reserved for future options.
class GetDirectoryPathIosOptions {
  const GetDirectoryPathIosOptions();
}

/// Windows-specific options for `FilePicker.getDirectoryPath`.
///
/// Reserved for future options.
class GetDirectoryPathWindowsOptions {
  const GetDirectoryPathWindowsOptions();
}

/// macOS-specific options for `FilePicker.getDirectoryPath`.
///
/// Reserved for future options.
class GetDirectoryPathMacosOptions {
  const GetDirectoryPathMacosOptions();
}

/// Linux-specific options for `FilePicker.getDirectoryPath`.
///
/// Reserved for future options.
class GetDirectoryPathLinuxOptions {
  const GetDirectoryPathLinuxOptions();
}
