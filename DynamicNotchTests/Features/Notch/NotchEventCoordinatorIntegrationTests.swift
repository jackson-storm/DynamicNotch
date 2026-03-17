import AppKit
import Combine
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

    func testVolumeHUDEventsShowTemporaryNotificationWhenEnabled() async {
        let context = makeContext()

        context.coordinator.handleHudEvent(.volume(72))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == "hud.system"
            }
        }
    }

    func testDisabledVolumeHUDSuppressesTemporaryNotification() async {
        let context = makeContext(volumeHUDEnabled: false)

        context.coordinator.handleHudEvent(.volume(72))

        try? await Task.sleep(nanoseconds: 50_000_000)

        let temporaryContent = await MainActor.run {
            context.notchViewModel.notchModel.temporaryNotificationContent
        }
        XCTAssertNil(temporaryContent)
    }

    func testDisabledBrightnessHUDSuppressesTemporaryNotification() async {
        let context = makeContext(brightnessHUDEnabled: false)

        context.coordinator.handleHudEvent(.display(44))

        try? await Task.sleep(nanoseconds: 50_000_000)

        let temporaryContent = await MainActor.run {
            context.notchViewModel.notchModel.temporaryNotificationContent
        }
        XCTAssertNil(temporaryContent)
    }

    func testDisabledKeyboardHUDSuppressesTemporaryNotification() async {
        let context = makeContext(keyboardHUDEnabled: false)

        context.coordinator.handleHudEvent(.keyboard(61))

        try? await Task.sleep(nanoseconds: 50_000_000)

        let temporaryContent = await MainActor.run {
            context.notchViewModel.notchModel.temporaryNotificationContent
        }
        XCTAssertNil(temporaryContent)
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

    func testNowPlayingEventsShowAndHideLiveActivity() async {
        let context = makeContext()

        context.nowPlayingService.publish(makeNowPlayingSnapshot())
        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" }
        }

        context.nowPlayingService.publish(nil)
        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .stopped)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }

    func testLockScreenEventsShowAndHideLockLiveActivity() async {
        let context = makeContext()

        context.lockScreenService.publish(isLocked: true)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "lockScreen" }
        }

        context.lockScreenService.publish(isLocked: false)

        await assertEventually(timeout: 0.5) {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }

    func testUnlockingRestoresNowPlayingAfterLockScreenActivityStops() async {
        let context = makeContext()
        context.nowPlayingService.publish(makeNowPlayingSnapshot())

        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" }
        }

        context.lockScreenService.publish(isLocked: true)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "lockScreen" }
        }

        context.lockScreenService.publish(isLocked: false)

        await assertEventually(timeout: 0.5) {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" }
        }
    }

    func testCheckFirstLaunchSyncsActiveNowPlayingSessionWhenOnboardingIsAlreadyCompleted() async {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        let context = makeContext()
        context.nowPlayingService.publish(makeNowPlayingSnapshot())

        context.coordinator.checkFirstLaunch()

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" }
        }
    }

    func testFinishingOnboardingRestoresNowPlayingWhenPlaybackIsActive() async {
        let context = makeContext()

        context.coordinator.handleOnboardingEvent(.onboarding)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "onboarding" }
        }

        context.nowPlayingService.publish(makeNowPlayingSnapshot())

        try? await Task.sleep(nanoseconds: 50_000_000)

        let activeContentID = await MainActor.run {
            context.notchViewModel.notchModel.liveActivityContent?.id
        }
        XCTAssertEqual(activeContentID, "onboarding")

        context.coordinator.finishOnboarding()

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" }
        }
    }
}

private extension NotchEventCoordinatorIntegrationTests {
    struct TestContext {
        let notchViewModel: NotchViewModel
        let coordinator: NotchEventCoordinator
        let airDropViewModel: AirDropNotchViewModel
        let nowPlayingViewModel: NowPlayingViewModel
        let nowPlayingService: FakeNowPlayingService
        let lockScreenManager: LockScreenManager
        let lockScreenService: FakeLockScreenMonitoringService
        let cancellables: Set<AnyCancellable>
    }

