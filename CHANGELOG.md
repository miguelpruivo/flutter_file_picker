## 1.3.0

**Breaking changes**
 * `FileType.CAMERA` is no longer available, if you need it, you can use this package along with [image_picker](https://pub.dartlang.org/packages/image_picker).
 
**New features**
 * You can now pick multiple files by using the `getMultiFilePath()` method which will return a `Map<String,String>` with all paths from selected files, where the key matches the file name and the value its path. Optionally, it also supports filtering by file extension, otherwise all files will be selectable. Nevertheless, you should keep using `getFilePath()` for single path picking.
 * You can now use `FileType.AUDIO` to pick audio files. In iOS this will let you select from your music library. Paths from DRM protected files won't be loaded (see README for more details).
 * Adds `getFile()` utility method that does the same of `getFilePath()` but returns a `File` object instead, for the returned path.
 
**Bug fixes and updates**
 * This package is no longer attached to the [image_picker](https://pub.dartlang.org/packages/image_picker), and because of that, camera permission is also no longer required.
 * Fixes an issue where sometimes the _InputStream_ wasn't being properly closed. Also, its exception is now being forward to the plugin caller.
 * Fixes an issue where the picker, when canceled, wasn't calling the result callback on the underlying platforms.

## 1.2.0

**Breaking change**: Migrate from the deprecated original Android Support Library to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to [also migrate](https://developer.android.com/jetpack/androidx/migrate) if they're using the original support library.

## 1.1.1

* Updates README file.

## 1.1.0

**Breaking changes** 
 * `FileType.PDF` was removed since now it can be used along with custom file types by using the `FileType.CUSTOM` and providing the file extension (e.g. PDF, SVG, ZIP, etc.).
 * `FileType.CAPTURE` is now `FileType.CAMERA`
 
**New features**
 * Now it is possible to provide a custom file extension to filter file picking options by using `FileType.CUSTOM`
 
**Bug fixes and updates**
 * Fixes file names from cloud on Android. Previously it would always display **Document**
 * Fixes an issue on iOS where an exception was being thrown after canceling and re-opening the picker.
 * Fixes an issue where collision could happen with request codes on Android.
 * Adds public documentation to `file_picker`
 * Example app updated.
 * Updates .gitignore

## 1.0.3

 * Fixes `build.gradle`.  

## 1.0.2

 * Minor update of README file. 

## 1.0.1

 * Adds comments for public API

## 1.0.0

 * **Version 1.0** release.
 * Adds support for ANY and VIDEO files.
 * Fixes an issue where permissions were recursively asked on Android.
 * Fixes an issue where some paths from document files couldn't be loaded with Android 8.0.
 * Updates README file to match changes. 
 * General refactor & cleanup. 

## 0.1.6
* Replaces commons dependency with FilePath class on Android, to handle path resolution on different SDK. 

## 0.1.5
* Minor correction on README file. 

## 0.1.4
* Changed Meta minimum version due to versioning conflict with flutter_localization. 

## 0.1.3

* Updated readme.

## 0.1.2

* Changed license from Apache 2.0 to MIT. 
* Adds demo screenshot.

## 0.1.1

* Adds license information (Apache 2.0).
* Adds CHANGELOG details.

## 0.1.0

* Initial realise.
* Supports picking paths from files on local storage, cloud.
* Supports picking paths from both gallery & camera due to [image_picker](https://pub.dartlang.org/packages/image_picker) dependency.
