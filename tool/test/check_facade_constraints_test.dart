import 'package:flutter_test/flutter_test.dart';

import '../check_facade_constraints.dart';

void main() {
  group('parseDependencies', () {
    test('reads the dependencies block and stops at the next section', () {
      const pubspec = '''
name: file_picker
version: 12.1.3

dependencies:
  flutter:
    sdk: flutter

  file_picker_platform_interface: ^3.2.0
  windows_file_picker: ^1.1.0

dev_dependencies:
  flutter_lints: ^6.0.0
''';

      final deps = parseDependencies(pubspec);

      expect(deps['file_picker_platform_interface'], '^3.2.0');
      expect(deps['windows_file_picker'], '^1.1.0');
      expect(deps.containsKey('flutter_lints'), isFalse);
    });
  });

  group('lowerBound', () {
    test('reads caret constraints', () {
      expect(lowerBound('^1.0.3'), '1.0.3');
    });

    test('reads ranged constraints', () {
      expect(lowerBound('>=1.0.3 <2.0.0'), '1.0.3');
    });

    test('reads an exact version', () {
      expect(lowerBound('1.0.3'), '1.0.3');
    });

    test('returns null for anything else', () {
      expect(lowerBound('any'), isNull);
    });
  });

  group('compareVersions', () {
    test('orders by major, minor and patch', () {
      expect(compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(compareVersions('1.0.2', '1.0.10'), lessThan(0));
      expect(compareVersions('3.0.3', '3.0.3'), 0);
    });

    test('ignores build metadata and pre-release suffixes', () {
      expect(compareVersions('1.0.1+2', '1.0.1'), 0);
      expect(compareVersions('12.0.0-beta.7', '12.0.0'), 0);
    });
  });

  group('firstCompatibleVersion', () {
    // Mirrors what pub.dev reports for windows_file_picker, where every 1.0.x
    // predates the DarwinOptions parameter and only 1.1.0 was built against it.
    const published = {
      '1.0.0': '^3.0.0',
      '1.0.1': '^3.0.0',
      '1.0.2': '^3.0.0',
      '1.1.0': '^3.2.0',
    };

    test('picks the earliest version built against the required interface', () {
      expect(
        firstCompatibleVersion(
          published: published,
          requiredInterfaceLowerBound: '3.2.0',
        ),
        '1.1.0',
      );
    });

    test('picks the earliest of several compatible versions', () {
      expect(
        firstCompatibleVersion(
          published: {...published, '1.2.0': '^3.2.0'},
          requiredInterfaceLowerBound: '3.2.0',
        ),
        '1.1.0',
      );
    });

    test('falls back to the very first version when nothing is required', () {
      expect(
        firstCompatibleVersion(
          published: published,
          requiredInterfaceLowerBound: '3.0.0',
        ),
        '1.0.0',
      );
    });

    test('returns null when no published version is compatible', () {
      expect(
        firstCompatibleVersion(
          published: published,
          requiredInterfaceLowerBound: '4.0.0',
        ),
        isNull,
      );
    });
  });
}
