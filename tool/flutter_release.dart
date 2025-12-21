/// Represents a single Flutter release entry from the JSON feed.
///
/// Contains the version string and the release date.
class FlutterRelease {
  /// The raw version string (e.g., "3.32.8").
  final String version;

  /// The date when this version was released.
  final DateTime releaseDate;

  /// Creates a [FlutterRelease] instance.
  FlutterRelease({
    required this.version,
    required this.releaseDate,
  });

  /// Tries to parse a JSON object into a [FlutterRelease].
  ///
  /// Returns `null` if the JSON object does not have the expected structure
  /// or if it represents a non-stable channel release (though filtering
  /// might happen outside, this parser strictly checks for keys).
  ///
  /// Note: The logic requires 'channel': 'stable' to be present.
  static FlutterRelease? tryParse(Object? json) {
    if (json
        case {
          'channel': 'stable',
          'version': final String version,
          'release_date': final String releaseDateString
        }) {
      return FlutterRelease(
        version: version,
        releaseDate: DateTime.parse(releaseDateString),
      );
    }
    return null;
  }
}
