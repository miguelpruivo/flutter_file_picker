import 'dart:async';
import 'dart:typed_data';

class PlatformFile {
  const PlatformFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
    this.readStream,
  });

  PlatformFile.fromMap(Map data, {this.readStream})
      : this.path = data['path'],
        this.name = data['name'],
        this.bytes = data['bytes'],
        this.size = data['size'];

  /// The absolute path for a cached copy of this file. It can be used to create a
  /// file instance with a descriptor for the given path.
  /// ```
  /// final File myFile = File(platformFile.path);
  /// ```
  /// On web this is always `null`. You should access `bytes` property instead.
  /// Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
  final String? path;

  /// File name including its extension.
  final String name;

  /// Byte data for this file. Particurlarly useful if you want to manipulate its data
  /// or easily upload to somewhere else.
  /// [Check here in the FAQ](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ) an example on how to use it to upload on web.
  final Uint8List? bytes;

  /// File content as stream
  final Stream<List<int>>? readStream;

  /// The file size in bytes.
  final int size;

  /// File extension for this file.
  String? get extension => name.split('.').last;
}
