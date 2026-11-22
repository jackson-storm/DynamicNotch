internal import AppKit
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct LockScreenSettingsView: View {
    @ObservedObject var settings: LockScreenFeatureSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @State private var lockSoundSelectionError: String?
    @State private var unlockSoundSelectionError: String?
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        applicationSettings.appLanguage.locale.dn(key, fallback: fallback)
    }
    
    var body: some View {
        SettingsPageScrollView {
            lockScreenActivity
            widgetAppearance
            artworkAppearance
        }
    }
    
    private var lockScreenActivity: some View {
        SettingsCard(title: "settings.lockScreen.card.activity") {
            SettingsToggleRow(
                title: "settings.lockScreen.activity.title",
                description: "settings.lockScreen.activity.desc",
                systemImage: "lock.fill",
                color: .black,
                stroke: true,
                isOn: $settings.isLockScreenLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.lockScreen.liveActivity"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.lockScreen.mediaPanel.title",
                description: "settings.lockScreen.mediaPanel.desc",
                systemImage: "play.rectangle.fill",
                color: .pink,
                isOn: $settings.isLockScreenMediaPanelEnabled,
                accessibilityIdentifier: "settings.activities.lockScreen.mediaPanel"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.lockScreen.sound.title",
                description: "settings.lockScreen.sound.desc",
                systemImage: "speaker.wave.2.fill",
                color: .red,
                isOn: $settings.isLockScreenSoundEnabled,
                accessibilityIdentifier: "settings.activities.lockScreen.sound"
            )
        }
    }
    
    private var artworkAppearance: some View {
        SettingsCard(title: "settings.lockScreen.card.artworkAppearance") {
            SettingsMenuRow(
                title: "settings.lockScreen.mediaPanelBackground.title",
                description: "settings.lockScreen.mediaPanelBackground.desc",
                options: Array(LockScreenMediaPanelBackgroundStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.general.hud.indicatorStyle",
                selection: $settings.mediaPanelBackgroundStyle
            )
            .accessibilityIdentifier("settings.activities.lockScreen.mediaPanelBackground")
        }
    }
    
    private var widgetAppearance: some View {
        SettingsCard(title: "settings.lockScreen.card.widgetAppearance") {
            SettingsSliderRow(
                title: "settings.lockScreen.mediaPanelPosition.title",
                description: "settings.lockScreen.mediaPanelPosition.desc",
                range: LockScreenSettings.mediaPanelVerticalOffsetRange,
                step: 5,
                fractionLength: 0,
                suffix: "px",
                accessibilityIdentifier: "settings.activities.lockScreen.mediaPanelPosition",
                value: $settings.mediaPanelVerticalOffset
            )
        }
    }
}
