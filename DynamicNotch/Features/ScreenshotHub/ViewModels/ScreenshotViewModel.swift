internal import AppKit
import Combine
import QuickLookUI

private struct ActiveScreenshotDrag {
    let screenshotID: UUID
    let fileURL: URL?
}

final class ScreenshotPasteboardWriter: NSObject, NSPasteboardWriting {
    private let fileURL: URL?
    private let pngData: Data?
    private let tiffData: Data?

    init(fileURL: URL?, image: NSImage) {
        self.fileURL = fileURL?.standardizedFileURL
        self.tiffData = image.tiffRepresentation

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData) {
            self.pngData = bitmap.representation(using: .png, properties: [:])
        } else {
            self.pngData = nil
        }
    }

    var isUsable: Bool {
        fileURL != nil || pngData != nil || tiffData != nil
    }

    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types: [NSPasteboard.PasteboardType] = []

        if fileURL != nil {
            types.append(contentsOf: [.fileURL, .URL])
        }
        if pngData != nil {
            types.append(.png)
        }
        if tiffData != nil {
            types.append(.tiff)
        }

        return types
    }

    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .fileURL, .URL:
            return fileURL?.absoluteString
        case .png:
            return pngData
        case .tiff:
            return tiffData
        default:
            return nil
        }
    }
}

@MainActor
final class ScreenshotViewModel: ObservableObject {
    @Published var activeScreenshot: ScreenshotModel?
    
    var onScreenshotReady: ((ScreenshotModel) -> Void)?
    var onScreenshotDismissed: (() -> Void)?
    var onScreenshotDragStateChanged: ((Bool) -> Void)?
    
    private(set) var isDropped = false
    private(set) var isDeleted = false
    private(set) var isSavedToDisk = false
    private(set) var isCopied = false
    private(set) var isDragging = false
    
    private var lastProcessedDate: Date?
    private var activeDrag: ActiveScreenshotDrag?
    private var pendingSaveScreenshotID: UUID?
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

    func suppressClipboardCapture() {
        monitorService.suppressMonitoring(for: 1.5)
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
    
    func beginDragging(screenshot: ScreenshotModel) -> NSPasteboardWriting? {
        guard activeScreenshot?.id == screenshot.id,
              activeDrag == nil else {
            return nil
        }

        let dragFileURL = makeStableDragFile(for: screenshot)
        let writer = ScreenshotPasteboardWriter(fileURL: dragFileURL, image: screenshot.image)
        guard writer.isUsable else { return nil }

        activeDrag = ActiveScreenshotDrag(
            screenshotID: screenshot.id,
            fileURL: dragFileURL
        )
        pendingSaveScreenshotID = nil
        isDragging = true
        onScreenshotDragStateChanged?(true)
        return writer
    }

    func finishDragging(screenshotID: UUID, didDrop: Bool) {
        guard let activeDrag,
              activeDrag.screenshotID == screenshotID else {
            return
        }

        let shouldSaveAfterCancelledDrag = pendingSaveScreenshotID == screenshotID
        self.activeDrag = nil
        pendingSaveScreenshotID = nil
        isDragging = false
        onScreenshotDragStateChanged?(false)
        scheduleDragFileCleanup(activeDrag.fileURL)

        guard activeScreenshot?.id == screenshotID else { return }

        if didDrop {
            isDropped = true
            dismiss()
        } else if shouldSaveAfterCancelledDrag {
            saveToDiskIfNeeded()
        }
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
        centerPreviewWindowOnScreen()
        dismiss()
    }
    
    private func centerPreviewWindowOnScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let script = """
            tell application "System Events"
                repeat with appName in {"Preview", "Просмотр", "QuickLook"}
                    if exists (process appName) then
                        tell process appName
                            if (count of windows) > 0 then
                                set win to window 1
                                set {w, h} to size of win
                                tell application "Finder"
                                    set screenBounds to bounds of window of desktop
                                    set screenW to item 3 of screenBounds
                                    set screenH to item 4 of screenBounds
                                end tell
                                set newX to (screenW - w) / 2
                                set newY to (screenH - h) / 2
                                set position of win to {newX, newY}
                                exit repeat
                            end if
                        end tell
                    end if
                end repeat
            end tell
            """
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
        
        if let panel = QLPreviewPanel.shared(), QLPreviewPanel.sharedPreviewPanelExists() {
            panel.center()
        }
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
        if let screenshotID = activeScreenshot?.id,
           activeDrag?.screenshotID == screenshotID {
            pendingSaveScreenshotID = screenshotID
            return
        }

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

    private func makeStableDragFile(for screenshot: ScreenshotModel) -> URL? {
        let dragDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("com.Jackson.DynamicNotch", isDirectory: true)
            .appendingPathComponent("ScreenshotDrag", isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: dragDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            return nil
        }

        let rawBaseName = URL(fileURLWithPath: screenshot.fileName)
            .deletingPathExtension()
            .lastPathComponent
        let sanitizedBaseName = rawBaseName
            .components(separatedBy: CharacterSet(charactersIn: "/:"))
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = sanitizedBaseName.isEmpty ? "Screenshot" : sanitizedBaseName
        let targetURL = uniqueURL(
            for: dragDirectory.appendingPathComponent("\(baseName).png")
        )

        writePNG(image: screenshot.image, to: targetURL)
        return fileManager.fileExists(atPath: targetURL.path) ? targetURL : nil
    }

    private func scheduleDragFileCleanup(_ url: URL?) {
        guard let url else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            try? self?.fileManager.removeItem(at: url)
        }
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
