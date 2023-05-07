import 'dart:async';
import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/file_picker_result.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:file_picker/src/utils.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

class FilePickerLinux extends FilePicker {
  XdgFileChooserFilter _fileTypeToFileFilter(
      FileType type, List<String>? allowedExtensions) {
    switch (type) {
      case FileType.any:
        return XdgFileChooserFilter(
            'Any files', [XdgFileChooserGlobPattern('*.*')]);
      case FileType.audio:
        return XdgFileChooserFilter(
            'Audio File', [XdgFileChooserMimeTypePattern('audio/*')]);
      case FileType.custom:
        final fileTypes = '*.${allowedExtensions!.join(', *.')}';
        final globPatterns =
            allowedExtensions.map((p) => XdgFileChooserGlobPattern('*.$p'));
        return XdgFileChooserFilter(
            'Custom file types ($fileTypes)', globPatterns);
      case FileType.image:
        return XdgFileChooserFilter(
            'Image File', [XdgFileChooserMimeTypePattern('image/*')]);
      case FileType.media:
        return XdgFileChooserFilter('Media File', [
          XdgFileChooserMimeTypePattern('image/*'),
          XdgFileChooserMimeTypePattern('video/*'),
        ]);
      case FileType.video:
        return XdgFileChooserFilter(
            'Video Files', [XdgFileChooserMimeTypePattern('video/*')]);
      default:
        throw Exception('unknown file type');
    }
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    final client = XdgDesktopPortalClient();

    final fileFilter = _fileTypeToFileFilter(
      type,
      allowedExtensions,
    );

    final result = await client.fileChooser
        .openFile(
          title: dialogTitle ?? defaultDialogTitle,
          filters: [fileFilter],
          multiple: allowMultiple,
          directory: false,
        )
        .first;

    final filePaths = result.uris;

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
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    final client = XdgDesktopPortalClient();

    final result = await client.fileChooser
        .openFile(
          title: dialogTitle ?? defaultDialogTitle,
          directory: true,
        )
        .first;

    return result.uris.first;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
  }) async {
    final client = XdgDesktopPortalClient();

    final fileFilter = _fileTypeToFileFilter(
      type,
      allowedExtensions,
    );

/*
    Uint8List? directory;
    if (initialDirectory != null) {
      final dir = Directory(initialDirectory);
      print(dir.absolute.path);
      final encodedDirectory = utf8.encode(dir.absolute.path);
      directory = Uint8List.fromList(encodedDirectory);
    }
*/

    final result = await client.fileChooser
        .saveFile(
          title: dialogTitle ?? defaultDialogTitle,
          filters: [fileFilter],
          currentName: fileName,
          //currentFolder: directory,
        )
        .first;
    return result.uris.first;
  }
}
