import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/src/api/android_saf_options.dart';
import 'package:file_picker/src/api/file_picker_result.dart';
import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:file_picker/src/api/platform_file.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart';

// ---------------------------------------------------------------------------
// JS interop for the File System Access API (showSaveFilePicker).
// Available in Chrome/Edge. Falls back to anchor download on other browsers.
// ---------------------------------------------------------------------------

@JS('showSaveFilePicker')
external JSPromise<JSAny?> _showSaveFilePickerJs(JSAny options);

extension type _FileHandle(JSObject _) implements JSObject {
  external JSPromise<JSAny?> createWritable();
}

extension type _WritableStream(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSAny data);
  external JSPromise<JSAny?> close();
}

// fetch() interop for reading bytes from a blob: URL.
@JS('fetch')
external JSPromise<JSObject> _fetchJs(JSString url);

extension type _Response(JSObject _) implements JSObject {
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

// ---------------------------------------------------------------------------
class FilePickerWeb extends FilePickerPlatform {
  late Element _target;
  final String _kFilePickerInputsDomId = '__file_picker_web-file-input';

  final int _readStreamChunkSize = 1000 * 1000; // 1 MB

  FilePickerWeb._() {
    _target = _ensureInitialized(_kFilePickerInputsDomId);
  }

  static void registerWith(Registrar registrar) {
    FilePickerPlatform.instance = FilePickerWeb._();
  }

