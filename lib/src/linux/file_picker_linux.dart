import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/src/file_picker.dart';
import 'package:file_picker/src/file_picker_result.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:file_picker/src/utils.dart';
import 'package:file_picker/src/linux/xdp_filechooser.dart';
import 'package:file_picker/src/linux/xdp_request.dart';
import 'package:dbus/dbus.dart';

typedef FilterInfo = Map<String, List<(int, String)>>;

class Filter {
  FilterInfo info = {};
  Filter(FileType type, List<String>? allowedExtensions) {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw ArgumentError.value(
        allowedExtensions,
        'allowedExtensions',
        'Custom extension filters are only allowed with FileType.custom. '
            'Remove the extension filter or change the FileType to FileType.custom.',
      );
    }
    switch (type) {
      case FileType.any:
        return;
      case FileType.audio:
        final audio = ["*.aac", "*.midi", "*.mp3", "*.ogg", "*.wav"];
        List<(int, String)> audioList = [];
        for (var filter in audio) {
          audioList.add((0, filter));
        }
        info["Audio"] = audioList;
      case FileType.custom:
        final custom = [...?allowedExtensions];
        List<(int, String)> customList = [];
        for (var filter in custom) {
          customList.add((0, filter));
        }
        info["Custom"] = customList;
      case FileType.image:
        final image = ["*.bmp", "*.gif", "*.jpeg", "*.jpg", "*.png", "*.webp"];
        List<(int, String)> imageList = [];
        for (var filter in image) {
          imageList.add((0, filter));
        }
        info["Image"] = imageList;
      case FileType.media:
        final media = [
          "*.avi",
          "*.flv",
          "*.m4v",
          "*.mkv",
          "*.mov",
          "*.mp4",
          "*.mpeg",
          "*.webm",
          "*.wmv",
          "*.bmp",
          "*.gif",
          "*.jpeg",
          "*.jpg",
          "*.png"
        ];
        List<(int, String)> mediaList = [];
        for (var filter in media) {
          mediaList.add((0, filter));
        }
        info["Media"] = mediaList;
      case FileType.video:
        final video = [
          "*.avi",
          "*.flv",
          "*.mkv",
          "*.mov",
          "*.mp4",
          "*.m4v",
          "*.mpeg",
          "*.webm",
          "*.wmv"
        ];
        List<(int, String)> videoList = [];
        for (var filter in video) {
          videoList.add((0, filter));
        }
        info["Video"] = videoList;
    }
  }
  DBusArray toDBusArray() {
    List<DBusValue> dataList = [];
    info.forEach((var key, var values) {
      List<DBusStruct> tmpList = [];
      for (var (posO, val) in values) {
        final pos = DBusUint32(posO);
        final value = DBusString(val);
        tmpList.add(DBusStruct([pos, value]));
      }
      DBusValue dataArray = DBusArray(
          DBusSignature.struct([DBusSignature.uint32, DBusSignature.string]),
          tmpList);
      dataList.add(DBusStruct([DBusString(key), dataArray]));
    });

    return DBusArray(
        DBusSignature.struct([
          DBusSignature.string,
          DBusSignature.array(DBusSignature.struct(
              [DBusSignature.uint32, DBusSignature.string]))
        ]),
        dataList);
  }
}

class FilePickerLinux extends FilePicker {
  static void registerWith() {
    FilePicker.platform = FilePickerLinux();
  }

  final destination = "org.freedesktop.portal.Desktop";
  late final DBusClient _client;
  late final OrgFreedesktopPortalFileChooser _xdpChooser;

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
    final filter = Filter(type, allowedExtensions);
    Map<String, DBusValue> xdpOption = {
      'handle_token': DBusString('flutter_picker'),
      'multiple': DBusBoolean(allowMultiple),
      'modal': DBusBoolean(lockParentWindow),
      'filters': filter.toDBusArray(),
    };
    if (initialDirectory != null) {
      List<int> tmp = [];
      for (var i = 0; i < initialDirectory.length; i++) {
        tmp.add(initialDirectory[i].codeUnitAt(0));
      }
      DBusArray directory = DBusArray.byte(tmp);
      xdpOption["current_folder"] = directory;
    }
    final replyPath = await _xdpChooser.callOpenFile(
        "", dialogTitle ?? "flutter picker", xdpOption);

    List<Uri> uriPaths = [];

    final request =
        OrgFreedesktopPortalRequest(_client, destination, path: replyPath);

    await for (var response in request.response) {
      final status = response.response;
      // Maybe cancelled
      if (status != 0) {
        return null;
      }
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
    Map<String, DBusValue> xdpOption = {
      'handle_token': DBusString('flutter_picker'),
      'directory': DBusBoolean(true),
      'modal': DBusBoolean(lockParentWindow),
    };
    if (initialDirectory != null) {
      List<int> tmp = [];
      for (var i = 0; i < initialDirectory.length; i++) {
        tmp.add(initialDirectory[i].codeUnitAt(0));
      }
      DBusArray directory = DBusArray.byte(tmp);
      xdpOption["current_folder"] = directory;
    }
    final replyPath = await _xdpChooser.callOpenFile(
        "", dialogTitle ?? "flutter picker", xdpOption);

    List<Uri> uriPaths = [];

    final request =
        OrgFreedesktopPortalRequest(_client, destination, path: replyPath);

    await for (var response in request.response) {
      final status = response.response;
      // Maybe cancelled
      if (status != 0) {
        return null;
      }
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
    final filter = Filter(type, allowedExtensions);
    Map<String, DBusValue> xdpOption = {
      'handle_token': DBusString('flutter_picker'),
      'current_name': DBusString(fileName ?? ''),
      'modal': DBusBoolean(lockParentWindow),
      'filters': filter.toDBusArray(),
    };
    if (initialDirectory != null) {
      List<int> tmp = [];
      for (var i = 0; i < initialDirectory.length; i++) {
        tmp.add(initialDirectory[i].codeUnitAt(0));
      }
      DBusArray directory = DBusArray.byte(tmp);
      xdpOption["current_folder"] = directory;
    }

    final replyPath = await _xdpChooser.callSaveFile(
        "", dialogTitle ?? "flutter picker", xdpOption);
    final request =
        OrgFreedesktopPortalRequest(_client, destination, path: replyPath);

    List<Uri> saveUris = [];
    await for (var response in request.response) {
      final status = response.response;
      // Maybe cancelled
      if (status != 0) {
        return null;
      }
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
