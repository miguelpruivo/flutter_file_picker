![fluter_file_picker](https://user-images.githubusercontent.com/27860743/64064695-b88dab00-cbfc-11e9-814f-30921b66035f.png)
<p align="center">
 <a href="https://pub.dartlang.org/packages/file_picker">
    <img alt="File Picker" src="https://img.shields.io/pub/v/file_picker.svg">
  </a>
 <a href="https://github.com/Solido/awesome-flutter">
    <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square">
  </a>
 <a href="https://codemagic.io/apps/5ce89f4a9b46f5000ca89638/5ce89f4a9b46f5000ca89637/latest_build">
    <img alt="Build Status" src="https://api.codemagic.io/apps/5ee2d379c2d4737a756cbd00/5ee2d379c2d4737a756cbcff/status_badge.svg">
  </a>
 <a href="https://www.buymeacoffee.com/gQyz2MR">
    <img alt="Buy me a coffee" src="https://img.shields.io/badge/Donate-Buy%20Me%20A%20Coffee-yellow.svg">
  </a>
</p>

# File Picker
A package that allows you to use the native file explorer to pick single or multiple files, with extensions filtering support.

## Currently supported features
* Uses OS default native pickers
* Pick files using  **custom format** filtering — you can provide a list of file extensions (pdf, svg, zip, etc.)
* Pick files from **cloud files** (GDrive, Dropbox, iCloud)
* Single or multiple file picks
* Different default type filtering (media, image, video, audio or any)
* Picking directories 
* Flutter Web
* Desktop (MacOS, Linux and Windows through Flutter Go)
* Load file data immediately into memory (`Uint8List`) if needed; 

If you have any feature that you want to see in this package, please feel free to issue a suggestion. 🎉

## Documentation
See the **[File Picker Wiki](https://github.com/miguelpruivo/flutter_file_picker/wiki)** for every detail on about how to install, setup and use it.

### File Picker Wiki

1. [Installation](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Installation)
2. [Setup](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup)
   * [Android](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup#android)
   * [iOS](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup#ios)
   * [Web](https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup#--web)
   * [Desktop (go-flutter)](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup/_edit#desktop-go-flutter)
3. [API](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/api)
   * [Filters](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/API#filters)
   * [Parameters](https://github.com/miguelpruivo/flutter_file_picker/wiki/API#parameters)
   * [Methods](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/API#methods)
4. [FAQ](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
5. [Troubleshooting](https://github.com/miguelpruivo/flutter_file_picker/wiki/Troubleshooting)

## Usage
Quick simple usage example:

#### Single file
```
FilePickerResult? result = await FilePicker.platform.pickFiles();

if(result != null) {
   File file = File(result.files.single.path);
} else {
   // User canceled the picker
}
```
#### Multiple files
```
FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

if(result != null) {
   List<File> files = result.paths.map((path) => File(path)).toList();
} else {
   // User canceled the picker
}
```
#### Multiple files with extension filter
```
FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'pdf', 'doc'],
        );
```
### Load result and file details
```
FilePickerResult? result = await FilePicker.platform.pickFiles();

if(result != null) {
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
#### Pick and upload a file to Firebase Storage with Flutter Web
```
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
![Demo](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/example.gif)
![DemoMultiFilters](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/example_ios.gif)

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).



