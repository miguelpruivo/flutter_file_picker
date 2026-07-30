import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart';

import 'web_platform_file.dart';

/// An implementation of [FilePickerPlatform] for the Web platform.
class FilePickerWeb extends FilePickerPlatform {
  late Element _target;
  final String _kFilePickerInputsDomId = '__file_picker_web-file-input';

  final int _readStreamChunkSize = 1000 * 1000; // 1 MB

  FilePickerWeb._() {
    _target = _ensureInitialized(_kFilePickerInputsDomId);
  }

  /// Registers this class as the default instance of [FilePickerPlatform].
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
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    throw UnimplementedError('getDirectoryPath() has not been implemented.');
  }

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final files = await pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
      androidOptions: androidOptions,
      windowsOptions: windowsOptions,
      linuxOptions: linuxOptions,
      webOptions: webOptions.copyWith(allowMultiple: false),
    );
    return files.firstOrNull;
  }

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (type == FileType.custom &&
        (allowedExtensions == null || allowedExtensions.isEmpty)) {
      throw ArgumentError(
        'If type is set to FileType.custom, allowedExtensions cannot be null or empty.',
      );
    }

    final Completer<List<PlatformFile>?> filesCompleter =
        Completer<List<PlatformFile>?>();

    final String accept = _fileType(type, allowedExtensions);
    final HTMLInputElement uploadInput = HTMLInputElement();
    uploadInput.type = 'file';
    uploadInput.draggable = true;
    uploadInput.multiple = webOptions.allowMultiple;
    uploadInput.accept = accept;
    uploadInput.style.display = 'none';

    bool changeEventTriggered = false;

    if (onFileLoading != null) {
      onFileLoading(FilePickerStatus.picking);
    }

    void changeEventListener(Event e) async {
      if (changeEventTriggered) {
        return;
      }
      changeEventTriggered = true;

      final FileList files = uploadInput.files!;
      final List<PlatformFile> pickedFiles = [];

      void addPickedFile(
        File file,
        Uint8List? bytes,
        String? path,
        Stream<List<int>>? readStream,
      ) {
        String? blobUrl = path;

        if ((blobUrl == null || blobUrl.isEmpty) && (bytes == null)) {
          try {
            blobUrl = URL.createObjectURL(file);
          } catch (_) {
            blobUrl = null;
          }
        } else if (bytes != null && bytes.isNotEmpty) {
          final blob = Blob(
            [bytes.toJS].toJS,
            BlobPropertyBag(type: file.type),
          );

          blobUrl = URL.createObjectURL(blob);
        }

        final uri = Uri.parse(blobUrl ?? '');

        pickedFiles.add(
          WebPlatformFile(
            name: file.name,
            uri: uri,
            bytesLength: bytes != null ? bytes.length : file.size,
            bytes: bytes,
            readStream: readStream,
          ),
        );

        if (pickedFiles.length >= files.length) {
          if (onFileLoading != null) {
            onFileLoading(FilePickerStatus.done);
          }
          filesCompleter.complete(pickedFiles);
        }
      }

      for (int i = 0; i < files.length; i++) {
        final File? file = files.item(i);
        if (file == null) {
          continue;
        }

        if (webOptions.withReadStream) {
          addPickedFile(file, null, null, _openFileReadStream(file));
          continue;
        }

        if (!webOptions.withData) {
          addPickedFile(file, null, null, null);
          continue;
        }

        final syncCompleter = Completer<void>();
        final FileReader reader = FileReader();
        reader.onLoadEnd.listen((e) {
          ByteBuffer? byteBuffer = (reader.result as JSArrayBuffer?)?.toDart;
          addPickedFile(file, byteBuffer?.asUint8List(), null, null);
          syncCompleter.complete();
        });
        reader.readAsArrayBuffer(file);
        if (webOptions.readSequential) {
          await syncCompleter.future;
        }
      }
    }

    void cancelledEventListener(Event _) {
      window.removeEventListener('focus', cancelledEventListener.toJS);

      Future.delayed(const Duration(seconds: 1)).then((value) {
        if (!changeEventTriggered) {
          changeEventTriggered = true;
          filesCompleter.complete(null);
        }
      });
    }

    uploadInput.onChange.listen(changeEventListener);
    uploadInput.addEventListener('change', changeEventListener.toJS);
    uploadInput.addEventListener('cancel', cancelledEventListener.toJS);

    if (webOptions.cancelUploadOnWindowBlur) {
      window.addEventListener('focus', cancelledEventListener.toJS);
    }

    Node? firstChild = _target.firstChild;
    while (firstChild != null) {
      _target.removeChild(firstChild);
      firstChild = _target.firstChild;
    }
    _target.children.add(uploadInput);
    uploadInput.click();

    firstChild = _target.firstChild;
    while (firstChild != null) {
      _target.removeChild(firstChild);
      firstChild = _target.firstChild;
    }

    final List<PlatformFile>? files = await filesCompleter.future;

    return files ?? <PlatformFile>[];
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError(
        'The bytes are required when saving a file on the web.',
      );
    }

    if (fileName.isEmpty) {
      throw ArgumentError(
        'A file name is required when saving a file on the web.',
      );
    }

    if (p.extension(fileName).isEmpty) {
      throw ArgumentError(
        'The file name should include a valid file extension.',
      );
    }

    final blob = Blob([bytes.toJS].toJS, BlobPropertyBag(type: mimeType));
    final url = URL.createObjectURL(blob);

    HTMLAnchorElement()
      ..href = url
      ..target = 'blank'
      ..download = fileName
      ..click();

    URL.revokeObjectURL(url);
    return Uri.parse(url);
  }

  static String _fileType(FileType type, List<String>? allowedExtensions) {
    return switch (type) {
      FileType.any => '',
      FileType.audio => 'audio/*',
      FileType.image => 'image/*',
      FileType.video => 'video/*',
      FileType.media => 'video/*|image/*',
      FileType.custom => allowedExtensions!.fold(
        '',
        (prev, next) => '${prev.isEmpty ? '' : '$prev,'} .$next',
      ),
    };
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

      if (readerResult.isA<JSArrayBuffer>()) {
        yield (readerResult as JSArrayBuffer).toDart.asUint8List();
        start += _readStreamChunkSize;
        continue;
      }

      if (readerResult.isA<JSArray>()) {
        yield (readerResult as JSArray).toDart.cast<int>();
        start += _readStreamChunkSize;
      }
    }
  }
}
