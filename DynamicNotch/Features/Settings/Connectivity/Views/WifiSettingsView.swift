import SwiftUI

struct WifiSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }
    
    private var hotspotPreviewStrokeColor: Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        if appearanceSettings.isDefaultActivityStrokeEnabled {
            return .white.opacity(0.2)
        }

        return .green.opacity(0.2)
    }
    
    var body: some View {
        SettingsPageScrollView {
            wifiActivity
            wifiDuration
            hotspotAppearance
        }
    }
    
    private var wifiActivity: some View {
        SettingsCard(title: "settings.wifi.card.activity") {
            SettingsToggleRow(
                title: "settings.wifi.temporaryActivity.title",
                description: "settings.wifi.temporaryActivity.desc",
                systemImage: "wifi",
                color: .blue,
                isOn: $connectivitySettings.isWifiTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.wifi"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.wifi.noInternet.title",
                description: "settings.wifi.noInternet.desc",
                systemImage: "wifi.slash",
                color: .red,
                isOn: $connectivitySettings.isNoInternetTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.noInternet"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.wifi.hotspot.title",
                description: "settings.wifi.hotspot.desc",
                systemImage: "personalhotspot",
                color: .green,
                isOn: $connectivitySettings.isHotspotLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot"
            )

        }
    }
    
    private var wifiDuration: some View {
        SettingsCard(title: "settings.wifi.card.duration") {
            SettingsSliderRow(
                title: "settings.wifi.duration.title",
                description: "settings.wifi.duration.desc",
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
        SettingsCard(title: "settings.wifi.card.hotspotAppearance") {
            CustomPicker(
                selection: $connectivitySettings.hotspotAppearanceStyle,
                options: Array(HotspotAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "settings.wifi.appearance.headerTitle",
                headerDescription: "settings.wifi.appearance.headerDesc",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                hotspotAppearancePickerContent(for: style, isSelected: isSelected)
            }


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
            .frame(width: 130, height: 30)
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
                        .foregroundStyle(.green)
                }
                .padding(.leading, 7)
                .padding(.trailing, 10)
            }
            .frame(width: 130, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
            
        case .battery:
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
                    
                    Text("78%")
                        .foregroundStyle(.green.gradient)
                        .font(.system(size: 12))
                }
                .padding(.leading, 7)
                .padding(.trailing, 10)
            }
            .frame(width: 130, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }
}
