# file_picker_darwin

The iOS and macOS implementation of `file_picker`.

## Usage

This package is endorsed, which means you can simply use `file_picker` as normal, and the iOS and macOS implementations will be automatically included.

#### Pick iOS media using its current representation
```dart
List<PlatformFile> files = await FilePicker.pickFiles(
  type: FileType.video,
  compressionQuality: 0,
  darwinOptions: const DarwinOptions(
    assetRepresentationMode: DarwinAssetRepresentationMode.current,
  ),
);
```

The available modes are `automatic` (the default), `current`, and
`compatible`. This option applies only to the iOS photo-library picker.
Non-automatic modes require `compressionQuality` to be `0`.
