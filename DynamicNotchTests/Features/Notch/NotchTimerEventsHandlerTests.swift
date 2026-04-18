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
                context.notchViewModel.notchModel.liveActivityContent?.id == TimerNotchContent.activityID
            }
        }
    }

    func testPausedTimerKeepsVisibleLiveActivity() async {
        let context = makeContext()

        context.monitor.publish(makeSnapshot(isPaused: false, remaining: 90))
        context.handler.handleTimer(context.timerViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == TimerNotchContent.activityID
            }
        }

        context.monitor.publish(makeSnapshot(isPaused: true, remaining: 90))
        context.handler.handleTimer(context.timerViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == TimerNotchContent.activityID
            }
        }
    }
}

private extension NotchTimerEventsHandlerTests {
    struct TestContext {
        let notchViewModel: NotchViewModel
        let timerViewModel: TimerViewModel
        let handler: NotchTimerEventsHandler
        let monitor: FakeClockTimerMonitor
    }

    func makeContext() -> TestContext {
        let settingsViewModel = SettingsViewModel()
        let notchViewModel = NotchViewModel(
            settings: settingsViewModel.application,
            hideDelay: 0.01,
            queueDelay: 0
        )
        let monitor = FakeClockTimerMonitor()
        let timerViewModel = TimerViewModel(monitor: monitor)
        let handler = NotchTimerEventsHandler(
            notchViewModel: notchViewModel,
            timerViewModel: timerViewModel
        )

        return TestContext(
            notchViewModel: notchViewModel,
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
