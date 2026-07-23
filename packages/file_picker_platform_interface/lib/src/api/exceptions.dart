/// An exception thrown when a file name contains characters that are not allowed
/// for the underlying platform.
class IllegalCharacterInFileNameException implements Exception {
  /// Creates an instance of [IllegalCharacterInFileNameException].
  const IllegalCharacterInFileNameException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'IllegalCharacterInFileNameException: $message';
}
