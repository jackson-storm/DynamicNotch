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

final class BluetoothViewModel: ObservableObject {
    @Published var deviceType: BluetoothDeviceType = .unknown
    @Published var event: BluetoothEvent?
    @Published var isConnected: Bool = false
    @Published var deviceName: String = ""
    @Published var batteryLevel: Int? = nil
    
    var notchViewModel: NotchViewModel?
    
    private var hasHandledInitialState = false
    private var isInitialized = false
    private var monitor = BluetoothMonitor()
    private var cancellables = Set<AnyCancellable>()
    
    init(notchViewModel: NotchViewModel? = nil) {
        self.notchViewModel = notchViewModel
        setupMonitoring()
        setupNotifications()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isInitialized = true
            self.checkBluetooth()
        }
    }
    
    func update() {
        checkBluetooth()
    }
    
    private func setupMonitoring() {
        Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkBluetooth()
            }
            .store(in: &cancellables)
    }
    
    private func checkBluetooth() {
        let info = monitor.getLatestDeviceInfo()
        
        DispatchQueue.main.async {
            
            if !self.hasHandledInitialState {
                self.isConnected = info.isConnected
                self.deviceName = info.name
                self.batteryLevel = info.battery
                self.deviceType = info.type
                
                self.hasHandledInitialState = true
                return
            }
            
            if info.isConnected && !self.isConnected {
                self.event = .connected
            }
            
            self.isConnected = info.isConnected
            self.deviceName = info.name
            self.batteryLevel = info.battery
            self.deviceType = info.type
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("IOBluetoothDeviceConnectNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self?.checkBluetooth()
            }
        }
    }
}

