import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  try {
    final json = await _fetchJson();
    final versions = parseVersions(json);
    print('versions=${jsonEncode(versions)}');
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
  final releases = (json['releases'] as List).cast<Map<String, dynamic>>();

  // Filter for stable channel
  final stableReleases = releases.where((r) => r['channel'] == 'stable');

  // Group by Major.Minor (e.g. 3.38)
  final Map<String, Map<String, Object?>> latestByMinor = {};

  for (final release in stableReleases) {
    final version = release['version'] as String;
    final parts = version.split('.');
    if (parts.length < 2) continue;
    final minor = '${parts[0]}.${parts[1]}';

    final releaseDate = DateTime.parse(release['release_date']);

    if (!latestByMinor.containsKey(minor)) {
      latestByMinor[minor] = release;
    } else {
      final currentBest = latestByMinor[minor]!;
      final currentBestDate = DateTime.parse(currentBest['release_date']);
      // Keep the most recent patch
      if (releaseDate.isAfter(currentBestDate)) {
        latestByMinor[minor] = release;
      }
    }
  }

  // Sort groups by release date descending
  final sortedByDate = latestByMinor.values.toList()
    ..sort((a, b) {
      final dateA = DateTime.parse(a['release_date']);
      final dateB = DateTime.parse(b['release_date']);
      return dateB.compareTo(dateA);
    });

  // Take the last 5 minor versions
  final top5 = sortedByDate.take(5).map((r) => r['version'] as String).toList();

  // Skip the first one (latest stable) to avoid duplication with 'stable' channel
  // Return the next 4
  final historicVersions = top5.skip(1).toList();

  return [...historicVersions, 'stable', 'beta'];
}
