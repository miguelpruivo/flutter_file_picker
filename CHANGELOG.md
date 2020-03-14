## 1.5.0

* **Breaking change:** Refactored `FileType` to match lower camelCase Dart guideline (eg. `FileType.ALL` now is `FileType.all`);
* Added support for new [Android plugins APIs](https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration) (Android V2 embedding);

## 1.4.3+2

Updates dependencies.

## 1.4.3+1

Removes checked flutter_export_environment.sh from example app.

## 1.4.3

**Bug fix**
 * Fixes an issue that could result in a crash when tapping multiple times in the same media file while picking, on some iOS devices (#171).

## 1.4.2+1

Updates go-flutter dependencies.

## 1.4.2

**Bug fix**
 * Fixes an issue that could cause a crash when picking video files in iOS 13 or above due to SDK changes.
 * Updates Go-Flutter with go 1.13.

## 1.4.1

**Bug fix:** Fixes an issue that could result in some cached files, picked from Google Photos (remote file), to have the name set as `null`.

## 1.4.0+1

**Bug fix:** Fixes an issue that could prevent internal storage files from being properly picked. 

## 1.4.0

**New features**
 * Adds Desktop support throught **[go-flutter](https://github.com/go-flutter-desktop/go-flutter)**, you can see detailed instructions on how to get in runing [here](https://github.com/go-flutter-desktop/hover).
 * Adds Desktop example, to run it just do `hover init` and then `hover run` within the plugin's example folder (you must have go and hover installed, check the previous point).
 * Similar to `getFile`, now there is also a `getMultiFile` which behaves the same way, but returning a list of files instead.

**Improvements**
 * Updates Android SDK deprecated code.
 * Sometimes when a big file was being picked from a remote directory (GDrive for example), the UI could be blocked. Now this shouldn't happen anymore.

## 1.3.8

**Bug fix:** Fixes an issue that could cause a crash when picking files with very long names.

**Changes:** Updates Android target API to 29.

## 1.3.7

**Rollback - Breaking change:** Re-adds runtime verification for external storage read permission. Don't forget to add the permission to the `AndroidManifest.xml` file as well. More info in the README file.

**Bug fix:** Fixes a crash that could cause some Android API to crash when multiple files were selected from external storage.

## 1.3.6

**Improvements**
 * Removes the Android write permissions requirement.
 * Minor improvements in the example app.
 * Now the exceptions are rethrown in case the user wants to handle them, despite that already being done in the plugin call.

## 1.3.5

**Bug fix:** Fixes an issue that could prevent users to pick files from the iCloud Drive app, on versions below iOS 11. 

## 1.3.4+1

**Rollback:** Removes a local dependency that shouldn't have been committed with `1.3.4` which would cause Android build to fail.

## 1.3.4

**Bug fix:** Protects the `registrar.activity()` in the Android side of being accessed when it's `null`.

## 1.3.3

**Bug fixes**
 * Fixes an issue where sometimes a single file path was being returned as a `List` instead of `String`.
 * `requestCode` in Android intents are now restricted to 16 bits.

## 1.3.2

**Bug fix:** Returns a `null` value in the `getFile()` when the picker is canceled.

## 1.3.1

**Bug fix:** Fixes an issue on Android, where other activity would try to call `FilePicker`'s result object when it shouldn't.  

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
* Minor correction in the README file. 

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

* Initial release.
* Supports picking paths from files on local storage, cloud.
* Supports picking paths from both gallery & camera due to [image_picker](https://pub.dartlang.org/packages/image_picker) dependency.
