//
//  BluetoothMonitor.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/17/26.
//

import Foundation
import Combine
import SwiftUI
import IOBluetooth

final class BluetoothService: ObservableObject {
    static let shared = BluetoothService()

    @Published var lastConnectedDevice: BluetoothAudioDevice?
    @Published var connectedDevices: [BluetoothAudioDevice] = []
    @Published var isBluetoothAudioConnected: Bool = false
    @Published var batteryStatus: [String: String] = [:]

    var observers: [NSObjectProtocol] = []
    var cancellables = Set<AnyCancellable>()
    var pollingTimer: Timer?
    let bluetoothPreferencesSuite = "/Library/Preferences/com.apple.Bluetooth"
    let batteryReader = BluetoothLEBatteryReader()
    var isLiveBatteryRefreshInFlight = false

    let appleVendorID: UInt16 = 0x05AC
    let devicePIDMap: [UInt16: BluetoothAudioDeviceType] = [
        0x2002: .airpods,
        0x200F: .airpods,
        0x2013: .airpodsGen3,
        0x2019: .airpodsGen4,
        0x201B: .airpodsGen4,
        0x200A: .airpodsMax,
        0x201F: .airpodsMax,
        0x200E: .airpodsPro,
        0x2014: .airpodsPro,
        0x2024: .airpodsPro,
        0x2027: .airpodsPro3,
        0x2017: .beatsstudio,
        0x2009: .beatsstudio,
        0x2006: .beatssolo,
        0x200C: .beatssolo
    ]

    var batteryStatusByAddress: [String: Int] = [:]
    var batteryStatusByName: [String: Int] = [:]
    var missingBatteryLog: Set<String> = []
    var lastBatteryStatusUpdate: Date?
    let batteryStatusUpdateInterval: TimeInterval = 20
    let pmsetFetchQueue = DispatchQueue(label: "com.dynamicisland.bluetooth.pmset", qos: .utility)
    var isPmsetRefreshInFlight = false
    var lastPmsetRefreshDate: Date?
    let pmsetRefreshCooldown: TimeInterval = 5
    let pollingInterval: TimeInterval = 3.0
    let pollingTolerance: TimeInterval = 1.0
    var hudBatteryWaitTasks: [UUID: Task<Void, Never>] = [:]
    var postConnectionBatteryRetryTasks: [UUID: Task<Void, Never>] = [:]
    let hudBatteryWaitInterval: TimeInterval = 0.3
    let hudBatteryWaitTimeout: TimeInterval = 1.8
    let postConnectionBatteryRetryDelays: [TimeInterval] = [0.4, 0.8, 1.2]

    private init() {
        print("🎧 [BluetoothAudioManager] Initializing...")
        setupBluetoothObservers()
        checkInitialDevices()
        startPollingForChanges()
    }

    deinit {
        cleanup()
    }

    // MARK: - HUD Display

    func showDeviceConnectedHUD(_ device: BluetoothAudioDevice) {
        cancelHUDBatteryWait(for: device)

        if let battery = bestBatteryLevel(for: device) {
            presentDeviceConnectedHUD(device: device, batteryLevel: battery)
            return
        }

        requestPmsetFallback(reason: "hud missing battery")

        let task = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let deadline = Date().addingTimeInterval(self.hudBatteryWaitTimeout)
            while Date() < deadline {
                try? await Task.sleep(nanoseconds: UInt64(self.hudBatteryWaitInterval * 1_000_000_000))
                guard !Task.isCancelled else { return }

                let batteryInfo = await MainActor.run { () -> (BluetoothAudioDevice, Int)? in
                    guard let refreshedDevice = self.connectedDevices.first(where: { $0.id == device.id }),
                          let battery = self.bestBatteryLevel(for: refreshedDevice) else {
                        return nil
                    }
                    return (refreshedDevice, battery)
                }

                if let (refreshedDevice, battery) = batteryInfo {
                    await MainActor.run {
                        self.presentDeviceConnectedHUD(device: refreshedDevice, batteryLevel: battery)
                    }
                    await self.cancelHUDBatteryWait(for: device)
                    return
                }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.presentDeviceConnectedHUD(device: device, batteryLevel: nil)
            }
            await self.cancelHUDBatteryWait(for: device)
        }

        hudBatteryWaitTasks[device.id] = task
    }

    func presentDeviceConnectedHUD(device: BluetoothAudioDevice, batteryLevel: Int?) {
        print("🎧 [BluetoothAudioManager] 📱 Showing device connected HUD")

        let _: CGFloat = if let batteryLevel {
            CGFloat(clampBatteryPercentage(batteryLevel)) / 100.0
        } else {
            0.0
        }
    }

    @MainActor
    func refreshConnectedDeviceBatteries() {
        refreshBatteryLevelsForConnectedDevices()
    }

    @MainActor
    func activeDeviceIconSymbol() -> String? {
        if let prioritizedDevice = connectedDevices.last ?? lastConnectedDevice {
            return prioritizedDevice.deviceType.sfSymbol
        }
        return nil
    }
}
