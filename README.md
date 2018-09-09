# file_picker

File picker plugin alows you to use a native file explorer to load absolute file path from different types of files.

## Installation

First, add both *file_picker* and *image_picker* as dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).

Note: for now, just add the file_picker as git plugin.
```
file_picker:
    git:
      url: https://github.com/miguelpruivo/plugins_flutter_file_picker.git

```

and the [image_picker](https://pub.dartlang.org/packages/image_picker#-readme-tab-).
```
image_picker: ^0.4.10
```

## Android
Add `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />` to your app `AndroidManifest.xml` file.

## iOS
Since we are using *image_picker* as a dependency from this plugin to load paths from gallery and camera, we need the following keys to your _Info.plist_ file, located in `<project root>/ios/Runner/Info.plist`:

* `NSPhotoLibraryUsageDescription` - describe why your app needs permission for the photo library. This is called _Privacy - Photo Library Usage Description_ in the visual editor.
* `NSCameraUsageDescription` - describe why your app needs access to the camera. This is called _Privacy - Camera Usage Description_ in the visual editor.
* `NSMicrophoneUsageDescription` - describe why your app needs access to the microphone, if you intend to record videos. This is called _Privacy - Microphone Usage Description_ in the visual editor.

## To-do
[X] Load paths from local files & cloud (GDrive, Dropbox, iCloud)<br>
[X] Load PDF file path<br>
[X] Load path from gallery<br>
[X] Load path from camera shot<br>
[ ] Load a custom format<br>

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
      String filePath = await FilePicker.getFilePath;
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
