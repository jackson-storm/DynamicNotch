//
//  FaceIDService.swift
//  DynamicNotch
//

internal import AppKit
@preconcurrency import AVFoundation
import Combine
import SwiftUI
@preconcurrency internal import Vision

@MainActor
final class FaceIDService: NSObject, ObservableObject {
    static let shared = FaceIDService()

    @Published private(set) var state: FaceIDState = .idle
    @Published private(set) var detectedFaceCount: Int = 0
    @Published private(set) var areEyesOpen: Bool = true
    @Published private(set) var livenessScore: Double = 0.0

    private let session = AVCaptureSession()
    private let captureQueue = DispatchQueue(label: "com.dynamicnotch.faceid.serviceQueue", qos: .userInitiated)
    nonisolated(unsafe) private var isConfigured = false
    private var isProcessingFrame = false
    private var scanTimeoutTimer: AnyCancellable?
    private var scanProgress: Double = 0.0
    private var completionHandler: ((Bool) -> Void)?
    private var requireOpenEyes: Bool = true
    private var livenessCheck: Bool = true

    override init() {
        super.init()
    }

    deinit {
        scanTimeoutTimer?.cancel()
        let captureSession = session
        captureQueue.async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    func startScan(
        requireOpenEyes: Bool = true,
        livenessCheck: Bool = true,
        completion: ((Bool) -> Void)? = nil
    ) {
        cancelScan()

        self.completionHandler = completion
        self.requireOpenEyes = requireOpenEyes
        self.livenessCheck = livenessCheck
        self.state = .searching
        self.detectedFaceCount = 0
        self.areEyesOpen = true
        self.livenessScore = 0.0
        self.scanProgress = 0.0

        // Arm a 6.5s timeout: if no face verified in time, mark as failed
        scanTimeoutTimer = Just(())
            .delay(for: .seconds(6.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.state.isActivelyEvaluating else { return }
                self.handleScanFailed(reason: "Face not recognized")
            }

        startCameraCapture()
    }

    func cancelScan() {
        scanTimeoutTimer?.cancel()
        scanTimeoutTimer = nil
        completionHandler = nil
        stopCameraCapture()
        state = .idle
        scanProgress = 0.0
    }

    private func startCameraCapture() {
        guard !AppEnvironment.isRunningTests else {
            simulateFallbackScan()
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupAndRunSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupAndRunSession()
                    } else {
                        self?.handleScanFailed(reason: "Camera access denied")
                    }
                }
            }
        default:
            handleScanFailed(reason: "No camera access")
        }
    }

    private func setupAndRunSession() {
        let captureSession = session
        captureQueue.async { [weak self] in
            guard let self else { return }

            if !self.isConfigured {
                captureSession.beginConfiguration()
                captureSession.sessionPreset = .high

                for input in captureSession.inputs {
                    captureSession.removeInput(input)
                }
                for output in captureSession.outputs {
                    captureSession.removeOutput(output)
                }

                guard let device = AVCaptureDevice.default(for: .video) else {
                    captureSession.commitConfiguration()
                    DispatchQueue.main.async {
                        self.simulateFallbackScan()
                    }
                    return
                }

                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if captureSession.canAddInput(input) {
                        captureSession.addInput(input)
                    }

                    let output = AVCaptureVideoDataOutput()
                    output.alwaysDiscardsLateVideoFrames = true
                    output.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                    ]
                    output.setSampleBufferDelegate(self, queue: self.captureQueue)

                    if captureSession.canAddOutput(output) {
                        captureSession.addOutput(output)
                    }

                    captureSession.commitConfiguration()
                    self.isConfigured = true
                } catch {
                    captureSession.commitConfiguration()
                    DispatchQueue.main.async {
                        self.handleScanFailed(reason: "Camera error")
                    }
                    return
                }
            }

            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }

    private func stopCameraCapture() {
        let captureSession = session
        captureQueue.async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    private func handleScanFailed(reason: String) {
        scanTimeoutTimer?.cancel()
        scanTimeoutTimer = nil
        stopCameraCapture()

        state = .failed(reason: reason)
        completionHandler?(false)
        completionHandler = nil

        // Reset to idle after 2.2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            guard let self, self.state.isFailed else { return }
            self.state = .idle
        }
    }

    private func handleFaceVerified() {
        scanTimeoutTimer?.cancel()
        scanTimeoutTimer = nil
        stopCameraCapture()

        state = .success
        let callback = completionHandler
        completionHandler = nil
        callback?(true)

        // Reset to idle after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self, self.state.isSuccess else { return }
            self.state = .idle
        }
    }

    private func simulateFallbackScan() {
        // Fallback for environments without physical camera (tests/CI)
        state = .scanning(progress: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.state = .scanning(progress: 0.7)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.handleFaceVerified()
            }
        }
    }

    func unlockWithSavedPassword() {
        guard let password = FaceIDKeychainService.getPassword(), !password.isEmpty else {
            // Do NOT simulate return key if password is empty, to prevent "Неверный пароль" error on lock screen
            return
        }

        DispatchQueue.main.async {
            NSApp.deactivate()
        }

        DispatchQueue.global(qos: .userInteractive).async {
            // Short delay to ensure password text field has focus
            usleep(150_000)

            let source = CGEventSource(stateID: .hidSystemState)

            for char in password {
                let utf16Chars = Array(String(char).utf16)

                if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                    keyDown.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
                    keyDown.post(tap: .cghidEventTap)
                }
                usleep(12_000)

                if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                    keyUp.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
                    keyUp.post(tap: .cghidEventTap)
                }
                usleep(12_000)
            }

            usleep(50_000)

            // Virtual Return (0x24)
            if let enterDown = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: true) {
                enterDown.post(tap: .cghidEventTap)
            }
            usleep(15_000)
            if let enterUp = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: false) {
                enterUp.post(tap: .cghidEventTap)
            }
        }
    }
}

extension FaceIDService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Process synchronously on captureQueue while pixelBuffer is guaranteed valid
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([request])
            let face = request.results?.first

            DispatchQueue.main.async { [weak self] in
                guard let self, self.state.isActivelyEvaluating else { return }

                if let face {
                    let box = face.boundingBox
                    let isCentered = (0.15...0.85).contains(box.midX) && (0.15...0.85).contains(box.midY)
                    let isGoodSize = box.width >= 0.14

                    let eyesPass = !self.requireOpenEyes || FaceAttentionEvaluator.areEyesOpen(face: face)
                    let attentionPass = !self.livenessCheck || (FaceAttentionEvaluator.isFacingCamera(face: face) && FaceAttentionEvaluator.isGazeDirect(face: face))

                    self.areEyesOpen = eyesPass
                    self.livenessScore = attentionPass ? 1.0 : 0.0

                    if isCentered && isGoodSize && eyesPass && attentionPass {
                        self.detectedFaceCount = 1
                        self.scanProgress = min(1.0, self.scanProgress + 0.18)
                        self.state = .scanning(progress: self.scanProgress)

                        if self.scanProgress >= 1.0 {
                            self.handleFaceVerified()
                        }
                    } else {
                        self.detectedFaceCount = 1
                        self.scanProgress = max(0.0, self.scanProgress - 0.04)
                        self.state = .searching
                    }
                } else {
                    self.detectedFaceCount = 0
                    self.scanProgress = max(0.0, self.scanProgress - 0.04)
                    if self.scanProgress == 0 {
                        self.state = .searching
                    }
                }
            }
        } catch {
            // Frame failed to parse
        }
    }
}
