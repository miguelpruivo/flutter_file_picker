[![pub package](https://img.shields.io/pub/v/file_picker.svg)](https://pub.dartlang.org/packages/file_picker)
[![Awesome Flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)
[![Codemagic build status](https://api.codemagic.io/apps/5ce89f4a9b46f5000ca89638/5ce89f4a9b46f5000ca89637/status_badge.svg)](https://codemagic.io/apps/5ce89f4a9b46f5000ca89638/5ce89f4a9b46f5000ca89637/latest_build)

# file_picker

A package that allows you to use a native file explorer to pick single or multiple absolute file paths, with extensions filtering support.

## Currently supported features
* [X] Load paths from **cloud files** (GDrive, Dropbox, iCloud)
* [X] Load path from a **custom format** by providing a file extension (pdf, svg, zip, etc.)
* [X] Load path from **multiple files** optionally, supplying a file extension
* [X] Load path from **gallery**
* [X] Load path from **audio**
* [X] Load path from **video**
* [X] Load path from **any** 
* [X] Create a `File` or `List<File>` objects from **any** selected file(s)
* [X] Supports desktop throught **go-flutter** (MacOS, Windows, Linux) 

If you have any feature that you want to see in this package, please add it [here](https://github.com/miguelpruivo/plugins_flutter_file_picker/issues/99). 🎉


## Installation

First, add  *file_picker*  as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
file_picker: ^1.4.0
```
### Android
Nothing is required here. You are good to go. 
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

##### Single file path
```
String filePath;

// Will let you pick one file path, from all extensions
filePath = await FilePicker.getFilePath(type: FileType.ANY);

// Will filter and only let you pick files with svg extension
filePath = await FilePicker.getFilePath(type: FileType.CUSTOM, fileExtension: 'svg'); 
```

##### Pick a single file directly
```
// Will return a File object directly from the selected file
File file = await FilePicker.getFile(type: FileType.ANY);
```

##### Multi file path
```
Map<String,String> filesPaths;

// Will let you pick multiple files of any format at once
filePaths = await FilePicker.getMultiFilePath();

// Will let you pick multiple pdf files at once
filePaths = await FilePicker.getMultiFilePath(fileExtension: 'pdf');

// Will let you pick multiple image files at once
filePaths = await FilePicker.getMultiFilePath(type: FileType.IMAGE); 

List<String> allNames = filePaths.keys; // List of all file names
List<String> allPaths = filePaths.values; // List of all paths
String someFilePath = filePaths['fileName']; // Access a file path directly by its name (matching a key)
```

##### Pick a list of files directly
```
// Will return a List<File> object directly from the selected files
List<File> files = await FilePicker.getMultiFile(type: FileType.ANY);
```

##### A few side notes
* Using `getMultiFilePath()` on iOS will always use the document picker (aka Files app). This means that multi picks are not currently supported for photo library images/videos or music library files. 
* When using `FileType.CUSTOM`, unsupported extensions will throw a `MissingPluginException` that is handled by the plugin.
* On Android, when available, you should avoid using third-party file explorers as those may prevent file extension filtering (behaving as `FileType.ANY`). In this scenario, you will need to validate it on return.

## How to setup go-flutter for desktop
1. Because go-flutter uses GO, you will need to install go-tools by following [these steps](https://golang.org/doc/install#install).
2. Then, follow [these instructions](https://github.com/go-flutter-desktop/hover) to install hover on your machine.
3. Now, inside your app's folder, you should be able to do `hover init .` that will create all the desktop boilerplate for you. If for some reasone you can't do this step, be sure that you haven't missed anything from the setup.
4. Go to your `project/desktop/cmd/options.go` and add the following lines
```
package main

import (
	... other imports ....
	
	"github.com/miguelpruivo/plugins_flutter_file_picker/go"
)

var options = []flutter.Option{
	... other plugins and options ...

	flutter.AddPlugin(&file_picker.FilePickerPlugin{}),
}
```
5. In your `main.dart` make sure you override the targetplatform to:
```
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
```
6. All set, just do `hover run` and you should have your app running on Desktop with FilePicker plugin.
## Demo App

![Demo](https://github.com/miguelpruivo/plugins_flutter_file_picker/blob/master/example/example.gif)

## Example
See example app.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).



