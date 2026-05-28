import 'dart:js_interop';
import 'dart:typed_data';

@JS('fetch')
external JSPromise<JSObject> _fetchJs(JSString url);

extension type _Response(JSObject _) implements JSObject {
  external JSPromise<JSArrayBuffer> arrayBuffer();
  external JSObject? get body;
}

extension type _ReadableStream(JSObject _) implements JSObject {
  external JSObject getReader();
}

extension type _Reader(JSObject _) implements JSObject {
  external JSPromise<JSObject> read();
}

extension type _ReadResult(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

// Web helper: recover bytes or a chunked stream from `blob:` / `data:` URLs.
//
// - `fetchBytesFromWebPath(path)` returns the full file bytes (uses
//   `fetch(...).arrayBuffer()` for `blob:` and parses `data:` URIs).
// - `fetchStreamFromWebPath(path)` returns a `Stream<Uint8List>` when the
//   browser/WebView exposes `Response.body` (a `ReadableStream`) and supports
//   `getReader()`; otherwise it returns `null` and callers should fall back to
//   `fetchBytesFromWebPath`.
//
// Compatibility notes:
// - Modern desktop and mobile browsers expose ReadableStream and will allow
//   streaming blobs without buffering the entire file in memory.
// - Embedded/legacy WebViews (older iOS `WKWebView` or Android System
//   WebView) may not expose `Response.body`; in that case streaming is
//   unavailable and the implementation falls back to `arrayBuffer()` (full
//   file in memory).
// Prefer `PlatformFile.readAsBytes()` for small files and
// `PlatformFile.readAsByteStream()` (streaming) for large files when supported.
// For legacy WebViews, consider server-side streaming to avoid OOMs.

/// Attempts to fetch bytes from a web-only path (`blob:` or `data:` URL).
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
/// (`blob:` or `data:` URL). Returns `null` when streaming isn't possible and
/// the caller should fall back to `fetchBytesFromWebPath`.
Stream<Uint8List>? fetchStreamFromWebPath(String? path) {
  if (path == null || path.isEmpty) return null;

  return _streamFromWebPath(path);
}

/// Reads a `blob:` or `data:` URL and emits its bytes as a stream when the
/// browser exposes a streaming `Response.body`; otherwise it falls back to a
/// single in-memory chunk or no output if the URL cannot be read.
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
