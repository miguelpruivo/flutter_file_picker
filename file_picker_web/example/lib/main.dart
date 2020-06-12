// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:file_picker_web/file_picker_web.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<File> _files = [];

  void _pickFiles() async {
    _files = await FilePicker.getMultiFile() ?? [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _files.isNotEmpty
                    ? ListView.separated(
                        itemBuilder: (BuildContext context, int index) =>
                            Text(_files[index].name),
                        itemCount: _files.length,
                        separatorBuilder: (_, __) => const Divider(
                          thickness: 5.0,
                        ),
                      )
                    : Center(
                        child: Text(
                          'Pick some files',
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: RaisedButton(
                  onPressed: _pickFiles,
                  child: Text('Pick Files'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
