// An example demonstrating the usage of file_picker.
import 'package:file_picker/file_picker.dart';

Future<void> main() async {
  // Pick a single file.
  final PlatformFile? file = await FilePicker.pickFile();
  if (file != null) {
    print('Picked ${file.name} (${await file.length()} bytes).');
  }

  // Pick multiple files, filtered by extension.
  final List<PlatformFile> images = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg'],
  );
  print('Picked ${images.length} image(s).');

  // Pick a directory.
  final String? directoryPath = await FilePicker.getDirectoryPath();
  print('Picked directory: $directoryPath');
}
