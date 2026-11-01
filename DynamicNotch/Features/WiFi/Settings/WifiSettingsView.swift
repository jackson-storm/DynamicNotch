import SwiftUI

struct WifiSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var hotspotPreviewStrokeColor: Color {
        appearanceSettings.isShowNotchStrokeEnabled ? .green.opacity(0.2) : .clear
    }
    
    var body: some View {
        SettingsPageScrollView {
            wifiActivity
            hotspotAppearance
        }
    }
    
    private var wifiActivity: some View {
        SettingsCard(title: "settings.wifi.card.activity") {
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
                    
                    Text("On")
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
