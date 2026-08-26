/// The representation that iOS should provide for assets selected with
/// `PHPickerViewController`.
enum DarwinAssetRepresentationMode {
  /// Lets the system select the best representation for the asset.
  automatic,

  /// Uses the current representation to avoid transcoding when possible.
  current,

  /// Uses a broadly compatible representation, transcoding when necessary.
  compatible,
}

/// Platform-specific options for file picking on Apple platforms.
class DarwinOptions {
  const DarwinOptions({
    this.assetRepresentationMode = DarwinAssetRepresentationMode.automatic,
  });

  /// The preferred representation for media selected from the iOS photo
  /// library.
  ///
  /// This option only applies when `compressionQuality` is `0`. It has no
  /// effect on macOS or when selecting files with the iOS document picker.
  final DarwinAssetRepresentationMode assetRepresentationMode;
}
