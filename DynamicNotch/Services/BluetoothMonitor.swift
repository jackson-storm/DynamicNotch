//
//  BluetoothMonitor.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/17/26.
//

import Foundation
import IOBluetooth
import IOKit

final class BluetoothMonitor {
    func getLatestDeviceInfo() -> (isConnected: Bool, name: String, battery: Int?) {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
              let connectedDevice = devices.first(where: { $0.isConnected() }) else {
            return (false, "Disconnected", nil)
        }
        
        let battery = getBatteryLevel(for: connectedDevice)
        return (true, connectedDevice.name ?? "Unknown", battery)
    }
    
    func getConnectedDevicesInfo() {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            print("Нет сопряженных устройств.")
            return
        }
        
        print("--- Поиск подключенных устройств ---")
        
        for device in devices {
            if device.isConnected() {
                let name = device.name ?? "Unknown Device"
                let address = device.addressString ?? "00:00:00:00:00:00"
                
                print("\nУстройство: \(name)")
                print("MAC: \(address)")
                
                if let batteryLevel = getBatteryLevel(for: device) {
                    print("Заряд: \(batteryLevel)%")
                } else {
                    print("Заряд: Не удалось определить (или не поддерживается)")
                }
            }
        }
    }
    private func getBatteryLevel(for device: IOBluetoothDevice) -> Int? {
        let matchingDict = IOServiceMatching("AppleDeviceManagementHIDEventService")
        var iterator: io_iterator_t = 0
        
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        
        if result != kIOReturnSuccess {
            return nil
        }
        
        defer { IOObjectRelease(iterator) }
        
        var batteryLevel: Int? = nil
        
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            
            if let deviceAddress = IORegistryEntryCreateCFProperty(service, "DeviceAddress" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                
                if deviceAddress.lowercased() == device.addressString.lowercased() {
                    
                    let batteryKeys = ["BatteryPercent", "BatteryLevel", "BatteryPercentCase", "BatteryPercentLeft", "BatteryPercentRight"]
                    
                    for key in batteryKeys {
                        if let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() {
                            if let intValue = value as? Int {
                                batteryLevel = intValue
                                break
                            }
                        }
                    }
                }
            }
            if batteryLevel != nil { break }
        }
        return batteryLevel
    }
}
