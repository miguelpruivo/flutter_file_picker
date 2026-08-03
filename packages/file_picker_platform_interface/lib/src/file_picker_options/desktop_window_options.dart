/// Configuration options common to desktop platforms (e.g. Linux and Windows).
abstract class DesktopWindowOptions {
  /// Creates an instance of [DesktopWindowOptions].
  const DesktopWindowOptions({this.lockParentWindow = false});

  /// Whether to lock the parent window modally when showing the file picker dialog.
  final bool lockParentWindow;
}
