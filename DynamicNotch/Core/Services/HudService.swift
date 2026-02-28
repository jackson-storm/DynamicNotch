//
//  HudService.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import Foundation
import Combine
import CoreAudio
import IOKit
import CoreGraphics
import Darwin

final class VolumeEngine {
    private var volumeListenerQueue = DispatchQueue(label: "dyn.notch.volume.listener")
    private var currentDeviceID: AudioObjectID = 0
    private var volumeAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    private var defaultDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    private var onChange: ((Int) -> Void)?

    init() {
        currentDeviceID = defaultOutputDeviceID
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, volumeListenerQueue) { [weak self] _, _ in
            guard let self else { return }
            self.reregisterForCurrentDevice()
            self.onChange?(self.getCurrentVolume())
        }
        registerVolumeListener(for: currentDeviceID)
    }

    deinit {
        AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, volumeListenerQueue, { _, _ in })
        AudioObjectRemovePropertyListenerBlock(currentDeviceID, &volumeAddress, volumeListenerQueue, { _, _ in })
    }

    func startListening(_ onChange: @escaping (Int) -> Void) {
        self.onChange = onChange
        onChange(getCurrentVolume())
    }

    private func reregisterForCurrentDevice() {
        AudioObjectRemovePropertyListenerBlock(currentDeviceID, &volumeAddress, volumeListenerQueue, { _, _ in })
        currentDeviceID = defaultOutputDeviceID
        registerVolumeListener(for: currentDeviceID)
    }

    private func registerVolumeListener(for deviceID: AudioObjectID) {
        AudioObjectAddPropertyListenerBlock(deviceID, &volumeAddress, volumeListenerQueue) { [weak self] _, _ in
            guard let self else { return }
            let v = self.getCurrentVolume()
            self.onChange?(v)
        }
    }

    private var defaultOutputDeviceID: AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout.size(ofValue: deviceID))
        _ = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
    }

    func getCurrentVolume() -> Int {
        var address = volumeAddress
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout.size(ofValue: volume))
        let status = AudioObjectGetPropertyData(currentDeviceID, &address, 0, nil, &size, &volume)
        return status == noErr ? Int(round(Double(volume) * 100.0)) : 0
    }
}

private enum PrivateBrightnessAPIs {
    typealias CDGetUserBrightnessFn = @convention(c) (UInt32) -> Float
    typealias DSGetLinearBrightnessFn = @convention(c) (UInt32, UnsafeMutablePointer<Double>) -> Int32

    private static let cdPath = "/System/Library/PrivateFrameworks/CoreDisplay.framework/CoreDisplay"
    private static let cdHandle: UnsafeMutableRawPointer? = {
        dlopen(cdPath, RTLD_NOW)
    }()
    static let coreDisplayGetUserBrightness: CDGetUserBrightnessFn? = {
        guard let h = cdHandle, let sym = dlsym(h, "CoreDisplay_Display_GetUserBrightness") else { return nil }
        return unsafeBitCast(sym, to: CDGetUserBrightnessFn.self)
    }()

    private static let dsPath = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
    private static let dsHandle: UnsafeMutableRawPointer? = {
        dlopen(dsPath, RTLD_NOW)
    }()
    static let displayServicesGetLinearBrightness: DSGetLinearBrightnessFn? = {
        guard let h = dsHandle, let sym = dlsym(h, "DisplayServicesGetLinearBrightness") else { return nil }
        return unsafeBitCast(sym, to: DSGetLinearBrightnessFn.self)
    }()
}

final class BrightnessEngine {
    func getBrightness() -> Int {
        let displayID = CGMainDisplayID()

        if let fn = PrivateBrightnessAPIs.coreDisplayGetUserBrightness {
            let val = fn(displayID) // 0.0 … 1.0
            if val.isFinite && val >= 0 {
                return Int(round(Double(val) * 100.0))
            }
        }
        
        if let fn = PrivateBrightnessAPIs.displayServicesGetLinearBrightness {
            var out: Double = 0
            let result = fn(displayID, &out) // 0.0 … 1.0
            if result == 0 && out.isFinite && out >= 0 {
                return Int(round(out * 100.0))
            }
        }
        
        if let percent = readBrightnessFromIORegistry() {
            return percent
        }

        return 0
    }

    private func readBrightnessFromIORegistry() -> Int? {
        let matching = IOServiceMatching("AppleBacklightDisplay")
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iter) }

        let service = IOIteratorNext(iter)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        let keys: [CFString] = [
            "CurrentBrightness" as CFString,
            "brightness" as CFString
        ]

        for key in keys {
            if let cf = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0)?.takeRetainedValue() {
                if let number = cf as? NSNumber {
                    let val = number.doubleValue
                    if val <= 1.0 {
                        return Int(round(val * 100.0))
                    } else {
                        return Int(round(min(100.0, max(0.0, (val / 255.0) * 100.0))))
                    }
                }
            }
        }
        return nil
    }
}

final class KeyboardBrightnessEngine {
    func getLevel() -> Int {
        var iterator: io_iterator_t = 0
        let matchingDict = IOServiceMatching("AppleHIDKeyboardBacklight")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)

        guard result == kIOReturnSuccess, iterator != 0 else {
            return 0
        }

        defer {
            IOObjectRelease(iterator)
        }

        let service = IOIteratorNext(iterator)
        guard service != 0 else {
            return 0
        }
        defer {
            IOObjectRelease(service)
        }

        let key = "KeyboardBacklightBrightness" as CFString
        if let cfValue = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0)?.takeRetainedValue() {
            if let number = cfValue as? NSNumber {
                let raw = number.doubleValue
                let normalized = min(100.0, max(0.0, (raw / 255.0) * 100.0))
                return Int(round(normalized))
            }
        }
        return 0
    }
}

final class HudService {
    static let shared = HudService()
    let eventPublisher = PassthroughSubject<HudEvent, Never>()

    private let volEngine = VolumeEngine()
    private let brightEngine = BrightnessEngine()
    private let kbEngine = KeyboardBrightnessEngine()

    private var cancellables = Set<AnyCancellable>()
    private var lastDisplayLevel: Int = -1
    private var lastKeyboardLevel: Int = -1

    init() {
        volEngine.startListening { [weak self] value in
            guard let self else { return }
            self.eventPublisher.send(.volume(value))
        }
        
        Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                let display = self.brightEngine.getBrightness()
                if display != self.lastDisplayLevel {
                    self.lastDisplayLevel = display
                    self.eventPublisher.send(.display(display))
                }

                let keyboard = self.kbEngine.getLevel()
                if keyboard != self.lastKeyboardLevel {
                    self.lastKeyboardLevel = keyboard
                    self.eventPublisher.send(.keyboard(keyboard))
                }
            }
            .store(in: &cancellables)
    }
}
