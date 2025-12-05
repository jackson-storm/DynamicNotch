import AppKit
import Combine

final class WindowModel: ObservableObject {
    static let shared = WindowModel()

    @Published var windowFrame: CGRect = .zero
    @Published var borderColor: NSColor = .white

    private var window: NSWindow?
    private var moveResizeToken: Any?

    private init() {}

    func attach(window: NSWindow) {
        self.window = window
        updateFrame()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowMovedOrResized),
            name: NSWindow.didMoveNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowMovedOrResized),
            name: NSWindow.didEndLiveResizeNotification,
            object: window
        )
    }

    @objc private func windowMovedOrResized() {
        updateFrame()
    }

    private func updateFrame() {
        guard let w = window else { return }
        DispatchQueue.main.async {
            self.windowFrame = w.frame
        }
    }
}
