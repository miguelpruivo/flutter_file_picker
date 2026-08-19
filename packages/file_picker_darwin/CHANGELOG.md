## 1.0.2

- Fixed the Save dialog on macOS auto-selecting the file extension along with the rest of the file name, making it easy to accidentally delete the extension when renaming. The extension is now hidden by default via `NSSavePanel.isExtensionHidden`.

## 1.0.1

- Fixed `pickFileAndDirectoryPaths` never returning directories on iOS and macOS. It now calls the native combined file and directory picker instead of silently falling back to file only selection.
- Fixed `MissingPluginException` on macOS by registering the event channel stream handler.
- Fixed method channel handling on macOS to support all file types and actions (`any`, `image`, `video`, `audio`, `media`, `custom`, `dir`, `save`).
- Fixed `saveFile` on macOS not writing the provided file `bytes` to the chosen location.
- Added safe argument unwrapping in macOS handler to prevent runtime crashes when arguments are null.
- Added native `UTType` file type filtering for macOS file dialogs.
- Improved package description, added example, and added missing API documentation.

## 1.0.0

- Initial release of iOS and macOS implementation package for `file_picker`.
