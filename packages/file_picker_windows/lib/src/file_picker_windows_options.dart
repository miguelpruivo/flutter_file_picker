import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

/// Configuration options specific to the Windows platform.
final class FilePickerWindowsOptions extends WindowsOptions {
  const FilePickerWindowsOptions({
    this.parentWindowHandle,
    this.lockParentWindow = false,
  });

  /// The HWND handle of the parent window.
  final int? parentWindowHandle;

  /// Whether to lock the parent window modally.
  final bool lockParentWindow;
}
