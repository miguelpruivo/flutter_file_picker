import 'package:file_picker_web/src/file_picker_web_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FilePickerWebOptions initializes with default properties', () {
    const options = FilePickerWebOptions(allowMultiple: true, withData: true);
    expect(options.allowMultiple, isTrue);
    expect(options.withData, isTrue);
    expect(options.withReadStream, isFalse);
    expect(options.readSequential, isFalse);
    expect(options.cancelUploadOnWindowBlur, isTrue);
  });

  test('FilePickerWebOptions copyWith works correctly', () {
    const options = FilePickerWebOptions();
    final updated = options.copyWith(allowMultiple: true, withReadStream: true);
    expect(updated.allowMultiple, isTrue);
    expect(updated.withReadStream, isTrue);
    expect(updated.withData, isTrue);
  });
}
