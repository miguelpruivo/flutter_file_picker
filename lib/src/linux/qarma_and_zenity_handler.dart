import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/linux/dialog_handler.dart';

class QarmaAndZenityHandler implements DialogHandler {
  @override
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

  @override
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

  @override
  List<String> resultStringToFilePaths(String fileSelectionResult) {
    if (fileSelectionResult.trim().isEmpty) {
      return [];
    }
    return fileSelectionResult
        .split('|/')
        .map((String path) => path.startsWith('/') ? path : '/' + path)
        .toList();
  }
}
