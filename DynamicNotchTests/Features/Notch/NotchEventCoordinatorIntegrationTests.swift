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

        context.coordinator.handleFocusEvent(.FocusOn(.doNotDisturb))

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Focus.active.id }
        }

        context.coordinator.handleFocusEvent(.FocusOff(.doNotDisturb))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent == nil &&
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Focus.inactive.id
            }
        }
    }

    func testSleepFocusOnAndOffLiveActivityDismissal() async {
        let context = makeContext()

        context.coordinator.handleFocusEvent(.FocusOn(.sleep))

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Focus.active.id }
        }

        context.coordinator.handleFocusEvent(.FocusOff(.sleep))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent == nil &&
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Focus.inactive.id
            }
        }
    }

    func testHotspotEventsShowAndHideLiveActivity() async {
        let context = makeContext()

        context.coordinator.handleWifiEvent(.hotspotActive)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Wifi.hotspot.id }
        }

        context.coordinator.handleWifiEvent(.hotspotHide)

        await assertEventually {
            await MainActor.run { context.notchViewModel.notchModel.content == nil }
        }
    }

    func testNoInternetEventShowsTemporaryNotification() async {
        let context = makeContext()

        context.coordinator.handleWifiEvent(.noInternetConnection)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Wifi.noInternet.id
            }
        }
    }

    func testDisabledNoInternetTemporaryActivitySuppressesNotification() async {
        let context = makeContext(noInternetTemporaryActivityEnabled: false)

        context.coordinator.handleWifiEvent(.noInternetConnection)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let temporaryContent = await MainActor.run {
            context.notchViewModel.notchModel.temporaryNotificationContent
        }
        XCTAssertNil(temporaryContent)
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

    func testVolumeHUDShowOnLockScreen() async {
        let context = makeContext()

        context.lockScreenService.publish(isLocked: true)
        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.LockScreen.activity.id
            }
        }

        context.coordinator.handleHudEvent(.volume(72))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.HUD.system.id
            }
        }
    }

    func testChargerNotificationShowOnLockScreen() async {
        let context = makeContext()

        context.lockScreenService.publish(isLocked: true)
        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.LockScreen.activity.id
            }
        }

        context.coordinator.handlePowerEvent(.charger)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Power.charger.id
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

    func testLiveActivitiesSuppressedOnLockScreenExceptLockScreenActivityAndTemporaryNotification() async {
        let context = makeContext(temporaryActivityDurationScale: 0.2)
        context.nowPlayingService.publish(makeNowPlayingSnapshot())
        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .started)

        await assertEventually {
            await MainActor.run { context.notchViewModel.displayedContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }

        context.lockScreenService.publish(isLocked: true)

        await assertEventually {
            await MainActor.run { context.notchViewModel.displayedContent?.id == NotchContentRegistry.LockScreen.activity.id }
        }

        context.coordinator.handleHudEvent(.volume(80))

        await assertEventually {
            await MainActor.run { context.notchViewModel.displayedContent?.id == NotchContentRegistry.HUD.system.id }
        }

        await assertEventually(timeout: 1.5) {
            await MainActor.run { context.notchViewModel.displayedContent?.id == NotchContentRegistry.LockScreen.activity.id }
        }

        context.lockScreenService.publish(isLocked: false)

        await assertEventually(timeout: 0.5) {
            await MainActor.run { context.notchViewModel.displayedContent?.id == NotchContentRegistry.Media.nowPlaying.id }
        }
    }

    func testLockScreenShowsLiveActivityWhenActivityPresentationHiddenIsTrue() async {
        let context = makeContext()
        context.notchViewModel.setActivityPresentationHidden(true)

        context.lockScreenService.publish(isLocked: true)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.isLocked &&
                context.notchViewModel.displayedContent?.id == NotchContentRegistry.LockScreen.activity.id
            }
        }

        context.lockScreenService.publish(isLocked: false)

        await assertEventually(timeout: 0.5) {
            await MainActor.run {
                !context.notchViewModel.isLocked &&
                context.notchViewModel.displayedContent == nil
            }
        }
    }

    func testSwipeDismissOnLockScreenDoesNotDismissContent() async {
        let context = makeContext()
        context.nowPlayingService.publish(makeNowPlayingSnapshot())
        context.coordinator.handleNowPlayingEvent(context.nowPlayingViewModel.event ?? .started)

        context.lockScreenService.publish(isLocked: true)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.isLocked &&
                context.notchViewModel.displayedContent?.id == NotchContentRegistry.LockScreen.activity.id &&
                context.notchViewModel.canDismissWithTrackpadSwipe
            }
        }

        await MainActor.run {
            context.notchViewModel.dismissActiveContent()
        }

        try? await Task.sleep(nanoseconds: 100_000_000)
        await assertEventually {
            await MainActor.run {
                context.notchViewModel.displayedContent?.id == NotchContentRegistry.LockScreen.activity.id
            }
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

    func testMessagesMessageShowsTemporaryNotification() async {
        let context = makeContext()
        let message = makeMessagesMessage(rowID: 1, text: "First message")

        defer {
            context.notchViewModel.hideTemporaryNotification()
        }

        context.coordinator.handleMessagesMessage(message)

        await assertEventually {
            await MainActor.run {
                guard let content = context.notchViewModel.notchModel.temporaryNotificationContent as? NotificationsNotchContent else {
                    return false
                }

                return content.messages == [message]
            }
        }
    }

    func testSecondMessagesMessageUpdatesExistingPresentation() async {
        let context = makeContext()
        let firstMessage = makeMessagesMessage(rowID: 1, text: "First message")
        let secondMessage = makeMessagesMessage(rowID: 2, text: "Second message")

        defer {
            context.notchViewModel.hideTemporaryNotification()
        }

        context.coordinator.handleMessagesMessage(firstMessage)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id
            }
        }

        let firstUpdateToken = context.notchViewModel.notchModel.updateToken

        context.coordinator.handleMessagesMessage(secondMessage)

        XCTAssertEqual(
            context.notchViewModel.notchModel.temporaryNotificationContent?.id,
            NotchContentRegistry.Notifications.messages.id
        )

        await assertEventually {
            await MainActor.run {
                guard let content = context.notchViewModel.notchModel.temporaryNotificationContent as? NotificationsNotchContent else {
                    return false
                }

                return content.messages.map(\.rowID) == [1, 2] &&
                context.notchViewModel.notchModel.updateToken != firstUpdateToken
            }
        }
    }

    func testThirdMessagesMessageKeepsOnlyTwoNewestMessages() async {
        let context = makeContext()

        defer {
            context.notchViewModel.hideTemporaryNotification()
        }

        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 1, text: "First message"))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id
            }
        }

        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 2, text: "Second message"))
        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 3, text: "Third message"))

        await assertEventually {
            await MainActor.run {
                guard let content = context.notchViewModel.notchModel.temporaryNotificationContent as? NotificationsNotchContent else {
                    return false
                }

                return content.messages.map(\.rowID) == [2, 3]
            }
        }
    }

    func testRepeatedMessagesRowReplacesExistingQueueItem() async {
        let context = makeContext()

        defer {
            context.notchViewModel.hideTemporaryNotification()
        }

        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 1, text: "First message"))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id
            }
        }

        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 2, text: "Original text"))
        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 2, text: "Updated text"))

        await assertEventually {
            await MainActor.run {
                guard let content = context.notchViewModel.notchModel.temporaryNotificationContent as? NotificationsNotchContent else {
                    return false
                }

                guard content.messages.map(\.rowID) == [1, 2] else {
                    return false
                }

                return content.messages.last?.parts == [.text("Updated text")]
            }
        }
    }

    func testMessagesQueueClearsAfterNotificationIsHidden() async {
        let context = makeContext()

        defer {
            context.notchViewModel.hideTemporaryNotification()
        }

        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 1, text: "First message"))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id
            }
        }

        context.notchViewModel.hideTemporaryNotification()

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent == nil
            }
        }

        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 2, text: "Second message"))

        await assertEventually {
            await MainActor.run {
                guard let content = context.notchViewModel.notchModel.temporaryNotificationContent as? NotificationsNotchContent else {
                    return false
                }

                return content.messages.map(\.rowID) == [2]
            }
        }
    }

    func testMessagesNotificationHidesAfterConfiguredDuration() async {
        let context = makeContext(temporaryActivityDurationScale: 0.2, messagesNotificationDuration: 3)

        context.coordinator.handleMessagesMessage(makeMessagesMessage(rowID: 1, text: "Temporary message"))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id
            }
        }

        await assertEventually(timeout: 1.4) {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent == nil
            }
        }
    }

    func testMessagesAudioPlaybackSuspendsAndRestartsAutoHideTimer() async throws {
        let context = makeContext(temporaryActivityDurationScale: 0.2, messagesNotificationDuration: 3)

        context.coordinator.handleMessagesMessage(makeMessagesAudioMessage(rowID: 1))

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id
            }
        }

        let initialContent = try XCTUnwrap(
            context.notchViewModel.notchModel.temporaryNotificationContent as? NotificationsNotchContent
        )

        let initialUpdateToken = context.notchViewModel.notchModel.updateToken

        initialContent.onAudioPlaybackStateChanged(true)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.updateToken != initialUpdateToken
            }
        }

        try? await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(
            context.notchViewModel.notchModel.temporaryNotificationContent?.id,
            NotchContentRegistry.Notifications.messages.id
        )

        let playingContent = try XCTUnwrap(
            context.notchViewModel.notchModel.temporaryNotificationContent as? NotificationsNotchContent
        )

        let playingUpdateToken = context.notchViewModel.notchModel.updateToken

        playingContent.onAudioPlaybackStateChanged(false)

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.updateToken != playingUpdateToken
            }
        }

        await assertEventually(timeout: 1.4) {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent == nil
            }
        }
    }

    func testLanguageChangeShowsTemporaryNotification() async {
        let context = makeContext()

        await MainActor.run {
            context.settingsViewModel.application.appLanguage = .russian
        }

        await assertEventually {
            await MainActor.run {
                context.notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Settings.language.id
            }
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
        let mailManager: MailManager
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
        trayLiveActivityEnabled: Bool = true,
        noInternetTemporaryActivityEnabled: Bool = true,
        homePageLiveActivityEnabled: Bool = false,
        messagesNotificationDuration: Int = 8
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
        UserDefaults.standard.set(false, forKey: "settings.live.focus.autoHide")
        UserDefaults.standard.set(true, forKey: "settings.live.nowPlaying")
        UserDefaults.standard.set(nowPlayingPauseHideTimerEnabled, forKey: "settings.nowPlaying.pauseHideTimerEnabled")
        UserDefaults.standard.set(nowPlayingPauseHideDelay, forKey: "settings.nowPlaying.pauseHideDelay")
        UserDefaults.standard.set(true, forKey: "settings.live.downloads")
        UserDefaults.standard.set(dragAndDropEnabled, forKey: "settings.live.dragAndDrop")
        UserDefaults.standard.set(dragAndDropActivityMode.rawValue, forKey: "settings.live.dragAndDrop.mode")
        UserDefaults.standard.set(trayLiveActivityEnabled, forKey: "settings.live.tray")
        UserDefaults.standard.set(true, forKey: "settings.live.fileConverter")
        UserDefaults.standard.set(true, forKey: LockScreenSettings.liveActivityKey)
        UserDefaults.standard.set(true, forKey: LockScreenSettings.mediaPanelKey)
        UserDefaults.standard.set(true, forKey: "settings.temporary.charger")
        UserDefaults.standard.set(true, forKey: "settings.temporary.lowPower")
        UserDefaults.standard.set(true, forKey: "settings.temporary.fullPower")
        UserDefaults.standard.set(true, forKey: "settings.temporary.bluetooth")
        UserDefaults.standard.set(true, forKey: "settings.temporary.wifi")
        UserDefaults.standard.set(true, forKey: "settings.temporary.vpn")
        UserDefaults.standard.set(noInternetTemporaryActivityEnabled, forKey: "settings.temporary.noInternet")
        UserDefaults.standard.set(false, forKey: "settings.temporary.focusOn")
        UserDefaults.standard.set(true, forKey: "settings.temporary.focusOff")
        UserDefaults.standard.set(true, forKey: "settings.temporary.notchSize")
        UserDefaults.standard.set(homePageLiveActivityEnabled, forKey: "settings.homePage.liveActivity")
        UserDefaults.standard.set(true, forKey: "settings.notifications.messages.enabled")
        UserDefaults.standard.set(true, forKey: "settings.notifications.appleMail.enabled")
        UserDefaults.standard.set(messagesNotificationDuration, forKey: "settings.notifications.messages.duration")

        let settingsViewModel = SettingsViewModel()
        let notchViewModel = NotchViewModel(
            settings: settingsViewModel.application,
            hideDelay: 0.01,
            queueDelay: 0
        )
        let wifiViewModel = WifiViewModel(monitor: FakeWifiMonitor(), settings: settingsViewModel.connectivity)
        let vpnViewModel = VpnViewModel(monitor: FakeWifiMonitor(), settings: settingsViewModel.connectivity)
        let downloadMonitor = FakeFileDownloadMonitor()
        let downloadViewModel = DownloadViewModel(monitor: downloadMonitor)
        let nowPlayingService = FakeNowPlayingService()
        let lockScreenService = FakeLockScreenMonitoringService()
        let nowPlayingViewModel = NowPlayingViewModel(service: nowPlayingService)
        let airDropViewModel = AirDropNotchViewModel()
        let fileTrayViewModel = FileTrayViewModel()
        let fileConverterViewModel = FileConverterViewModel()
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
        let screenRecordingViewModel = ScreenRecordingViewModel(monitor: FakeScreenRecordingMonitor())
        let homePageViewModel = HomePageViewModel()
        let localTimerViewModel = LocalTimerViewModel()
        let mailManager = MailManager()
        let messagesManager = MessagesManager()
        let calendarViewModel = CalendarViewModel()
        let coordinator = NotchEventCoordinator(
            notchViewModel: notchViewModel,
            bluetoothViewModel: BluetoothViewModel(),
            powerService: PowerService(startMonitoring: false),
            wifiViewModel: wifiViewModel,
            vpnViewModel: vpnViewModel,
            downloadViewModel: downloadViewModel,
            airDropViewModel: airDropViewModel,
            fileTrayViewModel: fileTrayViewModel,
            fileConverterViewModel: fileConverterViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            timerViewModel: timerViewModel,
            screenRecordingViewModel: screenRecordingViewModel,
            lockScreenManager: lockScreenManager,
            homePageViewModel: homePageViewModel,
            localTimerViewModel: localTimerViewModel,
            calendarViewModel: calendarViewModel,
            mailManager: mailManager,
            messagesManager: messagesManager,
            externalDrivesMonitor: ExternalDrivesMonitor()
        )
        let cancellables = Set<AnyCancellable>()

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
            cancellables: cancellables,
            mailManager: mailManager
        )
    }

    func makeMessagesMessage(rowID: Int64, text: String) -> MessagesMessage {
        MessagesMessage(
            rowID: rowID,
            guid: "message-\(rowID)",
            sender: MessagesSender(identifier: "+123456789", displayName: "Tim Cook", avatarData: nil),
            service: .iMessage,
            conversation: nil,
            receivedDate: Date(timeIntervalSinceReferenceDate: Double(rowID)),
            parts: [.text(text)]
        )
    }

    func makeMessagesAudioMessage(rowID: Int64) -> MessagesMessage {
        MessagesMessage(
            rowID: rowID,
            guid: "audio-message-\(rowID)",
            sender: MessagesSender(identifier: "+123456789", displayName: "Tim Cook", avatarData: nil),
            service: .iMessage,
            conversation: nil,
            receivedDate: Date(timeIntervalSinceReferenceDate: Double(rowID)),
            parts: [
                .attachment(
                    .audio(
                        MessagesAudioAttachment(
                            id: "audio-\(rowID)",
                            fileURL: URL(fileURLWithPath: "/tmp/messages-audio.caf"),
                            duration: 40
                        )
                    )
                )
            ]
        )
    }
}
