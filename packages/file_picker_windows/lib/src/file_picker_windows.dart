import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:win32/win32.dart';

import 'file_picker_windows_ffi_types.dart';
import 'file_picker_windows_options.dart';
import 'windows_platform_file.dart';

/// An implementation of [FilePickerPlatform] for Windows.
class FilePickerWindows extends FilePickerPlatform {
  /// Registers this class as the default instance of [FilePickerPlatform].
  static void registerWith() {
    FilePickerPlatform.instance = FilePickerWindows();
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
    WindowsOptions windowsOptions = const FilePickerWindowsOptions(),
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
      windowsOptions: windowsOptions,
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
    WindowsOptions windowsOptions = const FilePickerWindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final FilePickerWindowsOptions options = switch (windowsOptions) {
      FilePickerWindowsOptions opts => opts,
      _ => const FilePickerWindowsOptions(),
    };

    final port = ReceivePort();
    await Isolate.spawn(
      _callPickFiles,
      _OpenSaveFileArgs(
        port: port.sendPort,
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        lockParentWindow: options.lockParentWindow,
        parentWindowHandle: options.parentWindowHandle,
      ),
    );

    final fileNames = (await port.first) as List<String>? ?? [];
    if (fileNames.isEmpty) {
      return [];
    }

    return [for (final path in fileNames) WindowsPlatformFile.fromPath(path)];
  }

