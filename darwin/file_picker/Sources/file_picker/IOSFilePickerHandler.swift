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
    private var lastPickedFileExtension: String?

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
                self.updateLastPickedFileExtension(from: copiedURL)
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
            updateLastPickedFileExtension(from: copiedURL)
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
        let fileName = buildSaveFileName(from: arguments, data: bytes?.data)

        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: tempFile.path) {
                try FileManager.default.removeItem(at: tempFile)
            }
            if let data = bytes?.data {
                try data.write(to: tempFile, options: .atomic)
            }
        } catch {
            result?(
                FlutterError(
                    code: "Failed to write file",
                    message: error.localizedDescription,
                    details: nil))
            result = nil
            isSaveFile = false
            return
        }

        let picker = UIDocumentPickerViewController(
            forExporting: [tempFile],
            asCopy: true)
        picker.delegate = self
        picker.presentationController?.delegate = self
        topViewController()?.present(picker, animated: true)
    }

    private func buildSaveFileName(from arguments: [String: Any], data: Data?) -> String {
        let providedName = ((arguments["fileName"] as? String) ?? "").trimmingCharacters(
            in: .whitespacesAndNewlines)
        let fileType = (arguments["fileType"] as? String)?.lowercased()
        let allowedExtensions = arguments["allowedExtensions"] as? [String] ?? []

        let fallbackBaseName = "file_picker_file"
        let baseName = providedName.isEmpty ? fallbackBaseName : providedName

        // Keep user extension when provided; only infer when it is missing.
        if !URL(fileURLWithPath: baseName).pathExtension.isEmpty {
            return baseName
        }

        if let inferredExtension = inferSaveExtension(
            fileType: fileType,
            allowedExtensions: allowedExtensions,
            lastPickedExtension: lastPickedFileExtension,
            data: data)
        {
            return "\(baseName).\(inferredExtension)"
        }

        return baseName
    }

    private func inferSaveExtension(
        fileType: String?,
        allowedExtensions: [String],
        lastPickedExtension: String?,
        data: Data?
    ) -> String? {
        if let lastPickedExtension,
           !lastPickedExtension.isEmpty
        {
            return lastPickedExtension
        }

        if let customExtension = allowedExtensions
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .map({ $0.hasPrefix(".") ? String($0.dropFirst()) : $0 })
            .first(where: { !$0.isEmpty })
        {
            return customExtension
        }

        if let inferredByBytes = inferExtensionFromDataSignature(data) {
            return inferredByBytes
        }

        switch fileType {
        case "image":
            return "jpg"
        case "video":
            return "mp4"
        case "audio":
            return "m4a"
        default:
            return nil
        }
    }

    private func inferExtensionFromDataSignature(_ data: Data?) -> String? {
        guard let data, !data.isEmpty else {
            return nil
        }

        func hasPrefix(_ bytes: [UInt8]) -> Bool {
            guard data.count >= bytes.count else {
                return false
            }
            return data.prefix(bytes.count).elementsEqual(bytes)
        }

        func asciiString(from range: Range<Int>) -> String? {
            guard data.count >= range.upperBound else {
                return nil
            }
            let subdata = data.subdata(in: range)
            return String(data: subdata, encoding: .ascii)
        }

        if hasPrefix([0x25, 0x50, 0x44, 0x46]) { // %PDF
            return "pdf"
        }
        if hasPrefix([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return "png"
        }
        if hasPrefix([0xFF, 0xD8, 0xFF]) {
            return "jpg"
        }
        if hasPrefix([0x47, 0x49, 0x46, 0x38]) {
            return "gif"
        }
        if hasPrefix([0x49, 0x49, 0x2A, 0x00]) || hasPrefix([0x4D, 0x4D, 0x00, 0x2A]) {
            return "tiff"
        }
        if hasPrefix([0x42, 0x4D]) {
            return "bmp"
        }
        if hasPrefix([0x52, 0x49, 0x46, 0x46]),
           let riffType = asciiString(from: 8..<12)
        {
            if riffType == "WEBP" {
                return "webp"
            }
            if riffType == "WAVE" {
                return "wav"
            }
        }

        // ISO BMFF family (mp4/m4a/heic/heif)
        if let ftyp = asciiString(from: 4..<8), ftyp == "ftyp",
           let brand = asciiString(from: 8..<12)
        {
            if brand.hasPrefix("M4A") {
                return "m4a"
            }
            if ["heic", "heix", "hevc", "hevx", "heim", "heis", "mif1", "msf1"].contains(brand) {
                return "heic"
            }
            return "mp4"
        }

        if hasPrefix([0x49, 0x44, 0x33]) {
            return "mp3"
        }
        if hasPrefix([0x50, 0x4B, 0x03, 0x04]) {
            return "zip"
        }

        return nil
    }

    private func updateLastPickedFileExtension(from fileURL: URL) {
        let pathExtension = fileURL.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pathExtension.isEmpty {
            lastPickedFileExtension = pathExtension
        }
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
