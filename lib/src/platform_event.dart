enum PlatformEventType {
  STATUS,
  ORIGINAL_CONTENT_URL,
  UNKNOWN,
}

class PlatformEvent {
  const PlatformEvent({
    this.type,
    this.value,
  });

  PlatformEvent.fromMap(Map data)
      : this.type = determineEventType(data['type']),
        this.value = data['value'];

  static PlatformEventType determineEventType(dynamic type) {
    if (type == null) {
      return PlatformEventType.UNKNOWN;
    }

    if (type is String) {
      switch (type) {
        case 'STATUS':
          return PlatformEventType.STATUS;
        case 'ORIGINAL_CONTENT_URL':
          return PlatformEventType.ORIGINAL_CONTENT_URL;
        default:
          return PlatformEventType.UNKNOWN;
      }
    }

    return PlatformEventType.UNKNOWN;
  }

  final PlatformEventType type;
  final dynamic value;
}
