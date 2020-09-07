## [2.0.0] - Deprecates interface

Deprecates interface in favor of standalone [file_picker](https://pub.dev/packages/file_picker) for all platforms.

## [1.3.1] - Rollback `allowCompression`

Removes `allowCompression` from interface as it should only be used from `file_picker` (Android & iOS).

## [1.3.0] - Adds `allowCompression` parameter

Adds `allowCompression` that will allow developers to set whether the picked media files (image/video) can be automatically compressed by OS or not. Defaults to `true`.

## [1.2.0] - Adds FilePickerStatus

Adds `onFiledLoading` that will provide an event handler with `FilePickerStatus` when picking files.

## [1.1.0] - Adds directory pick 

Implements `getDirectoryPath()`

## [1.0.0] - Updates method channel

Implements `getFiles()`

## [0.0.3] - Updates interface

Removes `getFilePath()`

## [0.0.2] - Updates interface

Updates methods from File Picker interface

## [0.0.1+1] - Update README

Updates README

## [0.0.1] - Create Platform Interface

Added Filer Picker platform interface.
