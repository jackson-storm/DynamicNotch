import XCTest
import Combine
@testable import DynamicNotch

@MainActor
final class NotchLiveActivitySwapTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    private func makeViewModel() -> (NotchViewModel, () -> [String]) {
        let viewModel = NotchViewModel(settings: TestNotchSettings())
        TestLifetime.retain(viewModel)
        var shown: [String] = []
        viewModel.$notchModel
            .map { $0.liveActivityContent?.id ?? "nil" }
            .removeDuplicates()
            .sink { shown.append($0) }
            .store(in: &cancellables)
        return (viewModel, { shown })
    }

    // The engine paces events that arrive while it is still finishing the previous one by the
    // queue delay, so each phase waits for the queue to go idle before timing the next event.
    private func letTheQueueDrain() async {
        try? await Task.sleep(nanoseconds: 400_000_000)
    }

    func testEndingTheShownActivityMorphsStraightIntoTheNextOne() async {
        let (viewModel, shown) = makeViewModel()
        let music = TestNotchContent(id: "music", priority: 8)
        let timer = TestNotchContent(id: "timer", priority: 4)

        viewModel.send(.showLiveActivity(timer))
        viewModel.send(.showLiveActivity(music))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "music" } }
        await letTheQueueDrain()

        let before = Date()
        viewModel.send(.hideLiveActivity(id: "music"))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "timer" } }

        XCTAssertLessThan(Date().timeIntervalSince(before), 0.25, "the swap must not wait out the hide delay")
        XCTAssertEqual(Array(shown().suffix(2)), ["music", "timer"], "the island must not empty between the two")
    }

    func testAHigherPriorityActivityMorphsOverTheShownOne() async {
        let (viewModel, shown) = makeViewModel()
        let music = TestNotchContent(id: "music", priority: 8)
        let timer = TestNotchContent(id: "timer", priority: 4)

        viewModel.send(.showLiveActivity(timer))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "timer" } }

        viewModel.send(.showLiveActivity(music))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "music" } }

        XCTAssertEqual(Array(shown().suffix(2)), ["timer", "music"])
    }

    func testEndingTheLastActivityStillEmptiesTheIsland() async {
        let (viewModel, shown) = makeViewModel()
        viewModel.send(.showLiveActivity(TestNotchContent(id: "music", priority: 8)))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "music" } }

        viewModel.send(.hideLiveActivity(id: "music"))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent == nil } }

        XCTAssertEqual(Array(shown().suffix(2)), ["music", "nil"])
    }

    func testSwapCollapsesAnExpandedActivity() async {
        let (viewModel, _) = makeViewModel()
        let music = TestNotchContent(id: "music", priority: 8)
        var timer = TestNotchContent(id: "timer", priority: 4)
        timer.isExpandable = true

        viewModel.send(.showLiveActivity(music))
        viewModel.send(.showLiveActivity(timer))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "music" } }

        viewModel.send(.hideLiveActivity(id: "music"))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "timer" } }
        viewModel.expandActiveLiveActivity()
        await assertEventually { await MainActor.run { viewModel.notchModel.isLiveActivityExpanded } }

        viewModel.send(.showLiveActivity(music))
        await assertEventually { await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "music" } }
        XCTAssertFalse(viewModel.notchModel.isLiveActivityExpanded)
    }

    func testPauseHideDelayAcceptsZeroSeconds() {
        XCTAssertEqual(SettingsStoreBase.pauseHideDelayRange, 0...5)
        XCTAssertEqual(SettingsStoreBase.clampPauseHideDelay(0), 0)
        XCTAssertEqual(SettingsStoreBase.clampPauseHideDelay(-1), 0)
        XCTAssertEqual(SettingsStoreBase.clampPauseHideDelay(9), 5)
        XCTAssertEqual(SettingsStoreBase.clampTemporaryActivityDuration(0), 1, "other durations keep their 1 s floor")
    }
}
