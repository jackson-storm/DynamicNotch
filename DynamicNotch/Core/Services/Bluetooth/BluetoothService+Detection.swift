import Foundation
import IOBluetooth

extension BluetoothService {
    // MARK: - Device Detection Helpers

    func isAudioDevice(_ device: IOBluetoothDevice) -> Bool {
        let audioServiceUUID = IOBluetoothSDPUUID(uuid16: 0x110B)
        let headsetServiceUUID = IOBluetoothSDPUUID(uuid16: 0x1108)
        let handsfreeServiceUUID = IOBluetoothSDPUUID(uuid16: 0x111E)

        if device.getServiceRecord(for: audioServiceUUID) != nil {
            return true
        }
        if device.getServiceRecord(for: headsetServiceUUID) != nil {
            return true
        }
        if device.getServiceRecord(for: handsfreeServiceUUID) != nil {
            return true
        }

        let deviceClass = device.classOfDevice
        let majorClass = (deviceClass >> 8) & 0x1F
        let audioVideoMajorClass: UInt32 = 0x04

        return majorClass == audioVideoMajorClass
    }

    func createBluetoothAudioDevice(from device: IOBluetoothDevice) -> BluetoothAudioDevice? {
        let name = device.name ?? "Bluetooth Device"
        let address = device.addressString ?? "Unknown"
        let batteryLevel = getBatteryLevel(from: device)
        let deviceType = detectDeviceType(from: device, name: name)

        return BluetoothAudioDevice(
            name: name,
            address: address,
            batteryLevel: batteryLevel,
            deviceType: deviceType
        )
    }

    func getBatteryLevel(from device: IOBluetoothDevice) -> Int? {
        updateBatteryStatuses()

        if let level = batteryLevelFromRegistry(forAddress: device.addressString) {
            clearMissingBatteryInfo(for: device)
            return level
        }

        if let name = device.name, let level = batteryLevelFromRegistry(forName: name) {
            clearMissingBatteryInfo(for: device)
            return level
        }

        if let level = batteryLevelFromDefaults(forAddress: device.addressString) {
            clearMissingBatteryInfo(for: device)
            return level
        }

        if let name = device.name, let level = batteryLevelFromDefaults(forName: name) {
            clearMissingBatteryInfo(for: device)
            return level
        }

        logMissingBatteryInfo(for: device)
        return nil
    }

    // MARK: - PID-based Device Detection

    func extractUInt16(from payload: [String: Any], keys: [String]) -> UInt16? {
        for key in keys {
            guard let raw = payload[key] else { continue }

            if let number = raw as? NSNumber {
                return UInt16(truncatingIfNeeded: number.uint16Value)
            }
            if let intValue = raw as? Int {
                return UInt16(truncatingIfNeeded: intValue)
            }
            if let string = raw as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if trimmed.hasPrefix("0x") {
                    let hex = trimmed.dropFirst(2)
                    if let value = UInt16(hex, radix: 16) { return value }
                } else if let value = UInt16(trimmed, radix: 10) {
                    return value
                }
            }
        }

