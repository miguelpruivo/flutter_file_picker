export 'package:file_picker_platform_interface/file_picker.dart';
export 'src/file_picker.dart';
export 'src/platform/linux/file_picker_linux.dart'
    if (dart.library.js_interop) 'src/platform/web/file_picker_web.dart';
export 'src/platform/macos/file_picker_macos.dart'
    if (dart.library.js_interop) 'src/platform/web/file_picker_web.dart';
export 'src/platform/windows/file_picker_windows.dart'
    if (dart.library.js_interop) 'src/platform/web/file_picker_web.dart';
