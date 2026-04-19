/// The access mode that is coupled to an [AndroidSAFGrant].
enum AndroidSAFAccessMode {
  /// Only allow read permission for a URI.
  readOnly(0),

  /// Allow both read and write permissions for a URI.
  readWrite(1);

  const AndroidSAFAccessMode(this.rawValue);

  /// The raw value of this access mode.
  final int rawValue;
}

/// The grant type for an Android Storage Access Framework grant.
enum AndroidSAFGrant {
  /// Grant permission to the requested URI for the current request only.
  transient(0),

  /// Grant permission to the requested URI, until permission is explicitly revoked.
  lifetime(1);

  const AndroidSAFGrant(this.rawValue);

  /// The raw value of this grant.
  final int rawValue;
}

/// The configuration options for working with Android's Storage Access Framework.
/// Only applicable when reading APIs on Android 10+ (API 29+).
final class AndroidSAFOptions {
  const AndroidSAFOptions({
    this.grant = AndroidSAFGrant.transient,
    this.accessMode = AndroidSAFAccessMode.readOnly,
    this.persistGrant = true,
  });

  /// The grant to use with the Android Storage Access Framework.
  ///
  /// Defaults to [AndroidSAFGrant.transient].
  final AndroidSAFGrant grant;

  /// The access mode to use with the Android Storage Access Framework.
  ///
  /// Defaults to [AndroidSAFAccessMode.readOnly].
  final AndroidSAFAccessMode accessMode;

  /// Whether to automatically execute `takePersistableUriPermission` on the native side.
  /// Defaults to `true`.
  final bool persistGrant;

  Map<String, dynamic> toMap() {
    return {
      'grant': grant.name,
      'access': accessMode.name,
      'autoPersist': persistGrant,
    };
  }
}
