import XCTest
@testable import DynamicNotch

@MainActor
final class NetworkViewModelIntegrationTests: XCTestCase {
    func testStartsMonitoringImmediately() {
        let monitor = FakeNetworkMonitor()
        _ = makeViewModel(monitor: monitor)

        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testInitialHotspotStateProducesHotspotEvent() {
        let monitor = FakeNetworkMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: true, vpn: false)

        XCTAssertEqual(viewModel.networkEvent, .hotspotActive)
        XCTAssertTrue(viewModel.hotspotActive)
    }

    func testNetworkTransitionsProduceExpectedEvents() {
        let monitor = FakeNetworkMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: false)

        viewModel.networkEvent = nil
        monitor.send(wifi: true, hotspot: false, vpn: false)
        XCTAssertEqual(viewModel.networkEvent, .wifiConnected)

        viewModel.networkEvent = nil
        monitor.send(wifi: true, hotspot: false, vpn: true)
        XCTAssertEqual(viewModel.networkEvent, .vpnConnected)

        viewModel.networkEvent = nil
        monitor.send(wifi: false, hotspot: true, vpn: true)
        XCTAssertEqual(viewModel.networkEvent, .hotspotActive)

        viewModel.networkEvent = nil
        monitor.send(wifi: false, hotspot: false, vpn: true)
        XCTAssertEqual(viewModel.networkEvent, .hotspotHide)
    }

    func testConnectedNetworkNamesAreUpdatedFromMonitor() {
        let monitor = FakeNetworkMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: false)
        monitor.send(
            wifi: true,
            hotspot: false,
            vpn: true,
            wifiName: "Office Wi-Fi",
            vpnName: "Work VPN"
        )

        XCTAssertEqual(viewModel.wifiName, "Office Wi-Fi")
        XCTAssertEqual(viewModel.vpnName, "Work VPN")

        monitor.send(wifi: false, hotspot: false, vpn: false)

        XCTAssertEqual(viewModel.wifiName, "")
        XCTAssertEqual(viewModel.vpnName, "")
    }

    func testVPNConnectionStartDateTracksTunnelLifecycle() {
        let monitor = FakeNetworkMonitor()
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
}

private extension NetworkViewModelIntegrationTests {
    func makeViewModel(monitor: FakeNetworkMonitor) -> NetworkViewModel {
        let suiteName = "NetworkViewModelIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = ConnectivitySettingsStore(defaults: defaults)
        settings.isOnlyNotifyOnNetworkChangeEnabled = false

        return NetworkViewModel(
            monitor: monitor,
            settings: settings
        )
    }
}
