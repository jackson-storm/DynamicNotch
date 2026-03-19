import SwiftUI

enum SettingsWindowLayout {
    static let width: CGFloat = 500
    static let height: CGFloat = 565
}

struct SettingsRootView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    let notchViewModel: NotchViewModel
    let notchEventCoordinator: NotchEventCoordinator
    let bluetoothViewModel: BluetoothViewModel
    let networkViewModel: NetworkViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager

    @StateObject private var viewModel: SettingsRootViewModel

    init(
        powerService: PowerService,
        generalSettingsViewModel: GeneralSettingsViewModel,
        notchViewModel: NotchViewModel,
        notchEventCoordinator: NotchEventCoordinator,
        bluetoothViewModel: BluetoothViewModel,
        networkViewModel: NetworkViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager
    ) {
        self.powerService = powerService
        self.generalSettingsViewModel = generalSettingsViewModel
        self.notchViewModel = notchViewModel
        self.notchEventCoordinator = notchEventCoordinator
        self.bluetoothViewModel = bluetoothViewModel
        self.networkViewModel = networkViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        _viewModel = StateObject(
            wrappedValue: SettingsRootViewModel(
                settings: generalSettingsViewModel,
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator,
                bluetoothViewModel: bluetoothViewModel,
                powerService: powerService,
                networkViewModel: networkViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                lockScreenManager: lockScreenManager
            )
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

            #if DEBUG
            DebugSettingsView(
                viewModel: viewModel.debugViewModel
            )
            .tabItem {
                Label(
                    SettingsRootViewModel.Section.debug.title,
                    systemImage: SettingsRootViewModel.Section.debug.systemImage
                )
            }
            .tag(SettingsRootViewModel.Section.debug)
            .accessibilityIdentifier(SettingsRootViewModel.Section.debug.accessibilityIdentifier)
            #endif

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
