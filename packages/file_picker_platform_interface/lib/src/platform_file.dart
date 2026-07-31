import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

/// The abstract representation of a picked file on the current platform.
abstract base class PlatformFile {
  /// The name of the underlying file, including the extension.
  String get name;

  /// An [Uri] to the underlying file.
  Uri get uri;

  /// The local file path of the underlying file, or `null` if not on local disk.
  String? get path => uri.scheme == 'file' ? uri.toFilePath() : null;

  /// Get this file as an [XFile].
  XFile get xFile;

  /// Get the length of the file in bytes.
  Future<int> length();

  /// Read the bytes of the file as a single chunk.
  Future<Uint8List> readAsBytes();

  /// Read the file content as a stream of bytes.
  Stream<Uint8List> readAsByteStream();
}
