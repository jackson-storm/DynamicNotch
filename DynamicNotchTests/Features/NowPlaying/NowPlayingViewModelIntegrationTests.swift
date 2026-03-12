import XCTest
@testable import DynamicNotch

@MainActor
final class NowPlayingViewModelIntegrationTests: XCTestCase {
    func testPublishesStartedAndStoppedEventsWhenSessionLifecycleChanges() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        XCTAssertEqual(service.startCalls, 1)
        XCTAssertNil(viewModel.snapshot)

        let snapshot = makeNowPlayingSnapshot()
        service.publish(snapshot)

        XCTAssertEqual(viewModel.snapshot, snapshot)
        XCTAssertEqual(viewModel.event, .started)
        XCTAssertTrue(viewModel.hasActiveSession)

        service.publish(nil)

        XCTAssertNil(viewModel.snapshot)
        XCTAssertEqual(viewModel.event, .stopped)
        XCTAssertFalse(viewModel.hasActiveSession)
    }

    func testPlaybackControlsSendCommandsToService() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        viewModel.previousTrack()
        viewModel.togglePlayPause()
        viewModel.nextTrack()

        XCTAssertEqual(
            service.commands,
            [.previousTrack, .togglePlayPause, .nextTrack]
        )
    }
}
