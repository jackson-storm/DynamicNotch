//
//  NotchEventCoordinator.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/22/26.
//

import SwiftUI
import Combine

@MainActor
final class NotchEventCoordinator: ObservableObject {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel
    private let wifiViewModel: WifiViewModel
    private let calendarViewModel: CalendarViewModel
    private let systemHandler: NotchSystemEventsHandler
    private let focusHandler: NotchFocusEventsHandler
    private let hudHandler: NotchHUDEventsHandler
    private let connectivityHandler: NotchConnectivityEventsHandler
    private let powerHandler: NotchPowerEventsHandler
    private let mediaHandler: NotchMediaEventsHandler
    private let downloadHandler: NotchDownloadEventsHandler
    private let dragAndDropHandler: NotchDragAndDropEventsHandler
    private let timerHandler: NotchTimerEventsHandler
    private let homePageHandler: NotchHomePageEventsHandler
    private let localTimerHandler: NotchLocalTimerEventsHandler
    private let calendarHandler: NotchCalendarEventsHandler
    private let notificationsHandler: NotchNotificationsEventsHandler
    private let screenshotHandler: NotchScreenshotEventsHandler
    private let screenRecordingHandler: NotchScreenRecordingEventsHandler
    private let lockScreenHandler: NotchLockScreenEventsHandler
    private let onboardingHandler: NotchOnboardingEventsHandler
    private var settingsObserver: NotchSettingsObserver?
    private var cancellables = Set<AnyCancellable>()

    var isOnboardingActive: Bool {
        onboardingHandler.isOnboardingActive
    }

    convenience init(container: AppContainer) {
        self.init(
            notchViewModel: container.notchViewModel,
            powerViewModel: container.powerViewModel,
            focusViewModel: container.focusViewModel,
            bluetoothViewModel: container.bluetoothViewModel,
            powerService: container.powerService,
            wifiViewModel: container.wifiViewModel,
            vpnViewModel: container.vpnViewModel,
            downloadViewModel: container.downloadViewModel,
            airDropViewModel: container.airDropViewModel,
            fileTrayViewModel: container.fileTrayViewModel,
            fileConverterViewModel: container.fileConverterViewModel,
            settingsViewModel: container.settingsViewModel,
            nowPlayingViewModel: container.nowPlayingViewModel,
            timerViewModel: container.timerViewModel,
            screenRecordingViewModel: container.screenRecordingViewModel,
            lockScreenManager: container.lockScreenManager,
            homePageViewModel: container.homePageViewModel,
            localTimerViewModel: container.localTimerViewModel,
            calendarViewModel: container.calendarViewModel,
            screenshotViewModel: container.screenshotViewModel,
            screenRecordingResultViewModel: container.screenRecordingResultViewModel,
            mailManager: container.mailManager,
            messagesManager: container.messagesManager,
            externalDrivesMonitor: container.externalDrivesMonitor
        )
    }

