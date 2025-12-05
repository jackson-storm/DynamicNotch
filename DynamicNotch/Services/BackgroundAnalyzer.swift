import Foundation
import ScreenCaptureKit
import AppKit
import SwiftUI
import Combine

class BackgroundAnalyzer: NSObject, ObservableObject, SCStreamDelegate {
    @Published var strokeColor: Color = Color.white.opacity(0.25)

    private var stream: SCStream?
    private var contentFilter: SCContentFilter?
    private var windowID: CGWindowID?

    func setWindow(_ window: NSWindow) {
        self.windowID = CGWindowID(window.windowNumber)
        Task { await startCapture() }
    }

    @MainActor
    private func updateStroke(for brightness: CGFloat) {
        if brightness < 0.4 {
            strokeColor = Color.white.opacity(0.25)
        } else {
            strokeColor = Color.black.opacity(0.25)
        }
    }

    func startCapture() async {
        let disp = CGMainDisplayID()

        let source = try? await SCShareableContent.current
        guard let display = source?.displays.first(where: { $0.displayID == disp }) else { return }

        contentFilter = SCContentFilter(display: display, excludingWindows: [])

        let config = SCStreamConfiguration()
        config.queueDepth = 1
        config.width = 200
        config.height = 80
        config.scalesToFit = true

        stream = SCStream(filter: contentFilter!, configuration: config, delegate: self)
        try? await stream?.startCapture()
    }
}

extension BackgroundAnalyzer: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {

        guard type == .screen else { return }
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

        _ = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let base = CVPixelBufferGetBaseAddress(imageBuffer)!.assumingMemoryBound(to: UInt8.self)
        let bytes = CVPixelBufferGetBytesPerRow(imageBuffer)

        var totalBrightness: CGFloat = 0
        var count = 0
        
        for y in stride(from: 0, to: height, by: 10) {
            let pixel = base + y * bytes
            let r = CGFloat(pixel[0]) / 255
            let g = CGFloat(pixel[1]) / 255
            let b = CGFloat(pixel[2]) / 255
            let brightness = (r + g + b) / 3
            totalBrightness += brightness
            count += 1
        }

        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)

        let avg = totalBrightness / CGFloat(count)

        DispatchQueue.main.async {
            self.updateStroke(for: avg)
        }
    }
}

