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
import 'open_save_file_args.dart';
import 'windows_platform_file.dart';

/// An implementation of [FilePickerPlatform] for Windows.
class FilePickerWindows extends FilePickerPlatform {
  /// Registers this class as the default instance of [FilePickerPlatform].
  static void registerWith() {
    FilePickerPlatform.instance = FilePickerWindows();
  }

  /// The buffer size in characters allocated for `lpstrFile` in [OPENFILENAMEW].
  static const _lpstrFileBufferSize = 8192 * maximumPathLength;

  /// Filter string for any file type.
  static const _anyFilter = 'All Files (*.*)\x00*.*\x00\x00';

  /// Filter string for audio file types.
  static const _audioFilter =
      'Audios (*.aac,*.midi,*.mp3,*.ogg,*.wav,*.m4a)\x00*.aac;*.midi;*.mp3;*.ogg;*.wav;*.m4a\x00\x00';

  /// Filter string for image file types.
  static const _imageFilter =
      'Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png,*.webp)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png;*.webp\x00\x00';

  /// Filter string for media (video and image) file types.
  static const _mediaFilter =
      'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00Images (*.bmp,*.gif,*.jpeg,*.jpg,*.png)\x00*.bmp;*.gif;*.jpeg;*.jpg;*.png\x00\x00';

  /// Filter string for video file types.
  static const _videoFilter =
      'Videos (*.avi,*.flv,*.mkv,*.mov,*.mp4,*.mpeg,*.webm,*.wmv)\x00*.avi;*.flv;*.mkv;*.mov;*.mp4;*.mpeg;*.webm;*.wmv\x00\x00';

  /// Private getter for opening the `comdlg32.dll` dynamic library.
  DynamicLibrary get _comdlg32 => DynamicLibrary.open('comdlg32.dll');

  /// Private getter for opening the `user32.dll` dynamic library.
  DynamicLibrary get _user32 => DynamicLibrary.open('user32.dll');

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
    final files = await _pickFilesInternal(
      allowMultiple: false,
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
    return _pickFilesInternal(
      allowMultiple: true,
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
      windowsOptions: windowsOptions,
    );
  }

