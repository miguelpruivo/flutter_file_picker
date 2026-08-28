// An example demonstrating the usage of file_picker_linux.
import 'dart:io' show Process;

import 'package:file_picker_linux/file_picker_linux.dart';

void main() async {
  FilePickerLinux.registerWith();
  print('Registered file_picker_linux implementation.');

  final picker = FilePickerLinux();

  // `lockParentWindow` reaches the XDG portal as `modal`, but the portal also
  // needs to know which window to be modal against. Without `parentWindow` the
  // dialog is left unparented and nothing appears to be locked.
  final file = await picker.pickFile(
    dialogTitle: 'Pick a file',
    linuxOptions: FilePickerLinuxOptions(
      acceptLabel: 'Choose',
      lockParentWindow: true,
      parentWindow: await resolveParentWindow(),
    ),
  );

  print('Picked: ${file?.path}');
}

/// Resolves the window identifier the portal needs to parent the dialog.
///
/// Flutter exposes no API for the native window handle, so it has to come from
/// elsewhere. Under X11, including XWayland, that is the window XID, which
/// `xdotool` can report. A native Wayland session needs an `xdg_foreign`
/// exported handle instead, which cannot be obtained this way, so this returns
/// null there and the dialog stays unparented.
///
/// Shelling out to `xdotool` is not something a shipped app should do. It is
/// here because it is currently the only way to demonstrate the option.
Future<String?> resolveParentWindow() async {
  try {
    final result = await Process.run('xdotool', ['getactivewindow']);
    final xid = (result.stdout as String).trim(); // e.g. 25165834
    return xid.isEmpty ? null : xid;
  } catch (_) {
    return null;
  }
}
