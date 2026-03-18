import Combine
import SwiftUI

@MainActor
final class LiveActivitySettingsViewModel: ObservableObject {
    private let settings: GeneralSettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    init(settings: GeneralSettingsViewModel) {
        self.settings = settings

        settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var groups: [SettingsToggleGroup] {
        [
            SettingsToggleGroup(
                id: "live.core",
                title: "Core live activities",
                subtitle: "Persistent content that stays visible while the source event is still active.",
                items: [
                    SettingsToggleItem(
                        id: "live.nowPlaying",
                        title: "Now Playing",
                        description: "Keep the media player pinned in the notch while playback is active.",
                        systemImage: "music.note",
                        color: .red,
                        accessibilityIdentifier: "settings.activities.live.nowPlaying",
                        keyPath: \.isNowPlayingLiveActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "live.focus",
                        title: "Focus mode",
                        description: "Show a live indicator when Focus mode turns on.",
                        systemImage: "moon.fill",
                        color: .indigo,
                        accessibilityIdentifier: "settings.activities.live.focus",
                        keyPath: \.isFocusLiveActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "live.hotspot",
                        title: "Personal Hotspot",
                        description: "Show hotspot status as a long-lived activity while the hotspot remains enabled.",
                        systemImage: "personalhotspot",
                        color: .green,
                        accessibilityIdentifier: "settings.activities.live.hotspot",
                        keyPath: \.isHotspotLiveActivityEnabled
                    )
                ]
            ),
            SettingsToggleGroup(
                id: "live.lockScreen",
                title: "Lock screen",
                subtitle: "Controls specific to the lock screen transition and media handoff.",
                items: [
                    SettingsToggleItem(
                        id: "live.lockScreen.notch",
                        title: "Lock screen live activity",
                        description: "Show the dedicated lock screen state in the notch during lock transitions.",
                        systemImage: "lock.fill",
                        color: .black,
                        accessibilityIdentifier: "settings.activities.lockScreen.liveActivity",
                        keyPath: \.isLockScreenLiveActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "live.lockScreen.mediaPanel",
                        title: "Lock screen media panel",
                        description: "Present the detached media panel on the lock screen when playback is active.",
                        systemImage: "play.rectangle.fill",
                        color: .black,
                        accessibilityIdentifier: "settings.activities.lockScreen.mediaPanel",
                        keyPath: \.isLockScreenMediaPanelEnabled
                    )
                ]
            )
        ]
    }

    func binding(for item: SettingsToggleItem) -> Binding<Bool> {
        Binding(
            get: { self.settings[keyPath: item.keyPath] },
            set: { self.settings[keyPath: item.keyPath] = $0 }
        )
    }
}
