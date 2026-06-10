final class Allocation {
  final int size;
  final String type;
  final DateTime timestamp;
  final String? stackTrace;

  Allocation({this.size = 0, this.type = '', DateTime? timestamp, this.stackTrace})
      : timestamp = timestamp ?? DateTime.now();
}
