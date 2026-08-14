## 1.0.1

- Fixed `MissingPluginException` on macOS by registering the event channel stream handler.
- Fixed method channel handling on macOS to support all file types and actions (`any`, `image`, `video`, `audio`, `media`, `custom`, `dir`, `save`).
- Fixed `saveFile` on macOS not writing the provided file `bytes` to the chosen location.
- Added safe argument unwrapping in macOS handler to prevent runtime crashes when arguments are null.
- Added native `UTType` file type filtering for macOS file dialogs.

## 1.0.0

- Initial release of iOS and macOS implementation package for `file_picker`.
