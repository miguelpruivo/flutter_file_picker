[![pub package](https://img.shields.io/pub/v/file_picker.svg)](https://pub.dartlang.org/packages/file_picker)
[![Awesome Flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

# file_picker

File picker plugin alows you to use a native file explorer to load absolute file path from different file types.

## Installation

First, add  *file_picker*  as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
file_picker: ^1.3.0
```
## Android
Add `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>` to your app `AndroidManifest.xml` file. This is required due to file caching when a path is required from a remote file (eg. Google Drive).

## iOS
Based on the location of the files that you are willing to pick paths, you may need to add some keys to your iOS app's _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* **_NSAppleMusicUsageDescription_** - Required if you'll be using the `FileType.AUDIO`. Describe why your app needs permission to access music library. This is called _Privacy - Media Library Usage Description_ in the visual editor.

* **_NSPhotoLibraryUsageDescription_** - Required if you'll be using the `FileType.IMAGE` or `FileType.VIDEO`. Describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor.

* **_UIBackgroundModes_** with the **_fetch_** and **_remote-notifications_** keys - Required if you'll be using the `FileType.ANY` or `FileType.CUSTOM`. Describe why your app needs to access background taks, such downloading files (from cloud services) when not cached to locate path. This is called _Required background modes_, with the keys _App download content from network_ and _App downloads content in response to push notifications_ respectively in the visual editor (since both methods aren't actually overriden, not adding this property/keys may only display a warning, but shouldn't prevent its correct usage).

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

So, a few basically usages can be as follow:
```
String filePath;
filePath = await FilePicker.getFilePath(type: FileType.ANY); // will let you pick one file, from all extensions
filePath = await FilePicker.getFilePath(type: FileType.CUSTOM, fileExtension: 'svg'); // will filter and only let you pick files with svg extension.

Map<String,String> filesPaths;
filePaths = await FilePicker.getMultiFilePath(); // will let you pick multiple files of any format at once
filePaths = await FilePicker.getMultiFilePath(fileExtension: 'pdf'); // will let you pick multiple pdf files at once
```

##### A few notes
* When using `FileType.CUSTOM`, unsupported extensions will throw a `MissingPluginException` that is handled by the plugin.
* On Android, when available, you should avoid using custom file explorers as those may prevent file extension filtering (behaving as `FileType.ANY`). In this scenario, you will need to validate it on return.

## Currently supported features
* [X] Load paths from **cloud files** (GDrive, Dropbox, iCloud)
* [X] Load path from a **custom format** by providing a file extension (pdf, svg, zip, etc.)
* [X] Load path from **multiple files** with an optional file extension
* [X] Load path from **gallery**
* [X] Load path from **audio**
* [X] Load path from **video**
* [X] Load path from **any** file type (without filtering, just pick what you want)

## Demo App

![Demo](https://github.com/miguelpruivo/plugins_flutter_file_picker/blob/master/example/example.gif)

## Example
```
import 'package:file_picker/file_picker.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _filePath;

  void getFilePath() async {
   try {
      String filePath = await FilePicker.getFilePath(type: FileType.ANY);
      if (filePath == '') {
        return;
      }
      print("File path: " + filePath);
      setState((){this._filePath = filePath;});
    } on PlatformException catch (e) {
      print("Error while picking the file: " + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('File Picker Example'),
      ),
      body: new Center(
        child: _filePath == null
            ? new Text('No file selected.')
            : new Text('Path' + _filePath),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: getFilePath,
        tooltip: 'Select file',
        child: new Icon(Icons.sd_storage),
      ),
    );
  }
}

```

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).

