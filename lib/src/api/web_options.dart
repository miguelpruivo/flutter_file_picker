/// Configuration options specific to the Web platform.
final class WebOptions {
  /// Creates a set of Web-specific configuration options for file picker operations.
  const WebOptions({this.cancelUploadOnWindowBlur = true});

  /// Prevents upload cancellation when window focus is lost.
  final bool cancelUploadOnWindowBlur;
}
