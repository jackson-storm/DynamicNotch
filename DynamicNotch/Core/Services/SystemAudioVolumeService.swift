import CoreAudio
import Foundation

final class SystemAudioVolumeService {
    private let candidateElements: [AudioObjectPropertyElement] = [
        kAudioObjectPropertyElementMain,
        AudioObjectPropertyElement(1),
        AudioObjectPropertyElement(2)
    ]

    private let muteThreshold: Float = 0.001
    private var lastAudibleVolume: Float = 0.5

    func adjust(direction: MediaKeyDirection, granularity: MediaKeyGranularity) -> Int {
        let delta = stepSize(for: granularity) * (direction == .increase ? 1 : -1)
        return setVolume(currentEffectiveVolume + delta)
    }

    func toggleMute() -> Int {
        guard supportsMute(on: defaultOutputDeviceID()) else {
            if currentEffectiveVolume > muteThreshold {
                lastAudibleVolume = max(currentVolume, stepSize(for: .standard))
                return setVolume(0)
            }

            return setVolume(lastAudibleVolume)
        }

        let nextMutedState = !isMuted
        setMuted(nextMutedState)
        return nextMutedState ? 0 : percentValue(for: currentVolume)
    }

    @discardableResult
    func setVolume(_ value: Float) -> Int {
        let clampedValue = max(0, min(1, value))
        let deviceID = defaultOutputDeviceID()

        if clampedValue > muteThreshold {
            lastAudibleVolume = clampedValue
            if supportsMute(on: deviceID) {
                setMuted(false)
            }
        } else if supportsMute(on: deviceID) {
            setMuted(true)
        }

        let targetElements = volumeElements(on: deviceID)
        if targetElements.isEmpty {
            var scalar = clampedValue
            _ = setDataFloat32(
                deviceID: deviceID,
                selector: kAudioDevicePropertyVolumeScalar,
                element: kAudioObjectPropertyElementMain,
                value: &scalar
            )
        } else {
            for element in targetElements {
                var scalar = clampedValue
                _ = setDataFloat32(
                    deviceID: deviceID,
                    selector: kAudioDevicePropertyVolumeScalar,
                    element: element,
                    value: &scalar
                )
            }
        }

        return percentValue(for: currentEffectiveVolume)
    }

    var currentVolume: Float {
        let deviceID = defaultOutputDeviceID()
        let targetElements = volumeElements(on: deviceID)

        if let masterVolume = targetElements.compactMap({ volumeValue(deviceID: deviceID, element: $0) }).first {
            return max(0, min(1, masterVolume))
        }

        return 0
    }

    var currentEffectiveVolume: Float {
        isMuted ? 0 : currentVolume
    }

    var isMuted: Bool {
        let deviceID = defaultOutputDeviceID()
        let targetElements = muteElements(on: deviceID)

        if targetElements.isEmpty {
            return false
        }

        for element in targetElements {
            if muteValue(deviceID: deviceID, element: element) == false {
                return false
            }
        }

        return true
    }

    private func defaultOutputDeviceID() -> AudioDeviceID {
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout.size(ofValue: deviceID))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr else {
            NSLog("Failed to read the default output device: \(status)")
            return 0
        }

        return deviceID
    }

    private func volumeElements(on deviceID: AudioDeviceID) -> [AudioObjectPropertyElement] {
        candidateElements.filter { element in
            propertyExists(
                deviceID: deviceID,
                selector: kAudioDevicePropertyVolumeScalar,
                element: element
            )
        }
    }

    private func muteElements(on deviceID: AudioDeviceID) -> [AudioObjectPropertyElement] {
        candidateElements.filter { element in
            propertyExists(
                deviceID: deviceID,
                selector: kAudioDevicePropertyMute,
                element: element
            )
        }
    }

    private func supportsMute(on deviceID: AudioDeviceID) -> Bool {
        !muteElements(on: deviceID).isEmpty
    }

    private func propertyExists(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        element: AudioObjectPropertyElement
    ) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )

        return withUnsafePointer(to: &address) { pointer in
            AudioObjectHasProperty(deviceID, pointer)
        }
    }

    private func volumeValue(deviceID: AudioDeviceID, element: AudioObjectPropertyElement) -> Float? {
        var scalar: Float32 = 0
        let status = getData(
            deviceID: deviceID,
            selector: kAudioDevicePropertyVolumeScalar,
            element: element,
            data: &scalar
        )
        return status == noErr ? scalar : nil
    }

    private func muteValue(deviceID: AudioDeviceID, element: AudioObjectPropertyElement) -> Bool {
        var muted: UInt32 = 0
        let status = getData(
            deviceID: deviceID,
            selector: kAudioDevicePropertyMute,
            element: element,
            data: &muted
        )
        return status == noErr ? muted != 0 : false
    }

    private func setMuted(_ isMuted: Bool) {
        let deviceID = defaultOutputDeviceID()
        let targetElements = muteElements(on: deviceID)
        guard !targetElements.isEmpty else {
            return
        }

        for element in targetElements {
            var value: UInt32 = isMuted ? 1 : 0
            _ = setDataUInt32(
                deviceID: deviceID,
                selector: kAudioDevicePropertyMute,
                element: element,
                value: &value
            )
        }
    }

    private func getData<T>(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        element: AudioObjectPropertyElement,
        data: inout T
    ) -> OSStatus {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )
        var size = UInt32(MemoryLayout<T>.size)
        return withUnsafeMutablePointer(to: &data) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
    }

    private func setDataRaw(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        element: AudioObjectPropertyElement,
        data: UnsafeRawPointer,
        dataSize: UInt32
    ) -> OSStatus {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )
        return AudioObjectSetPropertyData(deviceID, &address, 0, nil, dataSize, data)
    }

    private func setDataFloat32(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        element: AudioObjectPropertyElement,
        value: inout Float32
    ) -> OSStatus {
        return withUnsafePointer(to: &value) { ptr in
            setDataRaw(
                deviceID: deviceID,
                selector: selector,
                element: element,
                data: UnsafeRawPointer(ptr),
                dataSize: UInt32(MemoryLayout<Float32>.size)
            )
        }
    }

    private func setDataUInt32(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        element: AudioObjectPropertyElement,
        value: inout UInt32
    ) -> OSStatus {
        return withUnsafePointer(to: &value) { ptr in
            setDataRaw(
                deviceID: deviceID,
                selector: selector,
                element: element,
                data: UnsafeRawPointer(ptr),
                dataSize: UInt32(MemoryLayout<UInt32>.size)
            )
        }
    }

    private func stepSize(for granularity: MediaKeyGranularity) -> Float {
        switch granularity {
        case .standard:
            return 1.0 / 16.0
        case .fine:
            return 1.0 / 64.0
        }
    }

    private func percentValue(for scalar: Float) -> Int {
        Int((max(0, min(1, scalar)) * 100).rounded())
    }
}
