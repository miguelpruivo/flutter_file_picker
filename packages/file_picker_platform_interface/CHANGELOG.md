## 3.1.0

- Added `PlatformFile.extension`, restoring the pre-12.0 convenience getter that was dropped during the federated rewrite. Returns the file extension of `name` without the leading dot, or `null` if there is none.

## 3.0.1

- Improved package description, added example, and added missing API documentation.

## 3.0.0

* Unified platform interface release for federated `file_picker` architecture.

## 2.0.0

* Deprecates interface in favor of standalone `file_picker` for all platforms.

## 1.3.1

* Removes `allowCompression` from interface as it should only be used from `file_picker` (Android & iOS).

## 1.3.0

* Adds `allowCompression` parameter.

## 1.2.0

* Adds `FilePickerStatus`.

## 1.1.0

* Implements `getDirectoryPath()`.

## 1.0.0

* Implements `getFiles()`.

## 0.0.3

* Removes `getFilePath()`.

## 0.0.2

* Updates methods from File Picker interface.

## 0.0.1

* Added File Picker platform interface.