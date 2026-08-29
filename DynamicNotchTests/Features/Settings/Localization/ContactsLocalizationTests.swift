import XCTest
@testable import DynamicNotch

final class ContactsLocalizationTests: XCTestCase {
    private static let languages = DynamicNotchLanguage.allCases.filter {
        $0 != .system
    }

    private static let settingsKeys = [
        "settings.notifications.messages.contacts.title",
        "settings.notifications.messages.contacts.description",
        "settings.notifications.messages.contacts.button",
        "settings.permissions.contacts.title",
        "settings.permissions.contacts.description",
        "settings.permissions.fullDiskAccess.description"
    ]

    func testEveryLanguageTranslatesContactsSettingsStrings() throws {
        for language in Self.languages {
            let bundle = try localizedBundle(for: language)

            for key in Self.settingsKeys {
                let value = bundle.localizedString(
                    forKey: key,
                    value: key,
                    table: nil
                )

                XCTAssertNotEqual(
                    value,
                    key,
                    "\(key) is unresolved in \(language.rawValue)"
                )

                XCTAssertFalse(
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "\(key) is empty in \(language.rawValue)"
                )
            }
        }
    }

    func testEveryLanguageTranslatesContactsUsageDescription() throws {
        let key = "NSContactsUsageDescription"

        for language in Self.languages {
            let bundle = try localizedBundle(for: language)
            let value = bundle.localizedString(
                forKey: key,
                value: key,
                table: "InfoPlist"
            )

            XCTAssertNotEqual(
                value,
                key,
                "\(key) is unresolved in \(language.rawValue)"
            )

            XCTAssertFalse(
                value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "\(key) is empty in \(language.rawValue)"
            )
        }
    }

    private func localizedBundle(
        for language: DynamicNotchLanguage
    ) throws -> Bundle {
        for candidate in language.bundleLanguageCandidates {
            if let path = Bundle.main.path(
                forResource: candidate,
                ofType: "lproj"
            ),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }

        throw XCTSkip(
            "No localized bundle is available for \(language.rawValue)"
        )
    }
}
