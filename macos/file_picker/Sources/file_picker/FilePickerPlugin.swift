import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

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
    let viewController = registrar.view?.window?.contentViewController
    return (viewController as? FlutterViewController)?.view.window
  }
}
