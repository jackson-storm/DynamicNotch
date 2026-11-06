import SwiftUI
import Combine

@MainActor
final class NotchLocalTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let localTimerViewModel: LocalTimerViewModel
    private let timerViewModel: TimerViewModel
    private let settingsViewModel: SettingsViewModel
    private let timerSoundPlayer: any TimerSoundPlaying
    private var cancellables = Set<AnyCancellable>()

    init(
        notchViewModel: NotchViewModel,
        localTimerViewModel: LocalTimerViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel,
        timerSoundPlayer: any TimerSoundPlaying
    ) {
        self.notchViewModel = notchViewModel
        self.localTimerViewModel = localTimerViewModel
        self.timerViewModel = timerViewModel
        self.settingsViewModel = settingsViewModel
        self.timerSoundPlayer = timerSoundPlayer

        self.localTimerViewModel.onTimerFinished = { [weak self] in
            guard let self else { return }
            self.handleLocalTimerFinished()
        }

        setupHotkeyObservation()
    }

    convenience init(
        notchViewModel: NotchViewModel,
        localTimerViewModel: LocalTimerViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.init(
            notchViewModel: notchViewModel,
            localTimerViewModel: localTimerViewModel,
            timerViewModel: timerViewModel,
            settingsViewModel: settingsViewModel,
            timerSoundPlayer: TimerSoundPlayer.shared
        )
    }

    private func setupHotkeyObservation() {
        Publishers.CombineLatest(
            settingsViewModel.mediaAndFiles.$localTimerShortcutKeyCode,
            settingsViewModel.mediaAndFiles.$localTimerShortcutModifiers
        )
        .sink { [weak self] keyCode, modifiers in
            guard let self else { return }
            self.registerHotkey(keyCode: keyCode, modifiers: modifiers)
        }
        .store(in: &cancellables)
    }

    private func registerHotkey(keyCode: Int, modifiers: Int) {
        guard keyCode >= 0 else {
            GlobalHotkeyManager.shared.unregister()
            return
        }

        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        GlobalHotkeyManager.shared.register(keyCode: UInt32(keyCode), modifiers: modifierFlags) { [weak self] in
            Task { @MainActor [weak self] in
                self?.toggleTimerSetup()
            }
        }
    }

    func toggleTimerSetup() {
        if notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.localTimerSetup.id {
            hideTimerSetup()
        } else {
            showTimerSetup()
        }
    }

    func showTimerSetup() {
        notchViewModel.send(
            .showLiveActivity(
                LocalTimerSetupNotchContent(
                    localTimerViewModel: localTimerViewModel,
                    onStart: { [weak self] in
                        guard let self else { return }
                        self.notchViewModel.setPreferredLiveActivity(id: NotchContentRegistry.Media.localTimer.id)
                    },
                    onClose: { [weak self] in
                        guard let self else { return }
                        self.hideTimerSetup()
                    }
                )
            )
        )
    }

    func hideTimerSetup() {
        notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.localTimerSetup.id))
    }

    func handleLocalTimerStateChanged(_ state: LocalTimerState) {
        switch state {
        case .running, .paused:
            // Conflict protection: If the system timer is actively running, abort.
            if timerViewModel.snapshot != nil && timerViewModel.snapshot!.isPaused == false {
                return
            }
            
            notchViewModel.send(
                .showLiveActivity(
                    TimerNotchContent(
                        source: .local(localTimerViewModel)
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.localTimer.id))
        }
    }

    func handleLocalTimerFinished() {
        timerSoundPlayer.play(
            sound: settingsViewModel.mediaAndFiles.timerSound,
            isSoundEnabled: settingsViewModel.mediaAndFiles.isTimerSoundEnabled,
            loop: true
        )

        notchViewModel.send(
            .showLiveActivity(
                TimerFinishedNotchContent(
                    onDismiss: { [weak self] in
                        guard let self else { return }
                        self.timerSoundPlayer.stop()
                        self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timerFinished.id))
                    },
                    onRestart: { [weak self] in
                        guard let self else { return }
                        self.timerSoundPlayer.stop()
                        self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timerFinished.id))
                        self.localTimerViewModel.restart()
                    }
                )
            )
        )
    }
}

