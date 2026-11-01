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

    static func notch(_ key: String, fallback: String? = nil) -> String {
        string(
            key,
            language: DynamicNotchLanguage.resolved(
                UserDefaults.standard.string(forKey: GeneralSettingsStorage.Keys.notchLanguage)
            ).effectiveNotchLanguage,
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
            if let bundle = lproj(languageCode) {
                return bundle
            }
        }

        // Nothing asked for is shipped, or the app follows the system language. Use the
        // user's first preferred language when the app has it, otherwise English, the
        // language the strings are written in. preferredLocalizations is not used here:
        // it walks the whole preferred list, so a Mac whose first language is not
        // shipped would get whichever lower-ranked language happens to be.
        if let preferred = Locale.preferredLanguages.first {
            for candidate in Locale(identifier: preferred).dynamicNotchLocalizationCandidates {
                if let bundle = lproj(candidate) {
                    return bundle
                }
            }
        }

        return lproj("en") ?? .main
    }

    private static func lproj(_ languageCode: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }
}
