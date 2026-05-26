import Foundation
import UniformTypeIdentifiers

enum FilePickerUtils {
    static func buildSaveFileName(from arguments: [String: Any], data: Data?, lastPickedFileExtension: String?) -> String {
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

    static func inferSaveExtension(
        fileType: String?,
        allowedExtensions: [String],
        lastPickedExtension: String?,
        data: Data?
    ) -> String? {
        if let lastPickedExtension, !lastPickedExtension.isEmpty {
            return lastPickedExtension
        }

        if let customExtension = allowedExtensions
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .map({ $0.hasPrefix(".") ? String($0.dropFirst()) : $0 })
            .first(where: { !$0.isEmpty })
        {
            return customExtension
        }

        if let inferredByBytes = inferExtensionFromData(data) {
            return inferredByBytes
        }

        switch fileType {
        case "image": return "jpg"
        case "video": return "mp4"
        case "audio": return "m4a"
        default: return nil
        }
    }

    /// Infers the file extension from the data's content type using Apple's native UTType API.
    static func inferExtensionFromData(_ data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        // Write data to a temporary file so the system can sniff its content type.
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            try data.prefix(1024).write(to: tempURL)
        } catch {
            return nil
        }

        guard let resourceValues = try? tempURL.resourceValues(forKeys: [.contentTypeKey]),
              let utType = resourceValues.contentType,
              utType != .data,
              utType != .item,
              let ext = utType.preferredFilenameExtension
        else {
            return nil
        }

        return ext
    }
}
