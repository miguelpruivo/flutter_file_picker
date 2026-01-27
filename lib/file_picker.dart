export 'src/api/file_picker_result.dart';
export 'src/api/file_picker_types.dart';
export 'src/api/platform_file.dart';
export 'src/file_picker.dart';
// Platform-specific implementations are exported only for plugin registration.
// These exports are hidden on Web to avoid dart:ffi and dart:io compatibility issues.
export 'src/platform/linux/file_picker_linux.dart'
    if (dart.library.js_interop) 'src/platform/web/file_picker_web.dart';
export 'src/platform/macos/file_picker_macos.dart'
    if (dart.library.js_interop) 'src/platform/web/file_picker_web.dart';
export 'src/platform/windows/file_picker_windows.dart'
    if (dart.library.js_interop) 'src/platform/web/file_picker_web.dart';
