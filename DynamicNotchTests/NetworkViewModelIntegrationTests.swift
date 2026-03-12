import XCTest
@testable import DynamicNotch

@MainActor
final class NetworkViewModelIntegrationTests: XCTestCase {
    func testStartsMonitoringImmediately() {
        let monitor = FakeNetworkMonitor()
        _ = NetworkViewModel(monitor: monitor)

        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testInitialHotspotStateProducesHotspotEvent() {
        let monitor = FakeNetworkMonitor()
        let viewModel = NetworkViewModel(monitor: monitor)

        monitor.send(wifi: false, hotspot: true, vpn: false)

        XCTAssertEqual(viewModel.networkEvent, .hotspotActive)
        XCTAssertTrue(viewModel.hotspotActive)
    }

    func testNetworkTransitionsProduceExpectedEvents() {
        let monitor = FakeNetworkMonitor()
        let viewModel = NetworkViewModel(monitor: monitor)

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
}
