internal import AppKit
import SwiftUI

struct FloatingLyricsSettingsSection: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject private var translationStore = LyricsTranslationStore.shared
    @State private var isLanguageDownloadRequested = false

    private var isEnabled: Bool {
        settings.isNowPlayingFloatingLyricsEnabled
    }

    var body: some View {
        Group {
            general
            layout
            behavior
            timing
            translation
            shortcuts
        }
    }

    private var general: some View {
        SettingsCard(title: "settings.floatingLyrics.card.general") {
            FloatingLyricsPreview(appearance: settings.floatingLyricsAppearance)

            Divider().opacity(0.6)

            SettingsToggleRow(
                title: "settings.nowPlaying.floatingLyrics.title",
                description: "settings.nowPlaying.floatingLyrics.desc",
                systemImage: "pip.fill",
                color: .purple,
                isOn: $settings.isNowPlayingFloatingLyricsEnabled,
                accessibilityIdentifier: "settings.activities.live.nowPlaying.floatingLyrics"
            )

            Divider().opacity(0.6)

            SettingsButtonRow(
                title: "settings.floatingLyrics.resetPosition.title",
                description: "settings.floatingLyrics.resetPosition.desc",
                buttonTitle: "settings.floatingLyrics.resetPosition.button",
                isButtonDisabled: !isEnabled,
                accessibilityIdentifier: "settings.floatingLyrics.resetPosition"
            ) {
                NotificationCenter.default.post(name: FloatingLyricsWindowManager.resetPositionNotification, object: nil)
            }
        }
    }

    private var layout: some View {
        SettingsCard(title: "settings.floatingLyrics.card.layout") {
            Group {
                SettingsToggleRow(
                    title: "settings.floatingLyrics.trackInfo.title",
                    description: "settings.floatingLyrics.trackInfo.desc",
                    systemImage: "music.note",
                    color: .pink,
                    iconBadge: false,
                    isOn: $settings.isFloatingLyricsTrackInfoVisible,
                    accessibilityIdentifier: "settings.floatingLyrics.trackInfo"
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "settings.floatingLyrics.nextLine.title",
                    description: "settings.floatingLyrics.nextLine.desc",
                    systemImage: "text.line.last.and.arrowtriangle.forward",
                    color: .indigo,
                    iconBadge: false,
                    isOn: $settings.isFloatingLyricsNextLineVisible,
                    accessibilityIdentifier: "settings.floatingLyrics.nextLine"
                )

                Divider().opacity(0.6)

                SettingsMenuRow(
                    title: "settings.floatingLyrics.color.title",
                    description: "settings.floatingLyrics.color.desc",
                    options: Array(FloatingLyricsColorStyle.allCases),
                    optionTitle: { $0.title },
                    accessibilityIdentifier: "settings.floatingLyrics.colorStyle",
                    selection: $settings.floatingLyricsColorStyle
                ) {
                    if settings.floatingLyricsColorStyle == .custom {
                        ColorPicker("", selection: customColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                }

                Divider().opacity(0.6)

                SettingsMenuRow(
                    title: "settings.floatingLyrics.font.title",
                    description: "settings.floatingLyrics.font.desc",
                    options: Array(FloatingLyricsFontDesign.allCases),
                    optionTitle: { $0.title },
                    accessibilityIdentifier: "settings.floatingLyrics.fontDesign",
                    selection: $settings.floatingLyricsFontDesign
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "settings.floatingLyrics.shadow.title",
                    description: "settings.floatingLyrics.shadow.desc",
                    systemImage: "shadow",
                    color: .gray,
                    iconBadge: false,
                    isOn: $settings.isFloatingLyricsShadowEnabled,
                    accessibilityIdentifier: "settings.floatingLyrics.shadow"
                )

                Divider().opacity(0.6)

                SettingsMenuRow(
                    title: "settings.floatingLyrics.alignment.title",
                    description: "settings.floatingLyrics.alignment.desc",
                    options: Array(FloatingLyricsAlignment.allCases),
                    optionTitle: { $0.title },
                    accessibilityIdentifier: "settings.floatingLyrics.alignment",
                    selection: $settings.floatingLyricsAlignment
                )

                Divider().opacity(0.6)

                SettingsSliderRow(
                    title: "settings.floatingLyrics.fontSize.title",
                    description: "settings.floatingLyrics.fontSize.desc",
                    range: 12...30,
                    step: 1,
                    fractionLength: 0,
                    suffix: "pt",
                    accessibilityIdentifier: "settings.floatingLyrics.fontSize",
                    value: $settings.floatingLyricsFontSize
                )

                Divider().opacity(0.6)

                SettingsSliderRow(
                    title: "settings.floatingLyrics.width.title",
                    description: "settings.floatingLyrics.width.desc",
                    range: 240...700,
                    step: 10,
                    fractionLength: 0,
                    suffix: "pt",
                    accessibilityIdentifier: "settings.floatingLyrics.width",
                    value: $settings.floatingLyricsWidth
                )

                Divider().opacity(0.6)

                SettingsSliderRow(
                    title: "settings.floatingLyrics.opacity.title",
                    description: "settings.floatingLyrics.opacity.desc",
                    range: 0...100,
                    step: 5,
                    fractionLength: 0,
                    suffix: "%",
                    accessibilityIdentifier: "settings.floatingLyrics.opacity",
                    value: Binding(
                        get: { settings.floatingLyricsBackgroundOpacity * 100 },
                        set: { settings.floatingLyricsBackgroundOpacity = $0 / 100 }
                    )
                )
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)
        }
    }

    private var customColor: Binding<Color> {
        Binding(
            get: { Color(lyricsHex: settings.floatingLyricsCustomColorHex) ?? .yellow },
            set: { settings.floatingLyricsCustomColorHex = $0.lyricsHex }
        )
    }

    private var behavior: some View {
        SettingsCard(title: "settings.floatingLyrics.card.behavior") {
            Group {
                SettingsToggleRow(
                    title: "settings.floatingLyrics.hideOnHover.title",
                    description: "settings.floatingLyrics.hideOnHover.desc",
                    systemImage: "cursorarrow.motionlines",
                    color: .teal,
                    iconBadge: false,
                    isOn: $settings.isFloatingLyricsHiddenOnHover,
                    accessibilityIdentifier: "settings.floatingLyrics.hideOnHover"
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "settings.floatingLyrics.hideWhenPaused.title",
                    description: "settings.floatingLyrics.hideWhenPaused.desc",
                    systemImage: "pause.circle.fill",
                    color: .orange,
                    iconBadge: false,
                    isOn: $settings.isFloatingLyricsHiddenWhenPaused,
                    accessibilityIdentifier: "settings.floatingLyrics.hideWhenPaused"
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "settings.floatingLyrics.lockPosition.title",
                    description: "settings.floatingLyrics.lockPosition.desc",
                    systemImage: "lock.fill",
                    color: .gray,
                    iconBadge: false,
                    isOn: $settings.isFloatingLyricsPositionLocked,
                    accessibilityIdentifier: "settings.floatingLyrics.lockPosition"
                )
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)
        }
    }

    private var timing: some View {
        SettingsCard(title: "settings.lyrics.card.timing") {
            SettingsSliderRow(
                title: "settings.lyrics.globalDelay.title",
                description: "settings.lyrics.globalDelay.desc",
                range: -5...5,
                step: 0.1,
                fractionLength: 1,
                suffix: "s",
                accessibilityIdentifier: "settings.lyrics.globalDelay",
                value: $settings.lyricsGlobalDelay
            )

            Divider().opacity(0.6)

            SettingsButtonRow(
                title: "settings.lyrics.songDelay.title",
                description: "settings.lyrics.songDelay.desc",
                buttonTitle: "settings.lyrics.globalDelay.reset",
                isButtonDisabled: settings.lyricsGlobalDelay == 0,
                accessibilityIdentifier: "settings.lyrics.globalDelay.reset"
            ) {
                settings.lyricsGlobalDelay = 0
            }
        }
    }

    private var shortcuts: some View {
        SettingsCard(title: "settings.lyrics.card.shortcuts") {
            SettingsShortcutRow(
                title: "settings.lyrics.shortcut.toggleFloating.title",
                description: "settings.lyrics.shortcut.toggleFloating.desc",
                keyCode: settings.floatingLyricsToggleShortcutKeyCode,
                modifiers: settings.floatingLyricsToggleShortcutModifiers,
                keyDisplay: settings.floatingLyricsToggleShortcutKeyDisplay,
                onSave: { keyCode, modifiers, display in
                    settings.floatingLyricsToggleShortcutKeyCode = keyCode
                    settings.floatingLyricsToggleShortcutModifiers = modifiers
                    settings.floatingLyricsToggleShortcutKeyDisplay = display
                },
                onReset: {
                    settings.floatingLyricsToggleShortcutKeyCode = 3
                    settings.floatingLyricsToggleShortcutModifiers = 786432
                    settings.floatingLyricsToggleShortcutKeyDisplay = "F"
                }
            )

            Divider().opacity(0.6)

            SettingsShortcutRow(
                title: "settings.lyrics.shortcut.delayLater.title",
                description: "settings.lyrics.shortcut.delayLater.desc",
                keyCode: settings.lyricsDelayLaterShortcutKeyCode,
                modifiers: settings.lyricsDelayLaterShortcutModifiers,
                keyDisplay: settings.lyricsDelayLaterShortcutKeyDisplay,
                onSave: { keyCode, modifiers, display in
                    settings.lyricsDelayLaterShortcutKeyCode = keyCode
                    settings.lyricsDelayLaterShortcutModifiers = modifiers
                    settings.lyricsDelayLaterShortcutKeyDisplay = display
                },
                onReset: {
                    settings.lyricsDelayLaterShortcutKeyCode = 30
                    settings.lyricsDelayLaterShortcutModifiers = 786432
                    settings.lyricsDelayLaterShortcutKeyDisplay = "]"
                }
            )

            Divider().opacity(0.6)

            SettingsShortcutRow(
                title: "settings.lyrics.shortcut.delayEarlier.title",
                description: "settings.lyrics.shortcut.delayEarlier.desc",
                keyCode: settings.lyricsDelayEarlierShortcutKeyCode,
                modifiers: settings.lyricsDelayEarlierShortcutModifiers,
                keyDisplay: settings.lyricsDelayEarlierShortcutKeyDisplay,
                onSave: { keyCode, modifiers, display in
                    settings.lyricsDelayEarlierShortcutKeyCode = keyCode
                    settings.lyricsDelayEarlierShortcutModifiers = modifiers
                    settings.lyricsDelayEarlierShortcutKeyDisplay = display
                },
                onReset: {
                    settings.lyricsDelayEarlierShortcutKeyCode = 33
                    settings.lyricsDelayEarlierShortcutModifiers = 786432
                    settings.lyricsDelayEarlierShortcutKeyDisplay = "["
                }
            )
        }
    }

    private var languageDownloadDescription: LocalizedStringKey {
        switch translationStore.status {
        case .needsLanguageDownload:
            return "settings.floatingLyrics.languageDownload.needed"
        case .translated:
            return "settings.floatingLyrics.languageDownload.ready"
        case .sameLanguage:
            return "settings.floatingLyrics.languageDownload.same"
        default:
            return "settings.floatingLyrics.languageDownload.desc"
        }
    }

    private var translation: some View {
        SettingsCard(title: "settings.floatingLyrics.card.translation") {
            Group {
                SettingsToggleRow(
                    title: "settings.floatingLyrics.translation.title",
                    description: "settings.floatingLyrics.translation.desc",
                    systemImage: "translate",
                    color: .blue,
                    isOn: $settings.isLyricsTranslationEnabled,
                    accessibilityIdentifier: "settings.floatingLyrics.translation"
                )

                Divider().opacity(0.6)

                SettingsToggleRow(
                    title: "settings.lyrics.notchTranslation.title",
                    description: "settings.lyrics.notchTranslation.desc",
                    systemImage: "rectangle.topthird.inset.filled",
                    color: .indigo,
                    iconBadge: false,
                    isOn: $settings.isNotchLyricsTranslationEnabled,
                    accessibilityIdentifier: "settings.lyrics.notchTranslation"
                )
                .disabled(!settings.isLyricsTranslationEnabled)
                .opacity(settings.isLyricsTranslationEnabled ? 1 : 0.5)

                Divider().opacity(0.6)

                SettingsButtonRow(
                    title: "settings.floatingLyrics.languageDownload.title",
                    description: languageDownloadDescription,
                    buttonTitle: "settings.floatingLyrics.languageDownload.button",
                    isButtonDisabled: translationStore.status != .needsLanguageDownload && translationStore.status != .failed,
                    accessibilityIdentifier: "settings.floatingLyrics.languageDownload"
                ) {
                    isLanguageDownloadRequested = true
                }
                .lyricsLanguageDownload(store: translationStore, isRequested: $isLanguageDownloadRequested)

                Divider().opacity(0.6)

                SettingsMenuRow(
                    title: "settings.floatingLyrics.translationLanguage.title",
                    description: "settings.floatingLyrics.translationLanguage.desc",
                    options: Array(LyricsTranslationLanguage.allCases),
                    optionTitle: { $0.title },
                    accessibilityIdentifier: "settings.floatingLyrics.translationLanguage",
                    selection: $settings.lyricsTranslationLanguage
                )
                .disabled(!settings.isLyricsTranslationEnabled)
                .opacity(settings.isLyricsTranslationEnabled ? 1 : 0.5)

                Divider().opacity(0.6)

                SettingsButtonRow(
                    title: "settings.floatingLyrics.translationLanguages.title",
                    description: "settings.floatingLyrics.translationLanguages.desc",
                    buttonTitle: "settings.floatingLyrics.translationLanguages.button",
                    accessibilityIdentifier: "settings.floatingLyrics.translationLanguages"
                ) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Divider().opacity(0.6)

            SettingsButtonRow(
                title: "settings.floatingLyrics.reset.title",
                description: "settings.floatingLyrics.reset.desc",
                buttonTitle: "settings.floatingLyrics.reset.button",
                accessibilityIdentifier: "settings.floatingLyrics.reset"
            ) {
                settings.resetFloatingLyrics()
            }
        }
    }
}

private struct FloatingLyricsPreview: View {
    let appearance: FloatingLyricsAppearance

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.22, green: 0.3, blue: 0.5), Color(red: 0.55, green: 0.32, blue: 0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            FloatingLyricsContentView(
                trackLine: "Sample Song · Sample Artist",
                lines: .synced(
                    id: 0,
                    current: "This is the line being sung",
                    translation: appearance.isTranslationEnabled ? "Translated line appears here" : nil,
                    next: "And this is the next line"
                ),
                appearance: appearance,
                accentColor: Color(red: 0.98, green: 0.77, blue: 0.31)
            )
            .frame(width: min(appearance.width, 460), height: appearance.panelHeight)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: appearance.panelHeight + 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: appearance)
    }
}
