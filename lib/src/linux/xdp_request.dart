// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object request.xml

import 'package:dbus/dbus.dart';

/// Signal data for org.freedesktop.portal.Request.Response.
class OrgFreedesktopPortalRequestResponse extends DBusSignal {
  int get response => values[0].asUint32();
  Map<String, DBusValue> get results => values[1].asStringVariantDict();

  OrgFreedesktopPortalRequestResponse(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}

class OrgFreedesktopPortalRequest extends DBusRemoteObject {
  /// Stream of org.freedesktop.portal.Request.Response signals.
  late final Stream<OrgFreedesktopPortalRequestResponse> response;

  OrgFreedesktopPortalRequest(super.client, String destination,
      {super.path = const DBusObjectPath.unchecked('/')})
      : super(name: destination) {
    response = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.freedesktop.portal.Request',
            name: 'Response',
            signature: DBusSignature('ua{sv}'))
        .asBroadcastStream()
        .map((signal) => OrgFreedesktopPortalRequestResponse(signal));
  }

  /// Invokes org.freedesktop.portal.Request.Close()
  Future<void> callClose(
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.freedesktop.portal.Request', 'Close', [],
        replySignature: DBusSignature(''),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }
}
