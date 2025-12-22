// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object org.freedesktop.portal.FileChooser.xml

import 'package:dbus/dbus.dart';

class OrgFreedesktopPortalFileChooser extends DBusRemoteObject {
  OrgFreedesktopPortalFileChooser(super.client, String destination,
      {super.path = const DBusObjectPath.unchecked('/')})
      : super(name: destination);

  /// Gets org.freedesktop.portal.FileChooser.version
  Future<int> getversion() async {
    var value = await getProperty(
        'org.freedesktop.portal.FileChooser', 'version',
        signature: DBusSignature('u'));
    return value.asUint32();
  }

  /// Invokes org.freedesktop.portal.FileChooser.OpenFile()
  Future<DBusObjectPath> callOpenFile(
      String parentWindow, String title, Map<String, DBusValue> options,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod(
        'org.freedesktop.portal.FileChooser',
        'OpenFile',
        [
          DBusString(parentWindow),
          DBusString(title),
          DBusDict.stringVariant(options)
        ],
        replySignature: DBusSignature('o'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }

  /// Invokes org.freedesktop.portal.FileChooser.SaveFile()
  Future<DBusObjectPath> callSaveFile(
      String parentWindow, String title, Map<String, DBusValue> options,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod(
        'org.freedesktop.portal.FileChooser',
        'SaveFile',
        [
          DBusString(parentWindow),
          DBusString(title),
          DBusDict.stringVariant(options)
        ],
        replySignature: DBusSignature('o'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }

  /// Invokes org.freedesktop.portal.FileChooser.SaveFiles()
  Future<DBusObjectPath> callSaveFiles(
      String parentWindow, String title, Map<String, DBusValue> options,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod(
        'org.freedesktop.portal.FileChooser',
        'SaveFiles',
        [
          DBusString(parentWindow),
          DBusString(title),
          DBusDict.stringVariant(options)
        ],
        replySignature: DBusSignature('o'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }
}
