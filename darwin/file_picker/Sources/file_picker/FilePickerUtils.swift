import Foundation

#if os(macOS)
import Cocoa
#endif
import UniformTypeIdentifiers

class FilePickerUtils {
    static func resolveType(_ type: String) -> [String] {
        // Implement mapping from "audio", "image", "video", "any" to UTTypes
        return []
    }
    
    static func clearTemporaryFiles() -> Bool {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        do {
            let filePaths = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil, options: [])
            for filePath in filePaths {
                try fileManager.removeItem(at: filePath)
            }
            return true
        } catch {
            return false
        }
    }
    
    static func saveFile(bytes: Data, fileName: String?) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let name = fileName ?? "tempfile_\(UUID().uuidString)"
        let fileURL = tempDir.appendingPathComponent(name)
        
        do {
            try bytes.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    // Helper to get mime type / UTType from extension
    static func mimeType(for pathExtension: String) -> String? {
        if #available(macOS 11.0, iOS 14.0, *) {
             return UTType(filenameExtension: pathExtension)?.identifier
        } else {
             return nil
        }
    }
}