    func makeContext(
        brightnessHUDEnabled: Bool = true,
        keyboardHUDEnabled: Bool = true,
        volumeHUDEnabled: Bool = true
    ) -> TestContext {
        UserDefaults.standard.set(false, forKey: "isLaunchAtLoginEnabled")
        UserDefaults.standard.set(0, forKey: "notchWidth")
        UserDefaults.standard.set(0, forKey: "notchHeight")
        UserDefaults.standard.set(brightnessHUDEnabled, forKey: "settings.hud.brightness")
        UserDefaults.standard.set(keyboardHUDEnabled, forKey: "settings.hud.keyboard")
        UserDefaults.standard.set(volumeHUDEnabled, forKey: "settings.hud.volume")
        UserDefaults.standard.set(true, forKey: "settings.live.airdrop")
        UserDefaults.standard.set(true, forKey: "settings.live.hotspot")
        UserDefaults.standard.set(true, forKey: "settings.live.focus")
        UserDefaults.standard.set(true, forKey: "settings.live.nowPlaying")
        UserDefaults.standard.set(true, forKey: LockScreenSettings.liveActivityKey)
        UserDefaults.standard.set(true, forKey: LockScreenSettings.mediaPanelKey)
        UserDefaults.standard.set(true, forKey: "settings.temporary.charger")
        UserDefaults.standard.set(true, forKey: "settings.temporary.lowPower")
        UserDefaults.standard.set(true, forKey: "settings.temporary.fullPower")
        UserDefaults.standard.set(true, forKey: "settings.temporary.bluetooth")
        UserDefaults.standard.set(true, forKey: "settings.temporary.wifi")
        UserDefaults.standard.set(true, forKey: "settings.temporary.vpn")
        UserDefaults.standard.set(true, forKey: "settings.temporary.focusOff")
        UserDefaults.standard.set(true, forKey: "settings.temporary.notchSize")

        let generalSettingsViewModel = GeneralSettingsViewModel()
        let notchViewModel = NotchViewModel(
            settings: generalSettingsViewModel,
            hideDelay: 0.01,
            queueDelay: 0
        )
        let networkViewModel = NetworkViewModel(monitor: FakeNetworkMonitor())
        let airDropViewModel = AirDropNotchViewModel()
        let nowPlayingService = FakeNowPlayingService()
        let lockScreenService = FakeLockScreenMonitoringService()
        let nowPlayingViewModel = NowPlayingViewModel(service: nowPlayingService)
        let lockScreenManager = LockScreenManager(
            service: lockScreenService,
            unlockCollapseDelay: 0.05,
            idleResetDelay: 0.05
        )
        TestLifetime.retain(nowPlayingViewModel)
        TestLifetime.retain(lockScreenManager)
        nowPlayingViewModel.startMonitoring()
        lockScreenManager.startMonitoring()
        let coordinator = NotchEventCoordinator(
            notchViewModel: notchViewModel,
            bluetoothViewModel: BluetoothViewModel(),
            powerService: PowerService(startMonitoring: false),
            networkViewModel: networkViewModel,
            airDropViewModel: airDropViewModel,
            generalSettingsViewModel: generalSettingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            lockScreenManager: lockScreenManager
        )
        var cancellables = Set<AnyCancellable>()

        lockScreenManager.$event
            .compactMap { $0 }
            .sink { event in
                coordinator.handleLockScreenEvent(event)
            }
            .store(in: &cancellables)

        return TestContext(
            notchViewModel: notchViewModel,
            coordinator: coordinator,
            airDropViewModel: airDropViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            nowPlayingService: nowPlayingService,
            lockScreenManager: lockScreenManager,
            lockScreenService: lockScreenService,
            cancellables: cancellables
        )
    }
}
