import SwiftUI

struct LockScreenSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Lock screen behavior",
                subtitle: "Control the lock-screen live activity, sound, and detached media panel."
            ) {
                VStack {
                    SettingsToggleRow(
                        title: "Lock screen live activity",
                        description: "Show the lock-screen live activity during lock and unlock transitions.",
                        systemImage: "lock.fill",
                        color: .black,
                        isOn: $generalSettingsViewModel.isLockScreenLiveActivityEnabled,
                        accessibilityIdentifier: "settings.activities.lockScreen.liveActivity"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Lock screen sound",
                        description: "Play a sound when locking or unlocking your Mac.",
                        systemImage: "speaker.wave.2.fill",
                        color: .red,
                        isOn: $generalSettingsViewModel.isLockScreenSoundEnabled,
                        accessibilityIdentifier: "settings.activities.lockScreen.sound"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Lock screen media panel",
                        description: "Show the detached media panel on the lock screen while playback is active.",
                        systemImage: "play.rectangle.fill",
                        color: .pink,
                        isOn: $generalSettingsViewModel.isLockScreenMediaPanelEnabled,
                        accessibilityIdentifier: "settings.activities.lockScreen.mediaPanel"
                    )
                }
            }
        }
    }
}
