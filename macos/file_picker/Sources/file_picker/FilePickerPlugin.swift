import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

enum EntitlementMode {
    case requireWrite
    case readOrWrite
}

private extension CFString {
    static let securityFilesUserSelectedReadOnly = "com.apple.security.files.user-selected.read-only" as CFString
    static let securityFilesUserSelectedReadWrite = "com.apple.security.files.user-selected.read-write" as CFString
}

public class FilePickerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "miguelruivo.flutter.plugins.filepicker",
            binaryMessenger: registrar.messenger)
        let instance = FilePickerPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private let registrar: FlutterPluginRegistrar
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickFiles":
            handleFileSelection(call, result: result)
            
        case "getDirectoryPath":
            handleDirectorySelection(call, result: result)
            
        case "pickFileAndDirectoryPaths":
            handleFileAndDirectorySelection(call, result: result)
            
        case "saveFile":
            handleSaveFile(call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleFileSelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let entitlementError = checkEntitlement(requiredMode: .readOrWrite) {
            result(entitlementError)
            return
        }
        let dialog = NSOpenPanel()
        let args = call.arguments as! [String: Any]
        
        dialog.directoryURL = URL(
            fileURLWithPath: args["initialDirectory"] as? String ?? ""
        )
        dialog.showsHiddenFiles = false
        let allowMultiple = args["allowMultiple"] as? Bool ?? false
        dialog.allowsMultipleSelection = allowMultiple
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        let extensions = args["allowedExtensions"] as? [String] ?? []
        applyExtensions(dialog, extensions)
        
        guard let appWindow = getFlutterWindow() else {
            result(nil)
            return
        }
        
        dialog.beginSheetModal(for: appWindow) { response in
            // User dismissed the dialog
            if (response != .OK) {
                result(nil)
                return
            }
            
            if allowMultiple {
                let pathResult = dialog.urls
                
                if pathResult.isEmpty {
                    result(nil)
                } else {
                    let paths = pathResult.map { $0.path }
                    result(paths)
                }
                return
            }
            
            if let pathResult = dialog.url {
                result([pathResult.path])
                return
            }
            
            result(nil)
        }
    }

    private func handleFileAndDirectorySelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let entitlementError = checkEntitlement(requiredMode: .readOrWrite) {
            result(entitlementError)
            return
        }
        let dialog: NSOpenPanel = NSOpenPanel()
        let args = call.arguments as! [String: Any]
        
        dialog.directoryURL = URL(
            fileURLWithPath: args["initialDirectory"] as? String ?? ""
        )
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = true
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = true
        let extensions = args["allowedExtensions"] as? [String] ?? []
        applyExtensions(dialog, extensions)
        
        guard let appWindow: NSWindow = getFlutterWindow() else {
            result(nil)
            return
        }
        
        dialog.beginSheetModal(for: appWindow) { response in
            // User dismissed the dialog
            if (response != .OK) {
                result(nil)
                return
            }
            
            let pathResult = dialog.urls
            
            if pathResult.isEmpty {
                result(nil)
            } else {
                let paths = pathResult.map { $0.path }
                result(paths)
            }
        }
    }

    private func handleDirectorySelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let entitlementError = checkEntitlement(requiredMode: .readOrWrite) {
            result(entitlementError)
            return
        }
        
        let dialog = NSOpenPanel()
        let args = call.arguments as! [String: Any]
        
        dialog.directoryURL = URL(
            fileURLWithPath: args["initialDirectory"] as? String ?? ""
        )
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        
        guard let appWindow = getFlutterWindow()  else {
            result(nil)
            return
        }
        dialog.beginSheetModal(for: appWindow) { response in
            // User dismissed the dialog
            if (response != .OK) {
                result(nil)
                return
            }
            
            if let url = dialog.url {
                result(url.path)
                return
            }
            
            result(nil)
        }
    }
    
    private func handleSaveFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let entitlementError = checkEntitlement(requiredMode: .requireWrite) {
            result(entitlementError)
            return
        }
        
        let dialog = NSSavePanel()
        let args = call.arguments as! [String: Any]
        
        dialog.title = args["dialogTitle"] as? String ?? ""
        dialog.showsTagField = false
        dialog.showsHiddenFiles = false
        dialog.canCreateDirectories = true
        dialog.nameFieldStringValue = args["fileName"] as? String ?? ""
        
        if let initialDirectory = args["initialDirectory"] as? String, !initialDirectory.isEmpty {
            dialog.directoryURL = URL(fileURLWithPath: initialDirectory)
        }
        
        let extensions = args["allowedExtensions"] as? [String] ?? []
        applyExtensions(dialog, extensions)
        
        guard let appWindow = getFlutterWindow() else {
            result(nil)
            return
        }
        dialog.beginSheetModal(for: appWindow) { response in
            // User dismissed the dialog
            if (response != .OK) {
                result(nil)
                return
            }
            
            if let url = dialog.url {
                result(url.path)
                return
            }
            
            result(nil)
        }
    }
    
    /// Checks if the  entitlements file contains the required entitlement for save files.
    private func checkEntitlement(requiredMode: EntitlementMode) -> FlutterError? {
        guard let task = SecTaskCreateFromSelf(nil) else {
            return FlutterError(code: "ENTITLEMENT_CHECK_FAILED", message: "Failed to verify file_picker entitlements.", details: nil)
        }
        
        let readWriteEntitlement = SecTaskCopyValueForEntitlement(task, .securityFilesUserSelectedReadWrite, nil) as? Bool
        let readOnlyEntitlement = SecTaskCopyValueForEntitlement(task, .securityFilesUserSelectedReadOnly, nil) as? Bool
        
        switch requiredMode {
        case .requireWrite:
            if readWriteEntitlement != true {
                return FlutterError(code: "ENTITLEMENT_REQUIRED_WRITE", message: "The Read-Write entitlement is required for this action.", details: nil)
            }
            
        case .readOrWrite:
            if readWriteEntitlement != true && readOnlyEntitlement != true {
                return FlutterError(code: "ENTITLEMENT_NOT_FOUND", message: "Either the Read-Only or Read-Write entitlement is required for this action.", details: nil)
            }
        }
        return nil
    }
    
    /// Applies extensions to dialog using appropriate API
    private func applyExtensions(_ dialog: NSSavePanel, _ extensions: [String]) {
        if !extensions.isEmpty {
            if #available(macOS 11.0, *) {
                let contentTypes = extensions.compactMap { ext in
                    UTType(filenameExtension: ext)
                }
                dialog.allowedContentTypes = contentTypes
            } else {
                dialog.allowedFileTypes = extensions
            }
        }
    }
    
    /// Gets the parent NSWindow
    private func getFlutterWindow() -> NSWindow? {
        return registrar.view?.window
    }
}
