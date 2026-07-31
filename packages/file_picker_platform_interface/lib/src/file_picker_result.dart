import 'platform_file.dart';

/// The result of a file picking operation.
class FilePickerResult {
  const FilePickerResult(this.files);

  /// List of picked files.
  final List<PlatformFile> files;

  /// Returns `true` if no files were picked.
  bool get isEmpty => files.isEmpty;

  /// Returns `true` if files were picked.
  bool get isNotEmpty => files.isNotEmpty;

  /// Number of picked files.
  int get count => files.length;

  /// Convenient getter to access single picked file.
  PlatformFile get single => files.single;

  /// Convenient list of all file paths.
  List<String?> get paths => files.map((file) => file.path).toList();

  /// Convenient list of all file names.
  List<String> get names => files.map((file) => file.name).toList();
}
