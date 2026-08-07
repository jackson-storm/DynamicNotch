internal import AppKit
import Combine

@MainActor
final class ScreenshotViewModel: ObservableObject {
    @Published var activeScreenshot: ScreenshotModel?
    
    var onScreenshotReady: ((ScreenshotModel) -> Void)?
    var onScreenshotDismissed: (() -> Void)?
    
    private(set) var isDropped = false
    private(set) var isDeleted = false
    private(set) var isSavedToDisk = false
    private(set) var isCopied = false
    
    private var lastProcessedDate: Date?
    private let monitorService: ScreenshotMonitorService
    private let ocrService: OCRService
    private let fileManager = FileManager.default
    
    init(monitorService: ScreenshotMonitorService? = nil,
         ocrService: OCRService? = nil) {
        self.monitorService = monitorService ?? ScreenshotMonitorService()
        self.ocrService = ocrService ?? .shared
        
        setupMonitoring()
    }
    
    func startMonitoring(disableSystemThumbnail: Bool = true) {
        monitorService.startMonitoring(disableSystemThumbnail: disableSystemThumbnail)
    }
    
    func stopMonitoring() {
        monitorService.stopMonitoring()
    }
    
    func processNewScreenshot(image: NSImage, fileURL: URL?, fileName: String) {
        let now = Date()
        if let last = lastProcessedDate, now.timeIntervalSince(last) < 0.8 {
            return
        }
        lastProcessedDate = now
        
        isDropped = false
        isDeleted = false
        isSavedToDisk = false
        isCopied = false
        
        let stagingDir = monitorService.rawStagingDirectoryURL()
        try? fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        
        let tempURL: URL
        if let originalURL = fileURL {
            tempURL = originalURL
        } else {
            let generatedTempURL = stagingDir.appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
            writePNG(image: image, to: generatedTempURL)
            tempURL = generatedTempURL
        }
        
        let targetDir = monitorService.userTargetDirectoryURL
        let name = fileName.hasSuffix(".png") ? fileName : "\(fileName).png"
        let targetURL = targetDir.appendingPathComponent(name)
        
        let model = ScreenshotModel(
            image: image,
            fileURL: tempURL,
            tempFileURL: tempURL,
            targetDestinationURL: targetURL,
            fileName: fileName,
            recognizedText: "",
            isRecognizing: true,
            timestamp: Date()
        )
        
        self.activeScreenshot = model
        self.onScreenshotReady?(model)
        
        ocrService.recognizeText(in: image) { [weak self] extractedText in
            Task { @MainActor in
                guard var current = self?.activeScreenshot, current.id == model.id else { return }
                current.recognizedText = extractedText
                current.isRecognizing = false
                self?.activeScreenshot = current
            }
        }
    }
    
    func markAsDropped() {
        isDropped = true
    }
    
    func copyImageToClipboard() {
        guard let image = activeScreenshot?.image else { return }
        isCopied = true
        monitorService.suppressMonitoring(for: 3.0)
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let tiffData = image.tiffRepresentation {
            pasteboard.setData(tiffData, forType: .tiff)
        }
        monitorService.updateLastPasteboardChangeCount()
        dismiss()
    }
    
    func showInFinder() {
        saveToDiskIfNeeded()
        guard let targetURL = activeScreenshot?.targetDestinationURL,
              fileManager.fileExists(atPath: targetURL.path) else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
        if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            finderApp.activate()
        }
        dismiss()
    }
    
    func openEditingWindow() {
        saveToDiskIfNeeded()
        guard let targetURL = activeScreenshot?.targetDestinationURL,
              fileManager.fileExists(atPath: targetURL.path) else { return }
        
        NSWorkspace.shared.open(targetURL)
        dismiss()
    }
    
    func makeItemProvider(for screenshot: ScreenshotModel) -> NSItemProvider {
        if let url = getFileURL(for: screenshot) {
            let provider = NSItemProvider(object: url as NSURL)
            provider.registerObject(screenshot.image, visibility: .all)
            return provider
        } else {
            return NSItemProvider(object: screenshot.image)
        }
    }
    
    func makePasteboardWriter(for screenshot: ScreenshotModel) -> NSPasteboardWriting {
        if let url = getFileURL(for: screenshot) {
            return url as NSURL
        } else {
            return screenshot.image
        }
    }
    
    private func getFileURL(for screenshot: ScreenshotModel) -> URL? {
        if let tempURL = screenshot.tempFileURL, fileManager.fileExists(atPath: tempURL.path) {
            return tempURL
        }
        if let fileURL = screenshot.fileURL, fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        let tempDir = fileManager.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
        writePNG(image: screenshot.image, to: tempURL)
        return tempURL
    }
    
    func deleteScreenshot() {
        isDeleted = true
        if let tempURL = activeScreenshot?.tempFileURL {
            try? fileManager.removeItem(at: tempURL)
        }
        if let targetURL = activeScreenshot?.targetDestinationURL, fileManager.fileExists(atPath: targetURL.path) {
            try? fileManager.removeItem(at: targetURL)
        }
        dismiss()
    }
    
    func dismiss() {
        monitorService.suppressMonitoring(for: 3.0)
        onScreenshotDismissed?()
        
        saveToDiskIfNeeded()
        
        if isDropped || isDeleted || isCopied {
            if let tempURL = activeScreenshot?.tempFileURL {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    try? self?.fileManager.removeItem(at: tempURL)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.activeScreenshot = nil
        }
    }
    
    func saveToDiskIfNeeded() {
        guard !isSavedToDisk, !isDeleted, !isDropped, !isCopied else { return }
        guard let screenshot = activeScreenshot else { return }
        
        let targetDir = monitorService.userTargetDirectoryURL
        let targetURL = screenshot.targetDestinationURL ?? targetDir.appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
        
        let finalTargetURL = uniqueURL(for: targetURL)
        monitorService.markPathAsKnown(finalTargetURL.path)
        monitorService.suppressMonitoring(for: 3.0)
        
        isSavedToDisk = true
        if var current = activeScreenshot {
            current.targetDestinationURL = finalTargetURL
            self.activeScreenshot = current
        }
        
        if let tempURL = screenshot.tempFileURL, fileManager.fileExists(atPath: tempURL.path) {
            do {
                try fileManager.moveItem(at: tempURL, to: finalTargetURL)
                return
            } catch {
                writePNG(image: screenshot.image, to: finalTargetURL)
                try? fileManager.removeItem(at: tempURL)
                return
            }
        }
        
        writePNG(image: screenshot.image, to: finalTargetURL)
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
    
    private func writePNG(image: NSImage, to url: URL) {
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: url)
        }
    }
    
    private func defaultScreenshotDirectory() -> URL {
        if let customLocation = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let expanded = (customLocation as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }
        return fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
    }
    
    private func setupMonitoring() {
        monitorService.onScreenshotCaptured = { [weak self] image, fileURL, fileName in
            self?.processNewScreenshot(image: image, fileURL: fileURL, fileName: fileName)
        }
    }
}
