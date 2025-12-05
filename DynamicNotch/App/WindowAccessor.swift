import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let w = v.window {
                callback(w)
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
