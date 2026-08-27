## 1.0.2

- Tightened the `file_picker_platform_interface` lower bound to `^3.2.0`. This package's `pickFile()`/`pickFiles()` signatures reference `DarwinOptions`, added in that version, so resolving against an older one would fail to compile.

## 1.0.1

- Relax `dbus` to `^0.7.13` so dependents can resolve `xml` 7. [#2130](https://github.com/miguelpruivo/flutter_file_picker/issues/2130)
- Improved package description, added example, and added missing API documentation.

## 1.0.0

- Initial release of Linux implementation package for `file_picker`.
- Added support for `acceptLabel` in `LinuxOptions` to customize the confirmation button label in file dialogs. [#2120](https://github.com/miguelpruivo/flutter_file_picker/pull/2120)

