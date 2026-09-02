@TestOn('browser')
library;

import 'package:file_picker_web/file_picker_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WebPlatformFile properties work correctly', () {
    final file = WebPlatformFile(
      name: 'test.txt',
      uri: Uri.parse('blob:http://localhost/123'),
      bytesLength: 4,
    );
    expect(file.name, 'test.txt');
    expect(file.uri, Uri.parse('blob:http://localhost/123'));
    expect(file.lengthSync(), 4);
  });

  test('WebPlatformFile.lengthSync() is null when not known', () {
    final file = WebPlatformFile(
      name: 'test.txt',
      uri: Uri.parse('blob:http://localhost/123'),
    );
    expect(file.lengthSync(), isNull);
  });
}
