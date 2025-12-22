import 'dart:convert';
import 'dart:io';

import 'flutter_release.dart';

/// Main entry point for the version fetching script.
///
/// Fetches the list of Flutter releases for Linux, parses them to find
/// the recent stable minor versions, and outputs them as a JSON list
/// to `stdout` in the format `versions=["..."]`.
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

/// Fetches the JSON data from the Flutter infrastructure releases URL.
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

/// Parses the JSON response to extract relevant Flutter versions.
///
/// Filters for stable releases, groups them by major.minor version, keeps
/// the latest patch for each group, and returns the last 5 minor versions
/// (excluding the very latest stable one which overlaps with 'stable' channel).
List<String> parseVersions(Map<String, Object?> json) {
  final releasesList = json['releases'];
  if (releasesList is! List) {
    throw const FormatException('Invalid JSON: releases is not a list');
  }

  // Group by Major.Minor (e.g. 3.38)
  final Map<String, FlutterRelease> latestByMinor = {};

  for (final releaseJson in releasesList) {
    final release = FlutterRelease.tryParse(releaseJson);
    if (release == null) continue;

    final parts = release.version.split('.');
    if (parts.length < 2) continue;
    final minor = '${parts[0]}.${parts[1]}';

    if (latestByMinor.containsKey(minor)) {
      final currentBest = latestByMinor[minor]!;
      // Keep the most recent patch
      if (release.releaseDate.isAfter(currentBest.releaseDate)) {
        latestByMinor[minor] = release;
      }
      continue;
    }

    latestByMinor[minor] = release;
  }

  // Sort groups by release date descending
  final sortedByDate = latestByMinor.values.toList()
    ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

  // Take the last 5 minor versions
  final top5 = sortedByDate.take(5).map((r) => r.version).toList();

  // Skip the first one (latest stable) to avoid duplication with 'stable' channel
  // Return the next 4
  final historicVersions = top5.skip(1).toList();

  return [...historicVersions, 'stable', 'beta'];
}
