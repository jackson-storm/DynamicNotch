import XCTest
@testable import DynamicNotch

@MainActor
final class ClipboardViewModelIntegrationTests: XCTestCase {
    func testStartMonitoringStartsMonitorOnce() {
        let monitor = FakeClipboardMonitor()
        let viewModel = ClipboardViewModel(monitor: monitor)

        viewModel.startMonitoring()
        viewModel.startMonitoring()

        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testClipboardChangePublishesSnapshotEvent() {
        let monitor = FakeClipboardMonitor()
        let viewModel = ClipboardViewModel(monitor: monitor)
        let snapshot = ClipboardSnapshot(
            kind: .link,
            title: "Link copied",
            subtitle: "example.com"
        )

        viewModel.startMonitoring()
        monitor.publish(snapshot)

        XCTAssertEqual(viewModel.latestSnapshot, snapshot)
        XCTAssertEqual(viewModel.event, .changed(snapshot))
    }

    func testStoppedMonitoringIgnoresIncomingSnapshots() {
        let monitor = FakeClipboardMonitor()
        let viewModel = ClipboardViewModel(monitor: monitor)

        viewModel.startMonitoring()
        viewModel.stopMonitoring()
        monitor.publish(.debugText)

        XCTAssertNil(viewModel.latestSnapshot)
        XCTAssertNil(viewModel.event)
        XCTAssertEqual(monitor.stopCalls, 1)
    }
}
