import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

import 'android_saf_handle.dart';
import '../platform_file_web_fetch_stub.dart'
    if (dart.library.js_interop) '../platform_file_web_fetch.dart';

/// Represents a file returned by the file picker.
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

    if (data case {'safHandle': final Map<Object?, Object?> safHandle}) {
      return AndroidPlatformFile(
        file: file,
        safHandle: AndroidSAFHandle.fromMap(safHandle),
      );
    }

    return file;
  }

  /// The absolute path for a cached copy of this file.
  final String? path;

  /// File name including its extension.
  final String name;

  /// Byte data for this file.
  @Deprecated(
    'Use readAsBytes() instead to avoid out-of-memory issues with large files.',
  )
  final Uint8List? bytes;

  /// File content as a stream of bytes.
  @Deprecated('Use readAsByteStream() instead')
  final Stream<List<int>>? readStream;

  /// The file size in bytes.
  final int size;

  /// The platform identifier for the original file.
  final String? identifier;

  /// File extension for this file.
  String? get extension => name.split('.').last;

  /// Retrieves this as a XFile
  XFile get xFile {
    if (kIsWeb && bytes != null) {
      return XFile.fromData(bytes!, name: name, length: size);
    } else {
      return XFile(path!, name: name, bytes: bytes, length: size);
    }
  }

  /// Read the file content as bytes.
  Future<Uint8List> readAsBytes() async {
    if (bytes != null) return bytes!;

    if (readStream != null) {
      final builder = BytesBuilder();
      await for (final chunk in readStream!) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    }

    if (kIsWeb) {
      final fetchedBytes = await fetchBytesFromWebPath(path);
      if (fetchedBytes != null) return fetchedBytes;
    } else if (path != null) {
      return xFile.readAsBytes();
    }

    throw StateError(
      'PlatformFile.readAsBytes(): file data is not available. '
      'Consume the file via PlatformFile.readAsByteStream(), or on Web ensure '
      'the file path is a fetchable blob/data URL that can be retrieved.',
    );
  }

  /// Read the file content as a stream of bytes.
  Stream<Uint8List> readAsByteStream() async* {
    if (kIsWeb) {
      final stream = fetchStreamFromWebPath(path);
      if (stream != null) {
        yield* stream;
        return;
      }

      yield await readAsBytes();
      return;
    }

    yield* xFile.openRead();
  }

  /// Returns the length of the file in bytes.
  Future<int> length() async {
    if (size > 0) return size;
    try {
      return await xFile.length();
    } catch (_) {
      return bytes?.lengthInBytes ?? 0;
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
        : Object.hash(path, name, bytes, readStream, identifier, size);
  }

  @override
  String toString() {
    return 'PlatformFile(${kIsWeb ? '' : 'path $path'}, name: $name, bytesLength: ${bytes?.lengthInBytes}, readStream: ${readStream != null}, size: $size)';
  }
}

/// A [PlatformFile] implementation that includes a handle to an Android Storage Access Framework URI.
class AndroidPlatformFile extends PlatformFile {
  AndroidPlatformFile({required PlatformFile file, required this.safHandle})
    : super(
        path: file.path,
        name: file.name,
        size: file.size,
        bytes: file.bytes,
        readStream: file.readStream,
        identifier: file.identifier,
      );

  /// The handle to the Storage Access Framework URI.
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
    return 'AndroidPlatformFile(${kIsWeb ? '' : 'path $path'}, name: $name, bytesLength: ${bytes?.lengthInBytes}, readStream: ${readStream != null}, size: $size, safHandle: $safHandle)';
  }
}
