internal import AppKit
import Foundation
import Combine
import AVFoundation

final class ScreenshotMonitorService {
    var onScreenshotCaptured: ((NSImage, NSImage, URL?, String) -> Void)?
    var onScreenRecordingCaptured: ((URL, NSImage, String) -> Void)?
    
    private(set) var userTargetDirectoryURL: URL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
    
    private var originalScreenshotLocation: String?
    private var fileWatcherTimer: Timer?
    private var knownFilePaths = Set<String>()
    private(set) var decodingPaths = Set<String>()
    private var failedDecodePaths = Set<String>()
    private let stagingDirectoryOverride: URL?
    private var isMonitoring = false
    private let fileManager = FileManager.default
    
    init(stagingDirectoryURL: URL? = nil) {
        self.stagingDirectoryOverride = stagingDirectoryURL
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring(disableSystemThumbnail: Bool = true) {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        self.originalScreenshotLocation = Self.getSystemScreenshotLocation()
        self.userTargetDirectoryURL = computeUserTargetDirectoryURL()
        
        let stagingDir = rawStagingDirectoryURL()
        try? fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        
        Self.setSystemScreenshotLocation(stagingDir.path)
        
        if disableSystemThumbnail {
            Self.setSystemFloatingThumbnailEnabled(false)
        }
        
        primeBaseline()
        
        fileWatcherTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.scanForNewScreenshots()
            self?.scanTargetDirectoryForRecordings()
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        fileWatcherTimer?.invalidate()
        fileWatcherTimer = nil
        
        Self.setSystemScreenshotLocation(originalScreenshotLocation)
    }
    
    func rawStagingDirectoryURL() -> URL {
        if let stagingDirectoryOverride {
            return stagingDirectoryOverride
        }
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        return caches.appendingPathComponent("com.Jackson.DynamicNotch/RawScreenshots")
    }
    
    private func computeUserTargetDirectoryURL() -> URL {
        if let customPath = UserDefaults.standard.string(forKey: "settings.screenshot.savePath"), !customPath.isEmpty {
            let expanded = (customPath as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
        let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        guard let original = originalScreenshotLocation, !original.isEmpty else {
            return desktop
        }
        let expanded = (original as NSString).expandingTildeInPath
        if expanded.contains("com.Jackson.DynamicNotch") || expanded.contains("RawScreenshots") {
            return desktop
        }
        return URL(fileURLWithPath: expanded)
    }
    
    private func computeScreenRecordingTargetDirectoryURL() -> URL {
        if let customPath = UserDefaults.standard.string(forKey: "settings.screenRecording.savePath"), !customPath.isEmpty {
            let expanded = (customPath as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
        return computeUserTargetDirectoryURL()
    }
    
    private func uniqueURL(for targetURL: URL) -> URL {
        guard fileManager.fileExists(atPath: targetURL.path) else { return targetURL }
        
        let dir = targetURL.deletingLastPathComponent()
        let ext = targetURL.pathExtension
        let baseName = targetURL.deletingPathExtension().lastPathComponent
        
        var counter = 1
        var candidateURL = targetURL
        while fileManager.fileExists(atPath: candidateURL.path) {
            let newName = ext.isEmpty ? "\(baseName) (\(counter))" : "\(baseName) (\(counter)).\(ext)"
            candidateURL = dir.appendingPathComponent(newName)
            counter += 1
        }
        return candidateURL
    }
    
    private func primeBaseline() {
        let dir = rawStagingDirectoryURL()
        if let urls = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
            for url in urls {
                knownFilePaths.insert(url.path)
            }
        }

        let targetDir = computeScreenRecordingTargetDirectoryURL()
        if let urls = try? fileManager.contentsOfDirectory(at: targetDir, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
            for url in urls {
                knownFilePaths.insert(url.path)
            }
        }
    }
    
    func scanNow() {
        scanForNewScreenshots()
        scanTargetDirectoryForRecordings()
    }

    func scanForNewScreenshots() {
        let dir = rawStagingDirectoryURL()
        guard let urls = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        let now = Date()
        var imageCandidates: [URL] = []
        for url in urls {
            let path = url.path
            guard !knownFilePaths.contains(path), !decodingPaths.contains(path) else { continue }
            
            let filename = url.lastPathComponent
            let lower = filename.lowercased()
            
            if lower.hasSuffix(".mov") || lower.hasSuffix(".mp4") || lower.contains("screen recording") || lower.contains("запись экрана") {
                guard let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                      resourceValues.isRegularFile == true else { continue }
                
                let targetDir = computeScreenRecordingTargetDirectoryURL()
                try? fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
                let destinationURL = uniqueURL(for: targetDir.appendingPathComponent(filename))
                do {
                    try fileManager.moveItem(at: url, to: destinationURL)
                    knownFilePaths.insert(path)
                    knownFilePaths.insert(destinationURL.path)

                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        let thumbnail = Self.generateVideoThumbnail(for: destinationURL) ?? NSWorkspace.shared.icon(forFile: destinationURL.path)
                        DispatchQueue.main.async {
                            self?.onScreenRecordingCaptured?(destinationURL, thumbnail, filename)
                        }
                    }
                } catch {
                    // File might be currently open/being written by screencapture, try again on next timer tick
                }
                continue
            }
            
            guard let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  resourceValues.isRegularFile == true,
                  let modDate = resourceValues.contentModificationDate,
                  now.timeIntervalSince(modDate) < 10.0 else {
                knownFilePaths.insert(path)
                failedDecodePaths.remove(path)
                continue
            }
            
            if lower.contains("screenshot") || lower.contains("скриншот") || lower.hasSuffix(".png") || lower.hasSuffix(".jpg") {
                imageCandidates.append(url)
            }
        }

        // A file that failed to decode is retried only when no other new file is waiting. Thus, it
        // cannot delay the next screenshot while it waits for the age check to retire it.
        guard let url = imageCandidates.first(where: { !failedDecodePaths.contains($0.path) }) ?? imageCandidates.first else {
            return
        }
        startDecoding(url)
    }

    private func startDecoding(_ url: URL) {
        let path = url.path
        let filename = url.lastPathComponent
        decodingPaths.insert(path)
        let previewMaxPixelSize = ScreenshotImageLoader.previewMaxPixelSize
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let loaded = ScreenshotImageLoader.load(contentsOf: url, previewMaxPixelSize: previewMaxPixelSize)
            DispatchQueue.main.async {
                guard let self else { return }
                self.decodingPaths.remove(path)
                guard let loaded else {
                    self.failedDecodePaths.insert(path)
                    return
                }
                self.failedDecodePaths.remove(path)
                self.knownFilePaths.insert(path)
                self.onScreenshotCaptured?(loaded.image, loaded.preview, url, filename)
            }
        }
    }

    private func scanTargetDirectoryForRecordings() {
        let targetDir = computeScreenRecordingTargetDirectoryURL()
        guard targetDir != rawStagingDirectoryURL() else { return }
        guard let urls = try? fileManager.contentsOfDirectory(
            at: targetDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let now = Date()
        for url in urls {
            let path = url.path
            guard !knownFilePaths.contains(path) else { continue }

            let filename = url.lastPathComponent
            let lower = filename.lowercased()
            guard lower.hasSuffix(".mov") || lower.hasSuffix(".mp4") || lower.contains("screen recording") || lower.contains("запись экрана") else {
                continue
            }

            guard let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  resourceValues.isRegularFile == true,
                  let modDate = resourceValues.contentModificationDate,
                  now.timeIntervalSince(modDate) < 15.0 else {
                knownFilePaths.insert(path)
                continue
            }

            // Ensure the file is not currently locked/open for exclusive writing
            guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
                continue
            }
            try? fileHandle.close()

            knownFilePaths.insert(path)

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let thumbnail = Self.generateVideoThumbnail(for: url) ?? NSWorkspace.shared.icon(forFile: url.path)
                DispatchQueue.main.async {
                    self?.onScreenRecordingCaptured?(url, thumbnail, filename)
                }
            }
        }
    }

    static func generateVideoThumbnail(for url: URL) -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 800, height: 800)

