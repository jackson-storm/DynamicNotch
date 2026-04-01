import Foundation
import IOBluetooth
import IOKit

private struct CoreBluetoothCacheSnapshot {
    let byAddress: [String: UUID]
    let byName: [String: UUID]
    let namesByUUID: [UUID: String]

    var hasEntries: Bool {
        !byAddress.isEmpty || !byName.isEmpty
    }

    static let empty = CoreBluetoothCacheSnapshot(byAddress: [:], byName: [:], namesByUUID: [:])
}

private struct PmsetAccessoryBatteryEntry {
    let displayName: String
    let normalizedName: String
    let level: Int
}

extension BluetoothService {
    func refreshBatteryLevelsForConnectedDevices(forceCacheRefresh: Bool = true) {
        if forceCacheRefresh {
            updateBatteryStatuses(force: true)
        }

        applyConnectedDeviceBatteryLevels()
        triggerLiveBatteryRefreshIfNeeded()
    }

    func applyConnectedDeviceBatteryLevels(triggerPmsetFallback: Bool = true) {
        guard !connectedDevices.isEmpty else {
            lastConnectedDevice = nil
            return
        }

        var updatedDevices: [BluetoothAudioDevice] = []
        for device in connectedDevices {
            let refreshedLevel = bestBatteryLevel(for: device)
            let updatedDevice = device.withBatteryLevel(refreshedLevel)
            updatedDevices.append(updatedDevice)

            if refreshedLevel != nil {
                clearMissingBatteryInfo(forName: device.name, address: device.address)
                cancelPostConnectionBatteryRefresh(for: device)
            } else {
                logMissingBatteryInfo(forName: device.name, address: device.address)
            }
        }

        connectedDevices = updatedDevices
        if let last = updatedDevices.last {
            lastConnectedDevice = last
        }

        if triggerPmsetFallback,
           updatedDevices.contains(where: { $0.batteryLevel == nil }) {
            requestPmsetFallback(reason: "missing battery after refresh")
        }
    }

    func bestBatteryLevel(for device: BluetoothAudioDevice) -> Int? {
        batteryLevelFromRegistry(forAddress: device.address)
            ?? batteryLevelFromRegistry(forName: device.name)
            ?? batteryLevelFromDefaults(forAddress: device.address)
            ?? batteryLevelFromDefaults(forName: device.name)
            ?? device.batteryLevel
    }

    func requestPmsetFallback(reason: String) {
        guard connectedDevices.contains(where: { $0.batteryLevel == nil }) else { return }
        guard !isPmsetRefreshInFlight else { return }

        let now = Date()
        if let lastPmsetRefreshDate,
           now.timeIntervalSince(lastPmsetRefreshDate) < pmsetRefreshCooldown {
            return
        }

        isPmsetRefreshInFlight = true
        print("🎧 [BluetoothAudioManager] 🔄 Triggering pmset fallback (\(reason))")
        pmsetFetchQueue.async { [weak self] in
            guard let self else { return }
            let entries = self.collectPmsetAccessoryBatteryEntries()
            DispatchQueue.main.async {
                self.handlePmsetFallbackResults(entries)
            }
        }
    }

    private func handlePmsetFallbackResults(_ entries: [PmsetAccessoryBatteryEntry]) {
        isPmsetRefreshInFlight = false
        lastPmsetRefreshDate = Date()
        guard !entries.isEmpty else { return }

        var updatedNames = batteryStatusByName
        let newlyFilled = mergePmsetEntries(entries, into: &updatedNames, logNewEntries: true)
        guard !newlyFilled.isEmpty else { return }

        batteryStatusByName = updatedNames
        applyConnectedDeviceBatteryLevels(triggerPmsetFallback: false)
    }

