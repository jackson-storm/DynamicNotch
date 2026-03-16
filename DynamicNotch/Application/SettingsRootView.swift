import SwiftUI

enum SettingsWindowLayout {
    static let width: CGFloat = 500
    static let height: CGFloat = 560
}

struct SettingsRootView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    @StateObject private var viewModel: SettingsRootViewModel

    init(
        powerService: PowerService,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.powerService = powerService
        self.generalSettingsViewModel = generalSettingsViewModel
        _viewModel = StateObject(
            wrappedValue: SettingsRootViewModel(settings: generalSettingsViewModel)
        )
    }

    var body: some View {
        TabView(selection: $viewModel.selection) {
            GeneralSettingsView(
                powerService: powerService,
                generalSettingsViewModel: generalSettingsViewModel
            )
            .tabItem {
                Label(
                    SettingsRootViewModel.Section.general.title,
                    systemImage: SettingsRootViewModel.Section.general.systemImage
                )
            }
            .tag(SettingsRootViewModel.Section.general)
            .accessibilityIdentifier(SettingsRootViewModel.Section.general.accessibilityIdentifier)

            LiveActivitySettingsView(
                viewModel: viewModel.liveActivityViewModel
            )
            .tabItem {
                Label(
                    SettingsRootViewModel.Section.liveActivity.title,
                    systemImage: SettingsRootViewModel.Section.liveActivity.systemImage
                )
            }
            .tag(SettingsRootViewModel.Section.liveActivity)
            .accessibilityIdentifier(SettingsRootViewModel.Section.liveActivity.accessibilityIdentifier)

            TemporaryActivitySettingsView(
                viewModel: viewModel.temporaryActivityViewModel
            )
            .tabItem {
                Label(
                    SettingsRootViewModel.Section.temporaryActivity.title,
                    systemImage: SettingsRootViewModel.Section.temporaryActivity.systemImage
                )
            }
            .tag(SettingsRootViewModel.Section.temporaryActivity)
            .accessibilityIdentifier(SettingsRootViewModel.Section.temporaryActivity.accessibilityIdentifier)

            AboutAppSettingsView()
                .frame(maxWidth: .infinity, alignment: .top)
                .background(.ultraThinMaterial)
            
            .tabItem {
                Label(
                    SettingsRootViewModel.Section.about.title,
                    systemImage: SettingsRootViewModel.Section.about.systemImage
                )
            }
            .tag(SettingsRootViewModel.Section.about)
            .accessibilityIdentifier(SettingsRootViewModel.Section.about.accessibilityIdentifier)
        }
        .frame(width: SettingsWindowLayout.width, height: SettingsWindowLayout.height)
        .accessibilityIdentifier("settings.root")
    }
}
