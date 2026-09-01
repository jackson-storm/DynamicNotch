import XCTest
@testable import DynamicNotch

@MainActor
final class VpnViewModelIntegrationTests: XCTestCase {
    func testStartsMonitoringImmediately() {
        let monitor = FakeWifiMonitor()
        _ = makeViewModel(monitor: monitor)

        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testVPNConnectionStateProducesVpnEvent() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: false)
        XCTAssertFalse(viewModel.vpnConnected)

        viewModel.vpnEvent = nil
        monitor.send(wifi: false, hotspot: false, vpn: true)

        XCTAssertEqual(viewModel.vpnEvent, .vpnConnected)
        XCTAssertTrue(viewModel.vpnConnected)
    }

    func testVPNConnectionStartDateTracksTunnelLifecycle() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: false)
        XCTAssertNil(viewModel.vpnConnectedAt)

        monitor.send(wifi: false, hotspot: false, vpn: true)
        let initialConnectionDate = viewModel.vpnConnectedAt

        XCTAssertNotNil(initialConnectionDate)

        monitor.send(wifi: false, hotspot: false, vpn: true)
        XCTAssertEqual(viewModel.vpnConnectedAt, initialConnectionDate)

        monitor.send(wifi: false, hotspot: false, vpn: false)
        XCTAssertNil(viewModel.vpnConnectedAt)
    }

    func testVPNDisconnectionStateProducesVpnEvent() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: true)
        XCTAssertTrue(viewModel.vpnConnected)

        viewModel.vpnEvent = nil
        monitor.send(wifi: false, hotspot: false, vpn: false)

        XCTAssertEqual(viewModel.vpnEvent, .vpnDisconnected)
        XCTAssertFalse(viewModel.vpnConnected)
    }
}

private extension VpnViewModelIntegrationTests {
    func makeViewModel(monitor: FakeWifiMonitor) -> VpnViewModel {
        let suiteName = "VpnViewModelIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = ConnectivitySettingsStore(defaults: defaults)

        return VpnViewModel(
            monitor: monitor,
            settings: settings
        )
    }
}
