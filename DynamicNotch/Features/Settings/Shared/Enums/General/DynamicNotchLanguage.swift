import Foundation
import SwiftUI

enum DynamicNotchLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case russian = "ru"
    case spanish = "es"
    case simplifiedChinese = "zh-Hans"
    case turkish = "tr"
    case german = "de"
    case french = "fr"
    case portuguese = "pt"
    case japanese = "ja"
    case korean = "ko"
    case italian = "it"
    case polish = "pl"
    case vietnamese = "vi"
    case indonesian = "id"

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
        case .portuguese:
            return ["pt", "pt-PT", "pt-BR"]
        case .japanese:
            return ["ja", "ja-JP"]
        case .korean:
            return ["ko", "ko-KR"]
        case .italian:
            return ["it", "it-IT"]
        case .polish:
            return ["pl", "pl-PL"]
        case .vietnamese:
            return ["vi", "vi-VN"]
        case .indonesian:
            return ["id", "id-ID"]
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
        case .simplifiedChinese:
            return "settings.language.option.chineseSimplified"
        case .turkish:
            return "settings.language.option.turkish"
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
        case .italian:
            return "settings.language.option.italian"
        case .polish:
            return "settings.language.option.polish"
        case .vietnamese:
            return "settings.language.option.vietnamese"
        case .indonesian:
            return "settings.language.option.indonesian"
        }
    }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey(titleKeyString)
    }

    var flagAssetName: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "english"
        case .russian:
            return "russian"
        case .spanish:
            return "spanish"
        case .simplifiedChinese:
            return "chinese"
        case .turkish:
            return "turkish"
        case .german:
            return "german"
        case .french:
            return "french"
        case .portuguese:
            return "portuguese"
        case .japanese:
            return "japanese"
        case .korean:
            return "korean"
        case .italian:
            return "italian"
        case .polish:
            return "polish"
        case .vietnamese:
            return "vietnamese"
        case .indonesian:
            return "indonesian"
        }
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
        case .simplifiedChinese:
            return "Simplified Chinese"
        case .turkish:
            return "Turkish"
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
        case .italian:
            return "Italian"
        case .polish:
            return "Polish"
        case .vietnamese:
            return "Vietnamese"
        case .indonesian:
            return "Indonesian"
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
        case .simplifiedChinese:
            return "简体中文"
        case .turkish:
            return "Türkçe"
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
        case .italian:
            return "Italiano"
        case .polish:
            return "Polski"
        case .vietnamese:
            return "Tiếng Việt"
        case .indonesian:
            return "Indonesia"
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
        case .simplifiedChinese:
            return [Color.red, Color.orange]
        case .turkish:
            return [Color.red, Color.pink]
        case .german:
            return [Color.red, Color.yellow]
        case .french:
            return [Color.blue, Color.red]
        case .portuguese:
            return [Color.green, Color.red]
        case .japanese:
            return [Color.red, Color.white]
        case .korean:
            return [Color.red, Color.blue]
        case .italian:
            return [Color.green, Color.red]
        case .polish:
            return [Color.white, Color.red]
        case .vietnamese:
            return [Color.red, Color.yellow]
        case .indonesian:
            return [Color.red, Color.white]
        }
    }

    static func resolved(_ rawValue: String?) -> DynamicNotchLanguage {
        guard let rawValue, let language = DynamicNotchLanguage(rawValue: rawValue) else {
            return .system
        }

        return language
    }
}
