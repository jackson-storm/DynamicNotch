internal import AppKit
import Combine

@MainActor
final class ScreenRecordingResultViewModel: ObservableObject {
    @Published var activeResult: ScreenRecordingResultModel?

    var onResultReady: ((ScreenRecordingResultModel) -> Void)?
    var onResultDismissed: (() -> Void)?

    private(set) var isDropped = false
    private(set) var isDeleted = false
    private let fileManager = FileManager.default

    func setRecordingResult(fileURL: URL, thumbnail: NSImage, fileName: String) {
        isDropped = false
        isDeleted = false

        let model = ScreenRecordingResultModel(
            fileURL: fileURL,
            thumbnail: thumbnail,
            fileName: fileName,
            timestamp: Date()
        )

        self.activeResult = model
        self.onResultReady?(model)
    }

    func markAsDropped() {
        isDropped = true
    }

    func openVideo() {
        guard let fileURL = activeResult?.fileURL,
              fileManager.fileExists(atPath: fileURL.path) else { return }

        NSWorkspace.shared.open(fileURL)
        dismiss()
    }

    func showInFinder() {
        guard let fileURL = activeResult?.fileURL,
              fileManager.fileExists(atPath: fileURL.path) else { return }

        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            finderApp.activate()
        }
        dismiss()
    }

    func copyToClipboard() {
        guard let fileURL = activeResult?.fileURL else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fileURL as NSURL])
        dismiss()
    }

    func deleteVideo() {
        isDeleted = true
        if let fileURL = activeResult?.fileURL, fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.trashItem(at: fileURL, resultingItemURL: nil)
        }
        dismiss()
    }

    func dismiss() {
        onResultDismissed?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.activeResult = nil
        }
    }

    func makeItemProvider(for result: ScreenRecordingResultModel) -> NSItemProvider {
        let provider = NSItemProvider(object: result.fileURL as NSURL)
        provider.registerObject(result.thumbnail, visibility: .all)
        return provider
    }
}
