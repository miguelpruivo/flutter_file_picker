import 'package:flutter_test/flutter_test.dart';
import '../tool/fetch_versions.dart';

void main() {
  test('parseVersions extracts last 4 minor versions + stable/beta', () {
    final json = {
      "releases": [
        // Minor 3.38
        {
          "version": "3.38.5",
          "channel": "stable",
          "release_date": "2025-12-12T10:00:00Z"
        },
        {
          "version": "3.38.4",
          "channel": "stable",
          "release_date": "2025-12-11T10:00:00Z"
        },

        // Minor 3.35
        {
          "version": "3.35.7",
          "channel": "stable",
          "release_date": "2025-11-12T10:00:00Z"
        },

        // Minor 3.32
        {
          "version": "3.32.8",
          "channel": "stable",
          "release_date": "2025-10-12T10:00:00Z"
        },

        // Minor 3.29
        {
          "version": "3.29.3",
          "channel": "stable",
          "release_date": "2025-09-12T10:00:00Z"
        },

        // Minor 3.27 (5th older minor, should be excluded if limit is 4)
        {
          "version": "3.27.4",
          "channel": "stable",
          "release_date": "2025-08-12T10:00:00Z"
        },

        // Beta (ignored by filter, but 'beta' string is added manually)
        {
          "version": "3.40.0-beta",
          "channel": "beta",
          "release_date": "2025-12-13T10:00:00Z"
        },
      ]
    };

    final versions = parseVersions(json);

    expect(versions, [
      "3.38.5", // Latest of 3.38
      "3.35.7", // Latest of 3.35
      "3.32.8", // Latest of 3.32
      "3.29.3", // Latest of 3.29
      "stable",
      "beta"
    ]);
    expect(versions.length, 6);
  });
}
