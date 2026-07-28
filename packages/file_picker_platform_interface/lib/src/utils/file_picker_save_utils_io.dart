import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

final class FilePickerSaveUtils {
  /// Save the given [bytes] to a file at [path].
  static Future<void> saveBytesToFile(Uint8List bytes, String path) async {
    if (bytes.isEmpty) {
      return;
    }

    final receivePort = ReceivePort();
    final transferable = TransferableTypedData.fromList([bytes]);

    await Isolate.spawn(_saveBytesIsolateEntry, [receivePort.sendPort, path, transferable]);

    final result = await receivePort.first;

    receivePort.close();

    if (result is Exception) {
      throw result;
    }
  }

  static Future<void> _saveBytesIsolateEntry(List<Object?> args) async {
    if (args case [SendPort send, String path, TransferableTypedData transferable]) {
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
}
