import UniformTypeIdentifiers

#if os(iOS)
import Flutter
import UIKit
import PhotosUI
import MobileCoreServices
#elseif os(macOS)
import FlutterMacOS
import Cocoa
#endif

public class FilePickerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif

        let channel = FlutterMethodChannel(
            name: "miguelruivo.flutter.plugins.filepicker",
            binaryMessenger: messenger
        )
        let instance = FilePickerPlugin(registrar: registrar, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Add event channel for status updates (e.g. media picking progress)
        let eventChannel = FlutterEventChannel(
            name: "miguelruivo.flutter.plugins.filepickerevent",
            binaryMessenger: messenger
        )
        eventChannel.setStreamHandler(instance)
    }

    private var registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel?
    private var eventSink: FlutterEventSink?
    
    // iOS specific properties
    #if os(iOS)
    private var result: FlutterResult?
    // Keep strong reference to pickers to prevent deallocation
    // private var pickerController: UIViewController? // Generic reference if needed
    #endif

    init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
        self.registrar = registrar
        self.channel = channel
        super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if os(iOS)
        self.result = result
        #endif
        
        switch call.method {
        case "pickFiles":
            handleFileSelection(call, result: result)
        case "getDirectoryPath":
            handleDirectorySelection(call, result: result)
        case "pickFileAndDirectoryPaths":
             #if os(macOS)
             handleFileAndDirectorySelection(call, result: result)
             #else
             result(FlutterMethodNotImplemented)
             #endif
        case "saveFile":
            handleSaveFile(call, result: result)
        case "clear":
             #if os(iOS)
             let cleaned = FilePickerUtils.clearTemporaryFiles()
             result(cleaned)
             self.result = nil
             #else
             result(true)
             #endif
        case "any", "custom":
            handleFileSelection(call, result: result)
        case "video", "image", "media":
            #if os(iOS)
            handleMediaSelection(call, result: result)
            #else
            handleFileSelection(call, result: result)
            #endif
        case "audio":
             #if os(iOS)
             handleAudioSelection(call, result: result)
             #else
             handleFileSelection(call, result: result)
             #endif
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Common Handlers
    
    private func handleFileSelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let allowMultiple = args["allowMultipleSelection"] as? Bool ?? false
        let allowedExtensions = args["allowedExtensions"] as? [String]
        let withData = args["withData"] as? Bool ?? false
        
        #if os(macOS)
        showMacOSPanel(
            args: args,
            allowMultiple: allowMultiple,
            allowedExtensions: allowedExtensions,
            withData: withData,
            canChooseFiles: true,
            canChooseDirectories: false,
            result: result
        )
        #elseif os(iOS)
        let type = call.method
        showIOSDocumentPicker(
            type: type, 
            allowedExtensions: allowedExtensions, 
            allowMultiple: allowMultiple, 
            withData: withData,
            result: result
        )
        #endif
    }
    
    private func handleDirectorySelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        #if os(macOS)
        showMacOSPanel(
            args: args,
            allowMultiple: false,
            allowedExtensions: nil,
            withData: false,
            canChooseFiles: false,
            canChooseDirectories: true,
            result: result
        )
        #elseif os(iOS)
        showIOSDocumentPicker(
            type: "dir", 
            allowedExtensions: nil, 
            allowMultiple: false, 
            withData: false,
            result: result
        )
        #endif
    }

    private func handleSaveFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let fileName = args["fileName"] as? String
        
        #if os(macOS)
        showMacOSSavePanel(args: args, result: result)
        #elseif os(iOS)
        // iOS save file logic (usually export mode of DocumentPicker)
        // Note: Dart side sends bytes for saveFile on mobile.
         guard let bytes = args["bytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "invalid_argument", message: "Bytes are required for saveFile on iOS", details: nil))
            self.result = nil
            return
        }
        showIOSSavePicker(fileName: fileName, bytes: bytes.data, result: result)
        #endif
    }

    // MARK: - macOS Specific Implementation
    #if os(macOS)
    private func handleFileAndDirectorySelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let allowMultiple = args["allowMultipleSelection"] as? Bool ?? false
        let allowedExtensions = args["allowedExtensions"] as? [String]
        
        showMacOSPanel(
            args: args,
            allowMultiple: allowMultiple,
            allowedExtensions: allowedExtensions,
            withData: args["withData"] as? Bool ?? false,
            canChooseFiles: true,
            canChooseDirectories: true,
            result: result
        )
    }

    private func showMacOSPanel(
        args: [String: Any],
        allowMultiple: Bool,
        allowedExtensions: [String]?,
        withData: Bool,
        canChooseFiles: Bool,
        canChooseDirectories: Bool,
        result: @escaping FlutterResult
    ) {
         if let entitlementError = checkEntitlement(requiredMode: .readOrWrite) {
            result(entitlementError)
            return
        }
        
        let dialog = NSOpenPanel()
        dialog.title = args["dialogTitle"] as? String ?? ""
        
        if let initialDirectory = args["initialDirectory"] as? String, !initialDirectory.isEmpty {
            dialog.directoryURL = URL(fileURLWithPath: initialDirectory)
        }
        
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = allowMultiple
        dialog.canChooseDirectories = canChooseDirectories
        dialog.canChooseFiles = canChooseFiles
        
        if let extensions = allowedExtensions {
             applyExtensions(dialog, extensions)
        }

        guard let appWindow = getFlutterWindow() else {
            result(nil)
            return
        }
        
        dialog.beginSheetModal(for: appWindow) { response in
            if response != .OK {
                result(nil)
                return
            }
            
            let urls = dialog.urls
             if urls.isEmpty {
                 result(nil)
                 return
             }
             
             if canChooseDirectories && !canChooseFiles && !allowMultiple {
                 // getDirectoryPath expects String?
                 result(urls.first?.path)
             } else {
                 // pickFiles expects List<Map>
                 let files = self.resolveResult(urls: urls, withData: withData)
                 result(files)
             }
        }
    }
    
    private func showMacOSSavePanel(args: [String: Any], result: @escaping FlutterResult) {
        if let entitlementError = checkEntitlement(requiredMode: .requireWrite) {
            result(entitlementError)
            return
        }
        
        let dialog = NSSavePanel()
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
            if response != .OK {
                result(nil)
                return
            }
             result(dialog.url?.path)
        }
    }

    private func applyExtensions(_ dialog: NSSavePanel, _ extensions: [String]) {
        if !extensions.isEmpty {
            if #available(macOS 11.0, *) {
                let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
                dialog.allowedContentTypes = contentTypes
            } else {
                dialog.allowedFileTypes = extensions
            }
        }
    }

    private func checkEntitlement(requiredMode: EntitlementMode) -> FlutterError? {
         guard let task = SecTaskCreateFromSelf(nil) else {
            return FlutterError(code: "ENTITLEMENT_CHECK_FAILED", message: "Failed to verify file_picker entitlements.", details: nil)
        }
        
        let readWriteEntitlement = SecTaskCopyValueForEntitlement(task, "com.apple.security.files.user-selected.read-write" as CFString, nil) as? Bool
        let readOnlyEntitlement = SecTaskCopyValueForEntitlement(task, "com.apple.security.files.user-selected.read-only" as CFString, nil) as? Bool
        
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
    
    enum EntitlementMode {
        case requireWrite
        case readOrWrite
    }
    
    private func getFlutterWindow() -> NSWindow? {
        return registrar.view?.window
    }
    
    #endif

    // MARK: - iOS Specific Implementation
    #if os(iOS)
    private func showIOSDocumentPicker(type: String, allowedExtensions: [String]?, allowMultiple: Bool, withData: Bool, result: @escaping FlutterResult) {
        // Map allowedExtensions to UTTypes
        var documentTypes: [String] = []
        
        // Temporarily store withData property for delegate to use? 
        // Ideally we should subclass or associate object, but simple var is hard with delegate commonality.
        // We will store it in the plugin instance
        self.loadData = withData
        
        if type == "dir" {
            documentTypes = ["public.folder"] // kUTTypeFolder
        } else if let extensions = allowedExtensions {
            documentTypes = extensions.compactMap { FilePickerUtils.mimeType(for: $0) } 
            if documentTypes.isEmpty {
                 // Fallback if mime lookup fails or empty
                 documentTypes = ["public.content", "public.data"] 
            }
        } else {
             if type == "audio" {
                 documentTypes = ["public.audio"]
             } else if type == "image" {
                 documentTypes = ["public.image"]
             } else if type == "video" {
                 documentTypes = ["public.movie"]
             } else if type == "media" {
                 documentTypes = ["public.image", "public.movie"]
             } else {
                 documentTypes = ["public.content", "public.data"] // Any
             }
        }
        
        let picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: type == "dir" ? .open : .import)
        picker.delegate = self
        picker.allowsMultipleSelection = allowMultiple
        // picker.modalPresentationStyle = .formSheet // Optional
        
        getViewController()?.present(picker, animated: true, completion: nil)
    }

    private func showIOSSavePicker(fileName: String?, bytes: Data, result: @escaping FlutterResult) {
        let tempUrl = FilePickerUtils.saveFile(bytes: bytes, fileName: fileName)
        guard let url = tempUrl else {
             result(FlutterError(code: "create_error", message: "Could not create temporary file for saving", details: nil))
             self.result = nil
             return
        }
        
        // Use UIDocumentPicker to export
        let picker = UIDocumentPickerViewController(urls: [url], in: .exportToService)
        picker.delegate = self
        getViewController()?.present(picker, animated: true, completion: nil)
    }
    
    private func handleMediaSelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
         var config = PHPickerConfiguration()
         let type = call.method
         if type == "image" { config.filter = .images }
         else if type == "video" { config.filter = .videos }
         else { config.filter = .any(of: [.images, .videos]) }
         
         
         let allowMultiple = (call.arguments as? [String: Any])?["allowMultipleSelection"] as? Bool ?? false
         let withData = (call.arguments as? [String: Any])?["withData"] as? Bool ?? false
         self.loadData = withData
         
         if allowMultiple { config.selectionLimit = 0 } else { config.selectionLimit = 1 }
         
         let picker = PHPickerViewController(configuration: config)
         picker.delegate = self
         getViewController()?.present(picker, animated: true)
    }
    
    private func handleAudioSelection(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // UIDocumentPicker handles audio fine usually, but MPMediaPickerController is for library.
        // Legacy plugin used MPMediaPickerController.
        // For simplicity and modernization, using document picker for audio is often better for files,
        // but if access to iTunes library is needed, MPPicker is needed.
        // Given 'audio' method usually implies generic audio file picking:
        
        // If strict parity with legacy is needed:
        // MPMediaPickerController implementation...
        // But for now, let's map audio to DocumentPicker with public.audio, which accesses Files app.
        // This is often preferred in modern apps.
        showIOSDocumentPicker(type: "audio", allowedExtensions: nil, allowMultiple: false, withData: false, result: result)
    }

    private func getViewController() -> UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }
    
    // State for data loading
    private var loadData: Bool = false
    
    #endif
    
    // MARK: - Shared Implementation
    private func resolveResult(urls: [URL], withData: Bool) -> [[String: Any?]] {
        return urls.compactMap { url -> [String: Any?]? in
             var size: UInt64 = 0
             do {
                 let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                 size = UInt64(resources.fileSize ?? 0)
             } catch {
                 print("Error getting file size: \(error)")
             }
             
             var bytes: FlutterStandardTypedData? = nil
             if withData {
                 do {
                     let data = try Data(contentsOf: url)
                     bytes = FlutterStandardTypedData(bytes: data)
                 } catch {
                     print("Error reading file data: \(error)")
                 }
             }
             
             return [
                 "name": url.lastPathComponent,
                 "path": url.path,
                 "size": size,
                 "bytes": bytes,
                 "identifier": url.absoluteString
             ]
        }
    }
}

