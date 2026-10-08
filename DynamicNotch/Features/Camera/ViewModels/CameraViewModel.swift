//
//  CameraViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/19/26.
//

import SwiftUI
import AVFoundation
import Combine

enum CameraState {
    case unknown
    case ready
    case unavailable
}

final class CameraViewModel: ObservableObject {
    let session = AVCaptureSession()
    @Published var cameraState: CameraState = .unknown
    
    private let sessionQueue = DispatchQueue(label: "com.dynamicnotch.cameraSessionQueue")
    private var stopWorkItem: DispatchWorkItem?
    private var isConfigured = false
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    init() {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        checkPermissions()
    }
    
    deinit {
        stopWorkItem?.cancel()
        previewLayer.session = nil
        let captureSession = session
        sessionQueue.async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }
    
    func checkPermissions() {
        guard !AppEnvironment.isRunningTests else {
            DispatchQueue.main.async {
                self.cameraState = .unavailable
            }
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.cameraState = .unavailable
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.cameraState = .unavailable
            }
        }
    }
    
    func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isConfigured else { return }
            
            let captureSession = self.session
            captureSession.beginConfiguration()
            
            for input in captureSession.inputs {
                captureSession.removeInput(input)
            }
            
            guard let device = AVCaptureDevice.default(for: .video) else {
                captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    self.cameraState = .unavailable
                }
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    self.isConfigured = true
                } else {
                    DispatchQueue.main.async {
                        self.cameraState = .unavailable
                    }
                }
            } catch {
                print("Failed to set up camera input: \(error)")
                DispatchQueue.main.async {
                    self.cameraState = .unavailable
                }
            }
            
            captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                withAnimation {
                    self.cameraState = self.isConfigured ? (self.session.isRunning ? .ready : .unknown) : .unavailable
                }
            }
        }
    }
    
    func startSession() {
        stopWorkItem?.cancel()
        stopWorkItem = nil
        
        guard cameraState != .unavailable else { return }
        
        if !session.isRunning {
            cameraState = .unknown
        }
        
        let startTimestamp = CACurrentMediaTime()
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let captureSession = self.session
            
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
            
            let elapsed = CACurrentMediaTime() - startTimestamp
            let minLoadingDuration: Double = 0.55
            let delay = max(0, minLoadingDuration - elapsed)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                    self.cameraState = .ready
                }
            }
        }
    }
    
    func stopSession() {
        stopWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            DispatchQueue.main.async {
                self.cameraState = .unknown
            }
        }
        self.stopWorkItem = workItem
        sessionQueue.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
}

class PreviewView: NSView {
    private weak var previewLayer: AVCaptureVideoPreviewLayer?

    init(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.addSublayer(previewLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        previewLayer?.frame = self.bounds
    }
}
