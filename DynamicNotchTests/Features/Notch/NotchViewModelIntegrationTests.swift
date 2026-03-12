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
        TestLifetime.retain(viewModel)

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
        TestLifetime.retain(viewModel)

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
        TestLifetime.retain(viewModel)

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

    @MainActor
    func testDismissActiveContentHidesTemporaryNotificationAndRestoresLiveActivity() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "live", priority: 10)))
        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "live" }
        }

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: .infinity
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run {
                viewModel.notchModel.temporaryNotificationContent == nil &&
                viewModel.notchModel.liveActivityContent?.id == "live"
            }
        }
    }

    @MainActor
    func testDismissActiveContentRemovesVisibleLiveActivityAndShowsNextHighest() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(.showLiveActivity(TestNotchContent(id: "low", priority: 10)))
        viewModel.send(.showLiveActivity(TestNotchContent(id: "high", priority: 50)))

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "high" }
        }

        viewModel.dismissActiveContent()

        await assertEventually {
            await MainActor.run { viewModel.notchModel.liveActivityContent?.id == "low" }
        }
    }

    @MainActor
    func testDuplicateTemporaryNotificationRestartsLifetimeInsteadOfUsingOldTimer() async {
        let viewModel = NotchViewModel(
            settings: TestNotchSettings(),
            hideDelay: 0.01,
            queueDelay: 0
        )
        TestLifetime.retain(viewModel)

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: 0.05
            )
        )

        await assertEventually {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent?.id == "temporary" }
        }

        try? await Task.sleep(nanoseconds: 30_000_000)

        viewModel.send(
            .showTemporaryNotification(
                TestNotchContent(id: "temporary", priority: 0),
                duration: 0.2
            )
        )

        try? await Task.sleep(nanoseconds: 80_000_000)

        let isStillVisible = await MainActor.run {
            viewModel.notchModel.temporaryNotificationContent?.id == "temporary"
        }
        XCTAssertTrue(isStillVisible, "The refreshed temporary notification should survive the old timer.")

        await assertEventually(timeout: 1.0) {
            await MainActor.run { viewModel.notchModel.temporaryNotificationContent == nil }
        }
    }

    @MainActor
    func testUpdateDimensionsAppliesSettingsOffsets() {
        let baseSettings = TestNotchSettings()
        let offsetSettings = TestNotchSettings(notchWidth: 7, notchHeight: 3)

        let baseViewModel = NotchViewModel(settings: baseSettings)
        let offsetViewModel = NotchViewModel(settings: offsetSettings)
        TestLifetime.retain(baseViewModel)
        TestLifetime.retain(offsetViewModel)

        XCTAssertEqual(offsetViewModel.notchModel.baseWidth - baseViewModel.notchModel.baseWidth, 7, accuracy: 0.001)
        XCTAssertEqual(offsetViewModel.notchModel.baseHeight - baseViewModel.notchModel.baseHeight, 3, accuracy: 0.001)
    }
}
