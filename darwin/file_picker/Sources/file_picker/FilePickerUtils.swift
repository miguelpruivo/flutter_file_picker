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

    static func inferExtensionFromDataSignature(_ data: Data?) -> String? {
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
}

