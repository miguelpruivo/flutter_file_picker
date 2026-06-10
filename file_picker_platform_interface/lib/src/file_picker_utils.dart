import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import '../file_picker.dart';
import 'package:path/path.dart';

/// Utility class for [FilePicker] that provides common helper methods
/// used across different platform implementations.
class FilePickerUtils {
  /// The default title for the file picker dialog.
  static const String defaultDialogTitle = 'File Picker';

  /// Converts a list of file paths into a list of [PlatformFile]s.
  static Future<List<PlatformFile>> filePathsToPlatformFiles(
    List<String> filePaths,
    bool withReadStream,
    bool withData,
  ) {
    return Future.wait(
      filePaths.where((String filePath) => filePath.isNotEmpty).map((
        String filePath,
      ) async {
        final file = File(filePath);

        if (withReadStream) {
          return createPlatformFile(file, null, file.openRead());
        }

        if (!withData) {
          return createPlatformFile(file, null, null);
        }

        final bytes = await file.readAsBytes();
        return createPlatformFile(file, bytes, null);
      }).toList(),
    );
  }

  /// Creates a [PlatformFile] instance from a [File] object.
  static Future<PlatformFile> createPlatformFile(
    File file,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
  ) async => PlatformFile(
    bytes: bytes,
    name: basename(file.path),
    path: file.path,
    readStream: readStream,
    size: file.existsSync() ? file.lengthSync() : 0,
  );

  /// Runs an executable with the given arguments and returns the output.
  static Future<String?> runExecutableWithArguments(
    String executable,
    List<String> arguments,
  ) async {
    final processResult = await Process.run(executable, arguments);
    final path = processResult.stdout?.toString().trim();
    if (processResult.exitCode != 0 || path == null || path.isEmpty) {
      return null;
    }
    return path;
  }

  /// Checks if an executable exists on the system path using `which`.
  static Future<String> isExecutableOnPath(String executable) async {
    final path = await runExecutableWithArguments('which', [executable]);
    if (path == null) {
      throw Exception('Couldn\'t find the executable $executable in the path.');
    }
    return path;
  }

  /// Saves the given [bytes] to a file at [path].
  static Future<void> saveBytesToFile(Uint8List? bytes, String? path) async {
    if (path != null && bytes != null && bytes.isNotEmpty) {
      final receivePort = ReceivePort();
      final transferable = TransferableTypedData.fromList([bytes]);

      await Isolate.spawn(_saveBytesIsolateEntry, [
        receivePort.sendPort,
        path,
        transferable,
      ]);

      final result = await receivePort.first;
      receivePort.close();
      if (result is Exception) {
        throw result;
      }
    }
  }

  static bool isAlpha(String x) {
    if (x.isEmpty) return false;
    final int codeUnit = x.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }
}

Future<void> _saveBytesIsolateEntry(List<Object?> args) async {
  if (args case [
    SendPort send,
    String path,
    TransferableTypedData transferable,
  ]) {
    try {
      final Uint8List bytes = transferable.materialize().asUint8List();
      final file = File(path);
      await file.writeAsBytes(bytes);
      send.send(null);
    } catch (e) {
      send.send(e);
    }
    return;
  }

  if (args case [final SendPort port, ...]) {
    port.send(Exception('Invalid isolate arguments'));
  }
}
