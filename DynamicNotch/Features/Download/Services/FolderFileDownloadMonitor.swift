import Darwin
import Foundation
import Dispatch
import CoreServices

nonisolated final class FolderFileDownloadMonitor: DownloadMonitoring, @unchecked Sendable {
    var onSnapshotChange: (@Sendable ([DownloadModel]) -> Void)?

    private struct ObservedFile {
        let url: URL
        let displayName: String
        let directoryName: String
        let byteCount: Int64
        let isTemporaryFile: Bool
        let authoritativeProgress: Double?
        let authoritativeTotalBytes: Int64?
    }

    private struct TrackedFile {
        var url: URL
        var displayName: String
        var directoryName: String
        var byteCount: Int64
        var estimatedTotalByteCount: Int64
        var progress: Double
        var bytesPerSecond: Int64
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
    private let chromiumReader: ChromiumDownloadMetadataReader
    private let callbackQueue = DispatchQueue(
        label: "com.dynamicnotch.download.monitor",
        qos: .utility
    )

    private var timer: DispatchSourceTimer?
    private var directoryWatcher: DirectoryWatcher?
    private var trackedFiles: [String: TrackedFile] = [:]
    private var lastPublishedTransfers: [DownloadModel] = []
    private var isMonitoring = false

    init(
        fileManager: FileManager = .default,
        monitoredDirectories: [URL]? = nil,
        chromiumReader: ChromiumDownloadMetadataReader = ChromiumDownloadMetadataReader()
    ) {
        self.fileManager = fileManager
        self.monitoredDirectories = monitoredDirectories ?? Self.defaultDirectories(using: fileManager)
        self.chromiumReader = chromiumReader
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        callbackQueue.async { [weak self] in
            guard let self, self.isMonitoring else { return }
            self.setupDirectoryWatcher()
            self.primeBaseline()
            self.performScan()
        }
    }

    func stopMonitoring() {
        guard isMonitoring || timer != nil || directoryWatcher != nil else { return }
        isMonitoring = false

        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.directoryWatcher?.stop()
            self.directoryWatcher = nil
            self.stopTimer()
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

    private func setupDirectoryWatcher() {
        directoryWatcher?.stop()
        directoryWatcher = DirectoryWatcher(
            urls: monitoredDirectories,
            queue: callbackQueue
        ) { [weak self] in
            self?.performScan()
        }
    }

    private func startTimerIfNeeded() {
        guard timer == nil, isMonitoring else { return }

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

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func primeBaseline() {
        let now = Date()
        trackedFiles = observedFiles().reduce(into: [:]) { result, observed in
            let progress = resolveProgress(
                for: observed,
                growthDelta: observed.byteCount,
                previousProgress: nil
            )

            result[observed.url.standardizedFileURL.path] = TrackedFile(
                url: observed.url,
                displayName: observed.displayName,
                directoryName: observed.directoryName,
                byteCount: observed.byteCount,
                estimatedTotalByteCount: observed.authoritativeTotalBytes ?? estimatedTotalByteCount(
                    currentByteCount: observed.byteCount,
                    progress: progress
                ),
                progress: progress,
                bytesPerSecond: 0,
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
                let elapsedInterval = max(now.timeIntervalSince(tracked.lastSeenAt), 0.001)

                if observed.byteCount > tracked.byteCount {
                    tracked.lastGrowthAt = now
                } else if tracked.isTemporaryFile && observed.isTemporaryFile {
                    tracked.lastGrowthAt = tracked.lastGrowthAt ?? now
                }

                tracked.url = observed.url
                tracked.displayName = observed.displayName
                tracked.directoryName = observed.directoryName
                tracked.byteCount = observed.byteCount
                tracked.progress = resolveProgress(
                    for: observed,
                    growthDelta: growthDelta,
                    previousProgress: tracked.progress
                )
                tracked.estimatedTotalByteCount = totalByteCount(
                    for: observed,
                    progress: tracked.progress,
                    previousEstimate: tracked.estimatedTotalByteCount
                )
                tracked.bytesPerSecond = estimatedBytesPerSecond(
                    growthDelta: growthDelta,
                    elapsedInterval: elapsedInterval,
                    previousBytesPerSecond: tracked.bytesPerSecond,
                    lastGrowthAt: tracked.lastGrowthAt,
                    now: now
                )
                tracked.isTemporaryFile = observed.isTemporaryFile
                tracked.lastSeenAt = now
                trackedFiles[path] = tracked
            } else {
                let progress = resolveProgress(
                    for: observed,
                    growthDelta: observed.byteCount,
                    previousProgress: nil
                )

                trackedFiles[path] = TrackedFile(
                    url: observed.url,
                    displayName: observed.displayName,
                    directoryName: observed.directoryName,
                    byteCount: observed.byteCount,
                    estimatedTotalByteCount: observed.authoritativeTotalBytes ?? estimatedTotalByteCount(
                        currentByteCount: observed.byteCount,
                        progress: progress
                    ),
                    progress: progress,
                    bytesPerSecond: estimatedInitialBytesPerSecond(
                        initialByteCount: observed.byteCount
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
                    estimatedTotalByteCount: tracked.estimatedTotalByteCount,
                    progress: tracked.progress,
                    startedAt: tracked.firstSeenAt,
                    lastUpdatedAt: tracked.lastGrowthAt ?? tracked.lastSeenAt,
                    isTemporaryFile: tracked.isTemporaryFile,
                    bytesPerSecond: tracked.bytesPerSecond
                )
            }
            .sorted {
                if $0.lastUpdatedAt != $1.lastUpdatedAt {
                    return $0.lastUpdatedAt > $1.lastUpdatedAt
                }

                return $0.byteCount > $1.byteCount
            }

        if activeTransfers.isEmpty {
            stopTimer()
        } else {
            startTimerIfNeeded()
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
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey
                ],
                options: [.skipsPackageDescendants]
            )
        else {
            return []
        }

        let now = Date()
        return urls.compactMap { url in
            let fileName = url.lastPathComponent
            let isTemporaryFile = isTemporaryDownloadFile(named: fileName)

            guard
                let resourceValues = try? url.resourceValues(forKeys: [
                    .isRegularFileKey,
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey
                ])
            else {
                return nil
            }

            let isRegular = resourceValues.isRegularFile == true
            let isDir = resourceValues.isDirectory == true

            // Optimization: Skip non-temporary regular files that have not been modified in the last 10 seconds.
            // This avoids processing thousands of static files and calling standardizedFileURL / getxattr on them.
            if !isTemporaryFile {
                guard isRegular else { return nil }
                if let modificationDate = resourceValues.contentModificationDate {
                    if now.timeIntervalSince(modificationDate) > 10.0 {
                        return nil
                    }
                } else {
                    return nil
                }
            }

            let standardizedURL = url.standardizedFileURL
            let byteCount = isRegular ? Int64(resourceValues.fileSize ?? 0) : recursiveByteCount(in: standardizedURL)

            var authoritativeProgress = downloadProgressAttribute(for: standardizedURL)
            var authoritativeTotalBytes: Int64?
            var resolvedDisplayName = displayName(for: fileName)

            if authoritativeProgress == nil, isTemporaryFile, standardizedURL.pathExtension.lowercased() == "crdownload" {
                if let info = chromiumReader.downloadInfo(for: standardizedURL), info.totalBytes > 0 {
                    authoritativeTotalBytes = info.totalBytes
                    authoritativeProgress = min(max(Double(byteCount) / Double(info.totalBytes), 0), 1)
                    if let targetPath = info.targetPath, !targetPath.isEmpty {
                        resolvedDisplayName = URL(fileURLWithPath: targetPath).lastPathComponent
                    }
                }
            }

            if isRegular {
                return ObservedFile(
                    url: standardizedURL,
                    displayName: resolvedDisplayName,
                    directoryName: directory.lastPathComponent,
                    byteCount: byteCount,
                    isTemporaryFile: isTemporaryFile,
                    authoritativeProgress: authoritativeProgress,
                    authoritativeTotalBytes: authoritativeTotalBytes
                )
            }

            guard isDir, isTemporaryFile else {
                return nil
            }

            return ObservedFile(
                url: standardizedURL,
                displayName: resolvedDisplayName,
                directoryName: directory.lastPathComponent,
                byteCount: byteCount,
                isTemporaryFile: true,
                authoritativeProgress: authoritativeProgress,
                authoritativeTotalBytes: authoritativeTotalBytes
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

    /// Uses the exact progress reported by the downloading app when available,
    /// otherwise falls back to the size-growth heuristic.
    private func resolveProgress(
        for observed: ObservedFile,
        growthDelta: Int64,
        previousProgress: Double?
    ) -> Double {
        if let authoritative = observed.authoritativeProgress {
            return min(max(authoritative, 0), 1)
        }

        return estimatedProgress(
            currentByteCount: observed.byteCount,
            growthDelta: growthDelta,
            previousProgress: previousProgress,
            isTemporaryFile: observed.isTemporaryFile
        )
    }

    /// Derives the total transfer size from the exact reported progress when
    /// available; otherwise preserves the original monotonic heuristic estimate.
    private func totalByteCount(
        for observed: ObservedFile,
        progress: Double,
        previousEstimate: Int64
    ) -> Int64 {
        if let authoritativeTotalBytes = observed.authoritativeTotalBytes, authoritativeTotalBytes > 0 {
            return max(authoritativeTotalBytes, observed.byteCount)
        }

        if observed.authoritativeProgress != nil {
            return estimatedTotalByteCount(
                currentByteCount: observed.byteCount,
                progress: progress
            )
        }

        return max(previousEstimate, observed.byteCount)
    }

    /// Reads the `com.apple.progress.fractionCompleted` extended attribute that
    /// browsers (Safari/WebKit and others) write onto in-flight downloads. The
    /// value is stored as a string whose decimal separator follows the current
    /// locale, so both "." and "," are accepted.
    private func downloadProgressAttribute(for url: URL) -> Double? {
        let attributeName = "com.apple.progress.fractionCompleted"

        return url.withUnsafeFileSystemRepresentation { pathPointer -> Double? in
            guard let pathPointer else { return nil }

            let length = getxattr(pathPointer, attributeName, nil, 0, 0, 0)
            guard length > 0 else { return nil }

            var buffer = [UInt8](repeating: 0, count: length)
            let read = getxattr(pathPointer, attributeName, &buffer, length, 0, 0)
            guard read > 0 else { return nil }

            let rawString = String(decoding: buffer[0..<read], as: UTF8.self)
            let normalized = rawString
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")

            guard let value = Double(normalized), value.isFinite else { return nil }
            return min(max(value, 0), 1)
        }
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

    private func estimatedInitialBytesPerSecond(initialByteCount: Int64) -> Int64 {
        guard initialByteCount > 0 else { return 0 }
        return Int64(Double(initialByteCount) / Metrics.scanInterval)
    }

    private func estimatedTotalByteCount(
        currentByteCount: Int64,
        progress: Double
    ) -> Int64 {
        let clampedProgress = min(max(progress, Metrics.minimumVisibleProgress), 1)
        guard clampedProgress > 0 else { return max(0, currentByteCount) }

        let estimatedTotal = Double(max(0, currentByteCount)) / clampedProgress
        return max(currentByteCount, Int64(estimatedTotal.rounded()))
    }

    private func estimatedBytesPerSecond(
        growthDelta: Int64,
        elapsedInterval: TimeInterval,
        previousBytesPerSecond: Int64,
        lastGrowthAt: Date?,
        now: Date
    ) -> Int64 {
        guard elapsedInterval > 0 else { return previousBytesPerSecond }

        if growthDelta > 0 {
            return Int64(Double(growthDelta) / elapsedInterval)
        }

        guard
            previousBytesPerSecond > 0,
            let lastGrowthAt,
            now.timeIntervalSince(lastGrowthAt) <= Metrics.scanInterval * 1.2
        else {
            return 0
        }

        return previousBytesPerSecond
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

private nonisolated final class DirectoryWatcher {
    private var stream: FSEventStreamRef?
    private let onChange: () -> Void

    init?(urls: [URL], queue: DispatchQueue, onChange: @escaping () -> Void) {
        guard !urls.isEmpty else { return nil }
        self.onChange = onChange

        let paths = urls.map { $0.path } as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, clientCallBackInfo, _, _, _, _ in
            guard let clientCallBackInfo else { return }
            let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
            watcher.onChange()
        }

        let flags = UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3,
            flags
        ) else {
            return nil
        }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit {
        stop()
    }
}

private extension Array where Element == URL {
    nonisolated func removingDuplicatePaths() -> [URL] {
        var seenPaths = Set<String>()

        return filter { url in
            let path = url.standardizedFileURL.path
            return seenPaths.insert(path).inserted
        }
    }
}
