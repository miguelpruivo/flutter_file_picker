import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

import 'android_saf_handle.dart';
import '../platform/web/platform_file_web_fetch_stub.dart'
    if (dart.library.js_interop) '../platform/web/platform_file_web_fetch.dart';

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

  /// The absolute path for a cached copy of this file. It can be used to create a
  /// file instance with a descriptor for the given path.
  /// ```
  /// final File myFile = File(platformFile.path);
  /// ```
  ///
  /// This property is `null` on Android, when using SAF without caching enabled.
  ///
  /// On the web this may or may not point to a Blob URL, which can be cleaned up using [URL.revokeObjectURL](https://pub.dev/documentation/web/latest/web/URL/revokeObjectURL.html).
  /// Read more about it [here](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ)
  final String? path;

  /// File name including its extension.
  final String name;

  /// Byte data for this file. Particularly useful if you want to manipulate its data
  /// or easily upload to somewhere else.
  ///
  /// This property is `null` unless [FilePicker.pickFiles] (or `pickFile`) was called with
  /// `withData: true`. Enabling this on mobile platforms for large files may lead to
  /// Out Of Memory (OOM) issues; use [readStream] instead.
  ///
  /// [Check here in the FAQ](https://github.com/miguelpruivo/flutter_file_picker/wiki/FAQ) an example on how to use it to upload on web.
  @Deprecated(
    'Use readAsBytes() instead to avoid out-of-memory issues with large files.',
  )
  final Uint8List? bytes;

  /// File content as a stream of bytes.
  ///
  /// This property is `null` unless [FilePicker.pickFiles] (or `pickFile`) was called with
  /// `withReadStream: true`. This is the recommended way to handle large files on
  /// mobile and desktop platforms.
  @Deprecated('Use readAsByteStream() instead')
  final Stream<List<int>>? readStream;

  /// The file size in bytes. Defaults to `0` if the file size could not be
  /// determined.
  final int size;

  /// The platform identifier for the original file, refers to an [Uri](https://developer.android.com/reference/android/net/Uri) on Android and
  /// to a [NSURL](https://developer.apple.com/documentation/foundation/nsurl) on iOS.
  /// Is set to `null` on all other platforms since those are all already referencing the original file content.
  ///
  /// This property is `null` in the following cases:
  /// - On Web, where local file paths are not available (it may point to a Blob URL instead).
  /// - On Android, when picking a directory or using SAF without caching enabled.
  ///
  /// Note: You can't use this to create a Dart `File` instance since this is a safe-reference for the original platform files, for
  /// that the [path] property should be used instead.
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
  ///
  /// For large files, prefer [readAsByteStream] to avoid Out Of Memory (OOM)
  /// issues.
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
  ///
  /// Preferred for large files or incremental processing.
  ///
  /// Web behavior:
  /// - When the browser/WebView exposes Fetch `ReadableStream` (`Response.body`)
  ///   this method streams chunks from a `blob:` URL without buffering the
  ///   entire file in memory.
  /// - If streaming is unavailable (older WebViews/browsers), it falls back to
  ///   loading the whole file via `arrayBuffer()` and emits a single
  ///   `Uint8List` chunk — which may cause high memory usage for large files.
  ///
  /// Recommendations:
  /// - Use `readAsBytes()` for small files and `readAsByteStream()` for large
  ///   files when streaming is available.
  /// - For environments without streaming support (older WebViews), consider
  ///   server-side streaming/upload strategies to avoid high memory usage.
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
  ///
  /// Note: on Web, `xFile.length()` depends on the underlying `XFile` implementation
  /// and may require `withData: true` when using `XFile.fromData` — in that case the
  /// fallback to `bytes` will be used.
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

/// A [PlatformFile] implementation that includes a handle to a Android's Storage Access Framework document URI.
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
