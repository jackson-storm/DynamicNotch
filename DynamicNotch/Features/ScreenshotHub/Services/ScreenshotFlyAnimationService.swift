//
//  ScreenshotFlyAnimationService.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/22/26.
//

import SwiftUI

@MainActor
final class ScreenshotFlyAnimationService {
    static let shared = ScreenshotFlyAnimationService()
    
    private var activeWindow: NSPanel?
    private var completionHandler: (() -> Void)?
    private var fallbackTask: Task<Void, Never>?
    
    private init() {}
    
    func playFlyToNotchAnimation(
        image: NSImage,
        onReachNotch: (@MainActor () -> Void)? = nil,
        onComplete: @escaping () -> Void
    ) {
        guard let mainScreen = NSScreen.main else {
            onComplete()
            return
        }
        
        fallbackTask?.cancel()
        fallbackTask = nil
        activeWindow?.orderOut(nil)
        activeWindow = nil
        completionHandler = onComplete
        
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? mainScreen
        let screenFrame = targetScreen.frame
        
        let isNotchless = targetScreen.isNotchless
        let notchY: CGFloat = isNotchless ? 4.0 : -12.0
        let notchPoint = CGPoint(x: screenFrame.width / 2.0, y: notchY)
        
        let rawStartX = mouseLoc.x - screenFrame.minX
        let rawStartY = screenFrame.maxY - mouseLoc.y
        let startX = max(70.0, min(screenFrame.width - 70.0, rawStartX))
        let startY = max(notchPoint.y + 90.0, min(screenFrame.height - 70.0, rawStartY))
        let startPoint = CGPoint(x: startX, y: startY)
        
        let imageSize = image.size
        let flightBounds = ScreenshotFlyAnimationView.flightBounds(
            start: startPoint,
            notch: notchPoint,
            screenSize: screenFrame.size,
            imageAspect: imageSize.height > 0 ? imageSize.width / imageSize.height : 1.0
        )
        let panelFrame = NSRect(
            x: screenFrame.minX + flightBounds.minX,
            y: screenFrame.maxY - flightBounds.maxY,
            width: flightBounds.width,
            height: flightBounds.height
        )
        
        let panel = OverlayPanelFactory.makePanel(
            frame: panelFrame,
            level: .floating,
            isFloatingPanel: true
        )
        panel.ignoresMouseEvents = true
        panel.alphaValue = 1.0
        
        let flyView = ScreenshotFlyAnimationView(
            image: image,
            startPoint: CGPoint(x: startPoint.x - flightBounds.minX, y: startPoint.y - flightBounds.minY),
            notchPoint: CGPoint(x: notchPoint.x - flightBounds.minX, y: notchPoint.y - flightBounds.minY),
            screenSize: screenFrame.size,
            isNotchless: isNotchless,
            onReachNotch: onReachNotch,
            onEarlyComplete: { [weak self] in
                self?.triggerEarlyCompletion()
            },
            onFinished: { [weak self, weak panel] in
                self?.cleanupPanel(panel)
            }
        )
        
        panel.contentView = NSHostingView(rootView: flyView)
        panel.orderFront(nil)
        
        self.activeWindow = panel
        self.fallbackTask = Task { @MainActor [weak self, weak panel] in
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            self?.cleanupPanel(panel)
        }
    }
    
    private func triggerEarlyCompletion() {
        guard let completion = completionHandler else { return }
        completionHandler = nil
        completion()
    }
    
    private func cleanupPanel(_ panel: NSPanel?) {
        triggerEarlyCompletion()
        panel?.orderOut(nil)
        if activeWindow === panel {
            activeWindow = nil
        }
        fallbackTask?.cancel()
        fallbackTask = nil
    }
}
