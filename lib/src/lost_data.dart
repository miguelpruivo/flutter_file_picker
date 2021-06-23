import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// The response object of [FilePicker.retrieveLostData].
///
/// Only applies to Android.
/// See also:
/// * [FilePicker.retrieveLostData] for more details on retrieving lost data.
class LostData {
  /// Creates an instance with the given [result] and [exception]. Any of
  /// the params may be null, but this is never considered to be empty.
  LostData({this.result, this.exception});

  /// Initializes an instance with all member params set to null and considered
  /// to be empty.
  LostData.empty()
      : result = null,
        exception = null,
        _empty = true;

  /// Whether it is an empty response.
  ///
  /// An empty response should have [file], [exception] and [type] to be null.
  bool get isEmpty => _empty;

  /// The file that was lost in a previous [pickFiles] call due to MainActivity being destroyed.
  ///
  /// Can be null if [exception] exists.
  final FilePickerResult? result;

  /// The exception of the last [pickFiles].
  ///
  /// If the last [pickFiles] threw some exception before the MainActivity destruction, this variable keeps that
  /// exception.
  /// You should handle this exception as if the [pickFiles] got an exception when the MainActivity was not destroyed.
  ///
  /// Note that it is not the exception that caused the destruction of the MainActivity.
  final PlatformException? exception;

  bool _empty = false;
}
