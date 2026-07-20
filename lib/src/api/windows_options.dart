/// Configuration options specific to the Windows platform.
final class WindowsOptions {
  /// Creates a set of Windows-specific configuration options for file picker operations.
  const WindowsOptions({
    this.parentWindowHandle,
    this.lockParentWindow = false,
  });

  /// An optional Win32 window handle (`HWND`) to override the default parent
  /// window lookup when `lockParentWindow` is enabled.
  final int? parentWindowHandle;

  /// Whether the child window (file picker window) will stay in front of the
  /// Flutter window until it is closed (like a modal window).
  final bool lockParentWindow;
}
