internal import AppKit
import Combine
import ScreenCaptureKit

@MainActor
final class ScreenshotCaptureModel: ObservableObject {
    enum Mode { case display, region }
    @Published private(set) var isCapturing = false
    @Published private(set) var didCopy = false

    private let selector = ScreenshotRegionSelector()
    private var task: Task<Void, Never>?
    private var hiddenWindows: [NSWindow] = []
    private var previousApplication: NSRunningApplication?
    private var applicationObserver: NSObjectProtocol?

    init() {
        rememberExternalApplication(NSWorkspace.shared.frontmostApplication)
        applicationObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated {
                self?.rememberExternalApplication(note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            }
        }
    }

    deinit {
        if let applicationObserver { NSWorkspace.shared.notificationCenter.removeObserver(applicationObserver) }
    }

    func capture(_ mode: Mode, screen: NSScreen?, collapse: @escaping () -> Void) {
        guard !isCapturing else { return }
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            showFailure(L10n.app("homeTools.capture.permission"), permission: true)
            return
        }
        rememberExternalApplication(NSWorkspace.shared.frontmostApplication)
        isCapturing = true
        didCopy = false
        let fullTarget = screen.flatMap { ScreenshotCaptureTarget(screen: $0) }
        task = Task { [weak self] in
            guard let self else { return }
            do {
                didCopy = try await ScreenshotCaptureFlow.run(
                    hide: {
                        collapse()
                        self.hiddenWindows = NSApp.windows.filter(\.isVisible)
                        self.hiddenWindows.forEach { $0.orderOut(nil) }
                    },
                    restore: {
                        self.isCapturing = false
                        self.hiddenWindows.forEach { $0.orderFrontRegardless() }
                        self.hiddenWindows = []
                        if let previous = self.previousApplication, !previous.isTerminated {
                            previous.activate(from: .current, options: [])
                        }
                    },
                    select: {
                        switch mode {
                        case .display:
                            guard let fullTarget else { throw CaptureError.displayUnavailable }
                            return fullTarget
                        case .region: return await self.selector.select()
                        }
                    },
                    capture: { target in
                        (image: try await Self.image(for: target), logicalSize: (target.selection ?? target.frame).size)
                    },
                    copy: { captured in try Self.copyToClipboard(captured.image, logicalSize: captured.logicalSize) }
                )
            } catch {
                showFailure((error as? CaptureError)?.message ?? error.localizedDescription)
            }
            task = nil
        }
    }

    private func rememberExternalApplication(_ application: NSRunningApplication?) {
        if let application, application.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previousApplication = application
        }
    }

    private static func image(for target: ScreenshotCaptureTarget) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == target.displayID }) else { throw CaptureError.displayUnavailable }
        // Filtering the entire app also protects against a window-server frame
        // arriving before an orderOut/collapse animation has finished.
        let ownApplications = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
        let filter = SCContentFilter(display: display, excludingApplications: ownApplications, exceptingWindows: [])
        let geometry = ScreenshotCaptureGeometry(screenFrame: target.frame, scale: target.scale, selection: target.selection)
        guard !geometry.sourceRect.isEmpty else { throw CaptureError.invalidSelection }
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = geometry.sourceRect
        configuration.width = geometry.pixelWidth
        configuration.height = geometry.pixelHeight
        configuration.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }

    static func copyToClipboard(_ image: CGImage, logicalSize: CGSize? = nil, pasteboard: NSPasteboard? = nil) throws {
        let bitmap = NSBitmapImageRep(cgImage: image)
        if let logicalSize { bitmap.size = logicalSize }
        guard let png = bitmap.representation(using: .png, properties: [:]), let tiff = bitmap.tiffRepresentation else { throw CaptureError.encodingFailed }
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        item.setData(tiff, forType: .tiff)
        let pasteboard = pasteboard ?? .general
        pasteboard.clearContents()
        guard pasteboard.writeObjects([item]) else { throw CaptureError.clipboardUnavailable }
    }

    private func showFailure(_ message: String, permission: Bool = false) {
        let alert = NSAlert()
        alert.messageText = L10n.app("homeTools.capture.failed")
        alert.informativeText = message
        alert.addButton(withTitle: L10n.app(permission ? "homeTools.capture.openSettings" : "OK"))
        if permission { alert.addButton(withTitle: L10n.app("common.cancel")) }
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn, permission,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    private enum CaptureError: Error {
        case displayUnavailable, invalidSelection, encodingFailed, clipboardUnavailable
        @MainActor var message: String {
            switch self {
            case .displayUnavailable: return L10n.app("homeTools.capture.displayUnavailable")
            case .invalidSelection: return L10n.app("homeTools.capture.invalidSelection")
            case .encodingFailed: return L10n.app("homeTools.capture.encodingFailed")
            case .clipboardUnavailable: return L10n.app("homeTools.capture.clipboardUnavailable")
            }
        }
    }
}
