import XCTest
@testable import DynamicNotch

final class NotchViewModelIntegrationTests: XCTestCase {
    @MainActor
    func testHigherPriorityLiveActivityReplacesLowerPriority() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "low" }
        }

        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }
    }

    @MainActor
    func testTemporaryNotificationSuspendsAndRestoresLiveActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: 0.05
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        await assertEventually(timeout: 1.5) {
            await MainActor.run {
                viewModel.notchModel.temporaryNotificationContent == nil &&
                viewModel.notchModel.liveActivityContent?.id == "live"
            }
        }
    }

    @MainActor
    func testHidingCurrentLiveActivityRestoresNextHighestPriorityActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        viewModel.send(.hideLiveActivity(id: "high"))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "low" }
        }
    }
}
