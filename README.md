# file_picker

File picker plugin alows you to use a native file explorer to load absolute file path from different types of files.

## Installation

First, add file_picker as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).

Note: for now, just add it as remote plugin.
```
file_picker:
    git:
      url: https://github.com/miguelpruivo/plugins_flutter_file_picker.git
```

## Android
Add `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />` to your app `AndroidManifest.xml` file.

## iOS
No configuration required - the plugin should work out of the box.

## To-do
[X] Load paths from local & cloud<br>
[X] Load pdf files<br>
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
      Logger(widget.tag).info("File path: " + filePath);
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
