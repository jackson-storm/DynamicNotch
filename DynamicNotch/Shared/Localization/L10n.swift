import Foundation

enum L10n {
    static func app(_ key: String, fallback: String? = nil) -> String {
        string(
            key,
            language: DynamicNotchLanguage.resolved(
                UserDefaults.standard.string(forKey: GeneralSettingsStorage.Keys.appLanguage)
            ),
            fallback: fallback
        )
    }

    static func string(_ key: String, language: DynamicNotchLanguage, fallback: String? = nil) -> String {
        localizedString(
            key,
            bundle: Bundle.localizedBundle(for: language.bundleLanguageCandidates),
            fallback: fallback
        )
    }

    static func string(_ key: String, locale: Locale, fallback: String? = nil) -> String {
        localizedString(
            key,
            bundle: Bundle.localizedBundle(for: locale.dynamicNotchLocalizationCandidates),
            fallback: fallback
        )
    }

    static func format(
        _ key: String,
        locale: Locale,
        fallback: String? = nil,
        _ arguments: CVarArg...
    ) -> String {
        let format = string(key, locale: locale, fallback: fallback)
        return String(format: format, locale: locale, arguments: arguments)
    }

    private static func localizedString(_ key: String, bundle: Bundle, fallback: String?) -> String {
        let value = NSLocalizedString(
            key,
            tableName: nil,
            bundle: bundle,
            value: fallback ?? key,
            comment: ""
        )

        return value == key ? (fallback ?? key) : value
    }
}

extension Locale {
    fileprivate var dynamicNotchLocalizationCandidates: [String] {
        let normalized = identifier.replacingOccurrences(of: "_", with: "-")
        let components = normalized.split(separator: "-").map(String.init)
        var candidates: [String] = []

        if !normalized.isEmpty {
            candidates.append(normalized)
        }

        if components.count >= 2 {
            candidates.append(components.prefix(2).joined(separator: "-"))
        }

        if let languageCode = components.first {
            candidates.append(languageCode)
        }

        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    func dn(_ key: String, fallback: String? = nil) -> String {
        L10n.string(key, locale: self, fallback: fallback)
    }

    func dnFormat(_ key: String, fallback: String? = nil, _ arguments: CVarArg...) -> String {
        L10n.format(key, locale: self, fallback: fallback, arguments)
    }
}

private extension L10n {
    static func format(
        _ key: String,
        locale: Locale,
        fallback: String? = nil,
        _ arguments: [CVarArg]
    ) -> String {
        let format = string(key, locale: locale, fallback: fallback)
        return String(format: format, locale: locale, arguments: arguments)
    }
}

private extension Bundle {
    static func localizedBundle(for languageCodes: [String]) -> Bundle {
        for languageCode in languageCodes {
            if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }

        if let fallbackPath = Bundle.main.path(
            forResource: Bundle.main.preferredLocalizations.first,
            ofType: "lproj"
        ),
           let fallbackBundle = Bundle(path: fallbackPath) {
            return fallbackBundle
        }

        return .main
    }
}
