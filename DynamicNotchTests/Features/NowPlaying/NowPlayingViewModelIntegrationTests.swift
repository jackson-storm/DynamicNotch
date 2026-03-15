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

    func testTogglePlayPauseUpdatesCurrentSnapshotImmediately() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(makeNowPlayingSnapshot(elapsedTime: 42, playbackRate: 1))

        viewModel.togglePlayPause()

        XCTAssertEqual(service.commands, [.togglePlayPause])
        XCTAssertEqual(viewModel.snapshot?.playbackRate, 0)
        XCTAssertFalse(viewModel.snapshot?.isPlaying ?? true)
    }

    func testSeekUpdatesCurrentSnapshotImmediately() {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(service: service)
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        service.publish(makeNowPlayingSnapshot(duration: 243, elapsedTime: 42, playbackRate: 1))

        viewModel.seek(to: 120)

        XCTAssertEqual(service.commands, [.seek(120)])
        XCTAssertEqual(viewModel.snapshot?.elapsedTime, 120)
        XCTAssertEqual(viewModel.snapshot?.duration, 243)
        XCTAssertEqual(viewModel.snapshot?.playbackRate, 1)
    }
}
