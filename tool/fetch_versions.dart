import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  try {
    final json = await _fetchJson();
    final versions = parseVersions(json);
    stdout.write('versions=${jsonEncode(versions)}');
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<Map<String, Object?>> _fetchJson() async {
  final url = Uri.parse(
      'https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json');
  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(url);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('Failed to fetch releases: ${response.statusCode}');
    }
    final responseBody = await response.transform(utf8.decoder).join();
    return jsonDecode(responseBody) as Map<String, Object?>;
  } finally {
    httpClient.close();
  }
}

List<String> parseVersions(Map<String, Object?> json) {
  final releasesList = json['releases'];
  if (releasesList is! List) {
    throw const FormatException('Invalid JSON: releases is not a list');
  }

  // Group by Major.Minor (e.g. 3.38)
  final Map<String, ({String version, DateTime date})> latestByMinor = {};

  for (final release in releasesList) {
    if (release
        case {
          'channel': 'stable',
          'version': final String version,
          'release_date': final String releaseDateString
        }) {
      final parts = version.split('.');
      if (parts.length < 2) continue;
      final minor = '${parts[0]}.${parts[1]}';

      final releaseDate = DateTime.parse(releaseDateString);

      if (!latestByMinor.containsKey(minor)) {
        latestByMinor[minor] = (version: version, date: releaseDate);
      } else {
        final currentBest = latestByMinor[minor]!;
        // Keep the most recent patch
        if (releaseDate.isAfter(currentBest.date)) {
          latestByMinor[minor] = (version: version, date: releaseDate);
        }
      }
    }
  }

  // Sort groups by release date descending
  final sortedByDate = latestByMinor.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // Take the last 5 minor versions
  final top5 = sortedByDate.take(5).map((r) => r.version).toList();

  // Skip the first one (latest stable) to avoid duplication with 'stable' channel
  // Return the next 4
  final historicVersions = top5.skip(1).toList();

  return [...historicVersions, 'stable', 'beta'];
}
