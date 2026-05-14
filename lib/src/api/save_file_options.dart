/// Cross-platform wrapper for platform-specific options used by saveFile.
class SaveFileOptions {
  /// Create a new [SaveFileOptions] instance.
  const SaveFileOptions({
    this.androidOptions = const SaveFileAndroidOptions(),
    this.webOptions = const SaveFileWebOptions(),
    this.iosOptions = const SaveFileIosOptions(),
    this.windowsOptions = const SaveFileWindowsOptions(),
    this.macosOptions = const SaveFileMacosOptions(),
    this.linuxOptions = const SaveFileLinuxOptions(),
  });

  /// Android-specific options for saveFile.
  final SaveFileAndroidOptions androidOptions;

  /// Web-specific options for saveFile.
  final SaveFileWebOptions webOptions;

  /// iOS-specific options for saveFile.
  final SaveFileIosOptions iosOptions;

  /// Windows-specific options for saveFile.
  final SaveFileWindowsOptions windowsOptions;

  /// macOS-specific options for saveFile.
  final SaveFileMacosOptions macosOptions;

  /// Linux-specific options for saveFile.
  final SaveFileLinuxOptions linuxOptions;
}

/// Android-specific options for saveFile.
class SaveFileAndroidOptions {
  const SaveFileAndroidOptions();
}

/// Web-specific options for saveFile.
class SaveFileWebOptions {
  const SaveFileWebOptions();
}

/// iOS-specific options for saveFile.
class SaveFileIosOptions {
  const SaveFileIosOptions();
}

/// Windows-specific options for saveFile.
class SaveFileWindowsOptions {
  const SaveFileWindowsOptions();
}

/// macOS-specific options for saveFile.
class SaveFileMacosOptions {
  const SaveFileMacosOptions();
}

/// Linux-specific options for saveFile.
class SaveFileLinuxOptions {
  const SaveFileLinuxOptions();
}
