import Foundation
import CoreBluetooth

final class BluetoothLEBatteryReader: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    struct Lookup {
        let uuid: UUID
        let addressKey: String?
        let nameKey: String?
    }

    struct Result {
        let uuid: UUID
        let level: Int
        let addressKey: String?
        let nameKey: String?
    }

    private enum State {
        case idle
        case requesting
    }

    private static let batteryServiceUUID = CBUUID(string: "180F")
    private static let batteryCharacteristicUUID = CBUUID(string: "2A19")

    private let timeoutInterval: TimeInterval = 6.0

    private var central: CBCentralManager!
    private var state: State = .idle
    private var pendingLookups: [Lookup] = []
    private var lookupByUUID: [UUID: Lookup] = [:]
    private var completion: (([Result]) -> Void)?
    private var pendingPeripherals: [UUID: CBPeripheral] = [:]
    private var results: [UUID: Result] = [:]
    private var missingUUIDs: Set<UUID> = []
    private var timeoutWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func fetchBatteryLevels(for lookups: [Lookup], completion: @escaping ([Result]) -> Void) {
        guard !lookups.isEmpty else {
            completion([])
            return
        }

        guard state == .idle else {
            completion([])
            return
        }

        state = .requesting
        pendingLookups = lookups
        lookupByUUID = Dictionary(uniqueKeysWithValues: lookups.map { ($0.uuid, $0) })
        self.completion = completion
        results.removeAll()
        pendingPeripherals.removeAll()
        missingUUIDs = Set(lookups.map { $0.uuid })

        switch central.state {
        case .poweredOn:
            startRequest()
        case .unauthorized, .unsupported, .poweredOff:
            complete(with: [])
        default:
            break
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard state == .requesting else { return }

        switch central.state {
        case .poweredOn:
            startRequest()
        case .unauthorized, .unsupported, .poweredOff:
            complete(with: [])
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([Self.batteryServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        markPeripheralFinished(peripheral.identifier)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard state == .requesting else { return }
        markPeripheralFinished(peripheral.identifier)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard state == .requesting else { return }
        guard missingUUIDs.contains(peripheral.identifier) else { return }

        missingUUIDs.remove(peripheral.identifier)
        configurePeripheral(peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard state == .requesting else { return }

        if let error {
            print("🎧 [BluetoothLEBatteryReader] Service discovery failed: \(error.localizedDescription)")
            markPeripheralFinished(peripheral.identifier)
            return
        }

        guard let service = peripheral.services?.first(where: { $0.uuid == Self.batteryServiceUUID }) else {
            markPeripheralFinished(peripheral.identifier)
            return
        }

        peripheral.discoverCharacteristics([Self.batteryCharacteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard state == .requesting else { return }

        if let error {
            print("🎧 [BluetoothLEBatteryReader] Characteristic discovery failed: \(error.localizedDescription)")
            markPeripheralFinished(peripheral.identifier)
            return
        }

        guard let characteristic = service.characteristics?.first(where: { $0.uuid == Self.batteryCharacteristicUUID }) else {
            markPeripheralFinished(peripheral.identifier)
            return
        }

        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard state == .requesting else { return }

        defer { markPeripheralFinished(peripheral.identifier) }

        if let error {
            print("🎧 [BluetoothLEBatteryReader] Battery read failed: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value,
              let byte = data.first,
              let lookup = lookupByUUID[peripheral.identifier] else {
            return
        }

        let level = Int(byte)
        results[peripheral.identifier] = Result(
            uuid: peripheral.identifier,
            level: level,
            addressKey: lookup.addressKey,
            nameKey: lookup.nameKey
        )
    }

    private func startRequest() {
        central.stopScan()

        let identifiers = Array(missingUUIDs)
        if !identifiers.isEmpty {
            let peripherals = central.retrievePeripherals(withIdentifiers: identifiers)
            for peripheral in peripherals {
                missingUUIDs.remove(peripheral.identifier)
                configurePeripheral(peripheral)
            }
        }

        let connectedPeripherals = central.retrieveConnectedPeripherals(withServices: [Self.batteryServiceUUID])
        for peripheral in connectedPeripherals where missingUUIDs.contains(peripheral.identifier) {
            missingUUIDs.remove(peripheral.identifier)
            configurePeripheral(peripheral)
        }

        if !missingUUIDs.isEmpty {
            central.scanForPeripherals(
                withServices: [Self.batteryServiceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        }

        if pendingPeripherals.isEmpty && missingUUIDs.isEmpty {
            complete(with: Array(results.values))
            return
        }

        scheduleTimeout()
    }

    private func configurePeripheral(_ peripheral: CBPeripheral) {
        pendingPeripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self

        switch peripheral.state {
        case .connected:
            peripheral.discoverServices([Self.batteryServiceUUID])
        default:
            central.connect(peripheral, options: nil)
        }
    }

    private func markPeripheralFinished(_ identifier: UUID) {
        pendingPeripherals.removeValue(forKey: identifier)
        missingUUIDs.remove(identifier)

        if missingUUIDs.isEmpty {
            central.stopScan()
        }

        if pendingPeripherals.isEmpty && missingUUIDs.isEmpty {
            complete(with: Array(results.values))
        }
    }

    private func scheduleTimeout() {
        cancelTimeout()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.complete(with: Array(self.results.values))
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: workItem)
    }

    private func cancelTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }

    private func complete(with results: [Result]) {
        guard state == .requesting else { return }
        cancelTimeout()
        central.stopScan()
        state = .idle

        pendingPeripherals.removeAll()
        missingUUIDs.removeAll()
        pendingLookups.removeAll()
        lookupByUUID.removeAll()

        let completion = self.completion
        self.completion = nil
        self.results.removeAll()

        completion?(results)
    }
}
