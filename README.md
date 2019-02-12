[![pub package](https://img.shields.io/pub/v/file_picker.svg)](https://pub.dartlang.org/packages/file_picker)
[![Awesome Flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

# file_picker

File picker plugin alows you to use a native file explorer to load absolute file path from different file types.

## Installation

First, add  *file_picker*  as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).

```
file_picker: ^1.2.0
```
## Android
Add `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>` to your app `AndroidManifest.xml` file.

## iOS
Since we are using *image_picker* as a dependency from this plugin to load paths from gallery and camera, we need the following keys to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor.
* `NSCameraUsageDescription` - describe why your app needs access to the camera. This is called _Privacy - Camera Usage Description_ in the visual editor.
* `NSMicrophoneUsageDescription` - describe why your app needs access to the microphone, if you intend to record videos. This is called _Privacy - Microphone Usage Description_ in the visual editor.
* `UIBackgroundModes` with the `fetch` and `remote-notifications` keys - describe why your app needs to access background taks, such downloading files (from cloud services) when not cached to locate path. This is called _Required background modes_, with the keys _App download content from network_ and _App downloads content in response to push notifications_ respectively in the visual editor (since both methods aren't actually overriden, not adding this property/keys may only display a warning, but shouldn't prevent its correct usage).

## Usage
There's only one method within this package
`FilePicker.getFilePath()`
this receives 2 optional parameters, the `fileType` and a `fileExtension` to be used along with `FileType.CUSTOM`. 
So, 2 basically usages may be:
```
await FilePicker.getFilePath(type: FileType.ANY); // will display all file types
await FilePicker.getFilePath(type: FileType.CUSTOM, fileExtension: 'svg'); // will filter and display only files with SVG extension.
```

**Note:** When using `FileType.CUSTOM`, unsupported extensions will throw a `MissingPluginException` that is handled by the plugin.

## Currently supported features
* [X] Load paths from **cloud files** (GDrive, Dropbox, iCloud)
* [X] Load path from **gallery**
* [X] Load path from **camera**
* [X] Load path from **video**
* [X] Load path from **any** type of file (without filtering)
* [X] Load path from a **custom format** by providing a file extension (pdf, svg, zip, etc.)

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
