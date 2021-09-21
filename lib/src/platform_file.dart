import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class PlatformFile {
  PlatformFile({
    String? path,
    required this.name,
    required this.size,
    this.bytes,
    this.readStream,
  }) : _path = path;

  factory PlatformFile.fromMap(Map data, {Stream<List<int>>? readStream}) {
    return PlatformFile(
      name: data['name'],
      path: data['path'],
      bytes: data['bytes'],
      size: data['size'],
      readStream: readStream,
    );
  }

  /// The absolute path for a cached copy of this file. It can be used to create a
  /// file instance with a descriptor for the given path.
  /// ```
  /// final File myFile = File(platformFile.path);
  /// ```
  /// On web this is always `null`. You should access `bytes` property instead.
  /// Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
  String? _path;

  String? get path {
    if (kIsWeb) {
      /// https://github.com/miguelpruivo/flutter_file_picker/issues/751
      throw '''
      On web `path` is always `null`,
      You should access `bytes` property instead,
      Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
      ''';
    }
    return _path;
  }

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PlatformFile &&
        (kIsWeb || other.path == path) &&
        other.name == name &&
        other.bytes == bytes &&
        other.readStream == readStream &&
        other.size == size;
  }

  @override
  int get hashCode {
    return kIsWeb
        ? 0
        : path.hashCode ^
            name.hashCode ^
            bytes.hashCode ^
            readStream.hashCode ^
            size.hashCode;
  }

  @override
  String toString() {
    return 'PlatformFile(${kIsWeb ? '' : 'path $path'}, name: $name, bytes: $bytes, readStream: $readStream, size: $size)';
  }
}
