/// The options for the web file picker.
class WebOptions {
  /// Whether to allow picking multiple files.
  final bool allowMultiple;

  /// Whether to load the file bytes into memory.
  final bool withData;

  /// Whether to create a read stream for picked files.
  final bool withReadStream;

  /// Whether to read files sequentially.
  final bool readSequential;

  /// Whether to cancel upload when window loses focus.
  final bool cancelUploadOnWindowBlur;

  /// Creates an instance of [WebOptions].
  const WebOptions({
    this.allowMultiple = false,
    this.withData = true,
    this.withReadStream = false,
    this.readSequential = false,
    this.cancelUploadOnWindowBlur = true,
  });

  /// Creates a copy of this [WebOptions] with the given fields replaced.
  WebOptions copyWith({
    bool? allowMultiple,
    bool? withData,
    bool? withReadStream,
    bool? readSequential,
    bool? cancelUploadOnWindowBlur,
  }) {
    return WebOptions(
      allowMultiple: allowMultiple ?? this.allowMultiple,
      withData: withData ?? this.withData,
      withReadStream: withReadStream ?? this.withReadStream,
      readSequential: readSequential ?? this.readSequential,
      cancelUploadOnWindowBlur:
          cancelUploadOnWindowBlur ?? this.cancelUploadOnWindowBlur,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebOptions &&
        other.allowMultiple == allowMultiple &&
        other.withData == withData &&
        other.withReadStream == withReadStream &&
        other.readSequential == readSequential &&
        other.cancelUploadOnWindowBlur == cancelUploadOnWindowBlur;
  }

  @override
  int get hashCode => Object.hash(
    allowMultiple,
    withData,
    withReadStream,
    readSequential,
    cancelUploadOnWindowBlur,
  );
}
