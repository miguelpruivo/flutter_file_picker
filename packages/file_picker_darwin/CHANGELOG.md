## 1.0.2

- Fixed a crash (`FileSystemException`/`OSError: Is a directory`) when picking a Live Photo from the iOS gallery. Live Photos are saved by iOS as `.pvt` packages (directories), which `loadFileRepresentation(forTypeIdentifier: UTType.item...)` returned as-is; the still image contained in the package is now extracted instead.
- Fixed `getDirectoryPath`, `pickFiles`, `pickFileAndDirectoryPaths`, and `saveFile` on macOS defaulting to the sandbox container's `Data` folder instead of the user's real home directory when no `initialDirectory` is provided and the app has App Sandbox enabled.
- Fixed the Save dialog on macOS auto-selecting the file extension along with the rest of the file name, making it easy to accidentally delete the extension when renaming. The extension is now hidden by default via `NSSavePanel.isExtensionHidden`.
- Fixed bundle-like directories (e.g. `.app`, `.fcpbundle`) not being selectable as files on macOS file pickers, a regression since 8.2.0. `NSOpenPanel.treatsFilePackagesAsDirectories` is now explicitly set to `false` so these are presented as selectable files, matching Finder and other native apps.

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
