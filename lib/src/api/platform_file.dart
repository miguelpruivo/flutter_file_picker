import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

import 'android_saf_handle.dart';

class PlatformFile {
  PlatformFile({
    this.path,
    required this.name,
    required this.size,
    this.bytes,
    this.readStream,
    this.identifier,
  });

  factory PlatformFile.fromMap(Map data, {Stream<List<int>>? readStream}) {
    final file = PlatformFile(
      name: data['name'],
      path: data['path'],
      bytes: data['bytes'],
      size: data['size'],
      identifier: data['identifier'],
      readStream: readStream,
    );

    if (data.containsKey('safHandle') && data['safHandle'] != null) {
      return AndroidPlatformFile(
        file: file,
        safHandle: AndroidSAFHandle.fromMap(
            Map<String, dynamic>.from(data['safHandle'])),
      );
    }

    return file;
  }

  /// The absolute path for a cached copy of this file. It can be used to create a
  /// file instance with a descriptor for the given path.
  /// ```
  /// final File myFile = File(platformFile.path);
  /// ```
  /// On web the path points to a Blob URL, if present, which can be cleaned up using [URL.revokeObjectURL](https://pub.dev/documentation/web/latest/web/URL/revokeObjectURL.html).
  /// Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
  final String? path;

  /// File name including its extension.
  final String name;

  /// Byte data for this file. Particularly useful if you want to manipulate its data
  /// or easily upload to somewhere else.
  /// [Check here in the FAQ](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ) an example on how to use it to upload on web.
  final Uint8List? bytes;

  /// File content as stream
  final Stream<List<int>>? readStream;

  /// The file size in bytes. Defaults to `0` if the file size could not be
  /// determined.
  final int size;

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
        other.path == path &&
        other.name == name &&
        other.bytes == bytes &&
        other.readStream == readStream &&
        other.identifier == identifier &&
        other.size == size;
  }

  @override
  int get hashCode {
    return kIsWeb
        ? 0
        : Object.hash(
            path,
            name,
            bytes,
            readStream,
            identifier,
            size,
          );
  }

  @override
  String toString() {
    return 'PlatformFile(${kIsWeb ? '' : 'path $path'}, name: $name, bytes: $bytes, readStream: $readStream, size: $size)';
  }
}

/// A [PlatformFile] implementation that includes a handle to a Android's Storage Access Framework document URI.
/// specifics, returned when picking files on Android 10+ with SAF options enabled.
class AndroidPlatformFile extends PlatformFile {
  AndroidPlatformFile({
    required PlatformFile file,
    required this.safHandle,
  }) : super(
          path: file.path,
          name: file.name,
          size: file.size,
          bytes: file.bytes,
          readStream: file.readStream,
          identifier: file.identifier,
        );

  /// The handle to the Storage Access Framework URI.
  /// Available if `AndroidSAFOptions` enabled `grant: AndroidSAFGrant.persist`.
  final AndroidSAFHandle safHandle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AndroidPlatformFile) return false;
    return super == other && other.safHandle == safHandle;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, safHandle);

  @override
  String toString() {
    return 'AndroidPlatformFile(${kIsWeb ? '' : 'path $path'}, name: $name, bytes: $bytes, readStream: $readStream, size: $size, safHandle: $safHandle)';
  }
}