    func triggerLiveBatteryRefreshIfNeeded() {
        guard !connectedDevices.isEmpty else { return }
        guard connectedDevices.contains(where: { $0.batteryLevel == nil }) else { return }
        guard !isLiveBatteryRefreshInFlight else { return }

        let lookups = coreBluetoothLookups(for: connectedDevices)
        guard !lookups.isEmpty else { return }

        isLiveBatteryRefreshInFlight = true
        batteryReader.fetchBatteryLevels(for: lookups) { [weak self] results in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLiveBatteryRefreshInFlight = false
                self.handleLiveBatteryResults(results)
            }
        }
    }

    func coreBluetoothLookups(for devices: [BluetoothAudioDevice]) -> [BluetoothLEBatteryReader.Lookup] {
        let snapshot = coreBluetoothCacheSnapshot()
        guard snapshot.hasEntries else { return [] }

        var lookups: [BluetoothLEBatteryReader.Lookup] = []
        var seenUUIDs: Set<UUID> = []

        for device in devices {
            let normalizedAddress = normalizeBluetoothIdentifier(device.address)
            let normalizedName = normalizeProductName(device.name)
            guard !normalizedAddress.isEmpty || !normalizedName.isEmpty else { continue }

            let uuid = snapshot.byAddress[normalizedAddress]
                ?? snapshot.byName[normalizedName]

            guard let uuid, !seenUUIDs.contains(uuid) else { continue }
            seenUUIDs.insert(uuid)

            let canonicalName = snapshot.namesByUUID[uuid] ?? normalizedName
            lookups.append(
                .init(
                    uuid: uuid,
                    addressKey: normalizedAddress.isEmpty ? nil : normalizedAddress,
                    nameKey: canonicalName.isEmpty ? nil : canonicalName
                )
            )
        }

        return lookups
    }

    func handleLiveBatteryResults(_ results: [BluetoothLEBatteryReader.Result]) {
        guard !results.isEmpty else { return }

        var didUpdate = false

        for result in results {
            let level = clampBatteryPercentage(result.level)

            if let addressKey = result.addressKey, !addressKey.isEmpty {
                let previous = batteryStatusByAddress[addressKey] ?? -1
                if level > previous {
                    batteryStatusByAddress[addressKey] = level
                    batteryStatus[addressKey] = String(level)
                    didUpdate = true
                }
            }

            if let nameKey = result.nameKey, !nameKey.isEmpty {
                let previous = batteryStatusByName[nameKey] ?? -1
                if level > previous {
                    batteryStatusByName[nameKey] = level
                    didUpdate = true
                }
            }
        }

        guard didUpdate else { return }

        applyConnectedDeviceBatteryLevels()
    }

    func hudBatteryLevelCandidate() -> Int? {
        lastConnectedDevice?.batteryLevel
            ?? connectedDevices.last(where: { $0.batteryLevel != nil })?.batteryLevel
    }

    private func coreBluetoothCacheSnapshot() -> CoreBluetoothCacheSnapshot {
        guard let preferences = UserDefaults(suiteName: bluetoothPreferencesSuite),
              let coreCache = preferences.object(forKey: "CoreBluetoothCache") as? [String: [String: Any]] else {
            return .empty
        }

        var byAddress: [String: UUID] = [:]
        var byName: [String: UUID] = [:]
        var namesByUUID: [UUID: String] = [:]

        for (uuidString, payload) in coreCache {
            guard let uuid = UUID(uuidString: uuidString) else { continue }

            let addressKeys = ["DeviceAddress", "Address", "BD_ADDR", "device_address"]
            for key in addressKeys {
                if let value = payload[key], let normalized = normalizeBluetoothIdentifier(from: value) {
                    byAddress[normalized] = uuid
                }
            }

            if let serialValue = payload["SerialNumber"], let normalizedSerial = normalizeBluetoothIdentifier(from: serialValue) {
                byAddress[normalizedSerial] = uuid
            }

            let nameKeys = ["Name", "DeviceName", "ProductName", "Product", "device_name"]
            for key in nameKeys {
                if let value = payload[key], let normalizedName = normalizeProductName(from: value) {
                    byName[normalizedName] = uuid
                    namesByUUID[uuid] = normalizedName
                }
            }
        }

        return CoreBluetoothCacheSnapshot(byAddress: byAddress, byName: byName, namesByUUID: namesByUUID)
    }

    func normalizeBluetoothIdentifier(from value: Any) -> String? {
        if let string = value as? String {
            let normalized = normalizeBluetoothIdentifier(string)
            return normalized.isEmpty ? nil : normalized
        }

        if let data = value as? Data,
           let ascii = String(data: data, encoding: .utf8) {
            let normalized = normalizeBluetoothIdentifier(ascii)
            return normalized.isEmpty ? nil : normalized
        }

        return nil
    }

    func normalizeProductName(from value: Any) -> String? {
        if let string = value as? String {
            let normalized = normalizeProductName(string)
            return normalized.isEmpty ? nil : normalized
        }
        if let data = value as? Data,
           let ascii = String(data: data, encoding: .utf8) {
            let normalized = normalizeProductName(ascii)
            return normalized.isEmpty ? nil : normalized
        }
        return nil
    }

    @discardableResult
    private func mergePmsetEntries(
        _ entries: [PmsetAccessoryBatteryEntry],
        into names: inout [String: Int],
        logNewEntries: Bool
    ) -> [PmsetAccessoryBatteryEntry] {
        guard !entries.isEmpty else { return [] }

        var newlyFilled: [PmsetAccessoryBatteryEntry] = []

        for entry in entries {
            let clamped = clampBatteryPercentage(entry.level)
            let previous = names[entry.normalizedName]

            if previous == nil {
                newlyFilled.append(entry)
                names[entry.normalizedName] = clamped
                continue
            }

            if let previous, clamped > previous {
                names[entry.normalizedName] = clamped
            }
        }

        if logNewEntries {
            for entry in newlyFilled {
                print("🎧 [BluetoothAudioManager] ℹ️ pmset reported \(entry.level)% for \(entry.displayName)")
            }
        }

        return newlyFilled
    }

    func batteryLevelFromDefaults(forAddress address: String?) -> Int? {
        guard let address, !address.isEmpty else { return nil }
        guard let preferences = UserDefaults(suiteName: bluetoothPreferencesSuite) else { return nil }
        guard let deviceCache = preferences.object(forKey: "DeviceCache") as? [String: Any] else { return nil }

        let normalizedTarget = normalizeBluetoothIdentifier(address)
        var bestMatch: Int?

        for (key, value) in deviceCache {
            guard let payload = value as? [String: Any] else { continue }
            if matchesBluetoothIdentifier(normalizedTarget, key: key, payload: payload) {
                if let level = extractBatteryPercentage(from: payload) {
                    let clamped = clampBatteryPercentage(level)
                    bestMatch = max(bestMatch ?? clamped, clamped)
                }
            }
        }

        return bestMatch
    }

    func batteryLevelFromDefaults(forName name: String) -> Int? {
        guard !name.isEmpty else { return nil }
        guard let preferences = UserDefaults(suiteName: bluetoothPreferencesSuite) else { return nil }
        guard let deviceCache = preferences.object(forKey: "DeviceCache") as? [String: Any] else { return nil }

        var bestMatch: Int?

        for value in deviceCache.values {
            guard let payload = value as? [String: Any] else { continue }
            let candidateName = (payload["Name"] as? String) ?? (payload["DeviceName"] as? String)
            if let candidateName, candidateName.caseInsensitiveCompare(name) == .orderedSame {
                if let level = extractBatteryPercentage(from: payload) {
                    let clamped = clampBatteryPercentage(level)
                    bestMatch = max(bestMatch ?? clamped, clamped)
                }
            }
        }

        return bestMatch
    }

    func batteryLevelFromRegistry(forName name: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = normalizeProductName(trimmed)
        guard !normalized.isEmpty else { return nil }
        if let value = batteryStatusByName[normalized] {
            return clampBatteryPercentage(value)
        }
        return nil
    }

    func updateBatteryStatuses(force: Bool = false) {
        let now = Date()
        if !force, let lastBatteryStatusUpdate,
           now.timeIntervalSince(lastBatteryStatusUpdate) < batteryStatusUpdateInterval {
            return
        }

        var combinedAddressPercentages: [String: Int] = [:]
        var combinedNamePercentages: [String: Int] = [:]

        let registry = collectRegistryBatteryLevels()
        mergeBatteryLevels(into: &combinedAddressPercentages, from: registry.addresses)
        mergeBatteryLevels(into: &combinedNamePercentages, from: registry.names)

        let defaults = collectDefaultsBatteryLevels()
        mergeBatteryLevels(into: &combinedAddressPercentages, from: defaults.addresses)
        mergeBatteryLevels(into: &combinedNamePercentages, from: defaults.names)

        let profiler = collectSystemProfilerBatteryLevels()
        mergeBatteryLevels(into: &combinedAddressPercentages, from: profiler.addresses)
        mergeBatteryLevels(into: &combinedNamePercentages, from: profiler.names)

        let pmsetEntries = collectPmsetAccessoryBatteryEntries()
        mergePmsetEntries(pmsetEntries, into: &combinedNamePercentages, logNewEntries: true)

        var statuses: [String: String] = [:]
        for (key, value) in combinedAddressPercentages {
            statuses[key] = String(clampBatteryPercentage(value))
        }

        let applyUpdates = {
            self.batteryStatus = statuses
            self.batteryStatusByAddress = combinedAddressPercentages
            self.batteryStatusByName = combinedNamePercentages
            self.lastBatteryStatusUpdate = now
        }

        if Thread.isMainThread {
            applyUpdates()
        } else {
            DispatchQueue.main.sync(execute: applyUpdates)
        }
    }

    func mergeBatteryLevels(into target: inout [String: Int], from source: [String: Int]) {
        guard !source.isEmpty else { return }
        for (key, value) in source {
            guard !key.isEmpty else { continue }
            if let existing = target[key] {
                target[key] = max(existing, value)
            } else {
                target[key] = value
            }
        }
    }

    func collectRegistryBatteryLevels() -> (addresses: [String: Int], names: [String: Int]) {
        var addressPercentages: [String: Int] = [:]
        var namePercentages: [String: Int] = [:]

        var iterator = io_iterator_t()
        let matchingDict: CFDictionary = IOServiceMatching("AppleDeviceManagementHIDEventService")

        let servicePort: mach_port_t
        if #available(macOS 12.0, *) {
            servicePort = kIOMainPortDefault
        } else {
            servicePort = kIOMasterPortDefault
        }

        let kernResult = IOServiceGetMatchingServices(servicePort, matchingDict, &iterator)

        if kernResult == KERN_SUCCESS {
            var entry: io_object_t = IOIteratorNext(iterator)
            while entry != 0 {
                if let percent = IORegistryEntryCreateCFProperty(entry, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                    let normalizedPercent = clampBatteryPercentage(percent)

                    let identifierKeys = ["DeviceAddress", "SerialNumber", "BD_ADDR"]
                    for key in identifierKeys {
                        if let identifier = stringValue(forKey: key, entry: entry) {
                            let normalizedIdentifier = normalizeBluetoothIdentifier(identifier)
                            if !normalizedIdentifier.isEmpty {
                                addressPercentages[normalizedIdentifier] = max(
                                    addressPercentages[normalizedIdentifier] ?? normalizedPercent,
                                    normalizedPercent
                                )
                            }
                        }
                    }

                    let nameKeys = [
                        "Product",
                        "ProductName",
                        "DeviceName",
                        "Name",
                        "USB Product Name",
                        "Bluetooth Product Name"
                    ]

                    for key in nameKeys {
                        if let product = stringValue(forKey: key, entry: entry) {
                            let normalizedName = normalizeProductName(product)
                            if !normalizedName.isEmpty {
                                namePercentages[normalizedName] = max(
                                    namePercentages[normalizedName] ?? normalizedPercent,
                                    normalizedPercent
                                )
                            }
                        }
                    }
                }

                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }
        }

        IOObjectRelease(iterator)
        return (addressPercentages, namePercentages)
    }

    func collectDefaultsBatteryLevels() -> (addresses: [String: Int], names: [String: Int]) {
        guard let preferences = UserDefaults(suiteName: bluetoothPreferencesSuite),
              let deviceCache = preferences.object(forKey: "DeviceCache") as? [String: Any] else {
            return ([:], [:])
        }

        var addressPercentages: [String: Int] = [:]
        var namePercentages: [String: Int] = [:]

        for (key, value) in deviceCache {
            guard let payload = value as? [String: Any] else { continue }
            guard let level = extractBatteryPercentage(from: payload) else { continue }
            let clamped = clampBatteryPercentage(level)

            let normalizedKey = normalizeBluetoothIdentifier(key)
            if !normalizedKey.isEmpty {
                addressPercentages[normalizedKey] = max(addressPercentages[normalizedKey] ?? clamped, clamped)
            }

            for identifier in identifiersFromDeviceCachePayload(payload) {
                addressPercentages[identifier] = max(addressPercentages[identifier] ?? clamped, clamped)
            }

            if let name = (payload["Name"] as? String) ?? (payload["DeviceName"] as? String) {
                let normalizedName = normalizeProductName(name)
                if !normalizedName.isEmpty {
                    namePercentages[normalizedName] = max(namePercentages[normalizedName] ?? clamped, clamped)
                }
            }
        }

        return (addressPercentages, namePercentages)
    }

    func collectSystemProfilerBatteryLevels() -> (addresses: [String: Int], names: [String: Int]) {
        guard let root = systemProfilerBluetoothDictionary() else {
            return ([:], [:])
        }

        var addressPercentages: [String: Int] = [:]
        var namePercentages: [String: Int] = [:]

        if let connectedList = root["device_connected"] as? [[String: [String: Any]]] {
            for deviceGroup in connectedList {
                for (rawName, payload) in deviceGroup {
                    guard let percent = extractSystemProfilerBatteryPercentage(from: payload) else { continue }
                    let clamped = clampBatteryPercentage(percent)

                    let normalizedName = normalizeProductName(rawName)
                    if !normalizedName.isEmpty {
                        namePercentages[normalizedName] = max(namePercentages[normalizedName] ?? clamped, clamped)
                    }

                    for address in profilerAddressCandidates(from: payload) {
                        let normalizedAddress = normalizeBluetoothIdentifier(address)
                        if !normalizedAddress.isEmpty {
                            addressPercentages[normalizedAddress] = max(
                                addressPercentages[normalizedAddress] ?? clamped,
                                clamped
                            )
                        }
                    }
                }
            }
        }

        return (addressPercentages, namePercentages)
    }

    private func collectPmsetAccessoryBatteryEntries() -> [PmsetAccessoryBatteryEntry] {
        let process = Process()
        process.launchPath = "/usr/bin/pmset"
        process.arguments = ["-g", "accps"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return []
        }
        guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else {
            return []
        }

        guard let regex = try? NSRegularExpression(
            pattern: #"^\s*-\s*(.+?)\s*(?:\(.+?\))?\s+(\d+)\s*%"#,
            options: [.anchorsMatchLines]
        ) else {
            return []
        }

        var entries: [PmsetAccessoryBatteryEntry] = []
        let nsOutput = output as NSString
        let range = NSRange(location: 0, length: nsOutput.length)

        regex.enumerateMatches(in: output, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges >= 3 else { return }

            let rawName = nsOutput
                .substring(with: match.range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let percentString = nsOutput.substring(with: match.range(at: 2))

            guard !rawName.isEmpty, let level = Int(percentString) else { return }

            let normalizedName = normalizeProductName(rawName)
            guard !normalizedName.isEmpty else { return }
            if normalizedName.hasPrefix("internalbattery") {
                return
            }

            entries.append(
                PmsetAccessoryBatteryEntry(
                    displayName: rawName,
                    normalizedName: normalizedName,
                    level: level
                )
            )
        }

        return entries
    }

    func identifiersFromDeviceCachePayload(_ payload: [String: Any]) -> [String] {
        var identifiers: Set<String> = []
        let candidateKeys = ["DeviceAddress", "Address", "BD_ADDR", "SerialNumber"]

        for key in candidateKeys {
            if let value = payload[key] as? String {
                let normalized = normalizeBluetoothIdentifier(value)
                if !normalized.isEmpty {
                    identifiers.insert(normalized)
                }
            } else if let data = payload[key] as? Data,
                      let ascii = String(data: data, encoding: .utf8) {
                let normalized = normalizeBluetoothIdentifier(ascii)
                if !normalized.isEmpty {
                    identifiers.insert(normalized)
                }
            }
        }

        return Array(identifiers)
    }

    func systemProfilerBluetoothDictionary() -> [String: Any]? {
        let process = Process()
        process.launchPath = "/usr/sbin/system_profiler"
        process.arguments = ["SPBluetoothDataType", "-json"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }
        guard !data.isEmpty else { return nil }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = jsonObject["SPBluetoothDataType"] as? [[String: Any]],
              let root = entries.first else {
            return nil
        }

        return root
    }

    func extractSystemProfilerBatteryPercentage(from payload: [String: Any]) -> Int? {
        let preferredKeys = [
            "device_batteryLevelCase",
            "device_batteryLevelLeft",
            "device_batteryLevelRight",
            "device_batteryLevelMain",
            "device_batteryLevel",
            "device_batteryLevelCombined",
            "device_batteryPercentCombined",
            "Left Battery Level",
            "Right Battery Level",
            "Battery Level",
            "BatteryPercent"
        ]

        var values: [Int] = []

        for key in preferredKeys {
            if let raw = payload[key], let converted = convertToBatteryPercentage(raw) {
                values.append(converted)
            }
        }

        if values.isEmpty {
            for (key, raw) in payload where key.lowercased().contains("battery") {
                if let converted = convertToBatteryPercentage(raw) {
                    values.append(converted)
                }
            }
        }

        let validValues = values.filter { $0 >= 0 }
        return validValues.max()
    }

    func profilerAddressCandidates(from payload: [String: Any]) -> [String] {
        var addresses: Set<String> = []
        let keys = [
            "device_address",
            "device_mac_address",
            "device_serial_num",
            "device_serialNumber",
            "device_serial_number"
        ]

        for key in keys {
            if let value = payload[key] as? String, !value.isEmpty {
                addresses.insert(value)
            } else if let data = payload[key] as? Data,
                      let ascii = String(data: data, encoding: .utf8), !ascii.isEmpty {
                addresses.insert(ascii)
            }
        }

        return Array(addresses)
    }

    func batteryLevelFromRegistry(forAddress address: String?) -> Int? {
        guard let address, !address.isEmpty else { return nil }
        let normalized = normalizeBluetoothIdentifier(address)
        if let value = batteryStatusByAddress[normalized] {
            return clampBatteryPercentage(value)
        }
        if let storedValue = batteryStatus[normalized], let value = Int(storedValue) {
            return clampBatteryPercentage(value)
        }
        return nil
    }

    func extractBatteryPercentage(from payload: [String: Any]) -> Int? {
        let keys = [
            "BatteryPercent",
            "BatteryPercentCase",
            "BatteryPercentLeft",
            "BatteryPercentRight",
            "BatteryPercentSingle",
            "BatteryPercentCombined",
            "BatteryPercentMain",
            "device_batteryLevelLeft",
            "device_batteryLevelRight",
            "device_batteryLevelMain",
            "Left Battery Level",
            "Right Battery Level"
        ]

        var values: [Int] = []

        for key in keys {
            guard let raw = payload[key] else { continue }
            if let converted = convertToBatteryPercentage(raw) {
                values.append(converted)
            }
        }

        if values.isEmpty,
           let services = payload["Services"] as? [[String: Any]] {
            for service in services {
                if let serviceValues = service["BatteryPercentages"] as? [String: Any] {
                    for value in serviceValues.values {
                        if let converted = convertToBatteryPercentage(value) {
                            values.append(converted)
                        }
                    }
                }
            }
        }

        return values.max()
    }

    func convertToBatteryPercentage(_ value: Any) -> Int? {
        if let number = value as? Int {
            if number == 1 {
                return 100
            }
            return number
        }
        if let number = value as? Double {
            if number <= 1.0 {
                return Int(number * 100)
            }
            return Int(number)
        }
        if let string = value as? String {
            let trimmed = string.replacingOccurrences(of: "%", with: "")
            if let doubleValue = Double(trimmed) {
                if doubleValue <= 1.0 {
                    return Int(doubleValue * 100)
                }
                return Int(doubleValue)
            }
        }

        return nil
    }

    func clampBatteryPercentage(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }

    func matchesBluetoothIdentifier(_ normalizedTarget: String, key: String, payload: [String: Any]) -> Bool {
        if normalizeBluetoothIdentifier(key) == normalizedTarget {
            return true
        }

        let candidateFields: [String?] = [
            payload["DeviceAddress"] as? String,
            payload["Address"] as? String,
            payload["BD_ADDR"] as? String,
            payload["SerialNumber"] as? String
        ]

        for field in candidateFields {
            if let field, normalizeBluetoothIdentifier(field) == normalizedTarget {
                return true
            }
        }

        if let deviceAddressData = payload["DeviceAddress"] as? Data,
           let ascii = String(data: deviceAddressData, encoding: .utf8),
           normalizeBluetoothIdentifier(ascii) == normalizedTarget {
            return true
        }

        if let addressData = payload["BD_ADDR"] as? Data,
           let ascii = String(data: addressData, encoding: .utf8),
           normalizeBluetoothIdentifier(ascii) == normalizedTarget {
            return true
        }

        if let serialData = payload["SerialNumber"] as? Data,
           let ascii = String(data: serialData, encoding: .utf8),
           normalizeBluetoothIdentifier(ascii) == normalizedTarget {
            return true
        }

        return false
    }

    func logMissingBatteryInfo(for device: IOBluetoothDevice) {
        let name = device.name ?? ""
        let address = device.addressString ?? ""
        logMissingBatteryInfo(forName: name, address: address)
    }

    func clearMissingBatteryInfo(for device: IOBluetoothDevice) {
        let name = device.name ?? ""
        let address = device.addressString ?? ""
        clearMissingBatteryInfo(forName: name, address: address)
    }

    func logMissingBatteryInfo(forName name: String, address: String) {
        let key = missingBatteryKey(name: name, address: address)
        guard !missingBatteryLog.contains(key) else { return }
        missingBatteryLog.insert(key)

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        let displayName = trimmedName.isEmpty ? "unknown device" : trimmedName
        let isUnknownAddress = trimmedAddress.caseInsensitiveCompare("unknown") == .orderedSame
        let displayAddress = (trimmedAddress.isEmpty || isUnknownAddress) ? "N/A" : trimmedAddress
        print("🎧 [BluetoothAudioManager] ⚠️ Battery percentage unavailable for \(displayName) (\(displayAddress))")
    }

    func clearMissingBatteryInfo(forName name: String, address: String) {
        let key = missingBatteryKey(name: name, address: address)
        missingBatteryLog.remove(key)
    }

    func missingBatteryKey(name: String, address: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedName = normalizeProductName(trimmedName)
        let isUnknownAddress = trimmedAddress.caseInsensitiveCompare("unknown") == .orderedSame
        let normalizedAddress = (trimmedAddress.isEmpty || isUnknownAddress) ? "" : normalizeBluetoothIdentifier(trimmedAddress)

        if normalizedName.isEmpty && normalizedAddress.isEmpty {
            return "unknown"
        }

        return normalizedName + "#" + normalizedAddress
    }

    func stringValue(forKey key: String, entry: io_object_t) -> String? {
        guard let unmanaged = IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }

        let value = unmanaged.takeRetainedValue()

        if let string = value as? String, !string.isEmpty {
            return string
        }

        if let data = value as? Data, let ascii = String(data: data, encoding: .utf8), !ascii.isEmpty {
            return ascii
        }

        return nil
    }

    func cancelHUDBatteryWait(for device: BluetoothAudioDevice) {
        let cancelBlock = { [weak self] in
            guard let self else { return }
            self.hudBatteryWaitTasks[device.id]?.cancel()
            self.hudBatteryWaitTasks.removeValue(forKey: device.id)
        }

        if Thread.isMainThread {
            cancelBlock()
        } else {
            DispatchQueue.main.async(execute: cancelBlock)
        }
    }

    func schedulePostConnectionBatteryRefreshes(for device: BluetoothAudioDevice) {
        cancelPostConnectionBatteryRefresh(for: device)

        let task = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }

            for delay in self.postConnectionBatteryRetryDelays {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }

                let shouldContinue = await MainActor.run { () -> Bool in
                    guard let refreshedDevice = self.connectedDevices.first(where: { $0.id == device.id }) else {
                        return false
                    }
                    guard refreshedDevice.batteryLevel == nil else {
                        return false
                    }

                    self.refreshConnectedDeviceBatteries()
                    return true
                }

                guard shouldContinue else { break }
            }

            await MainActor.run {
                self.cancelPostConnectionBatteryRefresh(for: device)
            }
        }

        postConnectionBatteryRetryTasks[device.id] = task
    }

    func cancelPostConnectionBatteryRefresh(for device: BluetoothAudioDevice) {
        let cancelBlock = { [weak self] in
            guard let self else { return }
            self.postConnectionBatteryRetryTasks[device.id]?.cancel()
            self.postConnectionBatteryRetryTasks.removeValue(forKey: device.id)
        }

        if Thread.isMainThread {
            cancelBlock()
        } else {
            DispatchQueue.main.async(execute: cancelBlock)
        }
    }

    func normalizeBluetoothIdentifier(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    func normalizeProductName(_ name: String) -> String {
        let components = name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        return components.joined()
    }
}
