#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import Foundation

public class FilePickerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
        let channel = FlutterMethodChannel(
            name: "miguelruivo.flutter.plugins.filepicker",
            binaryMessenger: registrar.messenger())

        let eventChannel = FlutterEventChannel(
            name: "miguelruivo.flutter.plugins.filepickerevent",
            binaryMessenger: registrar.messenger())

        let instance = FilePickerPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance.handler)
#elseif os(macOS)
        let channel = FlutterMethodChannel(
            name: "miguelruivo.flutter.plugins.filepicker",
            binaryMessenger: registrar.messenger)

        let instance = FilePickerPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
#endif
    }

#if os(iOS)
    private let handler: IOSFilePickerHandler
#elseif os(macOS)
    private let handler: MacOSFilePickerHandler
#endif

    init(registrar: FlutterPluginRegistrar) {
#if os(iOS)
        handler = IOSFilePickerHandler()
#elseif os(macOS)
        handler = MacOSFilePickerHandler(registrar: registrar)
#endif
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        handler.handle(call, result: result)
    }
}