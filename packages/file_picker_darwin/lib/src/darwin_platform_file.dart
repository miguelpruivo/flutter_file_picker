import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

/// A [PlatformFile] implementation for Apple platforms (iOS and macOS).
base class DarwinPlatformFile extends PlatformFile {
  DarwinPlatformFile({
    required this.name,
    required this.uri,
    XFile? xFile,
    int? bytesLength,
  }) : _xFile = xFile,
       _bytesLength = bytesLength;

  factory DarwinPlatformFile.fromMap(Map<Object?, Object?> data) {
    final String name = data['name'] as String? ?? '';
    final String path = data['path'] as String? ?? '';
    final Uri uri = Uri.tryParse(path) ?? Uri.file(path);
    final Uint8List? bytes = data['bytes'] as Uint8List?;

    return DarwinPlatformFile(
      name: name,
      uri: uri,
      xFile: path.isNotEmpty ? XFile(path, name: name, bytes: bytes) : null,
      bytesLength: bytes?.lengthInBytes ?? (data['size'] as int?),
    );
  }

  @override
  final String name;

  @override
  final Uri uri;

  final XFile? _xFile;
  final int? _bytesLength;

  @override
  XFile get xFile {
    final file = _xFile;
    if (file != null) return file;
    if (uri.scheme == 'file') {
      return XFile(uri.toFilePath(), name: name);
    }
    return XFile(uri.toString(), name: name);
  }

  @override
  Future<int> length() async {
    final len = _bytesLength;
    if (len != null && len > 0) return len;
    try {
      return await xFile.length();
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Uint8List> readAsBytes() async {
    return xFile.readAsBytes();
  }

  @override
  Stream<Uint8List> readAsByteStream() {
    return xFile.openRead();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DarwinPlatformFile) return false;
    return super == other && other.name == name && other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, name, uri);

  @override
  String toString() {
    return 'DarwinPlatformFile(name: $name, uri: $uri)';
  }
}
