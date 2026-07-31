/// The options for the Linux file picker.
class LinuxOptions {
  /// Creates an instance of [LinuxOptions].
  const LinuxOptions({this.lockParentWindow = false});

  /// Whether to lock the parent window when showing the file picker dialog.
  final bool lockParentWindow;
}
