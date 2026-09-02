import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the facade against allowing a platform implementation that predates
/// the platform interface it requires.
///
/// The `pub downgrade` build in CI resolves everything to its lowest allowed
/// version, which is internally consistent whenever the interface bound and
/// the implementation bounds are stale together. It never produces the pairing
/// that actually breaks, the newest interface next to the oldest allowed
/// implementation, so it cannot see this on its own. That pairing is what
/// https://github.com/vicajilau/flutter_file_picker/issues/2186 was.
///
/// The property checked here is the one that holds regardless of release
/// order, including the staged flow where the interface is published on its
/// own before the implementations catch up: for every implementation, the
/// facade's lower bound must be at least the first published version of that
/// implementation built against the interface the facade requires.
const String interfacePackage = 'file_picker_platform_interface';

void main() {
  group('constraint arithmetic', () {
    test('lowerBound reads the usual constraint shapes', () {
      expect(lowerBound('^1.0.3'), '1.0.3');
      expect(lowerBound('>=1.0.3 <2.0.0'), '1.0.3');
      expect(lowerBound('1.0.3'), '1.0.3');
      expect(lowerBound('any'), isNull);
    });

    test('compareVersions orders by major, minor and patch', () {
      expect(compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(compareVersions('1.0.2', '1.0.10'), lessThan(0));
      expect(compareVersions('3.0.3', '3.0.3'), 0);
      expect(compareVersions('1.0.1+2', '1.0.1'), 0);
    });

    test('parseDependencies stops at the next top level section', () {
      const pubspec =
          '''
name: file_picker

dependencies:
  flutter:
    sdk: flutter

  $interfacePackage: ^3.2.0
  windows_file_picker: ^1.1.0

dev_dependencies:
  flutter_lints: ^6.0.0
''';
      final deps = parseDependencies(pubspec);
      expect(deps[interfacePackage], '^3.2.0');
      expect(deps['windows_file_picker'], '^1.1.0');
      expect(deps.containsKey('flutter_lints'), isFalse);
    });
  });

  group('firstCompatibleVersion', () {
    // What pub.dev reports for windows_file_picker: every 1.0.x predates the
    // DarwinOptions parameter, only 1.1.0 was built against the interface that
    // introduced it.
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
          requiredInterface: '3.2.0',
        ),
        '1.1.0',
      );
    });

    test('picks the earliest of several compatible versions', () {
      expect(
        firstCompatibleVersion(
          published: {...published, '1.2.0': '^3.2.0'},
          requiredInterface: '3.2.0',
        ),
        '1.1.0',
      );
    });

    test('returns null when nothing published is compatible yet', () {
      expect(
        firstCompatibleVersion(
          published: published,
          requiredInterface: '4.0.0',
        ),
        isNull,
      );
    });

    test('reproduces issue 2186', () {
      // The facade asked for the interface at ^3.2.0 while still allowing
      // windows_file_picker ^1.0.0, and 1.0.0 was built against ^3.0.0.
      final required = firstCompatibleVersion(
        published: published,
        requiredInterface: '3.2.0',
      );
      expect(compareVersions('1.0.0', required!), lessThan(0));
    });
  });

  test('facade does not allow implementations older than its interface', () async {
    final root = _repoRoot();
    final facade = File(
      '${root.path}/packages/file_picker/pubspec.yaml',
    ).readAsStringSync();
    final dependencies = parseDependencies(facade);

    final requiredInterface = lowerBound(dependencies[interfacePackage]!);
    expect(requiredInterface, isNotNull);

    final Map<String, String> interfaceVersions;
    try {
      interfaceVersions = await _publishedInterfaceConstraints(
        interfacePackage,
      );
    } catch (e) {
      markTestSkipped('pub.dev unreachable: $e');
      return;
    }

    // On a branch that bumps the interface, the version the facade now asks for
    // is not published yet, so there is nothing to compare implementations
    // against. The staged release flow publishes the interface first, and from
    // the next release on this check has what it needs.
    if (!interfaceVersions.containsKey(requiredInterface)) {
      markTestSkipped(
        '$interfacePackage $requiredInterface is not published yet, '
        'so no implementation can have been built against it',
      );
      return;
    }

    final problems = <String>[];
    for (final name in _implementationNames(root, dependencies)) {
      final Map<String, String> published;
      try {
        published = await _publishedInterfaceConstraints(name);
      } catch (e) {
        markTestSkipped('pub.dev unreachable for $name: $e');
        return;
      }

      final required = firstCompatibleVersion(
        published: published,
        requiredInterface: requiredInterface!,
      );
      if (required == null) continue; // not released against it yet

      final declared = lowerBound(dependencies[name]!);
      if (declared == null || compareVersions(declared, required) < 0) {
        problems.add(
          '$name: facade allows >=$declared, but the first version built '
          'against $interfacePackage >=$requiredInterface is $required',
        );
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          'packages/file_picker/pubspec.yaml allows implementations that '
          'predate the interface it requires:\n  ${problems.join('\n  ')}\n'
          'Raise those bounds, otherwise pub can resolve a combination that '
          'satisfies every constraint and does not compile.',
    );
  });
}

