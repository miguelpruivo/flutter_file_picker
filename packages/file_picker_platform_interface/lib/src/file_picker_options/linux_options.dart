import 'desktop_window_options.dart';

/// The options for the Linux file picker.
class LinuxOptions extends DesktopWindowOptions {
  /// Creates an instance of [LinuxOptions].
  const LinuxOptions({this.acceptLabel, super.lockParentWindow});

  /// The label for the accept button of the file chooser dialog.
  ///
  /// See the `accept_label` option in the [XDG Desktop Portal FileChooser docs](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.impl.portal.FileChooser.html#org-freedesktop-impl-portal-filechooser-openfile).
  final String? acceptLabel;
}
