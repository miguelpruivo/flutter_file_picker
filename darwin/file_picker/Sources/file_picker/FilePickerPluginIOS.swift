#if os(iOS)
import Flutter
import Foundation

public class FilePickerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "miguelruivo.flutter.plugins.filepicker",
            binaryMessenger: registrar.messenger())

        let eventChannel = FlutterEventChannel(
            name: "miguelruivo.flutter.plugins.filepickerevent",
            binaryMessenger: registrar.messenger())

        let instance = FilePickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance.handler)
    }

    private let handler = IOSFilePickerHandler()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        handler.handle(call, result: result)
    }
}
#endif
