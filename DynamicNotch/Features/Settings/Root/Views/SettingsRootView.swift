import SwiftUI
internal import AppKit

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
    let wifiViewModel: WifiViewModel
    let vpnViewModel: VpnViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let timerViewModel: TimerViewModel
    let lockScreenManager: LockScreenManager

    private let aboutWebsiteURL = URL(string: "https://dynamicnotch.evgeniy-petrukovich.workers.dev/download")!
    private let viewModel: SettingsRootViewModel
    
    @AppStorage("settings.general.isBlueNightMode") private var isBlueNightMode = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var nsBackgroundColor: NSColor {
        if isBlueNightMode && colorScheme == .dark {
            return NSColor(red: 0.055, green: 0.086, blue: 0.129, alpha: 1.0)
        } else if colorScheme == .dark {
            return NSColor.controlBackgroundColor
        } else {
            return NSColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1.0)
        }
    }
    
    @StateObject private var permissionController = SettingsPermissionController()
    @State private var searchText = ""
    @State private var selectedSection: SettingsRootViewModel.Section
    @State private var selectionHistory: SettingsRootViewModel.SelectionHistory
    @State private var isShowingSearchSelection = false
    @State private var pendingResetSection: SettingsRootViewModel.Section?

    init(
        powerService: PowerService,
        settingsViewModel: SettingsViewModel,
        notchViewModel: NotchViewModel,
        notchEventCoordinator: NotchEventCoordinator,
        bluetoothViewModel: BluetoothViewModel,
        wifiViewModel: WifiViewModel,
        vpnViewModel: VpnViewModel,
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
        self.wifiViewModel = wifiViewModel
        self.vpnViewModel = vpnViewModel
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
            wifiViewModel: wifiViewModel,
            vpnViewModel: vpnViewModel,
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
                    }
                }
            }
            .scrollContentBackground(isBlueNightMode && colorScheme == .dark ? .hidden : .visible)
            .background {
                if isBlueNightMode && colorScheme == .dark {
                    Color(red: 0.090, green: 0.129, blue: 0.169)
                }
            }
            .searchable(
                text: $searchText,
                placement: .sidebar,
                prompt: localized("settings.search.prompt")
            )
            .background {
                if isBlueNightMode && colorScheme == .dark {
                    Color(red: 0.090, green: 0.129, blue: 0.169).ignoresSafeArea()
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 200)

        } detail: {
            NavigationStack {
                ZStack(alignment: .top) {
                    Group {
                        if filteredSections.isEmpty {
                            SettingsSearchEmptyState(query: searchText)
                        } else {
                            detailView(for: resolvedSelection)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                    
                    Color.clear
                        .frame(height: 52)
                        .background(Color(nsColor: nsBackgroundColor))
                        .overlay(alignment: .bottom) {
                            Divider()
                                .opacity(0.6)
                        }
                        .ignoresSafeArea(.container, edges: .top)
                }
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: nsBackgroundColor))
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
            updateWindowStyle()
        }
        .onChange(of: isBlueNightMode) {
            updateWindowStyle()
        }
        .onChange(of: colorScheme) {
            updateWindowStyle()
        }
        .onChange(of: settingsViewModel.application.appearanceMode) {
            updateWindowStyle()
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
        .background(Color(nsColor: nsBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SelectSettingsSection"))) { notification in
            if let section = notification.object as? SettingsRootViewModel.Section {
                applySelection(section, origin: .sidebar)
            }
        }
    }

    private func updateWindowStyle() {
        guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "DynamicNotchSettingsWindow" }) else {
            return
        }
        
        switch settingsViewModel.application.appearanceMode {
        case .system:
            window.appearance = nil
        case .light:
            window.appearance = NSAppearance(named: .aqua)
        case .dark:
            window.appearance = NSAppearance(named: .darkAqua)
        }
        
        window.backgroundColor = nsBackgroundColor
        window.isOpaque = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
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

    private func applySelection(_ section: SettingsRootViewModel.Section, origin: SelectionChangeOrigin) {
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
                    applicationSettings: settingsViewModel.application,
                    homePageSettings: settingsViewModel.homePage
                )
            }

        case .nowPlaying:
            detailContainer(for: section) {
                NowPlayingSettingsView(
                    settings: settingsViewModel.mediaAndFiles,
                    applicationSettings: settingsViewModel.application
                )
            }
            
        case .calendar:
            detailContainer(for: section) {
                CalendarSettingsView(
                    settings: settingsViewModel.calendar
                )
            }

        case .downloads:
            detailContainer(for: section) {
                DownloadsSettingsView(
                    mediaSettings: settingsViewModel.mediaAndFiles,
                    appearanceSettings: settingsViewModel.application
                )
            }

        case .drop:
            detailContainer(for: section) {
                DragAndDropSettingsView(
                    mediaSettings: settingsViewModel.mediaAndFiles,
                    appearanceSettings: settingsViewModel.application
                )
            }

        case .timer:
            detailContainer(for: section) {
                TimerSettingsView(
                    mediaSettings: settingsViewModel.mediaAndFiles,
                    appearanceSettings: settingsViewModel.application
                )
            }

        case .screenRecording:
            detailContainer(for: section) {
                ScreenRecordingSettingsView(
                    settings: settingsViewModel.screenRecording,
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

        case .wifi:
            detailContainer(for: section) {
                WifiSettingsView(
                    connectivitySettings: settingsViewModel.connectivity,
                    appearanceSettings: settingsViewModel.application
                )
            }

        case .vpn:
            detailContainer(for: section) {
                VpnSettingsView(
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
                AboutAppSettingsView(
                    applicationSettings: settingsViewModel.application,
                    onRequestInternetAccess: {
                        notchEventCoordinator.requestInternetAccess()
                    }
                )
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
                    openInternetURL(aboutWebsiteURL)
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

    private func openInternetURL(_ url: URL) {
        guard notchEventCoordinator.requestInternetAccess() else { return }
        openURL(url)
    }
}
