/// The options for the Windows file picker.
class WindowsOptions {
  /// Creates an instance of [WindowsOptions].
  const WindowsOptions({this.lockParentWindow = false});

  /// Whether to lock the parent window when showing the file picker dialog.
  final bool lockParentWindow;
}
