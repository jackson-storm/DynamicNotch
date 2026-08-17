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
    case dutch = "nl"
    case traditionalChinese = "zh-Hant"
    case ukrainian = "uk"
    case swedish = "sv"
    case czech = "cs"
    case arabic = "ar"

    case hindi = "hi"

    case thai = "th"

    case romanian = "ro"

    case hungarian = "hu"

    case greek = "el"

    case danish = "da"

    case finnish = "fi"

    case norwegian = "nb"

    case malay = "ms"

    case hebrew = "he"

    case bulgarian = "bg"

    case catalan = "ca"

    case slovak = "sk"

    case croatian = "hr"

    case serbian = "sr"

    case filipino = "fil"

    case kazakh = "kk"

    case persian = "fa"

    case bengali = "bn"

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
        case .traditionalChinese:
            return ["zh-Hant", "zh-TW", "zh-HK", "zh-MO"]
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
        case .dutch:
            return ["nl", "nl-NL", "nl-BE"]
        case .ukrainian:
            return ["uk", "uk-UA"]
        case .swedish:
            return ["sv", "sv-SE"]
        case .czech:
            return ["cs", "cs-CZ"]
        case .arabic:
            return ["ar", "ar-SA"]
        case .hindi:
            return ["hi", "hi-IN"]
        case .thai:
            return ["th", "th-TH"]
        case .romanian:
            return ["ro", "ro-RO"]
        case .hungarian:
            return ["hu", "hu-HU"]
        case .greek:
            return ["el", "el-GR"]
        case .danish:
            return ["da", "da-DK"]
        case .finnish:
            return ["fi", "fi-FI"]
        case .norwegian:
            return ["nb", "no", "nb-NO", "nn-NO"]
        case .malay:
            return ["ms", "ms-MY"]
        case .hebrew:
            return ["he", "he-IL"]
        case .bulgarian:
            return ["bg", "bg-BG"]
        case .catalan:
            return ["ca", "ca-ES"]
        case .slovak:
            return ["sk", "sk-SK"]
        case .croatian:
            return ["hr", "hr-HR"]
        case .serbian:
            return ["sr", "sr-RS", "sr-Cyrl"]
        case .filipino:
            return ["fil", "fil-PH", "tl", "tl-PH"]
        case .kazakh:
            return ["kk", "kk-KZ", "kk-Cyrl"]
        case .persian:
            return ["fa", "fa-IR"]
        case .bengali:
            return ["bn", "bn-BD", "bn-IN"]
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
        case .traditionalChinese:
            return "settings.language.option.chineseTraditional"
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
        case .dutch:
            return "settings.language.option.dutch"
        case .ukrainian:
            return "settings.language.option.ukrainian"
        case .swedish:
            return "settings.language.option.swedish"
        case .czech:
            return "settings.language.option.czech"
        case .arabic:
            return "settings.language.option.arabic"
        case .hindi:
            return "settings.language.option.hindi"
        case .thai:
            return "settings.language.option.thai"
        case .romanian:
            return "settings.language.option.romanian"
        case .hungarian:
            return "settings.language.option.hungarian"
        case .greek:
            return "settings.language.option.greek"
        case .danish:
            return "settings.language.option.danish"
        case .finnish:
            return "settings.language.option.finnish"
        case .norwegian:
            return "settings.language.option.norwegian"
        case .malay:
            return "settings.language.option.malay"
        case .hebrew:
            return "settings.language.option.hebrew"
        case .bulgarian:
            return "settings.language.option.bulgarian"
        case .catalan:
            return "settings.language.option.catalan"
        case .slovak:
            return "settings.language.option.slovak"
        case .croatian:
            return "settings.language.option.croatian"
        case .serbian:
            return "settings.language.option.serbian"
        case .filipino:
            return "settings.language.option.filipino"
        case .kazakh:
            return "settings.language.option.kazakh"
        case .persian:
            return "settings.language.option.persian"
        case .bengali:
            return "settings.language.option.bengali"
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
        case .traditionalChinese:
            return "traditionalChinese"
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
        case .dutch:
            return "dutch"
        case .ukrainian:
            return "ukrainian"
        case .swedish:
            return "swedish"
        case .czech:
            return "czech"
        case .arabic:
            return "arabic"
        case .hindi:
            return "hindi"
        case .thai:
            return "thai"
        case .romanian:
            return "romanian"
        case .hungarian:
            return "hungarian"
        case .greek:
            return "greek"
        case .danish:
            return "danish"
        case .finnish:
            return "finnish"
        case .norwegian:
            return "norwegian"
        case .malay:
            return "malay"
        case .hebrew:
            return "hebrew"
        case .bulgarian:
            return "bulgarian"
        case .catalan:
            return "catalan"
        case .slovak:
            return "slovak"
        case .croatian:
            return "croatian"
        case .serbian:
            return "serbian"
        case .filipino:
            return "filipino"
        case .kazakh:
            return "kazakh"
        case .persian:
            return "persian"
        case .bengali:
            return "bengali"
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
        case .traditionalChinese:
            return "Traditional Chinese"
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
        case .dutch:
            return "Dutch"
        case .ukrainian:
            return "Ukrainian"
        case .swedish:
            return "Swedish"
        case .czech:
            return "Czech"
        case .arabic:
            return "Arabic"
        case .hindi:
            return "Hindi"
        case .thai:
            return "Thai"
        case .romanian:
            return "Romanian"
        case .hungarian:
            return "Hungarian"
        case .greek:
            return "Greek"
        case .danish:
            return "Danish"
        case .finnish:
            return "Finnish"
        case .norwegian:
            return "Norwegian"
        case .malay:
            return "Malay"
        case .hebrew:
            return "Hebrew"
        case .bulgarian:
            return "Bulgarian"
        case .catalan:
            return "Catalan"
        case .slovak:
            return "Slovak"
        case .croatian:
            return "Croatian"
        case .serbian:
            return "Serbian"
        case .filipino:
            return "Filipino"
        case .kazakh:
            return "Kazakh"
        case .persian:
            return "Persian"
        case .bengali:
            return "Bengali"
        }
    }

    var nativeDisplayName: String {
        switch self {
        case .system:
            return "System"
        case .english:
            return "Engl."
        case .russian:
            return "Русск."
        case .spanish:
            return "Españ."
        case .simplifiedChinese:
            return "简中."
        case .traditionalChinese:
            return "繁中."
        case .turkish:
            return "Türk."
        case .german:
            return "Deut."
        case .french:
            return "Franç."
        case .portuguese:
            return "Portug."
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .italian:
            return "Ital."
        case .polish:
            return "Polsk."
        case .vietnamese:
            return "T. Việt"
        case .indonesian:
            return "Indon."
        case .dutch:
            return "Nederl."
        case .ukrainian:
            return "Україн."
        case .swedish:
            return "Svensk."
        case .czech:
            return "Češt."
        case .arabic:
            return "عرب."
        case .hindi:
            return "हिन्दी."
        case .thai:
            return "ไทย."
        case .romanian:
            return "Român."
        case .hungarian:
            return "Magy."
        case .greek:
            return "Ελλην."
        case .danish:
            return "Dansk."
        case .finnish:
            return "Suom."
        case .norwegian:
            return "Norsk."
        case .malay:
            return "Melay."
        case .hebrew:
            return "עִברִ."
        case .bulgarian:
            return "Бълг."
        case .catalan:
            return "Catal."
        case .slovak:
            return "Slov."
        case .croatian:
            return "Hrvat."
        case .serbian:
            return "Српск."
        case .filipino:
            return "Filip."
        case .kazakh:
            return "Қазақ."
        case .persian:
            return "فارسی."
        case .bengali:
            return "বাংলা."
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
        case .traditionalChinese:
            return [Color.blue, Color.red]
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
        case .dutch:
            return [Color.orange, Color.blue]
        case .ukrainian:
            return [Color.blue, Color.yellow]
        case .swedish:
            return [Color.blue, Color.yellow]
        case .czech:
            return [Color.blue, Color.red]
        case .arabic:
            return [Color.green, Color.white]
        case .hindi:
            return [Color.orange, Color.green]
        case .thai:
            return [Color.red, Color.blue]
        case .romanian:
            return [Color.blue, Color.yellow]
        case .hungarian:
            return [Color.red, Color.green]
        case .greek:
            return [Color.blue, Color.white]
        case .danish:
            return [Color.red, Color.white]
        case .finnish:
            return [Color.blue, Color.white]
        case .norwegian:
            return [Color.red, Color.blue]
        case .malay:
            return [Color.red, Color.yellow]
        case .hebrew:
            return [Color.blue, Color.white]
        case .bulgarian:
            return [Color.green, Color.red]
        case .catalan:
            return [Color.yellow, Color.red]
        case .slovak:
            return [Color.blue, Color.red]
        case .croatian:
            return [Color.red, Color.blue]
        case .serbian:
            return [Color.red, Color.blue]
        case .filipino:
            return [Color.blue, Color.red]
        case .kazakh:
            return [Color.cyan, Color.yellow]
        case .persian:
            return [Color.green, Color.red]
        case .bengali:
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
