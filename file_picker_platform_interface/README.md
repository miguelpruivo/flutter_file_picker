# MUST READ!

The interface is deprectated in favor of standalone [file_picker](https://pub.dev/packages/file_picker) for all platforms where an interface is integrated. This should be the one used as this package is not longer mantained.

# file_picker_platform_interface

A common platform interface for the [`file_picker`][1] plugin.

This interface allows platform-specific implementations of the `file_picker`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.


# Usage

To implement a new platform-specific implementation of `file_picker`, extend
[`FilePickerPlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`FilePickerPlatform` by calling
`FilePickerPlatform.instance = MyPlatformFilePicker()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.

[1]: ../file_picker
[2]: lib/file_picker_platform_interface.dart
