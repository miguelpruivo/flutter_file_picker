import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/utils.dart';

class FilePickerMacOS extends FilePicker {
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
    final String executable = await isExecutableOnPath('osascript');
    final String fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );
    final List<String> arguments = generateCommandLineArguments(
      escapeDialogTitle(dialogTitle ?? defaultDialogTitle),
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
    final String executable = await isExecutableOnPath('osascript');
    final List<String> arguments = generateCommandLineArguments(
      escapeDialogTitle(dialogTitle ?? defaultDialogTitle),
      pickDirectory: true,
    );

    final String? directorySelectionResult = await runExecutableWithArguments(
      executable,
      arguments,
    );
    if (directorySelectionResult == null) {
      return null;
    }

    return resultStringToFilePaths(directorySelectionResult).first;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final String executable = await isExecutableOnPath('osascript');
    final String fileFilter = fileTypeToFileFilter(
      type,
      allowedExtensions,
    );
    final List<String> arguments = generateCommandLineArguments(
      escapeDialogTitle(dialogTitle ?? defaultDialogTitle),
      fileFilter: fileFilter,
      fileName: fileName ?? '',
      saveFile: true,
    );

    final String? saveFileResult = await runExecutableWithArguments(
      executable,
      arguments,
    );
    if (saveFileResult == null) {
      return null;
    }

    return resultStringToFilePaths(saveFileResult).first;
  }

  String fileTypeToFileFilter(FileType type, List<String>? allowedExtensions) {
    switch (type) {
      case FileType.any:
        return '';
      case FileType.audio:
        return '"", "mp3", "wav", "midi", "ogg", "aac"';
      case FileType.custom:
        return '"", "' + allowedExtensions!.join('", "') + '"';
      case FileType.image:
        return '"", "jpg", "jpeg", "bmp", "gif", "png"';
      case FileType.media:
        return '"", "webm", "mpeg", "mkv", "mp4", "avi", "mov", "flv", "jpg", "jpeg", "bmp", "gif", "png"';
      case FileType.video:
        return '"", "webm", "mpeg", "mkv", "mp4", "avi", "mov", "flv"';
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
    final arguments = ['-e'];

    String argument = 'choose ';
    if (pickDirectory) {
      argument += 'folder ';
    } else {
      argument += 'file ';

      if (saveFile) {
        argument += 'name ';

        if (fileName.isNotEmpty) {
          argument += 'default name "$fileName" ';
        }
      } else {
        argument += 'of type {$fileFilter} ';

        if (multipleFiles) {
          argument += 'with multiple selections allowed ';
        }
      }
    }

    argument += 'with prompt "$dialogTitle"';
    arguments.add(argument);

    return arguments;
  }

  String escapeDialogTitle(String dialogTitle) => dialogTitle
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\\n');

  /// Transforms the result string (stdout) of `osascript` into a [List] of
  /// file paths.
  List<String> resultStringToFilePaths(String fileSelectionResult) {
    if (fileSelectionResult.trim().isEmpty) {
      return [];
    }
    return fileSelectionResult
        .trim()
        .split(', ')
        .map((String path) => path.trim())
        .where((String path) => path.isNotEmpty)
        .map((String path) {
      final pathElements = path.split(':').where((e) => e.isNotEmpty).toList();

      // First token is either "alias" or "file" (in case of saveFile dialog)
      final volumeName = pathElements[0].split(' ').sublist(1).join(' ');
      return ['/Volumes', volumeName, ...pathElements.sublist(1)].join('/');
    }).toList();
  }
}
