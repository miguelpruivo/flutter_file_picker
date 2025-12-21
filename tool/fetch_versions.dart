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

class FlutterRelease {
  final String version;
  final String channel;
  final DateTime releaseDate;

  FlutterRelease({
    required this.version,
    required this.channel,
    required this.releaseDate,
  });

  factory FlutterRelease.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final channel = json['channel'];
    final releaseDate = json['release_date'];

    if (version is! String || channel is! String || releaseDate is! String) {
      throw FormatException('Invalid release data: $json');
    }

    return FlutterRelease(
      version: version,
      channel: channel,
      releaseDate: DateTime.parse(releaseDate),
    );
  }
}

List<String> parseVersions(Map<String, Object?> json) {
  final releasesList = json['releases'];
  if (releasesList is! List) {
    throw const FormatException('Invalid JSON: releases is not a list');
  }

  final releases = releasesList
      .whereType<Map<String, Object?>>()
      .map(FlutterRelease.fromJson)
      .toList();

  // Filter for stable channel
  final stableReleases = releases.where((r) => r.channel == 'stable');

  // Group by Major.Minor (e.g. 3.38)
  final Map<String, FlutterRelease> latestByMinor = {};

  for (final release in stableReleases) {
    final parts = release.version.split('.');
    if (parts.length < 2) continue;
    final minor = '${parts[0]}.${parts[1]}';

    if (!latestByMinor.containsKey(minor)) {
      latestByMinor[minor] = release;
    } else {
      final currentBest = latestByMinor[minor]!;
      // Keep the most recent patch
      if (release.releaseDate.isAfter(currentBest.releaseDate)) {
        latestByMinor[minor] = release;
      }
    }
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
