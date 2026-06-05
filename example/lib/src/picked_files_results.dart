import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'file_picker_results.dart';

class PickedFilesResults extends StatelessWidget {
  const PickedFilesResults({
    super.key,
    required this.pickedFiles,
  });

  final List<PlatformFile>? pickedFiles;

  @override
  Widget build(BuildContext context) {
    return FilePickerResultsList(
      itemCount: pickedFiles?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        final pickedFile = pickedFiles![index];

        return ListTile(
          leading: Text(
            index.toString(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          title: const Text('File path: '),
          subtitle: Text(pickedFile.name),
        );
      },
    );
  }
}
