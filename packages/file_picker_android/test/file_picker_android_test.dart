import 'package:file_picker_android/file_picker_android.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilePickerAndroid', () {
    test('registers instance', () {
      FilePickerAndroid.registerWith();
      expect(FilePickerPlatform.instance, isA<FilePickerAndroid>());
    });

    test('AndroidSAFOptions toMap contains expected keys', () {
      const safOptions = AndroidSAFOptions(
        grant: AndroidSAFGrant.lifetime,
        accessMode: AndroidSAFAccessMode.readWrite,
        persistGrant: true,
      );
      const options = FilePickerAndroidOptions(safOptions: safOptions);
      final map = options.safOptions.toMap();
      expect(map['grant'], equals('lifetime'));
      expect(map['access'], equals('readWrite'));
      expect(map['autoPersist'], isTrue);
    });

    test('AndroidSAFHandle parses map correctly', () {
      final handle = AndroidSAFHandle.fromMap({
        'uri': 'content://media/external/images/media/1',
        'access': 'readWrite',
      });
      expect(
        handle.uri,
        equals(Uri.parse('content://media/external/images/media/1')),
      );
      expect(handle.accessMode, equals(AndroidSAFAccessMode.readWrite));
    });
  });
}
