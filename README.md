[![pub package](https://img.shields.io/pub/v/file_picker.svg)](https://pub.dartlang.org/packages/file_picker)
[![Awesome Flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)
[![Codemagic build status](https://api.codemagic.io/apps/5ce89f4a9b46f5000ca89638/5ce89f4a9b46f5000ca89637/status_badge.svg)](https://codemagic.io/apps/5ce89f4a9b46f5000ca89638/5ce89f4a9b46f5000ca89637/latest_build)

# file_picker

A package that allows you to use a native file explorer to pick single or multiple absolute file paths, with extensions filtering support.

## Installation

First, add  *file_picker*  as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
file_picker: ^1.3.4+1
```
### Android
Add 
```
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
before `<application>` to your app's `AndroidManifest.xml` file. This is required due to file caching when a path is required from a remote file (eg. Google Drive).

### iOS
Based on the location of the files that you are willing to pick paths, you may need to add some keys to your iOS app's _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* **_UIBackgroundModes_** with the **_fetch_** and **_remote-notifications_** keys - Required if you'll be using the `FileType.ANY` or `FileType.CUSTOM`. Describe why your app needs to access background taks, such downloading files (from cloud services). This is called _Required background modes_, with the keys _App download content from network_ and _App downloads content in response to push notifications_ respectively in the visual editor (since both methods aren't actually overriden, not adding this property/keys may only display a warning, but shouldn't prevent its correct usage).

  ```
  <key>UIBackgroundModes</key>
  <array>
     <string>fetch</string>
     <string>remote-notification</string>
  </array>
  ```

* **_NSAppleMusicUsageDescription_** - Required if you'll be using the `FileType.AUDIO`. Describe why your app needs permission to access music library. This is called _Privacy - Media Library Usage Description_ in the visual editor.

   ```
   <key>NSAppleMusicUsageDescription</key>
   <string>Explain why your app uses music</string>
   ```


* **_NSPhotoLibraryUsageDescription_** - Required if you'll be using the `FileType.IMAGE` or `FileType.VIDEO`. Describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor.

   ```
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Explain why your app uses photo library</string>
   ```

**Note:** Any iOS version below 11.0, will require an Apple Developer Program account to enable _CloudKit_ and make it possible to use the document picker (which happens when you select `FileType.ALL`, `FileType.CUSTOM` or any other option with `getMultiFilePath()`). You can read more about it [here]( https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/EnablingiCloudandConfiguringCloudKit/EnablingiCloudandConfiguringCloudKit.html).  


## Usage
There are only two methods that should be used with this package:

#### `FilePicker.getFilePath()`

Will let you pick a **single** file. This receives two optional parameters: the `fileType` for specifying the type of the picker and a `fileExtension` parameter to filter selectable files. The available filters are:
  * `FileType.ANY` - Will let you pick all available files.
  * `FileType.CUSTOM` - Will let you pick a single path for the extension matching the `fileExtension` provided.
  * `FileType.IMAGE` - Will let you pick a single image file. Opens gallery on iOS.
  * `FileType.VIDEO` - WIll let you pick a single video file. Opens gallery on iOS.
  * `FileType.AUDIO` - Will let you pick a single audio file. Opens music on iOS. Note that DRM protected files won't provide a path, `null` will be returned instead. 

#### `FilePicker.getMultiFilePath()`

Will let you select **multiple** files and retrieve its path at once. Optionally you can provide a `fileExtension` parameter to filter the allowed selectable files.
Will return a `Map<String,String>` with the files name (`key`) and corresponding path (`value`) of all selected files. 
Picking multiple paths from iOS gallery (image and video) aren't currently supported. 

#### Usages

So, a few example usages can be as follow:
```
// Single file path
String filePath;
filePath = await FilePicker.getFilePath(type: FileType.ANY); // will let you pick one file path, from all extensions
filePath = await FilePicker.getFilePath(type: FileType.CUSTOM, fileExtension: 'svg'); // will filter and only let you pick files with svg extension

// Pick a single file directly
File file = await FilePicker.getFile(type: FileType.ANY); // will return a File object directly from the selected file

// Multi file path
Map<String,String> filesPaths;
filePaths = await FilePicker.getMultiFilePath(); // will let you pick multiple files of any format at once
filePaths = await FilePicker.getMultiFilePath(fileExtension: 'pdf'); // will let you pick multiple pdf files at once
filePaths = await FilePicker.getMultiFilePath(type: FileType.IMAGE); // will let you pick multiple image files at once

List<String> allNames = filePaths.keys; // List of all file names
List<String> allPaths = filePaths.values; // List of all paths
String someFilePath = filePaths['fileName']; // Access a file path directly by its name (matching a key)
```

##### A few side notes
* Using `getMultiFilePath()` on iOS will always use the document picker (aka Files app). This means that multi picks are not currently supported for photo library images/videos or music library files. 
* When using `FileType.CUSTOM`, unsupported extensions will throw a `MissingPluginException` that is handled by the plugin.
* On Android, when available, you should avoid using third-party file explorers as those may prevent file extension filtering (behaving as `FileType.ANY`). In this scenario, you will need to validate it on return.

## Currently supported features
* [X] Load paths from **cloud files** (GDrive, Dropbox, iCloud)
* [X] Load path from a **custom format** by providing a file extension (pdf, svg, zip, etc.)
* [X] Load path from **multiple files** optionally, supplying a file extension
* [X] Load path from **gallery**
* [X] Load path from **audio**
* [X] Load path from **video**
* [X] Load path from **any** 
* [X] Create a `File` object from **any** selected file

## Demo App

![Demo](https://github.com/miguelpruivo/plugins_flutter_file_picker/blob/master/example/example.gif)

## Example
See example app.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).



