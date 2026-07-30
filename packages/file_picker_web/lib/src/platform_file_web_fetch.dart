import 'dart:js_interop';
import 'dart:typed_data';

@JS('fetch')
external JSPromise<JSObject> _fetchJs(JSString url);

/// Interop extension type representing a Web `Response` JS object.
extension type _Response(JSObject _) implements JSObject {
  external JSPromise<JSArrayBuffer> arrayBuffer();
  external JSObject? get body;
}

/// Interop extension type representing a Web `ReadableStream` JS object.
extension type _ReadableStream(JSObject _) implements JSObject {
  external JSObject getReader();
}

/// Interop extension type representing a Web `ReadableStreamDefaultReader` JS object.
extension type _Reader(JSObject _) implements JSObject {
  external JSPromise<JSObject> read();
}

/// Interop extension type representing a Web `ReadableStreamReadResult` JS object.
extension type _ReadResult(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

/// Attempts to fetch bytes from a web-only path (`blob:` or `data:` URL).
///
/// Returns the full file bytes (`Uint8List`) using `fetch(...).arrayBuffer()`
/// for `blob:` URLs, or parses `data:` URIs. Returns `null` if fetching fails
/// or if [path] is empty or not a valid web URL.
Future<Uint8List?> fetchBytesFromWebPath(String? path) async {
  if (path == null || path.isEmpty) return null;

  try {
    if (path.startsWith('data:')) {
      return Uri.parse(path).data?.contentAsBytes();
    }

    if (path.startsWith('blob:')) {
      final response = _Response(await _fetchJs(path.toJS).toDart);
      final buffer = await response.arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
    }
  } catch (_) {
    return null;
  }

  return null;
}

/// Attempts to create a streaming `Stream<Uint8List>` from a web-only path
/// (`blob:` or `data:` URL).
///
/// Returns `null` when streaming isn't possible and the caller should
/// fall back to [fetchBytesFromWebPath].
Stream<Uint8List>? fetchStreamFromWebPath(String? path) {
  if (path == null || path.isEmpty) return null;

  return _streamFromWebPath(path);
}

/// Reads a `blob:` or `data:` URL and emits its bytes as a stream.
///
/// Uses `Response.body` (`ReadableStream`) when available; otherwise falls
/// back to a single in-memory `arrayBuffer()` chunk.
Stream<Uint8List> _streamFromWebPath(String path) async* {
  try {
    if (path.startsWith('data:')) {
      final bytes = Uri.parse(path).data?.contentAsBytes();
      if (bytes != null) {
        yield bytes;
      }
      return;
    }

    if (path.startsWith('blob:')) {
      final jsResponse = await _fetchJs(path.toJS).toDart;

      final response = _Response(jsResponse);
      final body = response.body;

      // If there's no streaming body, fallback to arrayBuffer()
      if (body == null) {
        final buffer = await response.arrayBuffer().toDart;
        yield buffer.toDart.asUint8List();
        return;
      }

      final readable = _ReadableStream(body);
      final reader = _Reader(readable.getReader());

      while (true) {
        final jsResultObj = await reader.read().toDart;
        final result = _ReadResult(jsResultObj);
        if (result.done) break;

        final arr = result.value;
        if (arr == null) break;

        yield arr.toDart;
      }
    }
  } catch (_) {
    return;
  }
}
