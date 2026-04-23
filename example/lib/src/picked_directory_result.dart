import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'file_picker_results.dart';

class PickedDirectoryResult extends StatelessWidget {
  const PickedDirectoryResult({
    super.key,
    required this.pickedDirectoryPath,
    required this.readWriteAccess,
    required this.onDirectoryRemoved,
  });

  final String? pickedDirectoryPath;
  final bool readWriteAccess;
  final VoidCallback onDirectoryRemoved;

  @override
  Widget build(BuildContext context) {
    return FilePickerResultsList(
      itemCount: pickedDirectoryPath != null ? 1 : 0,
      itemBuilder: (BuildContext context, int index) {
        final directoryPath = pickedDirectoryPath;
        if (directoryPath == null) {
          return const SizedBox.shrink();
        }

        final isContentUri = directoryPath.startsWith('content://');

        final accessMode = readWriteAccess
            ? AndroidSAFAccessMode.readWrite
            : AndroidSAFAccessMode.readOnly;
        final Widget? trailingWidget = isContentUri
            ? IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
                  final safHandle = AndroidSAFHandle(
                    uri: Uri.parse(directoryPath),
                    accessMode: accessMode,
                  );
                  safHandle.releaseGrant();
                  onDirectoryRemoved();
                },
              )
            : null;

        return ListTile(
          title: Text(isContentUri ? 'Content URI:' : 'Filesystem path:'),
          subtitle: Text(directoryPath),
          trailing: trailingWidget,
        );
      },
    );
  }
}