// MARK: - Extensions for Delegates
#if os(iOS)
extension FilePickerPlugin: UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
    
    // MARK: UIDocumentPickerDelegate
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Handle results
        // If dir pick, return path
        // If file pick, return paths
        // If save, return path
        
        // Logic to differentiate save vs pick is tricky if not tracked.
        // We can check local var or context.
        // Since we store `result` but not operation type, we might need a state var.
        // Simplified:
        
        guard let result = self.result else { return }
        
        if controller.documentPickerMode == .open {
             // Dir picker
             result(urls.first?.path)
        } else if controller.documentPickerMode == .exportToService {
             // Save file
             result(urls.first?.path)
        } else {
             // Import mode (File picking)
             let files = self.resolveResult(urls: urls, withData: self.loadData)
             result(files)
        }
        self.result = nil
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        result?(nil)
        result = nil
    }
    
    // MARK: PHPickerViewControllerDelegate
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = self.result else { return }
        
        if results.isEmpty {
            result(nil)
            self.result = nil
            return
        }
        
        var paths: [String] = []
        let group = DispatchGroup()
        
        // Use serial queue for safe array access
        let queue = DispatchQueue(label: "file_picker_parsing")
        
        for pResult in results {
            group.enter()
            let provider = pResult.itemProvider
            
            // Prefer file representation
            // We need to determine type identifier to request
            // Usually we request what's available or specific type if known
            
            // Basic logic: try to get the highest fidelity file
            
            let typeIdentifier: String
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                typeIdentifier = UTType.movie.identifier
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                typeIdentifier = UTType.image.identifier
            } else {
                // Skip non-media
                group.leave()
                continue
            }
            
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                defer { group.leave() }
                
                guard let url = url, error == nil else {
                    print("Error loading file: \(String(describing: error))")
                    return
                }
                
                // Copy to temp because URL is transient
                let fileName = "picked_" + url.lastPathComponent
                do {
                    let tempDir = FileManager.default.temporaryDirectory
                    let destination = tempDir.appendingPathComponent(fileName)
                    
                    // Remove if exists
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    
                    try FileManager.default.copyItem(at: url, to: destination)
                    
                    queue.async {
                        paths.append(destination.path)
                    }
                } catch {
                    print("Error copying file: \(error)")
                }
            }
        }
        
        group.notify(queue: .main) {
             // Return paths
             if paths.isEmpty {
                 result(nil)
             } else {
                  // Map paths back to URLs to use resolveResult? 
                  // Or just construct map here since we already copied them.
                  // resolveResult expects URLs. 
                  let urls = paths.map { URL(fileURLWithPath: $0) }
                  let files = self.resolveResult(urls: urls, withData: self.loadData)
                  result(files)
             }
             self.result = nil
        }
    }
    

}
#endif

// MARK: - FlutterStreamHandler (Common)
extension FilePickerPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
