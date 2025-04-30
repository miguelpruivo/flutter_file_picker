![fluter_file_picker](https://user-images.githubusercontent.com/27860743/64064695-b88dab00-cbfc-11e9-814f-30921b66035f.png)
<p align="center">
  <a href="https://pub.dartlang.org/packages/file_picker">
    <img alt="File Picker" src="https://img.shields.io/pub/v/file_picker.svg">
  </a>
  <a href="https://github.com/Solido/awesome-flutter">
    <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square">
  </a>
  <a href="https://www.buymeacoffee.com/gQyz2MR">
    <img alt="Buy me a coffee" src="https://img.shields.io/badge/Donate-Buy%20Me%20A%20Coffee-yellow.svg">
  </a>
  <a href="https://github.com/miguelpruivo/flutter_file_picker/issues">
    <img src="https://img.shields.io/github/issues/miguelpruivo/flutter_file_picker" alt="GitHub issues badge">
  </a>
  <a href="https://github.com/miguelpruivo/flutter_file_picker?tab=MIT-1-ov-file">
    <img src="https://img.shields.io/github/license/miguelpruivo/flutter_file_picker" alt="GitHub license badge">
  </a>
  <a href="https://github.com/miguelpruivo/flutter_file_picker/actions/workflows/main.yml">
    <img alt="CI pipeline status" src="https://github.com/miguelpruivo/flutter_file_picker/actions/workflows/main.yml/badge.svg">
  </a>
</p>

# File Picker
A package that allows you to use the native file explorer to pick single or multiple files, with extensions filtering support.

## Currently supported features
* Uses OS default native pickers
* Supports multiple platforms (Mobile, Web, Desktop)
* Pick files using  **custom format** filtering — you can provide a list of file extensions (pdf, svg, zip, etc.)
* Pick files from **cloud files** (GDrive, Dropbox, iCloud)
* Single or multiple file picks
* Supports retrieving as XFile (cross_file) for easy manipulation with other libraries
* Different default type filtering (media, image, video, audio or any)
* Picking directories
* Picking both files and directories simultaneously
* Load file data immediately into memory (`Uint8List`) if needed; 
* Open a save-file / save-as dialog (a dialog that lets the user specify the drive, directory, and name of a file to save)

If you have any feature that you want to see in this package, please feel free to issue a suggestion. 🎉

## Compatibility Chart

| API                           | Android            | iOS                | Linux              | macOS              | Windows            | Web                |
|-------------------------------|--------------------|--------------------|--------------------|--------------------|--------------------|--------------------|
| `clearTemporaryFiles()`       | :white_check_mark: | :white_check_mark: | :x:                | :x:                | :x:                | :x:                |
| `getDirectoryPath()`          | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:                |
| `pickFileAndDirectoryPaths()` | :x:                | :x:                | :x:                | :white_check_mark: | :x:                | :x:                |
| `pickFiles()`                 | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| `saveFile()`                  | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |

See the [API section of the File Picker Wiki](https://github.com/miguelpruivo/flutter_file_picker/wiki/api) or the [official API reference on pub.dev](https://pub.dev/documentation/file_picker/latest/file_picker/FilePicker-class.html) for further details.

## Getting Started

For detailed setup docuemnt see [Setup document](https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup)

### Android

- For Android 11+, ensure gradle compatibility. See [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/Troubleshooting#-issue) for details.
- If you override `onActivityResult`, call `super.onActivityResult(...)`

### iOS

- Make sure `use_frameworks!` is included on your `ios/Podfile` file like this:
  ```
  target 'Runner' do
  use_frameworks!
  ```
- See [iOS Wiki Setup](https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup#ios) for full list of optional permissions

### Web

You are good to go as long as you are on `Flutter 2.0` or above.

### Widnows & Linux

You can enable Windows & Linux platform development in your application with this command
```bash
flutter config --enable-windows-desktop   # Windows
flutter config --enable-linux-desktop     # Linux
```

### macOS
You can enable macOS platform development in your application with this command
```bash
flutter config --enable-macos-desktop
```

It is **necessary** to enable the "Read" User Selected File entitlement for selecting files and "Read/Write" for saving:

![macOS setup](https://github.com/user-attachments/assets/921cc8dd-8fa1-41f0-a924-8aa49d4d3cf5)

Or you can enable it by adding:
```
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```
to `DebugProfile.entitlements` and `Release.entitlements` files.

## Usage
Quick simple usage example:

#### Single file
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  File file = File(result.files.single.path!);
} else {
  // User canceled the picker
}
```
#### Multiple files
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

if (result != null) {
  List<File> files = result.paths.map((path) => File(path!)).toList();
} else {
  // User canceled the picker
}
```
#### Multiple files with extension filter
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles(
  allowMultiple: true,
  type: FileType.custom,
  allowedExtensions: ['jpg', 'pdf', 'doc'],
);
```
#### Pick a directory
```dart
String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

if (selectedDirectory == null) {
  // User canceled the picker
}
```
#### Save-file / save-as dialog
```dart
String? outputFile = await FilePicker.platform.saveFile(
  dialogTitle: 'Please select an output file:',
  fileName: 'output-file.pdf',
);

if (outputFile == null) {
  // User canceled the picker
}
```
### Load result and file details
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  PlatformFile file = result.files.first;

  print(file.name);
  print(file.bytes);
  print(file.size);
  print(file.extension);
  print(file.path);
} else {
  // User canceled the picker
}
```
### Retrieve all files as XFiles or individually
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  // All files
  List<XFile> xFiles = result.xFiles;

  // Individually
  XFile xFile = result.files.first.xFile;
} else {
  // User canceled the picker
}
```
#### Pick and upload a file to Firebase Storage with Flutter Web
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  Uint8List fileBytes = result.files.first.bytes;
  String fileName = result.files.first.name;
  
  // Upload file
  await FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes);
}
```

For full usage details refer to the **[Wiki](https://github.com/miguelpruivo/flutter_file_picker/wiki)** above.

## Example App
#### Android
![DemoAndroid](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/screenshots/example_android.gif?raw=true)

#### iOS
![DemoMultiFilters](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/screenshots/example_ios.gif?raw=true)

#### MacOS
![DemoMacOS](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/screenshots/example_macos.gif?raw=true)

#### Linux
![DemoLinux](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/screenshots/example_linux.gif?raw=true)

#### Windows
![DemoWindows](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/screenshots/example_windows.gif?raw=true)

## Documentation
See the **[File Picker Wiki](https://github.com/miguelpruivo/flutter_file_picker/wiki)** for every detail on about how to install, setup and use it.