import 'package:flutter/foundation.dart';
import 'platform_file.dart';

/// The result of a file picking operation containing a list of [PlatformFile].
@immutable
final class FilePickerResult {
  const FilePickerResult(this.files);

  /// The list of picked files.
  final List<PlatformFile> files;

  /// Returns `true` if there are no picked files.
  bool get isEmpty => files.isEmpty;

  /// Returns `true` if there is at least one picked file.
  bool get isNotEmpty => files.isNotEmpty;

  /// Returns the number of picked files.
  int get count => files.length;

  /// Returns a list of paths of all picked files.
  List<String?> get paths => files.map((file) => file.path).toList();

  /// Returns a list of names of all picked files.
  List<String> get names => files.map((file) => file.name).toList();

  /// Returns a list of URIs of all picked files.
  List<Uri> get uris => files.map((file) => file.uri).toList();

  /// Returns the single picked file, or `null` if no file was picked.
  PlatformFile? get single => files.singleOrNull;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilePickerResult && listEquals(files, other.files);

  @override
  int get hashCode => Object.hashAll(files);

  @override
  String toString() => 'FilePickerResult(files: $files)';
}
