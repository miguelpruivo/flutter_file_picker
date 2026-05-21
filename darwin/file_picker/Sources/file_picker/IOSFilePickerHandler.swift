#if os(iOS)
import AVFoundation
import Flutter
import Foundation
import PhotosUI
import UniformTypeIdentifiers
import UIKit

final class IOSFilePickerHandler: NSObject,
    FlutterStreamHandler,
    PHPickerViewControllerDelegate,
    UIDocumentPickerDelegate,
    UIAdaptivePresentationControllerDelegate {

    private var result: FlutterResult?
    private var eventSink: FlutterEventSink?
    private var allowMultipleSelection = false
    private var loadDataToMemory = false
    private var isDirectoryPicker = false
    private var isSaveFile = false

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if self.result != nil {
            result(
                FlutterError(
                    code: "multiple_request",
                    message: "Cancelled by a second request",
                    details: nil))
            return
        }

        self.result = result

        if call.method == "clear" {
            self.result?(clearTemporaryFiles())
            self.result = nil
            return
        }

        if call.method == "dir" {
            isDirectoryPicker = true
            allowMultipleSelection = false
            presentDocumentPicker(
                contentTypes: [.folder],
                allowsMultipleSelection: false,
                asDirectoryPicker: true)
            return
        }

        guard let arguments = call.arguments as? [String: Any] else {
            self.result?(
                FlutterError(
                    code: "invalid_arguments",
                    message: "Expected method arguments as a map.",
                    details: nil))
            self.result = nil
            return
        }

        allowMultipleSelection =
            (arguments["allowMultipleSelection"] as? Bool) ?? false
        loadDataToMemory = (arguments["withData"] as? Bool) ?? false

        switch call.method {
        case "any":
            presentDocumentPicker(
                contentTypes: [.item],
                allowsMultipleSelection: allowMultipleSelection,
                asDirectoryPicker: false)
        case "custom":
            let allowed = arguments["allowedExtensions"] as? [String] ?? []
            let contentTypes = resolveCustomContentTypes(allowed)
            if contentTypes.isEmpty {
                self.result?(
                    FlutterError(
                        code: "Unsupported file extension",
                        message:
                            "If you are providing extension filters make sure that you are only using FileType.custom and the extension are provided without the dot, (ie., jpg instead of .jpg).",
                        details: nil))
                self.result = nil
                return
            }
            presentDocumentPicker(
                contentTypes: contentTypes,
                allowsMultipleSelection: allowMultipleSelection,
                asDirectoryPicker: false)
        case "image", "video", "media":
            presentMediaPicker(
                type: call.method,
                allowsMultipleSelection: allowMultipleSelection)
        case "audio":
            presentDocumentPicker(
                contentTypes: [.audio],
                allowsMultipleSelection: allowMultipleSelection,
                asDirectoryPicker: false)
        case "save":
            saveFile(arguments)
        default:
            result(FlutterMethodNotImplemented)
            self.result = nil
        }
    }

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        eventSink = events
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        guard let currentResult = result else {
            return
        }

        if results.isEmpty {
            currentResult(nil)
            result = nil
            eventSink?(false)
            return
        }

        eventSink?(true)
        let group = DispatchGroup()
        var resolved: [[String: Any]] = []

        for item in results {
            group.enter()
            item.itemProvider.loadFileRepresentation(
                forTypeIdentifier: UTType.item.identifier
            ) { [weak self] url, _ in
                defer { group.leave() }
                guard let self, let sourceURL = url,
                      let copiedURL = self.copyToTemporaryDirectory(sourceURL)
                else {
                    return
                }
                if let fileInfo = self.makeFileInfo(from: copiedURL) {
                    resolved.append(fileInfo)
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else {
                return
            }
            eventSink?(false)
            currentResult(resolved.isEmpty ? nil : resolved)
            result = nil
        }
    }

    func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
        result?(nil)
        result = nil
    }

    func presentationControllerDidDismiss(
        _: UIPresentationController
    ) {
        if result != nil {
            result?(nil)
            result = nil
        }
    }

    func documentPicker(
        _: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        guard let currentResult = result else {
            return
        }

        if isSaveFile {
            currentResult(urls.first?.path)
            result = nil
            isSaveFile = false
            return
        }

        if isDirectoryPicker {
            currentResult(urls.first?.path)
            result = nil
            isDirectoryPicker = false
            return
        }

        var resolved: [[String: Any]] = []

        for sourceURL in urls {
            guard let copiedURL = copyToTemporaryDirectory(sourceURL),
                  let fileInfo = makeFileInfo(from: copiedURL)
            else {
                continue
            }
            resolved.append(fileInfo)
        }

        currentResult(resolved.isEmpty ? nil : resolved)
        result = nil
    }

    private func presentMediaPicker(type: String, allowsMultipleSelection: Bool) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = allowsMultipleSelection ? 0 : 1

        switch type {
        case "image":
            configuration.filter = .images
        case "video":
            configuration.filter = .videos
        default:
            configuration.filter = .any(of: [.images, .videos])
        }

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.presentationController?.delegate = self
        topViewController()?.present(picker, animated: true)
    }

    private func presentDocumentPicker(
        contentTypes: [UTType],
        allowsMultipleSelection: Bool,
        asDirectoryPicker: Bool
    ) {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: contentTypes,
            asCopy: !asDirectoryPicker)
        picker.delegate = self
        picker.presentationController?.delegate = self
        picker.allowsMultipleSelection = allowsMultipleSelection
        topViewController()?.present(picker, animated: true)
    }

    private func saveFile(_ arguments: [String: Any]) {
        isSaveFile = true

        let bytes = arguments["bytes"] as? FlutterStandardTypedData

        let finalFileName = inferFileName(from: arguments, bytes: bytes)

        do {
            let tempFile = try writeTempFile(named: finalFileName, data: bytes?.data)

            let picker = UIDocumentPickerViewController(
                forExporting: [tempFile],
                asCopy: true)
            picker.delegate = self
            picker.presentationController?.delegate = self
            topViewController()?.present(picker, animated: true)
        } catch {
            result?(FlutterError(
                code: "Failed to write file",
                message: error.localizedDescription,
                details: nil))
            result = nil
            isSaveFile = false
            return
        }
    }

    private func inferFileName(from arguments: [String: Any], bytes: FlutterStandardTypedData?) -> String {
        var name = (arguments["fileName"] as? String) ?? ""

        if !(name as NSString).pathExtension.isEmpty {
            return name
        }

        if let ext = inferExtensionFromAllowed(arguments) {
            return name + "." + ext
        }

        if let fileType = arguments["fileType"] as? String, let ext = inferExtensionFromFileType(fileType) {
            return name + "." + ext
        }

        if let data = bytes?.data, let ext = inferExtensionFromBytes(data) {
            return name + "." + ext
        }

        return name
    }

    private func inferExtensionFromAllowed(_ arguments: [String: Any]) -> String? {
        guard let allowed = arguments["allowedExtensions"] as? [String], let first = allowed.first, !first.isEmpty else {
            return nil
        }
        return sanitizeExtension(first)
    }

    private func inferExtensionFromFileType(_ fileType: String) -> String? {
        switch fileType {
        case "image": return "jpg"
        case "video": return "mp4"
        case "audio": return "mp3"
        default: return nil
        }
    }

    private func inferExtensionFromBytes(_ data: Data) -> String? {
        if data.count >= 4, let header = String(data: data.subdata(in: 0..<4), encoding: .utf8), header == "%PDF" {
            return "pdf"
        }

        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        if data.count >= 4 && data.starts(with: Data(pngSignature)) {
            return "png"
        }

        if data.count >= 2 {
            let bytes = [UInt8](data.prefix(2))
            if bytes[0] == 0xFF && bytes[1] == 0xD8 {
                return "jpg"
            }
        }

        if data.count >= 6, let gifHeader = String(data: data.subdata(in: 0..<6), encoding: .ascii), gifHeader.hasPrefix("GIF") {
            return "gif"
        }

        return nil
    }

    private func sanitizeExtension(_ ext: String) -> String {
        let e = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
        return e.lowercased()
    }

    private func writeTempFile(named fileName: String, data: Data?) throws -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }

        if let d = data {
            try d.write(to: tempURL, options: .atomic)
        } else {
            FileManager.default.createFile(atPath: tempURL.path, contents: nil, attributes: nil)
        }

        return tempURL
    }

    private func resolveCustomContentTypes(_ allowedExtensions: [String]) -> [UTType] {
        allowedExtensions.compactMap { ext in
            let sanitized = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
            return UTType(filenameExtension: sanitized)
        }
    }

    private func clearTemporaryFiles() -> Bool {
        let tmpDirectory = NSTemporaryDirectory()

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: tmpDirectory)
            for file in files {
                let filePath = (tmpDirectory as NSString).appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: filePath)
            }
            return true
        } catch {
            return false
        }
    }

    private func topViewController() -> UIViewController? {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        var topController = window?.rootViewController

        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
        }

        return topController
    }

    private func copyToTemporaryDirectory(_ sourceURL: URL) -> URL? {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(sourceURL.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }

    private func makeFileInfo(from fileURL: URL) -> [String: Any]? {
        do {
            let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            let size = values.fileSize ?? 0
            let data = loadDataToMemory ? try Data(contentsOf: fileURL) : nil

            var fileInfo: [String: Any] = [
                "path": fileURL.path,
                "identifier": fileURL.absoluteString,
                "name": fileURL.lastPathComponent,
                "size": size,
            ]

            if let data {
                fileInfo["bytes"] = FlutterStandardTypedData(bytes: data)
            }

            return fileInfo
        } catch {
            return nil
        }
    }
}
#endif
