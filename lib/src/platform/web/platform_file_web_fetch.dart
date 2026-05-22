import 'dart:js_interop';
import 'dart:typed_data';

@JS('fetch')
external JSPromise<JSObject> _fetchJs(JSString url);

extension type _Response(JSObject _) implements JSObject {
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

/// Attempts to fetch bytes from a web-only path (`blob:` or `data:` URL).
Future<Uint8List?> fetchBytesFromWebPath(String? path) async {
  if (path == null || path.isEmpty) return null;

  try {
    if (path.startsWith('data:')) {
      return Uri.parse(path).data?.contentAsBytes();
    }

    if (path.startsWith('blob:')) {
      final buffer = await _Response(
        await _fetchJs(path.toJS).toDart,
      ).arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
    }
  } catch (_) {
    return null;
  }

  return null;
}


