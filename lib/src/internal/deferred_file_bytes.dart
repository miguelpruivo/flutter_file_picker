import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

final Expando<DeferredFileBytesSource> _deferredFileBytesExpando =
    Expando<DeferredFileBytesSource>('deferredFileBytes');

class DeferredFileBytesSource {
  const DeferredFileBytesSource({
    required this.path,
    required this.identifier,
    required this.name,
  });

  final String? path;
  final String? identifier;
  final String name;
}

Uint8List createDeferredFileBytesToken(DeferredFileBytesSource source) {
  final token = Uint8List(0);
  _deferredFileBytesExpando[token] = source;
  return token;
}

DeferredFileBytesSource? getDeferredFileBytesSource(Uint8List bytes) {
  return _deferredFileBytesExpando[bytes];
}

Future<void> copyFileToPathInChunks({
  required String sourcePath,
  required String targetPath,
  int chunkSize = 50 * 1024 * 1024,
}) async {
  final receivePort = ReceivePort();

  await Isolate.spawn(_copyFileIsolateEntry, [
    receivePort.sendPort,
    sourcePath,
    targetPath,
    chunkSize,
  ]);

  final result = await receivePort.first;
  receivePort.close();
  if (result is Exception) {
    throw result;
  }
}

Future<void> _copyFileIsolateEntry(List<Object?> args) async {
  if (args case [
    SendPort send,
    String sourcePath,
    String targetPath,
    int chunkSize,
  ]) {
    try {
      if (sourcePath == targetPath) {
        send.send(null);
        return;
      }

      final sourceFile = File(sourcePath);
      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);

      final source = await sourceFile.open();
      final target = await targetFile.open(mode: FileMode.write);

      try {
        await target.truncate(0);
        while (true) {
          final chunk = await source.read(chunkSize);
          if (chunk.isEmpty) {
            break;
          }
          await target.writeFrom(chunk);
        }
      } finally {
        await source.close();
        await target.close();
      }

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
