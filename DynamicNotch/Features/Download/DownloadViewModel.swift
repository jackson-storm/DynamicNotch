import Combine
import Foundation

@MainActor
final class DownloadViewModel: ObservableObject {
    @Published private(set) var activeDownloads: [DownloadModel] = []
    @Published var event: DownloadEvent?

    private let monitor: any DownloadMonitoring
    private var hasStartedMonitoring = false
    private var latestObservedDownloads: [DownloadModel] = []
    #if DEBUG
    private var debugPreviewDownloads: [DownloadModel]?
    #endif

    var hasActiveDownloads: Bool {
        !activeDownloads.isEmpty
    }

    var primaryDownload: DownloadModel? {
        activeDownloads.first
    }

    var additionalDownloadCount: Int {
        max(0, activeDownloads.count - 1)
    }

    init(monitor: any DownloadMonitoring) {
        self.monitor = monitor
        self.monitor.onSnapshotChange = { [weak self] downloads in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.apply(downloads)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.apply(downloads)
                }
            }
        }
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        monitor.startMonitoring()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }
        hasStartedMonitoring = false
        monitor.stopMonitoring()
    }

    #if DEBUG
    func showDebugPreviewDownloadsIfNeeded() {
        let previewDownloads = Self.makeDebugPreviewDownloads()
        debugPreviewDownloads = previewDownloads
        commit(previewDownloads, emitEvent: false)
    }

    func hideDebugPreviewDownloadsIfNeeded() {
        guard debugPreviewDownloads != nil else { return }
        debugPreviewDownloads = nil
        commit(latestObservedDownloads, emitEvent: false)
    }

    private static func makeDebugPreviewDownloads() -> [DownloadModel] {
        let now = Date()

        return [
            DownloadModel(
                url: URL(fileURLWithPath: "/tmp/DebugExport.mov"),
                displayName: "DebugExportBigNameForFile.mov",
                directoryName: "Downloads",
                byteCount: 148_320_256,
                estimatedTotalByteCount: 247_200_427,
                progress: 0.60,
                startedAt: now.addingTimeInterval(-24),
                lastUpdatedAt: now,
                isTemporaryFile: false,
                bytesPerSecond: 12_845_056
            ),
            DownloadModel(
                url: URL(fileURLWithPath: "/tmp/ProjectArchive.zip"),
                displayName: "ProjectArchive.zip",
                directoryName: "Desktop",
                byteCount: 62_914_560,
                estimatedTotalByteCount: 136_770_783,
                progress: 0.46,
                startedAt: now.addingTimeInterval(-31),
                lastUpdatedAt: now.addingTimeInterval(-2),
                isTemporaryFile: false,
                bytesPerSecond: 4_096_000
            )
        ]
    }
    #endif
}

private extension DownloadViewModel {
    func apply(_ downloads: [DownloadModel]) {
        let sortedDownloads = downloads.sorted {
            if $0.lastUpdatedAt != $1.lastUpdatedAt {
                return $0.lastUpdatedAt > $1.lastUpdatedAt
            }

            return $0.byteCount > $1.byteCount
        }

        latestObservedDownloads = sortedDownloads

        #if DEBUG
        guard debugPreviewDownloads == nil else { return }
        #endif

        commit(sortedDownloads)
    }

    func commit(_ downloads: [DownloadModel], emitEvent: Bool = true) {
        let wasActive = !activeDownloads.isEmpty
        let isActive = !downloads.isEmpty

        activeDownloads = downloads

        if emitEvent {
            if !wasActive && isActive {
                event = .started
            } else if wasActive && !isActive {
                event = .stopped
            }
        }
    }
}
