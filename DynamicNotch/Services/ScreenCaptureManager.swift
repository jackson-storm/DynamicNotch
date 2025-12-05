import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreImage
import AppKit
import Combine

@MainActor
final class ScreenCaptureManager: NSObject, ObservableObject, SCStreamDelegate {
    @Published var lastFrame: CGImage?

    private var stream: SCStream?
    private var output: SCStreamOutput?
    private var ciContext = CIContext()

    private var displayToCapture: SCDisplay?

    private var lastEmit = Date.distantPast
    private let minInterval: TimeInterval = 0.08

    func requestPermissionAndStart() async throws {
        if !ScreenCaptureManager.hasScreenRecordingPermission() {
            try await openScreenRecordingPrivacyPane()
        }

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            print("No displays available")
            return
        }
        displayToCapture = display

        let config = SCStreamConfiguration()
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)

        let filter = SCContentFilter(display: display, excludingWindows: [])

        stream = SCStream(filter: filter, configuration: config, delegate: self)
        output = self
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
        try await stream?.startCapture()
    }

    func stop() {
        stream?.stopCapture()
        stream = nil
    }

    private static func hasScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        } else {
            return true
        }
    }

    private func openScreenRecordingPrivacyPane() async throws {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}

extension ScreenCaptureManager: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        
        if let cg = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            let now = Date()
            if now.timeIntervalSince(lastEmit) >= minInterval {
                lastEmit = now
                DispatchQueue.main.async {
                    self.lastFrame = cg
                }
            }
        }
    }
}
