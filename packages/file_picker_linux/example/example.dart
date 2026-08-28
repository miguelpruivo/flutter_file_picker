// An example demonstrating the usage of file_picker_linux.
import 'dart:io' show Process, pid;

import 'package:file_picker_linux/file_picker_linux.dart';

void main() async {
  FilePickerLinux.registerWith();

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

/// Resolves the window identifier the portal needs in order to parent the
/// dialog, by looking for an X window that belongs to *this* process.
///
/// Flutter exposes no API for the native window handle, so it has to come from
/// elsewhere. Under X11, including XWayland, that is the window XID.
///
/// `xdotool getactivewindow` is the obvious call here and it is wrong: with
/// XWayland running it happily returns the focused *X* window, which on a
/// Wayland session belongs to some other application entirely. Searching by pid
/// returns nothing when this process has no X window, which is the correct
/// answer on a native Wayland session.
///
/// Shelling out to `xdotool` is not something a shipped app should do. It is
/// here because it is currently the only way to demonstrate the option.
Future<String?> resolveParentWindow() async {
  try {
    final result = await Process.run('xdotool', [
      'search',
      '--pid',
      '$pid',
      '--onlyvisible',
    ]);
    final ids = (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return ids.isEmpty ? null : ids.last; // e.g. 25165834
  } catch (_) {
    return null;
  }
}
