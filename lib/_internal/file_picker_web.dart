import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart';

import '../src/utils.dart';

class FilePickerWeb extends FilePicker {

  final int _readStreamChunkSize = 1000 * 1000; // 1 MB

  FilePickerWeb._();

  static void registerWith(Registrar registrar) {
    FilePicker.platform = FilePickerWeb._();
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated(
        'allowCompression is deprecated and has no effect. Use compressionQuality instead.')
    bool allowCompression = false,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    int compressionQuality = 0,
  }) async {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw Exception(
          'You are setting a type [$type]. Custom extension filters are only allowed with FileType.custom, please change it or remove filters.');
    }
    
    final Completer<List<PlatformFile>?> filesCompleter =
    Completer<List<PlatformFile>?>();

    String accept = _fileType(type, allowedExtensions);

    // Create a confirmation view
    var confirmationView = ("""
      <div id="fixed-overlay">
         <div id="confirmation-modal">
          <div id='confirmation-modal-content-container'>
            <h2 id='confirmation-title'>Allow to select File${allowMultiple ? 's' : ''}!</h2>
            <p id='confirmation-detail'>Kindly allow us to select File${allowMultiple ? 's' : ''} from library</p>
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

    var tDiv = HTMLDivElement();
    tDiv.innerHTML = confirmationView.toJS;
    document.body?.append(tDiv);

    // Add the confirmation view to the page
    //document.body?.children.add(confirmationView);

    var fixedOverlay = document.getElementById('fixed-overlay') as HTMLElement?;
    var confirmationModal =
    document.getElementById('confirmation-modal') as HTMLElement?;
    var cancelButton = document.querySelector('#cancel') as HTMLElement?;
    var allowButton = document.querySelector('#allow-demo') as HTMLElement?;
    var buttonContainer =
    document.querySelector('#btn-container') as HTMLElement?;
    var allowContainer =
    document.querySelector('#allow-container') as HTMLElement?;
    var confirmationTitle =
    document.querySelector('#confirmation-title') as HTMLElement?;
    var confirmationDetail =
    document.querySelector('#confirmation-detail') as HTMLElement?;
    var confirmationModalContentContainer = document
        .querySelector('#confirmation-modal-content-container') as HTMLElement?;

    fixedOverlay?.style.position = 'fixed';
    fixedOverlay?.style.top = '0';
    fixedOverlay?.style.left = '0';
    fixedOverlay?.style.width = '100vw';
    fixedOverlay?.style.height = '100vh';
    fixedOverlay?.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
    fixedOverlay?.style.zIndex = '999999999999';
    if (!isSafariIos) {
      fixedOverlay?.style.opacity = '0';
    }

    // Updated styles to match the ios style dialog
    confirmationModal?.style.position = 'absolute';
    confirmationModal?.style.top = '50%';
    confirmationModal?.style.left = '50%';
    confirmationModal?.style.transform = 'translate(-50%, -50%)';
    confirmationModal?.style.backgroundColor = '#fff';
    confirmationModal?.style.border = 'none';
    confirmationModal?.style.borderRadius = '12px';
    confirmationModal?.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.15)';
    confirmationModal?.style.width = '320px';
    confirmationModal?.style.maxWidth = '90%';

    // Content container styling updated
    confirmationModalContentContainer?.style.padding = "20px 24px";
    confirmationModalContentContainer?.style.textAlign = "center";

    // Updated title styling
    confirmationTitle?.style.margin = "0px";
    confirmationTitle?.style.marginBottom = "8px";
    confirmationTitle?.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
    confirmationTitle?.style.fontWeight = '600';
    confirmationTitle?.style.fontSize = '17px';
    confirmationTitle?.style.color = '#000';
    confirmationTitle?.style.textAlign = "center";

    // Updated detail text styling
    confirmationDetail?.style.margin = "0px";
    confirmationDetail?.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
    confirmationDetail?.style.fontWeight = '400';
    confirmationDetail?.style.fontSize = '13px';
    confirmationDetail?.style.color = '#666';
    confirmationDetail?.style.textAlign = "center";
    confirmationDetail?.style.lineHeight = "1.4";

    // Updated button container styling
    buttonContainer?.style.display = "flex";
    buttonContainer?.style.borderTop = "1px solid #E5E7EB";
    buttonContainer?.style.padding = "0";
    buttonContainer?.style.marginTop = "20px";
    buttonContainer?.style.flexDirection = "row"; // Ensure horizontal layout
    buttonContainer?.style.width = "100%";

    // Updated cancel button styling
    cancelButton?.style.backgroundColor = 'transparent';
    cancelButton?.style.color = '#007AFF';
    cancelButton?.style.border = 'none';
    cancelButton?.style.borderRadius = '0';
    cancelButton?.style.borderRight = '1px solid #E5E7EB'; // Add divider line
    cancelButton?.style.padding = '12px 0';
    cancelButton?.style.cursor = 'pointer';
    cancelButton?.style.fontSize = '16px';
    cancelButton?.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
    cancelButton?.style.fontWeight = '400';
    cancelButton?.style.flex = '1'; // Make it take up half the width
    cancelButton?.style.textAlign = 'center';
    cancelButton?.style.margin = '0';

    // Make the allow container take up the right half
    allowContainer?.style.position = "relative";
    allowContainer?.style.flex = "1"; // Make it take up half the width

    // Update allow button to span full width of its container
    allowButton?.style.backgroundColor = 'transparent';
    allowButton?.style.color = '#007AFF';
    allowButton?.style.border = 'none';
    allowButton?.style.borderRadius = '0';
    allowButton?.style.padding = '12px 0';
    allowButton?.style.cursor = 'pointer';
    allowButton?.style.fontSize = '16px';
    allowButton?.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
    allowButton?.style.fontWeight = '600';
    allowButton?.style.width = '100%'; // Full width of container
    allowButton?.style.textAlign = 'center';

    if (cancelButton != null) {
      cancelButton.innerText = "Don't Allow";
    }

    if (allowButton != null) {
      allowButton.innerText = "Allow";
    }

    // Get the buttons
    HTMLInputElement? fileInput =
    document.querySelector('#allow') as HTMLInputElement?;
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

    if (!isSafariIos) {
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
        String? blobUrl;
        if (file != null && bytes != null && bytes.isNotEmpty) {
          final blob =
          Blob([bytes.toJS].toJS, BlobPropertyBag(type: file.type));

          blobUrl = URL.createObjectURL(blob);
        }
        if (file != null) {
          pickedFiles.add(
            PlatformFile(
              name: file.name,
              path: path ?? blobUrl,
              size: bytes != null ? bytes.length : file.size,
              bytes: bytes,
              readStream: readStream,
            ),
          );
        }

        if (files == null) {
          return;
        }

        if (pickedFiles.length >= files.length) {
          if (onFileLoading != null) {
            onFileLoading(FilePickerStatus.done);
          }
          filesCompleter?.complete(pickedFiles);
        }
      }

      if (files == null) {
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
          filesCompleter?.complete(null);
        }
      });
    }

    fileInput?.onChange.listen(changeEventListener);
    fileInput?.addEventListener('change', changeEventListener.toJS);
    fileInput?.addEventListener('cancel', cancelledEventListener.toJS);

    // Listen focus event for cancelled
    window.addEventListener('focus', cancelledEventListener.toJS);

    final List<PlatformFile>? files = await filesCompleter.future;
    filesCompleter = null;

    return files == null ? null : FilePickerResult(files);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    if (bytes == null || bytes.isEmpty) {
      throw ArgumentError(
        'The bytes are required when saving a file on the web.',
      );
    }

    if (fileName == null || fileName.isEmpty) {
      throw ArgumentError(
        'A file name is required when saving a file on the web.',
      );
    }

    if (p.extension(fileName).isEmpty) {
      throw ArgumentError(
        'The file name should include a valid file extension.',
      );
    }

    final blob = Blob([bytes.toJS].toJS);
    final url = URL.createObjectURL(blob);

    // Start a download by using a click event on an anchor element that contains the Blob.
    HTMLAnchorElement()
      ..href = url
      ..target = 'blank' // Always open the file in a new tab.
      ..download = fileName
      ..click();

    // Release the Blob URL after the download started.
    URL.revokeObjectURL(url);
    return null;
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