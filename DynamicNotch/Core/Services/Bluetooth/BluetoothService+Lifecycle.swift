import Foundation
import Combine
internal import AppKit
import IOBluetooth

extension BluetoothService {
    // MARK: - Setup Methods

    func setupBluetoothObservers() {
        print("🎧 [BluetoothAudioManager] Setting up Bluetooth observers...")

        let dnc = DistributedNotificationCenter.default()

        dnc.addObserver(
            self,
            selector: #selector(handleDeviceConnectedNotification(_:)),
            name: NSNotification.Name("IOBluetoothDeviceConnectedNotification"),
            object: nil
        )

        dnc.addObserver(
            self,
            selector: #selector(handleDeviceDisconnectedNotification(_:)),
            name: NSNotification.Name("IOBluetoothDeviceDisconnectedNotification"),
            object: nil
        )

        print("🎧 [BluetoothAudioManager] ✅ Observers registered with DistributedNotificationCenter")
    }

    func startPollingForChanges() {
        print("🎧 [BluetoothAudioManager] Starting polling timer (\(pollingInterval)s interval)...")

        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkForDeviceChanges()
        }
        pollingTimer?.tolerance = pollingTolerance
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
                .filter { $0.isConnected() && isAudioDevice($0) }
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
            device.isConnected() && isAudioDevice(device)
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

    // MARK: - Device Event Handlers

    @objc
    func handleDeviceConnectedNotification(_ notification: Notification) {
        print("🎧 [BluetoothAudioManager] 📡 Device connection notification received")
        checkForNewlyConnectedDevices()
    }

    @objc
    func handleDeviceDisconnectedNotification(_ notification: Notification) {
        print("🎧 [BluetoothAudioManager] 📡 Device disconnection notification received")
        updateConnectedDevices()
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
            device.isConnected() && isAudioDevice(device)
        }

        for device in currentlyConnectedDevices {
            let address = device.addressString ?? "Unknown"

            if !connectedDevices.contains(where: { $0.address == address }) {
                print("🎧 [BluetoothAudioManager] 🎉 New audio device connected: \(device.name ?? "Unknown")")

                guard let audioDevice = createBluetoothAudioDevice(from: device) else {
                    continue
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
    }

    func updateConnectedDevices() {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }

        let currentlyConnectedAddresses = pairedDevices
            .filter { $0.isConnected() && isAudioDevice($0) }
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

    func handleDeviceConnected(_ notification: Notification) {
        guard let device = notification.object as? IOBluetoothDevice else {
            print("🎧 [BluetoothAudioManager] ⚠️ Could not extract device from notification")
            return
        }

        guard isAudioDevice(device) else {
            print("🎧 [BluetoothAudioManager] Device is not an audio device, ignoring")
            return
        }

        print("🎧 [BluetoothAudioManager] 🎉 Audio device connected: \(device.name ?? "Unknown")")

        guard let audioDevice = createBluetoothAudioDevice(from: device) else {
            return
        }

        if !connectedDevices.contains(where: { $0.address == audioDevice.address }) {
            connectedDevices.append(audioDevice)
        }

        lastConnectedDevice = audioDevice
        isBluetoothAudioConnected = true
        refreshBatteryLevelsForConnectedDevices()
        schedulePostConnectionBatteryRefreshes(for: audioDevice)
        showDeviceConnectedHUD(audioDevice)
    }

    func handleDeviceDisconnected(_ notification: Notification) {
        guard let device = notification.object as? IOBluetoothDevice else {
            return
        }

        guard isAudioDevice(device) else {
            return
        }

        print("🎧 [BluetoothAudioManager] 👋 Audio device disconnected: \(device.name ?? "Unknown")")

        let address = device.addressString ?? "Unknown"
        let removed = connectedDevices.filter { $0.address == address }
        connectedDevices.removeAll { $0.address == address }
        removed.forEach {
            cancelHUDBatteryWait(for: $0)
            cancelPostConnectionBatteryRefresh(for: $0)
        }
        isBluetoothAudioConnected = !connectedDevices.isEmpty
    }

    // MARK: - Cleanup

    func cleanup() {
        print("🎧 [BluetoothAudioManager] Cleaning up observers...")

        pollingTimer?.invalidate()
        pollingTimer = nil

        let dnc = DistributedNotificationCenter.default()
        dnc.removeObserver(self)
        observers.removeAll()
        cancellables.removeAll()
        hudBatteryWaitTasks.values.forEach { $0.cancel() }
        hudBatteryWaitTasks.removeAll()
        postConnectionBatteryRetryTasks.values.forEach { $0.cancel() }
        postConnectionBatteryRetryTasks.removeAll()
    }
}
