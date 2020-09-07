import 'dart:typed_data';

class PlatformFile {
  PlatformFile({
    this.path,
    this.uri,
    this.name,
    this.bytes,
    this.isDirectory = false,
  });

  /// The absolute path for this file instance.
  ///
  /// Typically whis will reflect a copy cached file and not the original source,
  /// also, it's not guaranteed that this path is always available as some files
  /// can be protected by OS.
  ///
  /// Available on IO only. On Web is always `null`.
  final String path;

  /// The URI (Universal Resource Identifier) for this file.
  ///
  /// This is the original file resource identifier and can be used to
  /// manipulate the original file (read, write, delete).
  ///
  /// Available on IO only. On Web is always `null`.
  final String uri;

  /// File name including its extension.
  final String name;

  /// Byte data for this file.
  final Uint8List bytes;

  /// Whether this file references a directory or not.
  final bool isDirectory;

  /// File extension for this file.
  String get extension => name.split('/').last;
}
