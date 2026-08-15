## 1.0.1

- Relaxed the `dbus` constraint to `^0.7.13` so apps that need `xml` 7 can resolve. Version 0.7.14 is identical to 0.7.13 apart from the `xml` bound, and pub still prefers 0.7.14 by default. [#2130](https://github.com/miguelpruivo/flutter_file_picker/issues/2130)

## 1.0.0

- Initial release of Linux implementation package for `file_picker`.
- Added support for `acceptLabel` in `LinuxOptions` to customize the confirmation button label in file dialogs. [#2120](https://github.com/miguelpruivo/flutter_file_picker/pull/2120)

