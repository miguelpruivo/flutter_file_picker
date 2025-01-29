import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/linux/dialog_handler.dart';
import 'package:path/path.dart' as p;

class QarmaAndZenityHandler implements DialogHandler {
  @override
  List<String> generateCommandLineArguments(
    String dialogTitle, {
    String fileFilter = '',
    String fileName = '',
    String initialDirectory = '',
    bool multipleFiles = false,
    bool pickDirectory = false,
    bool saveFile = false,
  }) {
    final arguments = ['--file-selection', '--title', dialogTitle];

    if (saveFile) {
      arguments.addAll(['--save', '--confirm-overwrite']);
    }

    if (fileName.isNotEmpty && initialDirectory.isNotEmpty) {
      arguments.add('--filename=${p.join(initialDirectory, fileName)}');
    } else if (fileName.isNotEmpty) {
      arguments.add('--filename=$fileName');
    } else if (initialDirectory.isNotEmpty) {
      arguments.add('--filename=$initialDirectory');
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
        return "Audio Files | ${DialogHandler.toCaseInsensitive('*.aac *.midi *.mp3 *.ogg *.wav *.m4a')}";
      case FileType.custom:
        return "Custom Files | ${DialogHandler.toCaseInsensitive('*.${allowedExtensions!.join(' *.')}')}";
      case FileType.image:
        return "Image Files | ${DialogHandler.toCaseInsensitive('*.bmp *.gif *.jpeg *.jpg *.png')}";
      case FileType.media:
        return "Media Files | ${DialogHandler.toCaseInsensitive('*.avi *.flv *.mkv *.mov *.mp4 *.mpeg *.webm *.wmv *.bmp *.gif *.jpeg *.jpg *.png')}";
      case FileType.video:
        return "Video Files | ${DialogHandler.toCaseInsensitive('*.avi *.flv *.mkv *.mov *.mp4 *.mpeg *.webm *.wmv')}";
    }
  }

  @override
  List<String> resultStringToFilePaths(String fileSelectionResult) {
    if (fileSelectionResult.trim().isEmpty) {
      return [];
    }
    return fileSelectionResult
        .split('|/')
        .map((String path) => path.startsWith('/') ? path : '/$path')
        .toList();
  }
}
