internal import AppKit
import SwiftUI
import QuartzCore

struct ScreenshotFlyAnimationView: View {
    let image: NSImage
    
    var body: some View {
        GeometryReader { proxy in
            let targetWidth = max(1, proxy.size.width - 70)
            let targetHeight = max(1, proxy.size.height - 70)
            
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: targetWidth, height: targetHeight)
                .clipped()
                .blur(radius: 20)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.15),
                            .init(color: .black, location: 0.85),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 0.15),
                            .init(color: .black, location: 0.85),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
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
        
        let initialWidth: CGFloat = 450
        let initialHeight: CGFloat = 450
        let rawX = mouseLoc.x - (initialWidth / 2)
        let rawY = mouseLoc.y - (initialHeight / 2)
        
        let initialX = max(screenFrame.minX + 20, min(rawX, screenFrame.maxX - initialWidth - 20))
        let initialY = max(screenFrame.minY + 20, min(rawY, screenFrame.maxY - initialHeight - 20))
        let startFrame = NSRect(x: initialX, y: initialY, width: initialWidth, height: initialHeight)
        
        let middleWidth: CGFloat = 250
        let middleHeight: CGFloat = 450
        let middleX = screenFrame.midX - (middleWidth / 2)
        let middleY = screenFrame.maxY - (middleHeight + 30)
        let middleFrame = NSRect(x: middleX, y: middleY, width: middleWidth, height: middleHeight)
        
        let finalWidth: CGFloat = 250
        let finalHeight: CGFloat = 30
        let finalX = screenFrame.midX - (finalWidth / 2)
        let finalY = screenFrame.maxY + 15
        let finalUpFrame = NSRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
        
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
        
        // Stage 1: Fly towards target point near notch
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(middleFrame, display: true)
        }
        
        // Stage 2: Seamlessly transition upwards into notch before Stage 1 stops (zero pause)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            triggerEarly()
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrame(finalUpFrame, display: true)
                panel.animator().alphaValue = 0.0
            } completionHandler: {
                MainActor.assumeIsolated {
                    panel.orderOut(nil)
                    self.activeWindow = nil
                }
            }
        }
    }
}
