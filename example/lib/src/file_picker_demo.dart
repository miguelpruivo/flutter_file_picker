// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'package:file/local.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'file_picker_results.dart';
import 'picked_directory_result.dart';
import 'picked_files_results.dart';

class FilePickerDemo extends StatefulWidget {
  const FilePickerDemo({super.key});

  @override
  State<FilePickerDemo> createState() => _FilePickerDemoState();
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _defaultFileNameController = TextEditingController();
  final _dialogTitleController = TextEditingController();
  final _initialDirectoryController = TextEditingController();
  final _fileExtensionController = TextEditingController();
  String? _extension;
  bool _isLoading = false;
  bool _lockParentWindow = false;
  bool _userAborted = false;
  bool _multiPick = false;
  bool _withData = true;
  bool _safPersist = false;
  bool _safReadWrite = false;
  bool _supportsSafOptions = false;
  FileType _pickingType = FileType.any;
  List<PlatformFile>? pickedFiles;
  Widget _resultsWidget = const Row(
    children: [
      Expanded(
        child: Center(
          child: SizedBox(
            width: 300,
            child: ListTile(
              leading: Icon(Icons.error_outline),
              contentPadding: EdgeInsets.symmetric(vertical: 40.0),
              title: Text('No action taken yet'),
              subtitle: Text(
                'Please use on one of the buttons above to get started',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _fileExtensionController.addListener(
      () => _extension = _fileExtensionController.text,
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _supportsSafOptions = true;
    }
  }

  @override
  void dispose() {
    _defaultFileNameController.dispose();
    _dialogTitleController.dispose();
    _initialDirectoryController.dispose();
    _fileExtensionController.dispose();
    super.dispose();
  }

  void _pickFiles() async {
    bool hasUserAborted = true;
    _resetState();

    try {
      final result = await FilePicker.pickFiles(
        type: _pickingType,
        allowMultiple: _multiPick,
        onFileLoading: (FilePickerStatus status) => setState(() {
          _isLoading = status == FilePickerStatus.picking;
        }),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
        withData: _withData,
        androidSafOptions: (_safPersist || _safReadWrite)
            ? AndroidSAFOptions(
                grant: _safPersist
                    ? AndroidSAFGrant.lifetime
                    : AndroidSAFGrant.transient,
                accessMode: _safReadWrite
                    ? AndroidSAFAccessMode.readWrite
                    : AndroidSAFAccessMode.readOnly,
              )
            : null,
      );
      printInDebug("pickedFiles: $result");
      pickedFiles = result?.files;
      hasUserAborted = pickedFiles == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;

      void updateResults() {
        _resultsWidget = PickedFilesResults(
          pickedFiles: pickedFiles,
          onRemoveAndroidFile:
              (int index, AndroidPlatformFile androidPlatformFile) {
                androidPlatformFile.safHandle.releaseGrant();
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text("SAF Permission Released!")),
                );
                setState(() {
                  pickedFiles!.removeAt(index);
                  updateResults();
                });
              },
        );
      }

      updateResults();
    });
  }

  void _pickFileAndDirectoryPaths() async {
    List<String>? pickedFilesAndDirectories;
    bool hasUserAborted = true;
    _resetState();

    try {
      pickedFilesAndDirectories = await FilePicker.pickFileAndDirectoryPaths(
        dialogTitle: _dialogTitleController.text,
        type: _pickingType,
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        initialDirectory: _initialDirectoryController.text,
      );
      hasUserAborted = pickedFilesAndDirectories == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;
      _resultsWidget = FilePickerResultsList(
        itemCount: pickedFilesAndDirectories?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          String name = 'File path:';
          if (!kIsWeb) {
            final fs = LocalFileSystem();
            name = fs.isFileSync(pickedFilesAndDirectories![index])
                ? 'File path:'
                : 'Directory path:';
          }
          return ListTile(
            leading: Text(
              index.toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            title: Text(name),
            subtitle: Text(pickedFilesAndDirectories![index]),
          );
        },
      );
    });
  }

  void _clearCachedFiles() async {
    pickedFiles = [];
    _resetState();
    try {
      bool? result = await FilePicker.clearTemporaryFiles();
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            (result!
                ? 'Temporary files removed with success.'
                : 'Failed to clean temporary files'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _selectFolder() async {
    String? pickedDirectoryPath;
    bool hasUserAborted = true;
    _resetState();

    try {
      pickedDirectoryPath = await FilePicker.getDirectoryPath(
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
        androidSafOptions: (_safPersist || _safReadWrite)
            ? AndroidSAFOptions(
                grant: _safPersist
                    ? AndroidSAFGrant.lifetime
                    : AndroidSAFGrant.transient,
                accessMode: _safReadWrite
                    ? AndroidSAFAccessMode.readWrite
                    : AndroidSAFAccessMode.readOnly,
              )
            : null,
      );
      hasUserAborted = pickedDirectoryPath == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;
      void updateResults() {
        _resultsWidget = PickedDirectoryResult(
          pickedDirectoryPath: pickedDirectoryPath,
          readWriteAccess: _safReadWrite,
          onDirectoryRemoved: () {
            _scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text("SAF Permission Released!")),
            );
            setState(() {
              pickedDirectoryPath = null;
              updateResults();
            });
          },
        );
      }

      updateResults();
    });
  }

  Future<void> _saveFile() async {
    String? pickedSaveFilePath;
    bool hasUserAborted = true;
    _resetState();

    try {
      pickedSaveFilePath = await FilePicker.saveFile(
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        type: FileType.custom,
        dialogTitle: _dialogTitleController.text,
        fileName: _defaultFileNameController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
        bytes: pickedFiles?.first.bytes,
      );
      hasUserAborted = pickedSaveFilePath == null;
    } on PlatformException catch (e) {
      _logException('Unsupported operation: $e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _userAborted = hasUserAborted;
      _resultsWidget = FilePickerResultsList(
        itemCount: pickedSaveFilePath != null ? 1 : 0,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: const Text('Save file path:'),
            subtitle: Text(pickedSaveFilePath ?? ''),
          );
        },
      );
    });
  }

