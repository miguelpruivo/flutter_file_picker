import 'package:file_picker_web/src/file_picker_web_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FilePickerWebOptions initializes with default properties', () {
    const options = FilePickerWebOptions(
      withData: false,
      withReadStream: true,
    );
    expect(options.withData, isFalse);
    expect(options.withReadStream, isTrue);
    expect(options.readSequential, isFalse);
    expect(options.cancelUploadOnWindowBlur, isTrue);
  });
}
