import 'dart:async';
import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/file_picker_result.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:file_picker/src/utils.dart';

class FilePickerLinux extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    final String executable = await _getPathToExecutable();
    final String fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );

    final List<String> arguments = (executable.contains('kdialog'))
        ? generateKdialogArguments(
            dialogTitle ?? defaultDialogTitle,
            fileFilter: fileFilter,
            multipleFiles: allowMultiple,
            pickDirectory: false,
          )
        : generateCommandLineArguments(
            dialogTitle ?? defaultDialogTitle,
            fileFilter: fileFilter,
            multipleFiles: allowMultiple,
            pickDirectory: false,
          );

    final String? fileSelectionResult = await runExecutableWithArguments(
      executable,
      arguments,
    );
    if (fileSelectionResult == null) {
      return null;
    }

    final List<String> filePaths = resultStringToFilePaths(
      fileSelectionResult,
    );
    final List<PlatformFile> platformFiles = await filePathsToPlatformFiles(
      filePaths,
      withReadStream,
      withData,
    );

    return FilePickerResult(platformFiles);
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
  }) async {
    final executable = await _getPathToExecutable();
    final List<String> arguments = (executable.contains('kdialog'))
        ? generateKdialogArguments(
            dialogTitle ?? defaultDialogTitle,
            pickDirectory: true,
          )
        : generateCommandLineArguments(
            dialogTitle ?? defaultDialogTitle,
            pickDirectory: true,
          );
    return await runExecutableWithArguments(executable, arguments);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
  }) async {
    final executable = await _getPathToExecutable();
    final String fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );
    final List<String> arguments = (executable.contains('kdialog'))
        ? generateKdialogArguments(
            dialogTitle ?? defaultDialogTitle,
            fileFilter: fileFilter,
            fileName: fileName ?? '',
            saveFile: true,
          )
        : generateCommandLineArguments(
            dialogTitle ?? defaultDialogTitle,
            fileFilter: fileFilter,
            fileName: fileName ?? '',
            saveFile: true,
          );
    return await runExecutableWithArguments(executable, arguments);
  }

  /// Returns the path to the executables `qarma`, `zenity` or `kdialog` as a
  /// [String].
  /// On Linux, the CLI tools `qarma` or `zenity` can be used to open a native
  /// file picker dialog. It seems as if all Linux distributions have at least
  /// one of these two tools pre-installed (on Ubuntu `zenity` is pre-installed).
  /// On distribuitions that use KDE Plasma as their Desktop Environment,
  /// `kdialog` is used to achieve these functionalities.
  /// The future returns an error, if none of the executables was found on
  /// the path.
  Future<String> _getPathToExecutable() async {
    try {
      try {
        return await isExecutableOnPath('qarma');
      } on Exception {
        return await isExecutableOnPath('kdialog');
      }
    } on Exception {
      return await isExecutableOnPath('zenity');
    }
  }

  String fileTypeToFileFilter(FileType type, List<String>? allowedExtensions) {
    switch (type) {
      case FileType.any:
        return '';
      case FileType.audio:
        return '*.aac *.midi *.mp3 *.ogg *.wav';
      case FileType.custom:
        return '*.' + allowedExtensions!.join(' *.');
      case FileType.image:
        return '*.bmp *.gif *.jpeg *.jpg *.png';
      case FileType.media:
        return '*.avi *.flv *.mkv *.mov *.mp4 *.mpeg *.webm *.wmv *.bmp *.gif *.jpeg *.jpg *.png';
      case FileType.video:
        return '*.avi *.flv *.mkv *.mov *.mp4 *.mpeg *.webm *.wmv';
      default:
        throw Exception('unknown file type');
    }
  }

  List<String> generateCommandLineArguments(
    String dialogTitle, {
    String fileFilter = '',
    String fileName = '',
    bool multipleFiles = false,
    bool pickDirectory = false,
    bool saveFile = false,
  }) {
    final arguments = ['--file-selection', '--title', dialogTitle];

    if (saveFile) {
      arguments.add('--save');
      if (fileName.isNotEmpty) {
        arguments.add('--filename=$fileName');
      }
    }

    if (fileFilter.isNotEmpty) {
      arguments.add('--file-filter=$fileFilter');
    }

    if (multipleFiles) {
      arguments.add('--multiple');
    }

    if (pickDirectory) {
      arguments.add('--directory');
    }

    return arguments;
  }

  List<String> generateKdialogArguments(
    String dialogTitle, {
    String fileFilter = '',
    String fileName = '',
    bool multipleFiles = false,
    bool pickDirectory = false,
    bool saveFile = false,
  }) {
    final arguments = ['--title', dialogTitle];

    if (saveFile) {
      arguments.add('--getsavefilename');
      if (fileName.isNotEmpty) {
        arguments.add(fileName);
      }
    }

    if (fileFilter.isNotEmpty) {
      arguments.add(fileFilter);
    }

    if (multipleFiles) {
      arguments.add('--multiple');
    }

    if (pickDirectory) {
      arguments.add('--getexistingdirectory');
    }

    return arguments;
  }

  /// Transforms the result string (stdout) of `qarma`, `zenity` or `kdialog` into a [List]
  /// of file paths.
  List<String> resultStringToFilePaths(String fileSelectionResult) {
    if (fileSelectionResult.trim().isEmpty) {
      return [];
    }
    return fileSelectionResult.split('|');
  }
}