  void _logException(String message) {
    printInDebug(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _resetState() {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _userAborted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileTypeItems = <DropdownMenuItem<FileType>>[
      for (final fileType in FileType.values)
        DropdownMenuItem<FileType>(
          value: fileType,
          child: Text(fileType.toString()),
        ),
    ];

    final configurationFields = <Widget>[
      SizedBox(
        width: 400,
        child: TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Dialog Title',
          ),
          controller: _dialogTitleController,
        ),
      ),
      SizedBox(
        width: 400,
        child: TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Initial Directory',
          ),
          controller: _initialDirectoryController,
        ),
      ),
      SizedBox(
        width: 400,
        child: TextField(
          decoration: const InputDecoration(
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
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: fileTypeItems,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _pickingType = value;
                if (_pickingType != FileType.custom) {
                  _fileExtensionController.text = _extension = '';
                }
              });
            }
          },
        ),
      ),
      if (_pickingType == FileType.custom)
        SizedBox(
          width: 400,
          child: TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'File Extension',
              hintText: 'jpg, png, gif',
            ),
            autovalidateMode: AutovalidateMode.always,
            controller: _fileExtensionController,
            keyboardType: TextInputType.text,
            maxLength: 15,
          ),
        ),
    ];

    final optionsFields = <Widget>[
      SizedBox(
        width: 400.0,
        child: SwitchListTile.adaptive(
          title: const Text('Lock parent window', textAlign: TextAlign.left),
          onChanged: (value) => setState(() => _lockParentWindow = value),
          value: _lockParentWindow,
        ),
      ),
      ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 400.0),
        child: SwitchListTile.adaptive(
          title: const Text('Pick multiple files', textAlign: TextAlign.left),
          onChanged: (value) => setState(() => _multiPick = value),
          value: _multiPick,
        ),
      ),
      ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 400.0),
        child: SwitchListTile.adaptive(
          title: const Text('Load file data to memory (withData)'),
          subtitle: const Text(
            'Disable this for large or multiple files. Prefer withReadStream.',
          ),
          onChanged: (value) => setState(() => _withData = value),
          value: _withData,
        ),
      ),
      if (_multiPick && _withData)
        const SizedBox(
          width: 400.0,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.warning_amber_rounded, color: Colors.amber),
            title: Text('Large multi-picks may run out of memory'),
            subtitle: Text(
              'Use withData = false and withReadStream for safety.',
            ),
          ),
        ),
      ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 400.0),
        child: SwitchListTile.adaptive(
          title: const Text(
            'SAF Persist (Android 10+)',
            textAlign: TextAlign.left,
          ),
          onChanged: _supportsSafOptions
              ? (value) => setState(() => _safPersist = value)
              : null,
          value: _safPersist,
        ),
      ),
      ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 400.0),
        child: SwitchListTile.adaptive(
          title: const Text(
            'SAF ReadWrite (Android 10+)',
            textAlign: TextAlign.left,
          ),
          onChanged: _supportsSafOptions
              ? (value) => setState(() => _safReadWrite = value)
              : null,
          value: _safReadWrite,
        ),
      ),
    ];

    final actionButtons = <Widget>[
      SizedBox(
        width: 120,
        child: FloatingActionButton.extended(
          onPressed: _pickFiles,
          label: Text(_multiPick ? 'Pick files' : 'Pick file'),
          icon: const Icon(Icons.description),
        ),
      ),
      SizedBox(
        width: 120,
        child: FloatingActionButton.extended(
          onPressed: _selectFolder,
          label: const Text('Pick folder'),
          icon: const Icon(Icons.folder),
        ),
      ),
      SizedBox(
        width: 250,
        child: FloatingActionButton.extended(
          onPressed: _pickFileAndDirectoryPaths,
          label: const Text('Pick files and directories'),
          icon: const Icon(Icons.folder_open),
        ),
      ),
      SizedBox(
        width: 120,
        child: FloatingActionButton.extended(
          onPressed: _saveFile,
          label: const Text('Save file'),
          icon: const Icon(Icons.save_as),
        ),
      ),
      SizedBox(
        width: 200,
        child: FloatingActionButton.extended(
          onPressed: _clearCachedFiles,
          label: const Text('Clear temporary files'),
          icon: const Icon(Icons.delete_forever),
        ),
      ),
    ];

    final loadingIndicator = Row(
      children: const [
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );

    final userAbortedContent = Row(
      children: const [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 300,
              child: ListTile(
                leading: Icon(Icons.error_outline),
                contentPadding: EdgeInsets.symmetric(vertical: 40.0),
                title: Text('User has aborted the dialog'),
              ),
            ),
          ),
        ),
      ],
    );

    late final Widget resultsContent;
    if (_isLoading) {
      resultsContent = loadingIndicator;
    } else if (_userAborted) {
      resultsContent = userAbortedContent;
    } else {
      resultsContent = _resultsWidget;
    }

    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.deepPurple,
        ),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: const Text('File Picker example app')),
        body: Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Configuration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 20.0),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: configurationFields,
                ),
                const SizedBox(height: 20.0),
                Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  direction: Axis.horizontal,
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: optionsFields,
                ),
                const SizedBox(height: 20.0),
                const Divider(),
                const SizedBox(height: 20.0),
                const Text(
                  'Actions',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: actionButtons,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 20.0),
                const Text(
                  'File Picker Result',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                resultsContent,
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void printInDebug(Object object) => debugPrint(object.toString());
}
