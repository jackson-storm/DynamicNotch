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
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == OnboardingSteps.first.liveActivityID
            }
        }

        context.coordinator.handlePowerEvent(.charger)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let state = await MainActor.run { context.notchViewModel.notchModel }
        XCTAssertEqual(state.liveActivityContent?.id, OnboardingSteps.first.liveActivityID)
        XCTAssertNil(state.temporaryNotificationContent)
    }

    func testFocusOffReplacesFocusLiveActivityWithTemporaryNotification() async {
        let context = makeContext()

        context.coordinator.handleFocusEvent(.FocusOn)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Focus.active.id }
        }

        context.coordinator.handleFocusEvent(.FocusOff)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent == nil &&
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Focus.inactive.id
            }
        }
    }

    func testHotspotEventsShowAndHideLiveActivity() async {
        let context = makeContext()

        context.coordinator.handleNetworkEvent(.hotspotActive)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Network.hotspot.id }
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
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.HUD.system.id
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

    func testTemporaryDurationScaleShortensHUDLifetime() async {
        let context = makeContext(temporaryActivityDurationScale: 0.5)

        context.coordinator.handleHudEvent(.volume(72))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.HUD.system.id
            }
        }

        await assertEventually(timeout: 1.3) {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent == nil
            }
        }
    }

    func testNowPlayingEventsShowAndHideLiveActivity() async {
        let context = makeContext()

        context.nowPlayingService.publish(makeNowPlayingSnapshot())
        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }

        context.nowPlayingService.publish(nil)
        context.coordinator.handleNowPlayingEvent(.stopped)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }

    func testPausedNowPlayingHidesAfterConfiguredDelay() async {
        let context = makeContext(nowPlayingPauseHideTimerEnabled: true, nowPlayingPauseHideDelay: 1)

        context.nowPlayingService.publish(makeNowPlayingSnapshot(playbackRate: 0))
        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }

        await assertEventually(timeout: 1.4) {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id != NotchContentRegistry.Media.nowPlaying.id }
        }
    }

    func testPausedNowPlayingStaysVisibleWhenPauseHideTimerIsDisabled() async {
        let context = makeContext(nowPlayingPauseHideTimerEnabled: false, nowPlayingPauseHideDelay: 1)

        context.nowPlayingService.publish(makeNowPlayingSnapshot(playbackRate: 0))
        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }

        try? await Task.sleep(nanoseconds: 1_250_000_000)

        let liveActivityID = await MainActor.run {
            context.notchViewModel.notchModel.liveActivityContent?.id
        }
        XCTAssertEqual(liveActivityID, NotchContentRegistry.Media.nowPlaying.id)
    }

    func testDownloadEventsShowAndHideLiveActivity() async {
        let context = makeContext()

        context.downloadMonitor.publish([
            DownloadModel(
                url: URL(fileURLWithPath: "/tmp/archive.zip"),
                displayName: "archive.zip",
                directoryName: "Downloads",
                byteCount: 1_024_000,
                estimatedTotalByteCount: 2_497_561,
                progress: 0.41,
                startedAt: .now.addingTimeInterval(-3),
                lastUpdatedAt: .now,
                isTemporaryFile: false,
                bytesPerSecond: 1_536_000
            )
        ])

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.download.id }
        }

        context.downloadMonitor.publish([])

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }

    func testDragAndDropTrayModeShowsTrayLiveActivity() async {
        let context = makeContext(dragAndDropActivityMode: .tray)

        context.airDropViewModel.setDraggingFile(true)
        context.coordinator.handleAirDropEvent(.dragStarted)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.DragAndDrop.tray.id
            }
        }
    }

    func testDragAndDropCombinedModeShowsCombinedLiveActivity() async {
        let context = makeContext(dragAndDropActivityMode: .combined)

        context.airDropViewModel.setDraggingFile(true)
        context.coordinator.handleAirDropEvent(.dragStarted)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.DragAndDrop.combined.id
            }
        }
    }

    func testFileTrayItemsShowTrayActiveLiveActivity() async {
        let context = makeContext(dragAndDropActivityMode: .tray)

        withExtendedLifetime(context.coordinator) {
            context.fileTrayViewModel.add([
                URL(fileURLWithPath: "/tmp/DynamicNotch-Tray-First.txt"),
                URL(fileURLWithPath: "/tmp/DynamicNotch-Tray-Folder", isDirectory: true)
            ])
        }

        await assertEventually({
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.DragAndDrop.trayActive.id
            }
        }, message: "Expected tray active content, got \(String(describing: context.notchViewModel.notchModel.liveActivityContent?.id)); count: \(context.fileTrayViewModel.count); enabled: \(context.settingsViewModel.isLiveActivityEnabled(.drop))")

        XCTAssertEqual(context.fileTrayViewModel.count, 2)

        context.fileTrayViewModel.clear()

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent == nil
            }
        }
    }

    func testDisabledTrayLiveActivitySuppressesFileTrayItems() async {
        let context = makeContext(
            dragAndDropActivityMode: .tray,
            trayLiveActivityEnabled: false
        )

        withExtendedLifetime(context.coordinator) {
            context.fileTrayViewModel.add([
                URL(fileURLWithPath: "/tmp/DynamicNotch-Tray-Disabled.txt")
            ])
        }

        XCTAssertEqual(context.fileTrayViewModel.count, 1)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent == nil
            }
        }
    }

    func testDisabledDragAndDropSuppressesLiveActivity() async {
        let context = makeContext(dragAndDropEnabled: false)

        context.airDropViewModel.setDraggingFile(true)
        context.coordinator.handleAirDropEvent(.dragStarted)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let liveActivityContent = await MainActor.run {
            context.notchViewModel.notchModel.liveActivityContent
        }
        XCTAssertNil(liveActivityContent)
    }

    func testLockScreenEventsShowAndHideLockLiveActivity() async {
        let context = makeContext()

        context.lockScreenService.publish(isLocked: true)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.LockScreen.activity.id }
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
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }

        context.lockScreenService.publish(isLocked: true)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.LockScreen.activity.id }
        }

        context.lockScreenService.publish(isLocked: false)

        await assertEventually(timeout: 0.5) {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }
    }

    func testCheckFirstLaunchSyncsActiveNowPlayingSessionWhenOnboardingIsAlreadyCompleted() async {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        let context = makeContext()
        context.nowPlayingService.publish(makeNowPlayingSnapshot())

        context.coordinator.checkFirstLaunch()

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }
    }

    func testFinishingOnboardingRestoresNowPlayingWhenPlaybackIsActive() async {
        let context = makeContext()

        context.coordinator.handleOnboardingEvent(.onboarding)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == OnboardingSteps.first.liveActivityID
            }
        }

        context.nowPlayingService.publish(makeNowPlayingSnapshot())

        try? await Task.sleep(nanoseconds: 50_000_000)

        let activeContentID = await MainActor.run {
            context.notchViewModel.notchModel.liveActivityContent?.id
        }
        XCTAssertEqual(activeContentID, OnboardingSteps.first.liveActivityID)

        context.coordinator.finishOnboarding()

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }
    }
}

