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
  }) async {
    final String executable = await _getPathToExecutable();
    final String fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );
    final List<String> arguments = generateCommandLineArguments(
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
  }) async {
    final executable = await _getPathToExecutable();
    final arguments = generateCommandLineArguments(
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
  }) async {
    final executable = await _getPathToExecutable();
    final String fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );
    final arguments = generateCommandLineArguments(
      dialogTitle ?? defaultDialogTitle,
      fileFilter: fileFilter,
      fileName: fileName ?? '',
      saveFile: true,
    );
    return await runExecutableWithArguments(executable, arguments);
  }

  /// Returns the path to the executables `qarma` or `zenity` as a [String].
  ///
  /// On Linux, the CLI tools `qarma` or `zenity` can be used to open a native
  /// file picker dialog. It seems as if all Linux distributions have at least
  /// one of these two tools pre-installed (on Ubuntu `zenity` is pre-installed).
  /// The future returns an error, if neither of both executables was found on
  /// the path.
  Future<String> _getPathToExecutable() async {
    try {
      return await isExecutableOnPath('qarma');
    } on Exception {
      return await isExecutableOnPath('zenity');
    }
  }

  String fileTypeToFileFilter(FileType type, List<String>? allowedExtensions) {
    switch (type) {
      case FileType.any:
        return '';
      case FileType.audio:
        return '*.mp3 *.wav *.midi *.ogg *.aac';
      case FileType.custom:
        return '*.' + allowedExtensions!.join(' *.');
      case FileType.image:
        return '*.bmp *.gif *.jpg *.jpeg *.png';
      case FileType.media:
        return '*.webm *.mpeg *.mkv *.mp4 *.avi *.mov *.flv *.jpg *.jpeg *.bmp *.gif *.png';
      case FileType.video:
        return '*.webm *.mpeg *.mkv *.mp4 *.avi *.mov *.flv';
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

  /// Transforms the result string (stdout) of `qarma` / `zenity` into a [List]
  /// of file paths.
  List<String> resultStringToFilePaths(String fileSelectionResult) {
    if (fileSelectionResult.trim().isEmpty) {
      return [];
    }
    return fileSelectionResult.split('|');
  }
}
