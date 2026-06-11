import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';

Future<List<PlatformFile>> filePathsToPlatformFiles(
  List<String> filePaths, {
  bool withReadStream = false,
  bool withData = false,
}) {
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

Future<PlatformFile> createPlatformFile(
  Object file,
  Uint8List? bytes,
  Stream<List<int>>? readStream,
) async {
  if (file case final File nativeFile) {
    return PlatformFile(
      bytes: bytes,
      name: basename(nativeFile.path),
      path: nativeFile.path,
      readStream: readStream,
      size: nativeFile.existsSync() ? nativeFile.lengthSync() : 0,
    );
  }

  throw ArgumentError('Expected file to be a File.');
}

Future<String?> runExecutableWithArguments(
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

Future<String> isExecutableOnPath(String executable) async {
  final path = await runExecutableWithArguments('which', [executable]);
  if (path == null) {
    throw Exception('Couldn\'t find the executable $executable in the path.');
  }
  return path;
}

Future<void> saveBytesToFile(Uint8List? bytes, String? path) async {
  if (path == null || bytes == null || bytes.isEmpty) {
    return;
  }

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
