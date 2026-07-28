/// The type of file that a file picker can select.
enum FileType {
  /// Select any file.
  any,

  /// Select video and image files.
  media,

  /// Select image files.
  image,

  /// Select video files.
  video,

  /// Select audio files.
  audio,

  /// Select files with specific extensions.
  custom,
}
