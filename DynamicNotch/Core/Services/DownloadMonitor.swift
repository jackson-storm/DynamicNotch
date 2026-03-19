import Foundation
import Dispatch

final class InactiveDownloadMonitor: DownloadMonitoring {
    var onSnapshotChange: (([DownloadModel]) -> Void)?

    func startMonitoring() {
        onSnapshotChange?([])
    }

    func stopMonitoring() {}
}

final class FolderFileDownloadMonitor: DownloadMonitoring {
    var onSnapshotChange: (([DownloadModel]) -> Void)?

    private struct ObservedFile {
        let url: URL
        let displayName: String
        let directoryName: String
        let byteCount: Int64
        let isTemporaryFile: Bool
    }

    private struct TrackedFile {
        var url: URL
        var displayName: String
        var directoryName: String
        var byteCount: Int64
        var progress: Double
        var isTemporaryFile: Bool
        var firstSeenAt: Date
        var lastSeenAt: Date
        var lastGrowthAt: Date?
    }

    private enum Metrics {
        static let scanInterval: TimeInterval = 1.0
        static let activityTimeout: TimeInterval = 2.5
        static let minimumVisibleProgress = 0.08
        static let maximumVisibleProgress = 0.97
        static let growthForecastMultiplier = 6.0
        static let minimumRemainingBytes: Double = 2_000_000
        static let steadyStateRemainingFraction = 0.08
    }

    private let fileManager: FileManager
    private let monitoredDirectories: [URL]
    private let callbackQueue = DispatchQueue(
        label: "com.dynamicnotch.download.monitor",
        qos: .utility
    )

    private var timer: DispatchSourceTimer?
    private var trackedFiles: [String: TrackedFile] = [:]
    private var lastPublishedTransfers: [DownloadModel] = []
    private var isMonitoring = false

    init(
        fileManager: FileManager = .default,
        monitoredDirectories: [URL]? = nil
    ) {
        self.fileManager = fileManager
        self.monitoredDirectories = monitoredDirectories ?? Self.defaultDirectories(using: fileManager)
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        callbackQueue.async { [weak self] in
            self?.primeBaseline()
            self?.installTimerIfNeeded()
        }
    }

    func stopMonitoring() {
        guard !(!isMonitoring && timer == nil) else { return }
        isMonitoring = false

        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.timer?.cancel()
            self.timer = nil
            self.trackedFiles.removeAll()
            self.lastPublishedTransfers.removeAll()
        }
    }
}

private extension FolderFileDownloadMonitor {
    static func defaultDirectories(using fileManager: FileManager) -> [URL] {
        let directories: [FileManager.SearchPathDirectory] = [
            .downloadsDirectory,
            .desktopDirectory,
            .documentDirectory,
            .moviesDirectory,
            .musicDirectory,
            .picturesDirectory
        ]

        return directories
            .compactMap { fileManager.urls(for: $0, in: .userDomainMask).first }
            .map { $0.standardizedFileURL }
            .removingDuplicatePaths()
    }

