import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';

/// An opaque handle to an Android Storage Access Framework [uri].
final class AndroidSAFHandle {
  const AndroidSAFHandle({
    required this.accessMode,
    required this.uri,
  });

  factory AndroidSAFHandle.fromMap(Map<String, dynamic> map) {
    return AndroidSAFHandle(
      uri: Uri.parse(map['uri'] as String),
      accessMode: map['access'] == 'readWrite'
          ? AndroidSAFAccessMode.readWrite
          : AndroidSAFAccessMode.readOnly,
    );
  }

  /// The access mode that is granted to the [uri].
  final AndroidSAFAccessMode accessMode;

  /// The URI that this handle represents.
  ///
  /// Typically a `content://` URI.
  final Uri uri;

  /// Release the grant on the given [uri].
  Future<void> releaseGrant() async {
    await FilePickerPlatform.instance.releaseSAFGrant(uri.toString());
  }
}
