import Foundation
import SwiftUI

enum DynamicNotchLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case russian = "ru"
    case spanish = "es"
    case german = "de"
    case french = "fr"
    case portuguese = "pt"
    case japanese = "ja"
    case korean = "ko"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        default:
            return Locale(identifier: rawValue)
        }
    }

    var bundleLanguageCandidates: [String] {
        switch self {
        case .system:
            return []
        case .simplifiedChinese:
            return ["zh-Hans", "zh"]
        default:
            return [rawValue]
        }
    }

    var titleKeyString: String {
        switch self {
        case .system:
            return "settings.language.option.system"
        case .english:
            return "settings.language.option.english"
        case .russian:
            return "settings.language.option.russian"
        case .spanish:
            return "settings.language.option.spanish"
        case .german:
            return "settings.language.option.german"
        case .french:
            return "settings.language.option.french"
        case .portuguese:
            return "settings.language.option.portuguese"
        case .japanese:
            return "settings.language.option.japanese"
        case .korean:
            return "settings.language.option.korean"
        case .simplifiedChinese:
            return "settings.language.option.chineseSimplified"
        }
    }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(titleKeyString)
    }

    var fallbackDisplayName: String {
        switch self {
        case .system:
            return "System"
        case .english:
            return "English"
        case .russian:
            return "Russian"
        case .spanish:
            return "Spanish"
        case .german:
            return "German"
        case .french:
            return "French"
        case .portuguese:
            return "Portuguese"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .simplifiedChinese:
            return "Simplified Chinese"
        }
    }

    var nativeDisplayName: String {
        switch self {
        case .system:
            return "System"
        case .english:
            return "English"
        case .russian:
            return "Русский"
        case .spanish:
            return "Español"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        case .portuguese:
            return "Português"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .simplifiedChinese:
            return "简体中文"
        }
    }

    var codeLabel: String {
        switch self {
        case .system:
            return "AUTO"
        case .english:
            return "EN"
        case .russian:
            return "RU"
        case .spanish:
            return "ES"
        case .german:
            return "DE"
        case .french:
            return "FR"
        case .portuguese:
            return "PT"
        case .japanese:
            return "JA"
        case .korean:
            return "KO"
        case .simplifiedChinese:
            return "ZH"
        }
    }

    var badgeLabel: String {
        switch self {
        case .system:
            return "••"
        case .english:
            return "EN"
        case .russian:
            return "RU"
        case .spanish:
            return "ES"
        case .german:
            return "DE"
        case .french:
            return "FR"
        case .portuguese:
            return "PT"
        case .japanese:
            return "あ"
        case .korean:
            return "가"
        case .simplifiedChinese:
            return "汉"
        }
    }

    var accentColors: [Color] {
        switch self {
        case .system:
            return [Color.gray.opacity(0.9), Color.blue.opacity(0.75)]
        case .english:
            return [Color.blue, Color.teal]
        case .russian:
            return [Color.blue, Color.red]
        case .spanish:
            return [Color.orange, Color.red]
        case .german:
            return [Color.orange.opacity(0.9), Color.red.opacity(0.9)]
        case .french:
            return [Color.indigo, Color.blue]
        case .portuguese:
            return [Color.green, Color.yellow.opacity(0.85)]
        case .japanese:
            return [Color.red, Color.pink]
        case .korean:
            return [Color.blue, Color.pink]
        case .simplifiedChinese:
            return [Color.red, Color.orange]
        }
    }

    static func resolved(_ rawValue: String?) -> DynamicNotchLanguage {
        guard let rawValue, let language = DynamicNotchLanguage(rawValue: rawValue) else {
            return .system
        }

        return language
    }
}
