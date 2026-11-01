internal import AppKit

/// The cache stores VPN app icons by bundle ID because the views request them on each one-second
/// redraw. It does not cache missing apps, so the views show their icons if they are installed
/// later.
enum VPNAppIconCache {
    private static var icons: [String: NSImage] = [:]

    static func icon(for bundleID: String) -> NSImage? {
        if let icon = icons[bundleID] {
            return icon
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        icons[bundleID] = icon
        return icon
    }
}
