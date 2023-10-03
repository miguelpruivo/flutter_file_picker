import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FilePickerWeb extends FilePicker {
  late Element _target;
  final String _kFilePickerInputsDomId = '__file_picker_web-file-input';

  final int _readStreamChunkSize = 1000 * 1000; // 1 MB

  static final FilePickerWeb platform = FilePickerWeb._();

  FilePickerWeb._() {
    _target = _ensureInitialized(_kFilePickerInputsDomId);
  }

  static void registerWith(Registrar registrar) {
    FilePicker.platform = platform;
  }

  /// Initializes a DOM container where we can host input elements.
  Element _ensureInitialized(String id) {
    Element? target = querySelector('#$id');
    if (target == null) {
      final Element targetElement = Element.tag('flt-file-picker-inputs')
        ..id = id;

      querySelector('body')!.children.add(targetElement);
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
    bool allowCompression = true,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
          'You are setting a type [$type]. Custom extension filters are only allowed with FileType.custom, please change it or remove filters.');
    }

    final Completer<List<PlatformFile>?> filesCompleter =
        Completer<List<PlatformFile>?>();

    String accept = _fileType(type, allowedExtensions);
    InputElement uploadInput = FileUploadInputElement() as InputElement;
    uploadInput.draggable = true;
    uploadInput.multiple = allowMultiple;
    uploadInput.accept = accept;
    uploadInput.style.display = 'none';

    bool changeEventTriggered = false;

    if (onFileLoading != null) {
      onFileLoading(FilePickerStatus.picking);
    }

    void changeEventListener(e) {
      if (changeEventTriggered) {
        return;
      }
      changeEventTriggered = true;

      final List<File> files = uploadInput.files!;
      final List<PlatformFile> pickedFiles = [];

      void addPickedFile(
        File file,
        Uint8List? bytes,
        String? path,
        Stream<Uint8List> Function([int? start, int? end])? readStream,
      ) {
        late DateTime lastModified;
        try {
          // log
          print('Getting last modified date');

          lastModified = file.lastModifiedDate;
        } catch (e) {
          print(
              'An error occured getting the last modified. Using datetime.now() instead');

          lastModified = DateTime.now();
        }

        pickedFiles.add(PlatformFile(
          name: file.name,
          path: path,
          size: bytes != null ? bytes.length : file.size,
          lastModified: lastModified,
          bytes: bytes,
          readStream: readStream,
        ));

        if (pickedFiles.length >= files.length) {
          if (onFileLoading != null) {
            onFileLoading(FilePickerStatus.done);
          }
          filesCompleter.complete(pickedFiles);
        }
      }

      for (File file in files) {
        if (withReadStream) {
          addPickedFile(file, null, null,
              ([int? s, int? e]) => _openFileReadStream(file, s, e));
          continue;
        }

        if (!withData) {
          final FileReader reader = FileReader();
          reader.onLoadEnd.listen((e) {
            addPickedFile(file, null, reader.result as String?, null);
          });
          reader.readAsDataUrl(file);
          continue;
        }

        final FileReader reader = FileReader();
        reader.onLoadEnd.listen((e) {
          addPickedFile(file, reader.result as Uint8List?, null, null);
        });
        reader.readAsArrayBuffer(file);
      }
    }

    void cancelledEventListener(_) {
      window.removeEventListener('focus', cancelledEventListener);

      // This listener is called before the input changed event,
      // and the `uploadInput.files` value is still null
      // Wait for results from js to dart
      Future.delayed(Duration(seconds: 1)).then((value) {
        if (!changeEventTriggered) {
          changeEventTriggered = true;
          filesCompleter.complete(null);
        }
      });
    }

    uploadInput.onChange.listen(changeEventListener);
    uploadInput.addEventListener('change', changeEventListener);

    // Listen focus event for cancelled
    window.addEventListener('focus', cancelledEventListener);

    //Add input element to the page body
    _target.children.clear();
    _target.children.add(uploadInput);
    uploadInput.click();

    final List<PlatformFile>? files = await filesCompleter.future;

    return files == null ? null : FilePickerResult(files);
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
        return allowedExtensions!
            .fold('', (prev, next) => '${prev.isEmpty ? '' : '$prev,'} .$next');
    }
  }

  Stream<Uint8List> _openFileReadStream(File file,
      [int? start, int? end]) async* {
    final reader = FileReader();

    int globalOffset = start ?? 0;
    int globalEnd = end ?? file.size;
    while (globalOffset < globalEnd) {
      final chunkEnd = globalOffset + _readStreamChunkSize > globalEnd
          ? globalEnd
          : globalOffset + _readStreamChunkSize;
      final blob = file.slice(globalOffset, chunkEnd);
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;
      yield reader.result as Uint8List;
      globalOffset += _readStreamChunkSize;
    }
  }
}
