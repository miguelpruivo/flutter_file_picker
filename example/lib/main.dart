import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(new FilePickerDemo());

class FilePickerDemo extends StatefulWidget {
  @override
  _FilePickerDemoState createState() => new _FilePickerDemoState();
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  String _fileName;
  String _path;
  Map<String, String> _paths;
  String _extension;
  bool _multiPick = false;
  bool _hasValidMime = false;
  FileType _pickingType;
  TextEditingController _controller = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _extension = _controller.text);
  }

  void _openFileExplorer() async {
    if (_pickingType != FileType.CUSTOM || _hasValidMime) {
      try {
        if (_pickingType == FileType.DIRECTORY_ONLY) {
          _path = await FilePicker.getDirectoryPath();
          print("PATH: " + _path);
        } else if (_multiPick) {
          _path = null;
          _paths = await FilePicker.getMultiFilePath(fileExtension: _extension);
        } else {
          _paths = null;
          _path = await FilePicker.getFilePath(type: _pickingType, fileExtension: _extension);
        }
      } on PlatformException catch (e) {
        print("Unsupported operation" + e.toString());
      }
      if (!mounted) return;

      setState(() {
        _fileName = _path != null ? _path.split('/').last : _paths != null ? _paths.keys.toString() : '...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('File Picker example app'),
        ),
        body: SingleChildScrollView(
          child: new Center(
              child: new Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 10.0, right: 10.0),
            child: new ConstrainedBox(
              constraints: new BoxConstraints(maxWidth: 200.0),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: new DropdownButton(
                        hint: new Text('LOAD PATH FROM'),
                        value: _pickingType,
                        items: <DropdownMenuItem>[
                          new DropdownMenuItem(
                            child: new Text('FROM AUDIO'),
                            value: FileType.AUDIO,
                          ),
                          new DropdownMenuItem(
                            child: new Text('FROM GALLERY'),
                            value: FileType.IMAGE,
                          ),
                          new DropdownMenuItem(
                            child: new Text('FROM VIDEO'),
                            value: FileType.VIDEO,
                          ),
                          new DropdownMenuItem(
                            child: new Text('FROM ANY'),
                            value: FileType.ANY,
                          ),
                          new DropdownMenuItem(
                            child: new Text('CUSTOM FORMAT'),
                            value: FileType.CUSTOM,
                          ),
                          new DropdownMenuItem(
                            child: new Text('DIRECTORY ONLY'),
                            value: FileType.DIRECTORY_ONLY,
                          ),
                        ],
                        onChanged: (value) => setState(() {
                              _pickingType = value;
                              if (_pickingType != FileType.CUSTOM && _pickingType != FileType.ANY) {
                                _multiPick = false;
                              }
                              if (_pickingType != FileType.CUSTOM) {
                                _controller.text = _extension = '';
                              }
                            })),
                  ),
                  _pickingType == FileType.CUSTOM
                      ? new TextFormField(
                          maxLength: 20,
                          autovalidate: true,
                          controller: _controller,
                          decoration: InputDecoration(labelText: 'File type'),
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            RegExp reg = new RegExp(r'[^a-zA-Z0-9]');
                            if (reg.hasMatch(value)) {
                              _hasValidMime = false;
                              return 'Invalid format';
                            }
                            _hasValidMime = true;
                          },
                        )
                      : new Container(),
                  new Visibility(
                    visible: _pickingType == FileType.ANY || _pickingType == FileType.CUSTOM,
                    child: new SwitchListTile.adaptive(
                      title: new Text('Pick multiple files', textAlign: TextAlign.right),
                      onChanged: (bool value) => setState(() => _multiPick = value),
                      value: _multiPick,
                    ),
                  ),
                  new Padding(
                    padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
                    child: new RaisedButton(
                      onPressed: () => _openFileExplorer(),
                      child: new Text("Open file picker"),
                    ),
                  ),
                  new Text(
                    'URI PATH ',
                    textAlign: TextAlign.center,
                    style: new TextStyle(fontWeight: FontWeight.bold),
                  ),
                  new Text(
                    _path ?? ((_paths != null && _paths.isNotEmpty) ? _paths.values.map((path) => path + '\n\n').toString() : '...'),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    textScaleFactor: 0.85,
                  ),
                  new Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: new Text(
                      'FILE NAME ',
                      textAlign: TextAlign.center,
                      style: new TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  new Text(
                    _fileName ?? '...',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }
}
