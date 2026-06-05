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
    private var withPersistentAccess = false
    private var isDirectoryPicker = false
    private var isSaveFile = false
    private var saveSourceTeardown: (() -> Void)?
    private var readSessions: [String: ReadSession] = [:]

    private struct ReadSession {
        let inputStream: InputStream
        let teardown: () -> Void
    }

    private struct ResolvedFileAccess {
        let url: URL
        let persistentIdentifier: String?
        let teardown: () -> Void
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if handleNonInteractiveMethod(call, result: result) {
            return
        }

        if self.result != nil {
            result(
                FlutterError(
                    code: "multiple_request",
                    message: "Cancelled by a second request",
                    details: nil))
            return
        }

        self.result = result

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
        withPersistentAccess = (arguments["withPersistentAccess"] as? Bool) ?? false

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
                presentDocumentPicker(
                    contentTypes: resolveDocumentContentTypes(for: call.method),
                    allowsMultipleSelection: allowMultipleSelection,
                    asDirectoryPicker: false)

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
        var resolved = Array<[String: Any]?>(repeating: nil, count: results.count)
        let resolvedLock = NSLock()

        for (index, item) in results.enumerated() {
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
                    resolvedLock.lock()
                    resolved[index] = fileInfo
                    resolvedLock.unlock()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else {
                return
            }
            eventSink?(false)
            let orderedResolved = resolved.compactMap { $0 }
            currentResult(orderedResolved.isEmpty ? nil : orderedResolved)
            result = nil
        }
    }

    func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
        finishCurrentRequest(nil)
    }

    func presentationControllerWillDismiss(_: UIPresentationController) {
        finishCurrentRequest(nil)
    }

    func presentationControllerDidDismiss(
        _: UIPresentationController
    ) {
        finishCurrentRequest(nil)
    }

    func documentPicker(
        _: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        guard let currentResult = result else {
            return
        }

        if isSaveFile {
            eventSink?(false)
            saveSourceTeardown?()
            saveSourceTeardown = nil
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
                guard let fileInfo = makePersistentFileInfo(from: sourceURL) else {
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
        if #available(iOS 15.0, *) {
            configuration.selection = .ordered
        }

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
            asCopy: false)
        picker.delegate = self
        picker.presentationController?.delegate = self
        picker.allowsMultipleSelection = allowsMultipleSelection
        topViewController()?.present(picker, animated: true)
    }

    private func saveFile(_ arguments: [String: Any]) {
        isSaveFile = true
        let fileName = (arguments["fileName"] as? String) ?? UUID().uuidString
        let bytes = arguments["bytes"] as? FlutterStandardTypedData
        let sourcePath = arguments["sourcePath"] as? String
        let sourceIdentifier = arguments["sourceIdentifier"] as? String
        let sourcePersistentIdentifier = arguments["sourcePersistentIdentifier"] as? String

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            do {
                let resolvedSource = try self.resolveSaveSource(
                    fileName: fileName,
                    bytes: bytes,
                    sourcePath: sourcePath,
                    sourceIdentifier: sourceIdentifier,
                    sourcePersistentIdentifier: sourcePersistentIdentifier)

                DispatchQueue.main.async { [weak self] in
                    guard let self else {
                        resolvedSource.teardown()
                        return
                    }

                    self.saveSourceTeardown = resolvedSource.teardown
                    self.eventSink?(true)

                    let picker = UIDocumentPickerViewController(
                        forExporting: [resolvedSource.url],
                        asCopy: true)
                    picker.delegate = self
                    picker.presentationController?.delegate = self
                    self.topViewController()?.present(picker, animated: true)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.eventSink?(false)
                    self.result?(
                        FlutterError(
                            code: "save_file_error",
                            message: error.localizedDescription,
                            details: nil))
                    self.result = nil
                    self.isSaveFile = false
                    self.saveSourceTeardown = nil
                }
            }
        }
    }

    private func resolveSaveSource(
        fileName: String,
        bytes: FlutterStandardTypedData?,
        sourcePath: String?,
        sourceIdentifier: String?,
        sourcePersistentIdentifier: String?
    ) throws -> ResolvedFileAccess {
        if let sourcePersistentIdentifier,
           let bookmarkData = Data(base64Encoded: sourcePersistentIdentifier)
        {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale)

            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(
                    domain: "file_picker",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Could not access the security-scoped resource for save."])
            }

            return ResolvedFileAccess(
                url: url,
                persistentIdentifier: sourcePersistentIdentifier,
                teardown: { url.stopAccessingSecurityScopedResource() })
        }

        if let sourceIdentifier, let sourceURL = URL(string: sourceIdentifier) {
            return ResolvedFileAccess(url: sourceURL, persistentIdentifier: nil, teardown: {})
        }

        if let sourcePath, !sourcePath.isEmpty {
            return ResolvedFileAccess(
                url: URL(fileURLWithPath: sourcePath),
                persistentIdentifier: nil,
                teardown: {})
        }

        if let data = bytes?.data {
            let tempFile = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(fileName)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: tempFile.path) {
                try fileManager.removeItem(at: tempFile)
            }
            try data.write(to: tempFile, options: .atomic)
            return ResolvedFileAccess(url: tempFile, persistentIdentifier: nil, teardown: {})
        }

        throw NSError(
            domain: "file_picker",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "Missing source reference. Provide bytes or sourcePath/sourceIdentifier/sourcePersistentIdentifier."])
    }

    private func resolveCustomContentTypes(_ allowedExtensions: [String]) -> [UTType] {
        allowedExtensions.compactMap { ext in
            let sanitized = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
            return UTType(filenameExtension: sanitized)
        }
    }

    private func resolveDocumentContentTypes(for type: String) -> [UTType] {
        switch type {
        case "image":
            return [.image]
        case "video":
            return [.movie, .video]
        case "media":
            return [.image, .movie, .video, .audio]
        default:
            return [.item]
        }
    }

    private func handleNonInteractiveMethod(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) -> Bool {
        switch call.method {
        case "clear":
            result(clearTemporaryFiles())
            return true
        case "resolvePersistentFile":
            guard let arguments = call.arguments as? [String: Any],
                  let persistentIdentifier = arguments["persistentIdentifier"] as? String
            else {
                result(
                    FlutterError(
                        code: "invalid_arguments",
                        message: "Missing persistentIdentifier.",
                        details: nil))
                return true
            }

            do {
                let access = try resolveFileAccess(
                    identifier: nil,
                    persistentIdentifier: persistentIdentifier)
                defer { access.teardown() }
                let withData = (arguments["withData"] as? Bool) ?? false
                result(
                    fileInfo(
                        from: access.url,
                        persistentIdentifier: access.persistentIdentifier,
                        path: nil))
            } catch {
                result(
                    FlutterError(
                        code: "resolve_persistent_file_error",
                        message: error.localizedDescription,
                        details: nil))
            }
            return true
        case "readFileBytes":
            guard let arguments = call.arguments as? [String: Any] else {
                result(nil)
                return true
            }

            do {
                let access = try resolveFileAccess(
                    identifier: arguments["identifier"] as? String,
                    persistentIdentifier: arguments["persistentIdentifier"] as? String)
                defer { access.teardown() }
                let data = try Data(contentsOf: access.url)
                result(FlutterStandardTypedData(bytes: data))
            } catch {
                result(
                    FlutterError(
                        code: "read_file_error",
                        message: error.localizedDescription,
                        details: nil))
            }
            return true
        case "openReadSession":
            guard let arguments = call.arguments as? [String: Any] else {
                result(nil)
                return true
            }

            do {
                let access = try resolveFileAccess(
                    identifier: arguments["identifier"] as? String,
                    persistentIdentifier: arguments["persistentIdentifier"] as? String)
                guard let inputStream = InputStream(url: access.url) else {
                    access.teardown()
                    throw NSError(
                        domain: "file_picker",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Unable to open an input stream for the selected file."])
                }
                inputStream.open()
                let sessionId = UUID().uuidString
                readSessions[sessionId] = ReadSession(
                    inputStream: inputStream,
                    teardown: access.teardown)
                result(sessionId)
            } catch {
                result(
                    FlutterError(
                        code: "open_read_session_error",
                        message: error.localizedDescription,
                        details: nil))
            }
            return true
        case "readSessionChunk":
            guard let arguments = call.arguments as? [String: Any],
                  let sessionId = arguments["sessionId"] as? String,
                  let session = readSessions[sessionId]
            else {
                result(nil)
                return true
            }

            let chunkSize = (arguments["chunkSize"] as? Int) ?? 64 * 1024
            var buffer = [UInt8](repeating: 0, count: chunkSize)
            let bytesRead = session.inputStream.read(&buffer, maxLength: chunkSize)

            if bytesRead < 0 {
                let message = session.inputStream.streamError?.localizedDescription
                    ?? "Unknown stream error."
                closeReadSession(nil, sessionId: sessionId)
                result(
                    FlutterError(
                        code: "read_session_chunk_error",
                        message: message,
                        details: nil))
            } else if bytesRead == 0 {
                closeReadSession(nil, sessionId: sessionId)
                result(nil)
            } else {
                result(
                    FlutterStandardTypedData(
                        bytes: Data(buffer.prefix(bytesRead))))
            }
            return true
        case "closeReadSession":
            let arguments = call.arguments as? [String: Any]
            closeReadSession(result, sessionId: arguments?["sessionId"] as? String)
            return true
        default:
            return false
        }
    }

    private func resolveFileAccess(
        identifier: String?,
        persistentIdentifier: String?
    ) throws -> ResolvedFileAccess {
        if let persistentIdentifier,
           let bookmarkData = Data(base64Encoded: persistentIdentifier)
        {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale)

            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(
                    domain: "file_picker",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Could not access the security-scoped resource."])
            }

            let refreshedIdentifier: String?
            if isStale {
                refreshedIdentifier = try createSecurityScopedBookmark(for: url)
            } else {
                refreshedIdentifier = persistentIdentifier
            }

            return ResolvedFileAccess(
                url: url,
                persistentIdentifier: refreshedIdentifier,
                teardown: { url.stopAccessingSecurityScopedResource() })
        }

        guard let identifier, let url = URL(string: identifier) else {
            throw NSError(
                domain: "file_picker",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Missing file identifier."])
        }

        return ResolvedFileAccess(url: url, persistentIdentifier: nil, teardown: {})
    }

    private func createSecurityScopedBookmark(for url: URL) throws -> String {
        let bookmarkData = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil)
        return bookmarkData.base64EncodedString()
    }

     private func makePersistentFileInfo(from fileURL: URL) -> [String: Any]? {
         do {
             guard fileURL.startAccessingSecurityScopedResource() else {
                 return nil
             }
             defer { fileURL.stopAccessingSecurityScopedResource() }

             let persistentIdentifier = try createSecurityScopedBookmark(for: fileURL)
             // When using persistent access, never load data into memory
             // Users should use PlatformFile.readAsByteStream() or readAsBytes() instead
             return fileInfo(
                 from: fileURL,
                 persistentIdentifier: persistentIdentifier,
                 path: nil)
         } catch {
             return nil
         }
     }

     private func fileInfo(
         from fileURL: URL,
         persistentIdentifier: String?,
         path: String?
     ) -> [String: Any]? {
         do {
             let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
             let size = values.fileSize ?? 0

             var fileInfo: [String: Any] = [
                 "path": path,
                 "identifier": fileURL.absoluteString,
                 "name": fileURL.lastPathComponent,
                 "size": size,
             ]

             if let persistentIdentifier {
                 fileInfo["persistentIdentifier"] = persistentIdentifier
             }

             return fileInfo
         } catch {
             return nil
         }
     }

    private func closeReadSession(
        _ result: FlutterResult?,
        sessionId: String?
    ) {
        guard let sessionId, let session = readSessions.removeValue(forKey: sessionId) else {
            result?(nil)
            return
        }

        session.inputStream.close()
        session.teardown()
        result?(nil)
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
        fileInfo(
            from: fileURL,
            persistentIdentifier: nil,
            path: fileURL.path)
    }

    private func finishCurrentRequest(_ value: Any?) {
        guard let currentResult = result else {
            return
        }

        if isSaveFile {
            eventSink?(false)
            isSaveFile = false
            saveSourceTeardown?()
            saveSourceTeardown = nil
        }

        result = nil
        currentResult(value)
    }
}
#endif
