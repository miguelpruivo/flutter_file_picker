import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

public class FilePickerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "miguelruivo.flutter.plugins.filepicker",
      binaryMessenger: registrar.messenger)
    let instance = FilePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
  {
    switch call.method {
    case "pickFiles":
      handleFileSelection(call, result: result)

    case "getDirectoryPath":
      handleDirectorySelection(call, result: result)

    case "saveFile":
      handleSaveFile(call, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleFileSelection(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
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

    if dialog.runModal() == NSApplication.ModalResponse.OK {
      if allowMultiple {
        let pathResult = dialog.urls
        if pathResult.isEmpty {
          result(nil)
        } else {
          let paths = pathResult.map { $0.path }
          result(paths)
        }
      } else {
        let pathResult = dialog.url
        if pathResult == nil {
          result(nil)
        } else {
          result([pathResult!.path])
        }
      }
      return
    } else {
      // User dismissed the dialog
      result(nil)
      return
    }
  }

  private func handleDirectorySelection(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    let dialog = NSOpenPanel()
    let args = call.arguments as! [String: Any]

    dialog.directoryURL = URL(
      fileURLWithPath: args["initialDirectory"] as? String ?? ""
    )
    dialog.showsHiddenFiles = false
    dialog.allowsMultipleSelection = false
    dialog.canChooseDirectories = true
    dialog.canChooseFiles = false

    if dialog.runModal() == NSApplication.ModalResponse.OK {
      if let url = dialog.url {
        result(url.path)
        return
      }
    }
    // User dismissed the dialog
    result(nil)
  }

  private func handleSaveFile(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    let dialog = NSSavePanel()
    let args = call.arguments as! [String: Any]

    dialog.title = args["dialogTitle"] as? String ?? ""
    dialog.showsTagField = false
    dialog.showsHiddenFiles = false
    dialog.canCreateDirectories = true
    dialog.nameFieldStringValue = args["fileName"] as? String ?? ""

    if let initialDirectory = args["initialDirectory"] as? String,
      !initialDirectory.isEmpty
    {
      dialog.directoryURL = URL(fileURLWithPath: initialDirectory)
    }

    let extensions = args["allowedExtensions"] as? [String] ?? []
    applyExtensions(dialog, extensions)

    if dialog.runModal() == NSApplication.ModalResponse.OK {
      if let url = dialog.url {
        result(url.path)
        return
      }
    }
    // User dismissed the dialog
    result(nil)
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
}
