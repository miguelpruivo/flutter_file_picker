@TestOn('vm')
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformFile persistent access', () {
    test(
      'readAsBytes throws when there is no local path or in-memory data',
      () async {
        final file = PlatformFile(name: 'movie.mov', size: 3);

        expect(file.readAsBytes(), throwsStateError);
      },
    );

    test(
      'readAsByteStream throws when there is no local path or in-memory data',
      () async {
        final file = PlatformFile(name: 'movie.mov', size: 3);

        expect(() => file.readAsByteStream().toList(), throwsStateError);
      },
    );
  });
}
