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
    
    func copyTextToClipboard() {
        guard let text = activeScreenshot?.recognizedText, !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func copyImageToClipboard() {
        guard let image = activeScreenshot?.image else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let tiffData = image.tiffRepresentation {
            pasteboard.setData(tiffData, forType: .tiff)
        }
    }
    
    func showInFinder() {
        guard let url = activeScreenshot?.fileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        dismiss()
    }
    
    func openEditingWindow() {
        guard let screenshot = activeScreenshot else { return }
        
        let targetURL: URL
        if let fileURL = screenshot.fileURL {
            targetURL = fileURL
        } else {
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent("Screenshot_\(Int(Date().timeIntervalSince1970)).png")
            if let tiff = screenshot.image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: tempURL)
                targetURL = tempURL
            } else {
                return
            }
        }
        
        NSWorkspace.shared.open(targetURL)
        dismiss()
    }
    
    func deleteScreenshot() {
        if let fileURL = activeScreenshot?.fileURL {
            try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
        }
        dismiss()
    }
    
    func dismiss() {
        activeScreenshot = nil
        onScreenshotDismissed?()
    }
    
    private func setupMonitoring() {
        monitorService.onScreenshotCaptured = { [weak self] image, fileURL, fileName in
            self?.processNewScreenshot(image: image, fileURL: fileURL, fileName: fileName)
        }
    }
}
