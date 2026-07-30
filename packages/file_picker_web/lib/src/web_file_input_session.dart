import 'dart:async';
import 'dart:js_interop';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart';

/// Internal helper class managing the life cycle of an HTML file input session on the web.
///
/// Encapsulates DOM element creation, event listening (`change`, `cancel`, `focus`),
/// cancel timeout handling, and conversion of selected files.
@internal
class WebFileInputSession {
  /// Creates a new [WebFileInputSession] instance.
  WebFileInputSession({
    required this.target,
    required this.accept,
    required this.webOptions,
    required this.onFileLoading,
    required this.processFiles,
  });

  /// The target DOM container element where the `<input>` element is temporarily attached.
  final Element target;

  /// The HTML `accept` attribute string filtering allowed file extensions/MIME types.
  final String accept;

  /// Web-specific configuration options.
  final WebOptions webOptions;

  /// Optional callback triggered during file picking status transitions.
  final Function(FilePickerStatus)? onFileLoading;

  /// Callback delegate used to process and convert the native [FileList] to [PlatformFile]s.
  final Future<List<PlatformFile>> Function(FileList, WebOptions) processFiles;

  final Completer<List<PlatformFile>?> _completer = Completer();
  bool _eventTriggered = false;

  /// Starts the file picker input interaction and returns a list of picked files or `null`.
  Future<List<PlatformFile>?> start() async {
    final uploadInput = HTMLInputElement()
      ..type = 'file'
      ..draggable = true
      ..multiple = webOptions.allowMultiple
      ..accept = accept
      ..style.display = 'none';

    onFileLoading?.call(FilePickerStatus.picking);

    uploadInput.addEventListener('change', _onFileSelection.toJS);
    uploadInput.addEventListener('cancel', _onCancel.toJS);

    if (webOptions.cancelUploadOnWindowBlur) {
      window.addEventListener('focus', _onCancel.toJS);
    }

    _clearTargetChildren();
    target.children.add(uploadInput);
    uploadInput.click();
    _clearTargetChildren();

    return _completer.future;
  }

  void _onFileSelection(Event e) async {
    if (_eventTriggered) return;
    _eventTriggered = true;

    final targetInput = e.target as HTMLInputElement?;
    final files = targetInput?.files;
    if (files == null) {
      _completer.complete(null);
      return;
    }

    final pickedFiles = await processFiles(files, webOptions);

    onFileLoading?.call(FilePickerStatus.done);
    _completer.complete(pickedFiles);
  }

  void _onCancel(Event _) {
    window.removeEventListener('focus', _onCancel.toJS);

    Future.delayed(const Duration(seconds: 1)).then((_) {
      if (!_eventTriggered) {
        _eventTriggered = true;
        _completer.complete(null);
      }
    });
  }

  void _clearTargetChildren() {
    Node? firstChild = target.firstChild;
    while (firstChild != null) {
      target.removeChild(firstChild);
      firstChild = target.firstChild;
    }
  }
}
