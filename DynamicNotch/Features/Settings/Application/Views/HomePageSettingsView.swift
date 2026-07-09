import SwiftUI

struct HomePageSettingsView: View {
    @ObservedObject var homePageSettings: HomePageSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            homePageActivity
            homePagePages
            homePageAppearance
        }
    }
    private var homePageActivity: some View {
        SettingsCard(title: "Home Page activity") {
            SettingsToggleRow(
                title: "Home Page live activity",
                description: "Show the Home Page in the notch.",
                systemImage: "house.fill",
                color: .blue,
                isOn: $homePageSettings.isHomePageLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.homePage"
            )
        }
    }

    private var homePagePages: some View {
        SettingsCard(title: "Pages") {
            SettingsOrderListView(
                items: $homePageSettings.homePageOrder,
                disabledItems: $homePageSettings.homePageDisabled,
                icon: { $0.icon },
                tint: { $0.tint },
                title: { $0.title },
                subtitle: { $0.subtitle },
                isListEnabled: homePageSettings.isHomePageLiveActivityEnabled
            )

            Divider().opacity(0.6)

            Text(LocalizedStringKey("Drag to reorder pages. Disabled pages will be hidden."))
                .font(.caption)
                .foregroundColor(.gray)
                .opacity(homePageSettings.isHomePageLiveActivityEnabled ? 1.0 : 0.5)
        }
    }
    
    private var homePageAppearance: some View {
        SettingsCard(title: "Home Page appearance") {
            HomePageAppearancePreview(
                homePageSettings: homePageSettings,
                applicationSettings: applicationSettings
            )

            Divider().opacity(0.6)

            SettingsToggleRow(
                title: "settings.homePage.pageIndicator.title",
                description: "settings.homePage.pageIndicator.description",
                systemImage: "ellipsis.rectangle.fill",
                color: .black,
                isOn: $homePageSettings.isHomePagePageIndicatorEnabled,
                accessibilityIdentifier: "settings.homePage.pageIndicator"
            )

            Divider().opacity(0.6)
            
            SettingsMenuRow(
                title: "settings.homePage.indicatorSize.title",
                description: "settings.homePage.indicatorSize.description",
                options: Array(HomePageIndicatorSize.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.homePage.indicatorSize",
                selection: $homePageSettings.homePageIndicatorSize
            )
            .disabled(!homePageSettings.isHomePagePageIndicatorEnabled)
            .opacity(homePageSettings.isHomePagePageIndicatorEnabled ? 1.0 : 0.5)
        }
    }
}

private struct HomePageAppearancePreview: View {
    @ObservedObject var homePageSettings: HomePageSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsNotchPreview(
            width: 260,
            height: 130,
            previewHeight: 180,
            topCornerRadius: 24,
            bottomCornerRadius: 38,
            showsStroke: applicationSettings.isShowNotchStrokeEnabled,
            strokeColor: .white.opacity(0.2).opacity(applicationSettings.notchStrokeOpacity),
            strokeWidth: 1.5,
            lightBackgroundImage: Image("backgroundLight"),
            darkBackgroundImage: Image("backgroundDark")
        ) {
            ZStack(alignment: .top) {
                VStack() {
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.white.opacity(0.12))
                            .frame(height: 107)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "web.camera.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                            
                            Text("Start Camera")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 140)
                }
                .padding(.horizontal, 32)
                
                if homePageSettings.isHomePagePageIndicatorEnabled {
                    let size = homePageSettings.homePageIndicatorSize
                    HStack(spacing: size.spacing) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index == 0 ? Color.white : Color.white.opacity(0.4))
                                .frame(width: size.dotSize, height: size.dotSize)
                        }
                    }
                    .padding(size.padding)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(applicationSettings.isShowNotchStrokeEnabled
                                    ? .white.opacity(0.2).opacity(applicationSettings.notchStrokeOpacity)
                                    : .clear, lineWidth: 1)
                    }
                    .offset(y: 148)
                }
            }
        }
    }
}
