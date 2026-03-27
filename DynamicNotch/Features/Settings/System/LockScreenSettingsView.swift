import SwiftUI

struct LockScreenSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Lock screen behavior",
                subtitle: "Control the lock transition overlay, sound, and detached media presentation."
            ) {
                VStack {
                    SettingsToggleRow(
                        title: "Lock screen live activity",
                        description: "Show the dedicated lock screen state in the notch during lock transitions.",
                        systemImage: "lock.fill",
                        color: .gray,
                        isOn: $generalSettingsViewModel.isLockScreenLiveActivityEnabled,
                        accessibilityIdentifier: "settings.activities.lockScreen.liveActivity"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Lock screen sound",
                        description: "When locking and unlocking, a sound is played.",
                        systemImage: "speaker.wave.2.fill",
                        color: .red,
                        isOn: $generalSettingsViewModel.isLockScreenSoundEnabled,
                        accessibilityIdentifier: "settings.activities.lockScreen.sound"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Lock screen media panel",
                        description: "Present the detached media panel on the lock screen when playback is active.",
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
