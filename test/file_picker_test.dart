import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFilePickerPlatform extends FilePickerPlatform
    with MockPlatformInterfaceMixin {
  bool pickFileCalled = false;
  bool pickFilesCalled = false;
  bool getDirectoryPathCalled = false;
  bool saveFileCalled = false;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus p1)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    pickFileCalled = true;
    return MockPlatformFile();
  }

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus p1)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    pickFilesCalled = true;
    return [MockPlatformFile()];
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    getDirectoryPathCalled = true;
    return '/mock/path';
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus p1)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    saveFileCalled = true;
    return Uri.file('/mock/saved/file.txt');
  }
}

final class MockPlatformFile extends PlatformFile {
  @override
  String get name => 'test.txt';

  @override
  Uri get uri => Uri.file('/mock/test.txt');

  @override
  String? get path => uri.scheme == 'file' ? uri.toFilePath() : null;

  @override
  XFile get xFile => XFile('/mock/test.txt');

  @override
  Future<int> length() async => 4;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList([1, 2, 3, 4]);

  @override
  Stream<Uint8List> readAsByteStream() async* {
    yield Uint8List.fromList([1, 2, 3, 4]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFilePickerPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockFilePickerPlatform();
    FilePickerPlatform.instance = mockPlatform;
  });

  test('FilePicker.pickFile delegates to platform instance', () async {
    final result = await FilePicker.pickFile();
    expect(mockPlatform.pickFileCalled, isTrue);
    expect(result?.name, 'test.txt');
  });

  test('FilePicker.pickFiles delegates to platform instance', () async {
    final result = await FilePicker.pickFiles();
    expect(mockPlatform.pickFilesCalled, isTrue);
    expect(result?.files.length, 1);
  });

  test('FilePicker.getDirectoryPath delegates to platform instance', () async {
    final result = await FilePicker.getDirectoryPath();
    expect(mockPlatform.getDirectoryPathCalled, isTrue);
    expect(result, '/mock/path');
  });

  test('FilePicker.saveFile delegates to platform instance', () async {
    final result = await FilePicker.saveFile(
      fileName: 'file.txt',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    expect(mockPlatform.saveFileCalled, isTrue);
    expect(result, '/mock/saved/file.txt');
  });
}
