import 'dart:convert';
import 'dart:io';

/// Verifies that `file_picker` cannot resolve a platform implementation that
/// predates the platform interface it requires.
///
/// The facade pins `file_picker_platform_interface` and separately pins each
/// implementation. When the interface changes a method signature, every
/// implementation has to be republished against it, and the facade's lower
/// bounds have to be raised in the same release. Forgetting the second half
/// leaves a resolution that satisfies every constraint and does not compile,
/// which is what happened in
/// https://github.com/miguelpruivo/flutter_file_picker/issues/2186
///
/// Run manually with `dart tool/check_facade_constraints.dart`.
Future<void> main() async {
  final facade = File('packages/file_picker/pubspec.yaml').readAsStringSync();
  final root = File('pubspec.yaml').readAsStringSync();

  final deps = parseDependencies(facade);
  final interfaceConstraint = deps[interfacePackage];
  if (interfaceConstraint == null) {
    stderr.writeln(
      'Error: $interfacePackage is not a dependency of the facade',
    );
    exit(1);
  }
  final requiredInterface = lowerBound(interfaceConstraint);
  if (requiredInterface == null) {
    stderr.writeln(
      'Error: cannot read a lower bound from $interfaceConstraint',
    );
    exit(1);
  }

  final implementations = implementationNames(root, deps);
  final violations = <String>[];

  for (final name in implementations) {
    final Map<String, String> published;
    try {
      published = await _fetchInterfaceConstraints(name);
    } catch (e) {
      // The guard is a safety net, not a gate. A flaky pub.dev should not fail
      // unrelated pull requests.
      stderr.writeln('Warning: skipping $name, could not reach pub.dev ($e)');
      continue;
    }

    final required = firstCompatibleVersion(
      published: published,
      requiredInterfaceLowerBound: requiredInterface,
    );
    if (required == null) {
      violations.add(
        '$name has no published version built against '
        '$interfacePackage >=$requiredInterface',
      );
      continue;
    }

    final declared = lowerBound(deps[name]!);
    if (declared == null || compareVersions(declared, required) < 0) {
      violations.add(
        '$name: facade allows >=$declared, but the first version built against '
        '$interfacePackage >=$requiredInterface is $required',
      );
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'OK: every implementation lower bound requires '
      '$interfacePackage >=$requiredInterface.',
    );
    return;
  }

  stderr.writeln(
    'packages/file_picker/pubspec.yaml allows implementations that predate '
    '$interfacePackage $requiredInterface:\n',
  );
  for (final violation in violations) {
    stderr.writeln('  - $violation');
  }
  stderr.writeln(
    '\nRaise those lower bounds. Otherwise pub can resolve a combination that '
    'satisfies every constraint and does not compile.',
  );
  exit(1);
}

/// The package whose version dictates which implementations are usable.
const String interfacePackage = 'file_picker_platform_interface';

/// Reads the `name: constraint` pairs from a pubspec's `dependencies` block.
Map<String, String> parseDependencies(String pubspec) {
  final result = <String, String>{};
  var inDependencies = false;
  for (final line in const LineSplitter().convert(pubspec)) {
    if (line.startsWith('dependencies:')) {
      inDependencies = true;
      continue;
    }
    if (inDependencies && line.isNotEmpty && !line.startsWith(' ')) break;
    if (!inDependencies) continue;

    final match = RegExp(r'^  ([a-z_0-9]+):\s*(\S.*)$').firstMatch(line);
    if (match != null) {
      result[match.group(1)!] = match.group(2)!.trim();
    }
  }
  return result;
}

/// The facade dependencies that are implementations maintained in this repo.
///
/// Derived from the workspace list rather than hardcoded, so a new platform
/// package is covered as soon as the facade depends on it.
List<String> implementationNames(String rootPubspec, Map<String, String> deps) {
  final workspaceDirs = const LineSplitter()
      .convert(rootPubspec)
      .map((line) => RegExp(r'^\s+- (packages/\S+)$').firstMatch(line))
      .whereType<RegExpMatch>()
      .map((match) => match.group(1)!)
      .toList();

  final names = <String>[];
  for (final dir in workspaceDirs) {
    final pubspec = File('$dir/pubspec.yaml');
    if (!pubspec.existsSync()) continue;
    final name = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec.readAsStringSync())?.group(1);
    if (name == null) continue;
    if (name == interfacePackage) continue;
    if (deps.containsKey(name)) names.add(name);
  }
  return names;
}

/// Extracts the lower bound of a pub version constraint.
String? lowerBound(String constraint) {
  final trimmed = constraint.trim().replaceAll(
    RegExp(r'^["\x27]|["\x27]$'),
    '',
  );
  final caret = RegExp(r'^\^([0-9]\S*)').firstMatch(trimmed);
  if (caret != null) return caret.group(1);
  final atLeast = RegExp(r'>=\s*([0-9]\S*)').firstMatch(trimmed);
  if (atLeast != null) return atLeast.group(1);
  final exact = RegExp(r'^([0-9]\S*)$').firstMatch(trimmed);
  return exact?.group(1);
}

/// Compares two versions, ignoring build metadata and pre-release suffixes.
int compareVersions(String a, String b) {
  List<int> parts(String version) => version
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  final left = parts(a);
  final right = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// The earliest published version whose interface constraint is at least
/// [requiredInterfaceLowerBound].
///
/// [published] maps a published version to the interface constraint it declares.
String? firstCompatibleVersion({
  required Map<String, String> published,
  required String requiredInterfaceLowerBound,
}) {
  final compatible =
      published.entries
          .where((entry) {
            final bound = lowerBound(entry.value);
            return bound != null &&
                compareVersions(bound, requiredInterfaceLowerBound) >= 0;
          })
          .map((entry) => entry.key)
          .toList()
        ..sort(compareVersions);

  return compatible.isEmpty ? null : compatible.first;
}

/// Maps every published version of [package] to the interface constraint it
/// declares.
Future<Map<String, String>> _fetchInterfaceConstraints(String package) async {
  final url = Uri.parse('https://pub.dev/api/packages/$package');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final response = await (await client.getUrl(url)).close();
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
      final dependencies =
          ((entry['pubspec'] as Map)['dependencies'] as Map?) ?? {};
      final constraint = dependencies[interfacePackage];
      if (constraint is String) result[version] = constraint;
    }
    return result;
  } finally {
    client.close();
  }
}
