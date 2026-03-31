import SwiftUI

struct AirDropSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            airDropActivity
            airDropAppearance
        }
    }
    
    private var airDropActivity: some View {
        SettingsCard(
            title: "AirDrop activity",
            subtitle: "Show a dedicated drop target in the notch while sharing files with AirDrop."
        ) {
            SettingsToggleRow(
                title: "AirDrop live activity",
                description: "Show the AirDrop drop target when you drag files over the notch.",
                systemImage: "dot.radiowaves.left.and.right",
                color: .blue,
                isOn: $mediaSettings.isAirDropLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.airDrop"
            )
        }
    }
    
    private var airDropAppearance: some View {
        SettingsCard(
            title: "AirDrop appearance",
            subtitle: "Preview the AirDrop notch and adjust its accent stroke."
        ) {
            NotchPreview(
                width: 230,
                height: 128,
                topCornerRadius: 24,
                bottomCornerRadius: 36,
                showsStroke: appearanceSettings.isShowNotchStrokeEnabled,
                strokeColor: mediaSettings.isAirDropDefaultStrokeEnabled ?
                    .white.opacity(0.2) :
                        .blue.opacity(0.3),
                strokeWidth: CGFloat(appearanceSettings.notchStrokeWidth)
            ) {
                AirDropPreviewNotchView()
            }
            
            SettingsToggleRow(
                title: "Use default stroke color",
                description: "Use the default notch stroke color instead of the blue AirDrop accent.",
                systemImage: "paintbrush.pointed.fill",
                color: .indigo,
                isOn: $mediaSettings.isAirDropDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.airDrop.defaultStroke"
            )
        }
    }
}
