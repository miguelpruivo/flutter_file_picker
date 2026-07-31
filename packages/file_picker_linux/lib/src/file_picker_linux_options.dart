import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

/// Configuration options specific to the Linux platform.
final class FilePickerLinuxOptions extends LinuxOptions {
  const FilePickerLinuxOptions({this.parentWindow, super.lockParentWindow});

  /// The parent window identifier (e.g. `x11:0x12345` or `wayland:...`).
  final String? parentWindow;
}
