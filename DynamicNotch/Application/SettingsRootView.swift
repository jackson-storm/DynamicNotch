import SwiftUI

enum SettingsWindowLayout {
    static let width: CGFloat = 760
    static let height: CGFloat = 610
}

struct SettingsRootView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    let notchViewModel: NotchViewModel
    let notchEventCoordinator: NotchEventCoordinator
    let bluetoothViewModel: BluetoothViewModel
    let networkViewModel: NetworkViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager

    private let viewModel: SettingsRootViewModel
    @State private var searchText = ""
    @State private var selectedSection: SettingsRootViewModel.Section
    @State private var pendingResetSection: SettingsRootViewModel.Section?

    init(
        powerService: PowerService,
        generalSettingsViewModel: GeneralSettingsViewModel,
        notchViewModel: NotchViewModel,
        notchEventCoordinator: NotchEventCoordinator,
        bluetoothViewModel: BluetoothViewModel,
        networkViewModel: NetworkViewModel,
        downloadViewModel: DownloadViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager
    ) {
        self.powerService = powerService
        self.generalSettingsViewModel = generalSettingsViewModel
        self.notchViewModel = notchViewModel
        self.notchEventCoordinator = notchEventCoordinator
        self.bluetoothViewModel = bluetoothViewModel
        self.networkViewModel = networkViewModel
        self.downloadViewModel = downloadViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        let rootViewModel = SettingsRootViewModel(
            settings: generalSettingsViewModel,
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

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                ForEach(groupedSections, id: \.group.id) { group in
                    Section {
                        ForEach(group.sections) { section in
                            NavigationLink(value: section) {
                                SettingsSidebarRow(
                                    title: section.title,
                                    systemImage: section.systemImage,
                                    tint: section.tint
                                )
                            }
                        }
                    } header: {
                        if let title = group.group.title {
                            Text(title)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
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
        .navigationTitle(filteredSections.isEmpty ? "Search" : resolvedSelection.title)
        .navigationSubtitle(filteredSections.isEmpty ? "" : resolvedSelection.subtitle)
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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    guard let toolbarSection else { return }
                    pendingResetSection = toolbarSection
                } label: {
                    Text("Default settings")
                }
                .disabled(!(toolbarSection.map { viewModel.canReset($0) } ?? false))
                .help(viewModel.resetHelpText(for: toolbarSection))
                .accessibilityIdentifier("settings.toolbar.resetCurrentTab")
            }
        }
        .alert(item: $pendingResetSection) { section in
            Alert(
                title: Text("Reset \(section.title) settings?"),
                message: Text("This will restore default values only for the current tab. This action cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    viewModel.reset(section)
                },
                secondaryButton: .cancel()
            )
        }
        .accessibilityIdentifier("settings.root")
    }

    private var filteredSections: [SettingsRootViewModel.Section] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return viewModel.sections
        }

        return viewModel.sections.filter { section in
            section.title.localizedCaseInsensitiveContains(query) ||
            section.subtitle.localizedCaseInsensitiveContains(query)
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

    private var toolbarSection: SettingsRootViewModel.Section? {
        guard !filteredSections.isEmpty else { return nil }
        return resolvedSelection
    }

    @ViewBuilder
    private func detailView(for section: SettingsRootViewModel.Section) -> some View {
        switch section {
        case .general:
            GeneralSettingsView(
                powerService: powerService,
                generalSettingsViewModel: generalSettingsViewModel
            )
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .nowPlaying:
            NowPlayingSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .downloads:
            DownloadsSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .airDrop:
            AirDropSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .focus:
            FocusSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .bluetooth:
            BluetoothSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .network:
            NetworkSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .battery:
            BatterySettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .hud:
            HUDSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        case .lockScreen:
            LockScreenSettingsView(generalSettingsViewModel: generalSettingsViewModel)
            .accessibilityIdentifier(section.accessibilityIdentifier)

        #if DEBUG
        case .debug:
            DebugSettingsView(
                viewModel: viewModel.debugViewModel
            )
            .accessibilityIdentifier(section.accessibilityIdentifier)
        #endif

        case .about:
            AboutAppSettingsView()
                .accessibilityIdentifier(section.accessibilityIdentifier)
        }
    }
}
