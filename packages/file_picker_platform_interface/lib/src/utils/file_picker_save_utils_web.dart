import 'dart:typed_data';

final class FilePickerSaveUtils {
  /// Save the given [bytes] to a file at [path].
  static Future<void> saveBytesToFile(Uint8List bytes, String path) async {
    throw UnsupportedError(
      'saveBytesToFile() is not supported on this platform.',
    );
  }
}
