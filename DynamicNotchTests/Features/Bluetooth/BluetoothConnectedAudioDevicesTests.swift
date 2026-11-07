import XCTest
@testable import DynamicNotch

@MainActor
final class BluetoothConnectedAudioDevicesTests: XCTestCase {
    private struct Device: Equatable {
        let name: String
        var isConnected = false
        var isAudio = true
        var isListed = false
    }

    private func connectedAudioDevices(in devices: [Device], listReads: inout Int) -> [Device] {
        BluetoothService.connectedAudioDevices(
            in: devices,
            isConnected: { $0.isConnected },
            isAudioDevice: { $0.isAudio },
            isListedInCoreAudio: { device, _ in device.isListed },
            activeCoreAudioDevices: {
                listReads += 1
                return []
            }
        )
    }

    func testSkipsTheCoreAudioListWhenEveryDeviceReportsAConnection() {
        let devices = [
            Device(name: "AirPods", isConnected: true),
            Device(name: "Keyboard", isConnected: true, isAudio: false),
        ]
        var listReads = 0

        XCTAssertEqual(connectedAudioDevices(in: devices, listReads: &listReads), [devices[0]])
        XCTAssertEqual(listReads, 0)
    }

    func testReadsTheCoreAudioListOnceForManyDisconnectedDevices() {
        var devices = (0..<14).map { Device(name: "Paired \($0)") }
        devices[3].isListed = true
        devices[9].isListed = true
        devices[9].isAudio = false
        var listReads = 0

        XCTAssertEqual(connectedAudioDevices(in: devices, listReads: &listReads), [devices[3]])
        XCTAssertEqual(listReads, 1)
    }

    func testKeepsTheSameDevicesAsAPerDeviceCheck() {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let devices = (0..<Int.random(in: 0...12, using: &generator)).map { index in
                Device(
                    name: "Paired \(index)",
                    isConnected: Bool.random(using: &generator),
                    isAudio: Bool.random(using: &generator),
                    isListed: Bool.random(using: &generator)
                )
            }
            var listReads = 0
            let expected = devices.filter { ($0.isConnected || $0.isListed) && $0.isAudio }

            XCTAssertEqual(connectedAudioDevices(in: devices, listReads: &listReads), expected)
            XCTAssertEqual(listReads, devices.contains { !$0.isConnected } ? 1 : 0)
        }
    }

    func testPassesTheListToEachDisconnectedDevice() {
        let list = [(name: "airpodspro", uid: "a1b2c3d4e5f6output")]
        var receivedLists: [[(name: String, uid: String)]] = []

        _ = BluetoothService.connectedAudioDevices(
            in: [Device(name: "One"), Device(name: "Two"), Device(name: "Three", isConnected: true)],
            isConnected: { $0.isConnected },
            isAudioDevice: { $0.isAudio },
            isListedInCoreAudio: { _, activeDevices in
                receivedLists.append(activeDevices)
                return false
            },
            activeCoreAudioDevices: { list }
        )

        XCTAssertEqual(receivedLists.count, 2)
        XCTAssertTrue(receivedLists.allSatisfy { $0.map(\.uid) == ["a1b2c3d4e5f6output"] && $0.map(\.name) == ["airpodspro"] })
    }

    func testMatchesAnAddressInsideTheUID() {
        let list = [(name: "headphones", uid: "a1b2c3d4e5f6output")]

        XCTAssertTrue(BluetoothService.isListed(address: "a1b2c3d4e5f6", name: "", in: list))
        XCTAssertFalse(BluetoothService.isListed(address: "ffffffffffff", name: "", in: list))
    }

    func testMatchesOnlyTheWholeName() {
        let list = [(name: "airpodspro2", uid: "0011")]

        XCTAssertTrue(BluetoothService.isListed(address: "", name: "airpodspro2", in: list))
        XCTAssertFalse(BluetoothService.isListed(address: "", name: "airpodspro", in: list))
    }

    func testEmptyAddressAndNameNeverMatch() {
        let list = [(name: "", uid: ""), (name: "speaker", uid: "a1b2c3d4e5f6")]

        XCTAssertFalse(BluetoothService.isListed(address: "", name: "", in: list))
        XCTAssertFalse(BluetoothService.isListed(address: "", name: "", in: []))
    }
}
