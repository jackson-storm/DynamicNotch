//
//  BluetoothViewModelTests.swift
//  DynamicNotchTests
//
//  Created by Евгений Петрукович on 6/27/26.
//

import XCTest
import Combine
@testable import DynamicNotch

private final class MockBluetoothService: BluetoothServiceProtocol, @unchecked Sendable {
    @Published var lastConnectedDevice: BluetoothAudioDevice?
    @Published var connectedDevices: [BluetoothAudioDevice] = []

    var lastConnectedDevicePublisher: AnyPublisher<BluetoothAudioDevice?, Never> {
        $lastConnectedDevice.eraseToAnyPublisher()
    }

    var connectedDevicesPublisher: AnyPublisher<[BluetoothAudioDevice], Never> {
        $connectedDevices.eraseToAnyPublisher()
    }

    let deviceConnectedEventSubject = PassthroughSubject<BluetoothAudioDevice, Never>()
    var deviceConnectedEventPublisher: AnyPublisher<BluetoothAudioDevice, Never> {
        deviceConnectedEventSubject.eraseToAnyPublisher()
    }

    var refreshCalled = false
    func refreshConnectedDeviceBatteries() {
        refreshCalled = true
    }
}

@MainActor
final class BluetoothViewModelTests: XCTestCase {
    private var mockService: MockBluetoothService!
    private var viewModel: BluetoothViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockBluetoothService()
        viewModel = BluetoothViewModel(bluetoothService: mockService)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.isConnected)
        XCTAssertEqual(viewModel.deviceName, "Unknown")
        XCTAssertNil(viewModel.batteryLevel)
        XCTAssertEqual(viewModel.deviceType, .generic)
        XCTAssertNil(viewModel.event)
    }

    func testDeviceConnectionUpdatesStateAndPublishesEvent() async {
        let device = BluetoothAudioDevice(
            name: "My AirPods Pro",
            address: "00:11:22:33:44:55",
            batteryLevel: 85,
            deviceType: .airpodsPro
        )

        // Имитируем подключение устройства
        mockService.connectedDevices = [device]

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

        mockService.connectedDevices = [device]
        mockService.lastConnectedDevice = device

        // Убеждаемся, что устройство изначально подключено
        await assertEventually {
            self.viewModel.isConnected == true
        }

        // Имитируем отключение устройства
        mockService.connectedDevices = []

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

        mockService.connectedDevices = [device]
        mockService.lastConnectedDevice = device

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
        mockService.lastConnectedDevice = updatedDevice

        await assertEventually {
            self.viewModel.batteryLevel == 90
        }

        XCTAssertEqual(viewModel.deviceName, "Beats Solo")
        XCTAssertEqual(viewModel.deviceType, .beatssolo)
    }

    func testUpdateCallsRefreshOnService() async {
        viewModel.update()
        // Wait for Task @MainActor to execute
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(mockService.refreshCalled)
    }

    func testConnectingSecondDeviceTriggersConnectedEvent() async {
        let firstDevice = BluetoothAudioDevice(
            name: "Bluetooth Speaker",
            address: "00:11:22:33:44:01",
            batteryLevel: 60,
            deviceType: .headphones
        )

        mockService.connectedDevices = [firstDevice]
        await assertEventually {
            self.viewModel.isConnected == true
        }
        XCTAssertEqual(viewModel.deviceName, "Bluetooth Speaker")

        // Reset event to nil (as would happen after HUD dismissal)
        viewModel.event = nil

        let galaxyBuds = BluetoothAudioDevice(
            name: "Galaxy Buds3 Pro",
            address: "AA:BB:CC:DD:EE:FF",
            batteryLevel: 95,
            deviceType: .headphones
        )

        // Connect a second device while the first remains connected
        mockService.connectedDevices = [firstDevice, galaxyBuds]

        await assertEventually {
            self.viewModel.event == .connected
        }

        XCTAssertEqual(viewModel.deviceName, "Galaxy Buds3 Pro")
        XCTAssertEqual(viewModel.batteryLevel, 95)
    }

    func testDeviceConnectedEventDirectlyTriggersHUD() async {
        let galaxyBuds = BluetoothAudioDevice(
            name: "Galaxy Buds3 Pro",
            address: "AA:BB:CC:DD:EE:FF",
            batteryLevel: 82,
            deviceType: .headphones
        )

        mockService.deviceConnectedEventSubject.send(galaxyBuds)

        await assertEventually {
            self.viewModel.isConnected == true && self.viewModel.event == .connected
        }

        XCTAssertEqual(viewModel.deviceName, "Galaxy Buds3 Pro")
        XCTAssertEqual(viewModel.batteryLevel, 82)
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
