import SwiftUI

struct NetworkSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }
    
    private var isHotspotDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }

    private var hotspotPreviewStrokeColor: Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        if appearanceSettings.isDefaultActivityStrokeEnabled || connectivitySettings.isHotspotDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }

        return .green.opacity(0.2)
    }
    
    var body: some View {
        SettingsPageScrollView {
            networkActivity
            networkDuration
            hotspotAppearance
        }
    }
    
    private var networkActivity: some View {
        SettingsCard(title: "Network activity") {
            SettingsToggleRow(
                title: "Wi-Fi temporary activity",
                description: "Show a short notification when Wi-Fi reconnects.",
                systemImage: "wifi",
                color: .blue,
                isOn: $connectivitySettings.isWifiTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.wifi"
            )
            
            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "No internet temporary activity",
                description: "Show a short notification when your Mac loses internet access.",
                systemImage: "wifi.slash",
                color: .red,
                isOn: $connectivitySettings.isNoInternetTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.noInternet"
            )

            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Personal Hotspot live activity",
                description: "Show a live activity while Personal Hotspot is enabled.",
                systemImage: "personalhotspot",
                color: .green,
                isOn: $connectivitySettings.isHotspotLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot"
            )

        }
    }
    
    private var networkDuration: some View {
        SettingsCard(title: "Network duration") {
            SettingsSliderRow(
                title: "Wi-Fi duration",
                description: "Choose how long the Wi-Fi reconnect notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.wifi.duration",
                value: Binding(
                    get: { Double(connectivitySettings.wifiTemporaryActivityDuration) },
                    set: { connectivitySettings.wifiTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!connectivitySettings.isWifiTemporaryActivityEnabled)
            .opacity(connectivitySettings.isWifiTemporaryActivityEnabled ? 1 : 0.5)
        }
    }
    
    private var hotspotAppearance: some View {
        SettingsCard(title: "Hotspot appearance") {
            CustomPicker(
                selection: $connectivitySettings.hotspotAppearanceStyle,
                options: Array(HotspotAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "Appearance",
                headerDescription: "Choose whether the hotspot activity stays minimal or shows more status.",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                hotspotAppearancePickerContent(for: style, isSelected: isSelected)
            }

            Divider().opacity(0.6)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the hotspot accent stroke.",
                isOn: $connectivitySettings.isHotspotDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot.defaultStroke"
            )
            .disabled(isHotspotDefaultStrokeLocked)
            .opacity(isHotspotDefaultStrokeLocked ? 0.5 : 1)
        }
    }
    
    @ViewBuilder
    private func hotspotAppearancePickerContent(for style: HotspotAppearanceStyle, isSelected: Bool) -> some View {
        switch style {
        case .minimal:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(hotspotPreviewStrokeColor, lineWidth: 1)
                    }
                
                HStack {
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 7)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
            
        case .detailed:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(hotspotPreviewStrokeColor, lineWidth: 1)
                    }
                
                HStack(spacing: 10) {
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Text(verbatim: "On")
                        .foregroundStyle(.green.opacity(0.8))
                }
                .padding(.leading, 7)
                .padding(.trailing, 10)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }
}
