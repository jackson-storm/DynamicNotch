internal import AppKit
import Foundation
import Combine

final class ScreenshotMonitorService {
    var onScreenshotCaptured: ((NSImage, URL?, String) -> Void)?
    
    private(set) var userTargetDirectoryURL: URL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
    
    private var originalScreenshotLocation: String?
    private var fileWatcherTimer: Timer?
    private var pasteboardTimer: Timer?
    private var lastPasteboardChangeCount: Int = 0
    private var knownFilePaths = Set<String>()
    private var isMonitoring = false
    private var suppressMonitoringUntil: Date?
    private let fileManager = FileManager.default
    
    init() {
        lastPasteboardChangeCount = NSPasteboard.general.changeCount
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
        }
        
        pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        fileWatcherTimer?.invalidate()
        fileWatcherTimer = nil
        pasteboardTimer?.invalidate()
        pasteboardTimer = nil
        
        Self.setSystemScreenshotLocation(originalScreenshotLocation)
    }
    
    func updateLastPasteboardChangeCount() {
        lastPasteboardChangeCount = NSPasteboard.general.changeCount
    }
    
    func suppressMonitoring(for duration: TimeInterval = 3.0) {
        suppressMonitoringUntil = Date().addingTimeInterval(duration)
        updateLastPasteboardChangeCount()
    }
    
    func rawStagingDirectoryURL() -> URL {
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
                let lower = url.lastPathComponent.lowercased()
                if !lower.hasSuffix(".mov") && !lower.hasSuffix(".mp4") {
                    knownFilePaths.insert(url.path)
                }
            }
        }
    }
    
    private func scanForNewScreenshots() {
        let dir = rawStagingDirectoryURL()
        guard let urls = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        let now = Date()
        for url in urls {
            let path = url.path
            guard !knownFilePaths.contains(path) else { continue }
            
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
                continue
            }
            
            if lower.contains("screenshot") || lower.contains("скриншот") || lower.hasSuffix(".png") || lower.hasSuffix(".jpg") {
                if let image = NSImage(contentsOf: url) {
                    knownFilePaths.insert(path)
                    updateLastPasteboardChangeCount()
                    suppressMonitoring(for: 1.5)
                    DispatchQueue.main.async { [weak self] in
                        self?.onScreenshotCaptured?(image, url, filename)
                    }
                    break
                }
            }
        }
    }
    
    private func checkPasteboard() {
        if let suppressUntil = suppressMonitoringUntil, Date() < suppressUntil {
            updateLastPasteboardChangeCount()
            return
        }
        
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastPasteboardChangeCount else { return }
        lastPasteboardChangeCount = currentCount
        
        let pb = NSPasteboard.general
        if let types = pb.types, types.contains(.tiff) || types.contains(.png) {
            if let data = pb.data(forType: .tiff) ?? pb.data(forType: .png),
               let image = NSImage(data: data) {
                DispatchQueue.main.async { [weak self] in
                    self?.onScreenshotCaptured?(image, nil, "Clipboard Screenshot")
                }
            }
        }
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
