import XCTest
import AppKit
@testable import DynamicNotch

final class LocalizationCatalogTests: XCTestCase {
    private static let translatableLanguages = DynamicNotchLanguage.allCases.filter { $0 != .system }

    /// Keys whose value is meaningfully different in every shipped language.
    private static let representativeKeys = [
        "menuBar.settings",
        "common.cancel",
        "settings.section.battery.title",
        "settings.section.lockScreen.title",
        "settings.system.launchAtLogin.title",
        "settings.permissions.status.needsAccess"
    ]

    /// Every key in the catalog that carries printf-style arguments.
    private static let formattedKeys = [
        "menuBar.version",
        "settings.reset.title",
        "settings.screenRecording.desktopFormat",
        "settings.search.empty.subtitle",
        "settings.notch.priorities.row.default",
        "settings.lockScreen.customSound.unavailableFallback"
    ]

    func testEveryLanguageShipsAnLprojDirectory() {
        for language in Self.translatableLanguages {
            let hasBundle = language.bundleLanguageCandidates.contains { candidate in
                Bundle.main.path(forResource: candidate, ofType: "lproj") != nil
            }

            XCTAssertTrue(hasBundle, "No .lproj directory is bundled for \(language.rawValue)")
        }
    }

    func testEveryLanguageTranslatesRepresentativeKeys() {
        for language in Self.translatableLanguages {
            for key in Self.representativeKeys {
                let value = L10n.string(key, language: language)

                XCTAssertNotEqual(value, key, "\(key) is unresolved in \(language.rawValue)")
                XCTAssertFalse(
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "\(key) is empty in \(language.rawValue)"
                )
            }
        }
    }

    func testTranslationsPreserveFormatSpecifiers() throws {
        for key in Self.formattedKeys {
            let english = try formatSpecifiers(in: L10n.string(key, language: .english))
            XCTAssertFalse(english.isEmpty, "\(key) was expected to carry format specifiers")

            for language in Self.translatableLanguages where language != .english {
                let translated = try formatSpecifiers(in: L10n.string(key, language: language))

                XCTAssertEqual(
                    translated,
                    english,
                    "\(key) has mismatched format specifiers in \(language.rawValue)"
                )
            }
        }
    }

    func testEveryLanguageProvidesPresentationMetadata() {
        for language in DynamicNotchLanguage.allCases {
            XCTAssertFalse(language.titleKeyString.isEmpty, "\(language.rawValue) has no title key")
            XCTAssertFalse(language.nativeDisplayName.isEmpty, "\(language.rawValue) has no native name")
            XCTAssertFalse(language.fallbackDisplayName.isEmpty, "\(language.rawValue) has no fallback name")
            XCTAssertEqual(language.accentColors.count, 2, "\(language.rawValue) needs two accent colors")

            guard let assetName = language.flagAssetName else {
                XCTAssertEqual(language, .system, "Only the system entry may omit a flag asset")
                continue
            }

            XCTAssertFalse(assetName.isEmpty, "\(language.rawValue) has empty flag asset name")
        }
    }

    func testResolvedFallsBackToSystemForUnknownValues() {
        XCTAssertEqual(DynamicNotchLanguage.resolved(nil), .system)
        XCTAssertEqual(DynamicNotchLanguage.resolved("klingon"), .system)
        XCTAssertEqual(DynamicNotchLanguage.resolved("tr"), .turkish)
        XCTAssertEqual(DynamicNotchLanguage.resolved("de"), .german)
        XCTAssertEqual(DynamicNotchLanguage.resolved("fr"), .french)
        XCTAssertEqual(DynamicNotchLanguage.resolved("pt"), .portuguese)
        XCTAssertEqual(DynamicNotchLanguage.resolved("ja"), .japanese)
        XCTAssertEqual(DynamicNotchLanguage.resolved("ko"), .korean)
        XCTAssertEqual(DynamicNotchLanguage.resolved("it"), .italian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("pl"), .polish)
        XCTAssertEqual(DynamicNotchLanguage.resolved("vi"), .vietnamese)
        XCTAssertEqual(DynamicNotchLanguage.resolved("id"), .indonesian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("nl"), .dutch)
        XCTAssertEqual(DynamicNotchLanguage.resolved("zh-Hant"), .traditionalChinese)
        XCTAssertEqual(DynamicNotchLanguage.resolved("uk"), .ukrainian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("sv"), .swedish)
        XCTAssertEqual(DynamicNotchLanguage.resolved("cs"), .czech)
        XCTAssertEqual(DynamicNotchLanguage.resolved("ar"), .arabic)
        XCTAssertEqual(DynamicNotchLanguage.resolved("hi"), .hindi)
        XCTAssertEqual(DynamicNotchLanguage.resolved("th"), .thai)
        XCTAssertEqual(DynamicNotchLanguage.resolved("ro"), .romanian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("hu"), .hungarian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("el"), .greek)
        XCTAssertEqual(DynamicNotchLanguage.resolved("da"), .danish)
        XCTAssertEqual(DynamicNotchLanguage.resolved("fi"), .finnish)
        XCTAssertEqual(DynamicNotchLanguage.resolved("nb"), .norwegian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("ms"), .malay)
        XCTAssertEqual(DynamicNotchLanguage.resolved("he"), .hebrew)
        XCTAssertEqual(DynamicNotchLanguage.resolved("bg"), .bulgarian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("ca"), .catalan)
        XCTAssertEqual(DynamicNotchLanguage.resolved("sk"), .slovak)
        XCTAssertEqual(DynamicNotchLanguage.resolved("hr"), .croatian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("sr"), .serbian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("fil"), .filipino)
        XCTAssertEqual(DynamicNotchLanguage.resolved("kk"), .kazakh)
        XCTAssertEqual(DynamicNotchLanguage.resolved("fa"), .persian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("bn"), .bengali)
    }
}

private extension LocalizationCatalogTests {
    /// Returns the ordered argument positions and conversion characters of a format string,
    /// so a translation can be compared against its source regardless of word order.
    func formatSpecifiers(in value: String) throws -> [String] {
        let pattern = "%(?:(\\d+)\\$)?[-+ #0]*[0-9]*(?:\\.[0-9]+)?(?:hh|h|ll|l|L|z|j|t|q)?([@diouxXeEfgGaAcsp%])"
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(value.startIndex..., in: value)

        let specifiers = regex.matches(in: value, range: range).enumerated().compactMap { index, match -> String? in
            guard let conversion = Range(match.range(at: 2), in: value) else { return nil }

            let position: Int
            if let explicit = Range(match.range(at: 1), in: value), let parsed = Int(value[explicit]) {
                position = parsed
            } else {
                position = index + 1
            }

            return "\(position)\(value[conversion])"
        }

        return specifiers.sorted()
        XCTAssertEqual(DynamicNotchLanguage.resolved("he"), .hebrew)
        XCTAssertEqual(DynamicNotchLanguage.resolved("bg"), .bulgarian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("ca"), .catalan)
        XCTAssertEqual(DynamicNotchLanguage.resolved("sk"), .slovak)
        XCTAssertEqual(DynamicNotchLanguage.resolved("hr"), .croatian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("sr"), .serbian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("fil"), .filipino)
        XCTAssertEqual(DynamicNotchLanguage.resolved("kk"), .kazakh)
        XCTAssertEqual(DynamicNotchLanguage.resolved("fa"), .persian)
        XCTAssertEqual(DynamicNotchLanguage.resolved("bn"), .bengali)
    }
}

