## 1.0.2

- Fixed `LinuxOptions.lockParentWindow` and `LinuxOptions.acceptLabel` being silently ignored. Passing a plain `LinuxOptions` fell back to a default `FilePickerLinuxOptions`, dropping whatever the caller had set, which is the exact API the deprecation on `FilePicker.pickFiles` points to. [#2183](https://github.com/miguelpruivo/flutter_file_picker/issues/2183)
- `FilePickerLinuxOptions` now accepts `acceptLabel`, so it no longer has to be traded away in order to set `parentWindow`.

## 1.0.1

- Relax `dbus` to `^0.7.13` so dependents can resolve `xml` 7. [#2130](https://github.com/miguelpruivo/flutter_file_picker/issues/2130)
- Improved package description, added example, and added missing API documentation.

## 1.0.0

- Initial release of Linux implementation package for `file_picker`.
- Added support for `acceptLabel` in `LinuxOptions` to customize the confirmation button label in file dialogs. [#2120](https://github.com/miguelpruivo/flutter_file_picker/pull/2120)

