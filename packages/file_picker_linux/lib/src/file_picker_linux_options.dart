import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

/// Configuration options specific to the Linux platform.
final class FilePickerLinuxOptions extends LinuxOptions {
  const FilePickerLinuxOptions({
    this.parentWindow,
    this.lockParentWindow = false,
  });

  /// The parent window identifier (e.g. `x11:0x12345` or `wayland:...`).
  final String? parentWindow;

  /// Whether to lock the parent window modally.
  final bool lockParentWindow;
}
