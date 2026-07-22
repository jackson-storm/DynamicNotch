import SwiftUI
internal import AppKit

enum SettingsWindowLayout {
    static let width: CGFloat = 760
    static let height: CGFloat = 590
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

    private let viewModel: SettingsRootViewModel
    
    @AppStorage("settings.general.isBlueNightMode") private var isBlueNightMode = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var nsBackgroundColor: NSColor {
        if isBlueNightMode && colorScheme == .dark {
            return NSColor(red: 0.07, green: 0.11, blue: 0.17, alpha: 1.0)
        } else if colorScheme == .dark {
            return NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        } else {
            return NSColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1.0)
        }
    }
    
    @StateObject private var permissionController = SettingsPermissionController()
    @State private var searchText = ""
    @State private var selectedSection: SettingsRootViewModel.Section
    @State private var selectionHistory: SettingsRootViewModel.SelectionHistory
    @State private var isShowingSearchSelection = false
    @State private var pendingResetSubPage: SettingsSubPage?
    @State private var navigationPath: [SettingsSubPage] = []
    @State private var availableDisplays = NSScreen.availableNotchDisplays()
    @ObservedObject private var updater = SparkleUpdater.shared

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
                                        tint: section.tint,
                                        showBadge: section == .general && updater.isUpdateAvailable
                                    )
                                } else {
                                    SettingsSidebarRow(
                                        title: localized(section.titleKey, fallback: section.fallbackTitle),
                                        systemImage: section.systemImage,
                                        tint: section.tint,
                                        showBadge: section == .general && updater.isUpdateAvailable
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(colorScheme == .dark ? .hidden : .visible)
            .background {
                if colorScheme == .dark {
                    if isBlueNightMode {
                        Color(red: 0.090, green: 0.129, blue: 0.169)
                    } else {
                        Color(red: 0.14, green: 0.14, blue: 0.15)
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .sidebar,
                prompt: localized("settings.search.prompt")
            )
            .background {
                if colorScheme == .dark {
                    if isBlueNightMode {
                        Color(red: 0.090, green: 0.129, blue: 0.169).ignoresSafeArea()
                    } else {
                        Color(red: 0.14, green: 0.14, blue: 0.15).ignoresSafeArea()
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 200, max: 200)

        } detail: {
            NavigationStack(path: $navigationPath) {
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
                        .background {
                            Color(nsColor: nsBackgroundColor)
                        }
                        .overlay(alignment: .bottom) {
                            Divider()
                                .opacity(0.6)
                        }
                        .ignoresSafeArea(.container, edges: .top)
                }
                .scrollContentBackground(.hidden)
                .background {
                    Color(nsColor: nsBackgroundColor)
                }
                .navigationDestination(for: SettingsSubPage.self) { subPage in
                    ZStack(alignment: .top) {
                        subPageView(for: subPage)
                        
                        Color.clear
                            .frame(height: 52)
                            .background {
                                Color(nsColor: nsBackgroundColor)
                            }
                            .overlay(alignment: .bottom) {
                                Divider()
                                    .opacity(0.6)
                            }
                            .ignoresSafeArea(.container, edges: .top)
                    }
                    .navigationBarBackButtonHidden(true)
                    .toolbar { toolbarContent(for: resolvedSelection) }
                }
            }
        }
        .navigationTitle(currentTitle)
        .navigationSubtitle(currentSubtitle)
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
        }        .alert(item: $pendingResetSubPage) { subPage in
            Alert(
                title: Text(localized("settings.reset.title")),
                message: Text(localized("settings.reset.message")),
                primaryButton: .destructive(Text(localized("settings.reset.action"))) {
                    reset(subPage)
                },
                secondaryButton: .cancel(Text(localized("common.cancel")))
            )
        }
        .accessibilityIdentifier("settings.root")
        .environment(\.locale, settingsViewModel.application.appLanguage.locale)
        .preferredColorScheme(settingsViewModel.application.appearanceMode.preferredColorScheme)
        .background {
            Color(nsColor: nsBackgroundColor)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SelectSettingsSection"))) { notification in
            if let section = notification.object as? SettingsRootViewModel.Section {
                applySelection(section, origin: .sidebar)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SelectSettingsSubPage"))) { notification in
            if let subPage = notification.object as? SettingsSubPage {
                applySelection(.general, origin: .sidebar)
                navigationPath = [subPage]
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
        !navigationPath.isEmpty || selectionHistory.canGoBack
    }

    private var canNavigateForward: Bool {
        navigationPath.isEmpty && selectionHistory.canGoForward
    }

    private func applySelection(_ section: SettingsRootViewModel.Section, origin: SelectionChangeOrigin) {
        navigationPath.removeAll()
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
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            return
        }
        guard let previousSection = selectionHistory.goBack() else { return }
        revealSectionIfNeeded(previousSection)
        applySelection(previousSection, origin: .history)
    }

    private func navigateForward() {
        guard navigationPath.isEmpty else { return }
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
                    applicationSettings: settingsViewModel.application,
                    permissionController: permissionController
                )
            }


        case .nowPlaying:
            detailContainer(for: section) {
                NowPlayingSettingsView(
                    settings: settingsViewModel.mediaAndFiles,
                    applicationSettings: settingsViewModel.application
                )
            }

        case .homePage:
            detailContainer(for: section) {
                 HomePageSettingsView(
                     homePageSettings: settingsViewModel.homePage,
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

        if let subPage = navigationPath.last, subPage.canReset {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    pendingResetSubPage = subPage
                } label: {
                    Text("Reset")
                }
                .help(
                    String(
                        format: localized("settings.reset.help.available", fallback: "Reset current tab to defaults"),
                        localized(subPage.titleKey, fallback: subPage.fallbackTitle)
                    )
                )
                .accessibilityIdentifier("settings.toolbar.resetCurrentSubPage")
            }
        }
    }

    private func openInternetURL(_ url: URL) {
        guard notchEventCoordinator.requestInternetAccess() else { return }
        openURL(url)
    }

    @ViewBuilder
    private func subPageView(for subPage: SettingsSubPage) -> some View {
        switch subPage {
        case .appearance:
            AppearanceSettingsView(applicationSettings: settingsViewModel.application)
        case .notch:
            NotchSettingsView(
                powerService: powerService,
                applicationSettings: settingsViewModel.application,
                availableDisplays: $availableDisplays
            )
        case .language:
            LanguageSettingsView(applicationSettings: settingsViewModel.application)
        case .system:
            SystemSettingsView(applicationSettings: settingsViewModel.application)
        case .permissions:
            PermissionsSettingsView(permissionController: permissionController, applicationSettings: settingsViewModel.application)
        case .softwareUpdate:
            SoftwareUpdateSettingsView()
        case .support:
            SupportSettingsView(
                onRequestInternetAccess: {
                    notchEventCoordinator.requestInternetAccess()
                }
            )
        case .about:
            AboutAppSettingsView(
                applicationSettings: settingsViewModel.application,
                onRequestInternetAccess: {
                    notchEventCoordinator.requestInternetAccess()
                }
            )
        #if DEBUG
        case .debug:
            DebugSettingsView(viewModel: viewModel.debugViewModel)
        #endif
        case .activityPriorities:
            ActivityPrioritiesSettingsView(applicationSettings: settingsViewModel.application)
        case .notchDisplay:
            DisplaySettingsView(applicationSettings: settingsViewModel.application, availableDisplays: $availableDisplays)
        case .notchAnimation:
            AnimationSettingsView(applicationSettings: settingsViewModel.application)
        case .gestures:
            GesturesSettingsView(applicationSettings: settingsViewModel.application)
        case .fileTray:
            FileTraySettingsView(
                mediaSettings: settingsViewModel.mediaAndFiles,
                appearanceSettings: settingsViewModel.application
            )
        case .fileConverter:
            FileConverterSettingsView(
                mediaSettings: settingsViewModel.mediaAndFiles
            )
        }
    }

    private var currentTitle: String {
        if filteredSections.isEmpty {
            return localized("settings.search.title")
        }
        if let subPage = navigationPath.last {
            return localized(subPage.titleKey, fallback: subPage.fallbackTitle)
        }
        return localized(resolvedSelection.titleKey, fallback: resolvedSelection.fallbackTitle)
    }

    private var currentSubtitle: String {
        if filteredSections.isEmpty {
            return ""
        }
        if let subPage = navigationPath.last {
            return localized(subPage.subtitleKey, fallback: subPage.fallbackSubtitle)
        }
        return localized(resolvedSelection.subtitleKey, fallback: resolvedSelection.fallbackSubtitle)
    }

    private func reset(_ subPage: SettingsSubPage) {
        switch subPage {
        case .appearance:
            settingsViewModel.application.resetAppearance()
        case .notch:
            settingsViewModel.application.resetNotch()
            settingsViewModel.application.resetDisplay()
        case .language:
            settingsViewModel.application.resetLanguage()
        case .activityPriorities:
            settingsViewModel.application.resetNotchContentPriorities()
        case .notchDisplay:
            settingsViewModel.application.resetDisplay()
        case .notchAnimation:
            settingsViewModel.application.resetAnimation()
        case .gestures:
            settingsViewModel.application.resetGestures()
        case .fileTray:
            settingsViewModel.mediaAndFiles.resetFileTray()
        case .fileConverter:
            settingsViewModel.mediaAndFiles.resetFileConverter()
        default:
            break
        }
    }
}
