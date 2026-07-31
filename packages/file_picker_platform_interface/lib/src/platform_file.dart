import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

/// The abstract representation of a picked file on the current platform.
///
/// Depending on the current platform,
/// an implementation may provide additional properties or methods specific to that platform.
abstract base class PlatformFile {
  /// The name of the underlying file, including the extension.
  String get name;

  /// An [Uri] to the underlying file.
  ///
  /// Depending on the platform, this may point to a local file, a blob, a data URI, or a network resource.
  Uri get uri;

  /// The local file path of the underlying file, or `null` if the file is not on the local file system (e.g., on Web or content URIs).
  String? get path;

  /// Get this file as an [XFile].
  XFile get xFile;

  /// Get the length of the file in bytes.
  Future<int> length();

  /// Read the bytes of the file as a single chunk.
  ///
  /// Prefer [readAsByteStream] for large files.
  Future<Uint8List> readAsBytes();

  /// Read the file content as a stream of bytes.
  Stream<Uint8List> readAsByteStream();
}
