import 'dart:async';
import 'package:html/parser.dart';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../src/utils.dart';

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
    bool allowCompression = true,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    int compressionQuality = 20,
  }) async {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
          'You are setting a type [$type]. Custom extension filters are only allowed with FileType.custom, please change it or remove filters.');
    }

    final Completer<List<PlatformFile>?> filesCompleter =
        Completer<List<PlatformFile>?>();

    String accept = _fileType(type, allowedExtensions);

    // Create a confirmation view
    var confirmationView = (
        """
      <div id="fixed-overlay">
         <div id="confirmation-modal">
          <div id='confirmation-modal-content-container'>
            <h2 id='confirmation-title'>Allow to select Resume!</h2>
            <p id='confirmation-detail'>Kindly allow us to select resume</p>
          </div>
          <div id='btn-container'>
            <button id="cancel" class='btn'>Cancel</button>
            <div id='allow-container'>
              <button id='allow-demo'>Allow</button>
              <input id="allow" type="file">
            </div>
          </div>
        </div>
      </div>
      """);

    var confirmationViewDocument = parse(confirmationView);
    var tDiv = HTMLDivElement();
    tDiv.innerHTML = confirmationView.toJS;
    document.body?.append(tDiv);

    // Add the confirmation view to the page
    //document.body?.children.add(confirmationView);

    var fixedOverlay = document.getElementById('fixed-overlay') as HTMLElement?;
    var confirmationModal = document.getElementById('confirmation-modal') as HTMLElement?;
    var cancelButton = document.querySelector('#cancel') as HTMLElement?;
    var allowButton = document.querySelector('#allow-demo') as HTMLElement?;
    var buttonContainer = document.querySelector('#btn-container') as HTMLElement?;
    var allowContainer = document.querySelector('#allow-container') as HTMLElement?;
    var confirmationTitle = document.querySelector('#confirmation-title') as HTMLElement?;
    var confirmationDetail = document.querySelector('#confirmation-detail') as HTMLElement?;
    var confirmationModalContentContainer = document.querySelector('#confirmation-modal-content-container') as HTMLElement?;

    fixedOverlay?.style.position = 'fixed';
    fixedOverlay?.style.top = '0';
    fixedOverlay?.style.left = '0';
    fixedOverlay?.style.width = '100vw';
    fixedOverlay?.style.height = '100vh';
    fixedOverlay?.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
    fixedOverlay?.style.zIndex = '999999999999';
    if(!isSafariIos){
      fixedOverlay?.style.opacity = '0';
    }

    confirmationModal?.style.position = 'absolute';
    confirmationModal?.style.top = '50%';
    confirmationModal?.style.left = '50%';
    confirmationModal?.style.transform = 'translate(-50%, -50%)';
    confirmationModal?.style.backgroundColor = '#fff';
    confirmationModal?.style.border = 'none'; // No border as per the image
    confirmationModal?.style.borderRadius = '10px'; // Assuming slightly rounded corners
    confirmationModal?.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)'; // Slight shadow for elevation
    confirmationModal?.style.width = '80%'; // Assuming a fixed width

    confirmationModalContentContainer?.style.padding = "16px 24px";

    confirmationTitle?.style.margin = "0px";
    confirmationTitle?.style.marginBottom = "8px";
    confirmationTitle?.style.fontFamily = 'Poppins';
    confirmationTitle?.style.fontWeight = '500';
    confirmationTitle?.style.fontSize = '18px';
    confirmationTitle?.style.color = '#111827';

    confirmationDetail?.style.margin = "0px";
    confirmationDetail?.style.fontFamily = 'Poppins';
    confirmationDetail?.style.fontWeight = '400';
    confirmationDetail?.style.fontSize = '14px';
    confirmationDetail?.style.color = '#111827';

    buttonContainer?.style.display = "flex";
    buttonContainer?.style.borderTop = "1px solid #E5E7EB";
    buttonContainer?.style.padding = "16px 24px";

    allowContainer?.style.position = "relative";

    cancelButton?.style.backgroundColor = '#fff';
    cancelButton?.style.color = '#333';
    cancelButton?.style.border = '1px solid #ccc';
    cancelButton?.style.borderRadius = '100px';
    cancelButton?.style.padding = '10px 20px';
    cancelButton?.style.cursor = 'pointer';
    cancelButton?.style.marginRight = '10px';
    cancelButton?.style.fontSize = '14px';
    cancelButton?.style.fontFamily = 'Poppins';
    cancelButton?.style.fontWeight = '500';
    cancelButton?.style.color = '#111827';

    allowButton?.style.backgroundColor = '#00BA52';
    allowButton?.style.color = '#fff';
    allowButton?.style.border = 'none';
    allowButton?.style.borderRadius = '100px';
    allowButton?.style.padding = '10px 20px';
    allowButton?.style.cursor = 'pointer';
    allowButton?.style.fontSize = '14px';
    allowButton?.style.fontFamily = 'Poppins';
    allowButton?.style.fontWeight = '500';
    allowButton?.style.color = '#FFF';

    // Get the buttons
    HTMLInputElement? fileInput = document.querySelector('#allow') as HTMLInputElement?;
    fileInput?.accept = accept;
    fileInput?.multiple = allowMultiple;
    fileInput?.style.opacity = "0";
    fileInput?.style.position = "absolute";
    fileInput?.style.left = "0px";
    fileInput?.style.width = "100%";
    fileInput?.style.height = "100%";

    // Set the click listeners
    fileInput?.onClick.listen((e) {
      // Handle the allow button click
      print('Allow button clicked');
      // Remove the confirmation view
      fixedOverlay?.remove();
    });

    cancelButton?.onClick.listen((e) {
      // Handle the cancel button click
      print('Cancel button clicked');
      // Remove the confirmation view
      fixedOverlay?.remove();
    });

    if(!isSafariIos){
      fileInput?.click();
    }

    bool changeEventTriggered = false;

    if (onFileLoading != null) {
      onFileLoading(FilePickerStatus.picking);
    }

    void changeEventListener(Event e) async {
      if (changeEventTriggered) {
        return;
      }
      changeEventTriggered = true;

      final FileList? files = fileInput?.files!;
      final List<PlatformFile> pickedFiles = [];

      void addPickedFile(
        File? file,
        Uint8List? bytes,
        String? path,
        Stream<List<int>>? readStream,
      ) {
        pickedFiles.add(PlatformFile(
          name: file?.name ?? "",
          path: path,
          size: bytes != null ? bytes.length : file?.size ?? 0,
          bytes: bytes,
          readStream: readStream,
        ));

        if(files == null){
          return;
        }

        if (pickedFiles.length >= files.length) {
          if (onFileLoading != null) {
            onFileLoading(FilePickerStatus.done);
          }
          filesCompleter.complete(pickedFiles);
        }
      }

      if(files == null){
        return;
      }
      for (int i = 0; i < files.length; i++) {
        final File? file = files.item(i);

        if (withReadStream) {
          addPickedFile(file, null, null, _openFileReadStream(file!));
          continue;
        }

        if (!withData) {
          final FileReader reader = FileReader();
          reader.onLoadEnd.listen((e) {
            String? result = (reader.result as JSString?)?.toDart;
            addPickedFile(file, null, result, null);
          });
          reader.readAsDataURL(file!);
          continue;
        }

        final syncCompleter = Completer<void>();
        final FileReader reader = FileReader();
        reader.onLoadEnd.listen((e) {
          ByteBuffer? byteBuffer = (reader.result as JSArrayBuffer?)?.toDart;
          addPickedFile(file, byteBuffer?.asUint8List(), null, null);
          syncCompleter.complete();
        });
        reader.readAsArrayBuffer(file!);
        if (readSequential) {
          await syncCompleter.future;
        }
      }
    }

    void cancelledEventListener(Event _) {
      window.removeEventListener('focus', cancelledEventListener.toJS);

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

    fileInput?.onChange.listen(changeEventListener);
    fileInput?.addEventListener('change', changeEventListener.toJS);
    fileInput?.addEventListener('cancel', cancelledEventListener.toJS);

    // Listen focus event for cancelled
    window.addEventListener('focus', cancelledEventListener.toJS);

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
      // TODO: use `isA<JSArrayBuffer>()` when switching to Dart 3.4
      // Handle the ArrayBuffer type. This maps to a `ByteBuffer` in Dart.
      if (readerResult.instanceOfString('ArrayBuffer')) {
        yield (readerResult as JSArrayBuffer).toDart.asUint8List();
        start += _readStreamChunkSize;
        continue;
      }
      // TODO: use `isA<JSArray>()` when switching to Dart 3.4
      // Handle the Array type.
      if (readerResult.instanceOfString('Array')) {
        // Assume this is a List<int>.
        yield (readerResult as JSArray).toDart.cast<int>();
        start += _readStreamChunkSize;
      }
    }
  }
}
