import AppKit
import XCTest
@testable import DynamicNotch

@MainActor
final class NotchEventCoordinatorIntegrationTests: XCTestCase {
    func testOnboardingBlocksPowerNotifications() async {
        let context = makeContext()

        context.coordinator.handleOnboardingEvent(.onboarding)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "onboarding" }
        }

        context.coordinator.handlePowerEvent(.charger)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let state = await MainActor.run { context.notchViewModel.notchModel }
        XCTAssertEqual(state.liveActivityContent?.id, "onboarding")
        XCTAssertNil(state.temporaryNotificationContent)
    }

    func testFocusOffReplacesFocusLiveActivityWithTemporaryNotification() async {
        let context = makeContext()

        context.coordinator.handleFocusEvent(.FocusOn)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "focus.on" }
        }

        context.coordinator.handleFocusEvent(.FocusOff)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent == nil &&
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == "focus.off"
            }
        }
    }

    func testHotspotEventsShowAndHideLiveActivity() async {
        let context = makeContext()

        context.coordinator.handleNetworkEvent(.hotspotActive)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "hotspot.active" }
        }

        context.coordinator.handleNetworkEvent(.hotspotHide)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }

    func testAirDropDragStartAndEndDriveLiveActivityLifecycle() async {
        let context = makeContext()

        context.coordinator.handleAirDropEvent(.dragStarted)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "airdrop" }
        }

        context.coordinator.handleAirDropEvent(.dragEnded)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }

    func testAirDropDropUsesPresentationViewWithoutSettingsWindow() async {
        let context = makeContext()
        let expectedURL = URL(fileURLWithPath: "/tmp/demo.txt")
        let expectedPoint = NSPoint(x: 120, y: 80)
        let presentationView = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 40))

        context.airDropViewModel.presentationView = presentationView

        var receivedShare: (urls: [URL], point: NSPoint, view: NSView)?
        context.airDropViewModel.shareHandler = { urls, point, view in
            receivedShare = (urls, point, view)
        }

        context.coordinator.handleAirDropEvent(.dragStarted)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "airdrop" }
        }

        context.coordinator.handleAirDropEvent(.dropped(urls: [expectedURL], point: expectedPoint))

        XCTAssertEqual(receivedShare?.urls, [expectedURL])
        XCTAssertEqual(receivedShare?.point, expectedPoint)
        XCTAssertTrue(receivedShare?.view === presentationView)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }
}

private extension NotchEventCoordinatorIntegrationTests {
    struct TestContext {
        let notchViewModel: NotchViewModel
        let coordinator: NotchEventCoordinator
        let airDropViewModel: AirDropNotchViewModel
    }

    func makeContext() -> TestContext {
        UserDefaults.standard.set(false, forKey: "isLaunchAtLoginEnabled")
        UserDefaults.standard.set(0, forKey: "notchWidth")
        UserDefaults.standard.set(0, forKey: "notchHeight")

        let generalSettingsViewModel = GeneralSettingsViewModel()
        let notchViewModel = NotchViewModel(
            settings: generalSettingsViewModel,
            hideDelay: 0.01,
            queueDelay: 0
        )
        let networkViewModel = NetworkViewModel(monitor: FakeNetworkMonitor())
        let airDropViewModel = AirDropNotchViewModel()
        let coordinator = NotchEventCoordinator(
            notchViewModel: notchViewModel,
            bluetoothViewModel: BluetoothViewModel(),
            powerService: PowerService(startMonitoring: false),
            networkViewModel: networkViewModel,
            airDropViewModel: airDropViewModel,
            generalSettingsViewModel: generalSettingsViewModel
        )

        return TestContext(
            notchViewModel: notchViewModel,
            coordinator: coordinator,
            airDropViewModel: airDropViewModel
        )
    }
}