/// Reads the `name: constraint` pairs from a pubspec's `dependencies` block.
Map<String, String> parseDependencies(String pubspec) {
  final result = <String, String>{};
  var inside = false;
  for (final line in const LineSplitter().convert(pubspec)) {
    if (line.startsWith('dependencies:')) {
      inside = true;
      continue;
    }
    if (inside && line.isNotEmpty && !line.startsWith(' ')) break;
    if (!inside) continue;
    final match = RegExp(r'^  ([a-z_0-9]+):\s*(\S.*)$').firstMatch(line);
    if (match != null) result[match.group(1)!] = match.group(2)!.trim();
  }
  return result;
}

/// Extracts the lower bound of a pub version constraint.
String? lowerBound(String constraint) {
  final trimmed = constraint.trim().replaceAll(RegExp('^["\']|["\']\$'), '');
  return RegExp(r'^\^([0-9]\S*)').firstMatch(trimmed)?.group(1) ??
      RegExp(r'>=\s*([0-9]\S*)').firstMatch(trimmed)?.group(1) ??
      RegExp(r'^([0-9]\S*)$').firstMatch(trimmed)?.group(1);
}

/// Compares two versions, ignoring build metadata and pre-release suffixes.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < 3; i++) {
    final l = i < x.length ? x[i] : 0;
    final r = i < y.length ? y[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

/// The earliest published version whose interface constraint is at least
/// [requiredInterface]. [published] maps a version to the constraint it
/// declares on the platform interface.
String? firstCompatibleVersion({
  required Map<String, String> published,
  required String requiredInterface,
}) {
  final compatible =
      published.entries
          .where((e) {
            final bound = lowerBound(e.value);
            return bound != null &&
                compareVersions(bound, requiredInterface) >= 0;
          })
          .map((e) => e.key)
          .toList()
        ..sort(compareVersions);
  return compatible.isEmpty ? null : compatible.first;
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        pubspec.readAsStringSync().contains(
          RegExp(r'^workspace:', multiLine: true),
        )) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not find the workspace root from ${Directory.current.path}');
    }
    dir = parent;
  }
}

/// Facade dependencies that are implementations maintained in this repository.
///
/// Derived from the workspace list rather than hardcoded, so a new platform
/// package is covered as soon as the facade depends on it.
List<String> _implementationNames(Directory root, Map<String, String> deps) {
  final rootPubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
  final names = <String>[];
  for (final match in RegExp(
    r'^\s+- (packages/\S+)$',
    multiLine: true,
  ).allMatches(rootPubspec)) {
    final pubspec = File('${root.path}/${match.group(1)}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;
    final name = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec.readAsStringSync())?.group(1);
    if (name == null || name == interfacePackage) continue;
    if (deps.containsKey(name)) names.add(name);
  }
  return names;
}

/// Maps every published version of [package] to the platform interface
/// constraint it declares.
Future<Map<String, String>> _publishedInterfaceConstraints(
  String package,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final response = await (await client.getUrl(
      Uri.parse('https://pub.dev/api/packages/$package'),
    )).close();
    if (response.statusCode != 200) {
      throw HttpException('pub.dev returned ${response.statusCode}');
    }
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 30));
    final json = jsonDecode(body) as Map<String, Object?>;

    final result = <String, String>{};
    for (final entry in json['versions'] as List) {
      final version = (entry as Map)['version'] as String;
      final deps = ((entry['pubspec'] as Map)['dependencies'] as Map?) ?? {};
      final constraint = deps[interfacePackage];
      result[version] = constraint is String ? constraint : '';
    }
    return result;
  } finally {
    client.close();
  }
}
