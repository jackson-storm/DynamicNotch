import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        SettingsPageScrollView {
            systemCard
            displayCard
            appearanceCard
            animationCard
        }
        .accessibilityIdentifier("settings.general.root")
    }
    
    private var systemCard: some View {
        SettingsCard(
            title: "System",
            subtitle: "Choose how Dynamic Notch integrates with macOS."
        ) {
            VStack {
                SettingsToggleRow(
                    title: "Launch at login",
                    description: "Start Dynamic Notch automatically after you sign in.",
                    systemImage: "power",
                    color: .blue,
                    isOn: $generalSettingsViewModel.isLaunchAtLoginEnabled,
                    accessibilityIdentifier: "settings.general.launchAtLogin"
                )
                
                Divider()
                
                SettingsToggleRow(
                    title: "Show menu bar icon",
                    description: "Keep a persistent shortcut in the menu bar for settings and quit.",
                    systemImage: "menubar.rectangle",
                    color: .purple,
                    isOn: $generalSettingsViewModel.isMenuBarIconVisible,
                    accessibilityIdentifier: "settings.general.menuBarIcon"
                )
            }
        }
    }
    
    private var displayCard: some View {
        SettingsCard(
            title: "Display",
            subtitle: "Pick which screen should host the notch overlay."
        ) {
            CustomPicker(
                selection: $generalSettingsViewModel.displayLocation,
                options: Array(NotchDisplayLocation.allCases),
                title: { $0.title },
                symbolName: { $0.symbolName }
            )
            .accessibilityIdentifier("settings.general.displayLocation")
        }
    }
    
    private var appearanceCard: some View {
        SettingsCard(
            title: "Notch appearance",
            subtitle: "Fine-tune the frame and stroke so the overlay matches your hardware."
        ) {
            VStack(alignment: .leading) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.08) : Color .gray.opacity(0.18))
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        .frame(height: 138)
                    
                    NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                        .fill(.black)
                        .overlay {
                            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                                .stroke(
                                    generalSettingsViewModel.isShowNotchStrokeEnabled ? .green.opacity(0.3) : .clear,
                                    lineWidth: generalSettingsViewModel.notchStrokeWidth
                                )
                        }
                        .overlay {
                            ChargerNotchView(powerService: powerService)
                        }
                        .frame(width: 370, height: 38)
                }
                
                SettingsToggleRow(
                    title: "Show notch stroke",
                    description: "Render a subtle outline that adapts to the active content color.",
                    systemImage: "square.on.square.squareshape.controlhandles",
                    color: .green,
                    isOn: $generalSettingsViewModel.isShowNotchStrokeEnabled,
                    accessibilityIdentifier: "settings.general.showNotchStroke"
                )
                
                Divider()
                
                SettingsToggleRow(
                    title: "Resize feedback",
                    description: "Show temporary notch-size hints while width or height sliders are adjusted.",
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    color: .red,
                    isOn: $generalSettingsViewModel.isNotchSizeTemporaryActivityEnabled,
                    accessibilityIdentifier: "settings.activities.temporary.notchSize"
                )
                
                Divider()
                
                SettingsSliderRow(
                    title: "Stroke width",
                    description: "Adjust the thickness of the visible notch outline.",
                    valueText: String(format: "%.1f px", generalSettingsViewModel.notchStrokeWidth),
                    range: 1...3,
                    step: 0.5,
                    accessibilityIdentifier: "settings.general.notchStrokeWidth",
                    value: $generalSettingsViewModel.notchStrokeWidth
                )
                
                SettingsSliderRow(
                    title: "Notch width",
                    description: "Offset the notch width to better match your display cutout.",
                    valueText: "\(generalSettingsViewModel.notchWidth) px",
                    range: -8...8,
                    step: 1,
                    accessibilityIdentifier: "settings.general.notchWidth",
                    value: Binding(
                        get: { Double(generalSettingsViewModel.notchWidth) },
                        set: { generalSettingsViewModel.notchWidth = Int($0.rounded()) }
                    )
                )
                
                SettingsSliderRow(
                    title: "Notch height",
                    description: "Offset the notch height to better match your display cutout.",
                    valueText: "\(generalSettingsViewModel.notchHeight) px",
                    range: -4...4,
                    step: 1,
                    accessibilityIdentifier: "settings.general.notchHeight",
                    value: Binding(
                        get: { Double(generalSettingsViewModel.notchHeight) },
                        set: { generalSettingsViewModel.notchHeight = Int($0.rounded()) }
                    )
                )
            }
        }
    }
    
    private var animationCard: some View {
        SettingsCard(
            title: "Animation",
            subtitle: "Choose one global motion preset for notch transitions, expansion, and visibility."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                CustomPicker(
                    selection: $generalSettingsViewModel.notchAnimationPreset,
                    options: Array(NotchAnimationPreset.allCases),
                    title: { $0.title },
                    symbolName: { $0.symbolName }
                )
                .accessibilityIdentifier("settings.general.animationPreset")
            }
        }
    }
}