  @override
  Future<List<String>> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final files = await pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
    );
    return files.map((e) => e.uri.path).toList();
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const FilePickerWindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final FilePickerWindowsOptions options = switch (windowsOptions) {
      FilePickerWindowsOptions opts => opts,
      _ => const FilePickerWindowsOptions(),
    };

    return compute(_getDirectoryPathIsolate, {
      'dialogTitle': dialogTitle,
      'initialDirectory': initialDirectory,
      'lockParentWindow': options.lockParentWindow,
      'parentWindowHandle': options.parentWindowHandle,
    });
  }

  static String? _getDirectoryPathIsolate(Map<String, Object?> args) {
    String? dialogTitle = args['dialogTitle'] as String?;
    String? initialDirectory = args['initialDirectory'] as String?;
    bool lockParentWindow = args['lockParentWindow'] as bool? ?? false;
    int? parentWindowHandle = args['parentWindowHandle'] as int?;

    final hr = CoInitializeEx(
      COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE,
    );

    if (hr.isError) {
      throw WindowsException(hr);
    }

    try {
      return using((arena) {
        final fileDialog = arena.com<IFileOpenDialog>(FileOpenDialog);

        final options =
            fileDialog.getOptions() |
            FOS_PICKFOLDERS |
            FOS_FORCEFILESYSTEM |
            FOS_NOCHANGEDIR;
        fileDialog.setOptions(FILEOPENDIALOGOPTIONS(options));

        fileDialog.setTitle(arena.pcwstr(dialogTitle ?? 'Select Folder'));

        if (initialDirectory != null) {
          final item = arena.adopt(
            SHCreateItemFromParsingName<IShellItem>(
              arena.pcwstr(initialDirectory),
              null,
            ),
          );
          fileDialog.setFolder(item);
        }

        try {
          HWND? parentHwnd;
          if (lockParentWindow) {
            parentHwnd = parentWindowHandle != null
                ? Pointer.fromAddress(parentWindowHandle) as HWND
                : GetForegroundWindow();
          }
          fileDialog.show(parentHwnd);
        } on WindowsException catch (e) {
          if (e.hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
            return null;
          }
          rethrow;
        }

        final selectedItem = fileDialog.getResult();
        if (selectedItem == null) {
          return null;
        }

        final item = arena.adopt(selectedItem);
        final pathPtr = item.getDisplayName(SIGDN_FILESYSPATH);
        try {
          return pathPtr.toDartString();
        } finally {
          CoTaskMemFree(pathPtr);
        }
      });
    } finally {
      CoUninitialize();
    }
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const FilePickerWindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final FilePickerWindowsOptions options = switch (windowsOptions) {
      FilePickerWindowsOptions opts => opts,
      _ => const FilePickerWindowsOptions(),
    };

    final port = ReceivePort();
    await Isolate.spawn(
      _callSaveFile,
      _OpenSaveFileArgs(
        port: port.sendPort,
        defaultFileName: fileName,
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        lockParentWindow: options.lockParentWindow,
        confirmOverwrite: true,
        parentWindowHandle: options.parentWindowHandle,
      ),
    );

    final savedFilePath = (await port.first) as String?;
    if (savedFilePath != null) {
      final file = File(savedFilePath);
      await file.writeAsBytes(bytes);
      return Uri.file(savedFilePath);
    }

    return null;
  }

  List<String>? _pickFiles(_OpenSaveFileArgs args) {
    final comdlg32 = DynamicLibrary.open('comdlg32.dll');

    final getOpenFileNameW = comdlg32
        .lookupFunction<GetOpenFileNameW, GetOpenFileNameWDart>(
          'GetOpenFileNameW',
        );

    final Pointer<OPENFILENAMEW> openFileNameW = _instantiateOpenFileNameW(
      args,
    );

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

  String? _saveFile(_OpenSaveFileArgs args) {
    final comdlg32 = DynamicLibrary.open('comdlg32.dll');

    final getSaveFileNameW = comdlg32
        .lookupFunction<GetSaveFileNameW, GetSaveFileNameWDart>(
          'GetSaveFileNameW',
        );

    final Pointer<OPENFILENAMEW> openFileNameW = _instantiateOpenFileNameW(
      args,
    );

    final result = getSaveFileNameW(openFileNameW);
    String? returnValue;
    if (result == 1) {
      final filePaths = extractSelectedFilesFromOpenFileNameW(
        openFileNameW.ref,
        isResultFromSaveFileDialog: true,
      );
      returnValue = filePaths.firstOrNull;
    }

    _freeMemory(openFileNameW);
    return returnValue;
  }

  String fileTypeToFileFilter(FileType type, List<String>? allowedExtensions) {
    if (type == FileType.custom &&
        (allowedExtensions == null || allowedExtensions.isEmpty)) {
      throw ArgumentError(
        'If type is set to FileType.custom, allowedExtensions cannot be null or empty.',
      );
    }
    switch (type) {
      case FileType.any:
        return 'All Files (*.*)\x00*.*\x00\x00';
      case FileType.audio:
        return 'Audios (*.aac,*.midi,*.mp3,*.ogg,*.wav,*.m4a)\x00*.aac;*.midi;*.mp3;*.ogg;*.wav;*.m4a\x00\x00';
      case FileType.custom:
        return 'Files (*.${allowedExtensions!.join(',*.')})\x00*.${allowedExtensions.join(';*.')}\x00\x00';
      case FileType.image:
        return 'Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png,*.webp)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png;*.webp\x00\x00';
      case FileType.media:
        return 'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png\x00\x00';
      case FileType.video:
        return 'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00\x00';
    }
  }

  void validateFileName(String fileName) {
    if (fileName.contains(RegExp(r'[<>:/\\|?*"]'))) {
      throw ArgumentError(
        'Reserved characters may not be used in file names. See: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions',
      );
    }
  }

  List<String> extractSelectedFilesFromOpenFileNameW(
    OPENFILENAMEW openFileNameW, {
    bool isResultFromSaveFileDialog = false,
  }) {
    final List<String> filePaths = [];
    final buffer = StringBuffer();
    int i = 0;
    bool lastCharWasNull = false;
    while (true) {
      final char = openFileNameW.lpstrFile.cast<Uint16>()[i];
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
    openFileNameW.ref.lpstrTitle = (args.dialogTitle ?? 'Select File')
        .toNativeUtf16();
    openFileNameW.ref.lpstrFile = calloc.allocate<Utf16>(lpstrFileBufferSize);
    openFileNameW.ref.lpstrFilter = fileTypeToFileFilter(
      args.type,
      args.allowedExtensions,
    ).toNativeUtf16();
    openFileNameW.ref.nMaxFile = lpstrFileBufferSize;
    openFileNameW.ref.lpstrInitialDir = (args.initialDirectory ?? '')
        .toNativeUtf16();
    openFileNameW.ref.flags =
        ofnExplorer | ofnFileMustExist | ofnHideReadOnly | ofnNoChangeDir;

    if (args.lockParentWindow) {
      openFileNameW.ref.hwndOwner = args.parentWindowHandle != null
          ? Pointer.fromAddress(args.parentWindowHandle!)
          : _getWindowHandle();
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

    final findWindowA = user32
        .lookupFunction<
          Int32 Function(Pointer<Utf8> lpClassName, Pointer<Utf8> lpWindowName),
          int Function(Pointer<Utf8> lpClassName, Pointer<Utf8> lpWindowName)
        >('FindWindowA');

    int hWnd = findWindowA(
      'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf8(),
      nullptr,
    );

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

  final bool allowMultiple;
  final bool lockParentWindow;
  final bool confirmOverwrite;
  final int? parentWindowHandle;

  _OpenSaveFileArgs({
    required this.port,
    this.defaultFileName,
    this.dialogTitle,
    this.initialDirectory,
    this.type = FileType.any,
    this.allowedExtensions,
    this.allowMultiple = false,
    this.lockParentWindow = false,
    this.confirmOverwrite = false,
    this.parentWindowHandle,
  });
}
