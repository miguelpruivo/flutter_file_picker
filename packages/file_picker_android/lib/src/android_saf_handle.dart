import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

import 'file_picker_android.dart';
import 'file_picker_android_options.dart';

/// An opaque handle to an Android Storage Access Framework [uri].
final class AndroidSAFHandle {
  const AndroidSAFHandle({required this.accessMode, required this.uri});

  factory AndroidSAFHandle.fromMap(Map<Object?, Object?> map) {
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
    if (FilePickerPlatform.instance case final FilePickerAndroid instance) {
      await instance.releaseSAFGrant(uri.toString());
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AndroidSAFHandle &&
        other.accessMode == accessMode &&
        other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(accessMode, uri);

  @override
  String toString() => 'AndroidSAFHandle(uri: $uri, accessMode: $accessMode)';
}
