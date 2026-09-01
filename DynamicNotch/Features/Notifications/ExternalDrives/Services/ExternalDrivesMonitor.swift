import Foundation
internal import AppKit
import OSLog

final class ExternalDrivesMonitor {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "ExternalDrivesMonitor")

    var onDriveEvent: ((ExternalDriveModel) -> Void)?
    var includeDiskImages: Bool = true

    private var observers: [NSObjectProtocol] = []
    private var knownVolumes: [String: (name: String, icon: NSImage?, isEjectable: Bool)] = [:]
    private let queue = DispatchQueue(label: "com.dynamicnotch.external-drives-monitor")

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard observers.isEmpty else { return }

        let center = NSWorkspace.shared.notificationCenter

        let mountObserver = center.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleVolumeMounted(notification)
        }

        let unmountObserver = center.addObserver(
            forName: NSWorkspace.didUnmountNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleVolumeUnmounted(notification)
        }

        observers = [mountObserver, unmountObserver]
        logger.info("External drives monitoring started")
    }

    func stopMonitoring() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
        logger.info("External drives monitoring stopped")
    }

    func ejectDrive(at url: URL, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: url)
                self?.logger.info("Successfully ejected drive at \(url.path)")
                DispatchQueue.main.async {
                    completion?(true)
                }
            } catch {
                self?.logger.error("Failed to eject drive at \(url.path): \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }

    private func handleVolumeMounted(_ notification: Notification) {
        guard let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else {
            return
        }

        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeLocalizedNameKey,
            .volumeIsInternalKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsReadOnlyKey
        ]

        guard let resourceValues = try? url.resourceValues(forKeys: keys) else {
            return
        }

        // Skip internal non-removable/non-ejectable system volumes
        let isInternal = resourceValues.volumeIsInternal ?? false
        let isEjectable = resourceValues.volumeIsEjectable ?? false
        let isRemovable = resourceValues.volumeIsRemovable ?? false

        if isInternal && !isEjectable && !isRemovable {
            return
        }

        // Skip standard internal volume names
        let name = resourceValues.volumeLocalizedName ?? resourceValues.volumeName ?? url.lastPathComponent
        if name == "Macintosh HD" || name == "Recovery" || name == "Preboot" || name == "Data" || name == "VM" {
            return
        }

        let isReadOnly = resourceValues.volumeIsReadOnly ?? false
        let isDiskImage = isReadOnly && isEjectable && !isRemovable

        if isDiskImage && !includeDiskImages {
            return
        }

        let total = Int64(resourceValues.volumeTotalCapacity ?? 0)
        let free = Int64(resourceValues.volumeAvailableCapacity ?? 0)
        let icon = NSWorkspace.shared.icon(forFile: url.path)

        // Cache info for unmount notification
        knownVolumes[url.path] = (name: name, icon: icon, isEjectable: isEjectable)

        let model = ExternalDriveModel(
            id: url.path,
            name: name,
            volumeURL: url,
            totalBytes: total,
            freeBytes: free,
            isEjectable: isEjectable,
            isDiskImage: isDiskImage,
            eventType: .connected,
            icon: icon
        )

        logger.info("External drive mounted: \(name)")
        onDriveEvent?(model)
    }

    private func handleVolumeUnmounted(_ notification: Notification) {
        guard let url = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else {
            return
        }

        guard let cached = knownVolumes.removeValue(forKey: url.path) else {
            return
        }

        guard cached.isEjectable else { return }

        let model = ExternalDriveModel(
            id: url.path,
            name: cached.name,
            volumeURL: nil,
            totalBytes: 0,
            freeBytes: 0,
            isEjectable: cached.isEjectable,
            isDiskImage: false,
            eventType: .ejected,
            icon: cached.icon
        )

        logger.info("External drive safely unmounted: \(cached.name)")
        onDriveEvent?(model)
    }
}
