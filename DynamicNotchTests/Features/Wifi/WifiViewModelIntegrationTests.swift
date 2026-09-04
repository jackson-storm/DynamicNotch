import XCTest
@testable import DynamicNotch

@MainActor
final class WifiViewModelIntegrationTests: XCTestCase {
    func testStartsMonitoringImmediately() {
        let monitor = FakeWifiMonitor()
        _ = makeViewModel(monitor: monitor)

        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testInitialHotspotStateProducesHotspotEvent() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: true, vpn: false)

        XCTAssertEqual(viewModel.wifiEvent, .hotspotActive)
        XCTAssertTrue(viewModel.hotspotActive)
    }

    func testNetworkTransitionsProduceExpectedEvents() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: false)

        viewModel.wifiEvent = nil
        monitor.send(wifi: true, hotspot: false, vpn: false)
        XCTAssertEqual(viewModel.wifiEvent, .wifiConnected)

        viewModel.wifiEvent = nil
        monitor.send(wifi: false, hotspot: true, vpn: false)
        XCTAssertEqual(viewModel.wifiEvent, .hotspotActive)

        viewModel.wifiEvent = nil
        monitor.send(wifi: false, hotspot: false, vpn: false)
        XCTAssertEqual(viewModel.wifiEvent, .hotspotHide)
    }

    func testSwitchingFromHotspotToWifiProducesHotspotHideThenWifiConnected() async {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: true, vpn: false)
        XCTAssertEqual(viewModel.wifiEvent, .hotspotActive)
        XCTAssertTrue(viewModel.hotspotActive)
        XCTAssertFalse(viewModel.wifiConnected)

        viewModel.wifiEvent = nil
        monitor.send(wifi: true, hotspot: false, vpn: false, wifiName: "Home Wi-Fi")

        XCTAssertEqual(viewModel.wifiEvent, .hotspotHide)
        XCTAssertFalse(viewModel.hotspotActive)
        XCTAssertTrue(viewModel.wifiConnected)
        XCTAssertEqual(viewModel.wifiName, "Home Wi-Fi")

        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(viewModel.wifiEvent, .wifiConnected)
    }

    func testConnectedNetworkNamesAreUpdatedFromMonitor() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: false)
        monitor.send(
            wifi: true,
            hotspot: false,
            vpn: false,
            wifiName: "Office Wi-Fi"
        )

        XCTAssertEqual(viewModel.wifiName, "Office Wi-Fi")

        monitor.send(wifi: false, hotspot: false, vpn: false)

        XCTAssertEqual(viewModel.wifiName, "")
    }

    func testInternetBecomingUnavailableProducesNoInternetEvent() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: true, hotspot: false, vpn: false, internetAvailable: true)

        viewModel.wifiEvent = nil
        monitor.send(wifi: false, hotspot: false, vpn: false, internetAvailable: false)

        XCTAssertEqual(viewModel.wifiEvent, .noInternetConnection)
        XCTAssertFalse(viewModel.isInternetAvailable)
        XCTAssertFalse(viewModel.wifiConnected)
        XCTAssertFalse(viewModel.hotspotActive)
    }

    func testInitialUnavailableInternetUpdatesStateWithoutShowingNotification() {
        let monitor = FakeWifiMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: false, vpn: false, internetAvailable: false)

        XCTAssertNil(viewModel.wifiEvent)
        XCTAssertFalse(viewModel.isInternetAvailable)
    }
}

private extension WifiViewModelIntegrationTests {
    func makeViewModel(monitor: FakeWifiMonitor) -> WifiViewModel {
        let suiteName = "WifiViewModelIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = ConnectivitySettingsStore(defaults: defaults)

        return WifiViewModel(
            monitor: monitor,
            settings: settings
        )
    }
}
