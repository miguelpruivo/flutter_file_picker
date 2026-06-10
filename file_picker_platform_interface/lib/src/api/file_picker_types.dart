/// Type of file to pick.
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

/// Status of the file picker.
enum FilePickerStatus {
  /// The file picker is currently active/open.
  picking,

  /// The file picking process is complete.
  done,
}
