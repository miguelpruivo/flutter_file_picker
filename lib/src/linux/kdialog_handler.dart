import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/linux/dialog_handler.dart';

class KDialogHandler implements DialogHandler {
  @override
  List<String> generateCommandLineArguments(
    String dialogTitle, {
    String fileFilter = '',
    String fileName = '',
    bool multipleFiles = false,
    bool pickDirectory = false,
    bool saveFile = false,
  }) {
    final arguments = ['--title', dialogTitle];

    // Choose right dialog
    if (saveFile && !pickDirectory) {
      arguments.add('--getsavefilename');
    } else if (!saveFile && !pickDirectory) {
      arguments.add('--getopenfilename');
    } else {
      arguments.add('--getexistingdirectory');
    }

    // Start directory for the dialog
    if (fileName.isNotEmpty) {
      arguments.add(fileName);
    }

    if (!pickDirectory && fileFilter.isNotEmpty) {
      // In order to specify a filter, a start directory has to be specified
      if (fileName.isEmpty) {
        arguments.add('.');
      }
      arguments.add(fileFilter);
    }

    // TODO: not working
    if (multipleFiles) {
      arguments.add('--multiple');
    }

    return arguments;
  }

  @override
  String fileTypeToFileFilter(
    FileType type,
    List<String>? allowedExtensions,
  ) {
    // TODO: implement fileTypeToFileFilter
    throw UnimplementedError();
  }

  @override
  List<String> resultStringToFilePaths(String fileSelectionResult) {
    // TODO: implement resultStringToFilePaths
    throw UnimplementedError();
  }
}
