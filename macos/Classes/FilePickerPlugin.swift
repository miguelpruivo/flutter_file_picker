import Cocoa
import FlutterMacOS

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

    dialog.showsResizeIndicator = true
    dialog.directoryURL = URL(
      fileURLWithPath: args["initialDirectory"] as? String ?? ""
    )
    dialog.showsHiddenFiles = false
    dialog.allowsMultipleSelection = args["allowMultiple"] as? Bool ?? false
    dialog.canChooseDirectories = false
    dialog.allowedFileTypes = args["allowedExtensions"] as? [String] ?? []

    if dialog.runModal() == NSApplication.ModalResponse.OK {
      let pathResult = dialog.url

      if pathResult != nil {
        if dialog.allowsMultipleSelection {
          let paths = dialog.urls.map { $0.path }
          result(paths)
          return
        } else {
          result([pathResult!.path])
          return
        }
      }
    } else {
      // User dismissed the dialog
      result(nil)
      return
    }
    result(nil)
  }

  private func handleDirectorySelection(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    let dialog = NSOpenPanel()
    let args = call.arguments as! [String: Any]

    dialog.showsResizeIndicator = true
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

    let allowedExtensions = args["allowedExtensions"] as? [String] ?? []
    if !allowedExtensions.isEmpty {
      dialog.allowedFileTypes = allowedExtensions
    }

    if dialog.runModal() == NSApplication.ModalResponse.OK {
      if let url = dialog.url {
        result(url.path)
        return
      }
    }
    // User dismissed the dialog
    result(nil)
  }
}
