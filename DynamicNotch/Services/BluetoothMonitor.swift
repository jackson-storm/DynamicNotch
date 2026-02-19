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
    func getLatestDeviceInfo() -> (isConnected: Bool, name: String, battery: Int?, type: BluetoothDeviceType) {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return (false, "Unknown", nil, .unknown)
        }
        
        guard let connectedDevice = devices.first(where: { $0.isConnected() }) else {
            return (false, "Unknown", nil, .unknown)
        }
        
        let type = deviceType(for: connectedDevice)
        let battery = getBatteryLevel(for: connectedDevice)
        
        return (true, connectedDevice.name ?? "Unknown", battery, type)
    }

    func deviceType(for device: IOBluetoothDevice) -> BluetoothDeviceType {
        let major = Int(device.deviceClassMajor)
        let minor = Int(device.deviceClassMinor)
        
        switch major {
        case 0x04:
            switch minor {
            case 0x01, 0x02: return .headset
            case 0x06: return .headphones
            case 0x05: return .speaker
            default: return .headphones
            }
        case 0x05:
            let minorDevice = minor & 0x30
            
            switch minorDevice {
            case 0x10:
                return .keyboard
            case 0x20:
                return .mouse
            case 0x30:
                return .keyboard
            default:
                return .unknown
            }
        case 0x01: return .computer
        case 0x02: return .phone
        default: return .unknown
        }
    }
    
    private func getBatteryLevel(for device: IOBluetoothDevice) -> Int? {
        let keys = ["batteryLevel", "batteryPercent", "batteryLevelMain", "batteryPercentSingle"]
        
        for key in keys {
            if device.responds(to: NSSelectorFromString(key)) {
                if let value = device.value(forKey: key) {
                    var level: Int = 0
                    
                    if let dblValue = value as? Double {
                        level = Int(dblValue <= 1.0 ? dblValue * 100 : dblValue)
                    }
                    else if let intValue = value as? Int {
                        level = intValue
                    }
                    
                    if level > 0 {
                        return level
                    }
                }
            }
        }
        return getBatteryFromRegistry(for: device)
    }
    
    private func getBatteryFromRegistry(for device: IOBluetoothDevice) -> Int? {
        guard let address = device.addressString else { return nil }
        let normalizedAddr = address.replacingOccurrences(of: ":", with: "-").lowercased()
        
        let services = ["AppleDeviceManagementHIDEventService", "AppleHSBluetoothDevice", "IOBluetoothDevice"]
        
        for serviceName in services {
            let matchingDict = IOServiceMatching(serviceName)
            var iterator: io_iterator_t = 0
            
            if IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == kIOReturnSuccess {
                while case let service = IOIteratorNext(iterator), service != 0 {
                    defer { IOObjectRelease(service) }
                    
                    if let regAddr = IORegistryEntryCreateCFProperty(service, "DeviceAddress" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                        if regAddr.lowercased().replacingOccurrences(of: ":", with: "-") == normalizedAddr {
                            let batteryKeys = ["BatteryPercent", "BatteryLevel", "BatteryPercentSingle", "RemoteDeviceBatteryLevel"]
                            for key in batteryKeys {
                                if let val = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                                    return val
                                }
                            }
                        }
                    }
                }
                IOObjectRelease(iterator)
            }
        }
        return nil
    }
}
