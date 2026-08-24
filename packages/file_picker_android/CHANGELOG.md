## 1.0.2

- Removed the stale `buildscript` classpath from the Android module, which pinned AGP 8.5.2 and Kotlin Gradle Plugin 1.8.22 in a module that supports AGP 9 and Kotlin 2.3. [#2154](https://github.com/miguelpruivo/flutter_file_picker/pull/2154)
- Fixed `allowedExtensions` filters being discarded entirely and falling back to showing all files when only some of the requested extensions had no mime type known to Android (e.g. `pfx`, `p12`). Now the extensions that do resolve to a mime type are still used to filter, and `*/*` is only used when none of them resolve.

## 1.0.1

- Improved package description, added example, and added missing API documentation.

## 1.0.0

- Initial release of Android implementation package for `file_picker`.
- Removed the Apache Tika dependency (~300 KB) used for MIME type detection in `saveFile()`. MIME types are now resolved from the file name extension via `MimeTypeMap`, with `URLConnection.guessContentTypeFromStream` as a content-sniffing fallback when no extension is available. [#2101](https://github.com/miguelpruivo/flutter_file_picker/issues/2101)
