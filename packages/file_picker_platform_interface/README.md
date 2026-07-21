# file_picker_platform_interface

A common platform interface for the `file_picker` plugin.

This package defines the interface that all platform implementation packages for `file_picker` (such as `file_picker_android`, `file_picker_ios`, `file_picker_macos`, `file_picker_windows`, `file_picker_linux`, `file_picker_web`) must implement.

## Usage

To implement a new platform plugin for `file_picker`, extend `FilePickerPlatform` and register your implementation:

```dart
class FilePickerCustomPlatform extends FilePickerPlatform {
  static void registerWith() {
    FilePickerPlatform.instance = FilePickerCustomPlatform();
  }

  // Implement methods...
}
```
