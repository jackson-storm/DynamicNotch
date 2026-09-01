import Foundation

enum FullDiskAccessAuthorization {
    private static let probeURLs: [URL] = [
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db"),
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/DoNotDisturb/DB/ModeConfigurations.json")
    ]

    static func hasPermission() -> Bool {
        for url in probeURLs {
            if canReadProtectedResource(at: url) {
                return true
            }
        }
        return false
    }

    private static func canReadProtectedResource(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return false
        }

        do {
            let handle = try FileHandle(forReadingFrom: url)
            try handle.close()
            return true
        } catch {
            return false
        }
    }
}
