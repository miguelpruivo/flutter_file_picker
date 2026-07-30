# file_picker_linux

The Linux implementation of `file_picker`.

## Usage

This package is endorsed, which means you can simply use `file_picker` as normal, and the Linux implementation will be automatically included.

## Development

The DBus bindings in `lib/src/xdp_filechooser.dart` and `lib/src/xdp_request.dart` are generated using `dart-dbus` from the XDG Desktop Portal DBus interface specifications on Linux:

1. Install `dart-dbus` globally via Pub:
   ```bash
   dart pub global activate dbus
   ```
2. Regenerate bindings against a running DBus daemon or XML interface definition:
   ```bash
   dart-dbus generate-remote-object org.freedesktop.portal.FileChooser
   dart-dbus generate-remote-object org.freedesktop.portal.Request
   ```
