import SwiftUI

struct LockScreenSettingsView: View {
    @ObservedObject var settings: LockScreenFeatureSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Lock screen behavior",
                subtitle: "Control the lock-screen live activity, sound, and detached media panel."
            ) {
                SettingsToggleRow(
                    title: "Lock screen live activity",
                    description: "Show the lock-screen live activity during lock and unlock transitions.",
                    systemImage: "lock.fill",
                    color: .black,
                    isOn: $settings.isLockScreenLiveActivityEnabled,
                    accessibilityIdentifier: "settings.activities.lockScreen.liveActivity"
                )
                
                Divider()
                    .opacity(0.6)
                    .padding(.leading, 43)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                
                SettingsToggleRow(
                    title: "Lock screen sound",
                    description: "Play a sound when locking or unlocking your Mac.",
                    systemImage: "speaker.wave.2.fill",
                    color: .red,
                    isOn: $settings.isLockScreenSoundEnabled,
                    accessibilityIdentifier: "settings.activities.lockScreen.sound"
                )
                
                Divider()
                    .opacity(0.6)
                    .padding(.leading, 43)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                
                SettingsToggleRow(
                    title: "Lock screen media panel",
                    description: "Show the detached media panel on the lock screen while playback is active.",
                    systemImage: "play.rectangle.fill",
                    color: .pink,
                    isOn: $settings.isLockScreenMediaPanelEnabled,
                    accessibilityIdentifier: "settings.activities.lockScreen.mediaPanel"
                )
            }
        }
    }
}
