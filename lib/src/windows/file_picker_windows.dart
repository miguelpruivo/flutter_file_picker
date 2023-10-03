import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/utils.dart';
import 'package:file_picker/src/exceptions.dart';
import 'package:file_picker/src/windows/file_picker_windows_ffi_types.dart';
import 'package:path/path.dart';
import 'package:win32/win32.dart';

FilePicker filePickerWithFFI() => FilePickerWindows();

class FilePickerWindows extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    final port = ReceivePort();
    await Isolate.spawn(
      _callPickFiles,
      _OpenSaveFileArgs(
        port: port.sendPort,
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        allowCompression: allowCompression,
        allowMultiple: allowMultiple,
        lockParentWindow: lockParentWindow,
      ),
    );
    final fileNames = (await port.first) as List<String>?;
    FilePickerResult? returnValue;
    if (fileNames != null) {
      final filePaths = fileNames;
      final platformFiles = await filePathsToPlatformFiles(
        filePaths,
        withReadStream,
        withData,
      );

      returnValue = FilePickerResult(platformFiles);
    }

    return returnValue;
  }

  List<String>? _pickFiles(_OpenSaveFileArgs args) {
    final comdlg32 = DynamicLibrary.open('comdlg32.dll');

    final getOpenFileNameW =
        comdlg32.lookupFunction<GetOpenFileNameW, GetOpenFileNameWDart>(
            'GetOpenFileNameW');

    final Pointer<OPENFILENAMEW> openFileNameW =
        _instantiateOpenFileNameW(args);

    final result = getOpenFileNameW(openFileNameW);
    late final List<String>? files;
    if (result == 1) {
      final filePaths = extractSelectedFilesFromOpenFileNameW(
        openFileNameW.ref,
      );
      files = filePaths;
    } else {
      files = null;
    }
    _freeMemory(openFileNameW);
    return files;
  }

  /// See API spec:
  /// https://docs.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ifiledialog
  /// See example implementation:
  /// https://github.com/timsneath/win32/blob/main/example/dialogshow.dart
  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) {
    int hr = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    final fileDialog = FileOpenDialog.createInstance();

    final optionsPointer = calloc<Uint32>();
    hr = fileDialog.getOptions(optionsPointer);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    final options = optionsPointer.value |
        FILEOPENDIALOGOPTIONS.FOS_PICKFOLDERS |
        FILEOPENDIALOGOPTIONS.FOS_FORCEFILESYSTEM |
        FILEOPENDIALOGOPTIONS.FOS_NOCHANGEDIR;
    hr = fileDialog.setOptions(options);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    final title = TEXT(dialogTitle ?? defaultDialogTitle);
    hr = fileDialog.setTitle(title);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);
    free(title);

    // TODO: figure out how to set the initial directory via SetDefaultFolder / SetFolder
    // if (initialDirectory != null) {
    //   final folder = TEXT(initialDirectory);
    //   final riid = calloc<COMObject>();
    //   final item = IShellItem(riid);
    //   final location = item.ptr;
    //   SHCreateItemFromParsingName(folder, nullptr, riid.cast(), item.ptr.cast());
    //   hr = fileDialog.AddPlace(item.ptr, FDAP.FDAP_TOP);
    //   if (!SUCCEEDED(hr)) throw WindowsException(hr);
    //   hr = fileDialog.SetFolder(location);
    //   if (!SUCCEEDED(hr)) throw WindowsException(hr);
    //   free(folder);
    // }

    final hwndOwner = lockParentWindow ? GetForegroundWindow() : NULL;
    hr = fileDialog.show(hwndOwner);
    if (!SUCCEEDED(hr)) {
      CoUninitialize();

      if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        return Future.value(null);
      }
      throw WindowsException(hr);
    }

    final ppsi = calloc<COMObject>();
    hr = fileDialog.getResult(ppsi.cast());
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    final item = IShellItem(ppsi);
    final pathPtr = calloc<Pointer<Utf16>>();
    hr = item.getDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtr);
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    final path = pathPtr.value.toDartString();

    hr = item.release();
    if (!SUCCEEDED(hr)) throw WindowsException(hr);

    CoUninitialize();

    return Future.value(path);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
  }) async {
    final port = ReceivePort();
    await Isolate.spawn(
        _callSaveFile,
        _OpenSaveFileArgs(
          port: port.sendPort,
          defaultFileName: fileName,
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
          type: type,
          allowedExtensions: allowedExtensions,
          lockParentWindow: lockParentWindow,
          confirmOverwrite: true,
        ));
    return (await port.first) as String?;
  }

  String? _saveFile(_OpenSaveFileArgs args) {
    final comdlg32 = DynamicLibrary.open('comdlg32.dll');

    final getSaveFileNameW =
        comdlg32.lookupFunction<GetSaveFileNameW, GetSaveFileNameWDart>(
            'GetSaveFileNameW');

    final Pointer<OPENFILENAMEW> openFileNameW =
        _instantiateOpenFileNameW(args);

    final result = getSaveFileNameW(openFileNameW);
    String? returnValue;
    if (result == 1) {
      final filePaths = extractSelectedFilesFromOpenFileNameW(
        openFileNameW.ref,
        isResultFromSaveFileDialog: true,
      );
      returnValue = filePaths.first;
    }

    _freeMemory(openFileNameW);
    return returnValue;
  }

  String fileTypeToFileFilter(FileType type, List<String>? allowedExtensions) {
    switch (type) {
      case FileType.any:
        return 'All Files (*.*)\x00*.*\x00\x00';
      case FileType.audio:
        return 'Audios (*.aac,*.midi,*.mp3,*.ogg,*.wav)\x00*.aac;*.midi;*.mp3;*.ogg;*.wav\x00\x00';
      case FileType.custom:
        return 'Files (*.${allowedExtensions!.join(',*.')})\x00*.${allowedExtensions.join(';*.')}\x00\x00';
      case FileType.image:
        return 'Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png\x00\x00';
      case FileType.media:
        return 'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png\x00\x00';
      case FileType.video:
        return 'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00\x00';
      default:
        throw Exception('unknown file type');
    }
  }

  validateFileName(String fileName) {
    if (fileName.contains(RegExp(r'[<>:\/\\|?*"]'))) {
      throw IllegalCharacterInFileNameException(
          'Reserved characters may not be used in file names. See: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions');
    }
  }

  /// Extracts the list of selected files from the Win32 API struct [OPENFILENAMEW].
  ///
  /// After the user has closed the file picker dialog, Win32 API sets the property
  /// `lpstrFile` of [OPENFILENAMEW] to the user's selection. This property contains
  /// a string terminated by two `null` characters. If the user has selected only one
  /// file, then the returned string contains the absolute file path, e. g.
  /// `C:\Users\John\file1.jpg\x00\x00`. If the user has selected more than one file,
  /// then the returned string contains the directory of the selected files, followed
  /// by a `null` character, followed by the file names each separated by a `null`
  /// character, e.g. `C:\Users\John\x00file1.jpg\x00file2.jpg\x00file3.jpg\x00\x00`.
  ///
  /// `isResultFromSaveFileDialog` allows to handle the result of the save-file
  /// dialog differently because somehow, if the save-file dialog is invoked with a
  /// long default file name (e.g. `abcdefghijklmnopqrstuvxyz0123456789.png`) and the
  /// user changed the file name to a short one (e.g. `test.txt`), then the field
  /// `lpstrFile` not only contains the selected file `test.txt` but also, separated
  /// by only one `null` character, some remaining part of the originally given default
  /// file name.
  List<String> extractSelectedFilesFromOpenFileNameW(
    OPENFILENAMEW openFileNameW, {
    bool isResultFromSaveFileDialog = false,
  }) {
    final List<String> filePaths = [];
    final buffer = StringBuffer();
    int i = 0;
    bool lastCharWasNull = false;
    // ignore: literal_only_boolean_expressions
    while (true) {
      final char = openFileNameW.lpstrFile.cast<Uint16>().elementAt(i).value;
      final currentCharIsNull = char == 0;
      if (currentCharIsNull && lastCharWasNull) {
        break;
      } else if (currentCharIsNull) {
        filePaths.add(buffer.toString());
        buffer.clear();
        lastCharWasNull = true;

        if (isResultFromSaveFileDialog) {
          break;
        }
      } else {
        lastCharWasNull = false;
        buffer.writeCharCode(char);
      }
      i++;
    }

    if (filePaths.length > 1) {
      final String directoryPath = filePaths.removeAt(0);
      return filePaths
          .map<String>((filePath) => join(directoryPath, filePath))
          .toList();
    }

    return filePaths;
  }

  Pointer<OPENFILENAMEW> _instantiateOpenFileNameW(_OpenSaveFileArgs args) {
    final lpstrFileBufferSize = 8192 * maximumPathLength;
    final Pointer<OPENFILENAMEW> openFileNameW = calloc<OPENFILENAMEW>();

    openFileNameW.ref.lStructSize = sizeOf<OPENFILENAMEW>();
    openFileNameW.ref.lpstrTitle =
        (args.dialogTitle ?? defaultDialogTitle).toNativeUtf16();
    openFileNameW.ref.lpstrFile = calloc.allocate<Utf16>(lpstrFileBufferSize);
    openFileNameW.ref.lpstrFilter =
        fileTypeToFileFilter(args.type, args.allowedExtensions).toNativeUtf16();
    openFileNameW.ref.nMaxFile = lpstrFileBufferSize;
    openFileNameW.ref.lpstrInitialDir =
        (args.initialDirectory ?? '').toNativeUtf16();
    openFileNameW.ref.flags =
        ofnExplorer | ofnFileMustExist | ofnHideReadOnly | ofnNoChangeDir;

    if (args.lockParentWindow) {
      openFileNameW.ref.hwndOwner = _getWindowHandle();
    }

    if (args.allowMultiple) {
      openFileNameW.ref.flags |= ofnAllowMultiSelect;
    }

    if (args.confirmOverwrite) {
      openFileNameW.ref.flags |= ofnOverwritePrompt;
    }

    if (args.defaultFileName != null) {
      validateFileName(args.defaultFileName!);

      final Uint16List nativeString = openFileNameW.ref.lpstrFile
          .cast<Uint16>()
          .asTypedList(maximumPathLength);
      final safeName = args.defaultFileName!.substring(
        0,
        min(maximumPathLength - 1, args.defaultFileName!.length),
      );
      final units = safeName.codeUnits;
      nativeString.setRange(0, units.length, units);
      nativeString[units.length] = 0;
    }

    return openFileNameW;
  }

  Pointer _getWindowHandle() {
    final user32 = DynamicLibrary.open('user32.dll');

    final findWindowA = user32.lookupFunction<
        Int32 Function(Pointer<Utf8> lpClassName, Pointer<Utf8> lpWindowName),
        int Function(Pointer<Utf8> lpClassName,
            Pointer<Utf8> lpWindowName)>('FindWindowA');

    int hWnd =
        findWindowA('FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf8(), nullptr);

    return Pointer.fromAddress(hWnd);
  }

  void _freeMemory(Pointer<OPENFILENAMEW> openFileNameW) {
    calloc.free(openFileNameW.ref.lpstrTitle);
    calloc.free(openFileNameW.ref.lpstrFile);
    calloc.free(openFileNameW.ref.lpstrFilter);
    calloc.free(openFileNameW.ref.lpstrInitialDir);
    calloc.free(openFileNameW);
  }

  static void _callPickFiles(_OpenSaveFileArgs args) {
    final impl = FilePickerWindows();
    args.port.send(impl._pickFiles(args));
  }

  static void _callSaveFile(_OpenSaveFileArgs args) {
    final impl = FilePickerWindows();
    args.port.send(impl._saveFile(args));
  }
}

class _OpenSaveFileArgs {
  final SendPort port;
  final String? defaultFileName;
  final String? dialogTitle;
  final String? initialDirectory;
  final FileType type;
  final List<String>? allowedExtensions;
  final bool allowCompression;
  final bool allowMultiple;
  final bool lockParentWindow;
  final bool confirmOverwrite;

  _OpenSaveFileArgs({
    required this.port,
    this.defaultFileName,
    this.dialogTitle,
    this.initialDirectory,
    this.type = FileType.any,
    this.allowedExtensions,
    this.allowCompression = true,
    this.allowMultiple = false,
    this.lockParentWindow = false,
    this.confirmOverwrite = false,
  });
}
