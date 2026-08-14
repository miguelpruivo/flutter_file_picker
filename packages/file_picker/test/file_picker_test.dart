import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FilePicker platform interface instance is not null', () {
    expect(FilePickerPlatform.instance, isNotNull);
  });
}