    private func installTimerIfNeeded() {
        guard timer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: callbackQueue)
        timer.schedule(
            deadline: .now() + Metrics.scanInterval,
            repeating: Metrics.scanInterval
        )
        timer.setEventHandler { [weak self] in
            self?.performScan()
        }
        self.timer = timer
        timer.resume()
    }

    private func primeBaseline() {
        let now = Date()
        trackedFiles = observedFiles().reduce(into: [:]) { result, observed in
            result[observed.url.standardizedFileURL.path] = TrackedFile(
                url: observed.url,
                displayName: observed.displayName,
                directoryName: observed.directoryName,
                byteCount: observed.byteCount,
                progress: estimatedProgress(
                    currentByteCount: observed.byteCount,
                    growthDelta: observed.byteCount,
                    previousProgress: nil,
                    isTemporaryFile: observed.isTemporaryFile
                ),
                isTemporaryFile: observed.isTemporaryFile,
                firstSeenAt: now,
                lastSeenAt: now,
                lastGrowthAt: observed.isTemporaryFile ? now : nil
            )
        }
    }

    private func performScan() {
        guard isMonitoring else { return }

        let now = Date()
        let currentFiles = Dictionary(
            uniqueKeysWithValues: observedFiles().map { ($0.url.standardizedFileURL.path, $0) }
        )

        for (path, observed) in currentFiles {
            if var tracked = trackedFiles[path] {
                let growthDelta = max(0, observed.byteCount - tracked.byteCount)

                if observed.byteCount > tracked.byteCount {
                    tracked.lastGrowthAt = now
                } else if tracked.isTemporaryFile && observed.isTemporaryFile {
                    tracked.lastGrowthAt = tracked.lastGrowthAt ?? now
                }

                tracked.url = observed.url
                tracked.displayName = observed.displayName
                tracked.directoryName = observed.directoryName
                tracked.byteCount = observed.byteCount
                tracked.progress = estimatedProgress(
                    currentByteCount: observed.byteCount,
                    growthDelta: growthDelta,
                    previousProgress: tracked.progress,
                    isTemporaryFile: observed.isTemporaryFile
                )
                tracked.isTemporaryFile = observed.isTemporaryFile
                tracked.lastSeenAt = now
                trackedFiles[path] = tracked
            } else {
                trackedFiles[path] = TrackedFile(
                    url: observed.url,
                    displayName: observed.displayName,
                    directoryName: observed.directoryName,
                    byteCount: observed.byteCount,
                    progress: estimatedProgress(
                        currentByteCount: observed.byteCount,
                        growthDelta: observed.byteCount,
                        previousProgress: nil,
                        isTemporaryFile: observed.isTemporaryFile
                    ),
                    isTemporaryFile: observed.isTemporaryFile,
                    firstSeenAt: now,
                    lastSeenAt: now,
                    lastGrowthAt: observed.isTemporaryFile ? now : nil
                )
            }
        }

        trackedFiles = trackedFiles.filter { currentFiles[$0.key] != nil }

        let activeTransfers = trackedFiles.values
            .compactMap { tracked -> DownloadModel? in
                guard isTransferActive(tracked, now: now) else { return nil }

                return DownloadModel(
                    url: tracked.url,
                    displayName: tracked.displayName,
                    directoryName: tracked.directoryName,
                    byteCount: tracked.byteCount,
                    progress: tracked.progress,
                    startedAt: tracked.firstSeenAt,
                    lastUpdatedAt: tracked.lastGrowthAt ?? tracked.lastSeenAt,
                    isTemporaryFile: tracked.isTemporaryFile
                )
            }
            .sorted {
                if $0.lastUpdatedAt != $1.lastUpdatedAt {
                    return $0.lastUpdatedAt > $1.lastUpdatedAt
                }

                return $0.byteCount > $1.byteCount
            }

        guard activeTransfers != lastPublishedTransfers else { return }
        lastPublishedTransfers = activeTransfers
        publish(activeTransfers)
    }

    private func observedFiles() -> [ObservedFile] {
        monitoredDirectories.flatMap { directory in
            observedFiles(in: directory)
        }
    }

    private func observedFiles(in directory: URL) -> [ObservedFile] {
        guard
            let urls = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [
                    .isRegularFileKey,
                    .fileSizeKey
                ],
                options: [.skipsPackageDescendants]
            )
        else {
            return []
        }

        return urls.compactMap { url in
            guard
                let resourceValues = try? url.resourceValues(forKeys: [
                    .isRegularFileKey,
                    .isDirectoryKey,
                    .fileSizeKey
                ])
            else {
                return nil
            }

            let standardizedURL = url.standardizedFileURL
            let fileName = standardizedURL.lastPathComponent
            let isTemporaryFile = isTemporaryDownloadFile(named: fileName)

            if resourceValues.isRegularFile == true {
                return ObservedFile(
                    url: standardizedURL,
                    displayName: displayName(for: fileName),
                    directoryName: directory.lastPathComponent,
                    byteCount: Int64(resourceValues.fileSize ?? 0),
                    isTemporaryFile: isTemporaryFile
                )
            }

            guard resourceValues.isDirectory == true, isTemporaryFile else {
                return nil
            }

            return ObservedFile(
                url: standardizedURL,
                displayName: displayName(for: fileName),
                directoryName: directory.lastPathComponent,
                byteCount: recursiveByteCount(in: standardizedURL),
                isTemporaryFile: true
            )
        }
    }

    private func isTransferActive(_ tracked: TrackedFile, now: Date) -> Bool {
        guard now.timeIntervalSince(tracked.lastSeenAt) <= Metrics.activityTimeout else {
            return false
        }

        if tracked.isTemporaryFile {
            return true
        }

        guard let lastGrowthAt = tracked.lastGrowthAt else {
            return false
        }

        return now.timeIntervalSince(lastGrowthAt) <= Metrics.activityTimeout
    }

    private func estimatedProgress(
        currentByteCount: Int64,
        growthDelta: Int64,
        previousProgress: Double?,
        isTemporaryFile: Bool
    ) -> Double {
        let currentByteCount = max(0, currentByteCount)
        guard currentByteCount > 0 else { return Metrics.minimumVisibleProgress }

        let forecastFromGrowth = Double(max(0, growthDelta)) * Metrics.growthForecastMultiplier
        let forecastFromCurrentSize = Double(currentByteCount) * Metrics.steadyStateRemainingFraction
        let remainingFloor = isTemporaryFile ?
            Metrics.minimumRemainingBytes :
            Metrics.minimumRemainingBytes * 0.5

        let estimatedRemainingBytes = max(
            forecastFromGrowth,
            forecastFromCurrentSize,
            remainingFloor
        )

        var progress = Double(currentByteCount) / (Double(currentByteCount) + estimatedRemainingBytes)
        progress = max(progress, Metrics.minimumVisibleProgress)
        progress = min(progress, Metrics.maximumVisibleProgress)

        if let previousProgress {
            progress = max(previousProgress, progress)
        }

        return progress
    }

    private func recursiveByteCount(in directory: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [
                .isRegularFileKey,
                .fileSizeKey
            ],
            options: [.skipsPackageDescendants],
            errorHandler: nil
        ) else {
            return 0
        }

        var total: Int64 = 0

        for case let fileURL as URL in enumerator {
            guard
                let resourceValues = try? fileURL.resourceValues(forKeys: [
                    .isRegularFileKey,
                    .fileSizeKey
                ]),
                resourceValues.isRegularFile == true
            else {
                continue
            }

            total += Int64(resourceValues.fileSize ?? 0)
        }

        return total
    }

    private func publish(_ transfers: [DownloadModel]) {
        let handler = onSnapshotChange
        DispatchQueue.main.async {
            handler?(transfers)
        }
    }

    private func displayName(for fileName: String) -> String {
        var name = fileName

        while isTemporaryDownloadFile(named: name) {
            let url = URL(fileURLWithPath: name)
            let trimmedName = url.deletingPathExtension().lastPathComponent
            guard trimmedName != name else { break }
            name = trimmedName
        }

        return name
    }

    private func isTemporaryDownloadFile(named fileName: String) -> Bool {
        let lowercasedName = fileName.lowercased()
        return [
            ".download",
            ".crdownload",
            ".part",
            ".partial",
            ".tmp"
        ].contains { lowercasedName.hasSuffix($0) }
    }
}

private extension Array where Element == URL {
    func removingDuplicatePaths() -> [URL] {
        var seenPaths = Set<String>()

        return filter { url in
            let path = url.standardizedFileURL.path
            return seenPaths.insert(path).inserted
        }
    }
}
