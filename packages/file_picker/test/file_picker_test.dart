import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

base class TestPlatformFile extends PlatformFile {
  TestPlatformFile({
    required this.name,
    required String path,
  }) : uri = Uri.file(path);

  @override
  final String name;

  @override
  final Uri uri;

  @override
  XFile get xFile => XFile(path ?? '');

  @override
  Future<int> length() async => 100;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => const Stream.empty();
}

class MockFilePickerPlatform extends FilePickerPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus status)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return [
      TestPlatformFile(
        name: 'test_file.txt',
        path: '/path/to/test_file.txt',
      ),
    ];
  }
}

void main() {
  test('FilePicker.pickFiles delegates to FilePickerPlatform.instance.pickFiles', () async {
    final mockPlatform = MockFilePickerPlatform();
    FilePickerPlatform.instance = mockPlatform;

    final files = await FilePicker.pickFiles();
    expect(files, isNotEmpty);
    expect(files.first.name, 'test_file.txt');
    expect(files.first.path, '/path/to/test_file.txt');
  });
}
