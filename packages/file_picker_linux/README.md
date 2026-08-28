# file_picker_linux

The Linux implementation of `file_picker`.

## Usage

This package is endorsed, which means you can simply use `file_picker` as normal, and the Linux implementation will be automatically included.

## Linux specific options

Pass `LinuxOptions` for the options shared with other desktop platforms, or
`FilePickerLinuxOptions` when you also need `parentWindow`.

```dart
final file = await FilePicker.pickFile(
  linuxOptions: const FilePickerLinuxOptions(
    acceptLabel: 'Choose',
    lockParentWindow: true,
    parentWindow: 'x11:0x1c00007',
  ),
);
```

### `acceptLabel`

Replaces the text on the dialog's confirmation button. Only applies to file
picking (`pickFile`, `pickFiles`), the portal does not take it for directory
selection or saving.

### `lockParentWindow`

Sent to the portal as `modal`. On its own it has no visible effect: the portal
needs to know *which* window to be modal against, so it only locks the parent
once `parentWindow` is also set.

### `parentWindow`

The window identifier handed to the portal so it can parent the dialog. Accepted
forms:

| You pass | Sent as |
| --- | --- |
| `x11:0x1c00007` | unchanged |
| `wayland:<handle>` | unchanged |
| `0x1c00007` | `x11:0x1c00007` |
| `29360135` (decimal) | `x11:0x1c00007` |
| `null` or empty | no parent window |

Flutter does not expose the native window handle, so you have to obtain it
yourself. Under X11 that is the window XID. Under Wayland it is an
[`xdg_foreign`](https://wayland.app/protocols/xdg-foreign-unstable-v2) exported
handle, which is considerably harder to get, so on Wayland sessions the dialog
is usually left unparented.

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
