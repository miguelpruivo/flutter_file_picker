/// Type of file to pick.
enum FileType {
  /// any - Select any file.
  any,

  /// media - Select video and image files.
  media,

  /// image - Select image files.
  image,

  /// video - Select video files.
  video,

  /// audio - Select audio files.
  audio,

  /// custom - Select files with custom extensions.
  custom,
}

/// Status of the file picker.
enum FilePickerStatus {
  /// picking - The picker is currently active/open.
  picking,

  /// done - The picking process is complete.
  done,
}