        return nil
    }

    func deepSearchUInt16(in value: Any, predicate: (String) -> Bool) -> UInt16? {
        if let dict = value as? [String: Any] {
            for (key, entry) in dict {
                if predicate(key) {
                    if let found = extractUInt16(from: dict, keys: [key]) {
                        return found
                    }
                    if let number = entry as? NSNumber { return UInt16(truncatingIfNeeded: number.uint16Value) }
                    if let intValue = entry as? Int { return UInt16(truncatingIfNeeded: intValue) }
                    if let string = entry as? String {
                        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if trimmed.hasPrefix("0x"), let value = UInt16(trimmed.dropFirst(2), radix: 16) {
                            return value
                        }
                        if let value = UInt16(trimmed, radix: 10) {
                            return value
                        }
                    }
                }
            }

            for entry in dict.values {
                if let found = deepSearchUInt16(in: entry, predicate: predicate) { return found }
            }
            return nil
        }

        if let array = value as? [Any] {
            for entry in array {
                if let found = deepSearchUInt16(in: entry, predicate: predicate) { return found }
            }
        }

        return nil
    }

    func vendorProductIDsFromSystemProfiler(forNormalizedAddress target: String) -> (vendor: UInt16, product: UInt16)? {
        guard !target.isEmpty else { return nil }
        guard let root = systemProfilerBluetoothDictionary() else { return nil }
        guard let deviceConnected = root["device_connected"] as? [Any] else { return nil }

        func pidFromPayload(_ payload: [String: Any]) -> UInt16? {
            if let raw = payload["device_productID"] as? String {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if trimmed.hasPrefix("0x"), let value = UInt16(trimmed.dropFirst(2), radix: 16) { return value }
                if let value = UInt16(trimmed, radix: 16) { return value }
            }

            let productKeys = [
                "device_productID", "ProductID", "product_id", "productID",
                "DeviceProductID", "ProductId", "Product ID"
            ]

            return extractUInt16(from: payload, keys: productKeys)
                ?? deepSearchUInt16(in: payload) { $0.lowercased().contains("productid") }
        }

        func vidFromPayload(_ payload: [String: Any]) -> UInt16? {
            let vendorKeys = [
                "device_vendorID", "VendorID", "vendor_id", "vendorID",
                "DeviceVendorID", "VendorId", "Vendor ID"
            ]

            return extractUInt16(from: payload, keys: vendorKeys)
                ?? deepSearchUInt16(in: payload) { $0.lowercased().contains("vendorid") }
        }

        for item in deviceConnected {
            guard let dict = item as? [String: Any],
                  let nameKey = dict.keys.first,
                  let infoAny = dict[nameKey],
                  let payload = infoAny as? [String: Any] else {
                continue
            }

            if let address = payload["device_address"] as? String {
                if normalizeBluetoothIdentifier(address) != target { continue }
            } else {
                let candidates = profilerAddressCandidates(from: payload).map(normalizeBluetoothIdentifier)
                if !candidates.contains(target) { continue }
            }

            if let pid = pidFromPayload(payload) {
                if let vid = vidFromPayload(payload) {
                    return (vendor: vid, product: pid)
                }
                if devicePIDMap[pid] != nil {
                    return (vendor: appleVendorID, product: pid)
                }
            }
        }

        return nil
    }

    func vendorProductIDs(for device: IOBluetoothDevice) -> (vendor: UInt16, product: UInt16)? {
        guard let preferences = UserDefaults(suiteName: bluetoothPreferencesSuite),
              let deviceCache = preferences.object(forKey: "DeviceCache") as? [String: Any] else {
            return nil
        }

        let target = normalizeBluetoothIdentifier(device.addressString ?? "")
        guard !target.isEmpty else { return nil }

        let vendorKeys = [
            "VendorID", "vendor_id", "vendorID",
            "device_vendorID", "DeviceVendorID", "device_vendor_id",
            "device_vendorId", "DeviceVendorId",
            "VendorId", "Vendor ID",
            "VendorIDSource", "VendorIDSourceLocal", "VendorIDSourceRemote"
        ]
        let productKeys = [
            "ProductID", "product_id", "productID",
            "device_productID", "DeviceProductID", "device_product_id",
            "device_productId", "DeviceProductId",
            "ProductId", "Product ID",
            "ProductIDSource", "ProductIDSourceLocal", "ProductIDSourceRemote"
        ]

        for (key, value) in deviceCache {
            guard let payload = value as? [String: Any] else { continue }
            if matchesBluetoothIdentifier(target, key: key, payload: payload) {
                let vendor = extractUInt16(from: payload, keys: vendorKeys)
                    ?? deepSearchUInt16(in: payload) { $0.lowercased().contains("vendorid") }
                let product = extractUInt16(from: payload, keys: productKeys)
                    ?? deepSearchUInt16(in: payload) { $0.lowercased().contains("productid") }

                if let product {
                    if let vendor {
                        return (vendor: vendor, product: product)
                    }
                    if devicePIDMap[product] != nil {
                        return (vendor: appleVendorID, product: product)
                    }
                }
            }
        }

        if let coreCache = preferences.object(forKey: "CoreBluetoothCache") as? [String: [String: Any]] {
            for payload in coreCache.values {
                if let addressValue = payload["DeviceAddress"]
                    ?? payload["Address"]
                    ?? payload["BD_ADDR"]
                    ?? payload["device_address"],
                   let address = normalizeBluetoothIdentifier(from: addressValue),
                   address == target {
                    let vendor = extractUInt16(from: payload, keys: vendorKeys)
                        ?? deepSearchUInt16(in: payload) { $0.lowercased().contains("vendorid") }
                    let product = extractUInt16(from: payload, keys: productKeys)
                        ?? deepSearchUInt16(in: payload) { $0.lowercased().contains("productid") }

                    if let product {
                        if let vendor {
                            return (vendor: vendor, product: product)
                        }
                        if devicePIDMap[product] != nil {
                            return (vendor: appleVendorID, product: product)
                        }
                    }
                }
            }
        }

        if let fromProfiler = vendorProductIDsFromSystemProfiler(forNormalizedAddress: target) {
            return fromProfiler
        }

        return nil
    }

    func airPodsTypeFromPID(_ device: IOBluetoothDevice) -> BluetoothAudioDeviceType? {
        if let ids = vendorProductIDs(for: device) {
            return devicePIDMap[ids.product]
        }
        return nil
    }

    func detectDeviceType(from device: IOBluetoothDevice, name: String) -> BluetoothAudioDeviceType {
        let lowercaseName = name.lowercased()

        if let pidBasedType = airPodsTypeFromPID(device) {
            return pidBasedType
        }

        if lowercaseName.contains("airpods") {
            if lowercaseName.contains("max") {
                return .airpodsMax
            } else if lowercaseName.contains("pro") {
                if lowercaseName.contains("3") || lowercaseName.contains("gen 3") || lowercaseName.contains("gen3") {
                    return .airpodsPro3
                }
                return .airpodsPro
            } else if lowercaseName.contains("gen 4")
                        || lowercaseName.contains("gen4")
                        || lowercaseName.contains("4th")
                        || lowercaseName.contains("airpods 4")
                        || lowercaseName.contains("airpods4") {
                return .airpodsGen4
            } else if lowercaseName.contains("gen 3")
                        || lowercaseName.contains("gen3")
                        || lowercaseName.contains("3rd")
                        || lowercaseName.contains("third")
                        || lowercaseName.contains("airpods 3")
                        || lowercaseName.contains("airpods3") {
                return .airpodsGen3
            }
            return .airpods
        }

        if lowercaseName.contains("beats") {
            if lowercaseName.contains("studio") {
                return .beatsstudio
            }
            if lowercaseName.contains("solo") {
                return .beatssolo
            }
            return .beatssolo
        } else if lowercaseName.contains("speaker") || lowercaseName.contains("boombox") {
            return .speaker
        } else if lowercaseName.contains("headphone") || lowercaseName.contains("headset")
                    || lowercaseName.contains("buds") || lowercaseName.contains("earbuds") {
            return .headphones
        }

        let deviceClass = device.classOfDevice
        let minorClass = (deviceClass >> 2) & 0x3F

        switch minorClass {
        case 0x01: return .headphones
        case 0x02: return .headphones
        case 0x06: return .headphones
        case 0x08: return .speaker
        case 0x0C: return .speaker
        default: return .generic
        }
    }
}
