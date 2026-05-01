import XCTest
@testable import DynamicNotch

@MainActor
final class ScreenRecordingViewModelIntegrationTests: XCTestCase {
    func testStartMonitoringStartsUnderlyingMonitorOnlyOnce() {
        let monitor = FakeScreenRecordingMonitor()
        let viewModel = ScreenRecordingViewModel(monitor: monitor)
        TestLifetime.retain(viewModel)

        viewModel.startMonitoring()
        viewModel.startMonitoring()

        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testPublishingRecordingStateEmitsStartedAndStoppedEvents() {
        let monitor = FakeScreenRecordingMonitor()
        let viewModel = ScreenRecordingViewModel(monitor: monitor)
        TestLifetime.retain(viewModel)

        viewModel.startMonitoring()
        monitor.publish(isRecording: true)

        XCTAssertTrue(viewModel.isRecording)
        XCTAssertEqual(viewModel.event, .started)

        monitor.publish(isRecording: false)

        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.event, .stopped)
    }

    func testStopMonitoringClearsRecordingState() {
        let monitor = FakeScreenRecordingMonitor()
        let viewModel = ScreenRecordingViewModel(monitor: monitor)
        TestLifetime.retain(viewModel)

        viewModel.startMonitoring()
        monitor.publish(isRecording: true)
        viewModel.stopMonitoring()

        XCTAssertEqual(monitor.stopCalls, 1)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.event, .stopped)
    }
}
