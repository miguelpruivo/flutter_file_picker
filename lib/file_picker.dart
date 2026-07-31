export 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
export 'src/file_picker.dart';

// Conditionally export platform-specific packages
// On Web (js_interop), non-web platform packages default to empty stub to avoid IO/FFI/DBus issues.
// On IO (non-web), web platform package defaults to empty stub to avoid package:web issues.
export 'package:file_picker_android/file_picker_android.dart'
    if (dart.library.js_interop) 'src/empty_stub.dart';
export 'package:file_picker_darwin/file_picker_darwin.dart'
    if (dart.library.js_interop) 'src/empty_stub.dart';
export 'package:file_picker_linux/file_picker_linux.dart'
    if (dart.library.js_interop) 'src/empty_stub.dart';
export 'package:file_picker_windows/file_picker_windows.dart'
    if (dart.library.js_interop) 'src/empty_stub.dart';
export 'package:file_picker_web/file_picker_web.dart'
    if (dart.library.io) 'src/empty_stub.dart';
