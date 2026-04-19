import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker_platform_interface.dart';
import 'package:file_picker/file_picker_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFilePickerPlatform
    with MockPlatformInterfaceMixin
    implements FilePickerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FilePickerPlatform initialPlatform = FilePickerPlatform.instance;

  test('$MethodChannelFilePicker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFilePicker>());
  });

  test('getPlatformVersion', () async {
    FilePicker filePickerPlugin = FilePicker();
    MockFilePickerPlatform fakePlatform = MockFilePickerPlatform();
    FilePickerPlatform.instance = fakePlatform;

    expect(await filePickerPlugin.getPlatformVersion(), '42');
  });
}
