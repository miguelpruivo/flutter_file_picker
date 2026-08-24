## 1.0.2

- Removed the stale `buildscript` classpath from the Android module, which pinned AGP 8.5.2 and Kotlin Gradle Plugin 1.8.22 in a module that supports AGP 9 and Kotlin 2.3. [#2154](https://github.com/miguelpruivo/flutter_file_picker/pull/2154)

## 1.0.1

- Improved package description, added example, and added missing API documentation.

## 1.0.0

- Initial release of Android implementation package for `file_picker`.
- Removed the Apache Tika dependency (~300 KB) used for MIME type detection in `saveFile()`. MIME types are now resolved from the file name extension via `MimeTypeMap`, with `URLConnection.guessContentTypeFromStream` as a content-sniffing fallback when no extension is available. [#2101](https://github.com/miguelpruivo/flutter_file_picker/issues/2101)
