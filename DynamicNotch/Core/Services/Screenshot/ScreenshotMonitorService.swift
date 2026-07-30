internal import AppKit
import Foundation
import Combine

final class ScreenshotMonitorService {
    var onScreenshotCaptured: ((NSImage, URL?, String) -> Void)?
    
    private var fileWatcherTimer: Timer?
    private var pasteboardTimer: Timer?
    private var lastPasteboardChangeCount: Int = 0
    private var knownFilePaths = Set<String>()
    private var isMonitoring = false
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
        
        if disableSystemThumbnail {
            Self.setSystemFloatingThumbnailEnabled(false)
        }
        
        primeBaseline()
        
        // Timer for polling filesystem for new screenshot files
        fileWatcherTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.scanForNewScreenshots()
        }
        
        // Timer for pasteboard screenshot detection
        pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
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
    }
    
    private func screenshotDirectoryURL() -> URL {
        if let customLocation = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let expanded = (customLocation as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
        return fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
    }
    
    private func primeBaseline() {
        let dir = screenshotDirectoryURL()
        if let urls = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) {
            knownFilePaths = Set(urls.map { $0.path })
        }
    }
    
    private func scanForNewScreenshots() {
        let dir = screenshotDirectoryURL()
        guard let urls = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        let now = Date()
        for url in urls {
            let path = url.path
            guard !knownFilePaths.contains(path) else { continue }
            knownFilePaths.insert(path)
            
            // Check if it's a recent image file created within last 5 seconds
            guard let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  resourceValues.isRegularFile == true,
                  let modDate = resourceValues.contentModificationDate,
                  now.timeIntervalSince(modDate) < 5.0 else {
                continue
            }
            
            let filename = url.lastPathComponent
            let lower = filename.lowercased()
            // Standard macOS screenshot naming or image file
            if lower.contains("screenshot") || lower.contains("скриншот") || lower.hasSuffix(".png") || lower.hasSuffix(".jpg") {
                if let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async { [weak self] in
                        self?.onScreenshotCaptured?(image, url, filename)
                    }
                    break
                }
            }
        }
    }
    
    private func checkPasteboard() {
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
    
    /// Configures system preference to hide or show the default floating screenshot thumbnail in the bottom-right corner of macOS.
    static func setSystemFloatingThumbnailEnabled(_ enabled: Bool) {
        let key = "show-thumbnail" as CFString
        let domain = "com.apple.screencapture" as CFString
        CFPreferencesSetValue(key, enabled as CFBoolean, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesAppSynchronize(domain)
    }
}
