internal import AppKit
import SwiftUI
import QuartzCore

struct ScreenshotFlyAnimationView: View {
    let image: NSImage
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black, radius: 20)
            .padding(20)
            .blur(radius: 20)
    }
}

@MainActor
final class ScreenshotFlyAnimationService {
    static let shared = ScreenshotFlyAnimationService()
    
    private var activeWindow: NSPanel?
    
    private init() {}
    
    func playFlyToNotchAnimation(image: NSImage, onComplete: @escaping () -> Void) {
        guard let mainScreen = NSScreen.main else {
            onComplete()
            return
        }
        
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? mainScreen
        let screenFrame = targetScreen.frame
        
        let initialWidth: CGFloat = 380
        let initialHeight: CGFloat = 240
        let rawX = mouseLoc.x - (initialWidth / 2)
        let rawY = mouseLoc.y - (initialHeight / 2)
        
        let initialX = max(screenFrame.minX + 20, min(rawX, screenFrame.maxX - initialWidth - 20))
        let initialY = max(screenFrame.minY + 20, min(rawY, screenFrame.maxY - initialHeight - 20))
        let startFrame = NSRect(x: initialX, y: initialY, width: initialWidth, height: initialHeight)
        
        let targetWidth: CGFloat = 140
        let targetHeight: CGFloat = 35
        let targetX = screenFrame.midX - (targetWidth / 2)
        let targetY = screenFrame.maxY - (targetHeight - 50)
        let endFrame = NSRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
        
        let panel = OverlayPanelFactory.makePanel(
            frame: startFrame,
            level: .floating,
            isFloatingPanel: true
        )
        panel.ignoresMouseEvents = true
        panel.alphaValue = 1.0
        
        let hostingView = NSHostingView(rootView: ScreenshotFlyAnimationView(image: image))
        panel.contentView = hostingView
        panel.orderFront(nil)
        self.activeWindow = panel
        
        var hasTriggeredComplete = false
        let triggerEarly = {
            guard !hasTriggeredComplete else { return }
            hasTriggeredComplete = true
            onComplete()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            triggerEarly()
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.38
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(endFrame, display: true)
            
        } completionHandler: {
            MainActor.assumeIsolated {
                triggerEarly()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                    panel.orderOut(nil)
                    self.activeWindow = nil
                }
            }
        }
    }
}
