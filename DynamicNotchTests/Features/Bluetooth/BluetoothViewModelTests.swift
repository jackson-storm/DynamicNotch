//
//  BluetoothViewModelTests.swift
//  DynamicNotchTests
//
//  Created by Евгений Петрукович on 6/27/26.
//

import XCTest
import Combine
@testable import DynamicNotch

@MainActor
final class BluetoothViewModelTests: XCTestCase {
    private var service: BluetoothService!
    private var viewModel: BluetoothViewModel!
    private var originalConnectedDevices: [BluetoothAudioDevice]!
    private var originalLastConnectedDevice: BluetoothAudioDevice?

    override func setUp() {
        super.setUp()
        service = BluetoothService.shared
        // Сохраняем исходное состояние синглтона, чтобы не ломать другие тесты
        originalConnectedDevices = service.connectedDevices
        originalLastConnectedDevice = service.lastConnectedDevice
    }

    override func tearDown() {
        // Восстанавливаем состояние синглтона
        service.connectedDevices = originalConnectedDevices
        service.lastConnectedDevice = originalLastConnectedDevice
        viewModel = nil
        service = nil
        super.tearDown()
    }

    func testInitialState() {
        service.connectedDevices = []
        service.lastConnectedDevice = nil

        viewModel = BluetoothViewModel(bluetoothService: service)

        XCTAssertFalse(viewModel.isConnected)
        XCTAssertEqual(viewModel.deviceName, "Unknown")
        XCTAssertNil(viewModel.batteryLevel)
        XCTAssertEqual(viewModel.deviceType, .generic)
        XCTAssertNil(viewModel.event)
    }

    func testDeviceConnectionUpdatesStateAndPublishesEvent() async {
        service.connectedDevices = []
        service.lastConnectedDevice = nil
        viewModel = BluetoothViewModel(bluetoothService: service)

        let device = BluetoothAudioDevice(
            name: "My AirPods Pro",
            address: "00:11:22:33:44:55",
            batteryLevel: 85,
            deviceType: .airpodsPro
        )

        // Имитируем подключение устройства
        service.connectedDevices = [device]

        // Ждем обновления на RunLoop.main
        await assertEventually {
            self.viewModel.isConnected == true
        }

        XCTAssertEqual(viewModel.deviceName, "My AirPods Pro")
        XCTAssertEqual(viewModel.batteryLevel, 85)
        XCTAssertEqual(viewModel.deviceType, .airpodsPro)
        XCTAssertEqual(viewModel.event, .connected)
    }

    func testDeviceDisconnectionResetsState() async {
        let device = BluetoothAudioDevice(
            name: "My AirPods Pro",
            address: "00:11:22:33:44:55",
            batteryLevel: 85,
            deviceType: .airpodsPro
        )

        service.connectedDevices = [device]
        service.lastConnectedDevice = device
        viewModel = BluetoothViewModel(bluetoothService: service)

        // Убеждаемся, что устройство изначально подключено
        await assertEventually {
            self.viewModel.isConnected == true
        }

        // Имитируем отключение устройства
        service.connectedDevices = []

        // Ждем сброса состояния
        await assertEventually {
            self.viewModel.isConnected == false
        }

        XCTAssertEqual(viewModel.deviceName, "Unknown")
        XCTAssertNil(viewModel.batteryLevel)
        XCTAssertEqual(viewModel.deviceType, .generic)
    }

    func testBatteryLevelUpdateForConnectedDevice() async {
        let device = BluetoothAudioDevice(
            name: "Beats Solo",
            address: "00:11:22:33:44:66",
            batteryLevel: 50,
            deviceType: .beatssolo
        )

        service.connectedDevices = [device]
        service.lastConnectedDevice = device
        viewModel = BluetoothViewModel(bluetoothService: service)

        await assertEventually {
            self.viewModel.isConnected == true
        }

        let updatedDevice = BluetoothAudioDevice(
            id: device.id,
            name: "Beats Solo",
            address: "00:11:22:33:44:66",
            batteryLevel: 90,
            deviceType: .beatssolo
        )

        // Имитируем обновление уровня заряда
        service.lastConnectedDevice = updatedDevice

        await assertEventually {
            self.viewModel.batteryLevel == 90
        }

        XCTAssertEqual(viewModel.deviceName, "Beats Solo")
        XCTAssertEqual(viewModel.deviceType, .beatssolo)
    }
}

// Вспомогательный хелпер для асинхронных ожиданий в тестах
private extension XCTestCase {
    func assertEventually(
        timeout: TimeInterval = 1.0,
        interval: TimeInterval = 0.05,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        XCTFail("Condition not met within \(timeout) seconds")
    }
}
