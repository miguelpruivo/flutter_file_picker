import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

import 'platform_file_web_fetch.dart';

/// A [PlatformFile] implementation for Web.
base class WebPlatformFile extends PlatformFile {
  WebPlatformFile({
    required this.name,
    required this.uri,
    XFile? xFile,
    int? bytesLength,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
  }) : _xFile = xFile,
       _bytesLength = bytesLength,
       _bytes = bytes,
       _readStream = readStream;

  @override
  final String name;

  @override
  final Uri uri;

  final XFile? _xFile;
  final int? _bytesLength;
  final Uint8List? _bytes;
  final Stream<List<int>>? _readStream;

  @override
  XFile get xFile {
    final file = _xFile;
    if (file != null) return file;
    return XFile(uri.toString(), name: name, bytes: _bytes);
  }

  @override
  Future<int> length() async {
    final len = _bytesLength;
    if (len != null && len > 0) return len;
    final bytes = _bytes;
    if (bytes != null) return bytes.length;
    try {
      return await xFile.length();
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Uint8List> readAsBytes() async {
    final bytes = _bytes;
    if (bytes != null) return bytes;

    // Try fetching from blob or data URL
    final fetched = await fetchBytesFromWebPath(uri.toString());
    if (fetched != null) return fetched;

    return xFile.readAsBytes();
  }

  @override
  Stream<Uint8List> readAsByteStream() async* {
    final readStream = _readStream;
    if (readStream != null) {
      await for (final chunk in readStream) {
        yield Uint8List.fromList(chunk);
      }
      return;
    }

    final webStream = fetchStreamFromWebPath(uri.toString());
    if (webStream != null) {
      yield* webStream;
      return;
    }

    yield* xFile.openRead();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebPlatformFile && other.name == name && other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(name, uri);

  @override
  String toString() {
    return 'WebPlatformFile(name: $name, uri: $uri)';
  }
}
