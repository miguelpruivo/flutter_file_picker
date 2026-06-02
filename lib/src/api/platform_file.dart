import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

import 'android_saf_handle.dart';
import '../file_picker_utils.dart';
import '../platform/file_picker_platform_interface.dart';
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
    this.persistentIdentifier,
  });

  factory PlatformFile.fromMap(Map data, {Stream<List<int>>? readStream}) {
    final file = PlatformFile(
      name: data['name'],
      path: data['path'],
      bytes: data['bytes'],
      size: data['size'],
      identifier: data['identifier'],
      persistentIdentifier: data['persistentIdentifier'],
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
  /// This property may be `null` when the picker is configured to avoid creating
  /// a cached copy and instead return a persistent platform reference.
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
  /// This property may be `null` in the following cases:
  /// - On Web, where local file paths are not available (it may point to a Blob URL instead).
  /// - On Android/iOS, when the picker returns a persistent platform reference instead of a cached file copy.
  ///
  /// Note: You can't use this to create a Dart `File` instance since this is a safe-reference for the original platform files, for
  /// that the [path] property should be used instead.
  final String? identifier;

  /// A platform-specific identifier that can be stored and later resolved to
  /// regain access to the original file without relying on a cached copy.
  ///
  /// - Android: usually the same persistable `content://` URI returned in
  ///   [identifier].
  /// - iOS: a base64-encoded security-scoped bookmark.
  final String? persistentIdentifier;

  /// File extension for this file.
  String? get extension => name.split('.').last;

  /// Retrieves this as a XFile
  XFile get xFile {
    if (kIsWeb) {
      return XFile.fromData(bytes!, name: name, length: size);
    }

    if (path != null) {
      return XFile(path!, name: name, bytes: bytes, length: size);
    }

    if (bytes != null) {
      return XFile.fromData(bytes!, name: name, length: size);
    }

    throw StateError(
      'PlatformFile.xFile is unavailable because there is no local path or in-memory data. '
      'Use readAsBytes() or readAsByteStream() instead.',
    );
  }

  /// Read the file content as bytes.
  ///
  /// For large files, prefer [readAsByteStream] to avoid Out Of Memory (OOM)
  /// issues.
  Future<Uint8List> readAsBytes() async {
    if (bytes != null) return bytes!;

    if (!kIsWeb && path != null) {
      final localBytes = await FilePickerUtils.readBytesFromFile(path);
      if (localBytes != null) {
        return localBytes;
      }
    }

    if (kIsWeb) {
      final fetchedBytes = await fetchBytesFromWebPath(path);
      if (fetchedBytes != null) return fetchedBytes;
    }

    if (!kIsWeb && _hasPlatformIdentifier()) {
      return FilePickerPlatform.instance.readFileAsBytes(
        identifier: identifier,
        persistentIdentifier: persistentIdentifier,
      );
    }

    throw StateError(
      'PlatformFile.readAsBytes(): file data is not available. '
      'Consume the file via PlatformFile.readAsByteStream(), restore it via '
      'FilePicker.restorePersistentFile(), or on Web ensure the file path is a '
      'fetchable blob/data URL that can be retrieved.',
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

    if (path == null && _hasPlatformIdentifier()) {
      yield* FilePickerPlatform.instance.readFileAsStream(
        identifier: identifier,
        persistentIdentifier: persistentIdentifier,
      );
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

  bool _hasPlatformIdentifier() =>
      identifier != null || persistentIdentifier != null;

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
        other.persistentIdentifier == persistentIdentifier &&
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
            persistentIdentifier,
            size,
          );
  }

  @override
  String toString() {
    return 'PlatformFile(${kIsWeb ? '' : 'path $path, '}name: $name, bytesLength: ${bytes?.lengthInBytes}, readStream: ${readStream != null}, identifier: $identifier, persistentIdentifier: ${persistentIdentifier != null}, size: $size)';
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
        persistentIdentifier: file.persistentIdentifier,
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
    return 'AndroidPlatformFile(${kIsWeb ? '' : 'path $path, '}name: $name, bytesLength: ${bytes?.lengthInBytes}, readStream: ${readStream != null}, identifier: $identifier, persistentIdentifier: ${persistentIdentifier != null}, size: $size, safHandle: $safHandle)';
  }
}
