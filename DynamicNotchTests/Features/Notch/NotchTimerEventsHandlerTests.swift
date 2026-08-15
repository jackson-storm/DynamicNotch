import XCTest
@testable import DynamicNotch

@MainActor
final class NotchTimerEventsHandlerTests: XCTestCase {
    func testRunningTimerShowsLiveActivity() async {
        let context = makeContext()

        context.monitor.publish(makeSnapshot(isPaused: false, remaining: 90))
        context.handler.handleTimer(context.timerViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.timer.id
            }
        }
    }

    func testPausedTimerKeepsVisibleLiveActivity() async {
        let context = makeContext()

        context.monitor.publish(makeSnapshot(isPaused: false, remaining: 90))
        context.handler.handleTimer(context.timerViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.timer.id
            }
        }

        context.monitor.publish(makeSnapshot(isPaused: true, remaining: 90))
        context.handler.handleTimer(context.timerViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.timer.id
            }
        }
    }

    func testDisabledTimerLiveActivityDoesNotShowNotchContent() async {
        let context = makeContext()
        context.settingsViewModel.mediaAndFiles.isTimerLiveActivityEnabled = false

        context.monitor.publish(makeSnapshot(isPaused: false, remaining: 90))
        context.handler.handleTimer(context.timerViewModel.event ?? .started)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let liveActivityID = await MainActor.run {
            context.notchViewModel.notchModel.liveActivityContent?.id
        }
        XCTAssertNil(liveActivityID)
    }

    func testSystemTimerHasWindowLinkAndLocalTimerDoesNot() {
        let context = makeContext()
        let systemContent = TimerNotchContent(source: .system(context.timerViewModel))
        let localContent = TimerNotchContent(source: .local(LocalTimerViewModel()))

        XCTAssertNotNil(systemContent.windowLink)
        XCTAssertNil(localContent.windowLink)
    }

    func testLocalTimerFinishedResetsState() async {
        let localTimerViewModel = LocalTimerViewModel()
        localTimerViewModel.start(hours: 0, minutes: 0, seconds: 1)
        XCTAssertEqual(localTimerViewModel.state, .running)

        // Wait slightly over 1 second for local timer to finish
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(localTimerViewModel.state, .stopped)
        XCTAssertEqual(localTimerViewModel.remainingTime, 0)
    }

    func testLocalTimerFinishedShowsTimerFinishedLiveActivity() async {
        let context = makeContext()
        let localTimerViewModel = LocalTimerViewModel()
        let localHandler = NotchLocalTimerEventsHandler(
            notchViewModel: context.notchViewModel,
            localTimerViewModel: localTimerViewModel,
            timerViewModel: context.timerViewModel,
            settingsViewModel: context.settingsViewModel
        )

        localHandler.handleLocalTimerFinished()

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.timerFinished.id
            }
        }
    }

    func testDismissingTimerFinishedLiveActivityIsNotRestorable() async {
        let context = makeContext()
        let localTimerViewModel = LocalTimerViewModel()
        let localHandler = NotchLocalTimerEventsHandler(
            notchViewModel: context.notchViewModel,
            localTimerViewModel: localTimerViewModel,
            timerViewModel: context.timerViewModel,
            settingsViewModel: context.settingsViewModel
        )

        localHandler.handleLocalTimerFinished()

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.timerFinished.id
            }
        }

        context.notchViewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent == nil
            }
        }

        XCTAssertFalse(context.notchViewModel.canRestoreDismissedContent)

        context.notchViewModel.restoreDismissedContent()

        try? await Task.sleep(nanoseconds: 50_000_000)

        let restoredContent = await MainActor.run {
            context.notchViewModel.notchModel.liveActivityContent?.id
        }
        XCTAssertNil(restoredContent)
    }

    func testLocalTimerRestartRestartsCountdown() {
        let localTimerViewModel = LocalTimerViewModel()
        localTimerViewModel.start(hours: 0, minutes: 1, seconds: 30)
        XCTAssertEqual(localTimerViewModel.totalTime, 90)
        XCTAssertEqual(localTimerViewModel.state, .running)

        localTimerViewModel.stop()
        XCTAssertEqual(localTimerViewModel.state, .stopped)
        XCTAssertEqual(localTimerViewModel.totalTime, 90)

        localTimerViewModel.restart()
        XCTAssertEqual(localTimerViewModel.state, .running)
        XCTAssertGreaterThan(localTimerViewModel.remainingTime, 85)
    }

    func testTimerSoundResolution() {
        XCTAssertEqual(TimerSound.resolved("radar"), .radar)
        XCTAssertEqual(TimerSound.resolved("invalid_name"), .radar)
        XCTAssertEqual(TimerSound.resolved(nil), .radar)
        XCTAssertEqual(TimerSound.allCases.count, 31)
    }
}

private extension NotchTimerEventsHandlerTests {
    struct TestContext {
        let notchViewModel: NotchViewModel
        let settingsViewModel: SettingsViewModel
        let timerViewModel: TimerViewModel
        let handler: NotchTimerEventsHandler
        let monitor: FakeClockTimerMonitor
    }

    func makeContext() -> TestContext {
        let suiteName = "NotchTimerEventsHandlerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        let settingsViewModel = SettingsViewModel(defaults: defaults)
        let notchViewModel = NotchViewModel(
            settings: settingsViewModel.application,
            hideDelay: 0.01,
            queueDelay: 0
        )
        let monitor = FakeClockTimerMonitor()
        let timerViewModel = TimerViewModel(monitor: monitor)
        let handler = NotchTimerEventsHandler(
            notchViewModel: notchViewModel,
            timerViewModel: timerViewModel,
            settingsViewModel: settingsViewModel,
            localTimerViewModel: LocalTimerViewModel()
        )

        return TestContext(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            timerViewModel: timerViewModel,
            handler: handler,
            monitor: monitor
        )
    }

    func makeSnapshot(isPaused: Bool, remaining: TimeInterval) -> ClockTimerSnapshot {
        let now = Date()
        let duration: TimeInterval = 120

        return ClockTimerSnapshot(
            identifier: "clock.timer.test",
            title: "Timer",
            duration: duration,
            endDate: now.addingTimeInterval(remaining),
            isPaused: isPaused,
            pausedRemaining: isPaused ? remaining : nil,
            fingerprint: isPaused ?
                "clock.timer.test|paused|\(Int(remaining.rounded()))" :
                "clock.timer.test|running|\(Int(now.addingTimeInterval(remaining).timeIntervalSince1970.rounded()))"
        )
    }

    final class FakeClockTimerMonitor: ClockTimerMonitoring {
        var onSnapshotChange: ((ClockTimerSnapshot?) -> Void)?

        func startMonitoring() {}

        func stopMonitoring() {}

        @MainActor
        func publish(_ snapshot: ClockTimerSnapshot?) {
            onSnapshotChange?(snapshot)
        }
    }
}
