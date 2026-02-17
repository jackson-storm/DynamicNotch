//
//  AudioHardwareViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/17/26.
//

import Foundation
import IOBluetooth
import IOKit
import Combine

enum BluetoothEvent {
    case connected
}

final class BluetoothViewModel: ObservableObject {
    @Published var event: BluetoothEvent?
    @Published var isConnected: Bool = false
    @Published var deviceName: String = ""
    @Published var batteryLevel: Int? = nil
    
    var notchViewModel: NotchViewModel?
    
    private var isInitialized = false
    private var monitor = BluetoothMonitor()
    private var cancellables = Set<AnyCancellable>()
    
    init(notchViewModel: NotchViewModel? = nil) {
        self.notchViewModel = notchViewModel
        setupMonitoring()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isInitialized = true
        }
    }
    
    func update() {
        checkBluetooth()
    }
    
    private func setupMonitoring() {
        Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkBluetooth()
            }
            .store(in: &cancellables)
    }
    
    private func checkBluetooth() {
            let info = monitor.getLatestDeviceInfo()
            
            if info.isConnected && !self.isConnected && isInitialized {
                self.event = .connected
            }
            
            self.isConnected = info.isConnected
            self.deviceName = info.name
            self.batteryLevel = info.battery
        }
}
