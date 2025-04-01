import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilePickerDemo extends StatefulWidget {
  @override
  _FilePickerDemoState createState() => _FilePickerDemoState();
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _defaultFileNameController = TextEditingController();
  final _dialogTitleController = TextEditingController();
  final _initialDirectoryController = TextEditingController();
  final _fileExtensionController = TextEditingController();
  String? _fileName;
  String? _saveAsFileName;
  List<PlatformFile>? _paths;
  String? _directoryPath;
  String? _extension;
  bool _isLoading = false;
  bool _lockParentWindow = false;
  bool _userAborted = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.any;

  @override
  void initState() {
    super.initState();
    _fileExtensionController
        .addListener(() => _extension = _fileExtensionController.text);
  }

  void _pickFiles() async {
    _resetState();
    try {
      _directoryPath = null;
      _paths = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: _multiPick,
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
        withData: true,
      ))
          ?.files;
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _fileName =
          _paths != null ? _paths!.map((e) => e.name).toString() : '...';
      _userAborted = _paths == null;
    });
  }

  void _clearCachedFiles() async {
    _resetState();
    try {
      bool? result = await FilePicker.platform.clearTemporaryFiles();
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            (result!
                ? 'Temporary files removed with success.'
                : 'Failed to clean temporary files'),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectFolder() async {
    _resetState();
    try {
      String? path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      );
      setState(() {
        _directoryPath = path;
        _userAborted = path == null;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFile() async {
    try {
      String? fileName = await FilePicker.platform.saveFile(
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        type: _pickingType,
        dialogTitle: _dialogTitleController.text,
        fileName: _defaultFileNameController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
        bytes: _paths?.first.bytes,
      );
      setState(() {
        _saveAsFileName = fileName;
        _userAborted = fileName == null;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      _resetState();
      setState(() => _isLoading = false);
    }
  }

  void _logException(String message) {
    print(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _directoryPath = null;
      _fileName = null;
      _paths = null;
      _saveAsFileName = null;
      _userAborted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.deepPurple,
        ),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('File Picker example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Configuration',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    SizedBox(
                      width: 400,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Dialog Title',
                        ),
                        controller: _dialogTitleController,
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Initial Directory',
                        ),
                        controller: _initialDirectoryController,
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Default File Name',
                        ),
                        controller: _defaultFileNameController,
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: DropdownButtonFormField<FileType>(
                        value: _pickingType,
                        icon: const Icon(Icons.expand_more),
                        alignment: Alignment.centerLeft,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: FileType.values
                            .map(
                              (fileType) => DropdownMenuItem<FileType>(
                                child: Text(fileType.toString()),
                                value: fileType,
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(
                          () {
                            _pickingType = value!;
                            if (_pickingType != FileType.custom) {
                              _fileExtensionController.text = _extension = '';
                            }
                          },
                        ),
                      ),
                    ),
                    _pickingType == FileType.custom
                        ? SizedBox(
                            width: 400,
                            child: TextFormField(
                              decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'File Extension',
                                  hintText: 'jpg, png, gif'),
                              autovalidateMode: AutovalidateMode.always,
                              controller: _fileExtensionController,
                              keyboardType: TextInputType.text,
                              maxLength: 15,
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  direction: Axis.horizontal,
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    SizedBox(
                      width: 400.0,
                      child: SwitchListTile.adaptive(
                        title: Text(
                          'Lock parent window',
                          textAlign: TextAlign.left,
                        ),
                        onChanged: (bool value) =>
                            setState(() => _lockParentWindow = value),
                        value: _lockParentWindow,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(width: 400.0),
                      child: SwitchListTile.adaptive(
                        title: Text(
                          'Pick multiple files',
                          textAlign: TextAlign.left,
                        ),
                        onChanged: (bool value) =>
                            setState(() => _multiPick = value),
                        value: _multiPick,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Divider(),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  'Actions',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: <Widget>[
                      SizedBox(
                        width: 120,
                        child: FloatingActionButton.extended(
                            onPressed: () => _pickFiles(),
                            label:
                                Text(_multiPick ? 'Pick files' : 'Pick file'),
                            icon: const Icon(Icons.description)),
                      ),
                      SizedBox(
                        width: 120,
                        child: FloatingActionButton.extended(
                          onPressed: () => _selectFolder(),
                          label: const Text('Pick folder'),
                          icon: const Icon(Icons.folder),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: FloatingActionButton.extended(
                          onPressed: () => _saveFile(),
                          label: const Text('Save file'),
                          icon: const Icon(Icons.save_as),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: FloatingActionButton.extended(
                          onPressed: () => _clearCachedFiles(),
                          label: const Text('Clear temporary files'),
                          icon: const Icon(Icons.delete_forever),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  'File Picker Result',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Builder(
                  builder: (BuildContext context) => _isLoading
                      ? Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40.0,
                                  ),
                                  child: const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _userAborted
                          ? Row(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: 300,
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.error_outline,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 40.0),
                                        title: const Text(
                                          'User has aborted the dialog',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _directoryPath != null
                              ? ListTile(
                                  title: const Text('Directory path'),
                                  subtitle: Text(_directoryPath!),
                                )
                              : _paths != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20.0,
                                      ),
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.50,
                                      child: Scrollbar(
                                          child: ListView.separated(
                                        itemCount:
                                            _paths != null && _paths!.isNotEmpty
                                                ? _paths!.length
                                                : 1,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          final bool isMultiPath =
                                              _paths != null &&
                                                  _paths!.isNotEmpty;
                                          final String name = 'File $index: ' +
                                              (isMultiPath
                                                  ? _paths!
                                                      .map((e) => e.name)
                                                      .toList()[index]
                                                  : _fileName ?? '...');
                                          final path = kIsWeb
                                              ? null
                                              : _paths!
                                                  .map((e) => e.path)
                                                  .toList()[index]
                                                  .toString();

                                          return ListTile(
                                            title: Text(
                                              name,
                                            ),
                                            subtitle: Text(path ?? ''),
                                          );
                                        },
                                        separatorBuilder:
                                            (BuildContext context, int index) =>
                                                const Divider(),
                                      )),
                                    )
                                  : _saveAsFileName != null
                                      ? ListTile(
                                          title: const Text('Save file'),
                                          subtitle: Text(_saveAsFileName!),
                                        )
                                      : const SizedBox(),
                ),
                SizedBox(
                  height: 40.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
