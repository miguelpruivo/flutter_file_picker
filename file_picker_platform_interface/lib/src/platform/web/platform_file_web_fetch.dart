import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<Uint8List?> fetchBytesFromWebPath(String? path) async {
  if (path == null || path.isEmpty) {
    return null;
  }

  final response = await window.fetch(path.toJS).toDart;
  if (!response.ok) {
    return null;
  }

  final buffer = await response.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

Stream<Uint8List>? fetchStreamFromWebPath(String? path) => null;