  Future<List<PlatformFile>> _pickFilesInternal({
    required bool allowMultiple,
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    WindowsOptions windowsOptions = const FilePickerWindowsOptions(),
  }) async {
    final FilePickerWindowsOptions options = switch (windowsOptions) {
      FilePickerWindowsOptions opts => opts,
      _ => const FilePickerWindowsOptions(),
    };

    final port = ReceivePort();
    await Isolate.spawn(
      _callPickFiles,
      OpenSaveFileArgs(
        port: port.sendPort,
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
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

  /// Runs [IFileOpenDialog] inside a separate isolate to prompt for a directory path.
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
      OpenSaveFileArgs(
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

  /// Opens the Win32 file picker dialog using [GetOpenFileNameW].
  List<String>? _pickFiles(OpenSaveFileArgs args) {
    final getOpenFileNameW = _comdlg32
        .lookupFunction<GetOpenFileNameW, GetOpenFileNameWDart>(
          'GetOpenFileNameW',
        );

    final Pointer<OPENFILENAMEW> openFileNameW = _instantiateOpenFileNameW(
      args,
    );

    final result = getOpenFileNameW(openFileNameW);
    final files = switch (result) {
      1 => extractSelectedFilesFromOpenFileNameW(openFileNameW.ref),
      _ => null,
    };
    _freeMemory(openFileNameW);
    return files;
  }

  /// Opens the Win32 save file dialog using [GetSaveFileNameW].
  String? _saveFile(OpenSaveFileArgs args) {
    final getSaveFileNameW = _comdlg32
        .lookupFunction<GetSaveFileNameW, GetSaveFileNameWDart>(
          'GetSaveFileNameW',
        );

    final Pointer<OPENFILENAMEW> openFileNameW = _instantiateOpenFileNameW(
      args,
    );

    final result = getSaveFileNameW(openFileNameW);
    final returnValue = switch (result) {
      1 => extractSelectedFilesFromOpenFileNameW(
        openFileNameW.ref,
        isResultFromSaveFileDialog: true,
      ).firstOrNull,
      _ => null,
    };
    _freeMemory(openFileNameW);
    return returnValue;
  }

  /// Converts a [FileType] enum and allowed extension list into a null-terminated
  /// Win32 file filter string for `OPENFILENAMEW`.
  String fileTypeToFileFilter(FileType type, List<String>? allowedExtensions) {
    if (type == FileType.custom &&
        (allowedExtensions == null || allowedExtensions.isEmpty)) {
      throw ArgumentError(
        'If type is set to FileType.custom, allowedExtensions cannot be null or empty.',
      );
    }
    return switch (type) {
      FileType.any => _anyFilter,
      FileType.audio => _audioFilter,
      FileType.custom =>
        'Files (*.${allowedExtensions!.join(',*.')})\x00*.${allowedExtensions.join(';*.')}\x00\x00',
      FileType.image => _imageFilter,
      FileType.media => _mediaFilter,
      FileType.video => _videoFilter,
    };
  }

  /// Validates that a file name does not contain reserved Win32 characters.
  void validateFileName(String fileName) {
    if (fileName.contains(RegExp(r'[<>:/\\|?*"]'))) {
      throw ArgumentError(
        'Reserved characters may not be used in file names. See: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#naming-conventions',
      );
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
    final fileUnits = openFileNameW.lpstrFile.cast<Uint16>();
    int i = 0;
    bool lastCharWasNull = false;
    while (true) {
      final char = fileUnits[i];
      final currentCharIsNull = char == 0;
      if (currentCharIsNull && lastCharWasNull) {
        break;
      }

      if (currentCharIsNull) {
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
      return [for (final filePath in filePaths) join(directoryPath, filePath)];
    }

    return filePaths;
  }

  /// Allocates and populates an [OPENFILENAMEW] struct with native memory for Win32 API calls.
  Pointer<OPENFILENAMEW> _instantiateOpenFileNameW(OpenSaveFileArgs args) {
    final Pointer<OPENFILENAMEW> openFileNameW = calloc<OPENFILENAMEW>();

    openFileNameW.ref.lStructSize = sizeOf<OPENFILENAMEW>();
    openFileNameW.ref.lpstrTitle = (args.dialogTitle ?? 'Select File')
        .toNativeUtf16();
    openFileNameW.ref.lpstrFile = calloc.allocate<Utf16>(_lpstrFileBufferSize);
    openFileNameW.ref.lpstrFilter = fileTypeToFileFilter(
      args.type,
      args.allowedExtensions,
    ).toNativeUtf16();
    openFileNameW.ref.nMaxFile = _lpstrFileBufferSize;
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

    // Without lpstrDefExt, Windows does not append an extension when the
    // user types a file name without one, producing extension-less files.
    if (resolveDefaultExtension(args) case final defaultExtension?) {
      openFileNameW.ref.lpstrDefExt = defaultExtension.toNativeUtf16();
    }

    if (args.defaultFileName case final defaultFileName?) {
      validateFileName(defaultFileName);

      final Uint16List nativeString = openFileNameW.ref.lpstrFile
          .cast<Uint16>()
          .asTypedList(maximumPathLength);
      final safeName = defaultFileName.substring(
        0,
        min(maximumPathLength - 1, defaultFileName.length),
      );
      final units = safeName.codeUnits;
      nativeString.setRange(0, units.length, units);
      nativeString[units.length] = 0;
    }

    return openFileNameW;
  }

  /// Resolves the default extension (without a leading dot) that Windows
  /// appends via `lpstrDefExt` when the user types a file name without one.
  ///
  /// Prefers the first entry of [OpenSaveFileArgs.allowedExtensions], falling
  /// back to the extension of [OpenSaveFileArgs.defaultFileName].
  @visibleForTesting
  String? resolveDefaultExtension(OpenSaveFileArgs args) {
    return switch (args.allowedExtensions) {
      [final first, ...] => first,
      _ => switch (args.defaultFileName) {
        final name? when extension(name).length > 1 => extension(
          name,
        ).substring(1),
        _ => null,
      },
    };
  }

  /// Retrieves the HWND handle of the Flutter runner window using `user32.dll`.
  Pointer _getWindowHandle() {
    final findWindowA = _user32
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

  /// Frees allocated native memory for an [OPENFILENAMEW] pointer.
  void _freeMemory(Pointer<OPENFILENAMEW> openFileNameW) {
    calloc.free(openFileNameW.ref.lpstrTitle);
    calloc.free(openFileNameW.ref.lpstrFile);
    calloc.free(openFileNameW.ref.lpstrFilter);
    calloc.free(openFileNameW.ref.lpstrInitialDir);
    if (openFileNameW.ref.lpstrDefExt != nullptr) {
      calloc.free(openFileNameW.ref.lpstrDefExt);
    }
    calloc.free(openFileNameW);
  }

  /// Top-level isolate callback to invoke [_pickFiles].
  static void _callPickFiles(OpenSaveFileArgs args) {
    final impl = FilePickerWindows();
    args.port.send(impl._pickFiles(args));
  }

  /// Top-level isolate callback to invoke [_saveFile].
  static void _callSaveFile(OpenSaveFileArgs args) {
    final impl = FilePickerWindows();
    args.port.send(impl._saveFile(args));
  }
}
