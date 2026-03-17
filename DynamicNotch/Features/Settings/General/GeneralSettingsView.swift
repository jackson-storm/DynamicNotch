import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            systemCard
            displayCard
            appearanceCard
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("settings.general.root")
    }

    private var systemCard: some View {
        SettingsCard(
            title: "System",
            subtitle: "Choose how Dynamic Notch integrates with macOS."
        ) {
            VStack(spacing: 16) {
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
            VStack(alignment: .leading, spacing: 10) {
                CustomPicker(
                    selection: $generalSettingsViewModel.displayLocation,
                    options: Array(NotchDisplayLocation.allCases),
                    title: { $0.title },
                    symbolName: { $0.symbolName }
                )
                .accessibilityIdentifier("settings.general.displayLocation")
            }
        }
    }

    private var appearanceCard: some View {
        SettingsCard(
            title: "Notch appearance",
            subtitle: "Fine-tune the frame and stroke so the overlay matches your hardware."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                notchPreview

                SettingsToggleRow(
                    title: "Show notch stroke",
                    description: "Render a subtle outline that adapts to the active content color.",
                    systemImage: "square.on.square.squareshape.controlhandles",
                    color: .green,
                    isOn: $generalSettingsViewModel.isShowNotchStrokeEnabled,
                    accessibilityIdentifier: "settings.general.showNotchStroke"
                )

                TickedSlider(
                    title: "Stroke width",
                    value: $generalSettingsViewModel.notchStrokeWidth,
                    range: 1...3,
                    step: 0.5,
                    valueFormatter: { String(format: "%.1f px", $0) }
                )
                .accessibilityIdentifier("settings.general.notchStrokeWidth")

                TickedSlider(
                    title: "Notch width",
                    value: Binding(
                        get: { Double(generalSettingsViewModel.notchWidth) },
                        set: { generalSettingsViewModel.notchWidth = Int($0.rounded()) }
                    ),
                    range: -8...8,
                    step: 1,
                    valueFormatter: { "\(Int($0)) px" }
                )
                .accessibilityIdentifier("settings.general.notchWidth")

                TickedSlider(
                    title: "Notch height",
                    value: Binding(
                        get: { Double(generalSettingsViewModel.notchHeight) },
                        set: { generalSettingsViewModel.notchHeight = Int($0.rounded()) }
                    ),
                    range: -4...4,
                    step: 1,
                    valueFormatter: { "\(Int($0)) px" }
                )
                .accessibilityIdentifier("settings.general.notchHeight")
            }
        }
    }

    private var notchPreview: some View {
        ZStack(alignment: .top) {
            Image("backgroundDark")
                .resizable()
                .scaledToFill()
                .frame(height: 138)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            LinearGradient(
                colors: [Color.black.opacity(0.12), Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 138)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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
    }
}
