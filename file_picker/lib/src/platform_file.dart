import 'dart:typed_data';

class PlatformFile {
  PlatformFile({
    this.path,
    this.uri,
    this.name,
    this.bytes,
    this.size,
    this.isDirectory = false,
  });

  PlatformFile.fromMap(Map data)
      : this.path = data['path'],
        this.uri = data['uri'],
        this.name = data['name'],
        this.bytes = data['bytes'],
        this.size = data['size'],
        this.isDirectory = data['isDirectory'];

  /// The absolute path for a cached copy of this file.
  /// If you want to access the original file identifier use [uri] property instead.
  final String path;

  /// The URI (Universal Resource Identifier) for this file.
  ///
  /// This is the identifier of original resource and can be used to
  /// manipulate the original file (read, write, delete).
  ///
  /// Android: it can be either content:// or file:// url.
  /// iOS: a file:// URL below a document provider (like iCloud).
  /// Web: Not supported, will be always `null`.
  final String uri;

  /// File name including its extension.
  final String name;

  /// Byte data for this file. Particurlarly useful if you want to manipulate its data
  /// or easily upload to somewhere else.
  final Uint8List bytes;

  /// The file size in KB.
  final int size;

  /// Whether this file references a directory or not.
  final bool isDirectory;

  /// File extension for this file.
  String get extension => name.split('/').last;
}
