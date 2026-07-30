internal import AppKit
import SwiftUI
import QuartzCore

struct ScreenshotFlyAnimationView: View {
    let image: NSImage
    
    @State private var isFlying = false
    
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .cornerRadius(20)
            .scaleEffect(
                x: isFlying ? 0.5 : 1.0,
                y: isFlying ? 0.5 : 1.0,
                anchor: .top
            )
            .blur(radius: isFlying ? 8 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(isFlying ? 0.4 : 0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: isFlying ? 16 : 8, x: 0, y: 6)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isFlying = true
                }
            }
    }
}

@MainActor
final class ScreenshotFlyAnimationService {
    static let shared = ScreenshotFlyAnimationService()
    
    private var activeWindow: NSPanel?
    
    private init() {}
    
    func playFlyToNotchAnimation(
        image: NSImage,
        onComplete: @escaping () -> Void
    ) {
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
        let targetY = screenFrame.maxY - targetHeight - 5
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
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(endFrame, display: true)
            panel.animator().alphaValue = 0.0
            
        } completionHandler: {
            MainActor.assumeIsolated {
                panel.orderOut(nil)
                self.activeWindow = nil
                onComplete()
            }
        }
    }
}
