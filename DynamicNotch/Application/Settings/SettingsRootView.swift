import SwiftUI

enum SettingsWindowLayout {
    static let width: CGFloat = 760
    static let height: CGFloat = 610
}

struct SettingsRootView: View {
    private enum SelectionChangeOrigin {
        case sidebar
        case history
        case search
        case initial
    }

    @Environment(\.openURL) private var openURL
    @ObservedObject var powerService: PowerService
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    let notchViewModel: NotchViewModel
    let notchEventCoordinator: NotchEventCoordinator
    let bluetoothViewModel: BluetoothViewModel
    let networkViewModel: NetworkViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let timerViewModel: TimerViewModel
    let lockScreenManager: LockScreenManager
    
    private let aboutWebsiteURL = URL(string: "https://dynamicnotch.evgeniy-petrukovich.workers.dev/download")!
    private let viewModel: SettingsRootViewModel
    @State private var searchText = ""
    @State private var selectedSection: SettingsRootViewModel.Section
    @State private var selectionHistory: SettingsRootViewModel.SelectionHistory
    @State private var isShowingSearchSelection = false
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
        timerViewModel: TimerViewModel,
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
        self.timerViewModel = timerViewModel
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
            timerViewModel: timerViewModel,
            lockScreenManager: lockScreenManager
        )
        self.viewModel = rootViewModel
        let initialSelection = rootViewModel.initialSelection()
        _selectedSection = State(initialValue: initialSelection)
        _selectionHistory = State(initialValue: .init(initialSelection: initialSelection))
    }
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        settingsViewModel.application.appLanguage.locale.dn(key, fallback: fallback)
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: selectionBinding) {
                ForEach(groupedSections, id: \.group.id) { group in
                    Section {
                        ForEach(group.sections) { section in
                            NavigationLink(value: section) {
                                if let imageName = section.imageName {
                                    SettingsSidebarRow(
                                        title: localized(section.titleKey, fallback: section.fallbackTitle),
                                        imageName: imageName,
                                        tint: section.tint
                                    )
                                } else {
                                    SettingsSidebarRow(
                                        title: localized(section.titleKey, fallback: section.fallbackTitle),
                                        systemImage: section.systemImage,
                                        tint: section.tint
                                    )
                                }
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
        .onChange(of: searchText) { _, newValue in
            syncSelectionWithSearch(query: newValue)
        }
        .onAppear {
            applySelection(viewModel.initialSelection(), origin: .initial)
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
    }

    private var selectionBinding: Binding<SettingsRootViewModel.Section> {
        Binding(
            get: { selectedSection },
            set: { applySelection($0, origin: .sidebar) }
        )
    }
    
    private var filteredSections: [SettingsRootViewModel.Section] {
        let query = trimmedSearchText
        guard !query.isEmpty else {
            return viewModel.sections
        }
        
        return viewModel.sections.filter { section in
            searchableStrings(for: section).contains { value in
                value.localizedCaseInsensitiveContains(query)
            }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func searchableStrings(for section: SettingsRootViewModel.Section) -> [String] {
        [
            localized(section.titleKey, fallback: section.fallbackTitle),
            section.fallbackTitle,
            localized(section.subtitleKey, fallback: section.fallbackSubtitle),
            section.fallbackSubtitle
        ] + section.searchKeywords
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
    
    private var canNavigateBack: Bool {
        selectionHistory.canGoBack
    }

    private var canNavigateForward: Bool {
        selectionHistory.canGoForward
    }

    private func applySelection(
        _ section: SettingsRootViewModel.Section,
        origin: SelectionChangeOrigin
    ) {
        switch origin {
        case .sidebar:
            guard selectedSection != section ||
                    isShowingSearchSelection ||
                    selectionHistory.currentSelection != section else {
                return
            }

            selectionHistory.record(section)
            selectedSection = section
            isShowingSearchSelection = false
            viewModel.persistSelection(section)

        case .history:
            guard selectedSection != section || isShowingSearchSelection else { return }
            selectedSection = section
            isShowingSearchSelection = false
            viewModel.persistSelection(section)

        case .search:
            guard selectedSection != section || !isShowingSearchSelection else { return }
            selectedSection = section
            isShowingSearchSelection = true

        case .initial:
            selectionHistory = .init(initialSelection: section)
            selectedSection = section
            isShowingSearchSelection = false
        }
    }

    private func syncSelectionWithSearch(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedQuery.isEmpty {
            guard isShowingSearchSelection else { return }
            applySelection(selectionHistory.currentSelection, origin: .history)
            return
        }

        guard !filteredSections.isEmpty else { return }

        if !filteredSections.contains(selectedSection) {
            applySelection(filteredSections[0], origin: .search)
        }
    }

    private func navigateBack() {
        guard let previousSection = selectionHistory.goBack() else { return }
        revealSectionIfNeeded(previousSection)
        applySelection(previousSection, origin: .history)
    }

    private func navigateForward() {
        guard let nextSection = selectionHistory.goForward() else { return }
        revealSectionIfNeeded(nextSection)
        applySelection(nextSection, origin: .history)
    }

    private func revealSectionIfNeeded(_ section: SettingsRootViewModel.Section) {
        guard !trimmedSearchText.isEmpty else { return }
        guard !filteredSections.contains(section) else { return }
        searchText = ""
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

        case .permissions:
            detailContainer(for: section) {
                PermissionsSettingsView(
                    permissionController: permissionController,
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
                NowPlayingSettingsView(
                    settings: settingsViewModel.mediaAndFiles,
                    applicationSettings: settingsViewModel.application
                )
            }
            
        case .downloads:
            detailContainer(for: section) {
                DownloadsSettingsView(
                    mediaSettings: settingsViewModel.mediaAndFiles,
                    appearanceSettings: settingsViewModel.application
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
                BluetoothSettingsView(
                    settings: settingsViewModel.connectivity,
                    applicationSettings: settingsViewModel.application
                )
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
                HUDSettingsView(
                    settings: settingsViewModel.hud,
                    applicationSettings: settingsViewModel.application
                )
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
        ToolbarItemGroup(placement: .navigation) {
            Button {
                navigateBack()
            } label: {
                Image(systemName: "chevron.backward")
            }
            .disabled(!canNavigateBack)
            .help(localized("settings.navigation.back", fallback: "Back"))
            .keyboardShortcut("[", modifiers: [.command])
            .accessibilityLabel(Text(localized("settings.navigation.back", fallback: "Back")))
            .accessibilityIdentifier("settings.toolbar.back")

            Button {
                navigateForward()
            } label: {
                Image(systemName: "chevron.forward")
            }
            .disabled(!canNavigateForward)
            .help(localized("settings.navigation.forward", fallback: "Forward"))
            .keyboardShortcut("]", modifiers: [.command])
            .accessibilityLabel(Text(localized("settings.navigation.forward", fallback: "Forward")))
            .accessibilityIdentifier("settings.toolbar.forward")
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
}
