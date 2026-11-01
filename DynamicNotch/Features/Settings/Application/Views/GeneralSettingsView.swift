import SwiftUI
internal import AppKit

enum GeneralTab: String, CaseIterable, Identifiable {
    case notch
    case language
    case other
    
    var id: String { rawValue }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .notch:
            return "settings.section.notch.title"
        case .language:
            return "settings.section.language.title"
        case .other:
            return "settings.general.tab.other"
        }
    }
    
    var titleKeyString: String {
        switch self {
        case .notch:
            return "settings.section.notch.title"
        case .language:
            return "settings.section.language.title"
        case .other:
            return "settings.general.tab.other"
        }
    }
    
    var fallbackTitle: String {
        switch self {
        case .notch:
            return "Notch"
        case .language:
            return "Language"
        case .other:
            return "Other"
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @Binding var availableDisplays: [NotchDisplayOption]
    @Binding var selectedTab: GeneralTab
    
    init(
        powerService: PowerService,
        applicationSettings: ApplicationSettingsStore,
        availableDisplays: Binding<[NotchDisplayOption]>,
        selectedTab: Binding<GeneralTab>
    ) {
        self._powerService = ObservedObject(wrappedValue: powerService)
        self._applicationSettings = ObservedObject(wrappedValue: applicationSettings)
        self._availableDisplays = availableDisplays
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        Group {
            switch selectedTab {
            case .notch:
                NotchSettingsView(
                    powerService: powerService,
                    applicationSettings: applicationSettings,
                    availableDisplays: $availableDisplays
                )
            case .language:
                LanguageSettingsView(
                    applicationSettings: applicationSettings,
                    isEmbedded: true
                )
            case .other:
                OtherSettingsView(
                    applicationSettings: applicationSettings
                )
            }
        }
        .accessibilityIdentifier("settings.general.root")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("", selection: $selectedTab.animation(.easeInOut(duration: 0.15))) {
                    ForEach(GeneralTab.allCases) { tab in
                        Text(tab.titleKey).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }
    
    private var systemCard: some View {
        SettingsCard(title: "settings.general.system.title") {
            SettingsToggleRow(
                title: "settings.system.launchAtLogin.title",
                description: "settings.system.launchAtLogin.desc",
                systemImage: "power",
                color: .red,
                isOn: $applicationSettings.isLaunchAtLoginEnabled,
                accessibilityIdentifier: "settings.general.launchAtLogin"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.system.dockIcon.title",
                description: "settings.system.dockIcon.desc",
                systemImage: "dock.rectangle",
                color: .orange,
                isOn: $applicationSettings.isDockIconVisible,
                accessibilityIdentifier: "settings.general.dockIcon"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 14) {
                SettingsToggleRow(
                    title: "settings.system.menuBarIcon.title",
                    description: "settings.system.menuBarIcon.desc",
                    systemImage: "menubar.rectangle",
                    color: .blue,
                    isOn: $applicationSettings.isMenuBarIconVisible,
                    accessibilityIdentifier: "settings.general.menuBarIcon"
                )
                if !applicationSettings.isMenuBarIconVisible {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.yellow)
                        
                        Text(LocalizedStringKey("settings.system.menuBarIcon.warning"))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
    }
}
