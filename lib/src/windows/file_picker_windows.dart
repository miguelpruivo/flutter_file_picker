import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/utils.dart';
import 'package:file_picker/src/exceptions.dart';
import 'package:file_picker/src/windows/file_picker_windows_ffi_types.dart';
import 'package:path/path.dart';

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
    final comdlg32 = DynamicLibrary.open('comdlg32.dll');

    final getOpenFileNameW =
        comdlg32.lookupFunction<GetOpenFileNameW, GetOpenFileNameWDart>(
            'GetOpenFileNameW');

    final Pointer<OPENFILENAMEW> openFileNameW = _instantiateOpenFileNameW(
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      lockParentWindow: lockParentWindow,
    );

    final result = getOpenFileNameW(openFileNameW);
    FilePickerResult? returnValue;
    if (result == 1) {
      final filePaths = _extractSelectedFilesFromOpenFileNameW(
        openFileNameW.ref,
      );
      final platformFiles = await filePathsToPlatformFiles(
        filePaths,
        withReadStream,
        withData,
      );

      returnValue = FilePickerResult(platformFiles);
    }

    _freeMemory(openFileNameW);
    return returnValue;
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) {
    final pathIdPointer =
        _pickDirectory(dialogTitle ?? defaultDialogTitle, lockParentWindow);
    if (pathIdPointer == null) {
      return Future.value(null);
    }
    return Future.value(
      _getPathFromItemIdentifierList(pathIdPointer),
    );
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
    final comdlg32 = DynamicLibrary.open('comdlg32.dll');

    final getSaveFileNameW =
        comdlg32.lookupFunction<GetSaveFileNameW, GetSaveFileNameWDart>(
            'GetSaveFileNameW');

    final Pointer<OPENFILENAMEW> openFileNameW = _instantiateOpenFileNameW(
      allowedExtensions: allowedExtensions,
      defaultFileName: fileName,
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      lockParentWindow: lockParentWindow,
    );

    final result = getSaveFileNameW(openFileNameW);
    String? returnValue;
    if (result == 1) {
      final filePaths = _extractSelectedFilesFromOpenFileNameW(
        openFileNameW.ref,
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

  /// Uses the Win32 API to display a dialog box that enables the user to select a folder.
  ///
  /// Returns a PIDL that specifies the location of the selected folder relative to the root of the
  /// namespace. Returns null, if the user clicked on the "Cancel" button in the dialog box.
  Pointer? _pickDirectory(String dialogTitle, bool lockParentWindow) {
    final shell32 = DynamicLibrary.open('shell32.dll');

    final shBrowseForFolderW =
        shell32.lookupFunction<SHBrowseForFolderW, SHBrowseForFolderW>(
            'SHBrowseForFolderW');

    final Pointer<BROWSEINFOA> browseInfo = calloc<BROWSEINFOA>();
    if (lockParentWindow) {
      browseInfo.ref.hwndOwner = _getWindowHandle();
    }
    browseInfo.ref.pidlRoot = nullptr;
    browseInfo.ref.pszDisplayName = calloc.allocate<Utf16>(maximumPathLength);
    browseInfo.ref.lpszTitle = dialogTitle.toNativeUtf16();
    browseInfo.ref.ulFlags =
        bifEditBox | bifNewDialogStyle | bifReturnOnlyFsDirs;

    final Pointer<NativeType> itemIdentifierList =
        shBrowseForFolderW(browseInfo);

    calloc.free(browseInfo.ref.pszDisplayName);
    calloc.free(browseInfo.ref.lpszTitle);
    calloc.free(browseInfo);

    if (itemIdentifierList == nullptr) {
      return null;
    }
    return itemIdentifierList;
  }

  /// Uses the Win32 API to convert an item identifier list to a file system path.
  ///
  /// [lpItem] must contain the address of an item identifier list that specifies a
  /// file or directory location relative to the root of the namespace (the desktop).
  /// Returns the file system path as a [String]. Throws an exception, if the
  /// conversion wasn't successful.
  String _getPathFromItemIdentifierList(Pointer lpItem) {
    final shell32 = DynamicLibrary.open('shell32.dll');

    final shGetPathFromIDListW =
        shell32.lookupFunction<SHGetPathFromIDListW, SHGetPathFromIDListWDart>(
            'SHGetPathFromIDListW');

    final Pointer<Utf16> pszPath = calloc.allocate<Utf16>(maximumPathLength);

    final int result = shGetPathFromIDListW(lpItem, pszPath);
    if (result == 0x00000000) {
      throw Exception(
          'Failed to convert item identifier list to a file system path.');
    }

    final path = pszPath.toDartString();
    calloc.free(pszPath);
    return path;
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
  List<String> _extractSelectedFilesFromOpenFileNameW(
    OPENFILENAMEW openFileNameW,
  ) {
    final List<String> filePaths = [];
    final buffer = StringBuffer();
    int i = 0;
    bool lastCharWasNull = false;

    // ignore: literal_only_boolean_expressions
    while (true) {
      final char = openFileNameW.lpstrFile.cast<Uint16>().elementAt(i).value;
      if (char == 0) {
        if (lastCharWasNull) {
          break;
        } else {
          filePaths.add(buffer.toString());
          buffer.clear();
          lastCharWasNull = true;
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

  Pointer<OPENFILENAMEW> _instantiateOpenFileNameW({
    bool allowMultiple = false,
    String? dialogTitle,
    String? defaultFileName,
    String? initialDirectory,
    List<String>? allowedExtensions,
    FileType type = FileType.any,
    bool lockParentWindow = false,
  }) {
    final lpstrFileBufferSize = 8192 * maximumPathLength;
    final Pointer<OPENFILENAMEW> openFileNameW = calloc<OPENFILENAMEW>();

    openFileNameW.ref.lStructSize = sizeOf<OPENFILENAMEW>();
    openFileNameW.ref.lpstrTitle =
        (dialogTitle ?? defaultDialogTitle).toNativeUtf16();
    openFileNameW.ref.lpstrFile = calloc.allocate<Utf16>(lpstrFileBufferSize);
    openFileNameW.ref.lpstrFilter =
        fileTypeToFileFilter(type, allowedExtensions).toNativeUtf16();
    openFileNameW.ref.nMaxFile = lpstrFileBufferSize;
    openFileNameW.ref.lpstrInitialDir =
        (initialDirectory ?? '').toNativeUtf16();
    openFileNameW.ref.flags = ofnExplorer | ofnFileMustExist | ofnHideReadOnly;

    if (lockParentWindow) {
      openFileNameW.ref.hwndOwner = _getWindowHandle();
    }

    if (allowMultiple) {
      openFileNameW.ref.flags |= ofnAllowMultiSelect;
    }

    if (defaultFileName != null) {
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

  Pointer _getWindowHandle() {
    final _user32 = DynamicLibrary.open('user32.dll');

    final findWindowA = _user32.lookupFunction<
        Int32 Function(Pointer<Utf8> _lpClassName, Pointer<Utf8> _lpWindowName),
        int Function(Pointer<Utf8> _lpClassName,
            Pointer<Utf8> _lpWindowName)>('FindWindowA');

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
}
