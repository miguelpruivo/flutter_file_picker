/// The access mode that is coupled to an [AndroidSAFGrant].
enum AndroidSAFAccessMode {
  /// Only allow read permission for a URI.
  readOnly,

  /// Allow both read and write permissions for a URI.
  readWrite;
}

/// The grant type for an Android Storage Access Framework grant.
enum AndroidSAFGrant {
  /// Grant permission to the requested URI for the current request only.
  transient,

  /// Grant permission to the requested URI, until permission is explicitly revoked.
  lifetime;
}

/// The configuration options for working with Android's Storage Access Framework.
/// Only supported on Android 10+ (API 29+).
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

  /// Whether to persist the [grant], so that it is preserved across device reboots.
  ///
  /// Defaults to `true`.
  final bool persistGrant;

  Map<String, Object?> toMap() {
    return {
      'grant': grant.name,
      'access': accessMode.name,
      'autoPersist': persistGrant,
    };
  }
}
