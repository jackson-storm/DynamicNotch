import CoreAudio
import Foundation

final class SystemAudioOutputRoutingService: AudioOutputRouting {
    private let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

    func availableRoutes() -> [AudioOutputRoute] {
        let currentDeviceID = defaultOutputDeviceID()

        return allAudioDeviceIDs()
            .filter(isEligibleOutputDevice)
            .compactMap { makeRoute(deviceID: $0, currentDeviceID: currentDeviceID) }
            .sorted { lhs, rhs in
                if lhs.isCurrent != rhs.isCurrent {
                    return lhs.isCurrent && !rhs.isCurrent
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func currentRoute() -> AudioOutputRoute? {
        availableRoutes().first(where: \.isCurrent)
    }

    @discardableResult
    func setCurrentRoute(_ id: AudioDeviceID) -> Bool {
        guard id != 0 else { return false }

        let didSetDefaultOutput = setDefaultDevice(
            selector: kAudioHardwarePropertyDefaultOutputDevice,
            deviceID: id
        )

        if canBeDefaultSystemOutputDevice(id) {
            _ = setDefaultDevice(
                selector: kAudioHardwarePropertyDefaultSystemOutputDevice,
                deviceID: id
            )
        }

        return didSetDefaultOutput
    }
}

private extension SystemAudioOutputRoutingService {
    func makeRoute(
        deviceID: AudioDeviceID,
        currentDeviceID: AudioDeviceID
    ) -> AudioOutputRoute? {
        let resolvedName = deviceName(for: deviceID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let resolvedName, resolvedName.isEmpty == false else {
            return nil
        }

        return AudioOutputRoute(
            id: deviceID,
            name: resolvedName,
            transportType: transportType(for: deviceID),
            isCurrent: deviceID == currentDeviceID
        )
    }

    func allAudioDeviceIDs() -> [AudioDeviceID] {
        var address = propertyAddress(
            selector: kAudioHardwarePropertyDevices,
            scope: kAudioObjectPropertyScopeGlobal
        )
        var dataSize: UInt32 = 0

        let sizeStatus = AudioObjectGetPropertyDataSize(
            systemObjectID,
            &address,
            0,
            nil,
            &dataSize
        )

        guard sizeStatus == noErr, dataSize > 0 else {
            return []
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(), count: deviceCount)

        let dataStatus = deviceIDs.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else {
                return kAudio_ParamError
            }
            return AudioObjectGetPropertyData(
                systemObjectID,
                &address,
                0,
                nil,
                &dataSize,
                base
            )
        }

        guard dataStatus == noErr else {
            return []
        }

        return deviceIDs
    }

    func isEligibleOutputDevice(_ deviceID: AudioDeviceID) -> Bool {
        isAlive(deviceID) &&
        isOutputCapable(deviceID) &&
        canBeDefaultOutputDevice(deviceID)
    }

    func isOutputCapable(_ deviceID: AudioDeviceID) -> Bool {
        var address = propertyAddress(
            selector: kAudioDevicePropertyStreamConfiguration,
            scope: kAudioDevicePropertyScopeOutput
        )
        var dataSize: UInt32 = 0

        let sizeStatus = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
            0,
            nil,
            &dataSize
        )

        guard sizeStatus == noErr, dataSize > 0 else {
            return false
        }

        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: Int(dataSize),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer {
            rawPointer.deallocate()
        }

        let dataStatus = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &dataSize,
            rawPointer
        )

        guard dataStatus == noErr else {
            return false
        }

        let bufferList = UnsafeMutableAudioBufferListPointer(
            rawPointer.assumingMemoryBound(to: AudioBufferList.self)
        )

        let outputChannelCount = bufferList.reduce(0) { partialResult, buffer in
            partialResult + Int(buffer.mNumberChannels)
        }

        return outputChannelCount > 0
    }

    func isAlive(_ deviceID: AudioDeviceID) -> Bool {
        propertyUInt32(
            deviceID: deviceID,
            selector: kAudioDevicePropertyDeviceIsAlive,
            scope: kAudioObjectPropertyScopeGlobal
        ) ?? 1 != 0
    }

    func canBeDefaultOutputDevice(_ deviceID: AudioDeviceID) -> Bool {
        propertyUInt32(
            deviceID: deviceID,
            selector: kAudioDevicePropertyDeviceCanBeDefaultDevice,
            scope: kAudioDevicePropertyScopeOutput
        ) ?? 1 != 0
    }

    func canBeDefaultSystemOutputDevice(_ deviceID: AudioDeviceID) -> Bool {
        propertyUInt32(
            deviceID: deviceID,
            selector: kAudioDevicePropertyDeviceCanBeDefaultSystemDevice,
            scope: kAudioDevicePropertyScopeOutput
        ) ?? 0 != 0
    }

    func deviceName(for deviceID: AudioDeviceID) -> String? {
        var name: CFString = "" as CFString
        let status = getPropertyData(
            objectID: deviceID,
            selector: kAudioObjectPropertyName,
            scope: kAudioObjectPropertyScopeGlobal,
            data: &name
        )

        guard status == noErr else {
            return nil
        }

        return name as String
    }

    func transportType(for deviceID: AudioDeviceID) -> UInt32 {
        propertyUInt32(
            deviceID: deviceID,
            selector: kAudioDevicePropertyTransportType,
            scope: kAudioObjectPropertyScopeGlobal
        ) ?? kAudioDeviceTransportTypeUnknown
    }

    func defaultOutputDeviceID() -> AudioDeviceID {
        var deviceID = AudioDeviceID()
        let status = getPropertyData(
            objectID: systemObjectID,
            selector: kAudioHardwarePropertyDefaultOutputDevice,
            scope: kAudioObjectPropertyScopeGlobal,
            data: &deviceID
        )

        guard status == noErr else {
            return 0
        }

        return deviceID
    }

    func setDefaultDevice(
        selector: AudioObjectPropertySelector,
        deviceID: AudioDeviceID
    ) -> Bool {
        var mutableDeviceID = deviceID
        var address = propertyAddress(
            selector: selector,
            scope: kAudioObjectPropertyScopeGlobal
        )

        let status = AudioObjectSetPropertyData(
            systemObjectID,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &mutableDeviceID
        )

        return status == noErr
    }

    func propertyUInt32(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> UInt32? {
        var value: UInt32 = 0
        let status = getPropertyData(
            objectID: deviceID,
            selector: selector,
            scope: scope,
            data: &value
        )

        return status == noErr ? value : nil
    }

    func getPropertyData<T>(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
        data: inout T
    ) -> OSStatus {
        var address = propertyAddress(
            selector: selector,
            scope: scope,
            element: element
        )
        var size = UInt32(MemoryLayout<T>.size)

        return withUnsafeMutablePointer(to: &data) { pointer in
            AudioObjectGetPropertyData(
                objectID,
                &address,
                0,
                nil,
                &size,
                pointer
            )
        }
    }

    func propertyAddress(
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope,
        element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: element
        )
    }
}