  /// Initializes a DOM container where we can host input elements.
  Element _ensureInitialized(String id) {
    Element? target = document.querySelector('#$id');
    if (target == null) {
      final Element targetElement = document.createElement(
        'flt-file-picker-inputs',
      )..id = id;

      document.querySelector('body')!.children.add(targetElement);
      target = targetElement;
    }
    return target;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus)? onFileLoading,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    int compressionQuality = 0,
    AndroidSAFOptions? androidSafOptions,
  }) async {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
        'You are setting a type [$type]. Custom extension filters are only allowed with FileType.custom, please change it or remove filters.',
      );
    }

    Completer<List<PlatformFile>?>? filesCompleter =
        Completer<List<PlatformFile>?>();

    final uploadInput = HTMLInputElement()
      ..type = 'file'
      ..draggable = true
      ..multiple = allowMultiple
      ..accept = _fileType(type, allowedExtensions)
      ..style.display = 'none';

    bool changeEventTriggered = false;
    onFileLoading?.call(FilePickerStatus.picking);

    void changeEventListener(Event e) async {
      if (changeEventTriggered) return;
      changeEventTriggered = true;

      final files = uploadInput.files;
      if (files == null) {
        onFileLoading?.call(FilePickerStatus.done);
        filesCompleter?.complete(null);
        return;
      }

      final pickedFiles = await _buildPickedFiles(
        files,
        withData: withData,
        withReadStream: withReadStream,
        readSequential: readSequential,
      );

      onFileLoading?.call(FilePickerStatus.done);
      filesCompleter?.complete(pickedFiles);
    }

    void cancelledEventListener(Event _) {
      window.removeEventListener('focus', cancelledEventListener.toJS);

      // This listener is called before the input changed event,
      // and the `uploadInput.files` value is still null
      // Wait for results from js to dart
      Future.delayed(const Duration(seconds: 1)).then((value) {
        if (!changeEventTriggered) {
          changeEventTriggered = true;
          filesCompleter?.complete(null);
        }
      });
    }

    uploadInput.onChange.listen(changeEventListener);
    uploadInput.addEventListener('change', changeEventListener.toJS);
    uploadInput.addEventListener('cancel', cancelledEventListener.toJS);

    if (cancelUploadOnWindowBlur) {
      // Listen focus event for cancelled
      window.addEventListener('focus', cancelledEventListener.toJS);
    }

    _clearTarget();
    _target.children.add(uploadInput);
    uploadInput.click();

    _clearTarget();

    final List<PlatformFile>? files = await filesCompleter.future;
    filesCompleter = null;

    return files == null ? null : FilePickerResult(files);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    String? path,
    Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
  }) async {
    // Ensure the file name has an extension.
    final name = _ensureExtension(fileName, allowedExtensions);

    // Resolve bytes from the provided data or by fetching the blob/data URL.
    final resolvedBytes = await _resolveBytes(bytes, path);

    if (resolvedBytes == null) {
      throw ArgumentError('Either bytes or a valid blob:/data: path must be provided.');
    }

    final blob = Blob([resolvedBytes.toJS].toJS);

    // Try the native "Save As" picker (Chrome/Edge).
    // Returns true=saved, false=cancelled, null=unsupported.
    final pickerResult = await _trySaveWithPicker(blob, name);
    if (pickerResult == true) return name;
    if (pickerResult == false) return null;

    // Fallback: standard browser download.
    _downloadBlob(blob, name);
    return name;
  }

  // ---------------------------------------------------------------------------
  // saveFile helpers
  // ---------------------------------------------------------------------------

  /// Appends a single allowed extension when the file name has none.
  String _ensureExtension(String fileName, List<String>? allowedExtensions) {
    if (fileName.contains('.')) return fileName;
    if (allowedExtensions == null || allowedExtensions.length != 1) {
      return fileName;
    }
    final ext = allowedExtensions.first.trim();
    if (ext.isEmpty) return fileName;
    return ext.startsWith('.') ? '$fileName$ext' : '$fileName.$ext';
  }

  /// Obtains the raw bytes: either directly from [bytes], or by fetching [path].
  Future<Uint8List?> _resolveBytes(Uint8List? bytes, String? path) async {
    if (bytes != null && bytes.isNotEmpty) return bytes;
    if (path == null || path.isEmpty) return null;
    return _fetchBytesFromUrl(path);
  }

  /// Returns `true` if saved, `false` if the user cancelled, `null` if the
  /// browser does not support the native save picker.
  Future<bool?> _trySaveWithPicker(Blob blob, String fileName) async {
    try {
      final handle = _FileHandle(
        await _showSaveFilePickerJs({'suggestedName': fileName}.jsify()!).toDart as JSObject,
      );
      final writable = _WritableStream(
        await handle.createWritable().toDart as JSObject,
      );
      await writable.write(blob as JSAny).toDart;
      await writable.close().toDart;
      return true;
    } catch (e) {
      // User pressed Cancel → AbortError.
      return e.toString().contains('Abort') ? false : null;
    }
  }

  /// Fetches raw bytes from a blob: or data: URL.
  Future<Uint8List?> _fetchBytesFromUrl(String url) async {
    try {
      if (url.startsWith('data:')) {
        return Uri.parse(url).data?.contentAsBytes();
      }
      if (url.startsWith('blob:')) {
        final buffer = await _Response(await _fetchJs(url.toJS).toDart).arrayBuffer().toDart;
        return buffer.toDart.asUint8List();
      }
    } catch (_) {}
    return null;
  }

  /// Triggers a browser download for [blob] with [fileName].
  void _downloadBlob(Blob blob, String fileName) {
    final url = URL.createObjectURL(blob);
    HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..click();
    URL.revokeObjectURL(url);
  }

  Future<List<PlatformFile>> _buildPickedFiles(
    FileList files, {
    required bool withData,
    required bool withReadStream,
    required bool readSequential,
  }) async {
    final futures = <Future<PlatformFile>>[];
    final pickedFiles = <PlatformFile>[];

    for (int i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file == null) continue;

      final pickedFile = _toPlatformFile(
        file,
        withData: withData,
        withReadStream: withReadStream,
      );

      if (readSequential) {
        pickedFiles.add(await pickedFile);
      } else {
        futures.add(pickedFile);
      }
    }

    return readSequential ? pickedFiles : Future.wait(futures);
  }

  Future<PlatformFile> _toPlatformFile(
    File file, {
    required bool withData,
    required bool withReadStream,
  }) async {
    if (withReadStream) {
      return PlatformFile(
        name: file.name,
        path: URL.createObjectURL(file),
        size: file.size,
        readStream: _openFileReadStream(file),
      );
    }

    if (!withData) {
      return PlatformFile(
        name: file.name,
        path: URL.createObjectURL(file),
        size: file.size,
      );
    }

    final bytes = await _readFileAsBytes(file);
    return PlatformFile(
      name: file.name,
      path: _blobUrlFromBytes(file, bytes),
      size: bytes?.length ?? file.size,
      bytes: bytes,
    );
  }

  Future<Uint8List?> _readFileAsBytes(File file) {
    final completer = Completer<Uint8List?>();
    final reader = FileReader();
    reader.onLoadEnd.listen((_) {
      final byteBuffer = (reader.result as JSArrayBuffer?)?.toDart;
      completer.complete(byteBuffer?.asUint8List());
    });
    reader.readAsArrayBuffer(file);
    return completer.future;
  }

  String? _blobUrlFromBytes(File file, Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final blob = Blob(
      [bytes.toJS].toJS,
      BlobPropertyBag(type: file.type),
    );
    return URL.createObjectURL(blob);
  }

  void _clearTarget() {
    Node? firstChild = _target.firstChild;
    while (firstChild != null) {
      _target.removeChild(firstChild);
      firstChild = _target.firstChild;
    }
  }

  static String _fileType(FileType type, List<String>? allowedExtensions) {
    switch (type) {
      case FileType.any:
        return '';

      case FileType.audio:
        return 'audio/*';

      case FileType.image:
        return 'image/*';

      case FileType.video:
        return 'video/*';

      case FileType.media:
        return 'video/*|image/*';

      case FileType.custom:
        return allowedExtensions!.fold(
          '',
          (prev, next) => '${prev.isEmpty ? '' : '$prev,'} .$next',
        );
    }
  }

  Stream<List<int>> _openFileReadStream(File file) async* {
    final reader = FileReader();

    int start = 0;
    while (start < file.size) {
      final end = start + _readStreamChunkSize > file.size
          ? file.size
          : start + _readStreamChunkSize;
      final blob = file.slice(start, end);
      reader.readAsArrayBuffer(blob);
      await EventStreamProviders.loadEvent.forTarget(reader).first;
      final JSAny? readerResult = reader.result;
      if (readerResult == null) {
        continue;
      }

      // Handle the ArrayBuffer type. This maps to a `ByteBuffer` in Dart.
      if (readerResult.isA<JSArrayBuffer>()) {
        yield (readerResult as JSArrayBuffer).toDart.asUint8List();
        start += _readStreamChunkSize;
        continue;
      }

      if (readerResult.isA<JSArray>()) {
        // Assume this is a List<int>.
        yield (readerResult as JSArray).toDart.cast<int>();
        start += _readStreamChunkSize;
      }
    }
  }
}
