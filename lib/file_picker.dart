export './src/file_picker.dart';
export './src/platform_file.dart';
export './src/file_picker_result.dart';
export './src/file_picker_macos.dart';
export './src/linux/file_picker_linux.dart';
export './src/file_picker_io.dart';
// Conditional export needed for web to successfully compile,
// as `dart:ffi` is not available on the web.
export './src/windows/file_picker_windows_stub.dart'
    if (dart.library.ffi) './src/windows/file_picker_windows.dart';
