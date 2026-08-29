import Foundation
internal import AppKit
import UniformTypeIdentifiers

enum ExternalDriveEventType: Equatable {
    case connected
    case ejected
}

struct ExternalDriveModel: Equatable {
    let id: String
    let name: String
    let volumeURL: URL?
    let totalBytes: Int64
    let freeBytes: Int64
    let isEjectable: Bool
    let isDiskImage: Bool
    let eventType: ExternalDriveEventType
    let icon: NSImage?

    static func == (lhs: ExternalDriveModel, rhs: ExternalDriveModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.volumeURL == rhs.volumeURL &&
        lhs.totalBytes == rhs.totalBytes &&
        lhs.freeBytes == rhs.freeBytes &&
        lhs.isEjectable == rhs.isEjectable &&
        lhs.isDiskImage == rhs.isDiskImage &&
        lhs.eventType == rhs.eventType
    }

    var formattedCapacity: String? {
        guard totalBytes > 0 else { return nil }
        let freeStr = ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file)
        let totalStr = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(freeStr) / \(totalStr)"
    }
}

#if DEBUG
extension ExternalDriveModel {
    static let debugPreviewConnected = ExternalDriveModel(
        id: "debug-drive-ssd",
        name: "Samsung T7 SSD",
        volumeURL: URL(fileURLWithPath: "/Volumes/Samsung T7 SSD"),
        totalBytes: 1_000_000_000_000,
        freeBytes: 654_000_000_000,
        isEjectable: true,
        isDiskImage: false,
        eventType: .connected,
        icon: NSWorkspace.shared.icon(for: .volume)
    )

    static let debugPreviewUSB = ExternalDriveModel(
        id: "debug-drive-usb",
        name: "SanDisk Ultra",
        volumeURL: URL(fileURLWithPath: "/Volumes/SanDisk Ultra"),
        totalBytes: 64_000_000_000,
        freeBytes: 42_300_000_000,
        isEjectable: true,
        isDiskImage: false,
        eventType: .connected,
        icon: NSWorkspace.shared.icon(for: .volume)
    )

    static let debugPreviewDiskImage = ExternalDriveModel(
        id: "debug-drive-dmg",
        name: "DynamicNotch Installer",
        volumeURL: URL(fileURLWithPath: "/Volumes/DynamicNotch Installer"),
        totalBytes: 250_000_000,
        freeBytes: 12_000_000,
        isEjectable: true,
        isDiskImage: true,
        eventType: .connected,
        icon: NSWorkspace.shared.icon(for: .volume)
    )

    static let debugPreviewEjected = ExternalDriveModel(
        id: "debug-drive-ejected",
        name: "Samsung T7 SSD",
        volumeURL: nil,
        totalBytes: 1_000_000_000_000,
        freeBytes: 654_000_000_000,
        isEjectable: true,
        isDiskImage: false,
        eventType: .ejected,
        icon: NSWorkspace.shared.icon(for: .volume)
    )
}
#endif
