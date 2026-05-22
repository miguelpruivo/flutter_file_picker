// Stub implementation used when dart:html is not available (non-web platforms).
// The real implementation lives in `platform_file_web_fetch.dart` which is
// conditionally imported only on web builds.

import 'dart:typed_data';

/// Attempts to fetch bytes from a web-only path (blob: or data: URL).
///
/// This stub is a no-op on non-web platforms and returns null.
Future<Uint8List?> fetchBytesFromWebPath(String? path) async => null;
