import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the facade's lower bounds against the packages this repo publishes.
///
/// `pub downgrade` in CI resolves every dependency to its lowest allowed
/// version and builds, which catches a stale bound *once the rest of the set
/// has moved past it*. It cannot catch a release where the interface bound and
/// the implementation bounds are stale together: the minimum set is then
/// internally consistent and compiles, while pub is still free to pair the new
/// interface with an old implementation in a real app.
///
/// That is how both
/// https://github.com/vicajilau/flutter_file_picker/issues/2186 and the
/// `PlatformFile.size` release nearly shipped, so this asserts the simpler
/// property the downgrade build cannot see: the facade must require at least
/// what this repo is about to publish.
void main() {
  test('facade requires at least the versions this repo publishes', () {
    final root = _repoRoot();
    final workspace = _workspacePackages(root);

    final facade = workspace['file_picker'];
    expect(facade, isNotNull, reason: 'file_picker is not in the workspace');

    final dependencies = _dependencies(
      File('${facade!.dir}/pubspec.yaml').readAsStringSync(),
    );

    final problems = <String>[];
    for (final entry in workspace.entries) {
      final name = entry.key;
      if (name == 'file_picker') continue;

      final constraint = dependencies[name];
      if (constraint == null) continue; // not a facade dependency

      final declared = _lowerBound(constraint);
      if (declared == null) {
        problems.add('$name: cannot read a lower bound from "$constraint"');
        continue;
      }
      if (_compare(declared, entry.value.version) < 0) {
        problems.add(
          '$name: facade allows >=$declared but this repo publishes '
          '${entry.value.version}',
        );
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          'packages/file_picker/pubspec.yaml is behind the workspace:\n'
          '  ${problems.join('\n  ')}\n'
          'Raise those bounds. Otherwise pub can pair the new platform '
          'interface with an implementation released before it.',
    );
  });
}

class _Package {
  _Package(this.dir, this.version);
  final String dir;
  final String version;
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

Map<String, _Package> _workspacePackages(Directory root) {
  final rootPubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
  final dirs = RegExp(
    r'^\s+- (packages/\S+)$',
    multiLine: true,
  ).allMatches(rootPubspec).map((m) => '${root.path}/${m.group(1)}');

  final packages = <String, _Package>{};
  for (final dir in dirs) {
    final pubspec = File('$dir/pubspec.yaml');
    if (!pubspec.existsSync()) continue;
    final text = pubspec.readAsStringSync();
    final name = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(text)?.group(1);
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(text)?.group(1);
    if (name != null && version != null) {
      packages[name] = _Package(dir, version);
    }
  }
  return packages;
}

Map<String, String> _dependencies(String pubspec) {
  final result = <String, String>{};
  var inside = false;
  for (final line in pubspec.split('\n')) {
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

String? _lowerBound(String constraint) {
  final trimmed = constraint.trim().replaceAll(RegExp('^["\']|["\']\$'), '');
  return RegExp(r'^\^([0-9]\S*)').firstMatch(trimmed)?.group(1) ??
      RegExp(r'>=\s*([0-9]\S*)').firstMatch(trimmed)?.group(1) ??
      RegExp(r'^([0-9]\S*)$').firstMatch(trimmed)?.group(1);
}

int _compare(String a, String b) {
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
