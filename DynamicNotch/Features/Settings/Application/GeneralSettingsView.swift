import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            systemCard
            themeCard
            displayCard
            languageCard
        }
        .accessibilityIdentifier("settings.general.root")
    }
    
    private var systemCard: some View {
        SettingsCard(title: "System") {
            SettingsToggleRow(
                title: "Launch at login",
                description: "Launch Dynamic Notch automatically when you sign in.",
                systemImage: "power",
                color: .red,
                isOn: $applicationSettings.isLaunchAtLoginEnabled,
                accessibilityIdentifier: "settings.general.launchAtLogin"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Show menu bar icon",
                description: "Show a menu bar shortcut for quick access to Settings and Quit.",
                systemImage: "menubar.rectangle",
                color: .blue,
                isOn: $applicationSettings.isMenuBarIconVisible,
                accessibilityIdentifier: "settings.general.menuBarIcon"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Show Dock icon",
                description: "Keep the app visible in the Dock for faster switching and window access.",
                systemImage: "dock.rectangle",
                color: .orange,
                isOn: $applicationSettings.isDockIconVisible,
                accessibilityIdentifier: "settings.general.dockIcon"
            )
        }
    }
    
    private var themeCard: some View {
        SettingsCard(title: "Appearance") {
            CustomPicker(
                selection: $applicationSettings.appearanceMode,
                options: Array(SettingsAppearanceMode.allCases),
                title: { $0.title },
                headerTitle: "Theme",
                headerDescription: "Choose the interface appearance used by the app.",
                itemHeight: 110,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { mode, isSelected in
                ThemeAppearancePickerContent(mode: mode, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.general.appearanceMode")
        }
    }

    private var displayCard: some View {
        SettingsCard(title: "Location") {
            CustomPicker(
                selection: $applicationSettings.displayLocation,
                options: Array(NotchDisplayLocation.allCases),
                title: { $0.title },
                headerTitle: "Display",
                headerDescription: "Choose which display Dynamic Notch should use.",
                symbolName: { $0.symbolName }
            )
            .accessibilityIdentifier("settings.general.displayLocation")

            Divider()
                .opacity(0.6)

            SettingsToggleRow(
                title: "Hide notch in full-screen mode",
                description: "Automatically hide Dynamic Notch while the selected display is showing a full-screen space.",
                systemImage: "arrow.up.left.and.arrow.down.right",
                color: .purple,
                isOn: $applicationSettings.isNotchHiddenInFullscreenEnabled,
                accessibilityIdentifier: "settings.general.hideNotchInFullscreen"
            )
        }
    }

    private var languageCard: some View {
        SettingsCard(title: "Localization") {
            VStack(alignment: .leading, spacing: 12) {
                AdaptiveCustomPicker(
                    selection: $applicationSettings.appLanguage,
                    options: Array(DynamicNotchLanguage.allCases),
                    headerTitle: "Language",
                    headerDescription: "Choose the language used by the app interface.",
                    minimumItemWidth: 88,
                    maximumItemWidth: 104,
                    title: { $0.titleKey },
                    accessibilityIdentifier: { "settings.language.option.\($0.rawValue)" }
                ) { language, isSelected in
                    
                    ZStack {
                        if let assetName = language.flagAssetName {
                            Image(assetName)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        } else {
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(width: 44, height: 34)
                }
                .accessibilityIdentifier("settings.language.card")

                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.yellow)

                    Text("Localization only works for settings, the notch remains in English.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}

private struct ThemeAppearancePickerContent: View {
    let mode: SettingsAppearanceMode
    let isSelected: Bool

    var body: some View {
        themePreview
    }

    @ViewBuilder
    private var themePreview: some View {
        switch mode {
        case .system:
            ZStack {
                ThemeMiniWindow(style: .light)
                    .frame(width: 100, height: 80)
                    .offset(x: -15)
                
                ThemeMiniWindow(style: .dark)
                    .frame(width: 100, height: 80)
                    .offset(x: 15)
            }

        case .light:
            ThemeMiniWindow(style: .light)
                .frame(width: 110, height: 80)

        case .dark:
            ThemeMiniWindow(style: .dark)
                .frame(width: 110, height: 80)
        }
    }
}

private struct ThemeMiniWindow: View {
    enum Style {
        case light
        case dark

        var background: Color {
            switch self {
            case .light:
                return Color(red: 0.985, green: 0.988, blue: 0.995)
            case .dark:
                return Color(red: 0.087, green: 0.098, blue: 0.118)
            }
        }

        var chrome: Color {
            switch self {
            case .light:
                return Color(red: 0.94, green: 0.95, blue: 0.972)
            case .dark:
                return Color(red: 0.118, green: 0.129, blue: 0.157)
            }
        }

        var sidebar: Color {
            switch self {
            case .light:
                return Color(red: 0.925, green: 0.937, blue: 0.962)
            case .dark:
                return Color(red: 0.102, green: 0.113, blue: 0.139)
            }
        }

        var surface: Color {
            switch self {
            case .light:
                return Color.gray.opacity(0.2)
            case .dark:
                return Color(red: 0.145, green: 0.161, blue: 0.196)
            }
        }

        var accent: Color {
            switch self {
            case .light:
                return Color(red: 0.29, green: 0.54, blue: 0.98)
            case .dark:
                return Color(red: 0.37, green: 0.67, blue: 1.0)
            }
        }

        var primary: Color {
            switch self {
            case .light:
                return Color.black.opacity(0.72)
            case .dark:
                return Color.white.opacity(0.84)
            }
        }

        var secondary: Color {
            switch self {
            case .light:
                return Color.black.opacity(0.26)
            case .dark:
                return Color.white.opacity(0.24)
            }
        }

        var stroke: Color {
            switch self {
            case .light:
                return Color.black.opacity(0.08)
            case .dark:
                return Color.white.opacity(0.08)
            }
        }

        var shadow: Color {
            switch self {
            case .light:
                return Color.black.opacity(0.08)
            case .dark:
                return Color.black.opacity(0.32)
            }
        }
    }

    let style: Style

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        shape
            .fill(style.background)
            .overlay {
                VStack(spacing: 0) {
                    chromeBar

                    HStack(spacing: 0) {
                        sidebar
                        content
                    }
                }
                .clipShape(shape)
            }
            .overlay {
                shape.stroke(style.stroke, lineWidth: 1)
            }
            .shadow(color: style.shadow, radius: 10, y: 4)
    }

    private var chromeBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 3) {
                Circle().fill(Color.red.opacity(style == .light ? 0.9 : 0.75))
                Circle().fill(Color.orange.opacity(style == .light ? 0.9 : 0.75))
                Circle().fill(Color.green.opacity(style == .light ? 0.9 : 0.75))
            }
            .frame(width: 20, height: 6)

            Spacer()
        }
        .padding(.horizontal, 6)
        .frame(height: 14)
        .background(style.chrome)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 5) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(style.secondary)
                .frame(width: 14, height: 4)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(style.accent.opacity(0.8))
                .frame(width: 14, height: 4)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(style.secondary)
                .frame(width: 14, height: 4)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(style.secondary)
                .frame(width: 14, height: 4)
            
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(style.secondary)
                .frame(width: 14, height: 4)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .frame(width: 26)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(style.sidebar)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 5) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(style.primary.opacity(0.76))
                .frame(width: 24, height: 5)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(style.accent.opacity(style == .light ? 0.14 : 0.22))
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(style.accent)
                        .frame(width: 14, height: 6)
                        .padding(4)
                }
                .frame(height: 20)

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(style.surface)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(style.surface)
            }
            .frame(height: 13)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(style.background)
    }
}
