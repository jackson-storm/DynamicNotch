import Foundation
import Combine
internal import AppKit
import IOBluetooth
import CoreAudio

extension BluetoothService {
    func setupBluetoothObservers() {
        print("🎧 [BluetoothAudioManager] Setting up Bluetooth observers...")

        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(handleDeviceConnected(_:fromDevice:))
        )

        registerDisconnectObserversForPairedDevices()
        setupCoreAudioObservers()
        print("🎧 [BluetoothAudioManager] ✅ Native IOBluetooth and CoreAudio observers registered")
    }

    func registerDisconnectObserversForPairedDevices() {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return }
        for device in pairedDevices {
            registerDisconnectObserver(for: device)
        }
    }

    func registerDisconnectObserver(for device: IOBluetoothDevice) {
        let address = device.addressString ?? ""
        guard !address.isEmpty else { return }
        guard disconnectNotifications[address] == nil else { return }

        if let notif = device.register(forDisconnectNotification: self, selector: #selector(handleDeviceDisconnected(_:fromDevice:))) {
            disconnectNotifications[address] = notif
        }
    }

    func setupCoreAudioObservers() {
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            DispatchQueue.main
        ) { [weak self] _, _ in
            self?.handleCoreAudioChange()
        }

        var defaultDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultDeviceAddress,
            DispatchQueue.main
        ) { [weak self] _, _ in
            self?.handleCoreAudioChange()
        }
    }

    private func handleCoreAudioChange() {
        print("🎧 [BluetoothAudioManager] 📡 CoreAudio device change detected - checking devices")
        checkForNewlyConnectedDevices()
        updateConnectedDevices()
    }

    func startPollingForChanges() {
        print("🎧 [BluetoothAudioManager] Starting polling timer (\(pollingInterval)s interval)...")

        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkForDeviceChanges()
        }
        pollingTimer?.tolerance = pollingTolerance
    }

    func isDeviceConnected(_ device: IOBluetoothDevice) -> Bool {
        if device.isConnected() {
            return true
        }
        return isDeviceConnectedInCoreAudio(device)
    }

    func isDeviceConnectedInCoreAudio(_ device: IOBluetoothDevice) -> Bool {
        let activeBTDevices = activeCoreAudioBluetoothDevices()
        let targetAddr = normalizeBluetoothIdentifier(device.addressString ?? "")
        let targetName = normalizeProductName(device.name ?? "")

        for bt in activeBTDevices {
            if !targetAddr.isEmpty && normalizeBluetoothIdentifier(bt.uid).contains(targetAddr) {
                return true
            }
            if !targetName.isEmpty && normalizeProductName(bt.name) == targetName {
                return true
            }
        }
        return false
    }

    func activeCoreAudioBluetoothDevices() -> [(name: String, uid: String)] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize) == noErr else {
            return []
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs) == noErr else {
            return []
        }

        var results: [(name: String, uid: String)] = []

        for id in deviceIDs {
            var transAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyTransportType,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var transport: UInt32 = 0
            var transSize = UInt32(MemoryLayout<UInt32>.size)
            guard AudioObjectGetPropertyData(id, &transAddr, 0, nil, &transSize, &transport) == noErr else {
                continue
            }

            guard transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE else {
                continue
            }

            var nameAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var nameCF: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            let nameErr = withUnsafeMutablePointer(to: &nameCF) { ptr in
                AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, ptr)
            }

            var uidAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var uidCF: CFString = "" as CFString
            var uidSize = UInt32(MemoryLayout<CFString>.size)
            let uidErr = withUnsafeMutablePointer(to: &uidCF) { ptr in
                AudioObjectGetPropertyData(id, &uidAddr, 0, nil, &uidSize, ptr)
            }

            let nameStr = (nameErr == noErr) ? (nameCF as String) : ""
            let uidStr = (uidErr == noErr) ? (uidCF as String) : ""
            results.append((name: nameStr, uid: uidStr))
        }

        return results
    }

    func checkForDeviceChanges() {
        guard IOBluetoothHostController.default()?.powerState == kBluetoothHCIPowerStateON else {
            if !connectedDevices.isEmpty {
                print("🎧 [BluetoothAudioManager] ⚠️ Bluetooth powered off - clearing connected devices")
                connectedDevices.removeAll()
                isBluetoothAudioConnected = false
            }
            return
        }

        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }

        let currentlyConnectedAddresses = Set(
            pairedDevices
                .filter { isDeviceConnected($0) && isAudioDevice($0) }
                .compactMap { $0.addressString }
        )

        let previousAddresses = Set(connectedDevices.map { $0.address })

        let newAddresses = currentlyConnectedAddresses.subtracting(previousAddresses)
        if !newAddresses.isEmpty {
            print("🎧 [BluetoothAudioManager] 🔍 Polling detected new connection(s)")
            checkForNewlyConnectedDevices()
        }

        let removedAddresses = previousAddresses.subtracting(currentlyConnectedAddresses)
        if !removedAddresses.isEmpty {
            print("🎧 [BluetoothAudioManager] 🔍 Polling detected disconnection(s)")
            updateConnectedDevices()
        }
    }

    func checkInitialDevices() {
        print("🎧 [BluetoothAudioManager] Checking for initially connected devices...")

        guard IOBluetoothHostController.default()?.powerState == kBluetoothHCIPowerStateON else {
            print("🎧 [BluetoothAudioManager] ⚠️ Bluetooth is powered off - skipping initial check")
            return
        }

        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            print("🎧 [BluetoothAudioManager] No paired devices found")
            return
        }

        let connectedAudioDevices = pairedDevices.filter { device in
            isDeviceConnected(device) && isAudioDevice(device)
        }

        print("🎧 [BluetoothAudioManager] Found \(connectedAudioDevices.count) connected audio devices")

        connectedDevices = connectedAudioDevices.compactMap { device in
            createBluetoothAudioDevice(from: device)
        }

        isBluetoothAudioConnected = !connectedDevices.isEmpty
        refreshBatteryLevelsForConnectedDevices()

        if let lastDevice = connectedDevices.last {
            lastConnectedDevice = lastDevice
            print("🎧 [BluetoothAudioManager] ✅ Bluetooth audio connected: \(lastDevice.name)")
        }
    }

    @objc
    func handleDeviceConnected(_ notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice) {
        guard isAudioDevice(device) else {
            print("🎧 [BluetoothAudioManager] Non-audio device connected: \(device.name ?? "Unknown")")
            return
        }

        print("🎧 [BluetoothAudioManager] 📡 IOBluetooth connect notification received: \(device.name ?? "Unknown")")
        registerDisconnectObserver(for: device)
        DispatchQueue.main.async { [weak self] in
            self?.processConnectedDevice(device)
        }
    }

    @objc
    func handleDeviceDisconnected(_ notification: IOBluetoothUserNotification, fromDevice device: IOBluetoothDevice) {
        print("🎧 [BluetoothAudioManager] 📡 IOBluetooth disconnect notification received: \(device.name ?? "Unknown")")
        DispatchQueue.main.async { [weak self] in
            self?.processDisconnectedDevice(device)
        }
    }

    func processConnectedDevice(_ device: IOBluetoothDevice) {
        let address = device.addressString ?? "Unknown"

        if !connectedDevices.contains(where: { $0.address == address }) {
            print("🎧 [BluetoothAudioManager] 🎉 New audio device connected: \(device.name ?? "Unknown")")

            guard let audioDevice = createBluetoothAudioDevice(from: device) else {
                return
            }

            connectedDevices.append(audioDevice)
            lastConnectedDevice = audioDevice
            isBluetoothAudioConnected = true

            refreshBatteryLevelsForConnectedDevices()
            schedulePostConnectionBatteryRefreshes(for: audioDevice)

            if let refreshedDevice = connectedDevices.last {
                showDeviceConnectedHUD(refreshedDevice)
            } else {
                showDeviceConnectedHUD(audioDevice)
            }
        }
    }

    func processDisconnectedDevice(_ device: IOBluetoothDevice) {
        let address = device.addressString ?? "Unknown"
        disconnectNotifications.removeValue(forKey: address)

        let removed = connectedDevices.filter { $0.address == address }
        connectedDevices.removeAll { $0.address == address }
        removed.forEach {
            cancelHUDBatteryWait(for: $0)
            cancelPostConnectionBatteryRefresh(for: $0)
        }
        isBluetoothAudioConnected = !connectedDevices.isEmpty
        refreshBatteryLevelsForConnectedDevices()
    }

    func checkForNewlyConnectedDevices() {
        guard IOBluetoothHostController.default()?.powerState == kBluetoothHCIPowerStateON else {
            print("🎧 [BluetoothAudioManager] ⚠️ Bluetooth is powered off - skipping device check")
            return
        }

        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }

        let currentlyConnectedDevices = pairedDevices.filter { device in
            isDeviceConnected(device) && isAudioDevice(device)
        }

        for device in currentlyConnectedDevices {
            processConnectedDevice(device)
        }
    }

    func updateConnectedDevices() {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }

        let currentlyConnectedAddresses = pairedDevices
            .filter { isDeviceConnected($0) && isAudioDevice($0) }
            .compactMap { $0.addressString }

        let removedDevices = connectedDevices.filter { device in
            !currentlyConnectedAddresses.contains(device.address)
        }
        connectedDevices.removeAll { device in
            !currentlyConnectedAddresses.contains(device.address)
        }

        if !removedDevices.isEmpty {
            print("🎧 [BluetoothAudioManager] 👋 Audio device(s) disconnected")
            removedDevices.forEach {
                cancelHUDBatteryWait(for: $0)
                cancelPostConnectionBatteryRefresh(for: $0)
            }
        }

        isBluetoothAudioConnected = !connectedDevices.isEmpty
        refreshBatteryLevelsForConnectedDevices()
    }

    func cleanup() {
        print("🎧 [BluetoothAudioManager] Cleaning up observers...")

        pollingTimer?.invalidate()
        pollingTimer = nil

        connectNotification?.unregister()
        connectNotification = nil

        for notif in disconnectNotifications.values {
            notif.unregister()
        }
        disconnectNotifications.removeAll()

        observers.removeAll()
        cancellables.removeAll()
        hudBatteryWaitTasks.values.forEach { $0.cancel() }
        hudBatteryWaitTasks.removeAll()
        postConnectionBatteryRetryTasks.values.forEach { $0.cancel() }
        postConnectionBatteryRetryTasks.removeAll()
    }
}
