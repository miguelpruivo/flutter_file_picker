import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';

/// Utility class for [FilePicker] that provides common helper methods
/// used across different platform implementations.
class FilePickerUtils {
  /// The default title for the file picker dialog.
  static const String defaultDialogTitle = 'File Picker';

  /// Converts a list of file paths into a list of [PlatformFile]s.
  ///
  /// This method is useful when the platform file picker returns a list of paths
  /// and we need to convert them into the plugin's internal representation.
  ///
  /// [filePaths] is the list of absolute paths to the selected files.
  /// [withReadStream] if true, the [PlatformFile] will contain a read stream.
  /// [withData] if true, the [PlatformFile] will contain the file bytes (use carefully with large files).
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
  ///
  /// [file] is the source file.
  /// [bytes] are the file bytes (optional).
  /// [readStream] is a stream of the file content (optional).
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
  ///
  /// Returns the trimmed stdout as a [String], or null if the process fails
  /// (exit code != 0) or produces no output.
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
  ///
  /// Returns the absolute path to the executable if found.
  /// Throws an [Exception] if the executable is not found.
  static Future<String> isExecutableOnPath(String executable) async {
    final path = await runExecutableWithArguments('which', [executable]);
    if (path == null) {
      throw Exception('Couldn\'t find the executable $executable in the path.');
    }
    return path;
  }

  /// Saves the given [bytes] to a file at [path].
  ///
  /// Does nothing if [path] or [bytes] is null or empty.
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

  /// Checks if the start of the string [x] is an alphabetical character (a-z or A-Z).
  ///
  /// Returns true if the first character of [x] is a letter.
  static bool isAlpha(String x) {
    if (x.isEmpty) return false;
    final int codeUnit = x.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122); // a-z
  }
}

/// Save the given bytes to a file, using a separate [Isolate].
///
/// The [args] is expected to contain a [SendPort], the [String] file path
/// and the [TransferableTypedData] bytes, in this order.
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
