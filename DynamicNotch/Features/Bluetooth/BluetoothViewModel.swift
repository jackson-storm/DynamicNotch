//
//  AudioHardwareViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/17/26.
//

import Foundation
import Combine

enum BluetoothEvent: Equatable {
    case connected
}

final class BluetoothViewModel: ObservableObject {
    @Published var deviceType: BluetoothAudioDeviceType = .generic
    @Published var event: BluetoothEvent?
    @Published var isConnected: Bool = false
    @Published var deviceName: String = "Unknown"
    @Published var batteryLevel: Int? = nil
    
    var notchViewModel: NotchViewModel?
    
    private var cancellables = Set<AnyCancellable>()
    private let bluetoothService: BluetoothService
    
    init(notchViewModel: NotchViewModel? = nil, bluetoothService: BluetoothService = .shared) {
        self.notchViewModel = notchViewModel
        self.bluetoothService = bluetoothService
        bindToService()
    }
    
    func update() {
        Task { @MainActor in
            bluetoothService.refreshConnectedDeviceBatteries()
        }
    }
    
    private func bindToService() {
        bluetoothService.$connectedDevices
            .receive(on: RunLoop.main)
            .sink { [weak self] devices in
                guard let self = self else { return }
                
                let wasConnected = self.isConnected
                let isNowConnected = !devices.isEmpty
                self.isConnected = isNowConnected
                
                if isNowConnected {
                    let device = devices.last ?? self.bluetoothService.lastConnectedDevice
                    self.deviceName = device?.name ?? "Unknown"
                    self.batteryLevel = device?.batteryLevel
                    self.deviceType = device?.deviceType ?? .generic
                } else {
                    self.deviceName = "Unknown"
                    self.batteryLevel = nil
                    self.deviceType = .generic
                }
                
                if isNowConnected && !wasConnected {
                    self.event = .connected
                }
            }
            .store(in: &cancellables)
    
        bluetoothService.$lastConnectedDevice
            .receive(on: RunLoop.main)
            .sink { [weak self] device in
                guard let self = self else { return }
                guard let device = device else { return }
                
                guard self.isConnected else { return }
                
                self.deviceName = device.name
                self.batteryLevel = device.batteryLevel
                self.deviceType = device.deviceType
            }
            .store(in: &cancellables)
    }
}