        let times = [
            CMTime(seconds: 0.5, preferredTimescale: 600),
            CMTime.zero,
            CMTime(seconds: 0.1, preferredTimescale: 600)
        ]

        for time in times {
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            }
        }

        return nil
    }
    
    func markPathAsKnown(_ path: String) {
        knownFilePaths.insert(path)
    }
    
    /// Configures system preference to hide or show the default floating screenshot thumbnail in the bottom-right corner of macOS.
    static func setSystemFloatingThumbnailEnabled(_ enabled: Bool) {
        let key = "show-thumbnail" as CFString
        let domain = "com.apple.screencapture" as CFString
        CFPreferencesSetValue(key, enabled as CFBoolean, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesAppSynchronize(domain)
    }
    
    static func getSystemScreenshotLocation() -> String? {
        let key = "location" as CFString
        let domain = "com.apple.screencapture" as CFString
        return CFPreferencesCopyAppValue(key, domain) as? String
    }
    
    static func setSystemScreenshotLocation(_ path: String?) {
        let key = "location" as CFString
        let domain = "com.apple.screencapture" as CFString
        if let path = path {
            let expanded = (path as NSString).expandingTildeInPath
            CFPreferencesSetValue(key, expanded as CFString, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        } else {
            CFPreferencesSetValue(key, nil, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        }
        CFPreferencesAppSynchronize(domain)
        
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["SystemUIServer"]
        try? task.run()
    }
}
