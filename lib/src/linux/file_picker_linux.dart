import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/file_picker_result.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:file_picker/src/utils.dart';
import 'package:file_picker/src/linux/xdp_filechooser.dart';
import 'package:file_picker/src/linux/xdg_request.dart';
import 'package:dbus/dbus.dart';

class FilePickerLinux extends FilePicker {
  static void registerWith() {
    FilePicker.platform = FilePickerLinux();
  }

  final destination = "org.freedesktop.portal.Desktop";
  late DBusClient _client;
  late OrgFreedesktopPortalFileChooser _xdpChooser;

  FilePickerLinux() : super() {
    _client = DBusClient.session();
    _xdpChooser = OrgFreedesktopPortalFileChooser(_client, destination,
        path: DBusObjectPath("/org/freedesktop/portal/desktop"));
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated(
        'allowCompression is deprecated and has no effect. Use compressionQuality instead.')
    bool allowCompression = false,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    int compressionQuality = 0,
  }) async {
    final replyPath =
        await _xdpChooser.callOpenFile("", dialogTitle ?? "flutter picker", {
      'handle_token': DBusString('flutter_picker'),
      'multiple': DBusBoolean(allowMultiple),
      'modal': DBusBoolean(lockParentWindow)
    });

    List<Uri> uriPaths = [];

    final request =
        OrgFreedesktopPortalRequest(_client, destination, path: replyPath);

    await for (var response in request.response) {
      final result = response.results;
      uriPaths = result["uris"]
              ?.asArray()
              .map((data) => Uri.parse(data.asString()))
              .toList() ??
          [];
      break;
    }

    final filePaths = uriPaths.map((uri) => uri.toFilePath()).toList();

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
    final replyPath =
        await _xdpChooser.callOpenFile("", dialogTitle ?? "flutter picker", {
      'handle_token': DBusString('flutter_picker'),
      'directory': DBusBoolean(true),
      'modal': DBusBoolean(lockParentWindow)
    });

    List<Uri> uriPaths = [];

    final request =
        OrgFreedesktopPortalRequest(_client, destination, path: replyPath);

    await for (var response in request.response) {
      final result = response.results;
      uriPaths = result["uris"]
              ?.asArray()
              .map((data) => Uri.parse(data.asString()))
              .toList() ??
          [];
      break;
    }

    final filePaths = uriPaths.map((uri) => uri.toFilePath()).toList();

    final List<PlatformFile> platformFiles = await filePathsToPlatformFiles(
      filePaths,
      false,
      false,
    );

    return platformFiles.firstOrNull?.path;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    final replyPath =
        await _xdpChooser.callSaveFile("", dialogTitle ?? "flutter picker", {
      'handle_token': DBusString('flutter_picker'),
      'current_name': DBusString(fileName ?? ''),
      'modal': DBusBoolean(lockParentWindow)
    });
    final request =
        OrgFreedesktopPortalRequest(_client, destination, path: replyPath);

    List<Uri> saveUris = [];
    await for (var response in request.response) {
      final result = response.results;
      saveUris = result["uris"]
              ?.asArray()
              .map((data) => Uri.parse(data.asString()))
              .toList() ??
          saveUris;
      break;
    }

    final savedFilePaths = saveUris.map((uri) => uri.toFilePath()).toList();

    return savedFilePaths.firstOrNull;
  }
}
