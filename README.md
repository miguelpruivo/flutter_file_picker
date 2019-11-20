![fluter_file_picker](https://user-images.githubusercontent.com/27860743/64064695-b88dab00-cbfc-11e9-814f-30921b66035f.png)
<p align="center">
 <a href="https://pub.dartlang.org/packages/file_picker">
    <img alt="File Picker" src="https://img.shields.io/pub/v/file_picker.svg">
  </a>
 <a href="https://github.com/Solido/awesome-flutter">
    <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square">
  </a>
 <a href="https://codemagic.io/apps/5ce89f4a9b46f5000ca89638/5ce89f4a9b46f5000ca89637/latest_build">
    <img alt="Build Status" src="https://api.codemagic.io/apps/5ce89f4a9b46f5000ca89638/5ce89f4a9b46f5000ca89637/status_badge.svg">
  </a>
 <a href="https://www.buymeacoffee.com/gQyz2MR">
    <img alt="Buy me a coffee" src="https://img.shields.io/badge/Donate-Buy%20Me%20A%20Coffee-yellow.svg">
  </a>
</p>

# File Picker
A package that allows you to use a native file explorer to pick single or multiple absolute file paths, with extensions filtering support.

## Currently supported features
* Load paths from **cloud files** (GDrive, Dropbox, iCloud)
* Load path from a **custom format** by providing a file extension (pdf, svg, zip, etc.)
* Load path from **multiple files** optionally, supplying a file extension
* Load path from **gallery**
* Load path from **audio**
* Load path from **video**
* Load path from **any** 
* Create a `File` or `List<File>` objects from **any** selected file(s)
* Supports desktop through **go-flutter** (MacOS, Windows, Linux) 

If you have any feature that you want to see in this package, please add it [here](https://github.com/miguelpruivo/plugins_flutter_file_picker/issues/99). 🎉

## Documentation
See the **[File Picker Wiki](https://github.com/miguelpruivo/flutter_file_picker/wiki)** for every detail on about how to install, setup and use it.

1. [Installation](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Installation)
2. [Setup](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup)
   * [Android](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup#android)
   * [iOS](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup#ios)
   * [Desktop (go-flutter)](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/Setup/_edit#desktop-go-flutter)
3. [API](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/api)
   * [Filters](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/API#filters)
   * [Methods](https://github.com/miguelpruivo/plugins_flutter_file_picker/wiki/API#methods)
4. [Example App](https://github.com/miguelpruivo/flutter_file_picker/blob/master/example/lib/src/file_picker_demo.dart)

## Usage
Quick simple usage example:

#### Single file
```
File file = await FilePicker.getFile();
```
#### Multiple files
```
List<File> files = await FilePicker.getMultiFile();
```
For full usage details refer to the **[Wiki](https://github.com/miguelpruivo/flutter_file_picker/wiki)** above.

## Example App
![Demo](https://github.com/miguelpruivo/plugins_flutter_file_picker/blob/master/example/example.gif)

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).



