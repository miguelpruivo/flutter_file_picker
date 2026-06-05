import 'package:flutter/material.dart';

import 'file_picker_results.dart';

class PickedDirectoryResult extends StatelessWidget {
  const PickedDirectoryResult({
    super.key,
    required this.pickedDirectoryPath,
    required this.onDirectoryRemoved,
  });

  final String? pickedDirectoryPath;
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

        final Widget? trailingWidget = isContentUri
            ? IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
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
