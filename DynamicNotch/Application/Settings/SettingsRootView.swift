import SwiftUI

enum SettingsWindowLayout {
    static let width: CGFloat = 760
    static let height: CGFloat = 610
}

struct SettingsRootView: View {
    @Environment(\.openURL) private var openURL
    
    @ObservedObject var powerService: PowerService
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    let notchViewModel: NotchViewModel
    let notchEventCoordinator: NotchEventCoordinator
    let bluetoothViewModel: BluetoothViewModel
    let networkViewModel: NetworkViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager
    
    private let aboutWebsiteURL = URL(string: "https://dynamicnotch.evgeniy-petrukovich.workers.dev/download")!
    private let viewModel: SettingsRootViewModel
    @State private var searchText = ""
    @State private var selectedSection: SettingsRootViewModel.Section
    @State private var pendingResetSection: SettingsRootViewModel.Section?
    @StateObject private var permissionController = SettingsPermissionController()
    
    init(
        powerService: PowerService,
        settingsViewModel: SettingsViewModel,
        notchViewModel: NotchViewModel,
        notchEventCoordinator: NotchEventCoordinator,
        bluetoothViewModel: BluetoothViewModel,
        networkViewModel: NetworkViewModel,
        downloadViewModel: DownloadViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager
    ) {
        self.powerService = powerService
        self.settingsViewModel = settingsViewModel
        self.notchViewModel = notchViewModel
        self.notchEventCoordinator = notchEventCoordinator
        self.bluetoothViewModel = bluetoothViewModel
        self.networkViewModel = networkViewModel
        self.downloadViewModel = downloadViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        let rootViewModel = SettingsRootViewModel(
            settingsViewModel: settingsViewModel,
            notchViewModel: notchViewModel,
            notchEventCoordinator: notchEventCoordinator,
            bluetoothViewModel: bluetoothViewModel,
            powerService: powerService,
            networkViewModel: networkViewModel,
            downloadViewModel: downloadViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            lockScreenManager: lockScreenManager
        )
        self.viewModel = rootViewModel
        _selectedSection = State(initialValue: rootViewModel.initialSelection())
    }
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        settingsViewModel.application.appLanguage.locale.dn(key, fallback: fallback)
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                ForEach(groupedSections, id: \.group.id) { group in
                    Section {
                        ForEach(group.sections) { section in
                            NavigationLink(value: section) {
                                SettingsSidebarRow(
                                    title: localized(section.titleKey, fallback: section.fallbackTitle),
                                    systemImage: section.systemImage,
                                    tint: section.tint
                                )
                            }
                        }
                    } header: {
                        if let titleKey = group.group.titleKey {
                            Text(localized(titleKey, fallback: group.group.fallbackTitle))
                        }
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .sidebar,
                prompt: localized("settings.search.prompt")
            )
            .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 200)
            
        } detail: {
            Group {
                if filteredSections.isEmpty {
                    SettingsSearchEmptyState(query: searchText)
                } else {
                    detailView(for: resolvedSelection)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .navigationTitle(
            filteredSections.isEmpty
            ? localized("settings.search.title")
            : localized(resolvedSelection.titleKey, fallback: resolvedSelection.fallbackTitle)
        )
        .navigationSubtitle(
            filteredSections.isEmpty
            ? ""
            : localized(resolvedSelection.subtitleKey, fallback: resolvedSelection.fallbackSubtitle)
        )
        .onChange(of: searchText) { _, _ in
            guard !filteredSections.isEmpty else { return }
            if !filteredSections.contains(selectedSection) {
                let newSelection = filteredSections[0]
                if selectedSection != newSelection {
                    selectedSection = newSelection
                }
            }
        }
        .onChange(of: selectedSection) { oldValue, newValue in
            viewModel.persistSelection(newValue)
        }
        .onAppear {
            selectedSection = viewModel.initialSelection()
        }
        .alert(item: $pendingResetSection) { section in
            Alert(
                title: Text(
                    String(
                        format: localized("settings.reset.title"),
                        localized(section.titleKey, fallback: section.fallbackTitle)
                    )
                ),
                message: Text(localized("settings.reset.message")),
                primaryButton: .destructive(Text(localized("settings.reset.action"))) {
                    viewModel.reset(section)
                },
                secondaryButton: .cancel(Text(localized("common.cancel")))
            )
        }
        .accessibilityIdentifier("settings.root")
        .environment(\.locale, settingsViewModel.application.appLanguage.locale)
        .preferredColorScheme(settingsViewModel.application.appearanceMode.preferredColorScheme)
        .tint(settingsViewModel.application.appTint.color)
        .accentColor(settingsViewModel.application.appTint.color)
    }
    
    private var filteredSections: [SettingsRootViewModel.Section] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return viewModel.sections
        }
        
        return viewModel.sections.filter { section in
            localized(section.titleKey, fallback: section.fallbackTitle).localizedCaseInsensitiveContains(query) ||
            localized(section.subtitleKey, fallback: section.fallbackSubtitle).localizedCaseInsensitiveContains(query)
        }
    }
    
    private var groupedSections: [(group: SettingsRootViewModel.SidebarGroup, sections: [SettingsRootViewModel.Section])] {
        SettingsRootViewModel.SidebarGroup.allCases.compactMap { group in
            let sections = filteredSections.filter { $0.sidebarGroup == group }
            guard !sections.isEmpty else { return nil }
            return (group, sections)
        }
    }
    
    private var resolvedSelection: SettingsRootViewModel.Section {
        if filteredSections.contains(selectedSection) {
            return selectedSection
        }
        
        return filteredSections.first ?? .general
    }
    
    @ViewBuilder
    private func detailView(for section: SettingsRootViewModel.Section) -> some View {
        switch section {
        case .general:
            detailContainer(for: section) {
                GeneralSettingsView(
                    applicationSettings: settingsViewModel.application
                )
            }
            
        case .notch:
            detailContainer(for: section) {
                NotchSettingsView(
                    powerService: powerService,
                    applicationSettings: settingsViewModel.application
                )
            }
            
        case .nowPlaying:
            detailContainer(for: section) {
                NowPlayingSettingsView(settings: settingsViewModel.mediaAndFiles)
            }
            
        case .downloads:
            detailContainer(for: section) {
                DownloadsSettingsView(
                    mediaSettings: settingsViewModel.mediaAndFiles,
                    appearanceSettings: settingsViewModel.application,
                    downloadViewModel: downloadViewModel
                )
            }
            
        case .airDrop:
            detailContainer(for: section) {
                AirDropSettingsView(
                    mediaSettings: settingsViewModel.mediaAndFiles,
                    appearanceSettings: settingsViewModel.application
                )
            }
            
        case .focus:
            detailContainer(for: section) {
                FocusSettingsView(
                    connectivitySettings: settingsViewModel.connectivity,
                    appearanceSettings: settingsViewModel.application
                )
            }
            
        case .bluetooth:
            detailContainer(for: section) {
                BluetoothSettingsView(settings: settingsViewModel.connectivity)
            }
            
        case .network:
            detailContainer(for: section) {
                NetworkSettingsView(
                    connectivitySettings: settingsViewModel.connectivity,
                    appearanceSettings: settingsViewModel.application
                )
            }
            
        case .battery:
            detailContainer(for: section) {
                BatterySettingsView(
                    batterySettings: settingsViewModel.battery,
                    appearanceSettings: settingsViewModel.application
                )
            }
            
        case .hud:
            detailContainer(for: section) {
                HUDSettingsView(settings: settingsViewModel.hud)
            }
            
        case .lockScreen:
            detailContainer(for: section) {
                LockScreenSettingsView(settings: settingsViewModel.lockScreen, applicationSettings: settingsViewModel.application)
            }
            
        #if DEBUG
        case .debug:
            detailContainer(for: section) {
                DebugSettingsView(
                    viewModel: viewModel.debugViewModel
                )
            }
        #endif
            
        case .about:
            detailContainer(for: section) {
                AboutAppSettingsView(applicationSettings: settingsViewModel.application)
            }
        }
    }
    
    private func detailContainer<Content: View>(for section: SettingsRootViewModel.Section, @ViewBuilder content: () -> Content) -> some View {
        content()
            .accessibilityIdentifier(section.accessibilityIdentifier)
            .toolbar { toolbarContent(for: section) }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent(for section: SettingsRootViewModel.Section) -> some ToolbarContent {
        if let permissionAction = toolbarPermissionAction(for: section) {
            ToolbarItem(placement: .primaryAction) {
                Button(action: permissionAction.handler) {
                    Label {
                        Text(
                            localized(
                                permissionAction.titleKey,
                                fallback: permissionAction.fallbackTitle
                            )
                        )
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                }
                .help(
                    localized(
                        permissionAction.helpKey,
                        fallback: permissionAction.fallbackHelp
                    )
                )
                .accessibilityIdentifier(permissionAction.accessibilityIdentifier)
            }
        }

        if section == .about {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openURL(aboutWebsiteURL)
                } label: {
                    Text("Check update")
                }
                .help("Open the DynamicNotch website")
                .accessibilityIdentifier("settings.toolbar.aboutWebsite")
            }
        }
        
        if viewModel.canReset(section) {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    pendingResetSection = section
                } label: {
                    Text("Reset")
                }
                .help(
                    viewModel.resetHelpText(
                        for: section,
                        locale: settingsViewModel.application.appLanguage.locale
                    )
                )
                .accessibilityIdentifier("settings.toolbar.resetCurrentTab")
            }
        }
    }

    private func toolbarPermissionAction(for section: SettingsRootViewModel.Section) -> SettingsPermissionController.ToolbarAction? {
        switch section {
        case .hud:
            let requiresAccessibility =
                settingsViewModel.hud.isVolumeHUDEnabled ||
                settingsViewModel.hud.isBrightnessHUDEnabled
            guard requiresAccessibility else { return nil }

        case .nowPlaying:
            guard settingsViewModel.mediaAndFiles.isNowPlayingLiveActivityEnabled else {
                return nil
            }

        default:
            return nil
        }

        return permissionController.toolbarAction(for: section)
    }
}
