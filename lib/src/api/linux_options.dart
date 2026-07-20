/// Configuration options specific to the Linux platform.
final class LinuxOptions {
  /// Creates a set of Linux-specific configuration options for file picker operations.
  const LinuxOptions({this.lockParentWindow = false, this.parentWindow});

  /// Whether the child window (file picker) should stay in front of the parent window
  /// as a modal window until closed.
  final bool lockParentWindow;

  /// An optional X11 or Wayland parent window handle identifier.
  ///
  /// Supports full X11 handles (e.g. `"x11:0x3a00001"`), raw hex X11 strings (e.g. `"0x3a00001"`),
  /// raw decimal X11 window IDs (e.g. `"60817409"`, automatically formatted as X11 handles),
  /// or Wayland handle strings (e.g. `"wayland:handle"`).
  final String? parentWindow;
}
