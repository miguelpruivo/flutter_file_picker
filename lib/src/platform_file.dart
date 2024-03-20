import 'dart:async';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

class PlatformFile {
  PlatformFile({
    String? path,
    required this.name,
    required this.size,
    this.lastModified,
    this.bytes,
    this.readStream,
    this.identifier,
  }) : _path = path;

  factory PlatformFile.fromMap(Map data, {Stream<Uint8List> Function([int? start, int? end])? readStream}) {
    return PlatformFile(
      name: data['name'],
      path: data['path'],
      bytes: data['bytes'],
      size: data['size'],
      lastModified: data['lastModified'],
      identifier: data['identifier'],
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
      On web `path` is unavailable and accessing it causes this exception.
      You should access `bytes` property instead,
      Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
      ''';
    }
    return _path;
  }

  /// File name including its extension.
  final String name;

  /// Byte data for this file. Particularly useful if you want to manipulate its data
  /// or easily upload to somewhere else.
  /// [Check here in the FAQ](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ) an example on how to use it to upload on web.
  final Uint8List? bytes;

  /// File content as stream
  final Stream<Uint8List> Function([int? start, int? end])? readStream;

  /// The file size in bytes. Defaults to `0` if the file size could not be
  /// determined.
  final int size;

  /// Last modified for this file.
  final DateTime? lastModified;

  /// The platform identifier for the original file, refers to an [Uri](https://developer.android.com/reference/android/net/Uri) on Android and
  /// to a [NSURL](https://developer.apple.com/documentation/foundation/nsurl) on iOS.
  /// Is set to `null` on all other platforms since those are all already referencing the original file content.
  ///
  /// Note: You can't use this to create a Dart `File` instance since this is a safe-reference for the original platform files, for
  /// that the [path] property should be used instead.
  final String? identifier;

  /// File extension for this file.
  String? get extension => name.split('.').last;

  /// Retrieves this as a XFile
  XFile get xFile {
    if (kIsWeb) {
      return XFile.fromData(bytes!, name: name, length: size);
    } else {
      return XFile(path!, name: name, bytes: bytes, length: size);
    }
  }

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
        other.identifier == identifier &&
        other.size == size &&
        other.lastModified == lastModified;
  }

  @override
  int get hashCode {
    return kIsWeb
        ? 0
        : path.hashCode ^
            name.hashCode ^
            bytes.hashCode ^
            readStream.hashCode ^
            identifier.hashCode ^
            size.hashCode ^
            lastModified.hashCode;
  }

  @override
  String toString() {
    return 'PlatformFile(${kIsWeb ? '' : 'path $path'}, name: $name, lastModified: $lastModified, bytes: $bytes, readStream: $readStream, size: $size)';
  }
}
