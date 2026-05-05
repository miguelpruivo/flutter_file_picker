import 'package:file_picker/src/api/android_saf_options.dart';

/// Cross-platform wrapper for all platform-specific options.
///
/// This groups all platform-specific configurations into a single object, mitigating
/// breaking changes when new options or new platforms are added.
class FilePickerOptions {
  /// Create a new [FilePickerOptions] instance.
  ///
  /// [androidOptions] specifies Android-specific configurations.
  /// [iosOptions] specifies iOS-specific configurations.
  /// [webOptions] specifies Web-specific configurations.
  /// [windowsOptions] specifies Windows-specific configurations.
  /// [macosOptions] specifies macOS-specific configurations.
  /// [linuxOptions] specifies Linux-specific configurations.
  const FilePickerOptions({
    this.androidOptions = const FilePickerAndroidOptions(),
    this.iosOptions = const FilePickerIosOptions(),
    this.webOptions = const FilePickerWebOptions(),
    this.windowsOptions = const FilePickerWindowsOptions(),
    this.macosOptions = const FilePickerMacosOptions(),
    this.linuxOptions = const FilePickerLinuxOptions(),
  });

  /// Options for Android.
  final FilePickerAndroidOptions androidOptions;

  /// Options for iOS.
  final FilePickerIosOptions iosOptions;

  /// Options for Web.
  final FilePickerWebOptions webOptions;

  /// Options for Windows.
  final FilePickerWindowsOptions windowsOptions;

  /// Options for macOS.
  final FilePickerMacosOptions macosOptions;

  /// Options for Linux.
  final FilePickerLinuxOptions linuxOptions;
}

/// Platform-specific options for Android.
class FilePickerAndroidOptions {
  const FilePickerAndroidOptions({this.safOptions});

  /// Options for the Storage Access Framework (SAF).
  final AndroidSAFOptions? safOptions;
}

/// Platform-specific options for iOS.
class FilePickerIosOptions {
  const FilePickerIosOptions();
  // Reserved for future iOS-specific options
}

/// Platform-specific options for Web.
class FilePickerWebOptions {
  const FilePickerWebOptions({
    this.readSequential = false,
    this.cancelUploadOnWindowBlur = true,
  });

  /// Whether to read files sequentially.
  ///
  /// Defaults to `false`.
  final bool readSequential;

  /// Whether to prevent upload cancellation when window focus is lost.
  ///
  /// Defaults to `true`.
  final bool cancelUploadOnWindowBlur;
}

/// Platform-specific options for Windows.
class FilePickerWindowsOptions {
  const FilePickerWindowsOptions();
}

/// Platform-specific options for macOS.
class FilePickerMacosOptions {
  const FilePickerMacosOptions();
  // Reserved for future macOS-specific options
}

/// Platform-specific options for Linux.
class FilePickerLinuxOptions {
  const FilePickerLinuxOptions();
  // Reserved for future Linux-specific options
}
