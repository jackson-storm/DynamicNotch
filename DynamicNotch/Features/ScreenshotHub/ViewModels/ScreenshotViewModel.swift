internal import AppKit
import Combine

@MainActor
final class ScreenshotViewModel: ObservableObject {
    @Published var activeScreenshot: ScreenshotModel?
    
    var onScreenshotReady: ((ScreenshotModel) -> Void)?
    var onScreenshotDismissed: (() -> Void)?
    
    private let monitorService: ScreenshotMonitorService
    private let ocrService: OCRService
    
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
        let model = ScreenshotModel(
            image: image,
            fileURL: fileURL,
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
    
    func copyImageToClipboard() {
        guard let image = activeScreenshot?.image else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let tiffData = image.tiffRepresentation {
            pasteboard.setData(tiffData, forType: .tiff)
        }
        monitorService.updateLastPasteboardChangeCount()
        dismiss()
    }
    
    func showInFinder() {
        guard let url = activeScreenshot?.fileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        dismiss()
    }
    
    func openEditingWindow() {
        guard let screenshot = activeScreenshot,
              let targetURL = getFileURL(for: screenshot) else { return }
        
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
        if let fileURL = screenshot.fileURL {
            return fileURL
        }
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
        if let tiff = screenshot.image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: tempURL)
            return tempURL
        }
        return nil
    }
    
    func deleteScreenshot() {
        if let fileURL = activeScreenshot?.fileURL {
            try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
        }
        dismiss()
    }
    
    func dismiss() {
        monitorService.suppressMonitoring(for: 3.0)
        onScreenshotDismissed?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.activeScreenshot = nil
        }
    }
    
    private func setupMonitoring() {
        monitorService.onScreenshotCaptured = { [weak self] image, fileURL, fileName in
            self?.processNewScreenshot(image: image, fileURL: fileURL, fileName: fileName)
        }
    }
}
