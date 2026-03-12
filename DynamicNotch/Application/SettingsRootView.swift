import SwiftUI

struct SettingsRootView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var powerService: PowerService
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(
                notchViewModel: notchViewModel,
                powerService: powerService,
                generalSettingsViewModel: generalSettingsViewModel
            )
            .tabItem {
                Label("General", systemImage: "gearshape.fill")
                    .accessibilityIdentifier("settings.tab.general")
            }
            .frame(width: 500, height: 560)

            ActivitySettingsView(
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator
            )
            .tabItem {
                Label("Activities", systemImage: "clock.fill")
                    .accessibilityIdentifier("settings.tab.activities")
            }
            .frame(width: 500, height: 560)

            AboutAppSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                        .accessibilityIdentifier("settings.tab.about")
                }
                .frame(width: 500, height: 560)
        }
        .accessibilityIdentifier("settings.root")
    }
}
