import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WebOptions initializes with default properties', () {
    const options = WebOptions(
      allowMultiple: true,
      withData: true,
    );
    expect(options.allowMultiple, isTrue);
    expect(options.withData, isTrue);
  });
}
