class IllegalCharacterInFileNameException implements Exception {
  const IllegalCharacterInFileNameException(this.message);
  
  final String message;
  
  @override
  String toString() => 'IllegalCharacterInFileNameException: $message';
}
  final String message;
  IllegalCharacterInFileNameException(this.message);
  @override
  String toString() => 'IllegalCharacterInFileNameException: $message';
}
