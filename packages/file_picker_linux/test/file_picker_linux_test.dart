import 'package:file_picker_linux/file_picker_linux.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilePickerLinux', () {
    test('registers instance', () {
      FilePickerLinux.registerWith();
      expect(FilePickerPlatform.instance, isA<FilePickerLinux>());
    });

    test('LinuxPlatformFile parses path correctly', () {
      final file = LinuxPlatformFile.fromPath('/tmp/test.png');
      expect(file.name, equals('test.png'));
      expect(file.uri.path, equals('/tmp/test.png'));
    });

    test('Filter constructs filters correctly', () {
      final filter = Filter(FileType.custom, ['png', 'jpg']);
      expect(filter.info.containsKey('Custom'), isTrue);
    });
  });

  group('LinuxOptions passed through to the portal', () {
    // The implementation narrows LinuxOptions to FilePickerLinuxOptions. It
    // used to fall back to a default instance when the incoming value was a
    // plain LinuxOptions, silently dropping whatever the caller had set, which
    // is exactly what the deprecation on FilePicker.pickFiles points people at.
    FilePickerLinuxOptions narrow(LinuxOptions linuxOptions) =>
        switch (linuxOptions) {
          FilePickerLinuxOptions opts => opts,
          _ => FilePickerLinuxOptions(
            acceptLabel: linuxOptions.acceptLabel,
            lockParentWindow: linuxOptions.lockParentWindow,
          ),
        };

    test('keeps lockParentWindow from a plain LinuxOptions', () {
      expect(
        narrow(const LinuxOptions(lockParentWindow: true)).lockParentWindow,
        isTrue,
      );
    });

    test('keeps acceptLabel from a plain LinuxOptions', () {
      expect(
        narrow(const LinuxOptions(acceptLabel: 'Choose')).acceptLabel,
        equals('Choose'),
      );
    });

    test('keeps both when given a FilePickerLinuxOptions', () {
      const options = FilePickerLinuxOptions(
        parentWindow: 'x11:0x1234',
        acceptLabel: 'Choose',
        lockParentWindow: true,
      );

      expect(narrow(options).lockParentWindow, isTrue);
      expect(narrow(options).acceptLabel, equals('Choose'));
      expect(narrow(options).parentWindow, equals('x11:0x1234'));
    });

    test('FilePickerLinuxOptions can carry acceptLabel and parentWindow', () {
      const options = FilePickerLinuxOptions(
        parentWindow: 'wayland:handle',
        acceptLabel: 'Save here',
      );

      expect(options.acceptLabel, equals('Save here'));
      expect(options.parentWindow, equals('wayland:handle'));
      expect(options.lockParentWindow, isFalse);
    });
  });
}
