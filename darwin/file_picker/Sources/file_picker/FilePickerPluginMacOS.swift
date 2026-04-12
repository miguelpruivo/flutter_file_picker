#if os(macOS)
import FlutterMacOS
import Foundation

public class FilePickerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "miguelruivo.flutter.plugins.filepicker",
            binaryMessenger: registrar.messenger)

        let instance = FilePickerPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private let handler: MacOSFilePickerHandler

    init(registrar: FlutterPluginRegistrar) {
        handler = MacOSFilePickerHandler(registrar: registrar)
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        handler.handle(call, result: result)
    }
}
#endif
