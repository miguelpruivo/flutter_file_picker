import CoreServices
import Foundation
import UniformTypeIdentifiers

enum MacOSFilePickerUtils {
    static func buildSaveFileName(from arguments: [String: Any], data: Data?, lastPickedFileExtension: String?) -> String {
        DarwinFilePickerUtils.buildSaveFileName(
            from: arguments,
            data: data,
            lastPickedFileExtension: lastPickedFileExtension,
            inferExtensionFromData: inferExtensionFromData)
    }

    /// Infers the file extension from the data's content type using Apple's native UTType API.
    private static func inferExtensionFromData(_ data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            try data.prefix(1024).write(to: tempURL)
        } catch {
            return nil
        }


        guard let resourceValues = try? tempURL.resourceValues(forKeys: [.typeIdentifierKey]),
              let typeIdentifier = resourceValues.typeIdentifier,
              typeIdentifier != "public.data",
              typeIdentifier != "public.item",
              let ext = UTTypeCopyPreferredTagWithClass(
                typeIdentifier as CFString,
                kUTTagClassFilenameExtension
              )?.takeRetainedValue() as String?
        else {
            return nil
        }

        return ext
    }
}
