import XCTest
@testable import DynamicNotch

final class EffectiveNotchLanguageTests: XCTestCase {
    func testSystemFollowsTheFirstPreferredLanguage() {
        XCTAssertEqual(DynamicNotchLanguage.system.effectiveNotchLanguage(preferredLanguages: ["ru-RU", "en-US"]), .russian)
        XCTAssertEqual(DynamicNotchLanguage.system.effectiveNotchLanguage(preferredLanguages: ["de-DE"]), .german)
        XCTAssertEqual(DynamicNotchLanguage.system.effectiveNotchLanguage(preferredLanguages: ["zh-Hans-CN"]), .simplifiedChinese)
        XCTAssertEqual(DynamicNotchLanguage.system.effectiveNotchLanguage(preferredLanguages: ["en-GB", "ru-RU"]), .english)
    }

    func testSystemFallsBackToEnglishWhenTheFirstLanguageIsNotSpoken() {
        // A supported language further down the list must not win over the first one.
        XCTAssertEqual(DynamicNotchLanguage.system.effectiveNotchLanguage(preferredLanguages: ["af-ZA", "ru-RU"]), .english)
        XCTAssertEqual(DynamicNotchLanguage.system.effectiveNotchLanguage(preferredLanguages: ["ja-JP", "de-DE"]), .english)
        XCTAssertEqual(DynamicNotchLanguage.system.effectiveNotchLanguage(preferredLanguages: []), .english)
    }

    func testExplicitChoicesIgnoreThePreferredLanguages() {
        XCTAssertEqual(DynamicNotchLanguage.french.effectiveNotchLanguage(preferredLanguages: ["ru-RU"]), .french)
        // A language the notch does not speak falls back to English, as before.
        XCTAssertEqual(DynamicNotchLanguage.japanese.effectiveNotchLanguage(preferredLanguages: ["ru-RU"]), .english)
    }
}
