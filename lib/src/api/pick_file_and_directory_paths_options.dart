/// Cross-platform wrapper for platform-specific options used by
/// pickFileAndDirectoryPaths.
class PickFileAndDirectoryPathsOptions {
  /// Create a new [PickFileAndDirectoryPathsOptions] instance.
  const PickFileAndDirectoryPathsOptions({
    this.androidOptions = const PickFileAndDirectoryPathsAndroidOptions(),
    this.webOptions = const PickFileAndDirectoryPathsWebOptions(),
    this.iosOptions = const PickFileAndDirectoryPathsIosOptions(),
    this.windowsOptions = const PickFileAndDirectoryPathsWindowsOptions(),
    this.macosOptions = const PickFileAndDirectoryPathsMacosOptions(),
    this.linuxOptions = const PickFileAndDirectoryPathsLinuxOptions(),
  });

  /// Android-specific options for pickFileAndDirectoryPaths.
  final PickFileAndDirectoryPathsAndroidOptions androidOptions;

  /// Web-specific options for pickFileAndDirectoryPaths.
  final PickFileAndDirectoryPathsWebOptions webOptions;

  /// iOS-specific options for pickFileAndDirectoryPaths.
  final PickFileAndDirectoryPathsIosOptions iosOptions;

  /// Windows-specific options for pickFileAndDirectoryPaths.
  final PickFileAndDirectoryPathsWindowsOptions windowsOptions;

  /// macOS-specific options for pickFileAndDirectoryPaths.
  final PickFileAndDirectoryPathsMacosOptions macosOptions;

  /// Linux-specific options for pickFileAndDirectoryPaths.
  final PickFileAndDirectoryPathsLinuxOptions linuxOptions;
}

/// Android-specific options for pickFileAndDirectoryPaths.
class PickFileAndDirectoryPathsAndroidOptions {
  const PickFileAndDirectoryPathsAndroidOptions();
}

/// Web-specific options for pickFileAndDirectoryPaths.
class PickFileAndDirectoryPathsWebOptions {
  const PickFileAndDirectoryPathsWebOptions();
}

/// iOS-specific options for pickFileAndDirectoryPaths.
class PickFileAndDirectoryPathsIosOptions {
  const PickFileAndDirectoryPathsIosOptions();
}

/// Windows-specific options for pickFileAndDirectoryPaths.
class PickFileAndDirectoryPathsWindowsOptions {
  const PickFileAndDirectoryPathsWindowsOptions();
}

/// macOS-specific options for pickFileAndDirectoryPaths.
class PickFileAndDirectoryPathsMacosOptions {
  const PickFileAndDirectoryPathsMacosOptions();
}

/// Linux-specific options for pickFileAndDirectoryPaths.
class PickFileAndDirectoryPathsLinuxOptions {
  const PickFileAndDirectoryPathsLinuxOptions();
}
