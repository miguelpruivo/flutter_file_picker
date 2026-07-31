import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'file_picker_results.dart';

typedef OnRemoveFile = void Function(int index, PlatformFile file);

class PickedFilesResults extends StatelessWidget {
  const PickedFilesResults({
    super.key,
    required this.pickedFiles,
    required this.onRemoveAndroidFile,
  });

  final List<PlatformFile>? pickedFiles;
  final OnRemoveFile onRemoveAndroidFile;

  @override
  Widget build(BuildContext context) {
    return FilePickerResultsList(
      itemCount: pickedFiles?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        final pickedFile = pickedFiles![index];
        final isContentUri = pickedFile.uri.scheme == 'content';
        final Widget? trailingWidget = isContentUri
            ? IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () => onRemoveAndroidFile(index, pickedFile),
              )
            : null;
        final path = '${pickedFile.path ?? pickedFile.uri}';

        return ListTile(
          leading: Text(
            index.toString(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          title: Text('File path (SAF Grant: $isContentUri):'),
          subtitle: Text(path),
          trailing: trailingWidget,
        );
      },
    );
  }
}
