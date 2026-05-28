import 'dart:typed_data';

/// Stub implementation used on non-web platforms (tests / VM).
/// Exposes the same API as `platform_file_web_fetch.dart` but returns null
/// so callers fall back to non-web behavior.

Future<Uint8List?> fetchBytesFromWebPath(String? path) async => null;

Stream<Uint8List>? fetchStreamFromWebPath(String? path) => null;