private extension NotchEventCoordinatorIntegrationTests {
    struct TestContext {
        let notchViewModel: NotchViewModel
        let coordinator: NotchEventCoordinator
        let downloadViewModel: DownloadViewModel
        let downloadMonitor: FakeFileDownloadMonitor
        let airDropViewModel: AirDropNotchViewModel
        let fileTrayViewModel: FileTrayViewModel
        let settingsViewModel: SettingsViewModel
        let nowPlayingViewModel: NowPlayingViewModel
        let nowPlayingService: FakeNowPlayingService
        let lockScreenManager: LockScreenManager
        let lockScreenService: FakeLockScreenMonitoringService
        let cancellables: Set<AnyCancellable>
    }

    func makeContext(
        brightnessHUDEnabled: Bool = true,
        keyboardHUDEnabled: Bool = true,
        volumeHUDEnabled: Bool = true,
        temporaryActivityDurationScale: Double = 1,
        nowPlayingPauseHideTimerEnabled: Bool = true,
        nowPlayingPauseHideDelay: Int = 5,
        dragAndDropEnabled: Bool = true,
        dragAndDropActivityMode: DragAndDropActivityMode = .airDrop,
        trayLiveActivityEnabled: Bool = true
    ) -> TestContext {
        UserDefaults.standard.set(false, forKey: "isLaunchAtLoginEnabled")
        UserDefaults.standard.set(0, forKey: "notchWidth")
        UserDefaults.standard.set(0, forKey: "notchHeight")
        UserDefaults.standard.set(brightnessHUDEnabled, forKey: "settings.hud.brightness")
        UserDefaults.standard.set(keyboardHUDEnabled, forKey: "settings.hud.keyboard")
        UserDefaults.standard.set(volumeHUDEnabled, forKey: "settings.hud.volume")
        UserDefaults.standard.set(HudStyle.standard.rawValue, forKey: "settings.hud.style")
        UserDefaults.standard.set(temporaryActivityDurationScale, forKey: "settings.temporary.durationScale")
        UserDefaults.standard.set(true, forKey: "settings.live.hotspot")
        UserDefaults.standard.set(true, forKey: "settings.live.focus")
        UserDefaults.standard.set(true, forKey: "settings.live.nowPlaying")
        UserDefaults.standard.set(nowPlayingPauseHideTimerEnabled, forKey: "settings.nowPlaying.pauseHideTimerEnabled")
        UserDefaults.standard.set(nowPlayingPauseHideDelay, forKey: "settings.nowPlaying.pauseHideDelay")
        UserDefaults.standard.set(true, forKey: "settings.live.downloads")
        UserDefaults.standard.set(dragAndDropEnabled, forKey: "settings.live.airDrop")
        UserDefaults.standard.set(dragAndDropActivityMode.rawValue, forKey: "settings.live.dragAndDrop.mode")
        UserDefaults.standard.set(trayLiveActivityEnabled, forKey: "settings.live.tray")
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

        let settingsViewModel = SettingsViewModel()
        let notchViewModel = NotchViewModel(
            settings: settingsViewModel.application,
            hideDelay: 0.01,
            queueDelay: 0
        )
        let networkViewModel = NetworkViewModel(monitor: FakeNetworkMonitor(), settings: settingsViewModel.connectivity)
        let downloadMonitor = FakeFileDownloadMonitor()
        let downloadViewModel = DownloadViewModel(monitor: downloadMonitor)
        let nowPlayingService = FakeNowPlayingService()
        let lockScreenService = FakeLockScreenMonitoringService()
        let nowPlayingViewModel = NowPlayingViewModel(service: nowPlayingService)
        let airDropViewModel = AirDropNotchViewModel()
        let fileTrayViewModel = FileTrayViewModel()
        let timerViewModel = TimerViewModel(monitor: ClockTimerMonitor())
        let lockScreenManager = LockScreenManager(
            service: lockScreenService,
            unlockCollapseDelay: 0.05,
            idleResetDelay: 0.05
        )
        TestLifetime.retain(downloadViewModel)
        TestLifetime.retain(nowPlayingViewModel)
        TestLifetime.retain(lockScreenManager)
        downloadViewModel.startMonitoring()
        nowPlayingViewModel.startMonitoring()
        lockScreenManager.startMonitoring()
        let coordinator = NotchEventCoordinator(
            notchViewModel: notchViewModel,
            bluetoothViewModel: BluetoothViewModel(),
            powerService: PowerService(startMonitoring: false),
            networkViewModel: networkViewModel,
            downloadViewModel: downloadViewModel,
            airDropViewModel: airDropViewModel,
            fileTrayViewModel: fileTrayViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            timerViewModel: timerViewModel,
            lockScreenManager: lockScreenManager
        )
        var cancellables = Set<AnyCancellable>()

        lockScreenManager.$event
            .compactMap { $0 }
            .sink { event in
                coordinator.handleLockScreenEvent(event)
            }
            .store(in: &cancellables)

        downloadViewModel.$event
            .compactMap { $0 }
            .sink { event in
                coordinator.handleDownloadEvent(event)
            }
            .store(in: &cancellables)

        return TestContext(
            notchViewModel: notchViewModel,
            coordinator: coordinator,
            downloadViewModel: downloadViewModel,
            downloadMonitor: downloadMonitor,
            airDropViewModel: airDropViewModel,
            fileTrayViewModel: fileTrayViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            nowPlayingService: nowPlayingService,
            lockScreenManager: lockScreenManager,
            lockScreenService: lockScreenService,
            cancellables: cancellables
        )
    }
}
