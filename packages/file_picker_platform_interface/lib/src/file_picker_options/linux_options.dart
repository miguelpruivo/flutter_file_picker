import 'desktop_window_options.dart';

/// The options for the Linux file picker.
class LinuxOptions extends DesktopWindowOptions {
  /// Creates an instance of [LinuxOptions].
  const LinuxOptions({this.acceptLabel, super.lockParentWindow});

  final String? acceptLabel;
}
