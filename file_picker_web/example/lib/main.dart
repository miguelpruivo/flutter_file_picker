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
                      itemBuilder: (BuildContext context, int index) {
                        return Row(
                            children: [
                              Text(_files[index].name),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: 150,
                                  maxHeight: 150,
                                ),
                                padding: EdgeInsets.all(8.0),
                                child: _files[index].type.contains('image') 
                                  ?  FutureBuilder<List<int>>(
                                      future: _files[index].fileAsBytes(),
                                      builder: (context, snapshot) => snapshot.hasData 
                                        ?  Image.memory(snapshot.data) 
                                        : CircularProgressIndicator()
                                    )
                                  : Icon(Icons.insert_drive_file, size: 100,),
                              )
                            ],
                          );
                      },  
                      itemCount: _files.length,
                      separatorBuilder: (_, __) => const Divider(
                        thickness: 2.0,
                      ),
                    )
                  // ? Image.memory(image)
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
