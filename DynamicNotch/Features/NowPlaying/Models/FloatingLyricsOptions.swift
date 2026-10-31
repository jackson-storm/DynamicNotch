import SwiftUI
internal import AppKit

enum FloatingLyricsAlignment: String, CaseIterable {
    case leading
    case center

    var title: LocalizedStringKey {
        switch self {
        case .leading:
            return "settings.floatingLyrics.alignment.leading"
        case .center:
            return "settings.floatingLyrics.alignment.center"
        }
    }

    var horizontalAlignment: HorizontalAlignment {
        self == .center ? .center : .leading
    }

    var frameAlignment: Alignment {
        self == .center ? .top : .topLeading
    }

    var textAlignment: TextAlignment {
        self == .center ? .center : .leading
    }
}

enum FloatingLyricsColorStyle: String, CaseIterable {
    case white
    case artwork
    case accent
    case custom

    var title: LocalizedStringKey {
        switch self {
        case .white:
            return "settings.floatingLyrics.color.white"
        case .artwork:
            return "settings.floatingLyrics.color.artwork"
        case .accent:
            return "settings.floatingLyrics.color.accent"
        case .custom:
            return "settings.floatingLyrics.color.custom"
        }
    }
}

enum FloatingLyricsFontDesign: String, CaseIterable {
    case standard
    case rounded
    case serif
    case monospaced

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "settings.floatingLyrics.font.standard"
        case .rounded:
            return "settings.floatingLyrics.font.rounded"
        case .serif:
            return "settings.floatingLyrics.font.serif"
        case .monospaced:
            return "settings.floatingLyrics.font.monospaced"
        }
    }

    var design: Font.Design {
        switch self {
        case .standard:
            return .default
        case .rounded:
            return .rounded
        case .serif:
            return .serif
        case .monospaced:
            return .monospaced
        }
    }
}

/// Languages offered as translation targets; all are supported by Apple's on-device Translation framework.
enum LyricsTranslationLanguage: String, CaseIterable {
    case indonesian = "id"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case thai = "th"
    case vietnamese = "vi"
    case hindi = "hi"
    case arabic = "ar"
    case spanish = "es"
    case portuguese = "pt-BR"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case dutch = "nl"
    case polish = "pl"
    case russian = "ru"
    case ukrainian = "uk"
    case turkish = "tr"

    var title: LocalizedStringKey {
        let name = Locale.current.localizedString(forIdentifier: rawValue) ?? rawValue
        return LocalizedStringKey(name.prefix(1).uppercased() + name.dropFirst())
    }

    var language: Locale.Language {
        Locale.Language(identifier: rawValue)
    }

    static var systemDefault: Self {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return allCases.first { $0.rawValue.hasPrefix(languageCode) } ?? .english
    }
}

struct FloatingLyricsAppearance: Equatable {
    let showsTrackInfo: Bool
    let showsNextLine: Bool
    let fontSize: CGFloat
    let width: CGFloat
    let backgroundOpacity: Double
    let alignment: FloatingLyricsAlignment
    let colorStyle: FloatingLyricsColorStyle
    let customColorHex: String
    let fontDesign: FloatingLyricsFontDesign
    let showsShadow: Bool
    let isTranslationEnabled: Bool
    let translationLanguage: LyricsTranslationLanguage

    var nextLineFontSize: CGFloat { (fontSize * 0.76).rounded() }
    var translationFontSize: CGFloat { (fontSize * 0.8).rounded() }

    /// Height that fits every visible row, so the panel grows or shrinks with the options.
    var panelHeight: CGFloat {
        var height: CGFloat = 24
        if showsTrackInfo {
            height += 14 + 6
        }
        height += lineHeight(fontSize)
        if isTranslationEnabled {
            height += 3 + lineHeight(translationFontSize)
        }
        if showsNextLine {
            height += 4 + lineHeight(nextLineFontSize)
        }
        return height.rounded(.up)
    }

    var panelSize: CGSize {
        CGSize(width: width, height: panelHeight)
    }

    private func lineHeight(_ size: CGFloat) -> CGFloat {
        size * 1.3
    }
}

extension Color {
    init?(lyricsHex hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    var lyricsHex: String {
        let color = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return String(
            format: "#%02X%02X%02X",
            Int((color.redComponent * 255).rounded()),
            Int((color.greenComponent * 255).rounded()),
            Int((color.blueComponent * 255).rounded())
        )
    }
}