    init(
        notchViewModel: NotchViewModel,
        powerViewModel: PowerViewModel? = nil,
        focusViewModel: FocusViewModel? = nil,
        bluetoothViewModel: BluetoothViewModel,
        powerService: PowerService,
        wifiViewModel: WifiViewModel,
        vpnViewModel: VpnViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        fileTrayViewModel: FileTrayViewModel,
        fileConverterViewModel: FileConverterViewModel,
        settingsViewModel: SettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        timerViewModel: TimerViewModel,
        screenRecordingViewModel: ScreenRecordingViewModel,
        lockScreenManager: LockScreenManager,
        homePageViewModel: HomePageViewModel,
        localTimerViewModel: LocalTimerViewModel,
        calendarViewModel: CalendarViewModel,
        screenshotViewModel: ScreenshotViewModel? = nil,
        screenRecordingResultViewModel: ScreenRecordingResultViewModel? = nil,
        mailManager: MailManager,
        messagesManager: MessagesManager,
        externalDrivesMonitor: ExternalDrivesMonitor
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.wifiViewModel = wifiViewModel
        self.calendarViewModel = calendarViewModel

        self.systemHandler = NotchSystemEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        self.focusHandler = NotchFocusEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        self.hudHandler = NotchHUDEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        self.connectivityHandler = NotchConnectivityEventsHandler(
            notchViewModel: notchViewModel,
            bluetoothViewModel: bluetoothViewModel,
            wifiViewModel: wifiViewModel,
            vpnViewModel: vpnViewModel,
            settingsViewModel: settingsViewModel
        )
        self.powerHandler = NotchPowerEventsHandler(
            notchViewModel: notchViewModel,
            powerService: powerService,
            settingsViewModel: settingsViewModel
        )
        self.mediaHandler = NotchMediaEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel
        )
        self.downloadHandler = NotchDownloadEventsHandler(
            notchViewModel: notchViewModel,
            downloadViewModel: downloadViewModel,
            settingsViewModel: settingsViewModel
        )
        self.dragAndDropHandler = NotchDragAndDropEventsHandler(
            notchViewModel: notchViewModel,
            airDropViewModel: airDropViewModel,
            fileTrayViewModel: fileTrayViewModel,
            fileConverterViewModel: fileConverterViewModel,
            settingsViewModel: settingsViewModel
        )
        self.timerHandler = NotchTimerEventsHandler(
            notchViewModel: notchViewModel,
            timerViewModel: timerViewModel,
            settingsViewModel: settingsViewModel,
            localTimerViewModel: localTimerViewModel
        )
        self.homePageHandler = NotchHomePageEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            localTimerViewModel: localTimerViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            fileConverterViewModel: fileConverterViewModel
        )
        self.calendarHandler = NotchCalendarEventsHandler(
            notchViewModel: notchViewModel,
            calendarViewModel: calendarViewModel,
            settingsViewModel: settingsViewModel
        )
        self.localTimerHandler = NotchLocalTimerEventsHandler(
            notchViewModel: notchViewModel,
            localTimerViewModel: localTimerViewModel,
            timerViewModel: timerViewModel,
            settingsViewModel: settingsViewModel
        )
        self.notificationsHandler = NotchNotificationsEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            mailManager: mailManager,
            messagesManager: messagesManager,
            externalDrivesMonitor: externalDrivesMonitor
        )
        let resolvedScreenshotHandler = NotchScreenshotEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            screenshotViewModel: screenshotViewModel ?? ScreenshotViewModel(),
            screenRecordingResultViewModel: screenRecordingResultViewModel ?? ScreenRecordingResultViewModel()
        )
        self.screenshotHandler = resolvedScreenshotHandler

        self.screenRecordingHandler = NotchScreenRecordingEventsHandler(
            notchViewModel: notchViewModel,
            screenRecordingViewModel: screenRecordingViewModel,
            settingsViewModel: settingsViewModel,
            screenshotHandler: resolvedScreenshotHandler
        )
        self.lockScreenHandler = NotchLockScreenEventsHandler(
            notchViewModel: notchViewModel,
            lockScreenManager: lockScreenManager,
            settingsViewModel: settingsViewModel
        )
        self.onboardingHandler = NotchOnboardingEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            mediaHandler: mediaHandler,
            homePageHandler: homePageHandler
        )

        setupEventSubscriptions(
            powerViewModel: powerViewModel,
            focusViewModel: focusViewModel,
            bluetoothViewModel: bluetoothViewModel,
            wifiViewModel: wifiViewModel,
            vpnViewModel: vpnViewModel,
            downloadViewModel: downloadViewModel,
            airDropViewModel: airDropViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            timerViewModel: timerViewModel,
            screenRecordingViewModel: screenRecordingViewModel,
            lockScreenManager: lockScreenManager,
            homePageViewModel: homePageViewModel
        )

        self.settingsObserver = NotchSettingsObserver(
            settingsViewModel: settingsViewModel,
            notchViewModel: notchViewModel,
            wifiViewModel: wifiViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            downloadViewModel: downloadViewModel,
            timerViewModel: timerViewModel,
            localTimerViewModel: localTimerViewModel,
            screenRecordingViewModel: screenRecordingViewModel,
            lockScreenManager: lockScreenManager,
            connectivityHandler: connectivityHandler,
            mediaHandler: mediaHandler,
            downloadHandler: downloadHandler,
            dragAndDropHandler: dragAndDropHandler,
            timerHandler: timerHandler,
            homePageHandler: homePageHandler,
            localTimerHandler: localTimerHandler,
            lockScreenHandler: lockScreenHandler,
            onLanguageChanged: { [weak self] language in
                self?.showLanguageChangedNotification(for: language)
            }
        )

        observeCalendarEvents()
    }

    func checkFirstLaunch() {
        onboardingHandler.checkFirstLaunch { [weak self] in
            self?.handleOnboardingEvent(.onboarding)
        }
    }

    func hideOnboarding(markAsSeen: Bool = false) {
        onboardingHandler.hideOnboarding(markAsSeen: markAsSeen)
    }

    func finishOnboarding() {
        onboardingHandler.hideOnboarding(markAsSeen: true)
    }

    func showOnboarding(step: OnboardingSteps = .first) {
        onboardingHandler.showOnboarding(step: step, coordinator: self)
    }

    #if DEBUG
    func showDebugOnboardingPreview(step: OnboardingSteps = .first) {
        onboardingHandler.showDebugOnboardingPreview(step: step, coordinator: self)
    }
    #endif

    func handleNotchWidthEvent(_ event: NotchSizeEvent) {
        guard !isOnboardingActive else { return }
        guard settingsViewModel.isTemporaryActivityEnabled(.notchSize) else { return }

        systemHandler.handleNotchSize(event)
    }

    func handleFocusEvent(_ event: FocusEvent) {
        guard !isOnboardingActive else { return }
        focusHandler.handleFocus(event)
    }

    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        hudHandler.handleHud(event)
    }

    func handleOnboardingEvent(_ event: OnboardingEvent) {
        switch event {
        case .onboarding:
            showOnboarding(step: .first)
        }
    }

    func handleBluetoothEvent(_ event: BluetoothEvent) {
        guard !isOnboardingActive else { return }
        connectivityHandler.handleBluetooth(event)
    }

    func handleWifiEvent(_ event: WifiEvent) {
        guard !isOnboardingActive else { return }
        connectivityHandler.handleWifi(event)
    }

    func handleVpnEvent(_ event: VpnEvent) {
        guard !isOnboardingActive else { return }
        connectivityHandler.handleVpn(event)
    }

    @discardableResult
    func requestInternetAccess() -> Bool {
        guard wifiViewModel.isInternetAvailable else {
            handleWifiEvent(.noInternetConnection)
            return false
        }

        return true
    }

    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        powerHandler.handle(event)
    }

    func handleDownloadEvent(_ event: DownloadEvent) {
        guard !isOnboardingActive else { return }
        downloadHandler.handleDownload(event)
    }

    func handleAirDropEvent(_ event: AirDropEvent) {
        dragAndDropHandler.handleAirDrop(event)
    }

    func handleNowPlayingEvent(_ event: NowPlayingEvent) {
        guard !isOnboardingActive else { return }
        mediaHandler.handleNowPlaying(event)
    }

    func handleTimerEvent(_ event: TimerEvent) {
        guard !isOnboardingActive else { return }
        timerHandler.handleTimer(event)
    }

    func handleHomePageEvent(_ event: HomePageEvent) {
        guard !isOnboardingActive else { return }
        homePageHandler.handleHomePage(event)
    }

    func handleScreenRecordingEvent(_ event: ScreenRecordingEvent) {
        guard !isOnboardingActive else { return }
        screenRecordingHandler.handleScreenRecordingEvent(event)
    }

    func handleLockScreenEvent(_ event: LockScreenEvent) {
        lockScreenHandler.handleLockScreenEvent(event)
    }

    func handleMailMessage(_ message: MailMessage) {
        notificationsHandler.handleMailMessage(message)
    }

    func handleMessagesMessage(_ message: MessagesMessage) {
        notificationsHandler.handleMessagesMessage(message)
    }

    func handleExternalDriveEvent(_ drive: ExternalDriveModel) {
        notificationsHandler.handleExternalDriveEvent(drive)
    }

    private func setupEventSubscriptions(
        powerViewModel: PowerViewModel?,
        focusViewModel: FocusViewModel?,
        bluetoothViewModel: BluetoothViewModel,
        wifiViewModel: WifiViewModel,
        vpnViewModel: VpnViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        timerViewModel: TimerViewModel,
        screenRecordingViewModel: ScreenRecordingViewModel,
        lockScreenManager: LockScreenManager,
        homePageViewModel: HomePageViewModel
    ) {
        powerViewModel?.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handlePowerEvent(event)
            }
            .store(in: &cancellables)

        bluetoothViewModel.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleBluetoothEvent(event)
            }
            .store(in: &cancellables)

        wifiViewModel.$wifiEvent.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleWifiEvent(event)
            }
            .store(in: &cancellables)

        vpnViewModel.$vpnEvent.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleVpnEvent(event)
            }
            .store(in: &cancellables)

        downloadViewModel.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleDownloadEvent(event)
            }
            .store(in: &cancellables)

        focusViewModel?.$focusEvent.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleFocusEvent(event)
            }
            .store(in: &cancellables)

        airDropViewModel.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleAirDropEvent(event)
            }
            .store(in: &cancellables)

        settingsViewModel.notchSizeEvent
            .sink { [weak self] event in
                self?.handleNotchWidthEvent(event)
            }
            .store(in: &cancellables)

        nowPlayingViewModel.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleNowPlayingEvent(event)
            }
            .store(in: &cancellables)

        timerViewModel.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleTimerEvent(event)
            }
            .store(in: &cancellables)

        screenRecordingViewModel.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleScreenRecordingEvent(event)
            }
            .store(in: &cancellables)

        lockScreenManager.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleLockScreenEvent(event)
            }
            .store(in: &cancellables)

        homePageViewModel.$event.compactMap { $0 }
            .sink { [weak self] event in
                self?.handleHomePageEvent(event)
            }
            .store(in: &cancellables)
    }

    private func observeCalendarEvents() {
        calendarViewModel.$events
            .map { _ in self.calendarViewModel.hasUpcomingEvent }
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.calendarHandler.handleCalendarEvent(self.calendarViewModel.hasUpcomingEvent)
                self.timerHandler.handleFrontmostApplicationChange()
            }
            .store(in: &cancellables)
    }

    private func showLanguageChangedNotification(for language: DynamicNotchLanguage) {
        let content = LanguageChangedNotchContent(language: language)
        notchViewModel.send(.showTemporaryNotification(content, duration: 3.0))
    }
}
