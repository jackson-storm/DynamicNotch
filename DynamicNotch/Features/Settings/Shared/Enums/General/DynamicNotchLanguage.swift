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
        }
    }

    static func resolved(_ rawValue: String?) -> DynamicNotchLanguage {
        guard let rawValue, let language = DynamicNotchLanguage(rawValue: rawValue) else {
            return .system
        }

        return language
    }
}
